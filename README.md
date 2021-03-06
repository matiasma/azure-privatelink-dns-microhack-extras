# **Azure Private Link DNS MicroHack - Challenge 8**

This challenge requires the "Azure Private Link DNS MicroHack" environment up and running (https://github.com/adstuart/azure-privatelink-dns-microhack)

# Challenge 8 : Use Azure Firewall to inspect traffic destined to a private endpoint

### Goal 

The goal of this exercise is to understand how to work with route table and network policy to inspect private link traffic by a Firewall 

## Task 1 : Create Azure Firewall and Route Table to inspect private endpoint traffic from a Virtual Machine (this task can also solve the Challange 7)

Run the following command from Azure Cloud Shell (requires the default Azure Private Link DNS Microhack environment on your subscription)

`curl https://raw.githubusercontent.com/matiasma/azure-privatelink-dns-microhack-extras/main/azure-private-link-microhack-firewall-challenge8.sh | bash`

Reference: https://docs.microsoft.com/en-us/azure/private-link/inspect-traffic-with-azure-firewall

## Task 2: Manage network policies for private endpoints

Referece: https://docs.microsoft.com/en-us/azure/private-link/disable-private-endpoint-network-policy

How to enable ICMP in the Windows Firewall

`netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow`

Run these commands before setup the WebApp Private Endpoint:

`az network nic show-effective-route-table --name az-dns-nic -g $resourcegroup`

`az network nic show-effective-route-table --name az-mgmt-nic -g $resourcegroup`

`az network watcher show-next-hop -g $resourcegroup --vm az-dns-vm --source-ip 10.0.0.4 --dest-ip 10.1.0.5`

`az network watcher show-next-hop -g $resourcegroup --vm az-mgmt-vm --source-ip 10.1.0.4 --dest-ip 10.1.0.5`

Create WebApp Private Endpoint in the Spoke VNET/Infrastructure Subnet, and re-run the commands above.

Enable Network Policies in the Private Endpoint subnet, and re-run the four commands above:

`az network vnet subnet update -g $resourcegroup -n InfrastructureSubnet --vnet-name spoke-vnet --disable-private-endpoint-network-policies false`

