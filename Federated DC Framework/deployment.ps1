#Define all parameters via user input
$buName = Read-Host -Prompt 'What us the BU name? (eg LCI or TMS)'
$locationName = Read-Host -Prompt 'What is the Azure location name? (eg East or NorthCentral)'
$azureRegion = Read-Host -Prompt 'What is the Azure region code? (eg eastus or northcentralus)'
$siteID = Read-Host -Prompt 'What is the Site ID? (eg AZEST or AZTMS)'
$vipwanAdminPassword = Read-Host -Prompt 'What should be the Vipwan admin password?' -AsSecureString
$frontDMZSubnetRange = Read-Host -Prompt 'What is the subnet/mask for the Net-Hub Front_DMZ Subnet? (eg 10.1.1.0/24)'
$wafDMZSubnetRange = Read-Host -Prompt 'What is the subnet/mask for the Net-Hub WAF_DMZ Subnet? (eg 10.1.1.0/24)'
$viptelaP2PSubnetRange = Read-Host -Prompt 'What is the subnet/mask for the Net-Hub Viptela_P2P Subnet? (eg 10.1.1.0/24)'
$l3NetMgmtSubnetRange = Read-Host -Prompt 'What is the subnet/mask for the Net-Hub L3_Net_Mgmt Subnet? (eg 10.1.1.0/24)'
$unclassifiedSubnetRange = Read-Host -Prompt 'What is the subnet/mask for the Prod-Servers Unclassified Subnet? (eg 10.1.1.0/24)'
$restrictedSubnetRange = Read-Host -Prompt 'What is the subnet/mask for the Prod-Servers Restricted Subnet? (eg 10.1.1.0/24)'
$confidentialSubnetRange = Read-Host -Prompt 'What is the subnet/mask for the Prod-Servers Confidential Subnet? (eg 10.1.1.0/24)'
$topsecretSubnetRange = Read-Host -Prompt 'What is the subnet/mask for the Prod-Servers Top-Secret Subnet? (eg 10.1.1.0/24)'
$adfswebSubnetRange = Read-Host -Prompt 'What is the subnet/mask for the ADFS ADFS_Web Subnet? (eg 10.1.1.0/24)'


#Define static parameters
$lciADConnectRG = "LCI_PROD_ADConnect"
$lciADConnectvNetID = "/subscriptions/35475d24-3b2b-4677-b89f-641336093cbb/resourceGroups/LCI_PROD_ADConnect/providers/Microsoft.Network/virtualNetworks/LCI_PROD_ADConnect-vNet"
$lciADConnectvNetName = "LCI_PROD_ADConnect-vNet"
$lciADFSEastRG = "LCI_ADFS_East"
$lciADFSEastvNetID = "/subscriptions/35475d24-3b2b-4677-b89f-641336093cbb/resourceGroups/LCI_ADFS_East/providers/Microsoft.Network/virtualNetworks/LCI_ADFS_East_vNet"
$lciADFSEastvNetName = "LCI_ADFS_East_vNet"
$lciADFSNorthCentralRG = "LCI_ADFS_North-Central"
$lciADFSNorthCentralvNetID = "/subscriptions/35475d24-3b2b-4677-b89f-641336093cbb/resourceGroups/LCI_ADFS_North-Central/providers/Microsoft.Network/virtualNetworks/LCI_ADFS_North-Central_vNet"
$lciADFSNorthCentralvNetName = "LCI_ADFS_North-Central_vNet"


Write-Host ""
Write-Host "Connecting to Azure & selecting Prod subscription..."
Connect-AzAccount
Select-AzSubscription "Lippert Prod"



$rg_template="./Resource_Groups.json"
$rgjob = 'job.' + ((Get-Date)).tostring("MMddyy.HHmm")
Write-Host ""
Write-Host "Phase 1/5"
Write-Host "Beginning deployment of resource groups..."

$rg_outputs = (New-AzSubscriptionDeployment -Name $rgjob -Location $azureRegion -TemplateFile $rg_template -buName $buName -locationName $locationName -azureRegion $azureRegion).Outputs

#Collect data from outputs section
$netHubRG = $rg_outputs.netHubRGID.value
$prodServersRG = $rg_outputs.prodServersRGID.value
$adfsRG = $rg_outputs.adfsRGID.value

Write-Host ""
Write-Host "Deployment of resource groups was successful..."
Write-Host ""
Write-Host "Deployment Outputs:"
Write-Host $netHubRG
Write-Host $prodServersRG
Write-Host $adfsRG



$nethub_template = "./Net-Hub_Resources.json"
$nethubjob = 'job.' + ((Get-Date)).tostring("MMddyy.HHmm")
Write-Host ""
Write-Host "Phase 2/5"
Write-Host "Beginning deployment of Net-Hub resources..."

