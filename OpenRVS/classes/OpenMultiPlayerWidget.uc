//fixes UBI's shitty connection code
//improves port logic
//allows you to join ip in the internet tab
//also allows listing of predermined good servers in internet tab
//debug - logs the joining server process
//IMPORTANT: assumes that serverbeaconport is main port+1000
//installed client side

class OpenMultiPlayerWidget extends R6MenuMultiPlayerWidget;

struct AServer
{
	var string ServerName;
	var string IP;
	var bool Locked;
	var string GameMode;
};
//var config array<AServer> ServerList;//1.2 - was config
var array<AServer> ServerList;//1.3 - not config - config is now in openserverlist, which handles loading the backup list
var config string ServerURL;//0.8 server list URL to load
var config string ServerListURL;//0.8 server list file to load

//0.8
//var bool bDONTQUERY;//failed to load online list - skips creation of OpenClientBeaconReceiver - commented out because we want to query the backup list
var bool bServerSuccess;//got list of servers from online provider

//ROOM VALIDITY
//bRoomValid determines how the cd key manager proceeds
//issues when set true?
//just set it false
//also commented out UBI code that prevents JoinIP in the internet tab
function QueryReceivedStartPreJoin ()
{
	local bool bRoomValid;
//	 log(" **** TESTING **** QUERYRECEIVEDSTARTPREJOIN");
	bRoomValid = false;//( m_GameService.m_ClientBeacon.PreJoinInfo.iLobbyID != 0 ) && ( m_GameService.m_ClientBeacon.PreJoinInfo.iGroupID != 0 );
//	if ( ( m_ConnectionTab == TAB_Internet_Server ) && !bRoomValid )//setting the above will make this error never occur
//	{
//		R6MenuRootWindow(Root).SimplePopUp(Localize("MultiPlayer","PopUp_Error_RoomJoin","R6Menu"),Localize("MultiPlayer","PopUp_Error_NoServer","R6Menu"), EPopUpID_RefreshServerList, MessageBoxButtons.MB_OK);
//		Refresh(false);
//		return;
//	}
	if ( bRoomValid )//eJoinRoomChoice - make this always happen? or set always false?	Hangs and doesn't join when set always true
	{
//		log(" **** TESTING **** VALID ROOM FAKED! STARTING CD KEY PROCESS");
		R6MenuRootWindow(Root).m_pMenuCDKeyManager.StartCDKeyProcess(EJRC_BY_LOBBY_AND_ROOM_ID,m_GameService.m_ClientBeacon.PreJoinInfo);
	}
	else//seems to be best to just set to false and default to this process
	{
//		log(" **** TESTING **** INVALID ROOM - starting cd key process with EJRC_NO");
		R6MenuRootWindow(Root).m_pMenuCDKeyManager.StartCDKeyProcess(EJRC_NO,m_GameService.m_ClientBeacon.PreJoinInfo);
	}
}

//0.8 - made this function load saved URL for server list
function Created()
{
	local OpenServerList OS;
	super.Created();
	m_GameService.m_bAutoLISave = false;//0.9 freeze fix - not sure if this does anything but seems to help steam users
//	LoadConfig("Servers.list");//only load this if fetching server list fails - see NoServerList()
	LoadConfig("openrvs.ini");//0.8 - see if we need alternate list source
	OS = Root.Console.ViewportOwner.Actor.spawn(class'OpenServerList');//get the list from Rvsgaming.org or alternate host
	OS.Init(self,ServerURL,ServerListURL);//0.8 made this load saved config vars in openrvs.ini
	//DEBUG: read google main page and try to parse it for server list
	//if working properly, should get the page, discard every line, and log warning that no serverlist was found
//	OS.Init(self,"www.google.com","index.html");
}

//couldn't get server list from rvsgaming.org
//1.3 - this function no longer used!
//openserverlist handles loading the backup list and sending to this class
function NoServerList()
{
	log("	 ---- OpenRVS ----");
	log("		Loading backup file Servers.list ...");
//	bDONTQUERY = true;//0.8//commented out - we want to query backup list too
	LoadConfig("Servers.list");
	bServerSuccess = true;//0.8 - leave this here if we want backup server list to get queried too
	GetGSServers();
}

//1.3
//clears server list
function ClearServerList()
{
	ServerList.remove(0,ServerList.length);
}

