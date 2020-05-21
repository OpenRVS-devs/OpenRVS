# OpenRVS
A patch to fix Ubisoft's mistakes (intentional and otherwise).

Allows multiplayer again, enables more serious modding, implements some QOL fixes.

Including: CD key bypass, UBI.com ID bypass, server registration bypass, mod system fixes, new features, and multiple bugfixes and connection fixes

Author: Twi

Thanks to: Tony, Psycho, Legacy, juguLator01, SMC and ShadowSquad clans, and the AllR6 community

# DISCLAIMER:
OpenRVS is a private project, made in response to UBISoft's choice to cease validation of cd keys for the game Rainbow Six 3: Raven Shield.  Although Raven Shield players have legally purchased the game, service for these players has now ceased.  Because UBISoft had shut down all support for online Raven Shield (as of September 24, 2016), I have decided to release this project.
Please note, this project was not made with the intention of allowing pirated copies to bypass the CD key system.  I fully support buying Raven Shield legally.  This project is ONLY so that legal owners of the game can continue to enjoy their purchase.

# How to update if you have an older version of the patch installed:
Clients just copy OpenRVS.u, openrvs.ini, Servers.list, and R6ClassDefines.ini to your system folder and overwrite the old files.

Server owners should copy OpenRVS.u and R6ClassDefines.ini to their System folder. Optionally, they can also copy OpenRenderFix.utx to their server's Textures folder, and follow server installation step #4 below.  This is optional but will ensure that clients with widescreen displays and high field of views will render their guns properly.

# How to install fresh on your personal Ravenshield copy:
1.    Stop your game if it’s running.  Copy the supplied files OpenRVS.u, R6ClassDefines.ini, openrvs.ini, and Servers.list to your game’s Ravenshield/System directory.
2.    Play the game!

Additional Info:

3.    The OpenRVS patch will automatically attempt to fetch a list of good servers from rvsgaming.org, a fan-owned community hub.  If this fetch fails, a list of known good servers found in the Servers.list file will be loaded instead.  You can edit this file to include other servers you know of.  You can also use the Join IP button to connect to any server you know the IP address of.  You can also edit openrvs.ini to fetch your server list from an alternate online provider.

4.    As of version 1.1, OpenRVS also fixes UBISoft's locked mods system. You are now able to play expansion-style mods (such as Ordnance Project or R6 Zombies) without needing a mod unlocker. You can also play *some* mods meant for multiplayer only in your singleplayer game.

5.    As of version 1.3, OpenRVS now allows installation of custom game types in singleplayer. Simply place the files for a mod game type in the Mods folder, and go to Custom Mission menu to play.

6.    As of version 1.4, OpenRVS now supports custom field of view settings as well as starting up the game in a mod. To change your FOV, open up openrvs.ini and set the FOV to the number you like, from 65 to 140 (default 90, recommend 105 or 110 for widescreen). To start the game in a mod, put the mod's keyword in the ForceStartMod entry in openrvs.ini - for example, "AthenaSword" or "SupplyDrop". Please note the mod keyword is case sensitive.

# How to install on your server:
1.    Stop your server if it’s running.  Copy the file OpenRVS.u to your server’s Ravenshield/System directory.
2.    Open your server’s Ravenshield/Mods/Ravenshield.mod file in a text editor.  Scroll to the bottom and add this line:
ServerActors=OpenRVS.OpenServer
3.    *Important: if you have N4Admin installed on your server, skip this step!*  Still in Ravenshield.mod, find the line
ServerActors=IpDrv.UdpBeacon
  Change it to say:
ServerActors=OpenRVS.OpenBeacon
4.    Optional: Still in Ravenshield.mod, copy and paste the following lines at the bottom of the file:
ServerPackages=OpenRenderFix
ServerActors=OpenRenderFix.OpenFix
  Then copy the file OpenRenderFix.utx to your server's Textures folder. This will ensure that clients with widescreen displays and a high field of view will render the first person gun correctly.
5.    *Important: make sure your server’s ports are set correctly!* In your server’s Ravenshield/System/Ravenshield.ini file, double check your server’s port number.  Ensure that your server’s ServerBeaconPort entry is the server’s port plus 1000, and your server’s BeaconPort is the server’s port plus 2000.  So for example, if your port is this:
Port=7779
  Then the ServerBeaconPort and BeaconPort entries should look like this:
ServerBeaconPort=8779
BeaconPort=9779
  In general, the default ports are 7777/8777/9777, and it is fine to leave them at this.
6.    Start your server!

Additional info:
7.    Many server owners have encountered periods of lagginess since UBISoft shut down the master server list. This lag can be fixed in two ways: 1) use the DLL patcher created by Chris (available at rvsgaming.org) to modify your server's R6GameService.dll file, or 2) set your server to be a LAN server in the server.ini file by modifying the "InternetServer=" setting. The second is an experimental solution that is not tested or necessarily guaranteed to work.
8.    Clients can connect to your server via the Join IP button if they know your server IP.  However, if you are running a server and would like it to appear in the server list fetched from rvsgaming.org, contact Tony (contact info available on smclan.org).
9.    Your server’s banlist will now ban via IP.  Your old CD key bans are also kept.  You can manually add an IP to ban in the file Ravenshield/Server/BanList.ini.
10.    You can also manually add a range of IPs to ban.  Simply enter an incomplete IP address, and any client joining with an IP that starts with this incomplete entry will be banned.  For example, an entry like this:
Banned=105.10.
  would ban any client with an IP starting with “105.10.”, including IPs like “105.10.2.144” and “105.10.20.2”.  Be careful, because an entry like this:
