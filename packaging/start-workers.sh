#!/usr/bin/env bash
bin=`readlink "$0"`
if [ "$bin" == "" ]; then
 bin=$0
fi
bin=`dirname "$bin"`
bin=`cd "$bin"; pwd`

. "$bin"/chorus-config.sh

STARTING="worker"
depends_on postgres

if [ -f $WORKER_PID_FILE ]; then
  if kill -0 `cat $WORKER_PID_FILE` > /dev/null 2>&1; then
    log "worker already running as process `cat $WORKER_PID_FILE`."
    exit 0
  fi
fi

RAILS_ENV=$RAILS_ENV $RUBY packaging/update_database_yml.rb
JRUBY_OPTS=$JRUBY_OPTS CHORUS_JAVA_OPTIONS=$CHORUS_JAVA_OPTIONS_WITHOUT_XMS RAILS_ENV=$RAILS_ENV SOLR_PORT=$SOLR_PORT $RUBY script/rails runner "ChorusWorker.new.start" >> $CHORUS_HOME/log/worker.$RAILS_ENV.log 2>&1 &
worker_pid=$!
echo $worker_pid > $WORKER_PID_FILE
log "worker started as pid $worker_pid"
