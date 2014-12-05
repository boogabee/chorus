#!/usr/bin/env bash

hostname=$1
dir=$2
archive_host=$3
archive_path=$4

echo "Creating backup"
ssh $hostname "rm -rf /tmp/backups/*.tar && cd $dir && source chorus_path.sh && ./chorus_control.sh backup -d /tmp/backups"
echo "Archiving backup to ${archive_host}:${archive_path}"
ssh $hostname "scp /tmp/backups/*.tar ${archive_host}:${archive_path}"
