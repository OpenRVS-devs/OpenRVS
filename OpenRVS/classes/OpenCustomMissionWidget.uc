//NEW in 1.3
//allows loading custom gametypes!
//handles creation of a new button for game type selection
//handles spawning the proper gametype

//mods should be:
//	- a text file with extension ".game", includes:
//		- GameType - the string for the new gametype class eg "newmod.mynewgametype"
//		- ParentGameType - the default game type it extends, eg "RGM_LoneWolfMode"
//		- ButtonText - the appearance of the new button in Custom Mission, usually caps, eg "STEALTH WOLF"
//		- HelpString - the tooltip text that appears at the bottom on mouseover
//	- UTX or U files that contain any needed resources

//issue:
//	- after pressing > button on mission completed (maybe on failed too?), all custom buttons disappear for good

class OpenCustomMissionWidget extends R6MenuCustomMissionWidget;

var config string GameType;//the string for the new gametype class eg "newmod.mynewgametype"
var config string ParentGameType;//the default game type it extends, eg "RGM_LoneWolfMode"
var config string ButtonText;//the appearance of the new button in Custom Mission, eg "Stealth Wolf"
var config string HelpString;//the info that will appear in the box, eg "A stealthy version of Lone Wolf by Twi"

var bool CurrentIsCustomType;//we are clicked on a custom game type button
var array<R6WindowButton> CustomTypeBut;//the buttons for the custom game type
struct GInfo
{
	var string GType;//class of new type
	var string PType;//parent game type marker
	var string BText;//button text
	var string HText;//tooltip text
};
var array<GInfo> NewTypes;//all the new game type mods we find

//finds all *.game files and uses them to populate the list of modded game types
function LoadNewGameTypes()
{
	local R6FileManager pFileManager;
	local int i,iFiles;
	local string szIniFilename;
	local GInfo Temp;
	pFileManager = new(none) class'R6FileManager';
	iFiles = pFileManager.GetNbFile("..\\Mods\\","game");
	for ( i = 0; i < iFiles; i++ )
	{
		GameType = "";
		ParentGameType = "";
		ButtonText = "";
		HelpString = "";
		pFileManager.GetFileName(i,szIniFilename);
		if ( szIniFilename == "" )
		continue;
		LoadConfig("..\\Mods\\"$szIniFilename);
		if ( GameType != "" )
		{
			Temp.GType = GameType;
			Temp.PType = ParentGameType;
			Temp.BText = ButtonText;
			Temp.HText = HelpString;
			NewTypes[NewTypes.length] = Temp;
		}
	}
}

//modified from super to create buttons for the new game types
function CreateButtons()
{
	local float fXOffset,fYOffset,fWidth,fHeight,fYPos;
	local int i;
	local R6WindowButton Temp;
	fXOffset = 10;
	fYOffset = 26;
	fWidth = 200;
	fHeight = 25;
	fYPos = 64;
	super.CreateButtons();//create the default buttons before cycling through *.game files looking for a new game mode to create
	LoadNewGameTypes();
	i = 0;
	while ( i < NewTypes.length )
	{
		Temp = R6WindowButton(CreateControl(class'R6WindowButton',fXOffset,(fYOffset*(i+1))+142,fWidth,fHeight,self));
		Temp.ToolTipString = NewTypes[i].HText;
		Temp.Text = NewTypes[i].BText;
		Temp.m_iButtonID = 99 + i;
		Temp.Align = TA_Left;
		Temp.m_buttonFont = m_LeftButtonFont;
		Temp.CheckToDownSizeFont(m_LeftDownSizeFont,0);
		Temp.ResizeToText();
		CustomTypeBut[CustomTypeBut.length] = Temp;
		i++;
	}
	i = 0;
	while ( i < CustomTypeBut.length )
	{
		if ( CustomMissionGameType == CustomTypeBut[i].m_iButtonID )
		{
			m_pButCurrent.m_bSelected = false;
			m_pButCurrent = CustomTypeBut[i];
			CustomTypeBut[i].m_bSelected = true;
			CurrentIsCustomType = true;
			RefreshList();//help fix?
		}
		i++;
	}  
}

//from super
//now adds U and UTX support to the Mods folder
function Created()
{
	local R6Mod Temp;
	super.Created();
	Temp = class'Actor'.static.GetModMgr().m_pCurrentMod;
	Temp.m_aExtraPaths[Temp.m_aExtraPaths.length] = "..\\Mods\\*.u";
	Temp.m_aExtraPaths[Temp.m_aExtraPaths.length] = "..\\Mods\\*.utx";
	class'Actor'.static.GetModMgr().AddNewModExtraPath(Temp,0);
}


