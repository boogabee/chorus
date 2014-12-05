#!/usr/bin/env bash
bin=`readlink "$0"`
if [ "$bin" == "" ]; then
 bin=$0
fi
bin=`dirname "$bin"`
bin=`cd "$bin"; pwd`

. "$bin"/chorus-config.sh

if [ -f $POSTGRES_PID_FILE ]; then
  if kill -0 `cat $POSTGRES_PID_FILE` > /dev/null 2>&1; then
    log_inline "stopping postgres "
    $CHORUS_HOME/postgres/bin/pg_ctl -D $POSTGRES_DATA_DIR -m fast stop > /dev/null
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        wait_for_stop $POSTGRES_PID_FILE
    fi
    exit $EXIT_CODE
  else
    log "no postgres to stop"
    rm -f $POSTGRES_PID_FILE
    exit 0
  fi
else
  log "no postgres to stop"
  exit 0
fi