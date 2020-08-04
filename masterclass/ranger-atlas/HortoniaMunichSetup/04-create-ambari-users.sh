export ambari_admin=${ambari_admin:-admin}

users="kate_hr ivanna_eu_hr joe_analyst sasha_eu_hr john_finance mark_bizdev jermy_contractor diane_csr log_monitor etl_user demokitadmin"
groups="hr analyst us_employee eu_employee finance business_dev contractor csr etl"
ambari_url="http://${ambari_host}:8080/api/v1"


for user in ${users}; do
  echo "adding user ${user} to Ambari"
  curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d "{\"Users/user_name\":\"${user}\",\"Users/password\":\"${ambari_pass}\",\"Users/active\":\"true\",\"Users/admin\":\"false\"}" ${ambari_url}/users 
done 

echo create groups in Ambari
for group in ${groups}; do
  echo "adding group ${group} to Ambari"
  curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d "{\"Groups/group_name\":\"${group}\"}" ${ambari_url}/groups
done

echo HR group membership
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"kate_hr", "MemberInfo/group_name":"hr"}' ${ambari_url}/groups/hr/members
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"ivanna_eu_hr", "MemberInfo/group_name":"hr"}' ${ambari_url}/groups/hr/members
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"sasha_eu_hr", "MemberInfo/group_name":"hr"}' ${ambari_url}/groups/hr/members


echo analyst group membership
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"joe_analyst", "MemberInfo/group_name":"analyst"}' ${ambari_url}/groups/analyst/members

echo us_employee group membership
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"kate_hr", "MemberInfo/group_name":"us_employee"}' ${ambari_url}/groups/us_employee/members
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"joe_analyst", "MemberInfo/group_name":"us_employee"}' ${ambari_url}/groups/us_employee/members

echo eu_employee group membership
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"ivanna_eu_hr", "MemberInfo/group_name":"eu_employee"}' ${ambari_url}/groups/eu_employee/members
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"sasha_eu_hr", "MemberInfo/group_name":"eu_employee"}' ${ambari_url}/groups/eu_employee/members

echo finance group membership
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"john_finance", "MemberInfo/group_name":"finance"}' ${ambari_url}/groups/finance/members

echo bizdev group membership
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"mark_bizdev", "MemberInfo/group_name":"business_dev"}' ${ambari_url}/groups/business_dev/members

echo contractor group membership
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"jermy_contractor", "MemberInfo/group_name":"contractor"}' ${ambari_url}/groups/contractor/members

echo csr group membership
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"diane_csr", "MemberInfo/group_name":"csr"}' ${ambari_url}/groups/csr/members

echo etl group membership
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"log_monitor", "MemberInfo/group_name":"etl"}' ${ambari_url}/groups/etl/members
curl -u ${ambari_admin}:${ambari_pass} -H "X-Requested-By: blah" -X POST -d '{"MemberInfo/user_name":"etl_user", "MemberInfo/group_name":"etl"}' ${ambari_url}/groups/etl/members
    


#echo add groups to Hive views
#curl -u ${ambari_admin}:${ambari_pass} -i -H "X-Requested-By: blah" -X PUT ${ambari_url}/views/HIVE/versions/1.5.0/instances/AUTO_HIVE_INSTANCE/privileges \
#   --data '[{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"us_employee","principal_type":"GROUP"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"business_dev","principal_type":"GROUP"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"eu_employee","principal_type":"GROUP"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"CLUSTER.ADMINISTRATOR","principal_type":"ROLE"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"CLUSTER.OPERATOR","principal_type":"ROLE"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"SERVICE.OPERATOR","principal_type":"ROLE"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"SERVICE.ADMINISTRATOR","principal_type":"ROLE"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"CLUSTER.USER","principal_type":"ROLE"}}]'

#curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: blah' -X PUT ${ambari_url}/views/HIVE/versions/2.0.0/instances/AUTO_HIVE20_INSTANCE/privileges \
#   --data '[{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"us_employee","principal_type":"GROUP"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"business_dev","principal_type":"GROUP"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"eu_employee","principal_type":"GROUP"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"CLUSTER.ADMINISTRATOR","principal_type":"ROLE"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"CLUSTER.OPERATOR","principal_type":"ROLE"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"SERVICE.OPERATOR","principal_type":"ROLE"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"SERVICE.ADMINISTRATOR","principal_type":"ROLE"}},{"PrivilegeInfo":{"permission_name":"VIEW.USER","principal_name":"CLUSTER.USER","principal_type":"ROLE"}}]'

#give demo users administrator rights in Ambari
curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: blah' -X PUT -d '{"Users" : {"admin" : "true"}}' ${ambari_url}/users/demokitadmin
curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: blah' -X PUT -d '{"Users" : {"admin" : "true"}}' ${ambari_url}/users/joe_analyst
curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: blah' -X PUT -d '{"Users" : {"admin" : "true"}}' ${ambari_url}/users/ivanna_eu_hr
curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: blah' -X PUT -d '{"Users" : {"admin" : "true"}}' ${ambari_url}/users/etl_user
curl -u ${ambari_admin}:${ambari_pass} -i -H 'X-Requested-By: blah' -X PUT -d '{"Users" : {"admin" : "true"}}' ${ambari_url}/users/scott_intern

