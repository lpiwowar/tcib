#!/bin/sh
# run_tempest.sh
# ==============
#
# This script is executed inside the tempest containers defined in the tcib
# repository (tempest, tempest-all and tempest-extra). The main purpose of this
# script is executing the tempest command with correct arguments and preparing
# the tempest.conf file. The execution of the script can be influenced by
# setting values for environment variables which match the TEMPEST_* or
# TEMPESTCONF_* regex.
#
#
# TEMPESTCONF_* environment variables
# -----------------------------------
#
# These variables define with which arguments should be the
# discover-tempest-config command executed.
#
# Supported boolean arguments:
#   --create, --insecure, --collect-timing, --no-default-deployer, --debug
#   --verbose, --no-rng, --non-admin, --retry-image, --convert-to-raw
#
# Supported string arguments:
#   --timeout, --out, --deployer-input, --test-accounts, --create-accounts-file
#   --profile, --generate-profile, --image-disk-format, --image,
#   --flavor-min-mem, --flavor-min-disk, --disk, --network-id
#
# If you want discover-tempest-config to be executed with any of the boolean arguments
# mentioned above, then set corresponding environment variable to 'true'. The
# name of the variable consists of the prefix 'TEMPESTCONF_' plus the name
# of the argument. For example, if you want to run discover-tempest-config with
# --non-admin argument then set TEMPESTCONF_NON_ADMIN=true. Similarly, in the case
# of string arguments, when you want to run discover-tempest-config with
# --timeout 600 then set TEMPESTCONF_TIMEOUT=600.
#
# To override values in tempest.conf generated by discover-tempest-config please
# use TEMPESTCONF_OVERRIDES.
#
# TEMPEST_* environment ariables
# ------------------------------
#
# These variables define behaviour of the part of the script which is
# responsible for the tempest tests execution.
#
# Supported boolean arguments:
#   --smoke, --parallel, --serial
#
# Supported string arguments:
#   --include-list, --exclude-list, --concurrency, --worker-file,
#
# If you want the tempest command to be executed with any of the boolean
# arguments mentioned above, then set the corresponding environment variable to
# 'true'. The name of the variable consists of the prefix 'TEMPEST_' plus the
# name of the argument. For example, if you want to run tempest with --smoke
# argument then set TEMPEST_SMOKE=true. Similarly, in the case of string
# arguments, when you want to run tempest witn --include-list=/path/to/list.txt
# then set TEMPEST_INCLUDE_LIST=/path/to/list.txt
#
# The script, putting the above-mentioned tempest environment variables aside,
# offers also the following extra variables: TEMPEST_EXTERNAL_PLUGIN_GIT_URL,
# TEMPEST_EXTERNAL_PLUGIN_CHANGE_URL, TEMPEST_EXTERNAL_PLUGIN_REFSPEC. These
# can be used to specify extra tempest plugins you want to be installed within
# the container plus patches you want to be applied on top of the installed
# plugins.
#
# For example, by setting the environment variables like in the example below
# you ensure that the script downloads barbican-tempest-plugin and
# neutron-tempest-plugin and installs neutron-tempest-plugin with
# "refs/changes/97/896397/2" change from gerrit:
#
#
# TEMPEST_EXTERNAL_PLUGIN_CHANGE_URL=\
# "https://opendev.org/openstack/barbican-tempest-plugin.git,"\
# "https://opendev.org/openstack/neutron-tempest-plugin.git"
#
# TEMPEST_EXTERNAL_PLUGIN_CHANGE_URL=\
# "-,"\
# "https://review.opendev.org/openstack/neutron-tempest-plugin"
#
# TEMPEST_EXTERNAL_PLUGIN_REFSPEC=\
# "-,"\
# "refs/changes/97/896397/2"
#
# Note, that if you specify these variables then tempest will have access only
# to plugins which were specified by these variables. Meaning, if you consider
# the example above, then tempest won't be able to execute tests from
# octavia-tempest-plugin for example.

set -x

echo "foobar"

