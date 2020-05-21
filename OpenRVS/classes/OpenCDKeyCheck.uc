//fools the CD key window into thinking you entered a good cd key
//installed client side

class OpenCDKeyCheck extends R6WindowUbiCDKeyCheck;

//FIX HANG AT PASSWORD BOX
//make this function just super any Msg except the one we need to change (should be UP_ENTER_CD_KEY)
//UP_ENTER_CD_KEY should call Popupboxdone, which gets overriden to in this case saveinfo, hidewindow, handlepbsituation
//handlepbsituation calls to ask for server password (found in r6windowmpmanager)
function ProcessGSMsg(string Msg)
{
	switch ( Msg )
	{
		case "UP_ENTER_CD_KEY":
			class'OpenLogger'.static.DebugLog("******************** DEBUG up enter cd key");
			m_pR6EnterCDKey.ModifyTextWindow(Localize("MultiPlayer","PopUp_EnterCDKey","R6Menu"),205.0,170.0,230.0,30.0);
			m_pR6EnterCDKey.ShowWindow();
			SelectCDKeyBox(false);
			ShowWindow();
			PopUpBoxDone(MR_OK,EPopUpID_EnterCDKey);//say that we are done cd key popup (even though we are not)
			class'OpenLogger'.static.DebugLog("******************** DEBUG done up enter cd key");
		break;
		default:
			super.ProcessGSMsg(Msg);
		break;
		//old attempt:
		//worked but just hangs when joining locked server
		//and probably would do the same when joining full server
		/*
		case "JOIN_SERVER_REQ_SUCCESS":
			class'OpenLogger'.static.DebugLog(" **** TESTING **** MWM_CDKEYVAL_SUCCESS");
			m_pSendMessageDest.SendMessage(MWM_CDKEYVAL_SUCCESS);
		break;
		case "JOIN_SERVER_FAIL_PASSWORDNOTCORRECT":
			m_pPleaseWait.HideWindow();
			DisplayErrorMsg(Localize("MultiPlayer","PopUp_Error_PassWd","R6Menu"),EPopUpID_JoinRoomErrorPassWd);
		break;
		case "JOIN_SERVER_FAIL_ROOMFULL":
			m_pPleaseWait.HideWindow();
			DisplayErrorMsg(Localize("MultiPlayer","PopUp_Error_ServerFull","R6Menu"),EPopUpID_JoinRoomErrorSrvFull);
		break;
		case "JOIN_SERVER_FAIL_DEFAULT":
			m_pPleaseWait.HideWindow();
			DisplayErrorMsg(Localize("MultiPlayer","PopUp_Error_RoomJoin","R6Menu"),EPopUpID_JoinRoomError);
		break;
		default://all the up_ and act_ should pretend to be req_success instead of throwing error messages
			m_GameService.SaveInfo();
			class'OpenLogger'.static.DebugLog(" **** TESTING **** GAMESERVICE SAVEINFO");
			m_pPleaseWait.HideWindow();
			HandlePunkBusterSvrSituation();
			class'OpenLogger'.static.DebugLog(" **** TESTING **** HIDEWINDOW AND HANDLEPUNKBUSTER");
		break;
		*/
	}
}

function PopUpBoxDone(MessageBoxResult Result,EPopUpID _ePopUpID)
{
	class'OpenLogger'.static.DebugLog("******************** DEBUG popupboxdone: " $ Result @ _ePopUpID);
	if ( ( Result == MR_OK ) && ( _ePopUpID == EPopUpID_EnterCDKey ) )
	{
		class'OpenLogger'.static.DebugLog("******************** DEBUG MR OK showing window");
		//original:
		//m_GameService.EnterCDKey(R6WindowEditBox(m_pR6EnterCDKey.m_ClientArea).GetValue());
		m_pPleaseWait.ShowWindow();
		class'OpenLogger'.static.DebugLog("******************** DEBUG game service saveinfo");
		//crack fix:
		m_GameService.SaveInfo();
		class'OpenLogger'.static.DebugLog("******************** DEBUG hiding window");
		m_pPleaseWait.HideWindow();
		class'OpenLogger'.static.DebugLog(" **** TESTING **** IS GAME LOCKED? " $ m_preJoinRespInfo.bLocked);
		class'OpenLogger'.static.DebugLog("******************** DEBUG handlepunkbustersvrs");
		HandlePunkBusterSvrSituation();
		class'OpenLogger'.static.DebugLog("******************** DEBUG done handlepunk");
	}
	else
		super.PopUpBoxDone(Result,_ePopUpID);
}