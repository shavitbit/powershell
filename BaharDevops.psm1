<#
    .SYNOPSIS
    Add the current branch to the searchable branch list.

    .DESCRIPTION
     Get all branches 
     Check if the current branch is in searchable branch list 
     if not
     	check if count of searchable branch is less than 5
            if ture
               add $currentBranch to searchable branches
     		if not
     			check if develop branch is inside
     			if true
     				build new list that contain devlop branch, $current_branch, and 3 newest searchable branches
                if not
                    build new list that contain $current_branch and 4 newest searchable branches
    
    .EXAMPLE
    PS> .\searchableStaging.ps1 -reponame devops.azureapi2 -currentBranch refs/heads/theNewBranch1 -key $key -OrganizationName 'payoneer' -projectname  "payoneer"
#>
function Add-SearchableBranchList {
param(
 [Parameter(Mandatory=$true)]
 [string] $reponame,
 [Parameter(Mandatory=$true)]
 [string] $currentBranch ,
 [Parameter(Mandatory=$true)]
 [string] $key,
 [Parameter(Mandatory=$false)]
 [string]$OrganizationName ='', 
 [Parameter(Mandatory=$false)]
 [string]$projectname = ''
)




$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($key)")) }



#region get repo id
$baseUri ="https://dev.azure.com/Payoneer/$($projectname)/_apis/git/repositories" 
$uriExtension = "_apis/projects?api-version=6.0"
$uri = $baseUri+"?"+$uriExtension   
$repolist=Invoke-RestMethod -Uri $uri -Method get -Headers $AzureDevOpsAuthenicationHeader 
$repoId = $repolist.value | Where-Object {$_.name -eq "$reponame"} | Select-Object id
$repoId = $repoId.id
#endregion




#region get repo policy
$repoPolicy= Invoke-RestMethod -Method Get -uri "https://dev.azure.com/$OrganizationName/$projectname/_apis/git/policy/configurations?repositoryId=$repoId&api-version=6.0" -Headers $AzureDevOpsAuthenicationHeader
$repo_type_id = $repoPolicy.value.type.id
$id = $repoPolicy.value.id
#endregion

#get all searchable branches
$existSearchanbleBranches = $repoPolicy.value.settings.searchBranches
write-host "Searchable Branches:"
$existSearchanbleBranches

#check if the current branch is in the list of searchable beanches 
 if ($existSearchanbleBranches.Contains($currentBranch) -or $currentBranch -eq "refs/heads/master"  -or $currentBranch -eq "refs/heads/main")
    {
     Write-Host "Branch exist in searchable branches."
    }

else
    {
     $selectedBranches = @()
     if($existSearchanbleBranches.Length -lt 5)
       {
          $selectedBranches = $existSearchanbleBranches + @($currentBranch)
       }
     else{
         
       if ($existSearchanbleBranches.Contains("refs/heads/develop"))
          {
           $selectedBranches+="refs/heads/develop"
           $selectedBranches+= $currentBranch
           [Collections.Generic.List[String]]$lst = $existSearchanbleBranches
           $lst.Remove("refs/heads/develop") | Out-Null
           [array]$tmp = $lst.GetRange(0,3)
           $selectedBranches +=$tmp
          }

        else
            {
             $selectedBranches+= $currentBranch
             [array]::Reverse($existSearchanbleBranches)
             [Collections.Generic.List[String]]$lst = $existSearchanbleBranches
             $lst.Remove("refs/heads/develop")
             [array]$tmp = $lst.GetRange(0,4)
             $selectedBranches +=$tmp
            }
       

       } 




#region PUT
     $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
     $headers.Add("accept", "application/json;api-version=5.0;excludeUrls=true;enumsAsNumbers=true;msDateFormat=true;noArrayWrap=true")
     $headers.Add("content-type", "application/json")
     $headers.Add("Authorization", $AzureDevOpsAuthenicationHeader.Values)
        
     $template = @"
      {
          "isEnabled": false,
          "isBlocking": false,
          "isDeleted": false,
          "settings": {
              "scope": [
                  {
                      "repositoryId": "$repoId"
                  }
              ],
              "searchBranches": [
                  "refs/heads/theNewBranch2",
                  "refs/heads/theNewBranch3",
                  "refs/heads/theNewBranch4"
              ]
          },
          "isEnterpriseManaged": false,
          "type": {
              "id": "$repo_type_id",
              "url": "https://dev.azure.com/$OrganizationName/$projectname/_apis/policy/types/$repo_type_id",
              "displayName": "GitRepositorySettingsPolicyName"
          }
      }
"@ | ConvertFrom-Json
        
        
            
        
     $template.settings.searchBranches = $selectedBranches
     $body = $template | ConvertTo-Json -Depth 10     
     
    
     $response = Invoke-RestMethod "https://dev.azure.com/$OrganizationName/$projectname/_apis/policy/Configurations/$id" -Method 'PUT' -Headers $headers -Body $body 
     Write-Host
     Write-Host "New Searchable Branches:"
     $response.settings.searchBranches
     #endregion  
  
    
    }


  
  }