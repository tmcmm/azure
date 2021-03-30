##!/usr/bin/env zsh
set -e
. ./params.sh
az aks create \
--resource-group $RG_NAME \
--name $CLUSTER_NAME \
--service-principal $SP \
--client-secret $SPPASS \
--node-count $NODE_COUNT \
--node-vm-size $NODE_SIZE \
--location $LOCATION \
--load-balancer-sku standard \
--vnet-subnet-id $VNET_SUBNETID \
--vm-set-type $VMSETTYPE \
--kubernetes-version $VERSION \
--network-plugin $CNI_PLUGIN \
--service-cidr $AKS_CLUSTER_SRV_CIDR \
--dns-service-ip $AKS_CLUSTER_DNS \
--docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
--pod-cidr $AKS_POD_CIDR \
--api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
--admin-username $GENERIC_ADMIN_USERNAME \
--nodepool-name sysnpool \
--nodepool-tags "env=syspool" \
--ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
--debug
