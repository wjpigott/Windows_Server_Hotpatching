# Create Update Session
$session = New-Object -ComObject "Microsoft.Update.Session"
$session.ClientApplicationID = "Sample Code"

# Create Update Searcher and search for updates
Write-Host "Creating Update Searcher and searching for updates.."
$updateSearcher = $session.CreateUpdateSearcher()
$searchResult = $updateSearcher.Search("IsInstalled=0 and DeploymentAction='Installation'")

# If no updates found, exit
if ($searchResult.Updates.Count -eq 0)
{
    Write-Host "No updates found!"
    Exit
}

# Loop over each update in the Search result Update Collection
foreach ($update in $searchResult.Updates)
{
    Write-Host "Update title: '$($update.Title)'"
    Write-Host "Querying static 'ContainsUpdateBootstrapper' property.."

    # Query for static extended property
    # https://learn.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdateex-get_extendedstaticproperty
    $containsUpdateBootstrapper = $update.ExtendedStaticProperty("ContainsUpdateBootstrapper")

    # If the update contains bootstrapper, perform pre-download and query for dynamic extended property
    if ($containsUpdateBootstrapper)
    {
        Write-Host "Update '$($update.Title)' contains update bootstrapper"
        Write-Host "Creating Update Downloader and performing pre-download of update bootstrapper.."

        # Create an update collection and add updates to download
        $downloadColl = New-Object -ComObject "Microsoft.Update.UpdateColl"
        $downloadColl.Add($update)

        # Create an Update Downloader and set the update collection to download
        $downloader = $Session.CreateUpdateDownloader()
        $downloader.Updates = $downloadColl

        # Perform pre-download to download only update bootstrapper
        # https://learn.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdatedownloaderex-download2
        $downloadResult = $downloader.Download2(1)
        if ($downloadResult.HResult -eq 0)
        {
            Write-Host "Successfully downloaded update bootstrapper"
            Write-Host "Evaluating Update 'RebootRequired' property.."
           # Write-Host $update
            # Query for dynamic extended property
            # https://learn.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdateex-evaluateextendeddynamicproperty
           try {
    		$doesUpdateRequireReboot = $update.EvaluateExtendedDynamicProperty("DoesUpdateRequireReboot")
		} catch {
    		Write-Host "Error evaluating property: $($_.Exception.Message)"
		}
	    if ($doesUpdateRequireReboot)
            {
                # If update requires reboot, skip download/install
                Write-Host "Update: '$($update.Title)' requires reboot, skipping"
            }
            else
            {
                # If update does not require reboot, it is a rebootless update, hence perform full download and install
                Write-Host "Update: '$($update.Title)' does not require reboot"
                Write-Host "Performing full download of update '$($update.Title)'.."

                # Perform full download of the update
                $fullDownloadResult = $downloader.Download()
                if ($fullDownloadResult.HResult -eq 0)
                {
                    Write-Host "Successfully downloaded update: '$($update.Title)'"
                    Write-Host "Creating Update Installer to install update: '$($update.Title)'.."

                    # Create an update collection and add updates to install
                    $installColl = New-Object -ComObject "Microsoft.Update.UpdateColl"
                    $installColl.Add($update)

                    # Create an Update Installer, set the update collection to install and install the updates
                    $installer = $Session.CreateUpdateInstaller()
                    $installer.Updates = $installColl

                    # Install the updates
                    $installResult = $installer.Install()
                    if ($installResult.HResult -eq 0)
                    {
                        Write-Host "Successfully installed update: '$($update.Title)'"
                    }
                    else
                    {
                        Write-Host "Failed to install update: '$($update.Title)'!"
                        Exit
                    }
                }
                else
                {
                    Write-Host "Failed to download update: '$($update.Title)'!"
                    Exit
                }
            }
        }
        else
        {
            Write-Host "Failed to download update bootstrapper for update: '$($update.Title)'!"
            Exit
        }
    }
    else
    {
        Write-Host "Update '$($update.Title)' does not contain update bootstrapper, skipping"
    }
} 
