# OpenRVS
OpenRVS is a community patch for Tom Clancy's Rainbow Six 3: Raven Shield. It overrides select UnrealScript classes to repair broken
features and add small improvements. Primarily, OpenRVS enables online multiplayer with community servers.

## What It Does
- Replaces the old Ubisoft-managed server list (shut down in 2016) with a community server list.
- Enables automatic registration of servers in the server list. Once a server starts, clients see it in the list within seconds.
- Overrides the client's network data rate to 100KB/s. Players no longer need to select T1/T3 in network settings.
- Improves support for custom mods and game types.
- Enables adjustment of settings like FOV in `openrvs.ini`.

## Installation Instructions
1. Stop your game if it's running.
2. Download the latest release ZIP from the [Releases page](https://github.com/OpenRVS-devs/OpenRVS/releases).
3. Extract the contents of the OpenRVS ZIP file to your game's `system` directory.
4. Optionally adjust your FOV in `openrvs.ini`.
5. Launch the game! You'll see a list of servers to choose from, or you can join by IP address.

There is one additional recommended step to avoid a brief hang when joining multiplayer. The game still tries to contact Ubisoft's
now-offline servers, so you can patch `system/R6GameService.dll` to prevent this. Simply replace this file with
[Chriswak's patched version](https://github.com/willroberts/raven-shield-2020/blob/main/R6GameService.dll). Alternatively, consider
client-side mods like [EnhancedRS3](https://github.com/Joshhhuaaa/EnhancedRS3) which provide this functionality and more.

## Dedicated Server Instructions
1. Stop your server process if it's running.
2. Download the latest release ZIP from the [Releases page](https://github.com/OpenRVS-devs/OpenRVS/releases).
3. Extract the contents of the OpenRVS ZIP file to your game's `system` directory.
4. Edit `RavenShield.mod` in your game's `Mods` directory, and add the following lines. NOTE: The `OpenRVS.OpenBeacon` line should replace
   the `IpDrv.UdpBeacon` line. This may not be compatible with N4Admin installations.
```ini
ServerActors=OpenRVS.OpenServer
ServerActors=OpenRVS.OpenBeacon
ServerActors=OpenRenderFix.OpenFix
ServerPackages=OpenRenderFix
```
5. Edit `system/RavenShield.ini`, and ensure that your `ServerBeaconPort` is set to exactly 1000 above your server's `Port`, and that
   `BeaconPort` is exactly 2000 above your server's `Port`.
6. Launch the server!

When the server starts, it will self-register with the community server list. Clients should be able to see it within seconds. If your
server is not appearing, open an issue for assistance.

## Listen (Non-Dedicated) Server Instructions
Support for listen servers is experimental. Follow the dedicated server instructions above before creating a game. OpenRVS includes a fix
for missing HUD/UI elements on clients joining listen servers via `OpenRenderFix.u`. The client and server need to have the same version of
this file.

## Local Development
See [CONTRIBUTING.md](CONTRIBUTING.md).

## Version History
See [CHANGELOG.md](CHANGELOG.md).

## Credits
By the OpenRVS team:
  - original author: Twi
  - programming: Twi and Will
  - game service fix: chriswak
  - community hosting: Tony and SMC Clan

Thanks to: Tony, Psycho, Legacy, juguLator01, SMC and ShadowSquad clans, and the AllR6 community.

## License
GPL v3
