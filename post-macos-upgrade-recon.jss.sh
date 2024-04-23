#!/bin/zsh

# Jason Filice
# jfilice@csumb.edu
# Technology Support Services in IT
# California State University, Monterey Bay
# https://csumb.edu/it

# Use as script in Jamf JSS.

# This script requires Jamf Pro management framework to be installed.
# Run it with the following optional positional parameters. 
# If these parameters are not passed to the script, then they must be hardcoded in the VARIABLES below.
# 
# 	[PlistPath]
# 		Full path to .plist file used to record the OS version/build values.
# 
# 	[checkJSSConnection_retry]
# 		The number of times the Jamf Pro server connection should be tested; while waiting 5 seconds between tries.
# 

# https://github.com/jfiliceatcsumb/recon-after-macos-update

# Change History:
# 2024/04/22:	forked from alectrona/recon-after-macos-update https://github.com/alectrona/recon-after-macos-update
# 2024/04/22:	Modified to run as Jamf Pro policy scripts.
# 2024/04/22:	Changed functionality to read the OS build number rather than the OS version number. 
# 				Build number will always change when the OS is updated, even when the OS version number does not always change after an update.
# 				Credit: https://docs.google.com/document/d/1QrfX9WBzG2Z3fCt5n9grpu6hpyvRkSQ6RUNHOCNwCXs/edit#bookmark=id.k2szjaauy98q
# 

SCRIPTNAME=`/usr/bin/basename "$0"`
SCRIPTDIR=`/usr/bin/dirname "$0"`

# Jamf JSS Parameters 1 through 3 are predefined as mount point, computer name, and username

pathToScript=$0
mountPoint=$1
computerName=$2
userName=$3

shift 3
# Shift off the $1 $2 $3 parameters passed by the JSS so that parameter 4 is now $1

echo "pathToScript=$pathToScript"
echo "mountPoint=$mountPoint"
echo "computerName=$computerName"
echo "userName=$userName"


set -x

# ##########################################
# VARIABLES - edit to suite your organization and preferred locations
# ##########################################
# 
# Full path to .plist file used to record the OS version/build values
PlistPath="/Library/Preferences/edu.csumb.custom.plist"

# The number of times the Jamf Pro server connection should be tested; while waiting 5 seconds between tries.
checkJSSConnection_retry=720
# ##########################################

# Read parameters passed from JSS
PlistPath_Param=${1}
checkJSSConnection_retry_Param=${2}

# Assign argument parameters from JSS, or if not assigned, use hardcoded values.
PlistPath=${PlistPath_Param:-$PlistPath}
checkJSSConnection_retry=${checkJSSConnection_retry_Param:-$checkJSSConnection_retry}
lastRecordedOSVersion=$(/usr/bin/defaults read "${PlistPath}" OS_Version 2> /dev/null)
lastRecordedOSBuild=$(/usr/bin/defaults read "${PlistPath}" OS_Build 2> /dev/null)
currentOSVersion=$(/usr/bin/sw_vers -productVersion)
currentOSBuild=$(/usr/bin/sw_vers --buildVersion)

if [ -z "${PlistPath}" ]; then
	echo "Error: Missing parameter value for PlistPath"
	exit 1
fi
if [ -z "${checkJSSConnection_retry}" ]; then
	echo "Error: Missing parameter value for checkJSSConnection_retry"
	exit 1
fi

echo "Running jamf checkJSSConnection to make sure we can access the Jamf Pro server..."
/usr/local/bin/jamf checkJSSConnection -retry ${checkJSSConnection_retry} -randomDelaySeconds 5

# If we have recorded the OS version before, check to see if our recorded value matches the current version

if [[ -n "$lastRecordedOSBuild" ]]; then
    if [[ ! "$currentOSBuild" == "$lastRecordedOSBuild" ]]; then
        echo "This Mac has been updated from $lastRecordedOSVersion ($lastRecordedOSBuild) to $currentOSVersion ($currentOSBuild); running jamf recon..."
        if /usr/local/bin/jamf recon -randomDelaySeconds 10 # jamf recon successful
        then
            # Record the current OS version to use as comparison upon next run
            /usr/bin/defaults write "${PlistPath}" OS_Version -string "$currentOSVersion"
            /usr/bin/defaults write "${PlistPath}" OS_Build -string "$currentOSBuild"
        fi
    else
        echo "No change in macOS version detected."
    fi
else
    echo "This appears to be the first run; initializing plist and running jamf recon..."
    # Record the current OS version to use as comparison upon next run
    /usr/bin/defaults write "${PlistPath}" OS_Version -string "$currentOSVersion"
    /usr/bin/defaults write "${PlistPath}" OS_Build -string "$currentOSBuild"
    /usr/local/bin/jamf recon -randomDelaySeconds 10 
fi

echo "Reading ${PlistPath}..."
/usr/bin/defaults read "${PlistPath}"
exit
