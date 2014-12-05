#!/bin/bash

export JRUBY_OPTS="--client -J-Xmx512m -J-Xms512m -J-Xmn128m -Xcext.enabled=true"
export PATH="$HOME/phantomjs/bin:$HOME/.rbenv/bin:$PATH"

eval "$(rbenv init - --no-rehash)"
rbenv shell `cat .rbenv-version`

gem list bundler | grep bundler || gem install bundler
bundle install --binstubs=b/ || (echo "bundler failed!!!!!!!!" && exit 1)

b/license_finder --quiet