//rewritten from super
//will get the custom game type if a custom type button is selected
function GotoPlanning()
{
	local R6MenuRootWindow R6Root;
	local R6MissionDescription CurrentMission;
	local R6WindowListBoxItem SelectedItem;
	local R6Console R6Console;
	R6Root = R6MenuRootWindow(Root);
	//Make sure that ValidateBeforePlanning() has returned true
	//Before calling this
	SelectedItem = R6WindowListBoxItem(m_GameLevelBox.m_SelectedItem);
	CurrentMission = R6MissionDescription(SelectedItem.m_Object);//IF THIS IS NONE WE ARE SCREWED
	R6Console = R6Console(Root.console);
	R6Console.master.m_StartGameInfo.m_CurrentMission = CurrentMission;
	R6Console.master.m_StartGameInfo.m_MapName = CurrentMission.m_MapName;
	R6Console.master.m_StartGameInfo.m_DifficultyLevel = R6MenuDiffCustomMissionSelect(m_DifficultyArea.m_ClientArea).GetDifficulty();
	R6Console.master.m_StartGameInfo.m_iNbTerro = R6MenuCustomMissionNbTerroSelect(m_TerroArea.m_ClientArea).GetNbTerro();
	if ( CurrentIsCustomType )//need to grab raw text of class name
		R6Console.master.m_StartGameInfo.m_GameMode = NewTypes[m_pButCurrent.m_iButtonID - 99].GType;
	else
		R6Console.master.m_StartGameInfo.m_GameMode = GetLevel().GetGameTypeClassName(GetLevel().ConvertGameTypeIntToString(m_pButCurrent.m_iButtonID));
	CustomMissionMap = CurrentMission.m_MapName;
	CustomMissionGameType = m_pButCurrent.m_iButtonID;
	SaveConfig();
	Root.ResetMenus();
	R6Root.m_bLoadingPlanning = true;
	R6Console.PreloadMapForPlanning();
}

//rewritten from super
//if a custom game type selected, will get the parent type to display maplist
function RefreshList()
{
	local   int		  i, iCampaign, iMission;
	local   R6console	r6Console;
	local   string	   szMapName;	
	local   R6WindowListBoxItem  NewItem, ItemToSelect;
	local   string	   szGameType;
	local   R6MissionDescription mission;
	r6console = R6Console( Root.Console );
	if ( CurrentIsCustomType )//need to grab parent type flag
		szGameType = NewTypes[m_pButCurrent.m_iButtonID - 99].PType;
	else
		szGameType = GetLevel().ConvertGameTypeIntToString(m_pButCurrent.m_iButtonID);
	m_GameLevelBox.Clear();
	// loop on campaign and list all thier mission in the right order
	iCampaign = 0;
	while ( iCampaign < r6console.m_aCampaigns.length )
	{
		iMission = 0;
		while ( iMission < r6console.m_aCampaigns[iCampaign].m_missions.length )
		{
			mission = r6console.m_aCampaigns[iCampaign].m_missions[iMission];
			// a campaign and is available and is for the current mod
			if ( mission.IsAvailableInGameType( szGameType ) && mission.m_MapName != "" && CampainMapExistInMapList(mission))
			{
				szMapName = Localize( mission.m_MapName, "ID_MENUNAME", mission.LocalizationFile, true );
				if ( szMapName == "" ) // failed to find the name, copy the map map (usefull for debugging)
				{
					szMapName = mission.m_MapName;
				}
				NewItem = R6WindowListBoxItem(m_GameLevelBox.Items.Append(m_GameLevelBox.ListClass));
				NewItem.HelpText = szMapName;
				NewItem.m_Object = mission;
				if ( mission.m_bIsLocked )
				{
					NewItem.m_bDisabled = true;
				}
				else if((mission.m_MapName == m_LastMapPlayed) && (ItemToSelect == None))
				{
					ItemToSelect = NewItem;
				}
			}
			++iMission;
		}
		++iCampaign;
	}   
	// loop on the mission description and add all none campaign mission
	iMission = 0;
	while ( iMission < r6console.m_aMissionDescriptions.length )
	{
		mission = r6console.m_aMissionDescriptions[iMission];
		// not a campaign and is available and is for the current mod
		if ( !mission.m_bCampaignMission && mission.IsAvailableInGameType( szGameType ) && mission.m_MapName != "" )
		{
			szMapName = Localize( mission.m_MapName, "ID_MENUNAME", mission.LocalizationFile, true );
			if ( szMapName == "" ) // failed to find the name, copy the map map (usefull for debugging)
			{
				szMapName = mission.m_MapName;
			}
			NewItem = R6WindowListBoxItem(m_GameLevelBox.Items.Append(m_GameLevelBox.ListClass));
			NewItem.HelpText = szMapName;
			NewItem.m_Object = mission;
			if ( mission.m_bIsLocked )
			{
				NewItem.m_bDisabled = true;
			}
			else if((mission.m_MapName == m_LastMapPlayed) && (ItemToSelect == None))
			{
				ItemToSelect = NewItem;
			}
		}
		++iMission;
	}
	if(m_GameLevelBox.Items.Count() > 0)
	{
		if(ItemToSelect != None)
		  m_GameLevelBox.SetSelectedItem(ItemToSelect);
		else
			m_GameLevelBox.SetSelectedItem(R6WindowListBoxItem(m_GameLevelBox.Items.Next));
		m_GameLevelBox.MakeSelectedVisible(); 
	}
	//TO DO : FILTER MAPS 
	UpdateBackground();
	m_LastMapPlayed = "";
}

