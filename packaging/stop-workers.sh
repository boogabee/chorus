#!/usr/bin/env bash
bin=`readlink "$0"`
if [ "$bin" == "" ]; then
 bin=$0
fi
bin=`dirname "$bin"`
bin=`cd "$bin"; pwd`

. "$bin"/chorus-config.sh

if [ -f $WORKER_PID_FILE ]; then
  if kill -2 `cat $WORKER_PID_FILE` > /dev/null 2>&1; then
    log_inline "stopping workers "
    kill `cat $WORKER_PID_FILE`
    wait_for_stop $WORKER_PID_FILE
    rm -f $WORKER_PID_FILE
  else
    log "could not stop worker. check that process `cat $WORKER_PID_FILE` exists"
    exit 0
  fi
else
  log "no worker to stop"
fi
