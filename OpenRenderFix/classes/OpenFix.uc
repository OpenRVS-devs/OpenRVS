class OpenFix extends Actor;

//a server actor class that will ensure clients can choose their own FOV and have weapons render correctly
//if the server already has a mod installed that requires a custom HUD, will not change it

//POTENTIAL ISSUE
//doesn't work in listen server? clients don't get a hud
//most likely not an issue here, it would be with host having the regular OpenRVS fov fix

simulated function PreBeginPlay()
{
	local string s;
	//FP WEAP FOV FIX
	s = caps(class'Actor'.static.GetModMgr().m_pCurrentMod.m_GlobalHUDToSpawn);
	//if it's blank or if it's set to default, change
	if ( ( s == "" ) || ( s == "R6GAME.R6HUD" ) )
		class'Actor'.static.GetModMgr().m_pCurrentMod.m_GlobalHUDToSpawn = "OpenRenderFix.OpenRender";
}

defaultproperties
{
	bHidden=true
	bAlwaysRelevant=true
	bAlwaysTick=true
	RemoteRole=ROLE_SimulatedProxy
}