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

For compatible releases, reuse the exact OpenRenderFix binary distributed with
v1.6, renamed from `OpenRenderFix.utx` to `OpenRenderFix.u`. Do not recompile
that package for distribution: reverting its source does not restore the released
package identity. The build copies and verifies the pinned binary in `vendor/OpenRenderFix-v1.6`
instead of compiling or stripping it. `make release` rejects any different binary. Keep only one
copy installed. Changes to this shared package require a separate compatibility
plan and cross-version join testing.

This preserves the v1.6 package identity, not every previously shipped identity:
v1.7 and v1.8 included incompatible rebuilds of `OpenRenderFix`. Affected players
can keep their existing `OpenRVS.u` and replace only OpenRenderFix with the v1.9
copy, removing other installed copies first. Servers must use the same canonical
package too. The listen-server HUD condition does not limit package checks:
`ServerPackages=OpenRenderFix` requires a matching package on dedicated servers
as well. See [the compatibility investigation](reports/openrenderfix-compatibility.md)
for evidence, limitations, and the proposed join-test matrix.

To enable debug logging, set `DebugMode=True` under `[OpenRVS.OpenLogger]` in `openrvs.ini`, then restart the game or server. The default is `False`.

## OpenRVS Libraries
We have included a number of reusable UnrealScript2 libraries in OpenRVS:

- OpenLogger.uc: For writing OpenRVS logs to system\ravenshield.log
- OpenString.uc: For common operations like Split() and RemoveQuotes()
- OpenTimer.uc: For measuring how long things take to execute
- OpenHTTPClient.uc: For sending HTTP requests and reading responses