HOMEDIR=/var/lib/tempest
TEMPEST_PATH=$HOMEDIR/
TEMPEST_DIR=$HOMEDIR/openshift
CONCURRENCY="${CONCURRENCY:-}"
TEMPESTCONF_ARGS=""
TEMPEST_ARGS=""
TEMPEST_DEBUG_MODE="${TEMPEST_DEBUG_MODE:-false}"
TEMPEST_CLEANUP="${TEMPEST_CLEANUP:-false}"

function catch_error_if_debug {
    echo "File run_tempest.sh has run into an error!"
    sleep infinity
}

# Catch errors when in debug mode
if [ ${TEMPEST_DEBUG_MODE} == true ]; then
    trap catch_error_if_debug ERR
fi

[[ -z ${TEMPEST_WORKFLOW_STEP_DIR_NAME} ]] && TEMPEST_WORKFLOW_STEP_DIR_NAME="tempest"
[[ ! -z ${USE_EXTERNAL_FILES} ]] && TEMPEST_PATH=$HOMEDIR/external_files/

[[ ${TEMPESTCONF_CREATE:=true} == true ]] && TEMPESTCONF_ARGS+="--create "
[[ ${TEMPESTCONF_INSECURE} == true ]] && TEMPESTCONF_ARGS+="--insecure "
[[ ${TEMPESTCONF_COLLECT_TIMING} == true ]] && TEMPESTCONF_ARGS+="--collect-timing "
[[ ${TEMPESTCONF_NO_DEFAULT_DEPLOYER} == true ]] && TEMPESTCONF_ARGS+="--no-default-deployer "
[[ ${TEMPESTCONF_DEBUG:=true} == true ]] && TEMPESTCONF_ARGS+="--debug "
[[ ${TEMPESTCONF_VERBOSE} == true ]] && TEMPESTCONF_ARGS+="--verbose "
[[ ${TEMPESTCONF_NO_RNG} == true ]] && TEMPESTCONF_ARGS+="--no-rng "
[[ ${TEMPESTCONF_NON_ADMIN} == true ]] && TEMPESTCONF_ARGS+="--non-admin "
[[ ${TEMPESTCONF_RETRY_IMAGE} == true ]] && TEMPESTCONF_ARGS+="--retry-image "
[[ ${TEMPESTCONF_CONVERT_TO_RAW} == true ]] && TEMPESTCONF_ARGS+="--convert-to-raw "

[[ ! -z ${TEMPESTCONF_TIMEOUT} ]] && TEMPESTCONF_ARGS+="--timeout ${TEMPESTCONF_TIMEOUT} "
[[ ! -z ${TEMPESTCONF_OUT} ]] && TEMPESTCONF_ARGS+="--out ${TEMPESTCONF_OUT} "
[[ ! -z ${TEMPESTCONF_DEPLOYER_INPUT} ]] && TEMPESTCONF_ARGS+="--deployer-input ${TEMPESTCONF_DEPLOYER_INPUT} "
[[ ! -z ${TEMPESTCONF_TEST_ACCOUNTS} ]] && TEMPESTCONF_ARGS+="--test-accounts ${TEMPESTCONF_TEST_ACCOUNTS} "
[[ ! -z ${TEMPESTCONF_CREATE_ACCOUNTS_FILE} ]] && TEMPESTCONF_ARGS+="--create-accounts-file ${TEMPESTCONF_CREATE_ACCOUNTS_FILE} "
[[ ! -z ${TEMPESTCONF_PROFILE} ]] && TEMPESTCONF_ARGS+="--profile ${TEMPESTCONF_PROFILE} "
[[ ! -z ${TEMPESTCONF_GENERATE_PROFILE} ]] && TEMPESTCONF_ARGS+="--generate-profile ${TEMPESTCONF_GENERATE_PROFILE} "
[[ ! -z ${TEMPESTCONF_IMAGE_DISK_FORMAT} ]] && TEMPESTCONF_ARGS+="--image-disk-format ${TEMPESTCONF_IMAGE_DISK_FORMAT} "
[[ ! -z ${TEMPESTCONF_IMAGE} ]] && TEMPESTCONF_ARGS+="--image ${TEMPESTCONF_IMAGE} "
[[ ! -z ${TEMPESTCONF_FLAVOR_MIN_MEM} ]] && TEMPESTCONF_ARGS+="--flavor-min-mem ${TEMPESTCONF_FLAVOR_MIN_MEM} "
[[ ! -z ${TEMPESTCONF_FLAVOR_MIN_DISK} ]] && TEMPESTCONF_ARGS+="--flavor-min-disk ${TEMPESTCONF_FLAVOR_MIN_DISK} "
[[ ! -z ${TEMPESTCONF_NETWORK_ID} ]] && TEMPESTCONF_ARGS+="--network-id ${TEMPESTCONF_NETWORK_ID} "

