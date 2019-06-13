﻿Remove-Item built -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item doc/index.md -Force -Recurse -ErrorAction SilentlyContinue  
Remove-Item doc/_site -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item doc/obj -Force -Recurse -ErrorAction SilentlyContinue    
dotnet clean 
dotnet restore 
dotnet test /p:CollectCoverage=true /p:Exclude=[xunit.*]* /p:CoverletOutput='../../built/coverage.cobertura.xml' /p:CoverletOutputFormat=cobertura
$temp = git-flow-version | ConvertFrom-Json
$version = $temp.FullSemVer
$assemblyVersion = $temp.AssemblyVersion
$assemblyInfoContent = @"
// <auto-generated/>
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyVersionAttribute("$($assemblyVersion)")]
[assembly: AssemblyFileVersionAttribute("$($assemblyVersion)")]
[assembly: AssemblyInformationalVersionAttribute("$($version)")]
"@
if (-not (Test-Path "built")) {
    New-Item -ItemType Directory "built"
}
$assemblyInfoContent | Out-File -Encoding utf8 (Join-Path "built" "SharedAssemblyInfo.cs") -Force

dotnet pack /p:PackageVersion=$version /p:NoPackageAnalysis=true
pushd built
dotnet nuget push --source "https://www.myget.org/F/divverence/api/v2/package" --api-key $env:DivverenceMygetApiKey *.nupkg
popd
Copy-Item README.md doc/index.md
docfx ./doc/docfx.json