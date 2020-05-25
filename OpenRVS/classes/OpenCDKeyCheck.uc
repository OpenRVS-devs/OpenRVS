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
			m_pR6EnterCDKey.ModifyTextWindow(Localize("MultiPlayer","PopUp_EnterCDKey","R6Menu"),205.0,170.0,230.0,30.0);
			m_pR6EnterCDKey.ShowWindow();
			SelectCDKeyBox(false);
			ShowWindow();
			PopUpBoxDone(MR_OK,EPopUpID_EnterCDKey);//say that we are done cd key popup (even though we are not)
		break;
		default:
			super.ProcessGSMsg(Msg);
		break;
		//old attempt:
		//worked but just hangs when joining locked server
		//and probably would do the same when joining full server
		/*
		case "JOIN_SERVER_REQ_SUCCESS":
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
			m_pPleaseWait.HideWindow();
			HandlePunkBusterSvrSituation();
		break;
		*/
	}
}

function PopUpBoxDone(MessageBoxResult Result,EPopUpID _ePopUpID)
{
	class'OpenLogger'.static.Debug("PopUpBoxDone: " $ Result @ _ePopUpID, self);
	if ( ( Result == MR_OK ) && ( _ePopUpID == EPopUpID_EnterCDKey ) )
	{
		m_pPleaseWait.ShowWindow();
		//crack fix:
		m_GameService.SaveInfo();
		m_pPleaseWait.HideWindow();
		class'OpenLogger'.static.Debug("IS GAME LOCKED? " $ m_preJoinRespInfo.bLocked, self);
		class'OpenLogger'.static.Debug("handlepunkbustersvrs", self);
		HandlePunkBusterSvrSituation();
		class'OpenLogger'.static.Debug("done handlepunk", self);
	}
	else
		super.PopUpBoxDone(Result,_ePopUpID);
}