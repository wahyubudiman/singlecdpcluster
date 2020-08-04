import com.hortonworks.hwc.HiveWarehouseSession
import com.hortonworks.hwc.HiveWarehouseSession._
val hive = HiveWarehouseSession.session(spark).build()

hive.execute("SELECT surname, streetaddress, country, age, password, nationalid, ccnumber, mrn, birthday FROM worldwidebank.us_customers").show(10)
hive.execute("select zipcode, insuranceid, bloodtype from worldwidebank.ww_customers").show(10)
hive.execute("select * from cost_savings.claim_savings").show(10)
