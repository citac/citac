#!/bin/bash

DIR=/tmp/demo.spec

mkdir $DIR
cd $DIR
echo "Initializing test Puppet spec in $DIR"
citac init

echo "Writing puppet commands to file $DIR/scripts/default"
echo "exec {'/bin/echo on >> /etc/setting': }" > scripts/default
echo "exec {'/bin/date >> /tmp/runs.txt': }" >> scripts/default

echo "Add test dependency to test Puppet spec: puppetlabs/stdlib 3.2.1"
citac add puppetlabs/stdlib 3.2.1
echo "Setting test OS: debian-7"
citac os debian-7

echo "Starting test execution"
citac test

echo "Getting test results"
citac results -d

