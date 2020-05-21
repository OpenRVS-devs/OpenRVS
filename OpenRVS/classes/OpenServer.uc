//OpenRVS:
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

//This class detects all players joining a server.
//Before the CD key check can run, this class modifies certain hidden variables,
//to fool the server into thinking the player's CD key has already been validated.
//This class also handles converting the old banlist system to IP-based bans
//Fixes bugs in multi-server lists
//Sets all pawns as always relevant - important for high ping players
//installed server side

class OpenServer extends Actor config(BanList);

var bool bLogged,bCracked;

//log to server to make sure it's running
event PreBeginPlay()
{
	log("	 ---- OpenRVS ----");
	log("	 Author: Twi");
	log("	 With thanks to Tony and Psycho");
	log("	 As well as SMC and SS clans");
	super.PreBeginPlay();
	SetTimer(60,true);
}

//find a player who hasn't been validated
//and fix it before the server attempts to send the info to Ubi master server
function Tick(float delta)
{
	local Controller C;
	local R6PlayerController P;
	local R6AbstractGameManager A;
	local R6GSServers G;
	local R6GameInfo I;
	local string s;
	local Pawn Pawn;
	super.Tick(delta);
	C = Level.ControllerList;
	while ( C != none )
	{
		P = R6PlayerController(C);
		if ( P != none )
		{
			if ( P.m_stPlayerVerCDKeyStatus.m_eCDKeyStatus != ECDKEYST_PLAYER_VALID )//doesn't have valid cd key
			{
				if ( !bLogged )
				{
					log("	 ---- OpenRVS ----");
					log("	 Current Status:  Validating players");
					bLogged = true;
				}
				//THE IMPORTANT STUFF
				//Set each client to have a validated cd key request object
				//Before the server gets around to checking them
				P.m_stPlayerVerCDKeyStatus.m_eCDKeyRequest = ECDKEY_NONE;
				P.m_stPlayerVerCDKeyStatus.m_szAuthorizationID = string(rand(1000000000));
				P.m_stPlayerVerCDKeyStatus.m_iCDKeyReqID = 1;
				P.m_stPlayerVerCDKeyStatus.m_bCDKeyValSecondTry = false;
				P.m_stPlayerVerCDKeyStatus.m_eCDKeyStatus = ECDKEYST_PLAYER_VALID;
				if ( HandleBans(P) )//PLAYER IS BANNED VIA IP ADDRESS
				{
					log("	 ---- OpenRVS ----");
					log("	 Player '" $ P.PlayerReplicationInfo.PlayerName $ "' is banned via IP address");
					P.ClientMessage("Your IP address is banned on this server");
					P.ClientKickedOut();
					P.SpecialDestroy();
					//debug:
//					log(" **** TESTING **** PLAYER BANNED");
				}
			}
		}
		//1.2:
		//set each existing pawn as always relevant
		//so they replicate location to each client
		//vanilla behaviour was to not let them be relevant unless engine determines they should be visible or near visible
		//but lag for high-ping players always meant that the enemy would "pop" in
		//this fix requires marginally more bandwidth but forces the server to replicate all alive pawns at all times
		Pawn = C.Pawn;
		if ( Pawn != none )
		{
			if ( Pawn.IsAlive() )
			{
				if ( !Pawn.bAlwaysRelevant )
					Pawn.bAlwaysRelevant = true;
			}
		}
		C = C.NextController;
	}
}

//bug fix: when multiple servers use the same ban list, data is not sent between the two always
//loading the config file every minute will ensure that the banlist is up to date
function Timer()
{
	super.Timer();
	Level.Game.AccessControl.LoadConfig();
}

//should be called once per controller per map
//set the globalID to the IP address
//so the IP will get banned instead of obsolete ID
function bool HandleBans(R6PlayerController P)
{
	local string s;
	local int i;
	s = P.GetPlayerNetworkAddress();
	P.m_szGlobalID = left(s,InStr(s,":"));
	//0.6 update:
	//log each player's IP address
	//TO DO:
	//log the time of joining as well
	log("	 Player '" $ P.PlayerReplicationInfo.PlayerName $ "' joining server; IP address is: " $ left(s,InStr(s,":")));
	//debug:
//	log(" **** TESTING **** PLAYER ID IS: " $ P.m_szGlobalID);
	while ( i < Level.Game.AccessControl.Banned.length )
	{
		if ( Level.Game.AccessControl.Banned[i] ~= Left(P.m_szGlobalID,Len(Level.Game.AccessControl.Banned[i])) )
			return true;
		i++;
	}
	//debug:
//	log(" **** TESTING **** PLAYER NOT BANNED");
	return false;
}

defaultproperties
{
	bHidden=true
	bAlwaysRelevant=true
	bAlwaysTick=true
	RemoteRole=ROLE_SimulatedProxy
}