TEMPESTCONF_OVERRIDES="$(echo ${TEMPESTCONF_OVERRIDES} | tr '\n' ' ') identity.v3_endpoint_type public "

# Octavia test-server is built as part of the installation of the python3-octavia-tests-tempest
# https://github.com/rdo-packages/octavia-tempest-plugin-distgit/blob/rpm-master/python-octavia-tests-tempest.spec#L127
if [[ ! -z ${TEMPESTCONF_OCTAVIA_TEST_SERVER_PATH} ]]; then
    TEMPESTCONF_OVERRIDES+="load_balancer.test_server_path ${TEMPESTCONF_OCTAVIA_TEST_SERVER_PATH} "
fi

# Tempest arguments
TEMPEST_EXTERNAL_PLUGIN_GIT_URL="${TEMPEST_EXTERNAL_PLUGIN_GIT_URL:-}"
TEMPEST_EXTERNAL_PLUGIN_CHANGE_URL="${TEMPEST_EXTERNAL_PLUGIN_CHANGE_URL:-}"
TEMPEST_EXTERNAL_PLUGIN_REFSPEC="${TEMPEST_EXTERNAL_PLUGIN_REFSPEC:-}"
TEMPEST_EXTERNAL_PLUGIN_DIR=/var/lib/tempest/external-plugins

TEMPEST_EXTRA_RPMS="${TEMPEST_EXTRA_RPMS:-}"

TEMPEST_EXTRA_IMAGES_URL="${TEMPEST_EXTRA_IMAGES_URL:-}"
TEMPEST_EXTRA_IMAGES_DISK_FORMAT="${TEMPEST_EXTRA_IMAGES_DISK_FORMAT:-}"
TEMPEST_EXTRA_IMAGES_OS_CLOUD="${TEMPEST_EXTRA_IMAGES_OS_CLOUD:-}"
TEMPEST_EXTRA_IMAGES_ID="${TEMPEST_EXTRA_IMAGES_ID:-}"
TEMPEST_EXTRA_IMAGES_NAME="${TEMPEST_EXTRA_IMAGES_NAME:-}"
TEMPEST_EXTRA_IMAGES_CONTAINER_FORMAT="${TEMPEST_EXTRA_IMAGES_CONTAINER_FORMAT:-}"

TEMPEST_EXTRA_IMAGES_FLAVOR_ID="${TEMPEST_EXTRA_IMAGES_FLAVOR_ID:-}"
TEMPEST_EXTRA_IMAGES_FLAVOR_RAM="${TEMPEST_EXTRA_IMAGES_FLAVOR_RAM:-}"
TEMPEST_EXTRA_IMAGES_FLAVOR_DISK="${TEMPEST_EXTRA_IMAGES_FLAVOR_DISK:-}"
TEMPEST_EXTRA_IMAGES_FLAVOR_VCPUS="${TEMPEST_EXTRA_IMAGES_FLAVOR_VCPUS:-}"
TEMPEST_EXTRA_IMAGES_FLAVOR_NAME="${TEMPEST_EXTRA_IMAGES_FLAVOR_NAME:-}"
TEMPEST_EXTRA_IMAGES_FLAVOR_OS_CLOUD="${TEMPEST_EXTRA_IMAGES_FLAVOR_OS_CLOUD:-}"
TEMPEST_EXTRA_IMAGES_CREATE_TIMEOUT="${TEMPEST_EXTRA_IMAGES_CREATE_TIMEOUT:-}"

