# post-macos-upgrade-recon.jss.sh

Jamf Pro script that performs a Jamf Pro inventory update when a change in macOS version is detected. This script should be run by a Jamf Pro policy that is configured with the following triggers:
- Startup
- Execution Frequency: Ongoing
- Make Available Offline 

This is a relatively simple Jamf Pro script that performs the following when triggered at Startup:
1. Checks for network connectivity before moving on
2. Determines the macOS version and writes that to a tracking plist (the first time it runs)
3. If at any subsequent boot ups the macOS version changes (following a macOS upgrade), the script will perform a Jamf Pro inventory update (recon)
4. If the recon is successful, it will update the tracking plist so that the process can repeat itself after any other macOS upgrades

Notes:
 - This script requires Jamf Pro management framework to be installed.
 - Run it with the following optional positional parameters. 
 - If these parameters are not passed to the script, then they must be hardcoded in the VARIABLES in the script.
	- `PlistPath`
   	Full path to .plist file used to record the OS version/build values.
	- `checkJSSConnection_retry`
   	 The number of times the Jamf Pro server connection should be tested; while waiting 5 seconds between tries.
 - By default logs are stored in `/var/log/jamf.log`
 - By default the macOS version tracking plist is `/Library/Preferences/edu.csumb.custom.plist`

