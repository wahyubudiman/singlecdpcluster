#run on CDP-DC master node
export enable_kerberos=${enable_kerberos:-true}      ## whether kerberos is enabled on cluster
export atlas_host=${atlas_host:-$(hostname -f)}      ##atlas hostname (if not on current host). Override with your own

#default settings for cloudcat cluster. You can override for your own setup
export ranger_password=${ranger_password:-admin123}  
export atlas_pass=${atlas_pass:-admin}
export kdc_realm=${kdc_realm:-GCE.CLOUDERA.COM}
export cluster_name=${cluster_name:-cm}

#default settings for AMI cluster
#export ranger_password=${ranger_password:-BadPass#1}
#export atlas_pass=${atlas_pass:-BadPass#1}
#export kdc_realm=${kdc_realm:-CLOUDERA.COM}
#export cluster_name=${cluster_name:-SingleNodeCluster}


yum install -y git jq
cd /tmp
git clone https://github.com/abajwa-hw/masterclass  
cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
chmod +x *.sh
./04-create-os-users.sh  
#bug?
useradd rangerlookup


echo "Waiting 30s for Ranger usersync..."
sleep 60


ranger_curl="curl -u admin:${ranger_password}"
ranger_url="http://localhost:6080/service"


${ranger_curl} -X POST -H "Content-Type: application/json" -H "Accept: application/json" ${ranger_url}/public/v2/api/roles  -d @- <<EOF
{
   "name":"Admins",
   "description":"",
   "users":[

   ],
   "groups":[
      {
         "name":"etl",
         "isAdmin":false
      }
   ],
   "roles":[

   ]
}
EOF



${ranger_curl} ${ranger_url}/public/v2/api/servicedef/name/hive \
  | jq '.options = {"enableDenyAndExceptionsInPolicies":"true"}' \
  | jq '.policyConditions = [
{
	  "itemId": 1,
	  "name": "resources-accessed-together",
	  "evaluator": "org.apache.ranger.plugin.conditionevaluator.RangerHiveResourcesAccessedTogetherCondition",
	  "evaluatorOptions": {},
	  "label": "Resources Accessed Together?",
	  "description": "Resources Accessed Together?"
},{
	"itemId": 2,
	"name": "not-accessed-together",
	"evaluator": "org.apache.ranger.plugin.conditionevaluator.RangerHiveResourcesNotAccessedTogetherCondition",
	"evaluatorOptions": {},
	"label": "Resources Not Accessed Together?",
	"description": "Resources Not Accessed Together?"
}
]' > hive.json

${ranger_curl} -i \
  -X PUT -H "Accept: application/json" -H "Content-Type: application/json" \
  -d @hive.json ${ranger_url}/public/v2/api/servicedef/name/hive
sleep 10


#Import Ranger policies
echo "Imorting Ranger policies..."
cd ../Scripts/cdp-policies

resource_policies=$(ls Ranger_Policies_ALL_*.json)
tag_policies=$(ls Ranger_Policies_TAG_*.json)

#import resource based policies
${ranger_curl} -X POST -H "Content-Type: multipart/form-data" -H "Content-Type: application/json" -F "file=@${resource_policies}" -H "Accept: application/json"  -F "servicesMapJson=@servicemapping-all.json" "${ranger_url}/plugins/policies/importPoliciesFromFile?isOverride=true&serviceType=hdfs,tag,hbase,yarn,hive,knox,kafka,atlas,solr"

#import tag based policies
${ranger_curl} -X POST -H "Content-Type: multipart/form-data" -H "Content-Type: application/json" -F "file=@${tag_policies}" -H "Accept: application/json"  -F "servicesMapJson=@servicemapping-tag.json" "${ranger_url}/plugins/policies/importPoliciesFromFile?isOverride=true&serviceType=tag"

cd ../../HortoniaMunichSetup

echo "Sleeping for 45s..."
sleep 45


