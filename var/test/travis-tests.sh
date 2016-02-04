#!/bin/bash

DIR=/tmp/demo.spec

mkdir $DIR
cd $DIR
citac init

echo "exec {'/bin/echo on >> /etc/setting': }" > scripts/default
echo "exec {'/bin/date >> /tmp/runs.txt': }" >> scripts/default

citac add puppetlabs/stdlib 3.2.1
citac os debian-7

citac test

citac results -d
