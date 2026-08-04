#!/bin/bash

aws cloudformation create-stack \
--stack-name Lab01-CloudFormation \
--template-body file://templates/lab01.yaml \
--capabilities CAPABILITY_NAMED_IAM