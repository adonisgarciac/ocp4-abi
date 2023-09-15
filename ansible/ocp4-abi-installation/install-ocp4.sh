#!/bin/bash

set -x

TEST_PLAYBOOK="install-openshift.yaml"
EE_IMAGE_NAME="quay.io/rh_ee_agarciac/ee-ocp-vmware:latest"

ansible-navigator run -vvv -m stdout  --pp missing --pae false --lf /tmp/out.log --eei "$EE_IMAGE_NAME" "$TEST_PLAYBOOK"
