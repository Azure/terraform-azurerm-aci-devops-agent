#!/bin/bash

set -e

# run test
go clean -testcache
go test -v ./ -timeout 30m | tee test_output.log
terratest_log_parser -testlog test_output.log -outputdir test_output