//receives a list of servers via connecting to rvsgaming.org
//parses into data understandable by the gsservers function
//function ServerListSuccess(array<string> List)//1.2 version
//1.3 function heavily modified
//parsing all moved to openserverlist
//this function just takes some values and puts them into the serverlist array
function ServerListSuccess(string sn,string sip,bool sl,string sm)
{
	//fill the array with fetched servers
	//OLD ATTEMPT:
	//commented out and retry in 1.3
	/*
	local int i,j;
	ServerList.length = 0;
	i = 0;
	while ( i < List.length )
	{
		ServerList.length = i + 1;
		//get server name
		j = InStr(List[i],",");
		ServerList[i].ServerName = Mid(List[i],0,j-1);
//		log(" **** TESTING **** " $ ServerList[i].ServerName);
		List[i] = Mid(List[i],j+5);//get rid of server name and ,IP="
		//get server IP
		j = InStr(List[i],",");
		ServerList[i].IP = Mid(List[i],0,j-1);
//		log(" **** TESTING **** " $ ServerList[i].IP);
		List[i] = Mid(List[i],j+8);//get rid of IP and ,Locked=
		//get locked
		j = InStr(List[i],",");
		ServerList[i].Locked = bool(Mid(List[i],0,j-1));
//		log(" **** TESTING **** " $ ServerList[i].Locked);
		List[i] = Mid(List[i],j+11);//get rid of locked and ,GameMode="
		//get coop
		ServerList[i].GameMode = List[i];
//		log(" **** TESTING **** " $ ServerList[i].GameMode);
		i++;
	}
	bServerSuccess = true;
//	SaveConfig("Servers.list");//don't save config in case catastrophic error overwrites good data and client has no backup!
	GetGSServers();
	*/
	//1.3 attempt
	//rewrote some of the dynamic array logic - see openserverlist for changes
	//moved parsing the list to the openserverlist class
	//to prevent auto saving and loading in this class's super
	local AServer Temp;
	Temp.ServerName = sn;
	Temp.IP = sip;
	Temp.Locked = sl;
	Temp.GameMode = sm;
	ServerList[ServerList.length] = Temp;
}

//1.3
//receives the signal that the server list is built
function FinishedServers()
{
	bServerSuccess = true;
	GetGSServers();
}

