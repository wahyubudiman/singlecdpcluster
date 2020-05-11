# Demo single CDP 7 with worlwideBankDemo data

## Single node CDP 7.0.3 including:

- Cloudera Manager (60 day trial license included) for managing the services
- Kerberos for authentication (via local MIT KDC)
- Ranger for authorization (via both resource/tag based policies for accessand masking)
- Atlas for governance (classification/lineage/search)
- Zeppelin for running/visualizing Hive queries
- Impala/Hive 3 for Sql access and ACID capabilities
- Spark/HiveWarehouseConnector for running secure SparkSQL queries


## Worldwide Bank artifacts
- Demo hive tables
- Demo tags/attributes and lineage in Atlas
- Demo Zeppelin notebooks to walk through demo scenario
- Ranger policies across HDFS, Hive/Impala, Hbase, Kafka, SparkSQL toshowcase:
  - Tag based policies across HDP components
  - Row level security in Hive columns
  - Dynamic tag based masking in Hive columns
  - Hive UDF execution authorization
  - Atlas capabilities like
    - Classifications (tags) and attributes
    - Tag propagation
    - Data lineage
    - Business glossary:categories and terms
  - GDPR Scenarios around consent and data erasure via Hive ACID
- Hive ACID / MERGE labs

## Option 1: Steps to deploy on your own setup
Launch a vanilla Centos 7 VM and set up a single node CDP cluster using this ​Github but instead of "base" CM template choose the "wwbank_krb.json" template:

```
yum install -y git
```
### setup KDC
```
curl -sSL https://gist.github.com/abajwa-hw/bca3d23fe146c3ebd59a9b5fd19480a3/raw | sudo -E sh
or 
sh DemoCDP7_WorldWideBank/setup_kdc.sh 

git clone https://github.com/wahyubudiman/singlecdpcluster.git
cd SingleNodeCDPCluster
./setup_krb.sh gcp templates/wwbank_krb.json
```
### Setup worldwide bank demo using ​script
```
curl -sSL https://raw.githubusercontent.com/abajwa-hw/masterclass/master/ranger-atlas/setup-dc-703.sh | sudo -E bash
```
Once the script completes, you will need to restart Zeppelin once (via CM) for it to pick up thedemo notebooks

### Accessing cluster resources 
### CDP urls
- Access CM at :7180 as admin/admin
- Access Ranger at :6080. ​Ranger login is admin/BadPass#1
- Access Atlas at :31000. ​Atlas login is admin/BadPass#1
- Access ​Zeppelin​ at :​8885. ​
  - Zeppelin user​s​ logins​ are:
    - joe_analyst = BadPass#1
    - ivanna_eu_hr = BadPass#1
    - etl_user = BadPass#1
- Access DAS at :30800

