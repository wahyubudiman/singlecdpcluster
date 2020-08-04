-- Airlines ORC

create database if not exists airlines_new_orc;
use airlines_new_orc;

create table if not exists airports (
  iata string,
  airport string,
  city string,
  state double,
  country string,
  lat double,
  lon double
)
stored as orc;

load data inpath '__mybucket__/airlines_new_orc.db/airports' into table airports;

create table if not exists airlines (
  code string,
  description string
)
stored as orc;
load data inpath '__mybucket__/airlines_new_orc.db/airlines' into table airlines;

create table if not exists planes (
  tailnum string,
  owner_type string,
  manufacturer string,
  issue_date string,
  model string,
  status string,
  aircraft_type string,
  engine_type string,
  year int
)
stored as orc;
load data inpath '__mybucket__/airlines_new_orc.db/planes' into table planes;

create table if not exists flights (
  month int,
  dayofmonth int,
  dayofweek int,
  deptime  int,
  crsdeptime int,
  arrtime int,
  crsarrtime int,
  uniquecarrier string,
  flightnum int,
  tailnum string,
  actualelapsedtime int,
  crselapsedtime int,
  airtime int,
  arrdelay int,
  depdelay int,
  origin string,
  dest string,
  distance int,
  taxiin int,
  taxiout int,
  cancelled int,
  cancellationcode string,
  diverted string,
  carrierdelay int,
  weatherdelay int,
  nasdelay int,
  securitydelay int,
  lateaircraftdelay int
)
partitioned by (year int)
stored as orc;

load data inpath '__mybucket__/airlines_new_orc.db/flights/year=1995' into table flights partition (year=1995);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=1996' into table flights partition (year=1996);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=1997' into table flights partition (year=1997);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=1998' into table flights partition (year=1998);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=1999' into table flights partition (year=1999);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=2000' into table flights partition (year=2000);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=2001' into table flights partition (year=2001);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=2002' into table flights partition (year=2002);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=2003' into table flights partition (year=2003);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=2004' into table flights partition (year=2004);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=2005' into table flights partition (year=2005);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=2006' into table flights partition (year=2006);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=2007' into table flights partition (year=2007);
load data inpath '__mybucket__/airlines_new_orc.db/flights/year=2008' into table flights partition (year=2008);

-- Airlines Parquet

create database if not exists airlines_new_parquet;
use airlines_new_parquet;

create table if not exists airports (
  iata string,
  airport string,
  city string,
  state double,
  country string,
  lat double,
  lon double
)
stored as parquet
tblproperties ("transactional"="true", "transactional_properties"="insert_only");

load data inpath '__mybucket__/airlines_new_parquet.db/airports' into table airports;

create table if not exists airlines (
  code string,
  description string
)
stored as parquet
tblproperties ("transactional"="true", "transactional_properties"="insert_only");

load data inpath '__mybucket__/airlines_new_parquet.db/airlines' into table airlines;

create table if not exists planes (
  tailnum string,
  owner_type string,
  manufacturer string,
  issue_date string,
  model string,
  status string,
  aircraft_type string,
  engine_type string,
  year int
)
stored as parquet
tblproperties ("transactional"="true", "transactional_properties"="insert_only");

load data inpath '__mybucket__/airlines_new_parquet.db/planes' into table planes;

create table if not exists flights (
  month int,
  dayofmonth int,
  dayofweek int,
  deptime  int,
  crsdeptime int,
  arrtime int,
  crsarrtime int,
  uniquecarrier string,
  flightnum int,
  tailnum string,
  actualelapsedtime int,
  crselapsedtime int,
  airtime int,
  arrdelay int,
  depdelay int,
  origin string,
  dest string,
  distance int,
  taxiin int,
  taxiout int,
  cancelled int,
  cancellationcode string,
  diverted string,
  carrierdelay int,
  weatherdelay int,
  nasdelay int,
  securitydelay int,
  lateaircraftdelay int
)
partitioned by (year int)
stored as parquet;

load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=1995' into table flights partition (year=1995);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=1996' into table flights partition (year=1996);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=1997' into table flights partition (year=1997);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=1998' into table flights partition (year=1998);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=1999' into table flights partition (year=1999);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=2000' into table flights partition (year=2000);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=2001' into table flights partition (year=2001);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=2002' into table flights partition (year=2002);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=2003' into table flights partition (year=2003);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=2004' into table flights partition (year=2004);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=2005' into table flights partition (year=2005);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=2006' into table flights partition (year=2006);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=2007' into table flights partition (year=2007);
load data inpath '__mybucket__/airlines_new_parquet.db/flights/year=2008' into table flights partition (year=2008);