# Convert comma separated lists to arrays
OLD_IFS=$IFS
IFS=","
read -ra TEMPEST_EXTERNAL_PLUGIN_GIT_URL <<< $TEMPEST_EXTERNAL_PLUGIN_GIT_URL
read -ra TEMPEST_EXTERNAL_PLUGIN_CHANGE_URL <<< $TEMPEST_EXTERNAL_PLUGIN_CHANGE_URL
read -ra TEMPEST_EXTERNAL_PLUGIN_REFSPEC <<< $TEMPEST_EXTERNAL_PLUGIN_REFSPEC
read -ra TEMPEST_EXTRA_RPMS <<< $TEMPEST_EXTRA_RPMS

read -ra TEMPEST_EXTRA_IMAGES_URL <<< ${TEMPEST_EXTRA_IMAGES_URL:-}
read -ra TEMPEST_EXTRA_IMAGES_DISK_FORMAT <<< $TEMPEST_EXTRA_IMAGES_DISK_FORMAT
read -ra TEMPEST_EXTRA_IMAGES_OS_CLOUD <<< $TEMPEST_EXTRA_IMAGES_OS_CLOUD
read -ra TEMPEST_EXTRA_IMAGES_ID <<< $TEMPEST_EXTRA_IMAGES_ID
read -ra TEMPEST_EXTRA_IMAGES_NAME <<< $TEMPEST_EXTRA_IMAGES_NAME
read -ra TEMPEST_EXTRA_IMAGES_CONTAINER_FORMAT <<< $TEMPEST_EXTRA_IMAGES_CONTAINER_FORMAT
read -ra TEMPEST_EXTRA_IMAGES_CREATE_TIMEOUT <<< $TEMPEST_EXTRA_IMAGES_CREATE_TIMEOUT

read -ra TEMPEST_EXTRA_IMAGES_FLAVOR_ID <<< $TEMPEST_EXTRA_IMAGES_FLAVOR_ID
read -ra TEMPEST_EXTRA_IMAGES_FLAVOR_RAM <<< $TEMPEST_EXTRA_IMAGES_FLAVOR_RAM
read -ra TEMPEST_EXTRA_IMAGES_FLAVOR_DISK <<< $TEMPEST_EXTRA_IMAGES_FLAVOR_DISK
read -ra TEMPEST_EXTRA_IMAGES_FLAVOR_VCPUS <<< $TEMPEST_EXTRA_IMAGES_FLAVOR_VCPUS
read -ra TEMPEST_EXTRA_IMAGES_FLAVOR_NAME <<< $TEMPEST_EXTRA_IMAGES_FLAVOR_NAME
read -ra TEMPEST_EXTRA_IMAGES_FLAVOR_OS_CLOUD <<< $TEMPEST_EXTRA_IMAGES_FLAVOR_OS_CLOUD
IFS=$OLD_IFS

[[ ${TEMPEST_SMOKE} == true ]] && TEMPEST_ARGS+="--smoke "
[[ ${TEMPEST_PARALLEL} == true ]] && TEMPEST_ARGS+="--parallel "
[[ ${TEMPEST_SERIAL} == true ]] && TEMPEST_ARGS+="--serial "

[[ ! -z ${TEMPEST_INCLUDE_LIST} ]] && TEMPEST_ARGS+="--include-list ${TEMPEST_INCLUDE_LIST} "
[[ ! -z ${TEMPEST_EXCLUDE_LIST} ]] && TEMPEST_ARGS+="--exclude-list ${TEMPEST_EXCLUDE_LIST} "
[[ ! -z ${TEMPEST_CONCURRENCY} ]] && TEMPEST_ARGS+="--concurrency ${TEMPEST_CONCURRENCY} "
[[ ! -z ${TEMPEST_WORKER_FILE} ]] && TEMPEST_ARGS+="--worker-file ${TEMPEST_WORKER_FILE} "
[[ -z ${TEMPEST_INCLUDE_LIST} ]] && TEMPEST_ARGS+="--include-list ${TEMPEST_PATH}include.txt "
[[ -z ${TEMPEST_EXCLUDE_LIST} ]] && TEMPEST_ARGS+="--exclude-list ${TEMPEST_PATH}exclude.txt "

if [[ ! -z ${TEMPESTCONF_APPEND} ]]; then
    while IFS= read -r line; do
        [[ ! -n "$line" ]] && continue
        arr_line=( $line )
        TEMPESTCONF_ARGS+="--append ${arr_line[0]}=${arr_line[1]} "
    done <<< "$TEMPESTCONF_APPEND"
