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
	var int iMaxPlayers,iNumPlayers;//1.5 - max players/current players
	var string szGameType;//1.5 - localized game mode name
	var string szMap;//1.5 - map name
	var bool bWrongVersion;//1.5 - running same expansion mod - for future use? - needs to be inverted so only true value will trigger changing the menu
	var int iPing;//1.5 - ping
};
var array<AServer> ServerList;//1.3 - not config - config is now in openserverlist, which handles loading the backup list
var config string ServerURL;//0.8 server list URL to load
var config string ServerListURL;//0.8 server list file to load
var bool bServerSuccess;//0.8 got list of servers from online provider
var array<string> OpenQueries;//1.5 keep track of servers we've queried
var OpenTimer Timer;//1.5 ping update
var OpenServerList OS;//moved here from local - because needed in tab switching function
var bool bNeedsExtraRefresh;//if going from lan tab to internet, we need an extra refresh forced after the server list is fetched

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
	super.Created();
	m_GameService.m_bAutoLISave = false;//0.9 freeze fix - not sure if this does anything but seems to help steam users
	LoadConfig("openrvs.ini");//0.8 - see if we need alternate list source
	OS = Root.Console.ViewportOwner.Actor.spawn(class'OpenServerList');//get the server list over http
	OS.Init(self,ServerURL,ServerListURL);//0.8 made this load saved config vars in openrvs.ini
}

//couldn't get server list
//1.3 - this function no longer used!
//openserverlist handles loading the backup list and sending to this class
function NoServerList()
{
	class'OpenLogger'.static.Info("loading backup file Servers.list", self);
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

// Adds a server to the list.
function AddServerToList(string sn, string sip, string sm)
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
	Temp.iPing = 1000;//1.5 - don't let iPing initialize with null value of 0 - for sorting. If server responds, this value will be set to actual ping
	ServerList[ServerList.length] = Temp;
}

//1.3
//receives the signal that the server list is built
function FinishedServers()
{
	bServerSuccess = true;
	GetGSServers();
	if ( bNeedsExtraRefresh )
	{
		bNeedsExtraRefresh = false;
		Refresh(false);
	}
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
	pLevel = GetLevel();

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
		NewItem.bFavorite = true;//todo - favorite servers
		NewItem.bSameVersion = !ServerList[i].bWrongVersion;//true;//1.5 change - bWrongVersion inits as false but can be set true in later check
		NewItem.szIPAddr = ServerList[i].IP;
		NewItem.iPing = ServerList[i].iPing;
		NewItem.szName = ServerList[i].ServerName;
		NewItem.szMap = ServerList[i].szMap;//"";//1.5 change
		NewItem.iMaxPlayers = ServerList[i].iMaxPlayers;
		NewItem.iNumPlayers = ServerList[i].iNumPlayers;
		NewItem.bLocked = ServerList[i].Locked;
		NewItem.bDedicated = true;//todo: grab dedicated info from client beacon receiver
		NewItem.bPunkBuster = false;
		//Root.GetMapNameLocalisation( NewItem.szMap, NewItem.szMap, true);
		NewItem.szGameType = ServerList[i].szGameType;//"";//1.5 change
		if ( InStr(caps(ServerList[i].GameMode),"ADV") != -1 )
			NewItem.szGameMode = Localize("MultiPlayer","GameMode_Adversarial","R6Menu");
		else
			NewItem.szGameMode = Localize("MultiPlayer","GameMode_Cooperative","R6Menu");
		// If selected server is still in list, reset this item
		// to be the selcted server.	By default the selected server will
		// be the first server in the list.
		if ( NewItem.szIPAddr == szSelSvrIP || bFirstSvr )
		{
			m_ServerListBox.SetSelectedItem( NewItem );//sends this server upstream
			//m_GameService.SetSelectedServer( i );
		}
		//if ( m_GameService.m_GameServerList[i].szIPAddress == szSelSvrIP )
		//	m_oldSelItem = m_ServerListBox.m_SelectedItem;
		//if ( NewItem.szIPAddr == szSelSvrIP )
		//	m_oldSelItem = m_ServerListBox.m_SelectedItem;

		bFirstSvr = false;
		i++;
	}

	ManageToolTip("", true);
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
	local bool bFound;//1.5 - prevent multiple open queries
	local int i,j;

	super.Refresh(bActivatedByUser);//call super first

	//dont do this function if we haven't received a server list OR if the open beacon isn't loaded
	if ( !bServerSuccess )
		return;
	if ( m_LanServers == none )
		return;
	if ( ( m_LanServers.m_ClientBeacon == none ) || ( !m_LanServers.m_ClientBeacon.IsA('OpenClientBeaconReceiver') ) )
		return;

	//1.5 - if initiated by user, clear the list of current queries and start fresh
	if ( bActivatedByUser )
		OpenQueries.remove(0,OpenQueries.length);
	//0.9: get each server in the list, then query for more info
	//1.5 - query ServerList instead
	j = 0;
	while ( j < ServerList.length )
	{
		i = 0;
		bFound = false;
		ServerList[j].iPing = 1000;//set to 1000 so if server doesn't respond this time, it will sort to the bottom of the list
		//1.5 - only one open query to a server at a time
		while ( i < OpenQueries.length )
		{
			if ( OpenQueries[i] == ServerList[j].IP )//aleady have query open
			{
				bFound = true;
				break;
			}
			i++;
		}
		if ( !bFound )
		{
			OpenQueries[OpenQueries.length] = ServerList[j].IP;
			//1.5 - get rough ping
			if ( Timer == none )
			{
				Timer = new class'OpenTimer';
				Timer.ClockSource = GetLevel();
			}
			Timer.StartTimer(ServerList[j].IP);
			OpenClientBeaconReceiver(m_GameService.m_ClientBeacon).QuerySingleServer(self,
				Left(ServerList[j].IP,InStr(ServerList[j].IP,":")),
				int(Mid(ServerList[j].IP,InStr(ServerList[j].IP,":")+1))+1000);
		}
		j++;
	}
}

