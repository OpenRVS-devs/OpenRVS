class OpenOptionsGame extends R6MenuOptionsGame config(openrvs);

//v1.4 experimental
//add the unlimited practice button back!
//not super useful for 99.99% of people

var R6WindowButtonBox m_pOptionUnlimitedP;//commented out in vanilla
var config bool bUnlimited;//need a save for this

//1.56 was named InitOptionsGame()
//renamed in 1.6
function InitPageOptions()
{
	local FLOAT fXOffset, fYOffset, fYStep, fWidth, fHeight, fTemp, fSizeOfCounter, fXRightOffset;
	local Font ButtonFont;

	local INT  iAutoAimBitmapHeight, iAutoAimVPadding, iSBButtonWidth;

	//create buttons -- check text label offset for concordance 
	ButtonFont = Root.Fonts[F_SmallTitle]; 

	//1.6 vanilla DOES NOT have following - this is from 1.56
	//m_ePageOptID = ePO_Game;

	fXOffset = 5;
	fXRightOffset = 26;
	fYOffset = 5;
	fWidth = WinWidth - fXOffset - 40; // 40 distance to the end of the window
	fHeight = 15;
	fYStep = 27;
	iSBButtonWidth = 14;
	
	iAutoAimBitmapHeight = 73;
	iAutoAimVPadding	 = 5; //Padding Between the bitmap and the scrollBar

	// ALWAYS RUN
	m_pOptionAlwaysRun = R6WindowButtonBox(CreateControl(class'R6WindowButtonBox',
		fXOffset, fYOffset, fWidth, fHeight, self));
	m_pOptionAlwaysRun.SetButtonBox(false);
	m_pOptionAlwaysRun.CreateTextAndBox(Localize("Options","Opt_GameAlways","R6Menu"), 
		Localize("Tip","Opt_GameAlways","R6Menu"), 0, 2);

	fYOffset += fYStep;
	// INVERT MOUSE
	m_pOptionInvertMouse = R6WindowButtonBox(CreateControl(class'R6WindowButtonBox',
		fXOffset, fYOffset, fWidth, fHeight, self));
	m_pOptionInvertMouse.SetButtonBox(false);
	m_pOptionInvertMouse.CreateTextAndBox(Localize("Options","Opt_GameInvertM","R6Menu"), 
		Localize("Tip","Opt_GameInvertM","R6Menu"), 0, 3);

	fYOffset += fYStep;
	// MOUSE SENSITIVITY
	m_pOptionMouseSens = R6WindowHScrollBar(CreateControl(class'R6WindowHScrollBar',
		fXOffset, fYOffset, WinWidth - fXOffset - fXRightOffset, C_fSCROLLBAR_HEIGHT, self));
	//180 is the size of the scrollbar
	m_pOptionMouseSens.CreateSB(0, C_fXPOS_SCROLLBAR, 0, C_fSCROLLBAR_WIDTH,
		C_fSCROLLBAR_HEIGHT, self);
	m_pOptionMouseSens.CreateSBTextLabel(Localize("Options","Opt_GameMouseSens","R6Menu"), 
		Localize("Tip","Opt_GameMouseSens","R6Menu"));	
	m_pOptionMouseSens.SetScrollBarRange(0, 120, 20);

	fYOffset += fYStep;
	// POP UP LOAD PLAN
	m_pPopUpLoadPlan = R6WindowButtonBox(CreateControl(class'R6WindowButtonBox',
		fXOffset, fYOffset, fWidth, fHeight, self));
	m_pPopUpLoadPlan.SetButtonBox(false);
	m_pPopUpLoadPlan.CreateTextAndBox(Localize("Options","Opt_GamePopUpLoadPlan","R6Menu"), 
		Localize("Tip","Opt_GamePopUpLoadPlan","R6Menu"), 0, 5);

	fYOffset += fYStep;
	// POP UP LOAD PLAN
	m_pPopUpQuickPlay = R6WindowButtonBox(CreateControl(class'R6WindowButtonBox',
		fXOffset, fYOffset, fWidth, fHeight, self));
	m_pPopUpQuickPlay.SetButtonBox(false);
	m_pPopUpQuickPlay.CreateTextAndBox(Localize("Options","Opt_GamePopUpQuickPlay","R6Menu"), 
		Localize("Tip","Opt_GamePopUpQuickPlay","R6Menu"), 0, 5);

	fYOffset += fYStep;

	//originally commented out!
	//moved lower as well
	// UNLIMITED PRATICE
	m_pOptionUnlimitedP = R6WindowButtonBox(CreateControl(class'R6WindowButtonBox',
		fXOffset, fYOffset, fWidth, fHeight, self));
	//m_pOptionUnlimitedP.SetButtonBox(false);
	//these next lines let us save the status of this box
	LoadConfig();
	m_pOptionUnlimitedP.SetButtonBox(bUnlimited);
	class'Actor'.static.GetGameOptions().UnlimitedPractice = m_pOptionUnlimitedP.m_bSelected;
	m_pOptionUnlimitedP.CreateTextAndBox("Unlimited Practice Mode", 
		"Hidden beta feature that lets you continue playing after completing or failing objectives.",
		0, 0);
	
	fYOffset += fYStep;
	
	// AUTO AIM	   
	m_pAutoAim = R6WindowTextureBrowser(CreateWindow(
		class'R6WindowTextureBrowser', fXOffset , fYOffset, WinWidth - fXOffset,
		C_fSCROLLBAR_HEIGHT + iAutoAimBitmapHeight + iAutoAimVPadding, self));
	m_pAutoAim.CreateSB(C_fXPOS_SCROLLBAR,
		m_pAutoAim.WinHeight - C_fSCROLLBAR_HEIGHT, C_fSCROLLBAR_WIDTH,
		C_fSCROLLBAR_HEIGHT); //180 is the size of the scrollbar
	m_pAutoAim.CreateBitmap(C_fXPOS_SCROLLBAR + iSBButtonWidth, 0,
		C_fSCROLLBAR_WIDTH - (2 * iSBButtonWidth), iAutoAimBitmapHeight);
	m_pAutoAim.SetBitmapProperties(false, true, 5, false);
	m_pAutoAim.SetBitmapBorder(true, Root.Colors.White);
	m_pAutoAim.CreateTextLabel(0, 0,
		m_pAutoAim.WinWidth - m_pAutoAim.m_CurrentSelection.WinLeft,
		m_pAutoAim.WinHeight, Localize("Options","Opt_AutoTarget","R6Menu"),
		Localize("Tip","Opt_AutoTarget","R6Menu"));	

	m_pAutoAim.AddTexture(m_pAutoAimTexture, m_pAutoAimTextReg[0]); 
	m_pAutoAim.AddTexture(m_pAutoAimTexture, m_pAutoAimTextReg[1]); 
	m_pAutoAim.AddTexture(m_pAutoAimTexture, m_pAutoAimTextReg[2]); 
	m_pAutoAim.AddTexture(m_pAutoAimTexture, m_pAutoAimTextReg[3]);

	InitResetButton();
	//1.6 vanilla DOES NOT have following:
	//SetMenuGameValues();

	//m_bInitComplete = true;
	//instead has:
	UpdateOptionsInPage();
}

