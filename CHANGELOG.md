## Version History

#### Release 1.10

- Improves backwards compatibility of `OpenRenderFix` between older clients and updated servers

#### Release 1.9

- Enables overrides of MaxClientRate for clients and servers
- Softens join checks to prevent greyed-out servers with long map rotations
- Fixes OpenRenderFix compatibility (1.8 clients could not connect to 1.6 servers)
- Rearranges beacon field order to ensure critical fields come first, preventing greyed-out servers with missing version / player list data

#### Release 1.8

- Repairs the server favorites feature, along with sorting and filtering favorites (Fixes #35)
- Fixes the server info panel, showing map rotation and server settings (Fixes #34)
- Fixes filtering servers (Fixes #33)
- Improves compatibility checks for OpenRVS versions
- Fixes dedicated server indicator icons, sorting, and filtering (Fixes #30)
- Fixes failure to join Internet servers after playing on LAN (Fixes #62)
- Fixes missing HUD when hosting or joining a non-dedicated (listen) server (Fixes #4)
- Improves debug logging and makes it opt-in (Fixes #42)
- Refactors part of OpenFOV into OpenConfigManager (Fixes #41)
- Adds multi-character separator support to OpenString.Split() (Fixes #37)
- Updates the download URL to GitHub releases

#### Release 1.7

- Improves beacon parsing and config loading, which should fix automatic server registration when using nonstandard ports
- Improves parsing of IPs, resulting in exact matching / correctness for IP bans
- Fixes a bug which could result in an empty server list when initial parsing failed
- Fixes several leaks and cases of duplicated or per-tick work, resulting in minor performance improvements for clients and servers
- Adds new tooling (make build) for compiling on Linux systems

#### Release 1.6

- Replaces hardcoded IPs with DNS names for improved reliability
- Updates the default server list to http://api.openrvs.org/servers
- Updates the default beacon server to udp://api.openrvs.org:8080
- Updates fallback server list
- Updates documentation
- Adds INI files to repo for easier packaging of releases

#### Release 1.5

- server ping in multiplayer menu added
- server sorting in multiplayer menu added
- version checking added - clients and servers not fully updated will write a warning to log, and clients will see a popup message with download link
- support for automatic server registration added - needs to be fully implemented on master list host for functionality
- support for CSV-format master server list added

#### Release 1.4

- support for custom FOVs added - including fix for weapon fov rendering
- support for loading the game straight into a mod added
- added back beta feature unlimited practice button
- mod actors can now use "CMD" console command
- support for cheat manager mods added
- multiplayer has new actor "OpenRenderFix.OpenFix" to help widescreen players

#### Release 1.3

- behind-the-scenes errors when first loading maplist fixed
- issue with clogging user.ini fixed (?)
- partial support for custom mods dedicated servers begun
- support for modded singleplayer gametypes added

#### Release 1.2

- buggy code in multiplayer menus cleaned up a bit
- enemy positioning data now sent at all times to players; fixes issues with invisible tangos on a laggy connection

#### Release 1.1

- Ubisoft mod locking removed; any mod can now work without extra help

#### Release 1.0

- server list disappearing when using escape menu fixed

#### Beta 0.9

- massive freeze when clicking multiplayer fixed

#### Beta 0.8

- server list now fetches some current info from each server
- added ability to specify alternate server list source
- servers loaded from the backup list (if connection to the configured server list fails) also fetch live info

#### Beta 0.7

- rewrote server list connection to fix game freeze when attempting to connect

#### Beta 0.6

- logs incoming player IP addresses
- fixes issue where server list retrieved from internet could be too large and not display properly or at all
- backup server list updated

#### Beta 0.5

- bypasses UBI.com login
- bypasses cd key client verification
- fixes bug in join IP window
- gets serverlist over http
- allows connection to LAN server through internet
- fixes issue with connecting to non-N4 server
- bypasses cd key server verification
- allows banning via IP
- fixes issue with multiple servers using same ban list
