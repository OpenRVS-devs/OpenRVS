// OpenLogger writes leveled logs to <GameDir>\system\ravenshield.log.
class OpenLogger extends Object;

const LOG_LEVEL_ERROR = "error";
const LOG_LEVEL_WARNING = "warning";
const LOG_LEVEL_INFO = "info";
const LOG_LEVEL_DEBUG = "debug";

const MAX_LOG_LEN = 512;

// Use Error() when something went wrong.
static function Error(string s, optional Object o)
{
	writeMsg(s, LOG_LEVEL_ERROR, o);
}

// Use Warning() when something went wrong, but we can proceed safely.
static function Warning(string s, optional Object o)
{
	writeMsg(s, LOG_LEVEL_WARNING, o);
}

// Use Info() for general messages.
static function Info(string s, optional Object o)
{
	writeMsg(s, LOG_LEVEL_INFO, o);
}

// Use Debug() for messages only developers should see.
// Enable debug logging for development builds in IsDebugEnabled() below.
static function Debug(string s, optional Object o)
{
	if (class'OpenLogger'.static.IsDebugEnabled())
		writeMsg(s, LOG_LEVEL_DEBUG, o);
}

// IsDebugEnabled reports whether Debug() writes messages. Call sites that build
// their message with string concatenation must check this first, otherwise the
// arguments are evaluated even when debug logging is disabled:
//   if (class'OpenLogger'.static.IsDebugEnabled())
//       class'OpenLogger'.static.Debug("value is " $ value, self);
static function bool IsDebugEnabled()
{
	local bool debugMode;
	debugMode = false;//WARNING: Set to false before building releases for users!
	return debugMode;
}

// writeMsg consistently formats OpenRVS logs, prepending the name of the caller
// class. For example: "[OpenRVS.OpenLogger] info: this is a log message".
static function writeMsg(string s, string level, optional Object o)
{
	// Format our log lines.
	if (o != none)
		s = "[" $ o.class $ "]" @ level $ ":" @ s;
	else
		s = "[OpenRVS]" @ level $ ":" @ s;

	// Enforce a maximum length. Calling log() with input longer than 990 bytes
	// appears to cause a full engine crash. Limit lines to 512 bytes and wrap
	// content beyond that length.
	while (Len(s) > MAX_LOG_LEN)
	{
		log(Left(s, MAX_LOG_LEN));//write 512 bytes
		s = Mid(s, MAX_LOG_LEN);//trim for next iteration
	}
	log(s);//write remaining bytes
}

// Prints the OpenRVS startup message to the log file.
static function LogStartupMessage()
{
	log("	 ---- OpenRVS ----");
	log("	 The team: Twi, Will, and Tony");//v1.5 update name
	log("	 With thanks to chriswak, Psycho, SMC clan, and SS clan");
}