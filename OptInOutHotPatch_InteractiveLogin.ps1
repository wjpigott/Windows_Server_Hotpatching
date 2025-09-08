# Enrollment workflow

$subscriptionId    = '' #Your subscription id
$resourceGroupName = '' # your Resource Group
$machineName       = '' # Arc resource name
$location = "" # The region where the test machine is arc enabled.
$tenantId = ""
# Do you want to opt-in ($true) or Opt-Out ($false) for receiving hotpatch without changing the license to get hotpatch.
$hotpatchStatus = $false

$account       = Connect-AzAccount -Subscription $subscriptionId
$context       = Set-azContext -Subscription $subscriptionId
$profile       = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = [Microsoft.Azure.Commands.ResourceManager.Common.rmProfileClient]::new( $profile )
 
$token         = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
$header = @{
   'Content-Type'='application/json'
   'Authorization'='Bearer ' + $token.AccessToken
}
 
$uri = [System.Uri]::new( "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.HybridCompute/machines/$machineName ?api-version=2024-07-10" )
$contentType = "application/json"
 
$data = @{ 
    location = $location;
    properties = @{
         osProfile = @{
             windowsConfiguration=@{
                 patchSettings=@{
                     enableHotpatching=$hotpatchStatus;
                 };
             };
         };
     };
};
 
$json = $data | ConvertTo-Json -Depth 4; 
$response = Invoke-RestMethod -Method PATCH -Uri $url -ContentType $contentType -Headers $header -Body $json;
