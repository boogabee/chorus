#!/usr/bin/env bash
DESIRED_RUBY_VERSION=`cat .ruby-version`

# Pipe through sed to remove asterisks, which get executed by backticks
INSTALLED_RUBY_VERSIONS=`rbenv versions | sed -e 's/*//'`

# If the desired ruby version is installed
if echo $INSTALLED_RUBY_VERSIONS | grep -q "$DESIRED_RUBY_VERSION"; then
	echo "$DESIRED_RUBY_VERSION is installed!"
else
	cd ~/.rbenv/plugins/ruby-build
	git pull
	rbenv install $DESIRED_RUBY_VERSION
fi