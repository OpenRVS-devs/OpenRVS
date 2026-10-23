// OpenHTTPClient handles all HTTP/TCP traffic originating from the game client.
// The base game only uses UDP, so this is only used by us.
// TcpLink extends InternetLink extends InternetInfo extends Info extends Actor.
// Use Spawn(class'OpenHTTPClient') to get an instance.
// Each OpenHTTPClient handles exactly one request. Once the callback has run,
// the client resets itself and destroys the actor, so callers should treat
// their reference as dead after that point (set it to None in the callback).
// Spawn a new client for every request; never keep one around after it has
// finished, or it will tick forever without doing anything.
// WARNING: UE2 only supports HTTP 1.0; HTTP 1.1 connections won't close before
// timing out.
// Instructions for using OpenHTTPClient:
// 1. Write a callback function with the signature `function C(HttpResponse r)`.
//    Your function can operate on the status code `r.Code` or the response
//    body lines `r.Lines`. This function should be added to the very bottom of
//    this file.
// 2. Add the name of your callback as a const in this class.
// 3. Add a reference to your callback provider as a var in this class.
// 4. Register your callback in the switch statement in triggerCallbacks().
// 5. After spawning the client, set c.CallbackName = "your_callback" and set
//    c.YourCallbackProvider = class. Then you can call c.SendRequest() and
//    receive the data in your callback provider.
class OpenHTTPClient extends TcpLink;

//
// Types
//

struct ParsedURL
{
	var string Host;//e.g. google.com
	var int Port;//e.g. 80
	var string Path;//e.g. /servers
};

struct HttpResponse
{
	var int Code;//e.g. 200 (OK) or 404 (Not Found)
	var array<string> Lines;//response body, split into lines
};

// A connection that is accepted but never answered would otherwise stay in
// flight (and keep the client alive) for the rest of the session. Give up after
// this many seconds and report an empty response (Code 0) so callers fall back.
const HTTP_TIMEOUT = 30.0;

// Real HTTP headers are a few hundred bytes at most. Cap the header search so a
// malformed response that never ends its header cannot be copied without bound.
const MAX_HEADER_BYTES = 8192;

//
// Instance Variables
//

var HttpResponse Response;
var array<string> kiloBuffer;//array of 999-byte response segments
var bool requestInFlight;

var string Host;
var int Port;
var string Path;
var string CallbackName;

// Add new Callback vars here.
const CALLBACK_SERVER_LIST = "server_list";
var OpenServerList ServerListCallbackProvider;

const CALLBACK_VERSION_CHECK = "version_check";
var OpenRVS VersionCheckCallbackProvider;

//
// Event Overrides
//

// Called when domain resolution is successful.
// The IpAddr struct Addr contains the valid address.
event Resolved(IpAddr Addr)
{
	super.Resolved(Addr);

	class'OpenLogger'.static.Debug("dns resolution succeeded, initiating connection", self);
	Addr.Port = Port;
	Open(Addr);	
}

// Called when domain resolution fails.
event ResolveFailed()
{
	super.ResolveFailed();

	if ( bPendingDelete || bDeleteMe )//cleanup already started, nothing to report
		return;

	class'OpenLogger'.static.Error("dns resolution failed", self);
	triggerCallbacks();//caller still needs to process a result; this also destroys the client
}

// Opened: Called when socket successfully connects.
// Sends an HTTP request.
event Opened()
{
	local string CRLF;

	super.Opened();
	class'OpenLogger'.static.Debug("connection opened", self);

	// HTTP GET request format:
	// First line is "GET $PATH $HOST HTTP/1.0" followed by CRLF.
	// Next N lines are headers followed by CRLF.
	// Last line is empty line (CRLF).

	CRLF = Chr(13) $ Chr(10);
	SendText("GET" @ Path @ "HTTP/1.0" $ CRLF $ "Host:" @ Host $ CRLF $ "Accept: text/plain" $ CRLF $ CRLF);
	class'OpenLogger'.static.Debug("request sent", self);
}

// ReceivedText: Called when data is received.
// It will only deliver 999 bytes of data per call, so we need to buffer the output.
event ReceivedText(string bytes)
{
	super.ReceivedText(bytes);

	if (class'OpenLogger'.static.IsDebugEnabled())
		class'OpenLogger'.static.Debug("text received. size:" @ Len(bytes) @ "bytes", self);
	kiloBuffer[kiloBuffer.Length] = bytes;
}

