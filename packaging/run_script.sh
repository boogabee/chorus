#!/usr/bin/env bash
bin=`readlink "$0"`
if [ "$bin" == "" ]; then
 bin=$0
fi
bin=`dirname "$bin"`
bin=`cd "$bin"; pwd`

. "$bin"/chorus-config.sh

export DYLD_LIBRARY_PATH=$CHORUS_HOME/postgres/lib
export LD_LIBRARY_PATH=$CHORUS_HOME/postgres/lib

exec ${@}
