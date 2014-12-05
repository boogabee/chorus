#!/usr/bin/env bash
bin=`readlink "$0"`
if [ "$bin" == "" ]; then
 bin=$0
fi
bin=`dirname "$bin"`
bin=`cd "$bin"; pwd`

. "$bin"/chorus-config.sh

if [ -f $NGINX_PID_FILE ]; then
  if kill -0 `cat $NGINX_PID_FILE` > /dev/null 2>&1; then
    log_inline "stopping nginx "
    cd $CHORUS_HOME/vendor/nginx/nginx_dist/
    OPENSSL_CONF=$OPENSSL_CONF ./$NGINX -s stop
    STOP_SUCCESS=$?
    if [ $STOP_SUCCESS -eq 0 ]; then
        wait_for_stop $NGINX_PID_FILE
    fi
    cd $CHORUS_HOME
  else
    log "no nginx to stop"
    rm -f $NGINX_PID_FILE
    STOP_SUCCESS=0
  fi
else
    log "no nginx to stop"
    STOP_SUCCESS=0
fi

case $RAILS_ENV in
    development )
        if [ -f $MIZUNO_PID_FILE ]; then
          if kill -0 `cat $MIZUNO_PID_FILE` > /dev/null 2>&1; then
            log_inline "stopping mizuno "
            bundle exec mizuno --stop --pidfile $MIZUNO_PID_FILE &>/dev/null
            STOP_SUCCESS=`expr $STOP_SUCCESS + $?`
            if [ $STOP_SUCCESS -eq 0 ]; then
                wait_for_stop $MIZUNO_PID_FILE
            fi
          else
            log "no mizuno to stop"
            rm -f $MIZUNO_PID_FILE
          fi
        else
          log "no mizuno to stop"
        fi
        ;;
    * )
        if [ -f $JETTY_PID_FILE ]; then
          if kill -0 `cat $JETTY_PID_FILE` > /dev/null 2>&1; then
            log "stopping jetty "
            cd $CHORUS_HOME/vendor/jetty/
            JETTY_PID=$JETTY_PID_FILE RAILS_ENV=$RAILS_ENV ./jetty-init stop
            STOP_SUCCESS=`expr $STOP_SUCCESS + $?`
            cd $CHORUS_HOME
            if [ $STOP_SUCCESS -eq 0 ]; then
                wait_for_stop $JETTY_PID_FILE
            fi
          else
            log "no jetty to stop"
            rm -f $JETTY_PID_FILE
          fi
        else
          log "no jetty to stop"
        fi
        ;;
esac

exit $STOP_SUCCESS