// Closed: Called when Close() completes or the connection is dropped.
// Parses an HTTP response and sends it to the matching callback function.
event Closed()
{
	local HttpResponse resp;

	// Ignore late events once cleanup has started (for example after the
	// timeout, or while the socket is being closed by Destroy()).
	if ( bPendingDelete || bDeleteMe )
		return;

	super.Closed();

	class'OpenLogger'.static.Debug("connection closed, data is ready", self);

	resp = parseHttpResponse(kiloBuffer);
	if (resp.Code == -1)//this is not an HTTP response
	{
		class'OpenLogger'.static.Debug("response was not HTTP, reporting failure", self);
		triggerCallbacks();//report the empty response so callers can fall back
		return;
	}
	if (class'OpenLogger'.static.IsDebugEnabled())
		class'OpenLogger'.static.Debug("response received with" @ resp.Lines.Length @ "body lines", self);
	Response = resp;

	if (Response.Code != 200)//warn and continue
		class'OpenLogger'.static.Warning("http request failed with code" @ Response.Code, self);

	triggerCallbacks();
}

// Fires when a request takes too long (see HTTP_TIMEOUT). Reports the empty
// response so the caller can fall back, then cleans up like any other request.
event Timer()
{
	class'OpenLogger'.static.Error("http request timed out", self);
	triggerCallbacks();
}

//
// Custom Functions
//

// SendRequest() sends an HTTP request to the given URL. The response can be
// passed to your code in triggerCallbacks(). Returns true on success.
// A client only handles one request; spawn another one for the next request.
function bool SendRequest(string url)
{
	local ParsedURL parsed;
	local HttpResponse resp;

	if (requestInFlight)
	{
		class'OpenLogger'.static.Error("another http request already in progress", self);
		return false;
	}
	requestInFlight = true;
	SetTimer(HTTP_TIMEOUT, false);//do not wait forever for a silent server

	kiloBuffer.Remove(0, kiloBuffer.Length);

	if (CallbackName == "")
		class'OpenLogger'.static.Debug("callbackName should not be empty", self);

	parsed = parseHttpUrl(url);
	if ( parsed.Host == "" || parsed.Port < 1 || parsed.Port > 65535 )
	{
		class'OpenLogger'.static.Error("invalid HTTP URL", self);
		triggerCallbacks();
		return false;
	}
	Host = parsed.Host;
	Port = parsed.Port;
	Path = parsed.Path;
	if (class'OpenLogger'.static.IsDebugEnabled())
		class'OpenLogger'.static.Debug("sending request to http://" $ Host $ ":" $ Port $ Path, self);

	BindPort();//create client socket
	LinkMode = MODE_Text;
	ReceiveMode = RMODE_Event;
	class'OpenLogger'.static.Debug("client tcp socket created", self);

	// Resolve DNS and open the connection.
	class'OpenLogger'.static.Debug("starting dns resolution", self);
	Resolve(parsed.Host);

	return true;
}

// Fires any matching callbacks. Register new callbacks here.
// This is the last thing a request does: the client is destroyed afterwards.
private function triggerCallbacks()
{
	if (CallbackName == "")
	{
		class'OpenLogger'.static.Debug("callback name was empty", self);
		finishRequest();//nothing to call, but still clean up
		return;
	}
	switch (CallbackName)
	{
		// Register new callbacks here.
		case CALLBACK_SERVER_LIST:
			class'OpenLogger'.static.Debug("calling ServerListCallback", self);
			ServerListCallback(Response);
			break;
		case CALLBACK_VERSION_CHECK:
			class'OpenLogger'.static.Debug("calling VersionCheckCallback", self);
			VersionCheckCallback(Response);
			break;
		default:
			if (class'OpenLogger'.static.IsDebugEnabled())
				class'OpenLogger'.static.Debug("unknown callback name" @ CallbackName, self);
			break;
	}

	finishRequest();//all done, release the actor
}

// Resets the instance and destroys it. A client is spawned per request and has
// nothing left to do after its callback, so keeping it alive would only leave
// an idle ticking TcpLink actor behind for the rest of the session.
private function finishRequest()
{
	resetHttpClient();
	Destroy();
}

// Clears the per-request state before the client is destroyed.
private function resetHttpClient()
{
	local HttpResponse emptyResp;

	kiloBuffer.Remove(0, kiloBuffer.Length);
	Response = emptyResp;
	Host = "";
	Port = 0;
	Path = "";
	requestInFlight = false;
}

// Separates an HTTP URL into Host, Port, and Path.
private static function ParsedURL parseHttpUrl(string url)
{
	local array<string> urlParts;
	local int numParts;
	local ParsedURL parsed;
	local int i;
	local string path;
	local int sep;//index of ":"

	if (InStr(url, "http://") == -1)
		url = "http://" $ url;//make http:// optional

	//before: "http://www.example.com[:80]/servers"
	//after: ["http:", "", "www.example.com[:80]", "servers"]
	numParts = class'OpenString'.static.Split(url, "/", urlParts);

	if ( numParts < 3 )
		return parsed;
	if ( urlParts[2] == "" )
		return parsed;

	// Parse host and port.
	if (InStr(urlParts[2], ":") == -1)//url does not contain port
	{
		parsed.Host = urlParts[2];
		parsed.Port = 80;//make port optional
	}
	else//url contains port
	{
		parsed.Host = Left(urlParts[2], InStr(urlParts[2], ":"));//up to :
		parsed.Port = int(Mid(urlParts[2], InStr(urlParts[2], ":")+1));//after :
	}

	// Parse path.
	for (i=3; i<numParts; i++)//i=3 skips proto and hostport, starting at path
	{
		path = path $ "/" $ urlParts[i];
	}
	if (path == "")
		path = "/";//make path optional
	parsed.Path = path;	

	return parsed;
}

