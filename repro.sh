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
CMAKE_VERSION_LIST+=("3.26.5")

###############################################################################
## Logic
###############################################################################
REPRO_SETUP_SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

[ ! -d "${REPRO_SETUP_SCRIPT_DIR}/spack" ] && git clone --depth=2 https://github.com/spack/spack.git "${REPRO_SETUP_SCRIPT_DIR}/spack"
[ ! -d "${REPRO_SETUP_SCRIPT_DIR}/hpcw" ] && git clone https://gitlab.dkrz.de/hpcw/hpcw.git "${REPRO_SETUP_SCRIPT_DIR}/hpcw"

source "${REPRO_SETUP_SCRIPT_DIR}/spack/share/spack/setup-env.sh"

# Install all necessary cmake versions & HPCW dependencies
for CMAKE_VERSION in "${CMAKE_VERSION_LIST}"; do
    spack install -j 8 cmake@${CMAKE_VERSION}
done

# Test download