//list known good servers in this function
function GetGSServers()
{
	local R6WindowListServerItem NewItem;
	local int i,j;
	local int iNumServers;
	local int iNumServersDisplay;
//	local int tPing;
	local string szSelSvrIP;
	local bool bFirstSvr;
	local string szGameType;
	local LevelInfo pLevel;
	local R6Console console;
	local int iNbPages;
	local int iStartingIndex,iEndIndex;
	local R6ServerList.stGameServer _stGameServer;

	InitServerList();//needed here to prevent big accessed nones!
	console = R6Console(Root.Console);
	pLevel	= GetLevel();
//	log(" **** TESTING **** CONSOLE: " $ console $ " LEVEL: " $ pLevel $ " LISTBOX: " $ m_ServerListBox);

	// Remember IP of selected server, we sill keep this server highlighted
	// in the list if it is still there after the list has been rebuilt.

	if ( m_ServerListBox.m_SelectedItem != none )
		szSelSvrIP = R6WindowListServerItem(m_ServerListBox.m_SelectedItem).szIPAddr;
	else
		szSelSvrIP = "";

//	log(" **** TESTING **** CLEARING");
	m_ServerListBox.ClearListOfItems();	// Clear current list of servers
	m_ServerListBox.m_SelectedItem = none;

	//iNumServers		= m_GameService.m_GameServerList.length;
	iNumServers = ServerList.length;
	//iNumServersDisplay = m_GameService.GetDisplayListSize();

	bFirstSvr = true;

	// nb of page
	//iNbPages = iNumServersDisplay / console.iBrowserMaxNbServerPerPage;
	iNbPages = 1; // start at page 1

	// cap the page number
	// set current page / set max page
	//if ( m_PageCount.m_iCurrentPages > iNbPages )
	//	m_PageCount.SetCurrentPage( iNbPages );

	//if ( iNbPages != m_PageCount.m_iTotalPages )
	//	m_PageCount.SetTotalPages( iNbPages );

	//iStartingIndex = console.iBrowserMaxNbServerPerPage * (m_PageCount.m_iCurrentPages - 1);
	//iEndIndex		= iStartingIndex + console.iBrowserMaxNbServerPerPage;

	//if ( iEndIndex > iNumServersDisplay )
	//	iEndIndex = iNumServersDisplay;

	i = 0;
	while ( i < ServerList.length )
	{
//		log(" **** TESTING **** STARTING SERVER LIST ITEM");
		NewItem = R6WindowListServerItem(m_ServerListBox.GetNextItem(i,NewItem));
		NewItem.Created();
		NewItem.iMainSvrListIdx = i;
		NewItem.bFavorite = true;
		NewItem.bSameVersion = true;
		NewItem.szIPAddr = ServerList[i].IP;
//		log(" **** TESTING **** IP: " $ NewItem.szIPAddr);
//		if ( m_GameService.CallNativeProcessIcmpPing(NewItem.szIPAddr,tPing) )//can't seem to query ping with this function?
//		NewItem.iPing = tPing;
//		else
		NewItem.iPing = 1000;//was 1000 in early versions, at some point post 0.6 was changed to 9000?
		NewItem.szName = ServerList[i].ServerName;
//		log(" **** TESTING **** NAME: " $ NewItem.szName);
		NewItem.szMap = "";
		NewItem.iMaxPlayers = 0;
		NewItem.iNumPlayers = 0;
		NewItem.bLocked = ServerList[i].Locked;
//		log(" **** TESTING **** LOCKED: " $ NewItem.bLocked);
		NewItem.bDedicated = true;
		NewItem.bPunkBuster = false;
//		log(" **** TESTING **** MAP NAME LOC");
//		Root.GetMapNameLocalisation( NewItem.szMap, NewItem.szMap, true);
//		log(" **** TESTING **** GAME TYPE LOC");
		NewItem.szGameType = "";
		if ( InStr(caps(ServerList[i].GameMode),"ADV") != -1 )
			NewItem.szGameMode = Localize("MultiPlayer","GameMode_Adversarial","R6Menu");
		else
			NewItem.szGameMode = Localize("MultiPlayer","GameMode_Cooperative","R6Menu");
//		log(" **** TESTING **** MODE: " $ NewItem.szGameMode);
		// If selected server is still in list, reset this item
		// to be the selcted server.	By default the selected server will
		// be the first server in the list.
		if ( NewItem.szIPAddr == szSelSvrIP || bFirstSvr )
		{
			m_ServerListBox.SetSelectedItem( NewItem );
//			m_GameService.SetSelectedServer( i );
		}
//		if ( m_GameService.m_GameServerList[i].szIPAddress == szSelSvrIP )
//			m_oldSelItem = m_ServerListBox.m_SelectedItem;
//		if ( NewItem.szIPAddr == szSelSvrIP )
//			m_oldSelItem = m_ServerListBox.m_SelectedItem;

		bFirstSvr = false;
		i++;
//		log(" **** TESTING **** FINISHED SERVER LIST ITEM");
	}
//	log(" **** TESTING **** DONE");
	ManageToolTip("",true);
	QueryForServerInfo();//0.8
}

//overrided function
//to allow joining a listed server
//for server beacon port, just adds 1000 to the server IP address
//in the original, the cd key manager join function gets called, which has no port specified!
//try to include the port in m_szServerIP
function JoinSelectedServerRequested()
{
	local INT iBeaconPort;
	if ( m_ServerListBox.m_SelectedItem == None )
		return;
	if ( m_ConnectionTab == TAB_Internet_Server )
	{
		//THE NEW SYSTEM:
		//v0.7
		//treat the connection as a join IP connection
		m_pJoinIPWindow.ShowWindow();
		R6WindowEditBox(m_pJoinIPWindow.m_pEnterIP.m_ClientArea).SetValue(R6WindowListServerItem(m_ServerListBox.m_SelectedItem).szIPAddr);//set the join ip box to selected server ip
		m_pJoinIPWindow.PopUpBoxDone(MR_OK,EPopUpID_EnterIP);//fake a click on OK
		m_bJoinIPInProgress = true;

		//THE OLD SYSTEM:
		//seemed to cause freezing on SOME computers (not all)
		//not sure why but join IP still works for everyone

		//get the server IP (NOT INCLUDING PORT) - this one needs the beacon port below
		//although we may not need to strip port number because m_pQuery does it already
//		m_szServerIP = Left(R6WindowListServerItem(m_ServerListBox.m_SelectedItem).szIPAddr,InStr(R6WindowListServerItem(m_ServerListBox.m_SelectedItem).szIPAddr,":"));
		//get the server beacon port = server port + 1000
//		iBeaconPort = int(Mid(R6WindowListServerItem(m_ServerListBox.m_SelectedItem).szIPAddr,InStr(R6WindowListServerItem(m_ServerListBox.m_SelectedItem).szIPAddr,":")+1))+1000;
		//DEBUG:
//		log(" **** TESTING **** WANTS TO JOIN IP: " $ m_szServerIP);
//		log(" **** TESTING **** WANTS TO QUERY PORT: " $ iBeaconPort);
//		m_pQueryServerInfo.StartQueryServerInfoProcedure(OwnerWindow,m_szServerIP,iBeaconPort);
//		m_bQueryServerInfoInProgress = true;
		//originally, UBI stripped out port information
		//to fix, try to get IP address with port included
//		m_szServerIP = R6WindowListServerItem(m_ServerListBox.m_SelectedItem).szIPAddr;
//		log(" **** TESTING **** ORIGINAL SERVER PORT INFO: " $ m_szServerIP);
	}
	else
		super.JoinSelectedServerRequested();
}

