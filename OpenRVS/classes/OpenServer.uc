//This class detects all players joining a server.
//Before the CD key check can run, this class modifies certain hidden variables,
//to fool the server into thinking the player's CD key has already been validated.
//This class also handles converting the old banlist system to IP-based bans
//Fixes bugs in multi-server lists
//Sets all pawns as always relevant - important for high ping players
//installed server side
class OpenServer extends Actor config(BanList);

var bool bLogged, bCracked;

// Walk the controller list when players join or leave (NumPlayers and
// NumSpectators change), and a few times per second so pawns that respawn
// between rounds still get flagged. This used to happen on every frame.
const PAWN_SCAN_INTERVAL = 0.25;

var private int lastNumPlayers;
var private int lastNumSpectators;
var private float nextPawnScan;

//log to server to make sure it's running
event PreBeginPlay()
{
	local OpenRVS openrvs;

	// The native NETSPEED receiver also caps requests against the server's
	// Player default, independently of TcpNetDriver.MaxClientRate.
	class'Player'.default.ConfiguredInternetSpeed = 100000;
	class'Player'.default.ConfiguredLanSpeed = 100000;

	openrvs = new class'OpenRVS';
	openrvs.Init(self);//initialize OpenRVS
	openrvs = none;//done initializing

	super.PreBeginPlay();
	SetTimer(60, true);
}

//once everything is initialized, build a beacon text and automatically register
//this server with the OpenRVS registry.
event PostNetBeginPlay()
{
	local OpenBeacon beacon;
	local R6AbstractGameInfo gameInfo;

	super.PostNetBeginPlay();

	//send a UDP beacon to the registry
	gameInfo = R6AbstractGameInfo(Level.Game);
	if ( gameInfo != None )
		beacon = OpenBeacon(gameInfo.m_UdpBeacon);
	if ( beacon != None )
		beacon.RegisterServer();
}

//find a player who hasn't been validated
//and fix it before the server attempts to send the info to Ubi master server
function Tick(float delta)
{
	local bool bScanControllers;

	super.Tick(delta);

	// A join or leave changes one of these counters, so scan immediately
	// instead of waiting for the next pawn pass.
	bScanControllers = false;
	if ( ( Level.Game.NumPlayers != lastNumPlayers ) || ( Level.Game.NumSpectators != lastNumSpectators ) )
	{
		lastNumPlayers = Level.Game.NumPlayers;
		lastNumSpectators = Level.Game.NumSpectators;
		bScanControllers = true;
	}
	// Nobody is connected, so there are no pawns to replicate and no CD keys
	// to validate. The count check above will start the scans again on join.
	if ( ( Level.Game.NumPlayers == 0 ) && ( Level.Game.NumSpectators == 0 ) )
		return;
	if ( Level.TimeSeconds >= nextPawnScan )
	{
		nextPawnScan = Level.TimeSeconds + PAWN_SCAN_INTERVAL;
		bScanControllers = true;
	}
	if ( !bScanControllers )
		return;

	ScanControllers();
}

//find unvalidated players and flag living pawns as always relevant
function ScanControllers()
{
	local Controller C, NextController;
	local R6PlayerController P;
	local Pawn Pawn;

	C = Level.ControllerList;
	while ( C != none )
	{
		NextController = C.NextController;
		P = R6PlayerController(C);
		if ( P != None && HandleBans(P) )
		{
			class'OpenLogger'.static.Info("Player '" $ P.PlayerReplicationInfo.PlayerName $ "' is banned via IP address", self);
			P.ClientMessage("Your IP address is banned on this server");
			P.ClientKickedOut();
			P.SpecialDestroy();
			C = NextController;
			continue;
		}
		//doesn't have valid cd key
		if ( ( P != none ) && ( P.m_stPlayerVerCDKeyStatus.m_eCDKeyStatus != ECDKEYST_PLAYER_VALID ) )
		{
			if ( !bLogged )
			{
				class'OpenLogger'.static.Debug("Current Status: Validating players", self);
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

		}
		//1.2:
		//set each existing pawn as always relevant
		//so they replicate location to each client
		//vanilla behaviour was to not let them be relevant unless engine determines they should be visible or near visible
		//but lag for high-ping players always meant that the enemy would "pop" in
		//this fix requires marginally more bandwidth but forces the server to replicate all alive pawns at all times
		Pawn = C.Pawn;
		if ( ( Pawn != none ) && ( Pawn.IsAlive() ) && ( !Pawn.bAlwaysRelevant ) )
		{
			Pawn.bAlwaysRelevant = true;
		}
		C = NextController;
	}
}

//bug fix: when multiple servers use the same ban list, data is not sent between the two always
//loading the config file every minute will ensure that the banlist is up to date
function Timer()
{
	super.Timer();
	Level.Game.AccessControl.LoadConfig();
}

//Check each player independently of CD-key validation on every controller scan
//set the globalID to the IP address
//so the IP will get banned instead of obsolete ID
function bool HandleBans(R6PlayerController P)
{
	local string s;
	local int i;
	s = P.GetPlayerNetworkAddress();
	if ( InStr(s, ":") != -1 )
		s = Left(s, InStr(s, ":"));
	if ( P.m_szGlobalID != s )
		class'OpenLogger'.static.Info("Player '" $ P.PlayerReplicationInfo.PlayerName $ "' joining server; IP address is:" @ s, self);
	P.m_szGlobalID = s;
	//0.6 update:
	//log each player's IP address
	//TO DO:
	//log the time of joining as well
	while ( i < Level.Game.AccessControl.Banned.length )
	{
		if ( Level.Game.AccessControl.Banned[i] != "" && Level.Game.AccessControl.Banned[i] == P.m_szGlobalID )
			return true;
		i++;
	}
	return false;
}

defaultproperties
{
	bHidden=true
	bAlwaysRelevant=true
	bAlwaysTick=true
	RemoteRole=ROLE_SimulatedProxy
}
