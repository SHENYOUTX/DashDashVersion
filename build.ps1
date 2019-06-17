﻿$ErrorActionPreference = "Stop";
Remove-Item built -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item doc/index.md -Force -Recurse -ErrorAction SilentlyContinue  
Remove-Item doc/_site -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item doc/obj -Force -Recurse -ErrorAction SilentlyContinue    
dotnet clean 
dotnet restore 
dotnet test /p:CollectCoverage=true /p:Exclude=[xunit.*]* /p:CoverletOutput='../../built/coverage.cobertura.xml' /p:CoverletOutputFormat=cobertura
$gitBranch = git rev-parse --abbrev-ref HEAD;

if($env:Build.Reason -ne "PullRequest")
{
    $temp = git-flow-version | ConvertFrom-Json
    $env:fullSemVer = $temp.FullSemVer
    $env:semVer = $temp.SemVer
    $env:assemblyVersion = $temp.AssemblyVersion

    $assemblyInfoContent = @"
// <auto-generated/>
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyVersionAttribute("$($env:assemblyVersion)")]
[assembly: AssemblyFileVersionAttribute("$($env:assemblyVersion)")]
[assembly: AssemblyInformationalVersionAttribute("$($env:fullSemVer)")]
"@

    if (-not (Test-Path "built")) {
        New-Item -ItemType Directory "built"
    }

    $assemblyInfoContent | Out-File -Encoding utf8 (Join-Path "built" "SharedAssemblyInfo.cs") -Force
    dotnet pack /p:PackageVersion=$env:fullSemVer /p:NoPackageAnalysis=true


    if ($env:TF_BUILD -eq "True" ) {

        if ($gitBranch -ne "master") {
		    git remote set-url origin git@github.com:hightechict/DashDashVersion.git
            git tag $env:semVer
            git push --verbose origin $env:semVer -ErrorAction SilentlyContinue  
        }

        if ($gitBranch -notlike "feature/*") {
            pushd built
            dotnet nuget push --api-key $env:NuGet_APIKEY *.nupkg
            popd
        }

        Copy-Item README.md doc/index.md
        docfx ./doc/docfx.json
    }
}