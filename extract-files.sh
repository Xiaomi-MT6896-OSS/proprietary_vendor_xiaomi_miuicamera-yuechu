#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=vendor
VENDOR=xiaomi/miuicamera-yuechu

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

export TARGET_ENABLE_CHECKELF=true

# If XML files don't have comments before the XML header, use this flag
# Can still be used with broken XML files by using blob_fixup
export TARGET_DISABLE_XML_FIXING=true

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        system/priv-app/MiuiCamera/MiuiCamera.apk)
            [ "$2" = "" ] && return 0
            local apktool="${ANDROID_ROOT}/prebuilts/extract-tools/common/apktool/apktool.jar"
            local apk_dir
            apk_dir="$(mktemp -d)"
            java -jar "${apktool}" d -f -o "${apk_dir}" "${2}"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0001-Assume-that-mod_device-is-global.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0002-Fix-rebuilt-resource-and-beauty-fallbacks.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0003-Drop-null-capture-result.patch"
            mkdir -p "${apk_dir}/assets/obfu_res/res/drawable"
            cp "${apk_dir}/res/drawable/ic_west_coast_princess.webp" "${apk_dir}/assets/obfu_res/res/drawable/ic_west_coast_princess.webp"
            java -jar "${apktool}" b "${apk_dir}" -o "${2}"
            rm -rf "${apk_dir}"
            ;;
        system/lib64/libcamera_algoup_jni.xiaomi.so)
            [ "$2" = "" ] && return 0
            grep -q "libgui_shim_miuicamera.so" "${2}" || "${PATCHELF}" --add-needed "libgui_shim_miuicamera.so" "${2}"
            "${SIGSCAN}" -p "08 AD 40 F9" -P "08 A9 40 f9" -f "${2}"
            ;;
        system/lib64/libcamera_mianode_jni.xiaomi.so|\
        system/lib64/libcamera_ispinterface_jni.xiaomi.so)
            [ "$2" = "" ] && return 0
            grep -q "libgui_shim_miuicamera.so" "${2}" || "${PATCHELF}" --add-needed "libgui_shim_miuicamera.so" "${2}"
            ;;
        system/lib64/vendor.mediatek.hardware.camera.isphal-V1-ndk.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.hardware.graphics.common-V5-ndk.so" "android.hardware.graphics.common-V7-ndk.so" "${2}"
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