//0.8 written
//1.3 added mod keyword locking
//1.5 receive locked info from specific servers, not master list
function ReceiveServerInfo(string sIP,coerce int iNumP,coerce int iMaxP,string sGMode,string sMapName,string sSvrName,string sModName,bool bSvrLocked)
{
	local R6WindowListServerItem CurServer;
	local int i,iTime;

	//1.5
	//modify the servers array rather than the list items
	//then rebuild list items with GetGSServers()
	i = 0;
	while ( i < OpenQueries.length )
	{
		if ( OpenQueries[i] == sIP )//close open query
		{
			OpenQueries.remove(i,1);
			break;
		}
		i++;
	}
	i = 0;
	while ( i < ServerList.length )
	{
		if ( ServerList[i].IP == sIP )
		{
			ServerList[i].ServerName = sSvrName;
			ServerList[i].Locked = bSvrLocked;
			ServerList[i].iMaxPlayers = iMaxP;
			ServerList[i].iNumPlayers = iNumP;
			ServerList[i].szGameType = GetLevel().GetGameNameLocalization(sGMode);
			ServerList[i].szMap = sMapName;
			ServerList[i].bWrongVersion = ( caps(class'Actor'.static.GetModMgr().m_pCurrentMod.m_szKeyWord) != caps(sModName) );
			iTime = Timer.EndTimer(sIP);
			if ( iTime != -1 )
				ServerList[i].iPing = iTime / 2;//divide by two for single-trip time - consistent with how Ubi used to measure
		}
		i++;
	}
	GetGSServers();
}

