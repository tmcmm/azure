##!/usr/bin/env bash
set -e
. ./params-windows.sh

## Add Windows Node
echo "Add windows node"
az aks nodepool add \
--resource-group $RG_NAME \
--cluster-name $CLUSTER_NAME \
--os-type Windows \
--name $WINDOWS_NODE_POOL_NAME \
--node-count $WINDOWS_NODE_POOL_NUMBER \
--node-vm-size $NODE_SIZE \
--debug
	
### Windows VM RDP Client subnet Creation
echo "Create VM RDP Subnet"
az network vnet subnet create \
-g $RG_NAME \
--vnet-name $WIN_VNET_NAME \
-n $WIN_VM_SUBNET_NAME \
--address-prefixes $WIN_VM_SNET_CIDR \
--debug
  
### Windows VM RDP NSG Create
echo "Create Windows RDP NSG"
az network nsg create \
-g $RG_NAME \
-n $WIN_VM_NSG_NAME \
--debug
  

### Windows Public IP Create
echo "Create Windows Public IP"
az network public-ip create \
--name $WIN_VM_PUBLIC_IP_NAME \
--resource-group $RG_NAME \
--debug
  
### Windows VM Nic Create
echo "Create Windows VM Nic"
az network nic create \
-g $RG_NAME \
--vnet-name $VNET_NAME \
--subnet $WIN_VNET_SUBNET_NAME \
-n $WIN_VM_NIC_NAME \
--network-security-group $WIN_VM_NSG_NAME \
--debug
  
### SSH Attach Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
--name $VM_DEFAULT_IP_CONFIG \
--nic-name $VM_NIC_NAME \
--resource-group $RG_NAME \
--public-ip-address $VM_PUBLIC_IP_NAME \
--debug


### Windows Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
--resource-group $RG_NAME \
--name $WIN_VNET_SUBNET_NAME \
--vnet-name $VNET_NAME \
--network-security-group $WIN_VM_NSG_NAME \
--debug
  
### Windows Create VM
echo "Create Windows VM"
az vm create \
--resource-group $RG_NAME \
--name $WIN_VM_NAME \
--image $WIN_IMAGE  \
--admin-username $ADMIN_USERNAME \
--admin-password $WINDOWS_AKS_ADMIN_PASSWORD \
--nics $WIN_VM_NIC_NAME \
--tags $WIN_TAGS \
--computer-name $WIN_VM_INTERNAL_NAME \
--authentication-type password \
--size $WIN_VM_SIZE \
--storage-sku $WIN_VM_STORAGE_SKU \
--os-disk-size-gb $WIN_VM_OS_DISK_SIZE \
--disk-name $WIN_VM_OS_DISK_NAME \
--nsg-rule NONE \
--debug

### SSH Output Public IP of VM
echo "Public IP of VM is:"
#VM_PUBLIC_IP=$(az network public-ip list -g $RG_NAME --query "{ip:[].ipAddress, name:[].name, tags:[].tags.purpose}" -o json | jq -r ".ip, .name, .tags | @csv")
WIN_VM_PUBLIC_IP=$(az network public-ip list -g $RG_NAME -o json | jq -r ".[] | [.name, .ipAddress] | @csv" | grep rdc | awk -F "," '{print $2}')


WIN_VM_PUBLIC_IP_PARSED=$(echo $WIN_VM_PUBLIC_IP | sed 's/"//g')

### WIN Allow Windows from my Home
echo "Update VM NSG to allow RDP"
az network nsg rule create \
--nsg-name $WIN_VM_NSG_NAME \
--resource-group $RG_NAME \
--name rdc_allow \
--priority 100 \
--source-address-prefixes $MY_HOME_PUBLIC_IP \
--source-port-ranges '*' \
--destination-address-prefixes $WIN_VM_PRIV_IP \
--destination-port-ranges 3389 \
--access Allow \
--protocol Tcp \
--description "Allow from MY ISP IP"
  
  
### Add Win password
ssh -i /home/gits/azure/vm/ssh-keys/id_rsa gits@$SSH_VM_PUBLIC_IP_PARSED "touch ~/win-pass.txt && echo "$WINDOWS_AKS_ADMIN_PASSWORD" > ~/win-pass.txt"

### AKS Get Credentials
echo "Getting Cluster Credentials"
az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME --overwrite-existing

