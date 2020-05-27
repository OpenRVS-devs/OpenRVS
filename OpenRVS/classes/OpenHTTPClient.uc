// OpenHTTPClient handles all HTTP/TCP traffic originating from the game client.
// The base game only uses UDP, so this is only used by us.
// TcpLink extends InternetLink extends InternetInfo extends Info extends Actor.
// Use Spawn(class'OpenHTTPClient') to get an instance.
// HTTP clients store an HttpResponse, an array<string> buffer, and a reference
// to each callback provider. These are all reused and should not be set to None
// after use. Instead, set your HTTP client instance to None with finished.
// WARNING: UE2 only supports HTTP 1.0; HTTP 1.1 connections won't close before
// timing out.
// Instructions for using OpenHTTPClient:
// 1. Write a callback function with the signature `function C(HttpResponse r)`.
//    Your function can operate on the status code `r.Code` or the response
//    body `r.Body`. This function should be added to the very bottom of this
//    file.
// 2. Add the name of your callback as a const in this class.
// 3. Add a reference to your callback provider as a var in this class.
// 4. Register your callback in the switch statement under Closed() in this class.
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
	var string Body;//response body
};

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
	super.Destroy();//clean up the connection

	class'OpenLogger'.static.Error("dns resolution failed", self);
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

	class'OpenLogger'.static.Debug("text received. size:" @ Len(bytes) @ "bytes", self);
	kiloBuffer[kiloBuffer.Length] = bytes;
}

// Closed: Called when Close() completes or the connection is dropped.
// Parses an HTTP response and sends it to the matching callback function.
event Closed()
{
	local HttpResponse resp;
	local string bytes;
	local int i;

	super.Closed();

	class'OpenLogger'.static.Debug("connection closed, data is ready", self);

	// Merge paged response data.
	for (i=0; i<kiloBuffer.Length; i++)
	{
		bytes = bytes $ kiloBuffer[i];
	}

	resp = parseHttpResponse(bytes);
	if (resp.Code == -1)//this is not an HTTP response
		return;//not relevant to HTTP client
	class'OpenLogger'.static.Debug("response received with length" @ Len(resp.Body), self);
	Response = resp;

	if (Response.Code != 200)//warn and continue
		class'OpenLogger'.static.Warning("http request failed with code" @ Response.Code, self);

	if (CallbackName == "")
	{
		class'OpenLogger'.static.Debug("callback name was empty", self);
		return;//nothing to do
	}
	switch (CallbackName)
	{
		// Register new callbacks here.
		case CALLBACK_SERVER_LIST:
			class'OpenLogger'.static.Debug("calling ServerListCallback", self);
			ServerListCallback(Response);
			break;
		default:
			class'OpenLogger'.static.Debug("unknown callback name" @ CallbackName, self);
			break;
	}

	// Reset and release the HTTP client for the next request.
	resetHttpClient();
}

//
// Custom Functions
//

// SendRequest() sends an HTTP request to the given URL. The response can be
// passed to your code in Closed(). Returns true on success.
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

	kiloBuffer.Remove(0, kiloBuffer.Length);

	if (CallbackName == "")
		class'OpenLogger'.static.Debug("callbackName should not be empty", self);

	parsed = parseHttpUrl(url);
	Host = parsed.Host;
	Port = parsed.Port;
	Path = parsed.Path;
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

// Resets and unlocks the instance to be used for the next request.
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

// Parses an HTTP response string, returning the code and message body.
private static function HttpResponse parseHttpResponse(string response)
{
	local string CRLF;
	local HttpResponse resp;
	local int bodyStartsAt;

	// HTTP response format:
	// First line is "HTTP/1.0 <HTTP CODE>" + CRLF e.g. "HTTP/1.0 200 OK"
	// Next N lines are info+headers followed by CRLF.
	// Next line is CRLF only.
	// Remaining lines are HTTP response body.

	if (Left(response, 4) != "HTTP")//this is not an HTTP response
	{
		resp.Code = -1;
		return resp;
	}
	resp.Code = int(Mid(response, 9, 11));//response code is always these three characters.

	// Two CRLF in a row precede response body.
	CRLF = Chr(13) $ Chr(10);
	bodyStartsAt = InStr(response, CRLF $ CRLF);
	resp.Body = Mid(response, bodyStartsAt+4);//4=bytes of CR LF CR LF

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
	ServerListCallbackProvider.ParseServersINI(resp);
}
