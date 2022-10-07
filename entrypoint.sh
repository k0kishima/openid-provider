#! /bin/sh -eu

rm -f tmp/pids/*
bundle install

exec "$@"
