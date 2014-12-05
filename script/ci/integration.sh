#!/bin/bash

export RAILS_ENV=integration

if [ "$HOSTNAME" = chorus-ci ]; then
  export GPDB_HOST=chorus-gpdb-ci
  export ORACLE_HOST=chorus-oracle
  export HAWQ_HOST=chorus-gphd20-2
  export HADOOP_HOST=chorus-gphd11
fi

. script/ci/setup.sh

set -e

b/rake assets:precompile

# start solr
b/rake services:solr:run > $WORKSPACE/solr.log 2>&1 &
solr_pid=$!
echo "Solr process id is : $solr_pid"
echo $solr_pid > tmp/pids/solr-$RAILS_ENV.pid
sleep 20

set +e

echo "Running integration tests"
b/rake -f `bundle show ci_reporter`/stub.rake ci:setup:rspecdoc spec:chorus_integration --trace 2>&1
INTEGRATION_TESTS_RESULT=$?

echo "Cleaning up solr process $solr_pid"
kill -s SIGTERM $solr_pid

echo "Cleaning assets"
b/rake assets:clean

echo "RSpec exit code: $INTEGRATION_TESTS_RESULT"
exit $INTEGRATION_TESTS_RESULT