$nethub_outputs = (New-AzResourceGroupDeployment -Name $nethubjob -ResourceGroupName $netHubRG -TemplateFile $nethub_template -siteID $siteID -buName $buName -locationName $locationName -vipwanAdminPassword $vipwanAdminPassword -frontDMZSubnetRange $frontDMZSubnetRange -wafDMZSubnetRange $wafDMZSubnetRange -viptelaP2PSubnetRange $viptelaP2PSubnetRange -l3NetMgmtSubnetRange $l3NetMgmtSubnetRange).Outputs

#Collect data from outputs section
$routeTableID = $nethub_outputs.routeTableID.value
$netHubvNetID = $nethub_outputs.netHubvNetID.value
$netHubvNetName = $nethub_outputs.netHubvNetName.value

Write-Host ""
Write-Host "Deployment of Net-Hub resources was successful..."
Write-Host ""
Write-Host "Deployment Outputs:"
Write-Host $routeTableID
Write-Host $netHubvNetID
Write-Host $netHubvNetName



$prodservers_template = "./Prod-Servers_Resources.json"
$prodserversjob = 'job.' + ((Get-Date)).tostring("MMddyy.HHmm")
Write-Host ""
Write-Host "Phase 3/5"
Write-Host "Beginning deployment of Prod-Servers resources..."

$prodservers_outputs = (New-AzResourceGroupDeployment -Name $prodserversjob -ResourceGroupName $prodServersRG -TemplateFile $prodservers_template -buName $buName -locationName $locationName -routeTableID $routeTableID -unclassifiedSubnetRange $unclassifiedSubnetRange -restrictedSubnetRange $restrictedSubnetRange -confidentialSubnetRange $confidentialSubnetRange -topsecretSubnetRange $topsecretSubnetRange).Outputs

#Collect data from outputs section
$prodServersvNetID = $prodservers_outputs.prodServersvNetID.value
$prodServersvNetName = $prodservers_outputs.prodServersvNetName.value

Write-Host ""
Write-Host "Deployment of Prod-Servers resources was successful..."
Write-Host ""
Write-Host "Deployment Outputs:"
Write-Host $prodServersvNetID
Write-Host $prodServersvNetName



$adfs_template = "./ADFS_Resources.json"
$adfsjob = 'job.' + ((Get-Date)).tostring("MMddyy.HHmm")
Write-Host ""
Write-Host "Phase 4/5"
Write-Host "Beginning deployment of ADFS resources..."

$adfs_outputs = (New-AzResourceGroupDeployment -Name $adfsjob -ResourceGroupName $adfsRG -TemplateFile $adfs_template -buName $buName -locationName $locationName -routeTableID $routeTableID -adfswebSubnetRange $adfswebSubnetRange).Outputs

#Collect data from outputs section
$adfsServersvNetID = $adfs_outputs.adfsServersvNetID.value
$adfsServersvNetName = $adfs_outputs.adfsServersvNetName.value

Write-Host ""
Write-Host "Deployment of ADFS resources was successful..."
Write-Host ""
Write-Host "Deployment Outputs:"
Write-Host $adfsServersvNetID
Write-Host $adfsServersvNetName



$fedpeering_template = "./vNet_Peering_Fed.json"
$lcipeering_template = "./vNet_Peering_LCI.json"
$fedpeeringjob = 'job.' + ((Get-Date)).tostring("MMddyy.HHmm")
$lcipeeringjob = 'job.' + ((Get-Date)).tostring("MMddyy.HHmm")
Write-Host ""
Write-Host "Phase 5/5"
Write-Host "Beginning connection of vNet Peers..."

New-AzResourceGroupDeployment -Name $fedpeeringjob -ResourceGroupName $netHubRG -TemplateFile $fedpeering_template -netHubRG $netHubRG -netHubvNetID $netHubvNetID -netHubvNetName $netHubvNetName -prodServersRG $prodServersRG -prodServersvNetID $prodServersvNetID -prodServersvNetName $prodServersvNetName -adfsRG $adfsRG -adfsServersvNetID $adfsServersvNetID -adfsServersvNetName $adfsServersvNetName -lciADConnectRG $lciADConnectRG -lciADConnectvNetID $lciADConnectvNetID -lciADFSEastRG $lciADFSEastRG -lciADFSEastvNetID $lciADFSEastvNetID -lciADFSNorthCentralRG $lciADFSNorthCentralRG -lciADFSNorthCentralvNetID $lciADFSNorthCentralvNetID
New-AzResourceGroupDeployment -Name $lcipeeringjob -ResourceGroupName $lciADConnectRG -TemplateFile $lcipeering_template -prodServersRG $prodServersRG -prodServersvNetID $prodServersvNetID -adfsRG $adfsRG -adfsServersvNetID $adfsServersvNetID -lciADConnectRG $lciADConnectRG -lciADConnectvNetName $lciADConnectvNetName -lciADFSEastRG $lciADFSEastRG -lciADFSEastvNetName $lciADFSEastvNetName -lciADFSNorthCentralRG $lciADFSNorthCentralRG -lciADFSNorthCentralvNetName $lciADFSNorthCentralvNetName

Write-Host ""
Write-Host "vNet Peering Connections Successful..."
Write-Host ""
Write-Host ""
Write-Host "All Phases Complete!"