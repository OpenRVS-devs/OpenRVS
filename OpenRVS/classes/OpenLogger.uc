class OpenLogger extends Object config(openrvs);

var config bool bDebugLoggingEnabled;

static function DebugLog(string s)
{
	if (bDebugLoggingEnabled)
	{
		log("***DEBUG***" @ s);
	}
}

defaultproperties
{
	bDebugLoggingEnabled=false // Set to true to enable debug logging globally.
}