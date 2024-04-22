# post-macos-upgrade-recon.jss

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
 - By default logs are stored in `/var/log/post-macos-upgrade-recon.jss.log`
 - By default the macOS version tracking plist is `/Library/Preferences/edu.csumb.it.configuration.plist`

