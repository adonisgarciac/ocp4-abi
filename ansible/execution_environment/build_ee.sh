#!/bin/bash

#VARS
EE_IMAGE_NAME="ee-ocp-vmware:latest"

#Build it
subscription-manager repos --enable=rhocp-4.12-for-rhel-8-x86_64-rpms
ansible-builder -v 3 build --tag "$EE_IMAGE_NAME"
