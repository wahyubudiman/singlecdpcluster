#curl -sSL https://raw.githubusercontent.com/abajwa-hw/masterclass/master/ranger-atlas/setup-dc-703.sh | sudo -E bash  

#run on CDP-DC master node
export enable_kerberos=${enable_kerberos:-true}      ## whether kerberos is enabled on cluster
export atlas_host=${atlas_host:-$(hostname -f)}      ##atlas hostname (if not on current host). Override with your own

#default settings for cloudcat cluster. You can override for your own setup
# export ranger_password=${ranger_password:-admin123}  
# export atlas_pass=${atlas_pass:-admin}
# export kdc_realm=${kdc_realm:-GCE.CLOUDERA.COM}
# export cluster_name=${cluster_name:-cm}

#default settings for AMI cluster
export ranger_password=${ranger_password:-BadPass#1}
export atlas_pass=${atlas_pass:-BadPass#1}
export kdc_realm=${kdc_realm:-CLOUDERA.COM}
#export cluster_name=${cluster_name:-SingleNodeCluster}
export import_hue_queries=${import_hue_queries:-true}
export host=$(hostname -f)

yum install -y git jq nc
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


kinit -kt /etc/security/keytabs/etl_user.keytab  etl_user/$(hostname -f)@${kdc_realm}
hdfs dfs -mkdir -p /apps/hive/share/udfs/
hdfs dfs -put /opt/cloudera/parcels/CDH/lib/hive/lib/hive-exec.jar /apps/hive/share/udfs/
hdfs  dfs -chown -R hive:hadoop  /apps


echo "Imorting data..."

cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
./05-create-hdfs-user-folders.sh
./06-copy-data-to-hdfs-dc.sh
hdfs dfs -ls -R /hive_data

echo "Create hive tables..."
beeline  -n etl_user -f ./data/HiveSchema-dc.hsql
beeline  -n etl_user -f ./data/TransSchema-cloud.hsql

echo "enable PAM auth for zeppelin, Hue..."
setfacl -m user:zeppelin:r /etc/shadow
setfacl -m user:hue:r /etc/shadow

if [ "${import_hue_queries}" = true  ]; then
   echo "import sample Hue queries..."
   #these were previously exported via: mysqldump -u hue -pcloudera hue desktop_document2 > desktop_document2.sql
   mysql -u hue -pcloudera hue < ./data/desktop_document2.sql
fi

sleep 5 
cd ../Scripts/interpreters/

echo "In Zeppelin, create shell and jdbc interpreter settings via API.."

#login to zeppelin and grab cookie 
cookie=$( curl -i --data "userName=etl_user&password=BadPass#1" -X POST http://$(hostname -f):8885/api/login | grep HttpOnly  | tail -1  )
echo "$cookie" > cookie.txt

#Create shell interpreter setting
curl -b ./cookie.txt -X POST http://$(hostname -f):8885/api/interpreter/setting -d @./shell.json

#Create jdbc interpreter setting
hivejar=$(ls /opt/cloudera/parcels/CDH/jars/hive-jdbc-3*-standalone.jar)
sed -i.bak "s|__hivejar__|${hivejar}|g" ./jdbc.json
curl -b ./cookie.txt -X POST http://$(hostname -f):8885/api/interpreter/setting -d @./jdbc.json

#list all interpreters settings - jdbc and sh should now be added
curl -b ./cookie.txt http://$(hostname -f):8885/api/interpreter/setting | python -m json.tool | grep "id"


#import zeppelin notebooks
cd /var/lib/zeppelin/notebook
mkdir 2EKX5F5MF
cp "/tmp/masterclass/ranger-atlas/Notebooks-CDP/Demos _ Security _ WorldWideBank _ Joe-Analyst.json"  ./2EKX5F5MF/note.json

mkdir 2EMPR5K29
cp "/tmp/masterclass/ranger-atlas/Notebooks-CDP/Demos _ Security _ WorldWideBank _ Ivanna EU HR.json" ./2EMPR5K29/note.json

mkdir 2EKHXD4H3
cp "/tmp/masterclass/ranger-atlas/Notebooks-CDP/Demos _ Security _ WorldWideBank _ etl_user.json" ./2EKHXD4H3/note.json

mkdir 2EZM9PAXV
cp "/tmp/masterclass/ranger-atlas/Notebooks-CDP/Demos _ Hive ACID.json" ./2EZM9PAXV/note.json

mkdir 2EXWA1114
cp "/tmp/masterclass/ranger-atlas/Notebooks-CDP/Demos _ Hive Merge.json" ./2EXWA1114/note.json


chown -R  zeppelin:zeppelin /var/lib/zeppelin/notebook 


echo "-------------------------"
cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
sed -i.bak "s/21000/31000/g" env_atlas.sh
sed -i.bak "s/localhost/${atlas_host}/g" env_atlas.sh
sed -i.bak "s/ATLAS_PASS=admin/ATLAS_PASS=${atlas_pass}/g" env_atlas.sh

./01-atlas-import-classification.sh

./08-create-hbase-kafka-dc.sh

echo "Sleeping for 60s..."
sleep 60
./09-associate-entities-with-tags-dc.sh

export cluster_name=$(curl -X GET -u admin:admin http://localhost:7180/api/v40/clusters/  | jq '.items[0].name' | tr -d '"')

if [ -d "/var/lib/nifi/" ] 
then
    echo "Setting up Nifi / Atlas. cluster_name:${cluster_name} kdc_realm:${kdc_realm} host:${host}"
    cp /tmp/masterclass/ranger-atlas/HortoniaMunichSetup/data/atlas-application.properties /tmp
    sed -i "s/cdp.cloudera.com/${host}/g; s/CLOUDERA.COM/${kdc_realm}/g; s/WWBank/${cluster_name}/g;" /tmp/atlas-application.properties
    chown nifi:nifi /tmp/atlas-application.properties

    cd /var/lib/nifi/
    mv flow.xml.gz flow.xml.gz.orig
    cp /tmp/masterclass/ranger-atlas/HortoniaMunichSetup/data/flow.xml .
    sed -i "s/cdp.cloudera.com/${host}/g; s/CLOUDERA.COM/${kdc_realm}/g; s/WWBank/${cluster_name}/g;" flow.xml
    gzip flow.xml
    chown nifi:nifi flow.xml.gz  

    nifi_keytab=$(find /var/run/cloudera-scm-agent/process/ -name nifi.keytab | tail -1)
    cp ${nifi_keytab} /tmp
    chown nifi:nifi /tmp/nifi.keytab
fi

echo "Setup complete! Restart Zeppelin/NiFi to see imported notebooks/templates"
exit 0

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


#GA build CM configs:
# 1. HDFS > Enable Ranger plugin for HDFS
# 2. HDFS > add etl group to admins by dfs.permissions.superusergroup=etl
# 3. Kafka > offsets.topic.replication.factor = 1
# 4. Hbase > Enable Atlas Hook=true
# 5. Ranger > ranger.tagsync.atlas.hdfs.instance.cm.ranger.service=cm_hdfs
# 6. Hue > auth_backend=desktop.auth.backend.PamBackend
# 7. HDFS > core-site saftey > hadoop.proxyuser.zeppelin.groups=*, hadoop.proxyuser.zeppelin.hosts=*
