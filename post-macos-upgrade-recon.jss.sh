#!/bin/zsh

# Jason Filice
# jfilice@csumb.edu
# Technology Support Services in IT
# California State University, Monterey Bay
# https://csumb.edu/it


# This script requires Jamf Pro binary to be installed.
# Run it with no arguments. 
# 
# Use as script in Jamf JSS.

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

# ##########################################
# VARIABLES - edit to suite your organization and preferred locations
# ##########################################
# 


set -x

currentOSVersion=$(/usr/bin/sw_vers -productVersion)
currentOSBuild=$(/usr/bin/sw_vers --buildVersion)
lastRecordedOSVersion=$(/usr/bin/defaults read /Library/Preferences/edu.csumb.custom.plist OS_Version 2> /dev/null)
lastRecordedOSBuild=$(/usr/bin/defaults read /Library/Preferences/edu.csumb.custom.plist OS_Build 2> /dev/null)
# ##########################################


function initial_network_test () {
    # Include rc.common for the CheckForNetwork function
    . /etc/rc.common

    local counter=1

    echo "Waiting up to 240 minutes for an active network connection..."
    CheckForNetwork
    while [[ "${NETWORKUP}" != "-YES-" ]] && [[ $counter -ne 2880 ]]; do
        /bin/sleep 5
        NETWORKUP=
        CheckForNetwork
        ((counter++))
    done

    if [[ "${NETWORKUP}" == "-YES-" ]]; then
        echo "Network connection appears to be active; continuing."
    else
        echo "Network connection appears to be offline; exiting."
        exit 1
    fi
}

function external_dns_lookup_test () {
    local jamfPlist domainToLookup externalDNSServerIP dnsLookupResult timer

    jamfPlist="/Library/Preferences/com.jamfsoftware.jamf.plist"
    domainToLookup=$(/usr/bin/defaults read "$jamfPlist" jss_url | /usr/bin/sed s'/.$//' | /usr/bin/awk -F '/' '{print $NF}' | /usr/bin/cut -f1 -d":")
    externalDNSServerIP="8.8.8.8"
    dnsLookupResult=$(/usr/bin/dig @"$externalDNSServerIP" "$domainToLookup" 2> /dev/null | /usr/bin/grep -A1 'ANSWER SECTION' | /usr/bin/grep "$domainToLookup")
    timer="120"

    # Do an external DNS lookup on the Jamf Pro URL that this Mac reports to, if we get an answer from the external DNS server we have network
    echo "Performing external DNS lookup on $domainToLookup..."
    while [[ -z "$dnsLookupResult" ]] && [[ "$timer" -gt "0" ]]; do
        dnsLookupResult=$(dig @"$externalDNSServerIP" "$domainToLookup" 2> /dev/null | /usr/bin/grep -A1 'ANSWER SECTION' | /usr/bin/grep "$domainToLookup")
        sleep 1
        ((timer--))
    done

    if [[ -n "$dnsLookupResult" ]]; then
        echo "DNS lookup succeeded; continuing."
    else
        echo "DNS lookup failed; exiting."
        exit 1
    fi
}

# Run our functions to make sure we can access the Jamf Pro server
initial_network_test
external_dns_lookup_test

# If we have recorded the OS version before, check to see if our recorded value matches the current version
if [[ -n "$lastRecordedOSBuild" ]]; then
    if [[ ! "$currentOSBuild" == "$lastRecordedOSBuild" ]]; then
        echo "This Mac has been updated from $lastRecordedOSVersion ($lastRecordedOSBuild) to $currentOSVersion ($currentOSBuild); running jamf recon..."
        if /usr/local/bin/jamf recon # jamf recon successful
        then
            # Record the current OS version to use as comparison upon next run
            /usr/bin/defaults write /Library/Preferences/edu.csumb.custom.plist OS_Version "$currentOSVersion"
            /usr/bin/defaults write /Library/Preferences/edu.csumb.custom.plist OS_Build "$currentOSBuild"
        fi
    else
        echo "No change in macOS version detected."
    fi
else
    echo "This appears to be the first run; initializing plist."
    # Record the current OS version to use as comparison upon next run
    /usr/bin/defaults write /Library/Preferences/edu.csumb.custom.plist OS_Version "$currentOSVersion"
    /usr/bin/defaults write /Library/Preferences/edu.csumb.custom.plist OS_Build "$currentOSBuild"
fi

exit
