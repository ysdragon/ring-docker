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
    if ! git checkout -f FETCH_HEAD > /dev/null 2>&1; then
        echo "Error: Failed to checkout $RING_VERSION"
        exit 1
    fi

    # Check the RING_VERSION and apply patches if it's under v1.22
    version_num=$(echo "$RING_VERSION" | sed 's/^v//')
    if [ "$(echo "$version_num < 1.22" | bc)" -eq 1 ] && [ "$RING_VERSION" != "master" ]; then
        echo "Applying patches for versions older than v1.22..."
        if ! git apply /patches/ringpdfgen.patch; then
            echo "Error: Failed to apply ringpdfgen.patch"
            exit 1
        fi
        if ! git apply /patches/ringfastpro.patch; then
            echo "Error: Failed to apply ringfastpro.patch"
            exit 1
        fi
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
    if ! bash install.sh; then
        echo "Error: Failed to install Ring"
        exit 1
    fi
    
    # Verify Ring binary exists and is executable
    if ! command -v ring &> /dev/null; then
        echo "Error: Ring binary not found after installation"
        exit 1
    fi
    
    # Return to the previous directory
    popd
fi

# Check if the RING_PACKAGES is not empty
if [ -n "$RING_PACKAGES" ]; then
    echo "$RING_PACKAGES" | while IFS= read -r line; do
        [ -z "$line" ] && continue
        
        # Parse the line into package specifications
        package_args=()
        words=($line)
        i=0
        while [ $i -lt ${#words[@]} ]; do
            package="${words[$i]}"
            
            # Check if next two words are "from username"
            if [ $((i + 2)) -lt ${#words[@]} ] && [ "${words[$((i + 1))]}" = "from" ]; then
                username="${words[$((i + 2))]}"
                ringpm install "$package" from "$username"
                i=$((i + 3))
            else
                ringpm install "$package"
                i=$((i + 1))
            fi
        done
    done
fi

# Check if RING_FILE is set before attempting execution
if [ -n "$RING_FILE" ]; then
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
elif [ $# -gt 0 ]; then
    # If no RING_FILE but arguments are provided, execute them directly
    exec "$@"
fi
