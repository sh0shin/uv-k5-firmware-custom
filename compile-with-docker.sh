#!/usr/bin/env bash

set -eu -o pipefail

DOCKER_IMAGE="uvk5:build"
DOCKER_PLATFORM="linux/amd64"
FIRMWARE_DIR="${PWD}/compiled-firmware"

# ------------------ BUILD VARIANTS ------------------

FIRMWARE_CUSTOM=(
    EDITION_STRING=Custom
    TARGET=f4hwn.custom
)

FIRMWARE_STANDARD=(
    ENABLE_SPECTRUM=0
    ENABLE_FMRADIO=0
    ENABLE_AIRCOPY=0
    ENABLE_NOAA=0
    EDITION_STRING=Standard
    TARGET=f4hwn.standard
)

FIRMWARE_BANDSCOPE=(
    ENABLE_SPECTRUM=1
    ENABLE_FMRADIO=0
    ENABLE_VOX=0
    ENABLE_AIRCOPY=1
    ENABLE_FEAT_F4HWN_SCREENSHOT=1
    ENABLE_FEAT_F4HWN_GAME=0
    ENABLE_FEAT_F4HWN_PMR=1
    ENABLE_FEAT_F4HWN_GMRS_FRS_MURS=1
    ENABLE_NOAA=0
    ENABLE_FEAT_F4HWN_RESCUE_OPS=0
    EDITION_STRING=Bandscope
    TARGET=f4hwn.bandscope
)

FIRMWARE_BROADCAST=(
    ENABLE_SPECTRUM=0
    ENABLE_FMRADIO=1
    ENABLE_VOX=1
    ENABLE_AIRCOPY=1
    ENABLE_FEAT_F4HWN_SCREENSHOT=1
    ENABLE_FEAT_F4HWN_GAME=0
    ENABLE_FEAT_F4HWN_PMR=1
    ENABLE_FEAT_F4HWN_GMRS_FRS_MURS=1
    ENABLE_NOAA=0
    ENABLE_FEAT_F4HWN_RESCUE_OPS=0
    EDITION_STRING=Broadcast
    TARGET=f4hwn.broadcast
)

FIRMWARE_BASIC=(
    ENABLE_SPECTRUM=1
    ENABLE_FMRADIO=1
    ENABLE_VOX=0
    ENABLE_AIRCOPY=0
    ENABLE_FEAT_F4HWN_GAME=0
    ENABLE_FEAT_F4HWN_SPECTRUM=0
    ENABLE_FEAT_F4HWN_PMR=1
    ENABLE_FEAT_F4HWN_GMRS_FRS_MURS=1
    ENABLE_NOAA=0
    ENABLE_AUDIO_BAR=0
    ENABLE_FEAT_F4HWN_RESUME_STATE=0
    ENABLE_FEAT_F4HWN_CHARGING_C=0
    ENABLE_FEAT_F4HWN_INV=1
    ENABLE_FEAT_F4HWN_CTR=0
    ENABLE_FEAT_F4HWN_NARROWER=1
    ENABLE_FEAT_F4HWN_RESCUE_OPS=0
    EDITION_STRING=Basic
    TARGET=f4hwn.basic
)

FIRMWARE_RESCUEOPS=(
    ENABLE_SPECTRUM=0
    ENABLE_FMRADIO=0
    ENABLE_VOX=1
    ENABLE_AIRCOPY=1
    ENABLE_FEAT_F4HWN_SCREENSHOT=1
    ENABLE_FEAT_F4HWN_GAME=0
    ENABLE_FEAT_F4HWN_PMR=1
    ENABLE_FEAT_F4HWN_GMRS_FRS_MURS=1
    ENABLE_NOAA=1
    ENABLE_FEAT_F4HWN_RESCUE_OPS=1
    EDITION_STRING=RescueOps
    TARGET=f4hwn.rescueops
)

FIRMWARE_GAME=(
    ENABLE_SPECTRUM=0
    ENABLE_FMRADIO=1
    ENABLE_VOX=0
    ENABLE_AIRCOPY=1
    ENABLE_FEAT_F4HWN_GAME=1
    ENABLE_FEAT_F4HWN_PMR=1
    ENABLE_FEAT_F4HWN_GMRS_FRS_MURS=1
    ENABLE_NOAA=0
    ENABLE_FEAT_F4HWN_RESCUE_OPS=0
    EDITION_STRING=Game
    TARGET=f4hwn.game
)

build() {
    FIRMWARE_MSG="$1"
    shift
    FIRMWARE_OPTS=( "$@" )

    DOCKER_BUILD_OPTS=(
        --platform "$DOCKER_PLATFORM"
        --tag "$DOCKER_IMAGE"
        .
    )

    DOCKER_RUN_OPTS=(
        --platform "$DOCKER_PLATFORM"
        --rm
        --volume "${FIRMWARE_DIR}:/app/compiled-firmware"
        "$DOCKER_IMAGE"
    )

    mkdir -p "$FIRMWARE_DIR"

    echo "⚙️ Rebuild Docker image '$DOCKER_IMAGE'..."
    if ! docker buildx build "${DOCKER_BUILD_OPTS[@]}"
    then
        echo "❌  Failed to build docker image"
        exit 1
    fi

    echo "$FIRMWARE_MSG"
    docker run "${DOCKER_RUN_OPTS[@]}" /bin/bash -c "make -s ${FIRMWARE_OPTS[*]} && cp f4hwn* compiled-firmware/"
}

# -------------------- CLEAN ALL ---------------------

clean() {
    echo "🧽  Cleaning all"
    docker image rm "$DOCKER_IMAGE" 2>/dev/null || true
    docker buildx prune --force
    docker buildx history ls | awk '/uv-k5-firmware-custom/ NR>1 {print $1}' | xargs docker buildx history rm
    make clean
    rm -rf "$FIRMWARE_DIR"
}

# ------------------ MENU ------------------

case "${1:-}" in
    clean)
        clean
        ;;
    custom)
        build "🔧  Custom compilation..." \
            "${FIRMWARE_CUSTOM[@]}"
        ;;
    standard)
        build "📦  Standard compilation..." \
            "${FIRMWARE_STANDARD[@]}"
        ;;
    bandscope)
        build "📺  Bandscope compilation..." \
            "${FIRMWARE_BANDSCOPE[@]}"
        ;;
    broadcast)
        build "📻  Broadcast compilation..." \
            "${FIRMWARE_BROADCAST[@]}"
        ;;
    basic)
        build "☘️ Basic compilation..." \
            "${FIRMWARE_BASIC[@]}"
        ;;
    rescueops)
        build "🚨  RescueOps compilation..." \
            "${FIRMWARE_RESCUEOPS[@]}"
        ;;
    game)
        build "🎮  Game compilation..." \
            "${FIRMWARE_GAME[@]}"
        ;;
    all)
        $0 bandscope
        $0 broadcast
        $0 basic
        $0 rescueops
        $0 game
        ;;
    *)
        echo "Usage: $0 {clean|custom|standard|bandscope|broadcast|basic|rescueops|game|all}"
        exit 1
        ;;
esac
