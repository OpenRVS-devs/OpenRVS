class OpenLogger extends Object config(openrvs);

var config bool bDebugLoggingEnabled;

// DebugLog write a message to stdout prefixed with ***DEBUG***.
// Set bDebugLogginEnabled=true in openrvs.ini to enable.
static function DebugLog(string s)
{
	if (bDebugLoggingEnabled)
	{
		log(s, "***DEBUG***");
	}
}

defaultproperties
{
	bDebugLoggingEnabled=false // Set to true to enable debug logging globally.
}