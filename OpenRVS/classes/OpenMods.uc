//forces the "Custom Game" mod menu to load ALL mods, not just UBISoft's official ones
//implements the FOV fix in singleplayer
//allows loading of a custom cheat manager class
//implements starting the game in any mod

class OpenMods extends R6MenuOptionsMODS config(openrvs);//1.4 added config(openrvs)

//v1.4
var config string ForceStartMod;
var int FOV;
var string NewCheatManagerClass;
var OpenFOV OpenFOV;

//cycles through all *.mod files in Mods folder
//and unlocks them for use
//code originally recycled from Mod Unlocker by me
function SetMenuMODS()
{
	local R6FileManager pFileManager;
	local R6ModMgr pModManager;
	local R6Mod aMod;
	local int iFiles,i2,j;
	local string szIniFilename,s;
	local class<R6CheatManager> CheatClass;//1.4
	local class<R6PlayerController> CustomPC;//1.4
	local bool bFound;
	pModManager = class'Actor'.static.GetModMgr();
	pFileManager = new(none) class'R6FileManager';
	iFiles = pFileManager.GetNbFile("..\\Mods\\","mod");
	for ( i2 = 0; i2 < iFiles; i2++ )
	{
		pFileManager.GetFileName(i2,szIniFilename);
		if ( szIniFilename != "" )
		{
			aMod = new(none) class'Engine.R6Mod';
			aMod.Init(szIniFilename);
			j = 0;
			bFound = false;
			while ( j < pModManager.GetNbMods() )
			{
				if ( pModManager.m_aMods[j].m_szKeyWord == aMod.m_szKeyWord )
				bFound = true;
				j++;
			}
			if ( !bFound )
			pModManager.m_aMods[pModManager.m_aMods.length] = aMod;
		}
	}
	super.SetMenuMODS();
	LoadConfig();//1.4
	//1.4 jump to mod
	if ( ( ForceStartMod != "" ) && ( caps(ForceStartMod) != "RAVENSHIELD" ) )
	{
		ForceMod();
		//CRASHES!
		//something not working right here ...
		//can we uscript just call the button and "click" it?
		//class'Actor'.static.GetModMgr().SetCurrentMod(caps(ForceStartMod),GetLevel(),true,Root.Console,GetPlayerOwner().xlevel);
		//R6Console(Root.console).CleanAndChangeMod();
		//R6Console(Root.console).m_GameService.InitModInfo();
		//R6Console(Root.console).m_GameService.m_ModGSInfo.InitMod();
		//R6Console(Root.console).LeaveR6Game(LG_InitMod);
		//R6Console(Root.console).m_bChangeModInProgress = true;
		//R6Console(Root.console).LeaveR6Game(LG_InitMod);
		//R6GSServers(class'Actor'.static.GetGameManager().GetGameMgrGameService()).InitializeMod();
	}
	//1.4
	//this section duplicated in OpenMenuIntelWidget
	OpenFOV = new class'OpenFOV';
	FOV = OpenFOV.GetFOV();
	NewCheatManagerClass = OpenFOV.GetCMClass();
	OpenFOV = none;
	if ( FOV != 0 )
	{
		FOV = clamp(FOV,65,140);
		class'R6PlayerController'.default.DefaultFOV = FOV;
		class'R6PlayerController'.default.DesiredFOV = FOV;
	}
	if ( NewCheatManagerClass == "" )
		CheatClass = class'OpenCheat';
	else
	{
		CheatClass = class<R6CheatManager>(DynamicLoadObject(NewCheatManagerClass,class'Class'));
		if ( CheatClass == none )
			CheatClass = class'OpenCheat';
	}
	class'OpenLogger'.static.Info("experimental SP manager set to:" @ CheatClass, self);

	class'R6PlayerController'.default.CheatClass = CheatClass;
	s = caps(class'Actor'.static.GetModMgr().m_pCurrentMod.m_PlayerCtrlToSpawn);
	if ( ( s != "" ) && ( InStr(s,"R6ENGINE.") == -1 ) )//mod has custom pc
	{
		CustomPC = class<R6PlayerController>(DynamicLoadObject(class'Actor'.static.GetModMgr().m_pCurrentMod.m_PlayerCtrlToSpawn,class'Class'));
		if ( CustomPC != none )
		{
			CustomPC.default.CheatClass = CheatClass;
			class'OpenLogger'.static.Debug("OpenRVS experimental SP manager set for: " $ CustomPC, self);
			if ( FOV != 0 )
			{
				FOV = clamp(FOV,65,140);
				CustomPC.default.DefaultFOV = FOV;
				CustomPC.default.DesiredFOV = FOV;
			}
		}
	}
	//FP WEAP FOV FIX
	s = caps(class'Actor'.static.GetModMgr().m_pCurrentMod.m_GlobalHUDToSpawn);
	if ( ( s == "" ) || ( s == "R6GAME.R6HUD" ) )
		class'Actor'.static.GetModMgr().m_pCurrentMod.m_GlobalHUDToSpawn = "OpenRVS.OpenHUD";
}

//1.4 jump straight to mod
function ForceMod()
{
	local R6WindowListBoxItem NewItem;
	if ( class'Actor'.static.GetModMgr().m_pCurrentMod.m_szKeyWord ~= ForceStartMod )
		return;
	NewItem = R6WindowListBoxItem(m_pListOfMods.FindItemWithName(ForceStartMod));
	if ( NewItem != none )
	{
		m_pListOfMods.SetSelectedItem(NewItem);
		m_pListOfMods.ActivateMOD();
	}
}