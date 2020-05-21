//experimental - load multiplayer mods in a singleplayer map
//works great since it's just actors spawned in a level
//but any mod that modifies MP only functions/classes/vars will have no effect
//also implements new FOV fix and cheat manager customization

class OpenMenuIntelWidget extends R6MenuIntelWidget config(openrvs);

var config bool bUseMPModsInSinglePlayer;//experimental
//v1.4
var int FOV;
var string NewCheatManagerClass;
var OpenFOV OpenFOV;

function ShowWindow()
{
	local int i;
	local GameEngine GE;
	local class<Actor> AMod;
	local Actor A;
	local bool bFound;
	local class<R6CheatManager> CheatClass;//1.4
	local string s;//1.4
	local class<R6PlayerController> CustomPC;//1.4
	super.ShowWindow();
	LoadConfig();
	if ( bUseMPModsInSinglePlayer )
	{
		log(" OpenRVS experimental MP mods feature enabled.");
		i = 0;
		GE = GameEngine(FindObject("Transient.GameEngine0",class'GameEngine'));
		if ( GE == none )
			return;
		GE.LoadConfig("..\\Mods\\" $ class'Actor'.static.GetModMgr().GetModKeyword() $ ".mod");
		while ( i < GE.ServerActors.length )
		{
			if ( ( InStr(caps(GE.ServerActors[i]),"OPENRVS") == -1 ) && ( InStr(caps(GE.ServerActors[i]),"IPDRV") == -1 ) )
				AMod = class<Actor>(DynamicLoadObject(GE.ServerActors[i],class'class'));
			if ( AMod != none )
			{
				bFound = false;
				foreach GetLevel().AllActors(class'Actor',A)
				{
					if ( A != none )
					{
						if ( A.class == AMod )
							bFound = true;
					}
				}
				if ( !bFound )
				{
					GetLevel().spawn(AMod);
					log(" OpenRVS using multiplayer mod " $ AMod $ " in single-player ...");
				}
			}
			AMod = none;
			i++;
		}
	}
	//1.4
	//this section duplicated in OpenMods
	//in case a mod or map skips planning, this here won't run
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
	//log(" OpenRVS experimental SP manager set to: "$CheatClass);
	class'R6PlayerController'.default.CheatClass = CheatClass;
	s = caps(class'Actor'.static.GetModMgr().m_pCurrentMod.m_PlayerCtrlToSpawn);
	if ( ( s != "" ) && ( InStr(s,"R6ENGINE.") == -1 ) )//mod has custom pc
	{
		CustomPC = class<R6PlayerController>(DynamicLoadObject(class'Actor'.static.GetModMgr().m_pCurrentMod.m_PlayerCtrlToSpawn,class'Class'));
		if ( CustomPC != none )
		{
			CustomPC.default.CheatClass = CheatClass;
			//log(" OpenRVS experimental SP manager set for: " $ CustomPC);
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