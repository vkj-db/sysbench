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

if [[ -z "${db_address}" ]]; then
  echo "db_address is not set"
  exit 1
fi

if [[ -z "${db_password}" ]]; then
  echo "db_password is not set"
  exit 1
fi

db_user="root"
db_port=3306
db_driver="mysql"
table_size=${TABLE_SIZE:-10000000}
tables=${TABLES:-50}
time=${TIME:-60}
report_interval=${REPORT_INTERVAL:-10}

# mode: clean, prepare, run
mode="${MODE:-run}"

# Clean DB
if [[ "${mode}" == "clean" ]]; then
  mysql -h "${db_address}" -P $db_port -u $db_user --password="${db_password}" \
    -e "drop database IF EXISTS sysbench; create database sysbench";
  exit 0
fi

# Prepare DB
if [[ "${mode}" == "prepare" ]]; then
  # Run prepare
  time sysbench --"${db_driver}"-host="${db_address}" --"${db_driver}"-port="${db_port}" --"${db_driver}"-user="${db_user}" --"${db_driver}"-password="${db_password}" --"${db_driver}"-db=sysbench --db-driver="${db_driver}" --table-size="${table_size}" --tables="${tables}" --threads="${tables}" \
  --create-secondary=false \
  oltp_point_select prepare
  exit 0
fi

# Run benchmark
run_bench() {
  time sysbench --"${db_driver}"-host="${db_address}" --"${db_driver}"-port="${db_port}" --"${db_driver}"-user="${db_user}" --"${db_driver}"-password="${db_password}" --"${db_driver}"-db=sysbench --db-driver="${db_driver}" --table-size="${table_size}" --tables="${tables}" --time="${time}" --report-interval="${report_interval}" \
  --threads="$2" "$1" run
}

echo "Benchmark #1: (read) point select"
echo "Threads: 1"
run_bench oltp_point_select 1
echo "Threads: 256"
run_bench oltp_point_select 256

echo "Benchmark #2: (write) batch inserts"
echo "Threads: 1"
run_bench oltp_batch_insert 1
echo "Threads: 256"
run_bench oltp_batch_insert 256

echo "Benchmark #3: (read) batch appends"
echo "Threads: 1"
run_bench oltp_batch_append 1
echo "Threads: 256"
run_bench oltp_batch_append 256

echo "Benchmark #4: (read and write) point select and batch inserts"
echo "Threads: 256"
run_bench oltp_point_select 256 &
run_bench oltp_batch_insert 256 &
wait

echo "Benchmark #5: (read and write) point select and batch appends"
echo "Threads: 256"
run_bench oltp_point_select 256 &
run_bench oltp_batch_append 256 &
wait
