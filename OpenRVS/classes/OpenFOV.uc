class OpenFOV extends Object config(openrvs);

// Retain this settings class and its config section for existing installs.
// Shared player-controller and HUD setup lives in OpenConfigManager.

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

// Compatibility entry point for callers using the original settings class.
static function ApplyClassDefaults(optional Object o)
{
	class'OpenConfigManager'.static.ApplyClassDefaults(o);
}
