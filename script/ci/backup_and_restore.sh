#!/bin/bash
hostname=$1
dir=$2
echo "Running backup"
ssh $hostname "cd $dir && . chorus_path.sh && ./chorus_control.sh backup -d $dir/backups"
echo "Stopping chorus"
ssh $hostname "cd $dir && . chorus_path.sh && ./chorus_control.sh stop"
echo "Running restore"
ssh $hostname "cd $dir && . chorus_path.sh && ./chorus_control.sh restore -s $dir/backups/*.tar"
echo "Starting chorus"
ssh $hostname "cd $dir && . chorus_path.sh && ./chorus_control.sh start"

