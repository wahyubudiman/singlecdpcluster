automate_kerberos=${automate_kerberos:-true} #whether to automate kerberos or deploy only KDC

cd /tmp
git clone https://github.com/crazyadmins/useful-scripts.git
cd useful-scripts/ambari/
cat << EOF > ambari.props
CLUSTER_NAME=${cluster_name}
AMBARI_ADMIN_USER=admin
AMBARI_ADMIN_PASSWORD=${ambari_pass}
AMBARI_HOST=$(hostname -f)
KDC_HOST=$(hostname -f)
REALM=${kdc_realm}
KERBEROS_CLIENTS=$(hostname -f)
EOF

cat ambari.props
chmod +x *.sh 

if [ "${automate_kerberos}" = true  ]; then
  ./setup_kerberos.sh 
else
  ./setup_only_kdc.sh
fi

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
kadmin.local -q "xst -k joe_analyst.keytab joe_analyst/$(hostname -f)@${kdc_realm}"    
kadmin.local -q "xst -k log_monitor.keytab log_monitor/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k diane_csr.keytab diane_csr/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k jermy_contractor.keytab jermy_contractor/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k mark_bizdev.keytab mark_bizdev/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k john_finance.keytab john_finance/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k ivanna_eu_hr.keytab ivanna_eu_hr/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k kate_hr.keytab kate_hr/$(hostname -f)@${kdc_realm}"
kadmin.local -q "xst -k etl_user.keytab etl_user/$(hostname -f)@${kdc_realm}" 

mv *.keytab /etc/security/keytabs
