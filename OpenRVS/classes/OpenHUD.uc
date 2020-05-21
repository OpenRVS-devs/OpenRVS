class OpenHUD extends R6HUD config(openrvs);

//new in v1.4
//implements weapon fov fix from supply drop

//weapon rendering
var config float DebugFPWeapRender;

//debug set fov rendering for weapon
exec function SetWeapFOV(float f)
{
	DebugFPWeapRender = f;
	SaveConfig();
	PlayerOwner.ClientMessage("DebugFPWeapRender="$DebugFPWeapRender);
}

simulated event RenderFirstPersonGun(Canvas C)
{
	local R6Pawn P;
	local R6Weapons W;
	local R6PlayerController PC;
	local float g;
	local rotator rNewRotation;
	if ( !PlayerOwner.bBehindView )
	{
		P = R6Pawn(PlayerOwner.ViewTarget);
		PC = R6PlayerController(PlayerOwner);
		if ( ( P != none ) && ( PC != none ) && ( R6Weapons(P.EngineWeapon) != none ) )
		{
			W = R6Weapons(P.EngineWeapon);
			if ( DebugFPWeapRender != 0.0 ) && ( !Level.m_bInGamePlanningActive ) &&( PC.m_bUseFirstPersonWeapon ) && ( W.m_FPHands != none )
			{
				W.m_FPHands.SetLocation(P.R6CalcDrawLocation(P.EngineWeapon,rNewRotation,P.EngineWeapon.m_vPositionOffset));
				W.m_FPHands.SetRotation(P.GetViewRotation() + rNewRotation + PC.m_rHitRotation);
				if ( PC.ShouldDrawWeapon() )
				{
					//IF DEBUGFPWEAPRENDER IS NEGATIVE
					//then the gun fov will be modified by the zoom level
					//this is default behaviour and what we want
					//ELSE
					//it will always render at a static fov
					if ( DebugFPWeapRender < -0.0 )//render at DebugFPWeapRender (modified by zoom)
						g = ( PlayerOwner.DefaultFOV * DebugFPWeapRender * -1 ) / PlayerOwner.default.DesiredFOV;
					else//render at DebugFPWeapRender (not modified)
						g = DebugFPWeapRender;
					C.DrawActor(W.m_FPHands,false,true,g);
				}
			}
			else
				P.EngineWeapon.RenderOverlays(C);//default vanilla ubi behaviour
		}
	}
}

defaultproperties
{
	DebugFPWeapRender=-90.0
}