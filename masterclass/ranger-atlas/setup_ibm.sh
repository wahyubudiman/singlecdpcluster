#Installs CDP-DC single node plus Worldwide bank demo on IBM Cloud
#Pre-reqs:
# - OS: CentOS 7 or RHEL 7
# - vCPUs: 16
# - Memory: 64GB RAM
# - Disk: 100 GB
# - Make sure that ext4 or xfs is used for /kudu e.g. 
# - fdisk -l
# -    Command (m for help): n
# -    Partition number (1-128, default 1): 
# -    First sector (34-209715166, default 2048): 
# -    Last sector, +sectors or +size{K,M,G,T,P} (2048-209715166, default 209715166): 
# -    Created partition 1
# -    Command (m for help): w
# -    The partition table has been altered!
# - fdisk /dev/vdd
# - mkdir /kudu
# - mkfs -t ext4 /dev/vdd
# - mount /dev/vdd /kudu

#Run by:
#curl -sSL https://raw.githubusercontent.com/abajwa-hw/masterclass/master/ranger-atlas/setup_ibm.sh | sudo -E sh

#!/bin/bash
host=$(hostname)
IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
mv /etc/hosts /etc/hosts.bak
echo "127.0.0.1  localhost  localhost.localdomain" > /etc/hosts
echo "${IP} ${host}.ibm.com ${host}" >> /etc/hosts
echo "updated hosts file:"
cat /etc/hosts
echo "hostname is $(hostname -f)"
echo "disabling SELinux for this boot.."
setenforce 0
sestatus


#on Redhat, extra steps needed
if [ $(rpm --query centos-release | grep "not installed" | wc -l) == 1 ]; then
  #if RH, here are the RH repos and commands for adding RH epel and python-pip packages:
  subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"  --enable "rhel-ha-for-rhel-*-server-rpms"
  yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  yum install -y python-pip

  #rest of the workshop vm install commands RH or centos:
  #install tools
  yum install -y java-1.8.0-openjdk-devel vim wget curl git bind-utils chrony
else
  yum install -y git chrony
fi


echo "Setting up KDC..."
curl -sSL https://gist.github.com/abajwa-hw/bca3d23fe146c3ebd59a9b5fd19480a3/raw | sudo -E sh


echo "installing CDP-DC..."
git clone https://github.com/fabiog1901/SingleNodeCDPCluster.git

cd SingleNodeCDPCluster
./setup_krb.sh gcp templates/wwbank_krb.json

echo "Sleeping for 30s..."
sleep 30

echo "Setting up Worldwide bank demo..."
curl -sSL https://raw.githubusercontent.com/abajwa-hw/masterclass/master/ranger-atlas/setup-dc-703.sh | sudo -E bash