// Splits one response chunk into lines, appending complete lines to lines.
// Returns the trailing incomplete line so a line that spans two chunks is not
// lost. Only the current chunk is ever sliced, so the whole body is never copied
// repeatedly.
private static function string splitLines(string chunk, string carry, out array<string> lines)
{
	local int i;//index of the next line break

	i = InStr(chunk, Chr(10));
	while (i != -1)
	{
		carry = carry $ Left(chunk, i);
		if ( Right(carry, 1) == Chr(13) )
			carry = Left(carry, Len(carry)-1);
		lines[lines.Length] = carry;
		carry = "";
		chunk = Mid(chunk, i+1);
		i = InStr(chunk, Chr(10));
	}
	return carry $ chunk;//keep the incomplete line for the next chunk
}

// Parses an HTTP response, returning the code and the body split into lines.
// The body arrives in 999-byte chunks, so only the (small, capped) header is
// concatenated; the body is split into lines chunk by chunk. Concatenating every
// chunk into one growing string would copy the body O(n^2) times.
private static function HttpResponse parseHttpResponse(array<string> chunks)
{
	local string CRLF;
	local HttpResponse resp;
	local string header;//response up to and including the end of the header
	local string carry;//line that continues in the next chunk
	local array<string> lines;
	local int headerEnd;//index of the blank line that ends the header
	local int i;

	// HTTP response format:
	// First line is "HTTP/1.0 <HTTP CODE>" + CRLF e.g. "HTTP/1.0 200 OK"
	// Next N lines are info+headers followed by CRLF.
	// Next line is CRLF only.
	// Remaining lines are HTTP response body.

	resp.Code = -1;//not an HTTP response unless proven otherwise
	if (chunks.Length == 0)
		return resp;
	if (Left(chunks[0], 4) != "HTTP")//this is not an HTTP response
		return resp;

	// Find the blank line that ends the header. It may span two chunks, so
	// search the chunks joined so far.
	CRLF = Chr(13) $ Chr(10);
	for (i = 0; i < chunks.Length; i++)
	{
		header = header $ chunks[i];
		headerEnd = InStr(header, CRLF $ CRLF);
		if (headerEnd != -1)
			break;
		if (Len(header) > MAX_HEADER_BYTES)//malformed response; do not keep growing
			return resp;
	}
	if (headerEnd == -1)//no blank line, so this is not a complete HTTP response
		return resp;

	resp.Code = int(Mid(header, 9, 11));//response code is always these three characters.

	// Split the body into lines. The body starts in the chunk where the header
	// ended, so use the rest of that chunk; the remaining chunks are used as-is.
	carry = splitLines(Mid(header, headerEnd+4), carry, lines);//4=bytes of CR LF CR LF
	for (i = i+1; i < chunks.Length; i++)
		carry = splitLines(chunks[i], carry, lines);
	if ( Right(carry, 1) == Chr(13) )
		carry = Left(carry, Len(carry)-1);
	if (carry != "")//body did not end with a line break
		lines[lines.Length] = carry;
	resp.Lines = lines;

	return resp;
}

//
// Callbacks (in lieu of waiting for responses, get a callback instead)
// Callbacks should accept an HttpResponse as the only param and return nothing.
//

// Feed data to the server list parser.
function ServerListCallback(HttpResponse resp)
{
	if (ServerListCallbackProvider == none)
	{
		class'OpenLogger'.static.Debug("ServerListCallbackProvider was none", self);
		return;//nothing to do
	}
	ServerListCallbackProvider.ParseServers(resp);
}

// Return the latest OpenRVS version to the version checker.
function VersionCheckCallback(HttpResponse resp)
{
	if (VersionCheckCallbackProvider == none)
	{
		class'OpenLogger'.static.Debug("VersionCheckCallbackProvider was none", self);
		return;//nothing to do
	}
	VersionCheckCallbackProvider.CheckVersion(resp);
}

defaultproperties
{
	// TcpLink turns this on by default, which keeps the actor ticking even in
	// players-only mode. Socket polling does not need that here: the client only
	// lives while a request is in flight, so let it tick like any other actor.
	bAlwaysTick=False
}