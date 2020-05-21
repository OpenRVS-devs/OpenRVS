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