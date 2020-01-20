#!/bin/sh

# install anyenv
git clone https://github.com/riywo/anyenv ~/.anyenv

# install rbenv & ruby
anyenv install rbenv
rbenv install 2.6.3
rbenv global  2.6.3
rbenv rehash

# require Ruby
# colorls
gem install colorls
rbenv rehash
rehash
