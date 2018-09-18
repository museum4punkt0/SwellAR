#!/bin/bash

# This script sets CFBundleVersion to the number of commits in the Git repo.
# It also adds a custom "LastCommit" key to the Info.plist, containing the last commit hash.
# The script does NOT touch the CFBundleShortVersionString, which should be changed manually & commited into the repo.

# Only the final product files are changed, the project's Info.plist is NOT updated.

LAST_COMMIT=$(git log --pretty=format:'%h' -n 1)
if [[ $(git status --porcelain) ]]; then
    LAST_COMMIT="${LAST_COMMIT}-dirty"
fi

if [ $(git rev-parse --abbrev-ref HEAD) = "master" ]; then
    MASTER_COMMIT_COUNT=$(git rev-list --count HEAD)
    BRANCH_COMMIT_COUNT=0
    BUNDLE_VERSION="$MASTER_COMMIT_COUNT"
else
    BRANCH_COMMIT_COUNT=$(git rev-list --count master..)
    if [ $BRANCH_COMMIT_COUNT = 0 ]; then
        MASTER_COMMIT_COUNT=$(git rev-list --count master)
    else
        MASTER_COMMIT_COUNT=$(git rev-list --count $(git rev-list master.. | tail -n 1)^)
    fi
    BUNDLE_VERSION="${MASTER_COMMIT_COUNT}.${BRANCH_COMMIT_COUNT}"
fi

echo "LAST_COMMIT: $LAST_COMMIT"
echo "MASTER_COMMIT_COUNT: $MASTER_COMMIT_COUNT"
echo "BRANCH_COMMIT_COUNT: $BRANCH_COMMIT_COUNT"
echo "BUNDLE_VERSION: $BUNDLE_VERSION"

INFO_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :LastCommit string $LAST_COMMIT" "$INFO_PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :LastCommit $LAST_COMMIT" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "$INFO_PLIST"


# The following part of the script puts the version into the settings bundle.
# It looks in the Root.plist for a PSTitleValueSpecifier with the Key "Version" and replaces its DefaultValue.
# It also looks for a PSGroupSpecifier item with a FooterText of "LastCommit" and replaces that, if found.

SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
PREF_VERSION="${SHORT_VERSION} ($BUNDLE_VERSION)"

SETTINGS_PLIST="${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/Settings.bundle/Root.plist"

PREF_COUNT=$(/usr/libexec/PlistBuddy -c "Print PreferenceSpecifiers:" "$SETTINGS_PLIST" | grep "Dict" | wc -l)
PREF_COUNT=$(expr $PREF_COUNT - 1)
for I in $(seq 0 $PREF_COUNT); do
    TYPE=$(/usr/libexec/PlistBuddy -c "Print PreferenceSpecifiers:${I}:Type" "$SETTINGS_PLIST")
    if [ $TYPE = "PSTitleValueSpecifier" ]; then
        if [ $(/usr/libexec/PlistBuddy -c "Print PreferenceSpecifiers:${I}:Key" "$SETTINGS_PLIST") = "Version" ]; then
            /usr/libexec/PlistBuddy -c "Set PreferenceSpecifiers:${I}:DefaultValue $PREF_VERSION" "$SETTINGS_PLIST"
        fi
    fi
    if [ $TYPE = "PSGroupSpecifier" ]; then
        if [ $(/usr/libexec/PlistBuddy -c "Print PreferenceSpecifiers:${I}:FooterText" "$SETTINGS_PLIST") = "LastCommit" ]; then
            /usr/libexec/PlistBuddy -c "Set PreferenceSpecifiers:${I}:FooterText $LAST_COMMIT" "$SETTINGS_PLIST"
        fi
    fi
done
