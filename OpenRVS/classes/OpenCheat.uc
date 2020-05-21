class OpenCheat extends R6CheatManager;

//v1.4 experimental
//allows actor mods to use cmd
//to use type in console: "cmd STRING"
//and actors will receive in SetAttachVar: R6PC actor (cast to get var), STRING, ''

//sends a command to mods
exec function cmd(string s)
{
	local Actor A;
	if ( CanExec() )
	{
		foreach AllActors(class'Actor',A)
		{
			if ( A != none )
				A.SetAttachVar(Outer,s,'');
		}
	}
}