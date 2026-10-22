//experimental - load multiplayer mods in a singleplayer map
//works great since it's just actors spawned in a level
//but any mod that modifies MP only functions/classes/vars will have no effect
//also implements new FOV fix and cheat manager customization

class OpenMenuIntelWidget extends R6MenuIntelWidget config(openrvs);

var config bool bUseMPModsInSinglePlayer;//experimental

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
	// Applies the FOV fix and custom cheat manager, shared with OpenMods. This
	// runs in case a mod or map skips planning.
	class'OpenFOV'.static.ApplyClassDefaults(self);
}