# Setup Hortoniabank demo on HDP 2.6.4 Cloudbreak
# Pre-reqs:
# HDP cluster with Hive LLAP/Ranger/Atlas already installed via cloudbreak
# 1. Install Zeppelin if not already installed
# 2. Ranger admin user with known credentials (or create your own) e.g. ali/Hadoop123
#
# TODOs: kafka/hbase policies not created? LLAP?
#
# Steps:
# SSH in to Ambari node as root and run below:
# curl -sSL https://raw.githubusercontent.com/abajwa-hw/masterclass/master/ranger-atlas/setup_cdb.sh | sudo -E sh

#Ambari admin password - replace with your own
export ambari_admin=admin1
export ambari_pass=Horton\!#works

#Ranger admin user credentials - replace with your own
export ranger_admin_user=admin
export ranger_admin_password=admin


#Choose password for Zeppelin users
export zeppelin_pass=BadPass#1

#whether to enable Hive ACID/transactions
export enable_hive_acid=${enable_hive_acid:-true}   

#where to enable kerberos
export enable_kerberos=${enable_kerberos:-false}   

#choose kerberos realm (if kerberos enabled)
export kdc_realm=HWX.COM

export ambari_host=$(hostname -f)


echo "####### Detect hosts.."
#detect name of cluster
output=`curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: ambari'  http://${ambari_host}:8080/api/v1/clusters`
export cluster_name=`echo $output | sed -n 's/.*"cluster_name" : "\([^\"]*\)".*/\1/p'`

