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

var bool bServerSuccess;//0.8 got list of servers from online provider

//1.5 ping update
var OpenTimer Timer;

// QueryReceivedStartPreJoin() (aka PREJOIN) fires when a server query has
// completed successfully. It is called by the SendMessage() function. In the
// base game, it is responsible for validating CD keys and joining Ubi.com rooms.
// In our version, we use the EJRC_NO enum to disable the Ubi.com interaction.
// Overrides the matching function in R6MenuMultiPlayerWidget.
function QueryReceivedStartPreJoin ()
{
	R6MenuRootWindow(Root).m_pMenuCDKeyManager.StartCDKeyProcess(EJRC_NO,
		m_GameService.m_ClientBeacon.PreJoinInfo);
}

// Created() fires when the menu widget has been successfully created. It is
// called by ShowWindow(). In the base game, it sets up some variables regarding
// server list refreshes. In our version, we use our own server types to
// populate the server list.
// Overrides the matching function in R6MenuMultiPlayerWidget.
// Added in 0.8 - made this function load saved URL for server list
function Created()
{
	local OpenServerList OS;
	super.Created();
	m_GameService.m_bAutoLISave = false;//0.9 freeze fix - not sure if this does anything but seems to help steam users
	//LoadConfig("Servers.list");//only load this if fetching server list fails - see NoServerList()
	LoadConfig("openrvs.ini");//0.8 - see if we need alternate list source
	OS = Root.Console.ViewportOwner.Actor.spawn(class'OpenServerList');//get the list from Rvsgaming.org or alternate host
	OS.Init(self,ServerURL,ServerListURL);//0.8 made this load saved config vars in openrvs.ini
	//DEBUG: read google main page and try to parse it for server list
	//if working properly, should get the page, discard every line, and log warning that no serverlist was found
	//OS.Init(self,"www.google.com","index.html");
}

