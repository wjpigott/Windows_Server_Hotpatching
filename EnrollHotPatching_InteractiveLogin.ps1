# Enrollment workflow

$subscriptionId    = '' #Your subscription id
$resourceGroupName = '' # your Resource Group
$machineName       = '' # Arc resource name
$location = "" # The region where the test machine is arc enabled.
$tenantId = ""

$subscriptionStatus = "Enable"; # Set SubscriptionStatus to "Disable" for disenrollment
 
$account       = Connect-AzAccount -Subscription $subscriptionId
$context       = Set-azContext -Subscription $subscriptionId
$profile       = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = [Microsoft.Azure.Commands.ResourceManager.Common.rmProfileClient]::new( $profile )
$token         = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
$header = @{
   'Content-Type'='application/json'
   'Authorization'='Bearer ' + $token.AccessToken
}
 
$uri = [System.Uri]::new( "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.HybridCompute/machines/$machineName/licenseProfiles/default?api-version=2023-10-03-preview" )
$contentType = "application/json"

$data = @{        
    location = $location;
    properties = @{
        productProfile = @{
            productType = "WindowsServer";
            productFeatures = @(@{name = "Hotpatch"; subscriptionStatus = $subscriptionStatus};)
        };
    };
};

$json = $data | ConvertTo-Json -Depth 4;
# To create a license profile resource use PUT call
#$response = Invoke-RestMethod -Method PUT -Uri $uri.AbsoluteUri -ContentType $contentType -Headers $header -Body $json;

# To update a license profile resource use PATCH call
$response = Invoke-RestMethod -Method PATCH -Uri $uri.AbsoluteUri -ContentType $contentType -Headers $header -Body $json;

$response.properties.licenseProfile
