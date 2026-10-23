//forces the "Custom Game" mod menu to load ALL mods, not just UBISoft's official ones
//implements the FOV fix in singleplayer
//allows loading of a custom cheat manager class
//implements starting the game in any mod

class OpenMods extends R6MenuOptionsMODS config(openrvs);//1.4 added config(openrvs)

//v1.4
var config string ForceStartMod;
var private bool bScannedMods;//.mod files are only read once per widget

//cycles through all *.mod files in Mods folder
//and unlocks them for use
//code originally recycled from Mod Unlocker by me
function SetMenuMODS()
{
	local R6FileManager pFileManager;
	local R6ModMgr pModManager;
	local R6Mod aMod;
	local int iFiles,i2,j;
	local string szIniFilename;
	local bool bFound;
	pModManager = class'Actor'.static.GetModMgr();
	// Scan the Mods directory and read each .mod file only once. This ran
	// every time the Mods page was initialized, even though the entries it
	// adds are kept in the mod manager.
	if ( !bScannedMods )
	{
		bScannedMods = true;
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
	// Applies the FOV fix and custom cheat manager, shared with
	// OpenMenuIntelWidget.
	class'OpenFOV'.static.ApplyClassDefaults(self);
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