export ranger_host=$(curl -u ${ambari_admin}:${ambari_pass} -X GET http://${ambari_host}:8080/api/v1/clusters/${cluster_name}/services/RANGER/components/RANGER_ADMIN|grep "host_name"|grep -Po ': "([a-zA-Z0-9\-_!?.]+)'|grep -Po '([a-zA-Z0-9\-_!?.]+)')

export hiveserver_host=$(curl -u ${ambari_admin}:${ambari_pass} -X GET http://${ambari_host}:8080/api/v1/clusters/${cluster_name}/services/HIVE/components/HIVE_SERVER|grep "host_name"|grep -Po ': "([a-zA-Z0-9\-_!?.]+)'|grep -Po '([a-zA-Z0-9\-_!?.]+)')

export kafka_broker=$(curl -u ${ambari_admin}:${ambari_pass} -X GET http://${ambari_host}:8080/api/v1/clusters/${cluster_name}/services/KAFKA/components/KAFKA_BROKER |grep "host_name"|grep -Po ': "([a-zA-Z0-9\-_!?.]+)'|grep -Po '([a-zA-Z0-9\-_!?.]+)')

export atlas_host=$(curl -u ${ambari_admin}:${ambari_pass} -X GET http://${ambari_host}:8080/api/v1/clusters/${cluster_name}/services/ATLAS/components/ATLAS_SERVER|grep "host_name"|grep -Po ': "([a-zA-Z0-9\-_!?.]+)'|grep -Po '([a-zA-Z0-9\-_!?.]+)')

       	

#detect hive port from transport mode
hive_transport_mode=$(/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a get -c hive-site | grep  hive.server2.transport.mode | grep -Po ': "([a-zA-Z]+)'|grep -Po '([a-zA-Z]+)')
if [ ${hive_transport_mode} == "http" ]; then
     export hiveserver_port=10001
     export hiveserver_url="jdbc:hive2://${hiveserver_host}:${hiveserver_port}/;transportMode=http;httpPath=cliservice"
else
     export hiveserver_port=10000
     export hiveserver_url="jdbc:hive2://${hiveserver_host}:${hiveserver_port}/"     
fi


#ranger_curl="curl -u admin:${ambari_pass}"
ranger_curl="curl -u ${ranger_admin_user}:${ranger_admin_password}"
ranger_url="http://${ranger_host}:6080/service"

echo "Testing ranger credentials..."
if [ $(${ranger_curl} ${ranger_url}/public/v2/api/servicedef/name/hive | grep -Po 401) ]; then
    echo "Invalid combination of ranger user or pass for user: ${ranger_admin_user}"
    exit 1
else
    echo "Ranger credentials succeeded"
fi



#make sure Ambari is up
while ! echo exit | nc ${ambari_host} 8080; do echo "waiting for Ambari to come up..."; sleep 10; done



echo "####### Download demo script and create local users ..."
cd /tmp
git clone https://github.com/abajwa-hw/masterclass  





cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
chmod +x *.sh

#Disabling creating local users as these will come from LDAP
#./04-create-os-users.sh    
#useradd ANONYMOUS    
    
echo "####### Configure cluster for demo..."




echo # Ranger config changes

#echo Enable kafka plugin for Ranger 
#/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c ranger-env -k ranger-kafka-plugin-enabled -v Yes
#/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c ranger-kafka-plugin-properties -k ranger-kafka-plugin-enabled -v Yes

#echo Enable Hbase plugin for Ranger 
#/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c ranger-env -k ranger-hbase-plugin-enabled -v Yes
#/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c ranger-hbase-plugin-properties -k ranger-hbase-plugin-enabled -v Yes

#disabling above as seems on CB envs the above plugins are already setup

echo Ranger tagsync mappings
/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c ranger-tagsync-site -k ranger.tagsync.atlas.hdfs.instance.cl1.ranger.service -v ${cluster_name}_hadoop
/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c ranger-tagsync-site -k ranger.tagsync.atlas.hdfs.instance.hdp.ranger.service -v ${cluster_name}_hadoop
/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c ranger-tagsync-site -k ranger.tagsync.atlas.hive.instance.hdp.ranger.service -v ${cluster_name}_hive
/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c ranger-tagsync-site -k ranger.tagsync.atlas.hbase.instance.cl1.ranger.service -v ${cluster_name}_hbase
/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c ranger-tagsync-site -k ranger.tagsync.atlas.kafka.instance.cl1.ranger.service -v ${cluster_name}_kafka


#echo Ranger setup Unix sync
#/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c ranger-ugsync-site -k ranger.usersync.source.impl.class -v org.apache.ranger.unixusersync.process.UnixUserGroupBuilder


echo stop Ranger
curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop RANGER via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://${ambari_host}:8080/api/v1/clusters/${cluster_name}/services/RANGER
while echo exit | nc ${ranger_host} 6080; do echo "waiting for Ranger to go down..."; sleep 10; done
sleep 10

echo start Ranger
curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start RANGER via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://${ambari_host}:8080/api/v1/clusters/${cluster_name}/services/RANGER


echo wait until ranger comes up
while ! echo exit | nc ${ranger_host} 6080; do echo "waiting for Ranger to come up..."; sleep 10; done


echo Change Hive doAs setting 
/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.server2.enable.doAs  -v true


if [ "${enable_hive_acid}" = true  ]; then
	/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c hive-env -k hive_txn_acid -v on
	/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.support.concurrency -v true
	/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.compactor.initiator.on -v true
	/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.compactor.worker.threads -v 1
	/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.enforce.bucketing -v true
	/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.exec.dynamic.partition.mode -v nonstrict
	/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.txn.manager -v org.apache.hadoop.hive.ql.lockmgr.DbTxnManager
fi


echo restart Hive

curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop HIVE via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://${ambari_host}:8080/api/v1/clusters/${cluster_name}/services/HIVE
while echo exit | nc ${hiveserver_host} ${hiveserver_port}; do echo "waiting for Hive to go down..."; sleep 10; done
while echo exit | nc ${hiveserver_host} 50111; do echo "waiting for Hcat to go down..."; sleep 10; done
sleep 15
curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start HIVE via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://${ambari_host}:8080/api/v1/clusters/${cluster_name}/services/HIVE


echo wait until hive comes up
while ! echo exit | nc ${hiveserver_host} ${hiveserver_port}; do echo "waiting for Hive to come up..."; sleep 10; done


echo Set Kafka replication factor to 1
/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c kafka-broker -k offsets.topic.replication.factor -v 1


echo stop kafka
curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop KAFKA via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://${ambari_host}:8080/api/v1/clusters/${cluster_name}/services/KAFKA
while echo exit | nc ${kafka_broker} 6667; do echo "waiting for Kafka to go down..."; sleep 10; done
sleep 10

echo start kafka
curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start KAFKA via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://${ambari_host}:8080/api/v1/clusters/${cluster_name}/services/KAFKA


echo wait until kafka comes up
while ! echo exit | nc ${kafka_broker} 6667; do echo "waiting for Kafka to come up..."; sleep 10; done



echo ###### Start HortoniaBank demo setup


cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
./04-create-ambari-users.sh


echo pull latest notebooks
curl -sSL https://raw.githubusercontent.com/hortonworks-gallery/zeppelin-notebooks/master/update_all_notebooks.sh | sudo -E sh 

sudo -u zeppelin hdfs dfs -rmr /user/zeppelin/notebook/*
sudo -u zeppelin hdfs dfs -put /usr/hdp/current/zeppelin-server/notebook/* /user/zeppelin/notebook/

echo disable anonymous login and create Hortonia users
cat << EOF > /tmp/zeppelin-env.json
{
  "properties": {
    "shiro_ini_content": "\n [users]\n etl_user = ${zeppelin_pass},admin\n ivanna_eu_hr = ${zeppelin_pass}, admin\n log_monitor = ${zeppelin_pass}, admin\n joe_analyst = ${zeppelin_pass}, admin\n \n \n [main]\n sessionManager = org.apache.shiro.web.session.mgt.DefaultWebSessionManager\n cacheManager = org.apache.shiro.cache.MemoryConstrainedCacheManager\n securityManager.cacheManager = \$cacheManager\n cookie = org.apache.shiro.web.servlet.SimpleCookie\n cookie.name = JSESSIONID\n cookie.httpOnly = true\n sessionManager.sessionIdCookie = \$cookie\n securityManager.sessionManager = \$sessionManager\n securityManager.sessionManager.globalSessionTimeout = 86400000\n shiro.loginUrl = /api/login\n \n [roles]\n role1 = *\n role2 = *\n role3 = *\n admin = *\n \n [urls]\n /api/version = anon\n #/** = anon\n /** = authc\n \n"
  }
}
EOF

/var/lib/ambari-server/resources/scripts/configs.py -u ${ambari_admin} -p ${ambari_pass} --host ${ambari_host} --port 8080 --cluster ${cluster_name} -a set -c zeppelin-shiro-ini -f /tmp/zeppelin-env.json
sleep 5


#disabling below as CB now has LLAP and below steps will kill LLAP

#echo kill any previous Hive/tez apps to clear queue
#for app in $(yarn application -list | awk '$2==hive && $3==TEZ && $6 == "ACCEPTED" || $6 == "RUNNING" { print $1 }')
#do 
#    yarn application -kill  "$app"
#done


echo make sure Ranger up
while ! echo exit | nc ${ranger_host} 6080; do echo "waiting for Ranger to come up..."; sleep 10; done

echo update ranger to support deny policies


sudo yum install -y jq

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


#create tag service repo in Ranger called tags
${ranger_curl} ${ranger_url}/public/v2/api/service -X POST  -H "Content-Type: application/json"  -d @- <<EOF
{
  "name":"tags",
  "description":"tags service from API",
  "type": "tag",
  "configs":{},
  "isActive":true
}
EOF

#associate tag service with Hive/Hbase/Kafka Ranger repos 
for component in hive hbase kafka ; do
  echo "Associating tags service with Ranger $component repo..."
  ${ranger_curl} ${ranger_url}/public/v2/api/service | jq ".[] | select (.type==\"${component}\")"  > tmp.json
  cat tmp.json | jq '. |= .+  {"tagService":"tags"}' > tmp-updated.json
  ${ranger_curl} ${ranger_url}/public/v2/api/service/name/${cluster_name}_${component} -X PUT  -H "Content-Type: application/json"  -d @tmp-updated.json
done 


cd /tmp/masterclass/ranger-atlas/Scripts/
echo "importing ranger Tag policies.."
< ranger-policies-tags.json jq '.policies[].service = "tags"' > ranger-policies-tags_apply.json
${ranger_curl} -X POST \
-H "Content-Type: multipart/form-data" \
-H "Content-Type: application/json" \
-F 'file=@ranger-policies-tags_apply.json' \
         "${ranger_url}/plugins/policies/importPoliciesFromFile?isOverride=true&serviceType=tag"

              
echo "import ranger Hive policies..."
< ranger-policies-enabled.json jq '.policies[].service = "'${cluster_name}'_hive"' > ranger-policies-apply.json
${ranger_curl} -X POST \
-H "Content-Type: multipart/form-data" \
-H "Content-Type: application/json" \
-F 'file=@ranger-policies-apply.json' \
          "${ranger_url}/plugins/policies/importPoliciesFromFile?isOverride=true&serviceType=hive"

echo "import ranger HDFS policies..." #to give hive access to /hive_data HDFS dir
< ranger-hdfs-policies.json jq '.policies[].service = "'${cluster_name}'_hadoop"' > ranger-hdfs-policies-apply.json
${ranger_curl} -X POST \
-H "Content-Type: multipart/form-data" \
-H "Content-Type: application/json" \
-F 'file=@ranger-hdfs-policies-apply.json' \
          "${ranger_url}/plugins/policies/importPoliciesFromFile?isOverride=true&serviceType=hdfs"

#TODO: Kafka repo not present even though plugin enabled
echo "import ranger kafka policies..." #  to give ANONYMOUS access to kafka or Atlas won't work
< ranger-kafka-policies.json jq '.policies[].service = "'${cluster_name}'_kafka"' > ranger-kafka-policies-apply.json
${ranger_curl} -X POST \
-H "Content-Type: multipart/form-data" \
-H "Content-Type: application/json" \
-F 'file=@ranger-kafka-policies-apply.json' \
          "${ranger_url}/plugins/policies/importPoliciesFromFile?isOverride=true&serviceType=kafka"

         
echo "import ranger hbase policies..."
< ranger-hbase-policies.json jq '.policies[].service = "'${cluster_name}'_hbase"' > ranger-hbase-policies-apply.json
${ranger_curl} -X POST \
-H "Content-Type: multipart/form-data" \
-H "Content-Type: application/json" \
-F 'file=@ranger-hbase-policies-apply.json' \
         "${ranger_url}/plugins/policies/importPoliciesFromFile?isOverride=true&serviceType=hbase"




cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup

sed -i.bak "s/localhost:6080/${ranger_host}:6080/g" env_ranger.sh
sed -i.bak "s/RANGER_ADMIN_USER=admin/RANGER_ADMIN_USER=${ranger_admin_user}/g" env_ranger.sh
sed -i.bak "s/RANGER_ADMIN_PASS=admin/RANGER_ADMIN_PASS=${ranger_admin_password}/g" env_ranger.sh

sed -i.bak "s/localhost:21000/${atlas_host}:21000/g" env_atlas.sh

./01-atlas-import-classification.sh
#./02-atlas-import-entities.sh      ## this gives 500 error so moving to end
#./03-update-servicedefs.sh

        
cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
su hdfs -c ./05-create-hdfs-user-folders.sh
su hdfs -c ./06-copy-data-to-hdfs.sh

echo make sure hive is up
while ! echo exit | nc ${hiveserver_host} ${hiveserver_port}; do echo "waiting for hive to come up..."; sleep 10; done

#./07-create-hive-schema.sh
beeline -u ${hiveserver_url} -n hive -f data/HiveSchema.hsql

if [ "${enable_hive_acid}" = true  ]; then
  beeline -u ${hiveserver_url} -n hive -f data/TransSchema.hsql
fi

#disabling kerberos on DPS
#if [ "${enable_kerberos}" = true  ]; then           
#  ./08-enable-kerberos.sh
#fi


echo make sure Atlas/Hive are up
while ! echo exit | nc ${atlas_host} 21000; do echo "waiting for atlas to come up..."; sleep 10; done



#echo "import Atlas entities"
#yum install -y zip
#if [ "${cluster_name}" != "hdp" ]; then
#   echo "Creating new entities zip based on cluster name ${cluster_name} ..."
#   cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup/data
#   mkdir tmp
#   mv export-hive_db-name.zip export-hive_db-name.orig.zip
#   unzip export-hive_db-name.orig.zip -d ./tmp
#   cd ./tmp
#   find . -name '*' -type f -exec sed -i "s/hdp/${cluster_name}/g" {} \;
#   zip -r export-hive_db-name.zip .
#   mv export-hive_db-name.zip ..
#fi

#echo "Importing entities ..."
#cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
#./02-atlas-import-entities.sh
# Need to do this twice due to bug: RANGER-1897 
# second time, the notification is of type ENTITY_UPDATE which gets processed correctly
#./02-atlas-import-entities.sh


cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
./08-create-hbase-kafka.sh

./09-associate-entities-with-tags.sh



echo "Automated portion of setup is complete, next please create the tag repo in Ranger, associate with Hive and import tag policies"
echo "See https://github.com/abajwa-hw/masterclass/blob/master/ranger-atlas/README.md for more details"
echo "Once complete, see here for walk through of demo: https://community.hortonworks.com/articles/151939/hdp-securitygovernance-demo-kit.html"
