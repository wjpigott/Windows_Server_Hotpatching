# Enrollment workflow

$subscriptionId    = '' #Your subscription id
$resourcegroup = '' # your Resource Group
$server       = '' # Arc resource name
$location = "" # The region where the test machine is arc enabled.
$subscriptionStatus = ""; # Set SubscriptionStatus to "Enable" for enrollment
#$subscriptionStatus = "Disable"; # Set SubscriptionStatus to "Disable" for disenrollment
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
# Output the token if needed by uncommenting out the following line
# $token
# Define the Azure API URL
$url = "https://management.azure.com/subscriptions/$subscriptionid/resourceGroups/$resourcegroup/providers/Microsoft.HybridCompute/machines/$server/licenseProfiles/default?api-version=2023-10-03-preview"
# Create headers with the Authorization token
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$data = @{        
    location = $location;
    properties = @{
        productProfile = @{
            productType = "WindowsServer";
            productFeatures = @(@{name = "Hotpatch"; subscriptionStatus = $subscriptionStatus};)
        };
    };
};


# Convert the request body to JSON format
$bodyJson = $data | ConvertTo-Json -Depth 4;
# Make the REST API call
try {
# To create a license profile resource use PUT call
    #$responseHotPatch = Invoke-RestMethod -Uri $url -Headers $headers -Method Put -Body $bodyJson
# To update a license profile resource use PATCH call
    $responseHotPatch = Invoke-RestMethod -Uri $url -Headers $headers -Method Patch -Body $bodyJson
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody"
    }
}

$responseHotPatch.properties.licenseProfile

