# OpenRVS

By the OpenRVS team:
  - original author: Twi
  - programming: Twi and Will
  - game service fix: chriswak
  - community hosting: Tony and SMC Clan

A patch to fix Red Storm Entertainment's mistakes (intentional and otherwise). Allows multiplayer again, enables more serious modding, implements some QOL fixes.

## Installing

For instructions on installing OpenRVS, see [ModDB](https://www.moddb.com/games/tom-clancys-rainbow-six-3-raven-shield/downloads/raven-shield-openrvs-patch-v15).

## To Do

See GitHub issues list for the complete to-do. Feel free to request modifications and additions there as well.

## The OpenRVS Registry

Since v1.5, OpenRVS servers send an extra UDP beacon to a web server running
[openrvs-registry](https://github.com/willroberts/openrvs-registry). This app tracks
all known servers, healthchecks them to hide unhealthy serers, and automatically
adds new servers to the list when the UDP beacon is received.

Since v1.6, the config key is `RegistryServerHost` instead of `RegistryServerIP`,
and DNS domain names are supported (rather than just IP addresses).

The registry listens for beacons on UDP port 8080, and listens for server list
requests on HTTP port 8080 (on the /servers URL).

The IP and port for the deployment can be configured in `openrvs.ini`:

```ini
[OpenRVS.OpenBeacon]
RegistryServerHost=api.openrvs.org
RegistryServerPort=8080
```

NOTE: The native code (not modifiable with UnrealScript) does not accept DNS names,
so the registry server IP must be an IP address.

## Local Development

**Note: You should test your changes using this process BEFORE opening a pull request!**

First, you will need to download [Twi's Raven Shield SDK](https://www.moddb.com/mods/raven-shield-software-development-kit). Put this somewhere convenient (such as `C:\rvssdk`).

The SDK expects the OpenRVS code (both `OpenRVS` and `OpenRenderFix` directories) to be inside the `Code Environment` directory in the SDK folder. Be sure to copy `\PATH\TO\GIT\REPO\{OpenRVS,OpenRenderFix}` to `\PATH\TO\SDK\Code Environment` to operate on the latest version of your code.

1. Open a command prompt in the `SDK2` directory.
1. Run `"SDK ToolBelt.bat"` to enter the CLI
1. Run `160` to activate the SDK for Raven Shield v1.60
1. Type `compile` to enter the compiler, and then type `OpenRVS` to compile OpenRVS. Address any errors or warnings if necessary. Type `log` to show more detail. Note: If you see an error regarding `appPreExit`, this can be ignored. This happens when building 1.60 code with the 1.56 compiler, and the compiled output will still be created successfully at `\PATH\TO\SDK\OpenRVS.u`
1. Type `strip` to enter the symbol/docstring stripper, and then type `OpenRVS.u` to run it. This will reduce output file size by around 60%
1. Copy `OpenRVS.u` and/or `OpenRenderFix.u` to your game directory's `system` folder (both client and server)
1. Test your changes in-game by connecting to the server

Repeat the above process for `OpenRenderFix` instead of `OpenRVS` to compile changes to weapon rendering in multiplayer.

In order to enable debug logging, edit `OpenLogger.uc` and change `false` to `true` where instructed.

## OpenRVS Libraries

We have included a number of reusable UnrealScript2 libraries in OpenRVS:

- OpenLogger.uc: For writing OpenRVS logs to system\ravenshield.log
- OpenString.uc: For common operations like Split() and RemoveQuotes()
- OpenTimer.uc: For measuring how long things take to execute
- OpenHTTPClient.uc: For sending HTTP requests and reading responses

## Version History

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