// InitServerList() creates a window for the server list. It is called by
// ShowWindow(). In our version, we are able to override the server ping timeout.
// Overrides the matching function in R6MenuMultiPlayerWidget.
// 1.3: fixed access none
function InitServerList()
{
	local Font buttonFont;
	local int iFiles, i, j;

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

//sorting update 1.5
//calls super if in LAN tab - use the built-in native functions for LAN
function ResortServerList(int iCategory, bool _bAscending)
{
	local int i,j;//indices for iterating ServerList
	local bool bSwap;
	local int iListSize;
	local AServer temp;
	local string sCompare1,sCompare2;
	local int iCompare1,iCompare2;
	local bool bIntComp;

	if ( m_ConnectionTab == TAB_Lan_Server )
	{
		super.ResortServerList(iCategory,_bAscending);
		return;
	}
	m_iLastSortCategory = iCategory;
	m_bLastTypeOfSort = _bAscending;
	iListSize = ServerList.length;
	for ( i = 0; i < iListSize - 1; i++ )
	{
		for ( j = 0; j < iListSize - 1 - i; j++ )
		{
			bIntComp = false;
			bSwap = false;
			switch ( iCategory )
			{
				case 1://locked
					sCompare1 = string(ServerList[j].Locked);
					sCompare2 = string(ServerList[j+1].Locked);
					break;
				case 5://name
					sCompare1 = ServerList[j].ServerName;
					sCompare2 = ServerList[j+1].ServerName;
					break;
				case 6://game type
					sCompare1 = ServerList[j].szGameType;
					sCompare2 = ServerList[j+1].szGameType;
					break;
				case 7://game mode
					sCompare1 = ServerList[j].GameMode;
					sCompare2 = ServerList[j+1].GameMode;
					break;
				case 8://map name
					sCompare1 = ServerList[j].szMap;
					sCompare2 = ServerList[j+1].szMap;
					break;
				case 9://num players
					bIntComp = true;
					iCompare1 = ServerList[j].iNumPlayers;
					iCompare2 = ServerList[j+1].iNumPlayers;
					break;
				default://ping sort and ALL unsupported right now (fav, punkbuster, dedicated) sort by ping - todo: add support for displaying and sorting by dedicated server, favorites
					bIntComp = true;
					iCompare1 = ServerList[j].iPing;
					iCompare2 = ServerList[j+1].iPing;
					break;
			}
			if ( bIntComp )//compare int sizes
			{
				if ( _bAscending )
					bSwap =  iCompare1 > iCompare2;
				else
					bSwap =  iCompare1 < iCompare2;
			}
			else//compare strings
			{
				if ( _bAscending )
					bSwap =  sCompare1 > sCompare2;
				else
					bSwap =  sCompare1 < sCompare2;
			}
			bSwap = ( ( bSwap || ( ServerList[j].iPing == 1000 ) ) && ( ServerList[j+1].iPing != 1000 ) );//always send servers with no response to the bottom of the list
			if ( bSwap )
			{
				temp = ServerList[j];
				ServerList[j] = ServerList[j + 1];
				ServerList[j + 1] = temp;
			}
		}
	}
	GetGSServers();//forces a rebuild in the menu list items based on our resorted ServerList array
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
			ClearServerList();//added to fix bug where internet servers stay in lan tab
			m_ServerListBox.ClearListOfItems();//fix lan tab
			m_ServerListBox.m_SelectedItem = none;//fix lan tab
			if ( m_LanServers.m_GameServerList.length == 0 )
				Refresh( FALSE );
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
			//when clicking from LAN to internet
			if ( m_iLastTabSel == MultiPlayerTabID.TAB_Lan_Server )
			{
				ClearServerList();
				bNeedsExtraRefresh = true;//force a refresh once server list fetched
				if ( OS != none )
					OS.Init(self,ServerURL,ServerListURL);//fix bug switching between internet/lan tabs - need to refetch server list
			}
			//GetGSServers();//commented out - this will get called automatically when openserverlist is done
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

defaultproperties
{
	ServerURL="api.openrvs.org"
	ServerListURL="servers"
	//ServerList(0)=(ServerName="SMC Mod Testing",IP="185.24.221.23:7777",MaxPlayers=4,Locked=true,GameMode="coop")
	//ServerList(1)=(ServerName="ShadowSquadHQ Adver",IP="198.23.145.10:7778",MaxPlayers=16,Locked=false,GameMode="Adver")
}
