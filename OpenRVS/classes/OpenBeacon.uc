//class to replace UdpBeacon in serveractors list
//should allow respondprejoinquery() regardless of server registration state
//this fixes issues in non-n4 admin servers
//IMPORTANT: Servers with N4 Admin should not install this class
//debug - should log any time an initial connection with client opens
//installed server side
class OpenBeacon extends UdpBeacon config(openrvs) transient;

// RegistryServer refers to a server running github.com/willroberts/openrvs-registry.
// This can be updated here, or disabled by commenting the RegisterServer() call
// in OpenServer.uc.
var config string RegistryServerHost;
var config int RegistryServerPort;

const MARKER_MOTD = "O2";
const MOTD_MAX_LEN = 60;//Container window can only display this many chars

const DEFAULT_REGISTRY_HOST = "api.openrvs.org";//Host running openrvs-registry
const DEFAULT_REGISTRY_PORT = 8080;//UDP beacon port

// Fallback map list, created once if the game does not already have one.
// R6MapList.PreBeginPlay() reads the server ini from disk, so spawning one per
// beacon response would mean a disk read on every client refresh.
var private R6MapList cachedMapList;

// Fire off automatic server registration.
function RegisterServer()
{
	local IpAddr addr;
	local bool ok;

	// Validate input from config file.
	if (RegistryServerHost == "")
		RegistryServerHost = DEFAULT_REGISTRY_HOST;
	if (RegistryServerPort == 0)
		RegistryServerPort = DEFAULT_REGISTRY_PORT;

	ok = StringToIpAddr(RegistryServerHost, addr);
	if (!ok) {
		// If RegistryServerHost was not already a valid IP address, attempt to resolve DNS.
		Resolve(RegistryServerHost);
	} else {
		// Register by IP without waiting for the Resolve() event.
		addr.Port = RegistryServerPort;
		if (class'OpenLogger'.static.IsDebugEnabled())
			class'OpenLogger'.static.Debug("sending registration beacon to" @ RegistryServerHost @ "on port" @ RegistryServerPort, self);
		BroadcastBeacon(addr);
		class'OpenLogger'.static.Debug("registration beacon sent", self);
	}
}

event Resolved(IpAddr addr)
{
	addr.Port = RegistryServerPort;
	if (class'OpenLogger'.static.IsDebugEnabled())
		class'OpenLogger'.static.Debug("sending registration beacon to" @ RegistryServerHost @ "on port" @ RegistryServerPort, self);
	BroadcastBeacon(addr);
	class'OpenLogger'.static.Debug("registration beacon sent", self);
}

event ResolveFailed()
{
	class'OpenLogger'.static.Warning("registry DNS resolution failed; automatic server listing unavailable", self);
}

event ReceivedText(IpAddr Addr, string Text)
{
	local R6ServerInfo pServerOptions;
	local BOOL bServerResistered;
	pServerOptions = class'Actor'.static.GetServerOptions();
	if (class'OpenLogger'.static.IsDebugEnabled())
		class'OpenLogger'.static.Debug("OpenBeacon received text:" @ Text, self);
	if (Text == "REPORT")
		BroadcastBeacon(Addr);
	if (Text == "REPORTQUERY")
		BroadcastBeaconQuery(Addr);
	if (Text == "PREJOIN")
		RespondPreJoinQuery(Addr);
}

// GetMapList() returns the server's map list without reloading it from disk.
// The game spawns an R6MapList during InitGame and keeps it in the server
// options, so reuse that one; it also reflects any in-game map list changes.
// If it is missing, spawn one and keep it for later beacon responses.
private function R6MapList GetMapList()
{
	local class<MapList> ML;
	local R6ServerInfo pServerOptions;

	pServerOptions = class'Actor'.static.GetServerOptions();
	if ( pServerOptions != None && pServerOptions.m_ServerMapList != None )
		return pServerOptions.m_ServerMapList;

	if ( cachedMapList == None )
	{
		ML = class<MapList>(DynamicLoadObject("Engine.R6MapList", class'Class'));
		cachedMapList = R6MapList(spawn(ML));
	}
	return cachedMapList;
}

