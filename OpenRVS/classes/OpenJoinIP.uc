//fixes UBISoft's stupid join IP bug
//properly uses the main port/serverbeaconport
//IMPORTANT: assumes that serverbeaconport is main port+1000
//also allows connection over the internet to a LAN server
//running an internet dedicated server as a LAN server does NOT seem like it is needed
//but COULD remove the need for the r6gameservice dll fix?
//functionality still left in this class just in case - (2020 - I believe some server owners do run their internet servers as LAN)
//debug: allows logging the state of joining a server
//installed client side

class OpenJoinIP extends R6WindowJoinIP;

//fix UBI's stupid code
function PopUpBoxDone(MessageBoxResult Result,ePopUpID _ePopUpID)
{
	local int m_iPort;
	if ( Result == MR_OK )
	{
		if ( _ePopUpID == EPopUpID_EnterIP )
		{
			class'OpenLogger'.static.DebugLog("popupboxdone() enterIP");
			m_szIP = R6WindowEditBox(m_pEnterIP.m_ClientArea).GetValue();
			
			//THIS IS UBI'S ORIGINAL LINE:
			//if ( m_GameService.m_ClientBeacon.PreJoinQuery(m_szIP,0) == false )
			
			//this is bullshit because it ignores the port number!
			
			//When PreJoinQuery() is called in class ClientBeaconReceiver, any number after ":" is discarded
			//and so if your server requires a port number, connection fails
			//because when ClientBeaconReceiver sees port 0, it just assumes the default port
			
			//here's the new version:
			class'OpenLogger'.static.DebugLog("finding correct port number");
			if ( InStr(m_szIP,":") != -1 )//find if a port number included
				m_iPort = int(Mid(m_szIP,InStr(m_szIP,":")+1))+1000;//get the port number (port to question is default +1000)
			else
				m_iPort = 0;//no port included, use the default port
			class'OpenLogger'.static.DebugLog("checking prejoinquery");
			if ( !m_GameService.m_ClientBeacon.PreJoinQuery(m_szIP,m_iPort) )
			{
				// handle invalid ip string format here
				class'OpenLogger'.static.DebugLog("wrong IP string");
				PopUpBoxDone(MR_OK,EPopUpID_JoinIPError);
				log("Invalid IP string entered");
			}
			else
			{
				class'OpenLogger'.static.DebugLog("starting the connection");
				if ( !m_bStartByCmdLine )
					m_pPleaseWait.ShowWindow();
				m_fBeaconTime =  m_GameService.NativeGetSeconds();
				eState = EJOINIP_WAITING_FOR_BEACON;
				class'OpenLogger'.static.DebugLog("state is waiting for beacon");
			}
		}
		else
			super.PopUpBoxDone(Result,_ePopUpID);
	}
	else
		super.PopUpBoxDone(Result,_ePopUpID);
}

//Overriding the original popup logic which does not allow IP connection to a LAN server
//some testers report crashes when they connect to a LAN though
//if internet servers can be preserved, this area may no longer be needed
function Manager( UWindowWindow _pCurrentWidget )
{
	local FLOAT elapsedTime;	  // Elapsed time waiting for response from server

	switch ( eState )
	{
		case EJOINIP_WAITING_FOR_UBICOMLOGIN:
		if ( m_GameService.m_bLoggedInUbiDotCom )
		{
			PopUpBoxDone(MR_OK, EPopUpID_EnterIP);
		}
		break;

		case EJOINIP_WAITING_FOR_BEACON:
		class'OpenLogger'.static.DebugLog("WAITING FOR BEACON");
		// Response has been received from the server
		if ( m_GameService.m_ClientBeacon.PreJoinInfo.bResponseRcvd )
		{
			class'OpenLogger'.static.DebugLog("RECEIVED A RESPONSE");
			class'OpenLogger'.static.DebugLog("INTERNET SERVER: " $ m_GameService.m_ClientBeacon.PreJoinInfo.bInternetServer);
			// Verify that the server is the same version as the game
			if ( Root.Console.ViewportOwner.Actor.GetGameVersion() != m_GameService.m_ClientBeacon.PreJoinInfo.szGameVersion )
			{
				class'OpenLogger'.static.DebugLog("VERSION FAIL");
				eState = EJOINIP_BEACON_FAIL;
				m_pPleaseWait.HideWindow();
				m_pError.ShowWindow();
				R6WindowTextLabel(m_pError.m_ClientArea).Text = Localize("MultiPlayer","PopUp_Error_BadVersion","R6Menu");
			}
			else if ( R6Console(Root.console).m_bNonUbiMatchMaking )
			{
				class'OpenLogger'.static.DebugLog("NON UBI MATCHMAKING");
				_pCurrentWidget.SendMessage( MWM_UBI_JOINIP_SUCCESS );
				if (!m_bStartByCmdLine)
				HideWindow();
			}
			// Only allow user to join internet servers using the Join IP button
			//BYPASSED!
			//allow any server, even LAN, to be joined via IP
			//however, seems to not work?  Maybe experience crashes
			//else if ( !m_GameService.m_ClientBeacon.PreJoinInfo.bInternetServer )
			//{
			//   eState = EJOINIP_BEACON_FAIL;
			//   m_pPleaseWait.HideWindow();
			//   m_pError.ShowWindow();
			//   R6WindowTextLabel(m_pError.m_ClientArea).Text = Localize("MultiPlayer","PopUp_Error_LanServer","R6Menu");
			//}
			else
			{
				//set to always false? seems to prevent hang when joining my personal server
				m_bRoomValid = false;//( m_GameService.m_ClientBeacon.PreJoinInfo.iLobbyID != 0 && m_GameService.m_ClientBeacon.PreJoinInfo.iGroupID != 0 );
				_pCurrentWidget.SendMessage( MWM_UBI_JOINIP_SUCCESS );
				class'OpenLogger'.static.DebugLog("SUCCESS");
				class'OpenLogger'.static.DebugLog("ROOM VALID: " $ m_bRoomValid);
				HideWindow();
			}
		}
		else
		{
			// Check if beacon has timed out, if so put up error message
			elapsedTime = m_GameService.NativeGetSeconds() - m_fBeaconTime;
			if ( elapsedTime > K_MAX_TIME_BEACON )
			{
				class'OpenLogger'.static.DebugLog("TIME OUT!");
				eState = EJOINIP_BEACON_FAIL;
				m_pPleaseWait.HideWindow();
				m_pError.ShowWindow();
				R6WindowTextLabel(m_pError.m_ClientArea).Text = Localize("MultiPlayer","PopUp_Error_NoServer","R6Menu");
			}
		}

		break;
		//commented out by UBI:
		//case EJOINIP_BEACON_FAIL:
		// break;
	}
}