fi

if [[ ! -z ${TEMPESTCONF_REMOVE} ]]; then
    while IFS= read -r line; do
        [[ ! -n "$line" ]] && continue
        arr_line=( $line )
        TEMPESTCONF_ARGS+="--remove ${arr_line[0]}=${arr_line[1]} "
    done <<< "$TEMPESTCONF_REMOVE"
fi

if [ -n "$CONCURRENCY" ] && [ -z ${TEMPEST_CONCURRENCY} ]; then
    TEMPEST_ARGS+="--concurrency ${CONCURRENCY} "
fi

function get_image_status {
    openstack image show $IMAGE_ID -f value -c status
}

function upload_extra_images {
    for image_index in "${!TEMPEST_EXTRA_IMAGES_NAME[@]}"; do
        if ! openstack image show ${TEMPEST_EXTRA_IMAGES_NAME[image_index]}; then
            image_create_params=()

            [[ ! -f "${TEMPEST_EXTRA_IMAGES_NAME[image_index]}" ]] && \
                curl -o "${HOMEDIR}/${TEMPEST_EXTRA_IMAGES_NAME[image_index]}" "${TEMPEST_EXTRA_IMAGES_URL[image_index]}"

            [[ ${TEMPEST_EXTRA_IMAGES_DISK_FORMAT[image_index]} != "-" ]] && \
                image_create_params+=(--disk-format ${TEMPEST_EXTRA_IMAGES_DISK_FORMAT[image_index]})

            [[ ${TEMPEST_EXTRA_IMAGES_OS_CLOUD[image_index]} != "-" ]] && \
                image_create_params+=(--os-cloud ${TEMPEST_EXTRA_IMAGES_OS_CLOUD[image_index]})

            [[ ${TEMPEST_EXTRA_IMAGES_ID[image_index]} != "-" ]] && \
                image_create_params+=(--id ${TEMPEST_EXTRA_IMAGES_ID[image_index]})

            [[ ${TEMPEST_EXTRA_IMAGES_NAME[image_index]} != "-" ]] && \
                image_create_params+=(--file "${HOMEDIR}/${TEMPEST_EXTRA_IMAGES_NAME[image_index]}")

            [[ ${TEMPEST_EXTRA_IMAGES_CONTAINER_FORMAT[image_index]} != "-" ]] && \
                image_create_params+=(--container-format ${TEMPEST_EXTRA_IMAGES_CONTAINER_FORMAT[image_index]})

            image_create_params+=(--public ${TEMPEST_EXTRA_IMAGES_NAME[image_index]})
            IMAGE_ID=$(openstack image create --import ${image_create_params[@]} -f value -c id)
            STATUS=$(get_image_status)
            START_TIME=$(date +%s)
            while [ "$STATUS" != "active" ]; do
                echo "Current status: $STATUS. Waiting for image to become active..."
                sleep 5
                if [ $(($(date +%s) - $START_TIME)) -gt ${TEMPEST_EXTRA_IMAGES_CREATE_TIMEOUT[image_index]} ]; then
                    echo "Error: Image creation exceeded the timeout period of ${TEMPEST_EXTRA_IMAGES_CREATE_TIMEOUT[image_index]} seconds."
                    exit 1
                fi
                STATUS=$(get_image_status)
            done
            echo "Image $IMAGE_ID is now active."
        fi

        if ! openstack flavor show ${TEMPEST_EXTRA_IMAGES_FLAVOR_NAME[image_index]}; then
            flavor_create_params=()

            [[ ${TEMPEST_EXTRA_IMAGES_FLAVOR_ID[image_index]} != "-" ]] && \
                flavor_create_params+=(--id ${TEMPEST_EXTRA_IMAGES_FLAVOR_ID[image_index]})

            [[ ${TEMPEST_EXTRA_IMAGES_FLAVOR_RAM[image_index]} != "-" ]] && \
                flavor_create_params+=(--ram ${TEMPEST_EXTRA_IMAGES_FLAVOR_RAM[image_index]})

            [[ ${TEMPEST_EXTRA_IMAGES_FLAVOR_DISK[image_index]} != "-" ]] && \
                flavor_create_params+=(--disk ${TEMPEST_EXTRA_IMAGES_FLAVOR_DISK[image_index]})

            [[ ${TEMPEST_EXTRA_IMAGES_FLAVOR_VCPUS[image_index]} != "-" ]] && \
                flavor_create_params+=(--vcpus ${TEMPEST_EXTRA_IMAGES_FLAVOR_VCPUS[image_index]})

            [[ ${TEMPEST_EXTRA_IMAGES_FLAVOR_NAME[image_index]} != "-" ]] && \
                flavor_create_params+=(--public ${TEMPEST_EXTRA_IMAGES_FLAVOR_NAME[image_index]})

            [[ ${TEMPEST_EXTRA_IMAGES_FLAVOR_OS_CLOUD[image_index]} != "-" ]] && \
                flavor_create_params+=(--os-cloud ${TEMPEST_EXTRA_IMAGES_FLAVOR_OS_CLOUD[image_index]})

            openstack flavor create ${flavor_create_params[@]}
        fi
    done
}