//function existed in 1.56 as SetGameValues()
//renamed in 1.6
function UpdateOptionsInEngine()
{
	local R6GameOptions pGameOptions;
	pGameOptions = class'Actor'.static.GetGameOptions();
	//commented out in vanilla
	pGameOptions.UnlimitedPractice = m_pOptionUnlimitedP.m_bSelected;
	pGameOptions.AlwaysRun		   = m_pOptionAlwaysRun.m_bSelected;
	pGameOptions.InvertMouse	   = m_pOptionInvertMouse.m_bSelected;
	pGameOptions.PopUpLoadPlan	   = m_pPopUpLoadPlan.m_bSelected;
	pGameOptions.PopUpQuickPlay	   = m_pPopUpQuickPlay.m_bSelected;
	pGameOptions.AutoTargetSlider  = m_pAutoAim.GetCurrentTextureIndex();
	pGameOptions.MouseSensitivity  = m_pOptionMouseSens.GetScrollBarValue();
	//added 1.4 orvs
	bUnlimited = m_pOptionUnlimitedP.m_bSelected;
	SaveConfig();
}

//function existed in 1.56 as SetMenuGameValues()
//renamed in 1.6
function UpdateOptionsInPage()
{
	local R6GameOptions pGameOptions;
	pGameOptions = class'Actor'.static.GetGameOptions();
	//commented out in vanilla
	m_pOptionUnlimitedP.SetButtonBox(pGameOptions.UnlimitedPractice);
	m_pOptionAlwaysRun.SetButtonBox(pGameOptions.AlwaysRun);
	m_pOptionInvertMouse.SetButtonBox(pGameOptions.InvertMouse);
	m_pPopUpLoadPlan.SetButtonBox(pGameOptions.PopUpLoadPlan);
	m_pPopUpQuickPlay.SetButtonBox(pGameOptions.PopUpQuickPlay);
	m_pAutoAim.SetCurrentTextureFromIndex(pGameOptions.AutoTargetSlider);
	m_pOptionMouseSens.SetScrollBarValue(pGameOptions.MouseSensitivity);
}