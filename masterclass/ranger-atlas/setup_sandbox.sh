# Setup Hortoniabank demo on HDP 2.6.4 sandbox
# Reset Ambari admin password, SSH in as root and run below:
# curl -sSL https://raw.githubusercontent.com/abajwa-hw/masterclass/master/ranger-atlas/setup_sandbox.sh | sudo -E sh

#Ambari admin password - replace with your own
export ambari_pass=${ambari_pass:-BadPass#1} 

#Choose password for Zeppelin users
export zeppelin_pass=BadPass#1

#choose kerberos realm
export kdc_realm=HWX.COM

export enable_kerberos=${enable_kerberos:-true}   
export enable_hive_acid=${enable_hive_acid:-true} 

export host=$(hostname -f)
export ambari_host=$(hostname -f)

#make sure Ambari is up
while ! echo exit | nc ${host} 8080; do echo "waiting for Ambari to come up..."; sleep 10; done


#detect name of cluster
output=`curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari'  http://${host}:8080/api/v1/clusters`
cluster_name=`echo $output | sed -n 's/.*"cluster_name" : "\([^\"]*\)".*/\1/p'`

echo "####### Download demo script and create local users ..."
cd /tmp
git clone https://github.com/abajwa-hw/masterclass  

cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
chmod +x *.sh
./04-create-os-users.sh    
useradd ANONYMOUS    
    
echo "####### Configure cluster for demo..."

echo stop Flume, oozie, spark2 and put in maintenance mode
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop FALCON via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/FLUME
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop OOZIE via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/OOZIE
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop SPARK2 via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/SPARK2
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Flume maintenance mode"}, "Body": {"ServiceInfo": {"maintenance_state": "ON"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/FLUME
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"OOZIE maintenance mode"}, "Body": {"ServiceInfo": {"maintenance_state": "ON"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/OOZIE
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"SPARK2 maintenance mode"}, "Body": {"ServiceInfo": {"maintenance_state": "ON"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/SPARK2

while echo exit | nc ${host} 18081; do echo "waiting for Spark2 to go down..."; sleep 10; done



echo make sure kafka, hbase, ambari infra, atlas, HDFS are out of maintenance mode
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Remove Kafka from maintenance mode"}, "Body": {"ServiceInfo": {"maintenance_state": "OFF"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/KAFKA
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Remove Hbase from maintenance mode"}, "Body": {"ServiceInfo": {"maintenance_state": "OFF"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/HBASE
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Remove Ambari Infra from maintenance mode"}, "Body": {"ServiceInfo": {"maintenance_state": "OFF"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/AMBARI_INFRA
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Remove Atlas from maintenance mode"}, "Body": {"ServiceInfo": {"maintenance_state": "OFF"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/ATLAS
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Remove HDFS from maintenance mode"}, "Body": {"ServiceInfo": {"maintenance_state": "OFF"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/HDFS

echo # Ranger config changes

echo Enable kafka plugin for Ranger 
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-env -k ranger-kafka-plugin-enabled -v Yes
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-kafka-plugin-properties -k ranger-kafka-plugin-enabled -v Yes

echo enable Audits for Ranger
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-env -k xasecure.audit.destination.solr -v true

echo enable other plugin audits
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-hdfs-audit -k xasecure.audit.destination.solr -v true
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-atlas-audit -k xasecure.audit.destination.solr -v true
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-kafka-audit -k xasecure.audit.destination.solr -v true
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-hbase-audit -k xasecure.audit.destination.solr -v true

echo Ranger tagsync mappings
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-tagsync-site -k ranger.tagsync.atlas.hdfs.instance.cl1.ranger.service -v ${cluster_name}_hadoop
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-tagsync-site -k ranger.tagsync.atlas.hdfs.instance.hdp.ranger.service -v ${cluster_name}_hadoop
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-tagsync-site -k ranger.tagsync.atlas.hive.instance.hdp.ranger.service -v ${cluster_name}_hive
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-tagsync-site -k ranger.tagsync.atlas.hbase.instance.cl1.ranger.service -v ${cluster_name}_hbase
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-tagsync-site -k ranger.tagsync.atlas.kafka.instance.cl1.ranger.service -v ${cluster_name}_kafka


echo Set Kafka replication factor to 1
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c kafka-broker -k offsets.topic.replication.factor -v 1


echo stop Ranger
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop RANGER via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/RANGER
while echo exit | nc ${host} 6080; do echo "waiting for Ranger to go down..."; sleep 10; done
sleep 10

echo start Ranger
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start RANGER via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/RANGER

#curl  -u admin:${ambari_pass} -H "X-Requested-By: ambari" -X POST  -d '{"RequestInfo":{"command":"RESTART","context":"Restart all required services","operation_level":"host_component"},"Requests/resource_filters":[{"hosts_predicate":"HostRoles/stale_configs=true"}]}' http://${host}:8080/api/v1/clusters/${cluster_name}/requests
#sleep 20


echo wait until ranger comes up
while ! echo exit | nc ${host} 6080; do echo "waiting for Ranger to come up..."; sleep 10; done


echo Change Hive doAs setting and enable audits
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.server2.enable.doAs  -v true
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c ranger-hive-audit -k xasecure.audit.destination.solr -v true

if [ "${enable_hive_acid}" = true  ]; then
    echo "enabling Hive ACID..."
	/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c hive-env -k hive_txn_acid -v on
	/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.support.concurrency -v true
	/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.compactor.initiator.on -v true
	/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.compactor.worker.threads -v 1
	/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.enforce.bucketing -v true
	/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.exec.dynamic.partition.mode -v nonstrict
	/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c hive-site -k hive.txn.manager -v org.apache.hadoop.hive.ql.lockmgr.DbTxnManager
fi


echo restart Hive

curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop HIVE via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/HIVE
while echo exit | nc ${host} 10000; do echo "waiting for Hive to go down..."; sleep 10; done
while echo exit | nc ${host} 50111; do echo "waiting for Hcat to go down..."; sleep 10; done
sleep 15
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start HIVE via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/HIVE


echo Start Kafka, HBase, Ambari infra, Atlas
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start KAFKA via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/KAFKA
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start HBASE via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/HBASE
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start Ambari infra via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/AMBARI_INFRA
curl -u admin:${ambari_pass} -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start Atlas via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://${host}:8080/api/v1/clusters/${cluster_name}/services/ATLAS

echo wait until atlas come up
while ! echo exit | nc ${host} 21000; do echo "waiting for atlas to come up..."; sleep 10; done


#note needed: if collection missing, create it: https://community.hortonworks.com/articles/90168/modifying-ranger-audit-solr-config.html
#/usr/lib/ambari-infra-solr-client/solrCloudCli.sh --zookeeper-connect-string ${host}:2181/infra-solr --check-config --config-set ranger_audits
#/usr/lib/ambari-infra-solr-client/solrCloudCli.sh --zookeeper-connect-string  ${host}:2181/infra-solr --upload-config --config-dir /usr/hdp/current/ranger-admin/contrib/solr_for_audit_setup/conf --config-set ranger_audits 
#/usr/lib/ambari-infra-solr-client/solrCloudCli.sh --zookeeper-connect-string ${host}:2181/infra-solr --create-collection --collection ranger_audits --config-set ranger_audits --shards 1 --replication 1 --max-shards 1 --retry 5 --interval 10


echo ###### Start HortoniaBank demo setup

cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
./04-create-ambari-users.sh


echo pull latest notebooks
curl -sSL https://raw.githubusercontent.com/hortonworks-gallery/zeppelin-notebooks/master/update_all_notebooks.sh | sudo -E sh 

echo make sure HDFS is up
while ! echo exit | nc ${host} 50070; do echo "waiting for HDFS to come up..."; sleep 10; done

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

/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host ${host} --port 8080 --cluster ${cluster_name} -a set -c zeppelin-shiro-ini -f /tmp/zeppelin-env.json
sleep 5


echo make sure YARN up
while ! echo exit | nc ${host} 8088; do echo "waiting for YARN to come up..."; sleep 10; done

echo kill any previous Hive/tez apps to clear queue
for app in $(yarn application -list | awk '$2==hive && $3==TEZ && $6 == "ACCEPTED" || $6 == "RUNNING" { print $1 }')
do 
    yarn application -kill  "$app"
done


echo make sure Ranger up
while ! echo exit | nc ${host} 6080; do echo "waiting for Ranger to come up..."; sleep 10; done

echo update ranger to support deny policies
ranger_curl="curl -u admin:admin"
ranger_url="http://${host}:6080/service"


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

./01-atlas-import-classification.sh
#./02-atlas-import-entities.sh      ## this gives 500 error so moving to end
#./03-update-servicedefs.sh

        
cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup
su hdfs -c ./05-create-hdfs-user-folders.sh
su hdfs -c ./06-copy-data-to-hdfs.sh

if [ "${enable_kerberos}" = true  ]; then           
  echo "Enabling kerberos..."
  ./08-enable-kerberos.sh     
fi

echo make sure hive is up
while ! echo exit | nc ${host} 10000; do echo "waiting for hive to come up..."; sleep 10; done
while ! echo exit | nc localhost 50111; do echo "waiting for hcat to come up..."; sleep 10; done

sleep 30

#kill any previous Hive/tez apps to clear queue before creating tables

if [ "${enable_kerberos}" = true  ]; then
  kinit -kVt /etc/security/keytabs/rm.service.keytab rm/$(hostname -f)@${kdc_realm}
fi    
#kill any previous Hive/tez apps to clear queue before hading cluster to end user
for app in $(yarn application -list | awk '$2==hive && $3==TEZ && $6 == "ACCEPTED" || $6 == "RUNNING" { print $1 }')
do 
	yarn application -kill  "$app"
done    

	
#create tables
	
if [ "${enable_kerberos}" = true  ]; then
   ./07-create-hive-schema-kerberos.sh
else
   ./07-create-hive-schema.sh        
fi     

if [ "${enable_kerberos}" = true  ]; then
  kinit -kVt /etc/security/keytabs/rm.service.keytab rm/$(hostname -f)@${kdc_realm}
fi    
#kill any previous Hive/tez apps to clear queue before hading cluster to end user
for app in $(yarn application -list | awk '$2==hive && $3==TEZ && $6 == "ACCEPTED" || $6 == "RUNNING" { print $1 }')
do 
	yarn application -kill  "$app"
done


cd /tmp/masterclass/ranger-atlas/HortoniaMunichSetup

#create kafka topics and populate data - do it after kerberos to ensure Kafka Ranger plugin enabled
./08-create-hbase-kafka.sh

#import Atlas entities 
./09-associate-entities-with-tags.sh


echo "Automated portion of setup is complete, next please create the tag repo in Ranger, associate with Hive and import tag policies"
echo "See https://github.com/abajwa-hw/masterclass/blob/master/ranger-atlas/README.md for more details"
echo "Once complete, see here for walk through of demo: https://community.hortonworks.com/articles/151939/hdp-securitygovernance-demo-kit.html"
