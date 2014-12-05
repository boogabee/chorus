#!/bin/bash

if ! command -v jshint >/dev/null 2>&1; then
    echo 'jshint not found. Please install jshint by running "npm -g install jshint".  Aborting lint!'
    exit 1
fi

echo 'Running jshint for changed javascript files...'

jshint --config config/jshint.json `git diff --cached --name-only --diff-filter=ACM | grep '\.js$'`
