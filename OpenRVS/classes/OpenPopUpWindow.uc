class OpenPopUpWindow extends R6WindowPopUpBox;

var OpenPopUpContent OpenClient;

function BuildPopUp(optional string sTitle,optional int iWidth,optional int iHeight)
{
	if ( sTitle == "" )
		sTitle = "Please Note:";
	if ( iWidth == 0 )
		iWidth = 230;
	if ( iHeight == 0 )
		iHeight = 140;
	CreateStdPopUpWindow(sTitle,30,320 - (iWidth / 2),240 - (iHeight / 2),iWidth,iHeight,2);//auto-centers the box based on width and height
	CreateClientWindow(class'OpenPopUpContent',false,true);
	OpenClient = OpenPopUpContent(m_ClientArea);
	m_ePopUpID = EPopUpID_UbiComDisconnected;
}

//pass to client window function
//adds text to the popup
function AddText(string s,optional bool bBlue)
{
	OpenClient.AddText(s,bBlue);
}

//pass to client window function
//creates a button that takes user to url at the bottom of the pop up
function MakeURLButton(string url,optional string buttonText)
{
	OpenClient.MakeURLButton(url,buttonText);
}
