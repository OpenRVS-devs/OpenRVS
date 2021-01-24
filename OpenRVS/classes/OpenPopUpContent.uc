class OpenPopUpContent extends UWindowDialogClientWindow;

var R6WindowWrappedTextArea wTextBox;
var R6WindowButton butURL;
var string urlString;
var float fMargin;

function MakeTextBox()
{
	wTextBox = R6WindowWrappedTextArea(CreateWindow(class'R6WindowWrappedTextArea',fMargin,fMargin,WinWidth-(fMargin*2),WinHeight-(fMargin*2),self));
	wTextBox.m_bDrawBorders = false;
	wTextBox.SetScrollable(true);
	wTextBox.VertSB.SetBorderColor(Root.Colors.GrayLight);  
	wTextBox.VertSB.SetHideWhenDisable(true);
	wTextBox.VertSB.SetEffect(true);
}

function AddText(string s,optional bool bBlue)
{
	local color c;
	if ( bBlue )
		c = Root.Colors.BlueLight;
	else
		c = Root.Colors.White;
	if ( wTextBox == none )
		MakeTextBox();
	wTextBox.AddText(s,c,Root.Fonts[F_VerySmallTitle]);
}

function MakeURLButton(string url,optional string buttonText)
{
	if ( url == "" )
		return;
	if ( buttonText == "" )
		buttonText = url;
	butURL = R6WindowButton(CreateControl(class'R6WindowButton',0,WinHeight-20,WinWidth,16,self));//todo - button could overlap text box bottom
	butURL.Text = buttonText;
	butURL.Align = TA_CENTER;
	butURL.m_buttonFont = Root.Fonts[F_VerySmallTitle];
	butURL.ResizeToText();
	urlString = url;
}

//handles clicking on buttons
function Notify(UWindowDialogControl C,byte E)
{ 
	if ( E == DE_Click )
	{
		if ( urlString != "" )
		{
			if ( C == butURL )
			{
				Root.Console.ConsoleCommand("startminimized"@urlString);
			}
		}
	}    
}

defaultproperties
{
	fMargin=4.0
}
