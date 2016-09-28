#!/bin/bash

set -ex

bundle install --no-deployment
bundle exec rake tmp:clear db:drop db:create db:dev:migrate
./bin/console 