# This function ensures all arguments are handled properly:
# - Embedded quotes are preserved, e.g. "Some string"
# - Special bash characters don't need to be escaped, e.g. cubswin:)
function discover_tempest_config {
    cat <<EOF | xargs discover-tempest-config
$*
EOF
}

function run_git_tempest {
    mkdir -p $TEMPEST_EXTERNAL_PLUGIN_DIR
    pushd $TEMPEST_EXTERNAL_PLUGIN_DIR

    python3 -m venv .venv
    source ./.venv/bin/activate

    for plugin_index in "${!TEMPEST_EXTERNAL_PLUGIN_GIT_URL[@]}"; do
        git_url=${TEMPEST_EXTERNAL_PLUGIN_GIT_URL[plugin_index]}
        change_url=${TEMPEST_EXTERNAL_PLUGIN_CHANGE_URL[plugin_index]}
        refspec=${TEMPEST_EXTERNAL_PLUGIN_REFSPEC[plugin_index]}
        plugin_name=$(basename -s .git $git_url)

        git clone $git_url

        if [[ ! -z $change_url ]] && [[ ! -z $refspec ]] || \
           [[ $change_url != "-" ]] && [[ $refspec != "-" ]]; then
            pushd $plugin_name
            git fetch $change_url $refspec
            git checkout FETCH_HEAD
            popd
        fi

        pip install -chttps://releases.openstack.org/constraints/upper/2023.1 ./$plugin_name
    done

    pushd $HOMEDIR
    tempest init openshift
    pushd $TEMPEST_DIR

    # We're running cleanup only under certain circumstances
    if [[ ${TEMPEST_CLEANUP} == true ]]; then
        # generate a simple tempest.conf so that we can run --init-saved-state
        discover-tempest-config
        # let's remove the images that discover-tempest-config creates by default
        # so that the're not part of the saved_state.json and can be deleted
        # by tempest cleanup later
        openstack image list -c Name -f value | grep cirros | xargs -I {} openstack image delete {}
        tempest cleanup --init-saved-state
    fi

    upload_extra_images

    discover_tempest_config ${TEMPESTCONF_ARGS} ${TEMPESTCONF_OVERRIDES} \
    && tempest run ${TEMPEST_ARGS}
    RETURN_VALUE=$?

    # Run tempest cleanup to delete any leftover resources when not in debug mode
    if [[ ${TEMPEST_CLEANUP} == true ]]; then
        tempest cleanup
    fi

    deactivate

    popd
    popd
    popd
}

