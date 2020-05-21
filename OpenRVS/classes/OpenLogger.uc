class OpenLogger;

var config bool bDebugLoggingEnabled;

static function DebugLog(string s)
{
    if (bDebugLoggingEnabled)
    {
        log(s);
    }
}

defaultproperties
{
	bDebugLoggingEnabled=false // Set to true to enable debug logging globally.
}