sudo -u hdfs hdfs dfs -mkdir -p /apps/hive/share/udfs/
sudo -u hdfs hdfs dfs -put /opt/cloudera/parcels/CDH/lib/hive/lib/hive-exec.jar /apps/hive/share/udfs/
sudo -u hdfs hdfs  dfs -chown -R hive:hadoop  /apps


echo "Imorting data..."

cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
sudo -u hdfs ./05-create-hdfs-user-folders.sh
sudo -u hdfs ./06-copy-data-to-hdfs-dc.sh
sudo -u hdfs hdfs dfs -ls -R /hive_data

sudo -u hive beeline  -n hive -f ./data/HiveSchema-dc.hsql
sudo -u hive beeline  -n hive -f ./data/TransSchema-cloud.hsql

echo "Creating users in KDC..."
kadmin.local -q "addprinc -randkey joe_analyst/$(hostname -f)@${kdc_realm}"
kadmin.local -q "addprinc -randkey kate_hr/$(hostname -f)@${kdc_realm}"
kadmin.local -q "addprinc -randkey log_monitor/$(hostname -f)@${kdc_realm}"
kadmin.local -q "addprinc -randkey diane_csr/$(hostname -f)@${kdc_realm}"
kadmin.local -q "addprinc -randkey jermy_contractor/$(hostname -f)@${kdc_realm}"
kadmin.local -q "addprinc -randkey mark_bizdev/$(hostname -f)@${kdc_realm}"
kadmin.local -q "addprinc -randkey john_finance/$(hostname -f)@${kdc_realm}"
kadmin.local -q "addprinc -randkey ivanna_eu_hr/$(hostname -f)@${kdc_realm}"
kadmin.local -q "addprinc -randkey etl_user/$(hostname -f)@${kdc_realm}"


echo "Creating user keytabs..."
mkdir -p /etc/security/keytabs
cd /etc/security/keytabs
kadmin.local -q "xst -k joe_analyst.keytab joe_analyst/$(hostname -f)@${kdc_realm}"    
kadmin.local -q "xst -k log_monitor.keytab log_monitor/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k diane_csr.keytab diane_csr/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k jermy_contractor.keytab jermy_contractor/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k mark_bizdev.keytab mark_bizdev/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k john_finance.keytab john_finance/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k ivanna_eu_hr.keytab ivanna_eu_hr/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k kate_hr.keytab kate_hr/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k etl_user.keytab etl_user/$(hostname -f)@${kdc_realm}" 
chmod +r *.keytab
cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup

#enable PAM auth for zeppelin
setfacl -m user:zeppelin:r /etc/shadow

-------------------------
sed -i.bak "s/21000/31000/g" env_atlas.sh
sed -i.bak "s/localhost/${atlas_host}/g" env_atlas.sh
sed -i.bak "s/ATLAS_PASS=admin/ATLAS_PASS=${atlas_pass}/g" env_atlas.sh

./01-atlas-import-classification.sh

./08-create-hbase-kafka-dc.sh

echo "Sleeping for 60s..."
sleep 60
./09-associate-entities-with-tags-dc.sh

echo "Done!"

-------------------------
#Sample queries (run as joe_analyst)
kinit -kt /etc/security/keytabs/joe_analyst.keytab joe_analyst/$(hostname -f)@${kdc_realm}
beeline

#masking
SELECT surname, streetaddress, country, age, password, nationalid, ccnumber, mrn, birthday FROM worldwidebank.us_customers limit 5

#prohibition
select zipcode, insuranceid, bloodtype from worldwidebank.ww_customers

#tag based deny (EXPIRED_ON)
select fed_tax from finance.tax_2015

#tag based deny (DATA_QUALITY)
select * from cost_savings.claim_savings limit 5


