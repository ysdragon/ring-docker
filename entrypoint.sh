#!/bin/bash

# Check if we need to switch Ring versions
if [ -n "$RING_VERSION" ]; then
    # Add 'v' prefix if it doesn't exist, but not for branch names like master
    if [[ ! "$RING_VERSION" =~ ^v ]] && [ "$RING_VERSION" != "master" ]; then
        RING_VERSION="v$RING_VERSION"
    fi
    
    # Get current Ring version
    pushd /opt/ring > /dev/null
    CURRENT_VERSION=$(git describe --tags --exact-match HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    popd > /dev/null
    
    # Only switch if the requested version is different from current
    if [ "$RING_VERSION" != "$CURRENT_VERSION" ]; then
        echo "Switching Ring version from $CURRENT_VERSION to $RING_VERSION..."
    else
        # Skip to package installation and execution
        RING_VERSION=""
    fi
fi

if [ -n "$RING_VERSION" ]; then
    # Navigate to the ring directory
    pushd /opt/ring
    
    # Clean untracked files and directories
    echo "Cleaning untracked files..."
    git clean -xf > /dev/null 2>&1

    # Fetch only the desired version (tag or branch) with a shallow clone
    echo "Fetching version: $RING_VERSION..."
    if ! git fetch --depth 1 origin "$RING_VERSION"; then
        echo "Error: Version $RING_VERSION not found"
        exit 1
    fi

    # Checkout the fetched version
    echo "Checking out version: $RING_VERSION"
    git checkout -f FETCH_HEAD > /dev/null 2>&1

    # Check the RING_VERSION and apply patches if it's under v1.22
    version_num=$(echo "$RING_VERSION" | sed 's/^v//')
    if [ "$(echo "$version_num < 1.22" | bc)" -eq 1 ] && [ "$RING_VERSION" != "master" ]; then
        echo "Applying patches for versions older than v1.22..."
        git apply /patches/ringpdfgen.patch && \
        git apply /patches/ringfastpro.patch
    fi

    # Apply necessary build modifications for the new version
    echo "Applying build modifications..."
    find . -type f -name "*.sh" -exec sed -i 's/\bsudo\b//g' {} +
    find . -type f -name "*.sh" -exec sed -i 's/-L \/usr\/lib\/i386-linux-gnu//g' {} +
    find extensions/ringqt -name "*.sh" -exec sed -i 's/\bmake\b/make -j$(nproc)/g' {} +
    rm -rf extensions/ringraylib5/src/linux_raylib-5
    rm -rf extensions/ringtilengine/linux_tilengine
    rm -rf extensions/ringlibui/linux
    sed -i 's/ -I linux_raylib-5\/include//g; s/ -L $PWD\/linux_raylib-5\/lib//g' extensions/ringraylib5/src/buildgcc.sh
    sed -i '/extensions\/ringraylib5\/src\/linux/d' bin/install.sh
    sed -i 's/ -I linux_tilengine\/include//g; s/ -L $PWD\/linux_tilengine\/lib//g' extensions/ringtilengine/buildgcc.sh
    sed -i '/extensions\/ringtilengine/d' bin/install.sh
    sed -i 's/ -I linux//g; s/ -L \$PWD\/linux//g' extensions/ringlibui/buildgcc.sh
    sed -i '/extensions\/ringlibui\/linux/d' bin/install.sh
    sed -i 's/-L \/usr\/local\/pgsql\/lib//g' extensions/ringpostgresql/buildgcc.sh

    # Build the project
    echo "Building Ring from source..."
    cd build
    
    # Check if we're running in the light variant using RING_VARIANT environment variable
    if [ "$RING_VARIANT" = "light" ]; then
        echo "Building light variant with selected extensions..."
        
        # Remove unnecessary directories like in Dockerfile.light
        cd ..
        rm -rf applications documents marketing samples \
            tools/editors tools/formdesigner tools/help2wiki tools/ringnotepad tools/string2constant tools/ringrepl tools/tryringonline tools/folder2qrc tools/findinfiles language/tests \
            extensions/android extensions/libdepwin extensions/ringfreeglut extensions/ringallegro extensions/ringbeep extensions/ringmouseevent extensions/ringnappgui extensions/ringwinapi extensions/ringwincreg extensions/ringwinlib extensions/ringraylib5 extensions/ringtilengine extensions/ringlibui extensions/ringqt extensions/ringrogueutil extensions/ringsdl extensions/webassembly extensions/tutorial extensions/microcontroller
        cd build
        
        if bash buildgcc.sh -ring \
            -ringmurmurhash \
            -ringzip \
            -ringhttplib \
            -ringmysql \
            -ringthreads \
            -ringcjson \
            -ringinternet \
            -ringodbc \
            -ringpdfgen \
            -ringconsolecolors \
            -ringcurl \
            -ringlibuv \
            -ringopenssl \
            -ringsockets \
            -ringfastpro \
            -ringpostgresql \
            -ringsqlite \
            -ring2exe \
            -ringpm; then
            echo "Ring light variant built successfully."
        else
            echo "Failed to build Ring light variant from source."
            exit 1
        fi
    else
        echo "Building full variant with all extensions..."
        if bash buildgcc.sh; then
            echo "Ring built successfully."
        else
            echo "Failed to build Ring from source."
            exit 1
        fi
    fi
    cd ../bin
    bash install.sh
    
    # Return to the previous directory
    popd
fi

# Check if the RING_PACKAGES is not empty
if [ -n "$RING_PACKAGES" ]; then
    # Split the RING string into an array of words
    IFS=' ' read -r -a words <<< "$RING_PACKAGES"
    
    declare -a packages
    i=0
    n_words=${#words[@]}
    while [ $i -lt $n_words ]; do
        # Check for the pattern "<package> from <user>"
        if [ $((i + 2)) -lt $n_words ] && [ "${words[$i+1]}" = "from" ]; then
            packages+=("${words[$i]} from ${words[$i+2]}")
            i=$((i + 3))
        else
            packages+=("${words[$i]}")
            i=$((i + 1))
        fi
    done

    # Loop through each reconstructed package and install it
    for package in "${packages[@]}"; do
        echo "Installing $package..."
        ringpm install "$package"
    done
fi

# Check if the RING_OUTPUT_EXE is 'true'
if [ "$RING_OUTPUT_EXE" = "true" ]; then
    # Create executable from Ring source
    SCRIPT_DIR=$(dirname "$RING_FILE")
    SCRIPT_BASE=$(basename "$RING_FILE")
    
    pushd "$SCRIPT_DIR" > /dev/null
    ring2exe $RING_ARGS "$SCRIPT_BASE"
    popd > /dev/null
else
    # Run Ring script directly
    SCRIPT_DIR=$(dirname "$RING_FILE")
    SCRIPT_BASE=$(basename "$RING_FILE")

    pushd "$SCRIPT_DIR" > /dev/null

    ring $RING_ARGS "$SCRIPT_BASE"
    
    popd > /dev/null
fi
