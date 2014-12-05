#!/bin/bash

install_processes=`ps aux | grep chorusrails-installer | wc -l`

if [[ $install_processes -le 1 ]]; then
    server=$1
    if [ -z $server ]; then
        server=stage
    fi

    for file in chorus-*.sh
    do
      echo "Deploying $file"
      chmod +x $file
      bundle exec rake deploy["$server","$file"]
      exit $?
    done
else
    echo "The last install did not complete; bad things happen when two installs run at once."
    exit 1
fi