//0.8
//create a custom client beacon receiver class
//0.9 - fix freeze here?
function ShowWindow()
{
	//0.8 attempt: allow super to run
	//but then replace the created client beacon with our own
	//0.9 fix: copy all super into this function and eliminate super call
	//super.ShowWindow();//0.9 - lag fix

	//BELOW IS FROM SUPER!
	local string _szIpAddress;

	//important line from 1.6 - not present in 1.56!
	//without this, will hang permanently on please wait
	R6MenuRootWindow(Root).m_pMenuCDKeyManager.SetWindowUser(MultiPlayerWidgetID,self);//root.15 is the UTPT version

	// Since the client beacon is an actor, it will get
	// destroyed every time we change levels.  Check here
	// if the beacon exists and re-spawn when needed.
	if ( m_LanServers == none )
	{
		m_LanServers = new(none) class<R6LanServers>(Root.MenuClassDefines.ClassLanServer);
		R6Console(Root.console).m_LanServers = m_LanServers;
		m_LanServers.Created();
		InitServerList();
		InitSecondTabWindow();//GameMode,Tech Filter,ServerInfo;
	}
	if ( m_LanServers.m_ClientBeacon == none )
		m_LanServers.m_ClientBeacon = Root.Console.ViewportOwner.Actor.spawn(class'OpenClientBeaconReceiver');//ClientBeaconReceiver');//0.9!
	m_GameService.m_ClientBeacon = m_LanServers.m_ClientBeacon;
	m_iLastSortCategory = m_LanServers.eSortCategory.eSG_PingTime;
	m_bLastTypeOfSort = true;

	//SUPER is actually uwindowwindow showwindow()
	//added here instead of calling super
	//Super.ShowWindow();//0.9
	ParentWindow.ShowChildWindow(self);
	WindowShown();
	//end uwindowwindow super()

	//0.9 - freeze
//	R6Console(Root.console).m_GameService.InitGSCDKey();//0.9 kill the freeze!
	//end 0.9

	// randomly update the background texture
	Root.SetLoadRandomBackgroundImage("Multiplayer");
	if ( R6Console(Root.console).m_bNonUbiMatchMaking )
	{
		class'Actor'.static.NativeNonUbiMatchMakingAddress(_szIpAddress);
		// ASE DEVELOPMENT - Eric Begin - May 11th, 2003
		//
		// In orfer to simplify the code, I added a new function "StartCmdLineJoinIPProcedure"
		// This functoin make sure that the player is connected on Ubi.Com before login in on the
		// game server
		m_pJoinIPWindow.StartCmdLineJoinIPProcedure(m_ButtonJoinIP,_szIpAddress);
		m_bJoinIPInProgress = true;
	}
	//END SUPER

//	if ( bDONTQUERY )//loaded backup list?
//	return;
	//0.9:
	//below will destroy old client beacon and spawn our own
	//since we added super above, can now comment out this below
	/*
	if ( ( m_LanServers.m_ClientBeacon != none ) && ( !m_LanServers.m_ClientBeacon.IsA('OpenClientBeaconReceiver') ) )
	{
		m_LanServers.m_ClientBeacon.Destroy();
		m_LanServers.m_ClientBeacon = none;
	}
	if ( m_LanServers.m_ClientBeacon == none )
	{
		m_LanServers.m_ClientBeacon = Root.Console.ViewportOwner.Actor.spawn(class'OpenClientBeaconReceiver');//0.8
	}
	m_GameService.m_ClientBeacon = m_LanServers.m_ClientBeacon;
	*/
	QueryForServerInfo();
}

//0.8
//should let refresh button also update player counts
function Refresh(bool bActivatedByUser)
{
	super.Refresh(bActivatedByUser);
	QueryForServerInfo();
}

