//initiates a connection with external server list
//strips the received data down to an array of strings, then sends them to the server list to be parsed and displayed
//class is spawned on client by OpenMultiPlayerWidget
//0.6 beta
// - fixed issue with server list file being too large and causing errors
// - now correctly retrieves a server list of any size (theoretically?)
//1.3
// - this class now handles all parsing of server information
// - also handles loading backup server list if connection fails
// - now passes each server's info to the widget class instead of passing the raw strings to parse
//1.5
// - refactored to use OpenHTTPClient for request/response
// - now only focuses on parsing the response
class OpenServerList extends Actor;

struct AServer
{
	var string ServerName;
	var string IP;
	var string GameMode;
};

const INI_HEADER_LINE = "[OpenRVS.";//support any OpenRVS class
const CSV_HEADER_LINE = "name,ip,port,mode";
const FALLBACK_SERVERS_FILE = "Servers.list";

var OpenMultiPlayerWidget M;
var OpenHTTPClient httpc;
var config array<AServer> FallbackServers;//var name must match Servers.list
var string WebAddress;
var string FileName;

// Starts OpenServerList and send an HTTP request to the server list provider.
function Init(OpenMultiPlayerWidget Widget, optional string W, optional string F)
{
	M = Widget;
	if ( W != "" )
		WebAddress = W;
	else
		WebAddress = "openrvs.org";
	if ( F != "" )
		FileName = F;
	else
		FileName = "servers";

	httpc = Spawn(class'OpenHTTPClient');
	httpc.CallbackName = "server_list";
	httpc.ServerListCallbackProvider = self;
	httpc.SendRequest("http://" $ WebAddress $ "/" $ FileName);
}

// Receives and detects type for an HTTP response from the server list provider.
// It is also responsible for sending servers to OpenMultiPlayerWidget.
function ParseServers(OpenHTTPClient.HttpResponse resp)
{
	local array<string> lines;

	httpc = none;//done with HTTP client

	//Check for errors.
	if (resp.Code != 200)
	{
		class'OpenLogger'.static.Error("failed to retrieve servers over http", self);
		SendServersUpstream(GetFallbackServers());
		return;
	}

	class'OpenLogger'.static.Info("loading servers from Internet", self);
	class'OpenString'.static.Split(resp.Body, Chr(10), lines);
	class'OpenLogger'.static.Info("parsing" @ lines.Length @ "server lines", self);

	// Determine response type.
	if (Left(lines[0], Len(CSV_HEADER_LINE)) ~= CSV_HEADER_LINE)
	{
		SendServersUpstream(ParseServersCSV(lines));
		return;
	}
	if (Left(lines[0], Len(INI_HEADER_LINE)) ~= INI_HEADER_LINE)
	{
		SendServersUpstream(ParseServersINI(lines));
		return;
	}

	// Fall back to local file.
	class'OpenLogger'.static.Error("unknown server list response type", self);
	SendServersUpstream(GetFallbackServers());
}

// Parses a server list in the INI file format.
function array<AServer> ParseServersINI(array<string> lines)
{
	local string line;//server list line "ServerList=(a=b,c=d,e=f)"
	local array<string> fields;//parsed server parameters ["a=b", "c=d"]
	local array<string> kvpair;//one key=value parameter pair ["a", "b"]
	local int numFields, numSubfields;
	local int i, j;
	local AServer srv;
	local array<AServer> servers;

	class'OpenLogger'.static.Debug("using csv parser", self);
	lines.Remove(0, 1);//skips header line (specific to INI parser)

	// Convert each line to CSV K=V format (i.e. "a=b,c=d,e=f")
	for (i=0; i<lines.Length; i++)
	{
		line = lines[i];
		line = Mid(line, 12);//trim up to "ServerName="
		line = Left(line, Len(line)-1);//remove )
		lines[i] = line;//overwrite
	}

	for (i=0; i<lines.Length; i++)
	{
		numFields = class'OpenString'.static.Split(lines[i], ",", fields);//fields is now a list of k=v
		for (j=0; j<numFields; j++)
		{
			numSubfields = class'OpenString'.static.Split(fields[j], "=", kvpair);//kvpair is one k=v set
			if (numSubfields != 2)
			{
				//occurs when someone has "=" in their server name
				//we simply drop anything after (and including) the first "="
				class'OpenLogger'.static.Warning("failed to parse k=v in ServerListSuccess:" @ fields[j], self);
			}
			switch (kvpair[0])//text before "="
			{
				case "ServerName":
					srv.ServerName = class'OpenString'.static.StripQuotes(kvpair[1]);
					break;
				case "IP":
					srv.IP = class'OpenString'.static.StripQuotes(kvpair[1]);
					break;
				case "GameMode":
					srv.GameMode = class'OpenString'.static.StripQuotes(kvpair[1]);
					break;
				default:
					break;//unsupported key, nothing to do
			}
		}
		//error checking for required fields
		if ( (srv.ServerName == "") || (srv.IP == "") || (srv.GameMode == "") )
			continue;//do not add this server
		servers[servers.Length] = srv;
	}

	return servers;
}

function array<AServer> ParseServersCSV(array<string> lines)
{
	local array<string> fields;
	local int i;
	local AServer srv;
	local array<AServer> servers;

	class'OpenLogger'.static.Debug("using csv parser", self);
	lines.Remove(0, 1);//skips header line (specific to registry csv format)

	for (i=0; i<lines.Length; i++)
	{
		class'OpenString'.static.Split(lines[i], ",", fields);
		if (fields.Length != 4)
		{
			class'OpenLogger'.static.Warning("invalid line skipped:" @ lines[i], self);
			continue;
		}
		
		srv.ServerName = fields[0];
		srv.IP = fields[1] $ ":" $ fields[2];//Includes Port
		srv.GameMode = fields[3];

		//error checking for required fields
		if ( (srv.ServerName == "") || (srv.IP == ":") || (srv.GameMode == "") )
		{
			class'OpenLogger'.static.Warning("line contained empty field(s):" @ lines[i], self);
			continue;//do not add this server
		}
		servers[servers.Length] = srv;
	}

	return servers;
}

// Retrieves fallback servers from local file on disk.
function array<AServer> GetFallbackServers()
{
	LoadConfig(FALLBACK_SERVERS_FILE);
	class'OpenLogger'.static.Info("loaded" @ FallbackServers.Length @ "servers from fallback file", self);
	return FallbackServers;
}

// Sends the completed server list to OpenMultiPlayerWidget.
function SendServersUpstream(array<AServer> servers)
{
	local int i;

	class'OpenLogger'.static.Info("loading" @ servers.Length @ "parsed servers", self);
	M.ClearServerList();
	for (i=0; i<servers.Length; i++)
	{
		M.AddServerToList(servers[i].ServerName, servers[i].IP, servers[i].GameMode);	
	}
	M.FinishedServers();
}
