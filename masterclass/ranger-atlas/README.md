# Ranger Atlas (Worldwide Bank)

## Demo overview

Demo overview can be found [here](https://community.hortonworks.com/articles/151939/hdp-securitygovernance-demo-kit.html) 

## Versions tested

Tested with:
- [x] CDP 7.0.3 / CM 7.0.3
- [x] HDP 3.1.0 / Ambari 2.7.3.0
- [x] HDP 3.0.1 / Ambari 2.7.1.0
- [x] HDP 3.0.0 / Ambari 2.7.0.0


## Fresh install of CDP-DC plus Worldwide demo

- Pre-reqs:
  - Launch a single vanilla Centos/RHEL 7.x VM (e.g. on local VM or openstack or cloud provider of choice) 
  - The VM should not already have any Cloudera/Hortonworks components installed (e.g. do NOT run script on HDP sandbox)
  - The VM requires 16 vcpus and ~64 GB RAM once all services are running and you execute a query, so m4.4xlarge size is recommended
  
- Login as root, (optionally [override any parameters](https://github.com/abajwa-hw/masterclass/blob/master/ranger-atlas/setup-dc-703.sh#L4-L18)) and run setup.sh as below:
```
yum install -y git 
#setup KDC 
curl -sSL https://gist.github.com/abajwa-hw/bca3d23fe146c3ebd59a9b5fd19480a3/raw | sudo -E sh

#install single node CDP-DC cluster
git clone https://github.com/fabiog1901/SingleNodeCDPCluster.git
cd SingleNodeCDPCluster
./setup_krb.sh gcp templates/wwbank_krb.json

#setup demo on cluster
curl -sSL https://raw.githubusercontent.com/abajwa-hw/masterclass/master/ranger-atlas/setup-dc-703.sh | sudo -E bash
```

- This will run for about 35min and install CDP-DC 7.0.3 cluster with the Ranger/Atlas demo installed




## Login details 

- Access CM at :7180 as admin/admin
- Access Ranger at :6080. Ranger login is admin/BadPass#1
- Access Atlas at :31000. Atlas login is admin/BadPass#1
- Access Zeppelin at :8885. Zeppelin users logins are:
  - joe_analyst = BadPass#1
  - ivanna_eu_hr = BadPass#1
  - etl_user = BadPass#1
  - Access DAS at :30800



  ## Demo walkthrough
  
  - CDP walthrough avaiable on Cloudera partner portal [here](https://my.cloudera.com/partner-portal/training/demo-center.html)
  - Older HDP walkthrough of demo steps available [here](https://community.hortonworks.com/articles/151939/hdp-securitygovernance-demo-kit.html)

  ## Other things to try
- Simulate users trying to randomly access Hive tables to generate more interesting audits
```
/tmp/masterclass/ranger-atlas/HortoniaMunichSetup/audit_simulator.sh
```

- Install Ranger Audits Banana dashboard to visuaize audits


  ## How does it work?
- The script basically:
  - uses [SingleNodeCDPCluster](https://github.com/fabiog1901/SingleNodeCDPCluster) to install CM and deploy CDP-DC cluster that includes Ranger/Atlas
  - uses Ranger APIs to import service defs, create tag repo and import policies for HDFS/Hive/Hbase/Kafka
  - import tags into Atlas
  - imports sample Hive data (which also creates HDFS/Hive entities in Atlas)
  - [uses Atlas APIs to associate tags with Hive/Kafka/Hbase/HDFS entities](https://community.hortonworks.com/articles/189615/atlas-how-to-automate-associating-tagsclassificati.html)
  - enables kerberos


 
