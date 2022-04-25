# variables
resourcegroup=privatelink-dns-microhack-rg
azfwname=AzFwHub01
azfwsubnet='10.0.2.0/26'
loganalyticsname=privatelink-dns-microhack
azfwscope='10.0.0.0/8'
spokeinfrasubnet='10.1.0.0/24'
hubdnssubnet='10.0.0.0/24'
routetablename=hubspoke01mc
hubvnetname=hub-vnet
spokevnetname=spoke-vnet
hubdnssubnetname=DNSSubnet
spokeinfrasubnetname=InfrastructureSubnet
# az cli azure-firewall extension
az config set extension.use_dynamic_install=yes_without_prompt
az extension add --name azure-firewall
# create Log Analytics Workspace
az monitor log-analytics workspace create -g $resourcegroup -n $loganalyticsname
loganalyticsid=$(az monitor log-analytics workspace show  -g $resourcegroup --workspace-name $loganalyticsname --query id -o tsv)
# create Azure Firewall Subnet
az network vnet subnet create -g $resourcegroup --vnet-name $hubvnetname \
	-n AzureFirewallSubnet --address-prefixes $azfwsubnet
# create Azure Firewall
az network firewall create --name $azfwname -g $resourcegroup
az network public-ip create --name pip01-$azfwname -g $resourcegroup \
	 --allocation-method static --sku standard
az network firewall ip-config create --firewall-name $azfwname --name $azfwname \
	--public-ip-address pip01-$azfwname -g $resourcegroup --vnet-name $hubvnetname
az network firewall update  --name $azfwname -g $resourcegroup 
fwprivaddr="$(az network firewall ip-config list -g $resourcegroup -f $azfwname \
	--query "[?name=='$azfwname'].privateIpAddress" --output tsv)"
azfwid=$(az network firewall show --name $azfwname -g $resourcegroup -o tsv --query id)
# enable Azure Firewall logs in the log analytics workspace
az monitor diagnostic-settings create -n 'toLogAnalytics'   --resource $azfwid    --workspace $loganalyticsid  \
	--logs '[{"category":"AzureFirewallApplicationRule","Enabled":true}, {"category":"AzureFirewallNetworkRule","Enabled":true}, {"category":"AzureFirewallDnsProxy","Enabled":true}]'
# create Route Table to send traffic between spokevnet\infrasubnet and hubvnet\dnssubnet to Azure Firewall
az network route-table create --name $routetablename --resource-group $resourcegroup
az network route-table route create --address-prefix $spokeinfrasubnet --name to-spoke-infra -g $resourcegroup \
	 --next-hop-type VirtualAppliance --route-table-name $routetablename --next-hop-ip-address $fwprivaddr
az network route-table route create --address-prefix $hubdnssubnet --name to-hub-ad -g $resourcegroup \
	--next-hop-type VirtualAppliance --route-table-name $routetablename --next-hop-ip-address $fwprivaddr
az network vnet subnet update -g $resourcegroup -n $hubdnssubnetname --vnet-name $hubvnetname --route-table $routetablename
az network vnet subnet update -g $resourcegroup -n $spokeinfrasubnetname --vnet-name $spokevnetname --route-table $routetablename
# Azure Firewall network rule (UDP and ICMP only)
az network firewall network-rule create --collection-name Net-Coll01 --dest-addr $azfwscope  \
   --destination-ports '*'  --firewall-name $azfwname --name Allow-All  --protocols UDP ICMP \
   --resource-group $resourcegroup --priority 100 --source-addresses $azfwscope  --action Allow
# New WebApp
webappname=web$(date +%s%N | cut -b10-19)
az appservice plan create --name $webappname --resource-group $resourcegroup --sku s1 --is-linux
az webapp create -g $resourcegroup -p $webappname -n $webappname --runtime "DOTNETCORE:6.0"
# Azure Firewall Application Rule
az network firewall application-rule create  --collection-name App-Coll01  --firewall-name $azfwname \
   --name Allow-WebApp --protocols Http=80 Https=443 -g $resourcegroup --target-fqdns "$webappname.azurewebsites.net" \
   --source-addresses '*'  --priority 200  --action Allow
# end
