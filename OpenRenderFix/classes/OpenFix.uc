class OpenFix extends Actor;

//a server actor class that will ensure clients can choose their own FOV and have weapons render correctly
//if the server already has a mod installed that requires a custom HUD, will not change it

// A listen host may already have selected OpenRVS.OpenHUD through its client
// menus. Replace that local HUD with the network-distributed multiplayer HUD
// too; preserve HUDs supplied by other mods.

simulated function PreBeginPlay()
{
	local string s;
	//FP WEAP FOV FIX
	s = caps(class'Actor'.static.GetModMgr().m_pCurrentMod.m_GlobalHUDToSpawn);
	// Stock and OpenRVS client HUDs both use the multiplayer replacement.
	if ( ( s == "" ) || ( s == "R6GAME.R6HUD" ) || ( s == "OPENRVS.OPENHUD" ) )
		class'Actor'.static.GetModMgr().m_pCurrentMod.m_GlobalHUDToSpawn = "OpenRenderFix.OpenRender";
}

defaultproperties
{
	bHidden=true
	bAlwaysRelevant=true
	bAlwaysTick=true
	RemoteRole=ROLE_SimulatedProxy
}