//from super
//handles the number of tangos area
//needs to get the string of parent type if custom
function UpdateBackground()
{
	local string s;
	if ( CurrentIsCustomType )//need to grab parent type flag
		s = NewTypes[m_pButCurrent.m_iButtonID - 99].PType;
	else
		s = GetLevel().ConvertGameTypeIntToString(m_pButCurrent.m_iButtonID);
	if ( GetLevel().GameTypeUseNbOfTerroristToSpawn(s) )
	{
		m_DifficultyArea.SetCornerType(Top_Corners);
		m_TerroArea.ShowWindow();
		// randomly update the background texture
		Root.SetLoadRandomBackgroundImage("OtherMission");
	}
	else
	{
		m_DifficultyArea.SetCornerType(All_Corners);
		m_TerroArea.HideWindow();
		// randomly update the background texture
		Root.SetLoadRandomBackgroundImage("PracticeMission");
	}
}

//from super
//needs to set CurrentIsCustomType based on what we click
function Notify(UWindowDialogControl C, byte E)
{
	local   R6WindowListBoxItem	 SelectedItem;
	local   R6MissionDescription	CurrentMission;
	local   R6WindowBitMap		  mapBitmap;
	local int i;
	if(E == DE_Click)
	{   
		switch(C)
		{
		case m_ButtonMainMenu:
			Root.ChangeCurrentWidget(MainMenuWidgetID);
			break;
		case m_ButtonOptions:
			Root.ChangeCurrentWidget(OptionsWidgetID);
			break;	
		case m_ButtonStart:
			if( ValidateBeforePlanning() )
				GotoPlanning();	
			break;			
		case m_pButPraticeMission:
		case m_pButLoneWolf:
		case m_pButTerroHunt:
		case m_pButHostageRescue:
			CurrentIsCustomType = false;
		case m_pButCurrent:
			m_pButCurrent.m_bSelected = false;
			R6WindowButton(C).m_bSelected = true;
			m_pButCurrent = R6WindowButton(C);
			RefreshList();
			break;
		case m_GameLevelBox:
			mapBitmap = R6WindowBitMap(m_Map.m_ClientArea);
			SelectedItem = R6WindowListBoxItem(m_GameLevelBox.m_SelectedItem);
			
			if(SelectedItem == None)
			{
				mapBitmap.T = None;
				break;
			}
			if(SelectedItem.m_Object == None)
				break;
			CurrentMission  = R6MissionDescription(SelectedItem.m_Object);
			if(CurrentMission == None)
				break;
			//This is for the current mission overview texture
			//Bottom right og the page
			mapBitmap.R = CurrentMission.m_RMissionOverview;
			mapBitmap.T = CurrentMission.m_TMissionOverview;
			break;
		default:
			//added so that we can click on the new types and it sets the customtype flag to true, then refreshes
			i = 0;
			while ( i < CustomTypeBut.length )
			{
				if ( ( R6WindowButton(C) != none ) && ( R6WindowButton(C) == CustomTypeBut[i] ) )
				{
					CurrentIsCustomType = true;
					m_pButCurrent.m_bSelected = false;
					R6WindowButton(C).m_bSelected = true;
					m_pButCurrent = R6WindowButton(C);
					RefreshList();
				}
				i++;
			}
			break;
		}
	}
	else if (E == DE_DoubleClick)
	{
		// start a game on a double-click on the list
		if ( (C == m_GameLevelBox) && ( ValidateBeforePlanning() ) )
		{
			GotoPlanning();	
		}
	}
}