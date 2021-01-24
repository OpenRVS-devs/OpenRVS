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
// Disable debug logging for releases by changing the default property below.
static function Debug(string s, optional Object o)
{
	local bool debugMode;
	debugMode = true;//WARNING: Set to false before building releases for users!
	if (debugMode)
		writeMsg(s, LOG_LEVEL_DEBUG, o);
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
	log("	 The team: Twi, ijemafe, and Tony");
	log("	 With thanks to chriswak, Psycho, SMC clan, and SS clan");
}
