class OpenFOV extends Object config(openrvs);

//can be used not just for FOV but also other things we need to load from multiple classes
//a simple object that any class can create and use to load config variables

var config int FieldOfView;
var config string NewCheatManagerClass;

function int GetFOV()
{
	LoadConfig();
	return FieldOfView;
}

function string GetCMClass()
{
	LoadConfig();
	return NewCheatManagerClass;
}

// Applies the configured FOV and cheat manager to the class defaults, including
// any custom player controller declared by the current mod, and points the
// stock HUD at OpenHUD for the first-person weapon FOV fix. OpenMods and
// OpenMenuIntelWidget used to carry identical copies of this block, each
// creating its own OpenFOV; loading the config once here removes the
// duplication and the second disk read.
static function ApplyClassDefaults(optional Object o)
{
	local OpenFOV FOVConfig;
	local class<R6CheatManager> CheatClass;
	local class<R6PlayerController> CustomPC;
	local int FOV;
	local string s;

	FOVConfig = new class'OpenFOV';
	FOVConfig.LoadConfig();
	FOV = FOVConfig.FieldOfView;
	if ( FOV != 0 )
	{
		FOV = clamp(FOV,65,140);
		class'R6PlayerController'.default.DefaultFOV = FOV;
		class'R6PlayerController'.default.DesiredFOV = FOV;
	}
	if ( FOVConfig.NewCheatManagerClass == "" )
		CheatClass = class'OpenCheat';
	else
	{
		CheatClass = class<R6CheatManager>(DynamicLoadObject(FOVConfig.NewCheatManagerClass,class'Class'));
		if ( CheatClass == none )
			CheatClass = class'OpenCheat';
	}
	class'OpenLogger'.static.Info("experimental SP manager set to:" @ CheatClass, o);
	class'R6PlayerController'.default.CheatClass = CheatClass;
	s = caps(class'Actor'.static.GetModMgr().m_pCurrentMod.m_PlayerCtrlToSpawn);
	if ( ( s != "" ) && ( InStr(s,"R6ENGINE.") == -1 ) )//mod has custom pc
	{
		CustomPC = class<R6PlayerController>(DynamicLoadObject(class'Actor'.static.GetModMgr().m_pCurrentMod.m_PlayerCtrlToSpawn,class'Class'));
		if ( CustomPC != none )
		{
			CustomPC.default.CheatClass = CheatClass;
			if (class'OpenLogger'.static.IsDebugEnabled())
				class'OpenLogger'.static.Debug("OpenRVS experimental SP manager set for: " $ CustomPC, o);
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