//couldn't get server list from rvsgaming.org
//1.3 - this function no longer used!
//openserverlist handles loading the backup list and sending to this class
function NoServerList()
{
	class'OpenLogger'.static.Info("loading backup file Servers.list", self);
	//bDONTQUERY = true;//0.8//commented out - we want to query backup list too
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
//1.3 function heavily modified
//parsing all moved to openserverlist
//this function just takes some values and puts them into the serverlist array
function ServerListSuccess(string sn, string sip, string sm)
{
	//fill the array with fetched servers
	//1.3 attempt
	//rewrote some of the dynamic array logic - see openserverlist for changes
	//moved parsing the list to the openserverlist class
	//to prevent auto saving and loading in this class's super
	local AServer Temp;
	Temp.ServerName = sn;
	Temp.IP = sip;
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

// GetGSServers() retrieves the current list of servers from the GameService.
// It fires when filters or favorites are changed, when switching tabs in the MP
// menu, and in the Paint() function which fills the window.
// In the base game, it does not refresh the list, but instead processes a list
// which has already been built.
// Overrides the matching function in R6MenuMultiPlayerWidget.
function GetGSServers()
{
	local R6WindowListServerItem NewItem;
	local int i,j;
	local int iNumServers;
	local int iNumServersDisplay;
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
	class'OpenLogger'.static.Debug("CONSOLE: " $ console $ " LEVEL: " $ pLevel $ " LISTBOX: " $ m_ServerListBox, self);

	// Remember IP of selected server, we sill keep this server highlighted
	// in the list if it is still there after the list has been rebuilt.

	if ( m_ServerListBox.m_SelectedItem != none )
		szSelSvrIP = R6WindowListServerItem(m_ServerListBox.m_SelectedItem).szIPAddr;
	else
		szSelSvrIP = "";

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
		NewItem = R6WindowListServerItem(m_ServerListBox.GetNextItem(i,NewItem));
		NewItem.Created();
		NewItem.iMainSvrListIdx = i;
		NewItem.bFavorite = true;
		NewItem.bSameVersion = true;
		NewItem.szIPAddr = ServerList[i].IP;
		NewItem.iPing = 1000;//was 1000 in early versions, at some point post 0.6 was changed to 9000?
		NewItem.szName = ServerList[i].ServerName;
		NewItem.szMap = "";
		NewItem.iMaxPlayers = 0;
		NewItem.iNumPlayers = 0;
		NewItem.bLocked = ServerList[i].Locked;
		NewItem.bDedicated = true;
		NewItem.bPunkBuster = false;
		//Root.GetMapNameLocalisation( NewItem.szMap, NewItem.szMap, true);
		NewItem.szGameType = "";
		if ( InStr(caps(ServerList[i].GameMode),"ADV") != -1 )
			NewItem.szGameMode = Localize("MultiPlayer","GameMode_Adversarial","R6Menu");
		else
			NewItem.szGameMode = Localize("MultiPlayer","GameMode_Cooperative","R6Menu");
		// If selected server is still in list, reset this item
		// to be the selcted server.	By default the selected server will
		// be the first server in the list.
		if ( NewItem.szIPAddr == szSelSvrIP || bFirstSvr )
		{
			m_ServerListBox.SetSelectedItem( NewItem );
			//m_GameService.SetSelectedServer( i );
		}
		//if ( m_GameService.m_GameServerList[i].szIPAddress == szSelSvrIP )
		//	m_oldSelItem = m_ServerListBox.m_SelectedItem;
		//if ( NewItem.szIPAddr == szSelSvrIP )
		//	m_oldSelItem = m_ServerListBox.m_SelectedItem;

		bFirstSvr = false;
		i++;
	}
	ManageToolTip("",true);
}

// JoinSelectedServerRequested() fires when a user connects to a server in the
// server list. In the base game, it parses the IP, sends a beacon request, and
// then hands off to StartQueryServerInfoProcedure(). In our version, we skip
// any calls to the CD key manager.
// Overrides the matching function in R6MenuMultiPlayerWidget.
function JoinSelectedServerRequested()
{
	if ( m_ServerListBox.m_SelectedItem == None )
		return;
	if ( m_ConnectionTab == TAB_Internet_Server )
	{
		//0.7: treat the connection as a join IP connection
		m_pJoinIPWindow.ShowWindow();
		R6WindowEditBox(m_pJoinIPWindow.m_pEnterIP.m_ClientArea).SetValue(R6WindowListServerItem(m_ServerListBox.m_SelectedItem).szIPAddr);//set the join ip box to selected server ip
		m_pJoinIPWindow.PopUpBoxDone(MR_OK,EPopUpID_EnterIP);//fake a click on OK
		m_bJoinIPInProgress = true;
	}
	else
		super.JoinSelectedServerRequested();
}

// ShowWindow() displays the server list window. It fires when a user changes
// tabs in the multiplayer menu. In the base game, it performs some CD key
// checking. In our version, these checks are disabled.
// Overrides the matching function in R6MenuMultiPlayerWidget.
//0.8 - create a custom client beacon receiver class
//0.9 - fix freeze here?
function ShowWindow()
{
	//0.8 attempt: allow super to run
	//but then replace the created client beacon with our own
	//0.9 fix: copy all super into this function and eliminate super call
	//super.ShowWindow();//0.9 - lag fix
	local string _szIpAddress;
	class'OpenLogger'.static.Debug("user opened mp menu", self);

	//BELOW IS FROM SUPER!
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
	//R6Console(Root.console).m_GameService.InitGSCDKey();//0.9 kill the freeze!
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
}

// Refresh() refreshes the list of servers. In the base game, it clears the list
// and rebuilds it with fresh data. In our version, we execute our own refresh.
// Refresh is called at the following times:
// - When a user opens the Internet tab for the first time
// - When a user opens the LAN tab for the first time
// - When a user manually refreshes the list of servers
// Overrides the matching function in R6MenuMultiPlayerWidget.
// 0.8: should let refresh button also update player counts
function Refresh(bool bActivatedByUser)
{
	local R6WindowListServerItem CurServer;
	local string s;//1.5
	
	super.Refresh(bActivatedByUser);//call super first

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
	CurServer = R6WindowListServerItem(m_ServerListBox.GetItemAtIndex(0));
	while ( CurServer != none )
	{
		//1.5 - get rough ping
		if ( Timer == none )
		{
			Timer = new class'OpenTimer';//.static.New(GetEntryLevel());
			Timer.ClockSource = GetEntryLevel();
		}
		s = class'OpenString'.static.ReplaceText(CurServer.szIPAddr,".","");
		s = class'OpenString'.static.ReplaceText(s,":","");
		Timer.StartTimer(s);
		OpenClientBeaconReceiver(m_GameService.m_ClientBeacon).QuerySingleServer(self,Left(CurServer.szIPAddr,InStr(CurServer.szIPAddr,":")),int(Mid(CurServer.szIPAddr,InStr(CurServer.szIPAddr,":")+1))+1000);
		CurServer = R6WindowListServerItem(CurServer.Next);
	}
}

// ManageTabSelection() performs various actions when a user changes the tab in
// the multiplayer menu.
// Overrides the matching function in R6MenuMultiPlayerWidget.
// Copied directly and commented out additional refreshes.
function ManageTabSelection(INT _MPTabChoiceID)
{
	switch(_MPTabChoiceID)
	{
		case MultiPlayerTabID.TAB_Lan_Server:
			m_ConnectionTab = TAB_Lan_Server;
			//if ( m_LanServers.m_GameServerList.length == 0 )
			//	Refresh( FALSE );
			GetLanServers();
			GetServerInfo( m_LanServers );
			UpdateServerFilters();
			m_iLastTabSel = MultiPlayerTabID.TAB_Lan_Server;
			SaveConfig();
			break;
		case MultiPlayerTabID.TAB_Internet_Server:
			m_ConnectionTab = TAB_Internet_Server;
			m_LoginSuccessAction = eLSAct_InternetTab;
			m_pLoginWindow.StartLogInProcedure(self);
			//if ( m_GameService.m_GameServerList.length == 0 )
			//	Refresh( FALSE );
			GetGSServers();
			UpdateServerFilters();
			m_iLastTabSel = MultiPlayerTabID.TAB_Internet_Server;
			SaveConfig();
			break;
		case MultiPlayerTabID.TAB_Game_Mode:
			m_FilterTab = TAB_Game_Mode;
			m_ServerInfoPlayerBox.HideWindow();
			m_ServerInfoMapBox.HideWindow();
			m_ServerInfoOptionsBox.HideWindow();
			m_pSecondWindow.HideWindow();
			m_pSecondWindowGameMode.ShowWindow();
			m_pSecondWindow = m_pSecondWindowGameMode;
			break;
		case MultiPlayerTabID.TAB_Tech_Filter:
			m_FilterTab = TAB_Tech_Filter;
			m_ServerInfoPlayerBox.HideWindow();
			m_ServerInfoMapBox.HideWindow();
			m_ServerInfoOptionsBox.HideWindow();
			m_pSecondWindow.HideWindow();
			m_pSecondWindowFilter.ShowWindow();
			m_pSecondWindow = m_pSecondWindowFilter;
			break;
		case MultiPlayerTabID.TAB_Server_Info:
			m_FilterTab = TAB_Server_Info;
			m_pSecondWindow.HideWindow();
			m_pSecondWindowServerInfo.ShowWindow();
			m_ServerInfoPlayerBox.ShowWindow();
			m_ServerInfoMapBox.ShowWindow();
			m_ServerInfoOptionsBox.ShowWindow();
			m_pSecondWindow = m_pSecondWindowServerInfo;
			break;
		default:
			class'OpenLogger'.static.Warning("This tab was not supported (OpenMultiPlayerWidget)", self);
			break;
	}
}

//0.8 written
//1.3 added mod keyword locking
//1.5 receive locked info from specific servers, not master list
function ReceiveServerInfo(string sIP,coerce int iNumP,coerce int iMaxP,string sGMode,string sMapName,string sSvrName,string sModName,bool bSvrLocked)
{
	local R6WindowListServerItem CurServer;
	local int i;
	local string s;//1.5

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
			if ( caps(class'Actor'.static.GetModMgr().m_pCurrentMod.m_szKeyWord) != caps(sModName) )
				CurServer.bSameVersion = false;
			else
				CurServer.bSameVersion = true;
			CurServer.bLocked = bSvrLocked;//1.5 added locked here
			//1.5 add ping
			s = class'OpenString'.static.ReplaceText(CurServer.szIPAddr,".","");
			s = class'OpenString'.static.ReplaceText(s,":","");
			i = Timer.EndTimer(s);
			if ( i != -1 )
				CurServer.iPing = i;
			CurServer = none;//break the while loop
		}
		else
		CurServer = R6WindowListServerItem(CurServer.Next);
	}
}

// InitServerList() creates a window for the server list. It is called by
// ShowWindow(). In our version, we are able to override the server ping timeout.
// Overrides the matching function in R6MenuMultiPlayerWidget.
// 1.3: fixed access none
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
	//ServerList(0)=(ServerName="SMC Mod Testing",IP="185.24.221.23:7777",MaxPlayers=4,Locked=true,GameMode="coop")
	//ServerList(1)=(ServerName="ShadowSquadHQ Adver",IP="198.23.145.10:7778",MaxPlayers=16,Locked=false,GameMode="Adver")
}