#sparksql
kinit -kt /etc/security/keytabs/joe_analyst.keytab joe_analyst/$(hostname -f)@${kdc_realm}
spark-shell --jars /opt/cloudera/parcels/CDH/jars/hive-warehouse-connector-assembly*.jar     --conf spark.sql.hive.hiveserver2.jdbc.url="jdbc:hive2://$(hostname -f):10000/default;"    --conf "spark.sql.hive.hiveserver2.jdbc.url.principal=hive/$(hostname -f)@${kdc_realm}"    --conf spark.security.credentials.hiveserver2.enabled=false

import com.hortonworks.hwc.HiveWarehouseSession
import com.hortonworks.hwc.HiveWarehouseSession._
val hive = HiveWarehouseSession.session(spark).build()

hive.execute("SELECT surname, streetaddress, country, age, password, nationalid, ccnumber, mrn, birthday FROM worldwidebank.us_customers").show(10)
hive.execute("select zipcode, insuranceid, bloodtype from worldwidebank.ww_customers").show(10)
hive.execute("select * from cost_savings.claim_savings").show(10)


# ---------------------------------
# Config changes required on RC build 
# ---------------------------------
# 
# CM changes
# ------------------------------------
# CM > Hive  >  ranger-hive-security.xml
# ranger.plugin.hive.policy.rest.supports.policy.deltas=false
# ranger.plugin.hive.tag.rest.supports.tag.deltas=false
# 
# CM > Impala  >  ranger-impala-security.xml
# ranger.plugin.hive.policy.rest.supports.policy.deltas=false 
# ranger.plugin.hive.tag.rest.supports.tag.deltas=false
# 
# 
# Kafka server: offsets.topic.replication.factor=1
# Atlas server: atlas.kafka.bootstrap.servers=cdp.cloudera.com:9092
# Ranger: ranger.tagsync.source.atlas=true
# Hbase: Enable Atlas Hook=true
# 
# YARN:
# yarn.nodemanager.resource.memory-mb=20gb
# yarn.scheduler.maximum-allocation-mb=8gb   
# 
# 
# ------------------------------
# Ranger changes:
# kafka > Atlas_entities > rangertagsync > create/configure/consume
# 
# ---------------------------------
# Zeppelin changes:
# 
# CM > zeppelin > disable Knox
# 
# zeppelin.shiro.user.block
# admin=admin,admins
# joe_analyst=BadPass#1,admins
# ivanna_eu_hr=BadPass#1,admins
# etl_user = BadPass#1,admins
# 
# 
# #Zeppelin - HDFS changes
# Cluster-wide Advanced Configuration Snippet (Safety Valve) for core-site.xml
# hadoop.proxyuser.zeppelin.groups=*
# hadoop.proxyuser.zeppelin.hosts=*
# 
# #Zeppelin shiro urls block - remove these
# roles[{{zeppelin_admin_group}}], /api/notebook-repositories/** = authc, roles[{{zeppelin_admin_group}], /api/configurations/** = authc, roles[{{zeppelin_admin_group}}], /api/credential/** = authc, roles[{{zeppelin_admin_group}}], /api/admin/** = authc, roles[{{zeppelin_admin_group}}], /** = authc]
# 
# 
# #Add Zeppelin jdbc interpreter then add below configs
# hive.driver=org.apache.hive.jdbc.HiveDriver
# hive.password=	
# hive.proxy.user.property	=hive.server2.proxy.user
# hive.url	=jdbc:hive2://172.31.21.93:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2
# hive.user	=hive
# 
# 
# #restart zeppelin to auto-populate below
# zeppelin.jdbc.principal 
# zeppelin.jdbc.keytab.location 
# 
# #import notebooks, enable JDBC interpreter in notebook and run
# 
# 
# 
# KnoxUI (knoxui/knoxui) > sandbox > 
# 
#    <service>
#       <role>ZEPPELINUI</role>
#       <url>http://sv-worldwidebank-1.vpc.cloudera.com:8885</url>
#    </service>
#    <service>
#       <role>ZEPPELINWS</role>
#       <url>ws://sv-worldwidebank-1.vpc.cloudera.com:8885</url>
#    </service>
#    
