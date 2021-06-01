<#
.SYNOPSIS
    Get all build definitions that contain $taskGroupId and change them to multiconfiguration build.
.DESCRIPTION
    bf9c91d4-2db3-4650-9f78-989497614690 = the id of the taskgroup of Build - Infrastructure NuGets - New CSProj - NuGet.exe
.PARAMETER key
    String PAT key.
.PARAMETER taskGroupId
    String task ex bf9c91d4-2db3-4650-9f78-989497614690.
.PARAMETER Multipliers
    String variable that multiply the build ex buildConfiguration.
.PARAMETER maxConcurrency
    Limit the number of agents to be used. If more configurations are specified than the maximum number of agents.
.EXAMPLE
        
        PS> set-multiconfiguration -key $key -taskGroup "bf9c91d4-2db3-4650-9f78-989497614690" -Multipliers "buildConfiguration" -MaxConcurrency 2
        File.txt
#>
param (
[Parameter(Mandatory,Position=0)][string]$key, #$key = Get-Content -Path C:\azureKey\key.txt
[Parameter(Mandatory,Position=1)][string]$taskGroupId, #bf9c91d4-2db3-4650-9f78-989497614690
[Parameter(Mandatory,Position=2)][string]$Multipliers, #buildConfiguration
[Parameter(Mandatory,Position=3)][int]$maxConcurrency  # 2
)
function change2multi{
 param(
 [string]$Multipliers = "buildConfiguration",
 [int]$maxConcurrency = 1,
 [int]$build_id
 )
 

   #$Multipliers = "test"
   #$maxConcurrency = 2
   #$build_id = 1099
   
   
   $multi = [PSCustomObject]@{
       multipliers     = @("$Multipliers")
       maxConcurrency = $maxConcurrency
       continueOnError    = $false
       type             = 1
   }
   
   $build.variables.BuildConfiguration.value = "Debug,Release"
   
   $build = Get-VSTeamBuildDefinition -ProjectName payoneer -Id $build_id -Raw
   $build.process.phases.target.executionOptions = $multi
   
   $body = $build | ConvertTo-Json -Depth 100
   Update-VSTeamBuildDefinition -ProjectName payoneer -Id $build_id -BuildDefinition $body -Force
   
 }





Import-Module VSTeam

Set-VSTeamAccount -Account payoneer -PersonalAccessToken $key

$builds = Get-VSTeamBuildDefinition -ProjectName payoneer | Sort-Object -Unique


#check all build if they have the task group Infrastructure NuGets - New CSProj and foreach one change to multiconfiguration build.
foreach ($build in $builds) 
 {
 $stepsid = $build.internalObject.process.phases.steps.task.id
    foreach ($stepid in $stepsid) 
    {
        if($stepid -eq $taskGroupId){
        Write-Host $stepid
        $buildid=$build.id
        change2multi -Multipliers $Multipliers -maxConcurrency $maxConcurrency -build_id $buildid
         }
    }
 }
 

 
