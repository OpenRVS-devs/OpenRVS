class OpenLogger;

var config bool bDebugLoggingEnabled = False; // Set to True to enable debug logging in a debug build.

static function DebugLog(string s)
{
    if (bDebugLoggingEnabled)
    {
        log(s);
    }
}