//0.8
function QueryForServerInfo()
{
	local R6WindowListServerItem CurServer;
//	local ServerQ Q;
	//dont do this function if we haven't received a server list OR if the open beacon isn't loaded
	if ( !bServerSuccess )
		return;
	if ( m_LanServers == none )
		return;
	if ( ( m_LanServers.m_ClientBeacon == none ) || ( !m_LanServers.m_ClientBeacon.IsA('OpenClientBeaconReceiver') ) )
		return;
	//0.8
	//get each server in the list, then query for more info
	//0.9
	//ping update: clear the list of queried servers and recreate it:
	//removed! can't make ping work nicely?
//	ServerQs.Remove(0,ServerQs.length);
	CurServer = R6WindowListServerItem(m_ServerListBox.GetItemAtIndex(0));
	while ( CurServer != none )
	{
		//remove the 0.9 ping attempt
//		Q.SvrItem = CurServer;
//		Q.mSeconds = m_GameService.NativeGetMilliSeconds();
//		ServerQs[ServerQs.length] = Q;
		OpenClientBeaconReceiver(m_GameService.m_ClientBeacon).QuerySingleServer(self,Left(CurServer.szIPAddr,InStr(CurServer.szIPAddr,":")),int(Mid(CurServer.szIPAddr,InStr(CurServer.szIPAddr,":")+1))+1000);
		CurServer = R6WindowListServerItem(CurServer.Next);
	}
}

//0.8 written
//1.3 added mod keyword locking
function ReceiveServerInfo(string sIP,coerce int iNumP,coerce int iMaxP,string sGMode,string sMapName,string sSvrName,string sModName)
{
	local R6WindowListServerItem CurServer;
	local int i;
	//debug:
//	log("** Server " $ sSvrName $ " at " $ sIP $ " is playing map " $ sMapName $ " in game mode type " $ sGMode $ ". Players: " $ sNumP $ "/" $ sMaxP);//debug
	//0.8
	//find the server in the list that we received info for, and update
	CurServer = R6WindowListServerItem(m_ServerListBox.GetItemAtIndex(0));
	while ( CurServer != none )
	{
		if ( CurServer.szIPAddr == sIP )
		{
			CurServer.iMaxPlayers = iMaxP;
			CurServer.iNumPlayers = iNumP;
			CurServer.szName = sSvrName;
			CurServer.szGameType = GetLevel().GetGameNameLocalization(sGMode);
			CurServer.szMap = sMapName;
			//1.3 - grey out version if not the right mod
			//debug
//			log("*****"@class'Actor'.static.GetModMgr().m_pCurrentMod.m_szKeyWord@sModName);
			if ( caps(class'Actor'.static.GetModMgr().m_pCurrentMod.m_szKeyWord) != caps(sModName) )
				CurServer.bSameVersion = false;
			else
				CurServer.bSameVersion = true;
			CurServer = none;//break the while loop
		}
		else
		CurServer = R6WindowListServerItem(CurServer.Next);
	}
}

//1.3
//fix accessed none
//why is there no lan servers at this point?
function InitServerList()
{
	local Font buttonFont;
	local int iFiles,i,j;
	// Create window for server list
	if ( m_ServerListBox != none )
		return;
	m_ServerListBox = R6WindowServerListBox(CreateWindow(class'R6WindowServerListBox',K_XSTARTPOS_NOBORDER,K_YPOS_FIRST_TABWINDOW,K_WINDOWWIDTH_NOBORDER,K_FFIRST_WINDOWHEIGHT,self));
	m_ServerListBox.Register( m_pFirstTabManager);
	m_ServerListBox.SetCornerType(No_Borders);
	m_ServerListBox.m_Font = Root.Fonts[F_ListItemSmall];
	if ( m_LanServers != none )//accessed none fix?
		m_ServerListBox.m_iPingTimeOut = m_LanServers.NativeGetPingTimeOut();
	else
		m_ServerListBox.m_iPingTimeOut = 10000;
}

defaultproperties
{
	ServerURL="gsconnect.rvsgaming.org"
	ServerListURL="servers-updated.list"
	//debug:
//	ServerList(0)=(ServerName="SMC Mod Testing",IP="185.24.221.23:7777",MaxPlayers=4,Locked=true,GameMode="coop")
//	ServerList(1)=(ServerName="ShadowSquadHQ Adver",IP="198.23.145.10:7778",MaxPlayers=16,Locked=false,GameMode="Adver")
}