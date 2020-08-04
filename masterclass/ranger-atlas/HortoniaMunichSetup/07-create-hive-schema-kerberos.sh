export kdc_realm=${kdc_realm:-HWX.COM}
export beeline_url="jdbc:hive2://localhost:10000/default;principal=hive/$(hostname -f)@${kdc_realm}"

kinit -kVt /etc/security/keytabs/hive.service.keytab hive/$(hostname -f)@${kdc_realm}
beeline -u ${beeline_url} -f ./data/HiveSchema.hsql

if [ "${enable_hive_acid}" = true  ]; then
  beeline -u ${beeline_url} -n hive -f data/TransSchema.hsql
fi

kdestroy
