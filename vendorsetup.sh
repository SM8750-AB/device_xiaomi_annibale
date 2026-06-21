#!/bin/bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Locate the root of the Android source tree
if [ -n "$ANDROID_BUILD_TOP" ]; then
    ROOT_DIR="$ANDROID_BUILD_TOP"
else
    # Find upward
    curr_dir="$PWD"
    while [ "$curr_dir" != "/" ]; do
        if [ -f "$curr_dir/build/envsetup.sh" ]; then
            ROOT_DIR="$curr_dir"
            break
        fi
        curr_dir=$(dirname "$curr_dir")
    done
fi

if [ -z "$ROOT_DIR" ]; then
    ROOT_DIR="$PWD"
fi

# Detect current script directory and git branch of the device tree
if [ -n "$BASH_SOURCE" ]; then
    SCRIPT_PATH="${BASH_SOURCE[0]}"
else
    SCRIPT_PATH="$0"
fi

DEVICE_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
BRANCH=""
if [ -d "$DEVICE_DIR/.git" ]; then
    BRANCH=$(git -C "$DEVICE_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

echo -e "\033[0;34m=== Annibale Auto-Cloner Vendorsetup ===\033[0m"
if [ -n "$BRANCH" ]; then
    echo -e "\033[0;32mDetected active branch: $BRANCH\033[0m"
fi

# Repositories to clone formatted as "target_path|repo_url"
REPOS=(
    "device/xiaomi/annibale-kernel|https://github.com/SM8750-AB/device_xiaomi_annibale-kernel"
    "hardware/lineage/compat|https://github.com/SM8750-AB/android_hardware_lineage_compat"
    "packages/apps/Aperture|https://github.com/SM8750-AB/android_packages_apps_Aperture"
    "hardware/xiaomi|https://github.com/SM8750-AB/hardware_xiaomi"
    "vendor/xiaomi/annibale|https://github.com/SM8750-AB/vendor_xiaomi_annibale"
)

for repo_info in "${REPOS[@]}"; do
    path="${repo_info%%|*}"
    url="${repo_info##*|}"
    target_path="$ROOT_DIR/$path"
    
    if [ -d "$target_path" ]; then
        echo -e "\033[0;33m[annibale] $path already exists, skipping.\033[0m"
    else
        echo -e "\033[0;36m[annibale] Cloning $path...\033[0m"
        mkdir -p "$(dirname "$target_path")"
        if [ -n "$BRANCH" ]; then
            git clone -b "$BRANCH" "$url" "$target_path" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo -e "\033[0;33m[annibale] Branch $BRANCH not found in $url. Cloning default branch...\033[0m"
                git clone "$url" "$target_path"
            fi
        else
            git clone "$url" "$target_path"
        fi
    fi
done

# Script to dynamically reassemble .part* files (run after cloning vendor)
for file in $(find "$ROOT_DIR/vendor/xiaomi/annibale" -type f -name "*.part00" 2>/dev/null); do
    base_name=${file%.part00}
    cat ${base_name}.part* > "$base_name"
    echo "Reassembly of $base_name complete!"
done

