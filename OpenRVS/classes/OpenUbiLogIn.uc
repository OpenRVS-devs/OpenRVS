//fools the UBI ID window into thinking you successfully logged in
//so you can select the Internet tab without any problems
//installed client side
class OpenUbiLogIn extends R6WindowUbiLogIn;

//in 1.56 this is done in function Manager()
//changed in 1.6 to processgsmsg
function ProcessGSMsg (string _szMsg)
{
	m_pR6UbiAccount.HideWindow();
	m_pDisconnected.HideWindow();
	HideWindow();
	m_GameService.SaveConfig();
	m_pSendMessageDest.SendMessage(MWM_UBI_LOGIN_SUCCESS);
	class'OpenLogger'.static.Debug("SUCCESSFULLY FAKED UBI LOGIN", self);
}