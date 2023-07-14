#!/bin/bash

set -e -x

# Just run the following replacing the values for db_address, db_password:
#
#sudo docker rm -f tidb_benchmark && \
#sudo docker run --name tidb_benchmark -i \
#  -e db_address=<db-address>  \
#  -e db_password='<db-password>' \
#  -t vikasjain353/sysbench-fork
#
# NOTE: This script assumes that the db is already created and populated with data.

db_user="root"
db_port=3306
db_driver="mysql"

if [[ -z "${TABLE_SIZE}" ]]; then
  table_size=10000000
else
  table_size="${TABLE_SIZE}"
fi

if [[ -z "${TABLES}" ]]; then
  tables=50
else
  tables="${TABLES}"
fi

if [[ -z "${TIME}" ]]; then
  time=60
else
  time="${TIME}"
fi

if [[ -z "${REPORT_INTERVAL}" ]]; then
  report_interval=10
else
  report_interval="${REPORT_INTERVAL}"
fi

# mode: prepare or run
mode="${MODE:-run}"

# if condition for mode == prepare
if [[ "${mode}" == "prepare" ]]; then
  # Run prepare
  sysbench --"${db_driver}"-host="${db_address}" --"${db_driver}"-port="${db_port}" --"${db_driver}"-user="${db_user}" --"${db_driver}"-password="${db_password}" --"${db_driver}"-db=sysbench --db-driver="${db_driver}" --table-size="${table_size}" --tables="${tables}" --time="${time}" --report-interval="${report_interval}" --threads="${tables}" \
  --create-secondary=false \
  oltp_point_select prepare
  exit 0
fi

run_bench() {
  sysbench --"${db_driver}"-host="${db_address}" --"${db_driver}"-port="${db_port}" --"${db_driver}"-user="${db_user}" --"${db_driver}"-password="${db_password}" --"${db_driver}"-db=sysbench --db-driver="${db_driver}" --table-size="${table_size}" --tables="${tables}" --time="${time}" --report-interval="${report_interval}" \
  --threads="$2" "$1" run
}

run_bench oltp_point_select 1
run_bench oltp_point_select 256

run_bench oltp_batch_insert 1
run_bench oltp_batch_insert 256