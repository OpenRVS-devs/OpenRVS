OpenRVS
Author: Twi

//A patch to fix Ubisoft's mistakes (intentional and otherwise)
//Allows multiplayer again, enables more serious modding, implements some QOL fixes

//compile in 160, strip, clean, convert

//0.5 beta
// - bypasses UBI.com login
// - bypasses cd key client verification
// - fixes bug in join IP window
// - gets serverlist from rvsgaming.org
// - allows connection to LAN server through internet
// - fixes issue with connecting to non-N4 server
// - bypasses cd key server verification
// - allows banning via IP
// - fixes issue with multiple servers using same ban list
//0.6 beta
// - logs incoming player IP addresses
// - fixes issue where server list retrieved from internet could be too large and not display properly or at all
// - backup server list updated
//0.7 beta
// - rewrote server list connection to fix game freeze when attempting to connect
//0.8 beta
// - server list now fetches some current info from each server
// - added ability to specify alternate server list source
// - servers loaded from the backup list (if connection to gsconnect.rvsgaming.org fails) also fetch live info
//0.9 beta
// - massive freeze when clicking multiplayer fixed
//1.0 release
// - server list disappearing when using escape menu fixed
//1.1 release
// - UBISoft mod locking removed; any mod can now work without extra help
//1.2 release
// - buggy code in multiplayer menus cleaned up a bit
// - enemy positioning data now sent at all times to players; fixes issues with invisible tangos on a laggy connection
//1.3 release
// - behind-the-scenes errors when first loading maplist fixed
// - issue with clogging user.ini fixed (?)
// - partial support for custom mods dedicated servers begun
// - support for modded singleplayer gametypes added
//1.4 release
// - support for custom FOVs added - including fix for weapon fov rendering
// - support for loading the game straight into a mod added
// - added back beta feature unlimited practice button
// - mod actors can now use "CMD" console command
// - support for cheat manager mods added
// - multiplayer has new actor "OpenRenderFix.OpenFix" to help widescreen players
//future?
// - still weird stutter when opening MP menu - LAN only!
// - further mod support? perhaps a main menu button for a new menu to toggle actor mods on/off?
// - CSV format for server list?
// - clarify HUD FOV fix issues - can make it work in Listen server too?
// - implement MOTD in server beacon? in place of PB probably?
// - remove locked from the info we initially request from servers? useless - will be received with a pre join inquiry
// - get ping from each server? - NOTE: even when latency was measured in 0.9 beta, couldn't update server list in OpenMultiPlayerWidget?