function run_rpm_tempest {
    pushd $HOMEDIR
    tempest init openshift
    pushd $TEMPEST_DIR

    # Install additional plugins from .rpms plus their dependencies
    [ ${#TEMPEST_EXTRA_RPMS[@]} -ne 0 ] && sudo dnf install -y ${TEMPEST_EXTRA_RPMS[@]}

    # List Tempest packages
    rpm -qa | grep tempest

    # We're running cleanup only under certain circumstances
    if [[ ${TEMPEST_CLEANUP} == true ]]; then
        # generate a simple tempest.conf so that we can run --init-saved-state
        discover-tempest-config
        # let's remove the images that discover-tempest-config creates by default
        # so that the're not part of the saved_state.json and can be deleted
        # by tempest cleanup later
        openstack image list -c Name -f value | grep cirros | xargs -I {} openstack image delete {}
        tempest cleanup --init-saved-state
    fi

    upload_extra_images

    discover_tempest_config ${TEMPESTCONF_ARGS} ${TEMPESTCONF_OVERRIDES} \
    && tempest run ${TEMPEST_ARGS}
    RETURN_VALUE=$?

    # Run tempest cleanup to delete any leftover resources when not in debug mode
    if [[ ${TEMPEST_CLEANUP} == true ]]; then
        tempest cleanup
    fi

    popd
    popd
}

function generate_test_results {
    pushd $TEMPEST_DIR

    echo "Excluded tests"
    if [ ! -z ${TEMPEST_EXCLUDE_LIST} ]; then
        cat ${TEMPEST_EXCLUDE_LIST}
    fi

    echo "Included tests"
    if [ ! -z ${TEMPEST_INCLUDE_LIST} ]; then
        cat ${TEMPEST_INCLUDE_LIST}
    fi

    TEMPEST_LOGS_DIR=${TEMPEST_PATH}${TEMPEST_WORKFLOW_STEP_DIR_NAME}/
    mkdir -p ${TEMPEST_LOGS_DIR}

    echo "Generate subunit, then xml and html results"
    stestr last --subunit > ${TEMPEST_LOGS_DIR}testrepository.subunit \
    && (subunit2junitxml ${TEMPEST_LOGS_DIR}testrepository.subunit > ${TEMPEST_LOGS_DIR}tempest_results.xml || true) \
    && subunit2html ${TEMPEST_LOGS_DIR}testrepository.subunit ${TEMPEST_LOGS_DIR}stestr_results.html || true

    # NOTE: Remove cirros image before copying of the logs.
    rm ${TEMPEST_DIR}/etc/*.img

    echo Copying logs file
    cp -rf ${TEMPEST_DIR}/* ${TEMPEST_LOGS_DIR}

    popd
}

export OS_CLOUD=default

if [ ! -z ${USE_EXTERNAL_FILES} ] && [ -e ${TEMPEST_PATH}clouds.yaml ]; then
    mkdir -p $HOME/.config/openstack
    cp ${TEMPEST_PATH}clouds.yaml $HOME/.config/openstack/clouds.yaml
fi

if [ -f ${TEMPEST_PATH}profile.yaml ] && [ -z ${TEMPESTCONF_PROFILE} ]; then
    TEMPESTCONF_ARGS+="--profile ${TEMPEST_PATH}profile.yaml "
fi

if [ ! -f ${TEMPEST_PATH}include.txt ] && [ -z ${TEMPEST_INCLUDE_LIST} ]; then
    echo "tempest.api.identity.v3" > ${TEMPEST_PATH}include.txt
fi

if [ ! -f ${TEMPEST_PATH}exclude.txt ] && [ -z ${TEMPEST_EXCLUDE_LIST} ]; then
    touch ${TEMPEST_PATH}exclude.txt
fi

# This workaround is required for the whitebox-neutron-tempest plugin. We need
# to be able to specify 600 permissions for the id_ecdsa.
if [ -f ${HOMEDIR}/id_ecdsa ]; then
    mkdir -p ${HOMEDIR}/.ssh
    cp ${HOMEDIR}/id_ecdsa ${HOMEDIR}/.ssh/id_ecdsa
    chmod 700 ${HOMEDIR}/.ssh
    chmod 600 ${HOMEDIR}/.ssh/id_ecdsa
    chown -R tempest:tempest ${HOMEDIR}/.ssh
fi

if [ -z $TEMPEST_EXTERNAL_PLUGIN_GIT_URL ]; then
    run_rpm_tempest
else
    run_git_tempest
fi

generate_test_results

# Keep pod in running state when in debug mode
if [ ${TEMPEST_DEBUG_MODE} == true ]; then
    sleep infinity
fi

exit ${RETURN_VALUE}