Banned=105.10
  without the period would ban any client with an IP starting with “105.10”, including IPs like “105.10.2.144” but also “105.107.2.144”.
11.    OpenRVS is NOT officially supported in any way on Listen servers (aka non-dedicated servers).  I have heard that it will work but the clients joining may encounter bugs.

# What exactly does the OpenRVS patch do?
On the client:
1.    The UBI.com window is bypassed, and the game is fooled into thinking a successful login occurred.
2.    The CD key entry window is bypassed, and the game is fooled into thinking a good CD key was validated by UBI.com.
3.    A bug in the Join IP window was fixed.  Previously a client could only join a server running on the default ports, and servers with non-standard configurations were non-responsive.  Now the Join IP window correctly chooses what port to connect to.
4.    The serverlist, previously fetched from UBI.com, is now fetched from rvsgaming.org.  If no connection can be established to rvsgaming.org, a backup serverlist is loaded from the file Servers.list.  (NEW in beta version 0.8 - you can specify a master server list source other than rvsgaming.org in the file openrvs.ini)
5.    Experimental: The Join IP window can now connect to a LAN server with a public internet IP address.  This feature is not extensively tested.
6.    NEW in beta version 0.6 - A bug in fetching the server list from rvsgaming.org is fixed.  Previously, the feature would break if the list was too large. Now the patch should *hopefully* work with a server list of any size.
7.    NEW in beta version 0.7 - Some players were experiencing game freezes when trying to join a server in the list from rvsgaming.org.  Now the server connection code has been rewritten to hopefully avoid these freezes.
8.    NEW in beta version 0.8 - The server list attempts to connect to each server and grab some current info, such as current map, number of players, etc.
9.    NEW in beta version 0.9 - Some players had experienced game freezing for fifteen seconds or even longer when clicking the Multiplayer button.  This version should fix that issue.
10.  NEW in beta version 1.0 - When leaving a server via the escape menu, the server list would disappear.  This version should fix that issue.
11.  NEW in version 1.1 - UBISoft locked non-official "expansion-style" mods from working in patch version 1.6. This version should fix that issue.
12.  NEW in version 1.1 - Experimental: Multiplayer mods can now be used in singleplayer as well.  To try it, set bUseMPModsInSinglePlayer to TRUE in openrvs.ini.  No guarantee is made as to whether any given mod will work in singleplayer.  Generally, the simpler the mod, the better it will work.  Mods that deal with multiplayer menus (for example, the Custom Guns mod) will not work.
13.  NEW in version 1.3 - Some behind the scenes bugs have been fixed. Also, support for some expansions and mods to connect online for multiplayer has been partially added.
14.  NEW in version 1.3 - Custom game types can now be played in singleplayer. Just drop the mod files for a custom game type into your Mods folder, then play the game through the Custom Mission menu!
15.  NEW in version 1.4 - Support for custom field of view settings added! Edit your FOV in openrvs.ini. (Note: If you experience issues with weapon rendering, try the console command SetWeapFOV followed by a negative number [default is -90]).
16.  NEW in version 1.4 - You can now start the game in your mod of choice. Set ForceStartMod in openrvs.ini to the mod's keyword (case sensitive).
17.  NEW in version 1.4 - The development beta feature "unlimited practice mode" has been added as a toggle button to the game options. Enable it to prevent ending the mission when you fail or complete an objective.
18.  NEW in version 1.4 - For mod creators, Actor mods in singleplayer can now receive the console command "CMD". Just add function SetAttachVar(Actor P,string s,name N) to your mod, where P is the PlayerController executing the command, and s is the string of the command. Type CMD followed by a string in the console to use.
19.  NEW in version 1.4 - For mod creators, you can now set a custom Cheat Manager to use in single player. Set NewCheatManagerClass in openrvs.ini to your new mod class to use. Don't forget to add exec function CMD(string s) and in it call SetAttachVar(Outer,s,'') on all actors to keep compatibility with the CMD feature.

On the server:
1.    An issue is fixed where only a server connected to UBI.com (or running the N4Admin mod) could respond to a player’s request to join.
2.    Every player joining the server is validated, regardless of actual CD key status.
3.    A player’s IP address is checked against the server’s ban list.
4.    Any player banned while in-server will have their IP address added to the server’s ban list.
5.    An issue was fixed where multiple servers using the same banlist could find ban data not saved.
6.    NEW in beta version 0.6 - The server will now write each player's name and IP address in the log file when they connect to the server.  This makes it easier to find IP addresses for manually adding to the server's ban list.
7.    NEW in version 1.2 - The server will now ensure that player and AI locations are properly sent to each client at all times when in game. This will fix the glitch where players with a slow connection can be killed by invisible enemies.
8.    NEW in version 1.4 – Using the optional OpenRenderFix file, the server can make sure that clients with an ultra-wide field of view render their first-person weapon properly. (Note: If you run a mod that modifies the game's default HUD, this feature will not work. Contact the mod author to ask them to fix.)
