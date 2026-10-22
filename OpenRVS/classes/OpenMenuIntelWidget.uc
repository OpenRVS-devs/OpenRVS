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

// Candidate mod classes from ServerActors, and whether the level already
// contains an instance of each. Used so one level scan covers all of them.
struct ModSpawnCheck
{
	var class<Actor> ModClass;
	var bool bFound;
};

function ShowWindow()
{
	local int i,j;
	local GameEngine GE;
	local class<Actor> AMod;
	local Actor A;
	local bool bDuplicate;
	local array<ModSpawnCheck> ModChecks;
	local class<R6CheatManager> CheatClass;//1.4
	local string s;//1.4
	local class<R6PlayerController> CustomPC;//1.4
	super.ShowWindow();
	LoadConfig();
	if ( bUseMPModsInSinglePlayer )
	{
		class'OpenLogger'.static.Info("experimental MP mods feature enabled", self);
		GE = GameEngine(FindObject("Transient.GameEngine0",class'GameEngine'));
		if ( GE == none )
			return;
		GE.LoadConfig("..\\Mods\\" $ class'Actor'.static.GetModMgr().GetModKeyword() $ ".mod");
		// Resolve the ServerActors entries first. This used to happen inside a
		// loop which also walked every actor in the level for each entry.
		i = 0;
		while ( i < GE.ServerActors.length )
		{
			AMod = none;
			if ( ( InStr(caps(GE.ServerActors[i]),"OPENRVS") == -1 ) && ( InStr(caps(GE.ServerActors[i]),"IPDRV") == -1 ) )
				AMod = class<Actor>(DynamicLoadObject(GE.ServerActors[i],class'class'));
			if ( AMod != none )
			{
				// Ignore repeated ServerActors entries for the same class.
				bDuplicate = false;
				j = 0;
				while ( j < ModChecks.length )
				{
					if ( ModChecks[j].ModClass == AMod )
						bDuplicate = true;
					j++;
				}
				if ( !bDuplicate )
				{
					ModChecks.Length = ModChecks.Length + 1;
					ModChecks[ModChecks.Length - 1].ModClass = AMod;
					ModChecks[ModChecks.Length - 1].bFound = false;
				}
			}
			i++;
		}
		// Walk the level once, checking every actor against every candidate
		// class, instead of doing a full scan per ServerActors entry.
		if ( ModChecks.length > 0 )
		{
			foreach GetLevel().AllActors(class'Actor',A)
			{
				if ( A != none )
				{
					j = 0;
					while ( j < ModChecks.length )
					{
						if ( A.class == ModChecks[j].ModClass )
							ModChecks[j].bFound = true;
						j++;
					}
				}
			}
			i = 0;
			while ( i < ModChecks.length )
			{
				if ( !ModChecks[i].bFound )
				{
					GetLevel().spawn(ModChecks[i].ModClass);
					class'OpenLogger'.static.Info("using multiplayer mod " $ ModChecks[i].ModClass $ " in single-player ...", self);
				}
				i++;
			}
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
	if (class'OpenLogger'.static.IsDebugEnabled())
		class'OpenLogger'.static.Debug("OpenRVS experimental SP manager set to: "$CheatClass, self);
	class'R6PlayerController'.default.CheatClass = CheatClass;
	s = caps(class'Actor'.static.GetModMgr().m_pCurrentMod.m_PlayerCtrlToSpawn);
	if ( ( s != "" ) && ( InStr(s,"R6ENGINE.") == -1 ) )//mod has custom pc
	{
		CustomPC = class<R6PlayerController>(DynamicLoadObject(class'Actor'.static.GetModMgr().m_pCurrentMod.m_PlayerCtrlToSpawn,class'Class'));
		if ( CustomPC != none )
		{
			CustomPC.default.CheatClass = CheatClass;
			if (class'OpenLogger'.static.IsDebugEnabled())
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