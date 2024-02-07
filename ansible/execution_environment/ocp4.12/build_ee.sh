#!/bin/bash
#
#date         :17/09/23
#version      :0.1
#authors      :jtudelag@redhat.com
#description  :Script to build an Ansible Execution Environment to install OpenShift.
#              Tailored to install OpenShift using ABI on vSphere and baremetal.
#              Butane is used to produce some MachineConfig during the installation process.
#              Coreos-installer is required to add new nodes to the cluster.
#              Each EE build is tagged exactly after the Openshift version it will install.

set -euo pipefail

#VARS
# Dont include TAGS!!!! Only the name.
EE_IMAGE_NAME="ee-ocp-vmware"
OCP_MAJOR=4
OCP_MINOR=12
OCP_PATCH=32
COREOS_INSTALLER_VERSION="0.17.0-1"
BUTANE_VERSION="0.18.0-1"
#Used for RPMs repos.
RHEL_VERSION="8"

# Constants, dont change!!!
OCP_XY="${OCP_MAJOR}.${OCP_MINOR}"
OCP_XYZ="${OCP_XY}.${OCP_PATCH}"
OCP_MIRROR_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OCP_XYZ}"
CLI_INSTALL_FILE="openshift-install-linux.tar.gz"
CLI_OC_FILE="openshift-client-linux.tar.gz"
BUTANE_FINAL_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/butane/v${BUTANE_VERSION}/butane"
COREOS_INSTALLER_FINAL_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/coreos-installer/v${COREOS_INSTALLER_VERSION}/coreos-installer"

# Create Temporary folders
BASE_TMPDIR="$(mktemp -d -q)"
mkdir "${BASE_TMPDIR}/tar"
BASE_TARGZ_DIR="${BASE_TMPDIR}/tar"
mkdir "${BASE_TMPDIR}/bin"
BASE_BIN_DIR="${BASE_TMPDIR}/bin"
FINAL_FILE="./files/ocp_binaries.tar.gz"

dl_oc () {
  echo "Downloading oc ;)"
  DEST_FOLDER=${1:-$DOWNLOAD_FOLDER}
  URL="$OCP_MIRROR_URL/${CLI_OC_FILE}"
  TAR_FILE="${BASE_TARGZ_DIR}/$CLI_OC_FILE"
  curl -L "${URL}" -o "${TAR_FILE}"
  sudo tar xvfz "${TAR_FILE}" --directory "${BASE_BIN_DIR}/" oc
}

dl_openshift_install () {
  echo "Downloading openshift-install ;)"
  DEST_FOLDER=${1:-$DOWNLOAD_FOLDER}
  URL="${OCP_MIRROR_URL}/${CLI_INSTALL_FILE}"
  TAR_FILE="${BASE_TARGZ_DIR}/$CLI_INSTALL_FILE"
  curl -L "${URL}" -o "${TAR_FILE}"
  sudo tar xvfz "${TAR_FILE}" --directory "${BASE_BIN_DIR}/" openshift-install
}

dl_butane () {
  echo "Downloading butane ;)"
  URL="${BUTANE_FINAL_URL}"
  BIN_FILE="${BASE_BIN_DIR}/butane"
  curl -L "${URL}" -o "${BIN_FILE}"
}

dl_coreos_installer () {
  echo "Downloading coreos-installer ;)"
  URL="${COREOS_INSTALLER_FINAL_URL}"
  BIN_FILE="${BASE_BIN_DIR}/coreos-installer"
  curl -L "${URL}" -o "${BIN_FILE}"
}

download () {
  dl_oc "${BASE_TARGZ_DIR}"
  dl_openshift_install "${BASE_TARGZ_DIR}"
  dl_butane
  dl_coreos_installer
  
  sudo chmod +x ${BASE_BIN_DIR}/*
  sudo chown root:root ${BASE_BIN_DIR}/*
  tar cvfz "${FINAL_FILE}" -C "${BASE_BIN_DIR}/" .
}

build () {
  sudo subscription-manager repos --enable="rhocp-${OCP_MAJOR}.${OCP_MINOR}-for-rhel-${RHEL_VERSION}-x86_64-rpms"
  
  #Build it
  ansible-builder build -v 3 \
  	--squash all \
	--build-arg EE_BASE_IMAGE="registry.redhat.io/ansible-automation-platform-24/ee-minimal-rhel${RHEL_VERSION}:latest" \
  	--prune-images \
  	--tag "${EE_IMAGE_NAME}:${OCP_XYZ}"
}

all () {
  download
  build
}

help () {
   # Display Help
   echo "Script to build an Ansible EE to install OpenShift"
   echo
   echo "Syntax: build_ee.sh [-h|-a|-b|-d]"
   echo "options:"
   echo "-h   Print this Help."
   echo "-d   Download Openshift artifacts."
   echo "-b   Build EE."
   echo "-a   Download OpenShift artifacts and build EE."
   echo ""
}

#----------------------------------- MAIN--------------------------

PASSED_ARGS=$@
if [[ ${#PASSED_ARGS} -ne 0 ]]
then
     case "$1" in
        -h) # display Help
           help
           exit;;
        -a) # all
           all
           exit;;
        -b) # all
           build
           exit;;
        -d) # all
           download 
           exit;;
        *) # incorrect option
           echo "Error: Invalid option"
  	   help
           exit;;
        :) # incorrect option
           echo "Error: Invalid option"
  	   help
           exit;;
        \?) # incorrect option
           echo "Error: Invalid option"
  	   help
           exit;;
     esac
else
  help
  exit
fi
