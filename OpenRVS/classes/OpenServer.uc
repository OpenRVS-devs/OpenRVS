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
		//doesn't have valid cd key
		if ( P != none ) && if ( P.m_stPlayerVerCDKeyStatus.m_eCDKeyStatus != ECDKEYST_PLAYER_VALID )
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
				class'OpenLogger'.static.DebugLog("PLAYER BANNED");
			}
		}
		//1.2:
		//set each existing pawn as always relevant
		//so they replicate location to each client
		//vanilla behaviour was to not let them be relevant unless engine determines they should be visible or near visible
		//but lag for high-ping players always meant that the enemy would "pop" in
		//this fix requires marginally more bandwidth but forces the server to replicate all alive pawns at all times
		Pawn = C.Pawn;
		if ( Pawn != none ) && if ( Pawn.IsAlive() ) && ( !Pawn.bAlwaysRelevant )
		{
			Pawn.bAlwaysRelevant = true;
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
	class'OpenLogger'.static.DebugLog("PLAYER ID IS: " $ P.m_szGlobalID);
	while ( i < Level.Game.AccessControl.Banned.length )
	{
		if ( Level.Game.AccessControl.Banned[i] ~= Left(P.m_szGlobalID,Len(Level.Game.AccessControl.Banned[i])) )
			return true;
		i++;
	}
	//debug:
	class'OpenLogger'.static.DebugLog("PLAYER NOT BANNED");
	return false;
}

defaultproperties
{
	bHidden=true
	bAlwaysRelevant=true
	bAlwaysTick=true
	RemoteRole=ROLE_SimulatedProxy
}