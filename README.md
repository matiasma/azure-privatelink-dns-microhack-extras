# **Azure Private Link DNS MicroHack - Challenge 8**

This is an extra challenge for those who are running the "Azure Private Link DNS MicroHack" from Adam Stuart https://github.com/adstuart/azure-privatelink-dns-microhack

# Challenge 8 : Use Azure Firewall to inspect traffic destined to a private endpoint

### Goal 

The goal of this exercise is to understand how to work with route table to send private link traffic to a Firewall 

## Task 1 : Create Azure Firewall and Route Table to inspect private endpoint traffic from a Virtual Machine

Run the folloing command from Azure Cloud Shell

`azure-private-link-microhack-firewall-challenge8.sh`

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

