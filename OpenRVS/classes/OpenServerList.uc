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
class OpenServerList extends TcpLink;

struct AServer
{
	var string ServerName;
	var string IP;
	var string GameMode;
};//1.3 added here

var OpenMultiPlayerWidget M;
var string WebAddress;
var string FileName;
var config array<AServer> ServerList;

//start up
//receives a URL from multiplayer widget
//if no URL, connects with the default server list at rvsgaming.org
function Init(OpenMultiPlayerWidget Widget, optional string W, optional string F)
{
	local OpenHTTPClient httpc;

	log("	 ---- OpenRVS ----");
	log("	 Author: Twi");
	log("	 With thanks to Tony and Psycho");
	log("	 As well as SMC and SS clans");

	class'OpenLogger'.static.Debug("STARTING UP", self);

	M = Widget;
	if ( W != "" )
		WebAddress = W;
	else
		WebAddress = "gsconnect.rvsgaming.org";
	if ( F != "" )
		FileName = F;
	else
		FileName = "servers-updated.list";

	httpc = Spawn(class'OpenHTTPClient');
	httpc.CallbackName = "server_list";//access OpenHTTPClient.CALLBACK_SERVER_LIST?
	httpc.ServerListCallbackProvider = self;
	httpc.SendRequest("http://" $ WebAddress $ "/" $ FileName);
}

//when connection is finished, check the length of each received line.
//lines too large will crash/cause other issues
//so split lines into manageable size
//then parse them to find server info and send back to the multiplayer menu.
//strips out extra info on the ends of the string and returns a server string in this format:
//a server name",IP="44.434.4.434:7777",Locked=false,GameMode="Adver
//the function in OpenMultiPlayerWidget will parse this further to get the needed info.
//1.3 - NO LONGER parsed in OpenMultiPlayerWidget, parsed below
function ParseServersINI(OpenHTTPClient.HttpResponse resp)
{
	local array<string> lines;
	local string line;
	local int i;

	//Check for errors.
	if (resp.Code != 200)
	{
		class'OpenLogger'.static.Error("failed to retrieve servers over http", self);
		NoServerList();
	}

	// Convert each line to CSV K=V format (i.e. "a=b,c=d,e=f")
	class'OpenString'.static.Split(resp.Body, Chr(10), lines);
	lines.Remove(0, 1);//skips header line (specific to INI parser)
	for (i=0; i<lines.Length; i++)
	{
		line = lines[i];
		line = Mid(line, 12);//trim up to "ServerName="
		line = Left(line, Len(line)-1);//remove )
		lines[i] = line;//overwrite
	}

	if ( lines.length > 0 )
	{
		class'OpenLogger'.static.Info("loading server list from URL", self);
		ServerListSuccess(lines);//1.3 parsing moved here
	}
	else
		NoServerList();//1.3 noserverlist moved here
}

//1.3
//function moved here from openmultiplayerwidget
//in the widget, the config list of servers was getting saved and loaded in the user.ini
//and filling it with needless garbage?
//moving it here should prevent it from saving automatically to user.ini
//and prevent it from trying to load the glitchy lines?
//function parses an array of strings to get server info, then will send each server item to widget
function ServerListSuccess(array<string> List)
{
	local array<string> fields;//parsed server parameters ["a=b", "c=d"]
	local array<string> kvpair;//one key=value parameter pair ["a", "b"]
	local int numFields, numSubfields;
	local int i, j;
	local AServer srv;

	class'OpenLogger'.static.Info("parsing" @ List.Length @ "server lines", self);
	for (i=0; i<List.Length; i++)
	{
		numFields = class'OpenString'.static.Split(List[i], ",", fields);//fields is now a list of k=v
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
		ServerList[ServerList.length] = srv;
	}
	class'OpenLogger'.static.Info("loading" @ ServerList.Length @ "parsed servers", self);

	M.ClearServerList();//clears the widget's server list
	for (i=0; i<ServerList.Length; i++)
	{
		M.ServerListSuccess(ServerList[i].ServerName,ServerList[i].IP,ServerList[i].GameMode);
	}
	M.FinishedServers();//tells widget that the list is done, display them
}

//1.3
//moved function from widget to here
//handles loading backup list
function NoServerList()
{
	local int i;
	class'OpenLogger'.static.Info("loading backup file Servers.list", self);
	//bDONTQUERY = true;//0.8//commented out - we want to query backup list too
	LoadConfig("Servers.list");
	M.ClearServerList();//clears the widget's server list
	i = 0;
	while ( i < ServerList.length )
	{
		M.ServerListSuccess(ServerList[i].ServerName,ServerList[i].IP,ServerList[i].GameMode);
		i++;
	}
	M.FinishedServers();//tells widget that the list is done, display them
}