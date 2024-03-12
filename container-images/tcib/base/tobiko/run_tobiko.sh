#!/bin/sh

set -x

TOBIKO_DIR=/var/lib/tobiko

# assert mandatory variables have been set
[ -z "${TOBIKO_TESTENV}" ] && echo "TOBIKO_TESTENV not set" && exit 1

# download Ubuntu minimal image used by the Tobiko scenario tests, if needed
if [ ! -z ${TOBIKO_UBUNTU_MINIMAL_IMAGE_URL} ]; then
    mkdir -p ${TOBIKO_DIR}/.downloaded-images
    curl ${TOBIKO_UBUNTU_MINIMAL_IMAGE_URL} -o ${TOBIKO_DIR}/.downloaded-images/ubuntu-minimal
fi

# set default values for the required variables
TOBIKO_VERSION=${TOBIKO_VERSION:-master}
TOBIKO_PRIVATE_KEY_FILE=${TOBIKO_PRIVATE_KEY_FILE:-id_ecdsa}
TOBIKO_OCP_CLIENT_TGZ=${TOBIKO_OCP_CLIENT_TGZ:-"https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz"}
TOBIKO_KEYS_FOLDER=${TOBIKO_KEYS_FOLDER:-${TOBIKO_DIR}/external_files}
TOBIKO_LOGS_DIR_NAME=${TOBIKO_LOGS_DIR_NAME:-"tobiko"}

# export OS_CLOUD variable
[ ! -z ${TOBIKO_OS_CLOUD} ] && export OS_CLOUD=${TOBIKO_OS_CLOUD} || export OS_CLOUD=default

# export optional variables, relevant for tox and pytest execution (see tobiko tox.ini file)
[ ! -z ${TOBIKO_PYTEST_ADDOPTS} ] && export PYTEST_ADDOPTS=${TOBIKO_PYTEST_ADDOPTS}
[ ! -z ${TOBIKO_RUN_TESTS_TIMEOUT} ] && export TOX_RUN_TESTS_TIMEOUT=${TOBIKO_RUN_TESTS_TIMEOUT}
[ ! -z ${TOBIKO_PREVENT_CREATE} ] && export TOBIKO_PREVENT_CREATE=${TOBIKO_PREVENT_CREATE}
[ ! -z ${TOBIKO_NUM_PROCESSES} ] && export TOX_NUM_PROCESSES=${TOBIKO_NUM_PROCESSES}

pushd ${TOBIKO_DIR}
git clone https://opendev.org/x/tobiko
pushd tobiko
git checkout ${TOBIKO_VERSION}

# obtain clouds.yaml, ssh private/public keys and tobiko.conf from external_files directory
if [ ! -z ${USE_EXTERNAL_FILES} ]; then
    if [ -f $TOBIKO_DIR/external_files/clouds.yaml ]; then
        mkdir -p $TOBIKO_DIR/.config/openstack
        cp $TOBIKO_DIR/external_files/clouds.yaml $TOBIKO_DIR/.config/openstack/
    fi
    if [ -f ${TOBIKO_KEYS_FOLDER}/${TOBIKO_PRIVATE_KEY_FILE} ]; then
        mkdir -p $TOBIKO_DIR/.ssh
        sudo cp ${TOBIKO_KEYS_FOLDER}/${TOBIKO_PRIVATE_KEY_FILE}* $TOBIKO_DIR/.ssh/
        sudo chown tobiko:tobiko $TOBIKO_DIR/.ssh/${TOBIKO_PRIVATE_KEY_FILE}*
    fi
    [ -f $TOBIKO_DIR/external_files/tobiko.conf ] && cp $TOBIKO_DIR/external_files/tobiko.conf .
fi

# install openshift client
which oc || curl -s -L ${TOBIKO_OCP_CLIENT_TGZ} | sudo tar -zxvf - -C /usr/local/bin/

# run tobiko tests
python3 -m tox -e ${TOBIKO_TESTENV}
RETURN_VALUE=$?

# copy logs to external_files
if [ ! -z ${USE_EXTERNAL_FILES} ]; then
    echo "Copying logs file"
    TOBIKO_TESTENV_ARR=($TOBIKO_TESTENV)
    LOG_DIR=${TOX_REPORT_DIR:-/var/lib/tobiko/tobiko/.tox/${TOBIKO_TESTENV_ARR}/log}
    sudo cp -rf ${LOG_DIR} ${TOBIKO_DIR}/external_files/${TOBIKO_LOGS_DIR_NAME}/
    if [ -f tobiko.conf ]; then
        sudo cp tobiko.conf ${TOBIKO_DIR}/external_files/${TOBIKO_LOGS_DIR_NAME}/
    elif [ -f /etc/tobiko/tobiko.conf ]; then
        sudo cp /etc/tobiko/tobiko.conf ${TOBIKO_DIR}/external_files/${TOBIKO_LOGS_DIR_NAME}/
    fi
fi

exit ${RETURN_VALUE}
