#!/usr/bin/env bash
bin=`readlink "$0"`
if [ "$bin" == "" ]; then
 bin=$0
fi
bin=`dirname "$bin"`
bin=`cd "$bin"; pwd`

. "$bin"/chorus-config.sh

DYLD_LIBRARY_PATH=$CHORUS_HOME/postgres/lib LD_LIBRARY_PATH=$CHORUS_HOME/postgres/lib exec $CHORUS_HOME/postgres/bin/pg_restore ${@}
