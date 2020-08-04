#!/usr/bin/env bash
export cluster_name=$1
export ambari_pass=$2
export providerUrl=$3

yum -y -q install crudini

#update zeppelin configs to include ivanna/joe/diane users
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host localhost --port 8080 --cluster ${cluster_name} -a get -c zeppelin-shiro-ini \
| sed -e "1,2d" \
| sed -e 's/ //g' \
| python -c "import sys, json; print json.load(sys.stdin)['properties']['shiro_ini_content']" > /tmp/zeppelin-shiro.ini

cp /tmp/knox.cert /etc/zeppelin/conf/knox-sso.pem
chown zeppelin:zeppelin /etc/zeppelin/conf/knox-sso.pem

#Delete in user section from ini
crudini --del /tmp/zeppelin-shiro.ini users

#Setup other required details

sed -i "/main/c [main]\nknoxJwtRealm = org.apache.zeppelin.realm.jwt.KnoxJwtRealm\nknoxJwtRealm.providerUrl = $providerUrl\nknoxJwtRealm.login = gateway/knoxsso/knoxauth/login.html\nknoxJwtRealm.logout = gateway/knoxssout/api/v1/webssout\nknoxJwtRealm.logoutAPI = true\nknoxJwtRealm.redirectParam = originalUrl\nknoxJwtRealm.cookieName = hadoop-jwt\nknoxJwtRealm.publicKeyPath = /etc/zeppelin/conf/knox-sso.pem\nknoxJwtRealm.groupPrincipalMapping = group.principal.mapping\nknoxJwtRealm.principalMapping = principal.mapping\nauthc = org.apache.zeppelin.realm.jwt.KnoxAuthenticationFilter\n" /tmp/zeppelin-shiro.ini

cat <<EOF > convert-zeppelin-shiro-ini-to-json.py
import json;
with open('/tmp/zeppelin-shiro.ini', 'r') as myfile:
    content=myfile.read();

data={};
data['properties']={}
data['properties']['shiro_ini_content']=content;
json_data=json.dumps(data);
print json_data
EOF

python convert-zeppelin-shiro-ini-to-json.py > /tmp/zepplin-shiro-ini.json

/var/lib/ambari-server/resources/scripts/configs.py -u admin -p ${ambari_pass} --host localhost --port 8080 --cluster ${cluster_name} -a set -c zeppelin-shiro-ini -f /tmp/zepplin-shiro-ini.json

hostname=$(hostname -f)
#restart Zeppelin
sudo curl -u admin:${ambari_pass} -H 'X-Requested-By: blah' -X POST -d "
{
\"RequestInfo\":{
  \"command\":\"RESTART\",
  \"context\":\"Restart Zeppelin\",
  \"operation_level\":{
	 \"level\":\"HOST\",
	 \"cluster_name\":\"${cluster_name}\"
  }
},
\"Requests/resource_filters\":[
  {
	 \"service_name\":\"ZEPPELIN\",
	 \"component_name\":\"ZEPPELIN_MASTER\",
	 \"hosts\":\"${hostname}\"
  }
]
}" http://localhost:8080/api/v1/clusters/${cluster_name}/requests  

echo "Sleeping for 20s..."
sleep 20
