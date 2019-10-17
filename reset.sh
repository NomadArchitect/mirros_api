#!/bin/bash
ENV=$1

if [[ ${ENV} == 'production' && -n ${SNAP} ]]; then
    rm -rf "$SNAP_DATA/rails/.bundle/*" \
           "$SNAP_DATA/rails/vendor/*" \
           "$SNAP_DATA/rails/db/*" \
           "$SNAP_DATA/rails/Gemfile" \
           "$SNAP_DATA/rails/Gemfile.lock"

    cp -r "$SNAP/api/bundle_installed/*" "$SNAP_DATA/rails/.bundle"
    cp -r "$SNAP/api/vendor_installed/*" "$SNAP_DATA/rails/vendor"
    cp -r "$SNAP/api/db_installed/*" "$SNAP_DATA/rails/db"
    cat "$SNAP/api/Gemfile_installed" > "$SNAP_DATA/rails/Gemfile"
    cat "$SNAP/api/Gemfile.lock_installed" > "$SNAP_DATA/rails/Gemfile.lock"
    bundle clean --force
else
    git checkout -- Gemfile
    git checkout -- Gemfile.lock
    bundle clean
fi