// BuildBeaconText() formats the UDP message for the server beacon protocol.
// Copied from IpDrv/Classes/UdpBeacon.uc in the 1.56 source code.
// Local beacon marker ¶O2 returns the server MOTD. Rotation lists are sent
// last so long rotations do not displace player data and compatibility fields.
function string BuildBeaconText()
{
	local string textData;
	local INT integerData;
	local R6MapList myList;
	local INT iCounter;
	local PlayerController aPC;
	local INT iNumPlayers;
	local string szIPAddr;
	local FLOAT fPlayingTime[32];
	local INT iPingTimeMS[32];
	local INT iKillCount[32];
	local Controller _Controller;
	local R6ServerInfo pServerOptions;

	// Custom OpenRVS fields
	local string motd;
	local string mapNames;//MapListMarker section
	local string gameTypeNames;//MenuGmNameMarker section

	pServerOptions = class'Actor'.static.GetServerOptions();
	textData = KeyWordMarker $ " ";

	// This large block of textData changes packs all relevant data into the UDP
	// message body for the beacon response.
	textData = textData @ GamePortMarker @ Mid(Level.GetAddressURL(), InStr(Level.GetAddressURL(),":")+1);
	if ( InStr(Level.Game.GetURLMap(), ".") == -1 )
		textData = textData @ MapNameMarker @ Level.Game.GetURLMap();
	else
		textData = textData @ MapNameMarker @ left( Level.Game.GetURLMap(), InStr(Level.Game.GetURLMap(), ".") );
	textData = textData @ SvrNameMarker @ Level.Game.GameReplicationInfo.ServerName;
	textData = textData @ GameTypeMarker @ Level.Game.m_szCurrGameType;
	textData = textData @ MaxPlayersMarker @ Level.Game.MaxPlayers;
	if ( Level.Game.AccessControl.GamePasswordNeeded() )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ LockedMarker @ integerData;
	if ( Level.NetMode == NM_DedicatedServer )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ DecicatedMarker @ integerData;
	myList = GetMapList();
	mapNames = "";
	gameTypeNames = "";
	if ( myList != None )
	for ( iCounter = 0; iCounter < arraycount(myList.Maps); iCounter++ )
	{
		if ( myList.Maps[iCounter] != "" )
		{
			if ( InStr(myList.Maps[iCounter], ".") == -1 )
				mapNames = mapNames $ "/" $ myList.Maps[iCounter];
			else
				mapNames = mapNames $ "/" $ left( myList.Maps[iCounter], InStr(myList.Maps[iCounter], ".") );
		}
		// Empty map slots still contribute their (empty) game type, matching the
		// stock beacon output that clients already expect.
		gameTypeNames = gameTypeNames $ "/" $ Level.GetGameTypeFromClassName(myList.GameType[iCounter]);
	}
	textData = textData @ PlayerListMarker $ " ";
	CheckForPlayerTimeouts();
	iNumPlayers = 0;
	for (_Controller=Level.ControllerList; _Controller!=None; _Controller=_Controller.NextController)
	{
		aPC = PlayerController(_Controller);
		if (aPC!=none && iNumPlayers < arraycount(iPingTimeMS)
			&& iNumPlayers < arraycount(iKillCount) && iNumPlayers < arraycount(fPlayingTime))
		{
			textData = textData $ "/" $ aPC.PlayerReplicationInfo.PlayerName;
			if ( NetConnection( aPC.Player) == None )
				szIPAddr = WindowConsole(aPC.Player.Console).szStoreIP;
			else
				szIPAddr = aPC.GetPlayerNetworkAddress();
			szIPAddr = left( szIPAddr, InStr( szIPAddr, ":" ) );
			iPingTimeMS[iNumPlayers] = aPC.PlayerReplicationInfo.Ping;
			iKillCount[iNumPlayers] = aPC.PlayerReplicationInfo.m_iKillCount;
			fPlayingTime[iNumPlayers] = GetPlayingTime( szIPAddr );
			iNumPlayers++;
		}
	}
	textData = textData @ PlayerTimeMarker $ " ";
	for (iCounter = 0; iCounter < iNumPlayers; iCounter++ )
	{
		textData = textData $ "/" $ DisplayTime( INT( fPlayingTime[iCounter] ) );
	}
	textData = textData @ PlayerPingMarker $ " ";
	for (iCounter = 0; iCounter < iNumPlayers; iCounter++ )
	{
		textData = textData $ "/" $ iPingTimeMS[iCounter];
	}
	textData = textData @ PlayerKillMarker $ " ";
	for (iCounter = 0; iCounter < iNumPlayers; iCounter++ )
	{
		textData = textData $ "/" $ iKillCount[iCounter];
	}
	textData = textData @ NumPlayersMarker @ iNumPlayers;
	textData = textData @ RoundsPerMatchMarker @ pServerOptions.RoundsPerMatch;
	textData = textData @ RoundTimeMarker @ pServerOptions.RoundTime;
	textData = textData @ BetTimeMarker @ pServerOptions.BetweenRoundTime;
	if (pServerOptions.BombTime > -1)
		textData = textData @ BombTimeMarker @ pServerOptions.BombTime;
	if ( pServerOptions.ShowNames )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ ShowNamesMarker @ integerData;
	if ( pServerOptions.InternetServer )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ InternetServerMarker @ integerData;
	if ( pServerOptions.FriendlyFire )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ FriendlyFireMarker @ integerData;
	if ( pServerOptions.Autobalance )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ AutoBalTeamMarker @ integerData;
	if ( pServerOptions.TeamKillerPenalty )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ TKPenaltyMarker @ integerData;
	textData = textData @ GameVersionMarker @ Level.GetGameVersion();
	if ( pServerOptions.AllowRadar )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ AllowRadarMarker @ integerData;
	textData = textData @ LobbyServerIDMarker $ " 0";
	textData = textData @ GroupIDMarker $ " 0";
	textData = textData @ BeaconPortMarker @ boundport;
	textData = textData @ NumTerroMarker @ pServerOptions.NbTerro;
	if ( pServerOptions.AIBkp )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ AIBkpMarker @ integerData;
	if ( pServerOptions.RotateMap )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ RotateMapMarker @ integerData;
	if ( pServerOptions.ForceFPersonWeapon )
		integerData = 1;
	else
		integerData = 0;
	textData = textData @ ForceFPWpnMarker @ integerData;
	textData = textData @ ModNameMarker @ class'Actor'.static.GetModMgr().m_pCurrentMod.m_szKeyWord;
	textData = textData @ PunkBusterMarker $ " 0";

	// Begin OpenRVS modifications.
	motd = pServerOptions.MOTD;
	if ( len(motd) > MOTD_MAX_LEN )
		motd = left(motd, MOTD_MAX_LEN);
	textData = textData @ getMarker(MARKER_MOTD) @ motd;
	// End OpenRVS modifications.

	// Keep optional rotation lists last: legacy beacon text can be truncated.
	// Existing clients identify these fields by marker, not position.
	textData = textData @ MapListMarker $ " " $ mapNames;
	textData = textData @ MenuGmNameMarker $ " " $ gameTypeNames;

	return textData;
}

private function string getMarker(string m)
{
	// Chr(182) returns ¶
	return Chr(182) $ m;
}
