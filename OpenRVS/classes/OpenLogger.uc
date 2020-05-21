class OpenLogger extends Object;

var config bool bDebugLoggingEnabled;

// DebugLog write a message to stdout prefixed with ***DEBUG***.
static function DebugLog(string s)
{
	if (false) // Set to true to enable debug logging globally.
	{
        // log() can accept a tag as a second parameter, e.g. `log(s, 'DEBUG');`, but
        // the tag does not support non-alphanumeric characters such as `*` or `[]`.
		log("***DEBUG***" @ s);
	}
}