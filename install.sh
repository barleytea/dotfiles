#!/bin/sh

# install anyenv
git clone https://github.com/riywo/anyenv ~/.anyenv

# install rbenv & ruby
anyenv install rbenv
rbenv install 2.3.4
rbenv global  2.3.4
rbenv rehash

# require Ruby
gem install colorls
rbenv rehash
rehash
