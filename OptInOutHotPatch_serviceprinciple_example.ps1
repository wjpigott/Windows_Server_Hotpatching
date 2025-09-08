$subscriptionId    = '' #Your subscription id
$resourcegroup = '' # your Resource Group
$server       = '' # Arc resource name
$location = "" # The region where the test machine is arc enabled.
# Do you want to opt-in ($true) or Opt-Out ($false) for receiving hotpatch without changing the license to get hotpatch.
$hotpatchStatus = $true
#
$tenantId = ""
$clientId = "" # Service Principle Application Client ID
$clientSecret = "" # Service Principle Secret
#
# Define the resource you want to access
$resource = "https://management.azure.com/"
# Define the token endpoint
$tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/token"
# Define the body of the request
$body = @{
    'resource' = $resource
    'client_id' = $clientId
    'grant_type' = 'client_credentials'
    'client_secret' = $clientSecret
}
# Invoke the REST method to get the token
$response = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -Body $body
# Extract the token from the response
$token = $response.access_token
# Define the Azure API URL
$url = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.HybridCompute/machines/$machineName ?api-version=2024-07-10"
# Create headers with the Authorization token
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

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
 
$json = $data | ConvertTo-Json -Depth 4; $response = Invoke-RestMethod -Method PATCH -Uri $url -ContentType $contentType -Headers $headers -Body $json;
