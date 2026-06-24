#!/usr/bin/env bash
###############################################################################
# Copyright (C) 2026 Bull S. A. S. -  All rights reserved
# Bull, Rue Jean Jaures, B.P.68, 78340, Les Clayes-sous-Bois, France
# This is not Free or Open Source software.
# Please contact Bull S. A. S. for details about its license.
###############################################################################
# Author:      Antoine Morvan
# License:     Private
# Version:     0.0.1
# Maintainer:  Antoine Morvan
# EMail        antoine.morvan@bull.com
# Status:      beta
# Credits:     Antoine Morvan
# BugTracker:  
###############################################################################
set -e -u -o pipefail

###############################################################################
## Config
###############################################################################

CMAKE_VERSION_LIST=()
CMAKE_VERSION_LIST+=("4.3.3")
# CMAKE_VERSION_LIST+=("4.2.3")
# CMAKE_VERSION_LIST+=("4.1.5")
# CMAKE_VERSION_LIST+=("4.0.6")
# CMAKE_VERSION_LIST+=("3.31.11")
# CMAKE_VERSION_LIST+=("3.30.9")
# CMAKE_VERSION_LIST+=("3.29.6")
# CMAKE_VERSION_LIST+=("3.28.6")
# CMAKE_VERSION_LIST+=("3.27.9")
# CMAKE_VERSION_LIST+=("3.26.6")
# CMAKE_VERSION_LIST+=("3.25.3")
# CMAKE_VERSION_LIST+=("3.24.4")
# CMAKE_VERSION_LIST+=("3.23.5")
# CMAKE_VERSION_LIST+=("3.22.6")
# CMAKE_VERSION_LIST+=("3.21.7")
# CMAKE_VERSION_LIST+=("3.20.6")
# CMAKE_VERSION_LIST+=("3.19.8")
# CMAKE_VERSION_LIST+=("3.18.6")
# CMAKE_VERSION_LIST+=("3.17.5")
# CMAKE_VERSION_LIST+=("3.16.9")
# CMAKE_VERSION_LIST+=("3.15.7")
# CMAKE_VERSION_LIST+=("3.14.7")
# CMAKE_VERSION_LIST+=("3.13.5")
# CMAKE_VERSION_LIST+=("3.12.4")
# CMAKE_VERSION_LIST+=("3.11.4")
# CMAKE_VERSION_LIST+=("3.10.3")
# CMAKE_VERSION_LIST+=("3.9.6")
# CMAKE_VERSION_LIST+=("3.8.2")
# CMAKE_VERSION_LIST+=("3.7.2")
# CMAKE_VERSION_LIST+=("3.6.1")
# CMAKE_VERSION_LIST+=("3.5.2")
# CMAKE_VERSION_LIST+=("3.4.3")
# CMAKE_VERSION_LIST+=("3.3.1")
# CMAKE_VERSION_LIST+=("3.1.0")


###############################################################################
## Logic
###############################################################################
REPRO_SETUP_SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

log_dir="${REPRO_SETUP_SCRIPT_DIR}/logs_$(date -u --iso=seconds)"

[ ! -d "${REPRO_SETUP_SCRIPT_DIR}/spack" ] && git clone --depth=2 https://github.com/spack/spack.git "${REPRO_SETUP_SCRIPT_DIR}/spack"
[ ! -d "${REPRO_SETUP_SCRIPT_DIR}/hpcw" ] && git clone https://gitlab.dkrz.de/hpcw/hpcw.git "${REPRO_SETUP_SCRIPT_DIR}/hpcw"

source "${REPRO_SETUP_SCRIPT_DIR}/spack/share/spack/setup-env.sh"

# Install all necessary cmake versions & HPCW dependencies
for CMAKE_VERSION in "${CMAKE_VERSION_LIST}"; do
    echo "## -- spack install cmake@${CMAKE_VERSION}"
    spack install -j 8 cmake@${CMAKE_VERSION}
done

mkdir -p "${log_dir}"

# Test download
ISSUE_VERSIONS=()
for HPCW_LOG_ENABLE in ON; do
    for CMAKE_VERSION in "${CMAKE_VERSION_LIST}"; do
        (
            echo "## -- test cmake@${CMAKE_VERSION} log enable = ${HPCW_LOG_ENABLE}"
            spack load cmake@${CMAKE_VERSION}
            cmake --version

            cd "${REPRO_SETUP_SCRIPT_DIR}/hpcw"
            git clean -xdff
            cd downloads
            cmake . -DENABLE_LOGGING=${HPCW_LOG_ENABLE}
            make

            echo "## -- ls"
            ls -ailh "${REPRO_SETUP_SCRIPT_DIR}/hpcw/hpcw-store"/*
            echo "## -- find"
            find "${REPRO_SETUP_SCRIPT_DIR}/hpcw/hpcw-store" -name "*.tmp*" -o -regex "\.[a-zA-Z0-9].*"
        ) |& tee "${log_dir}"/LOG_${HPCW_LOG_ENABLE}-CMAKE_${CMAKE_VERSION}.log
        TMP_FILECOUNT=$(find "${REPRO_SETUP_SCRIPT_DIR}/hpcw/hpcw-store" -name "*.tmp*" -o -regex "\.[a-zA-Z0-9].*")
        if [ "${TMP_FILECOUNT}" -gt 0 ]; then
            ISSUE_VERSIONS+=("CMake@${CMAKE_VERSION} / Logging ${HPCW_LOG_ENABLE}")
        fi
    done
done

echo "## -- Results:"
if [ ${#ISSUE_VERSIONS[@]} -gt 0 ]; then
    for issue in "${ISSUE_VERSIONS[@]}"; do
        echo "## --   >> $issue"
    done
else
    echo "## -- NO ISSUE"
fi

echo "## -- Done."
exit 0
