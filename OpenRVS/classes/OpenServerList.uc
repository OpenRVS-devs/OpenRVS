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

var OpenMultiPlayerWidget M;
var string WebAddress;
var string FileName;
var array<string> buffer;
//1.3 added here
struct AServer
{
	var string ServerName;
	var string IP;
	var bool Locked;
	var string GameMode;
};
var config array<AServer> ServerList;

//start up
//receives a URL from multiplayer widget
//if no URL, connects with the default server list at rvsgaming.org
function Init(OpenMultiPlayerWidget Widget,optional string W,optional string F)
{
//	log(" **** TESTING **** STARTING UP");
	M = Widget;
	if ( W != "" )
		WebAddress = W;
	else
		WebAddress = "gsconnect.rvsgaming.org";
	if ( F != "" )
		FileName = F;
	else
		FileName = "servers-updated.list";
	BindPort();
//	LinkMode = MODE_Line;//orig
	LinkMode = MODE_Text;//different mode - receive file as chunks of text
	ReceiveMode = RMODE_Event;
	Resolve(WebAddress);
}

//when received a connection with server list host
event Resolved(IpAddr Addr)
{
//	log(" **** TESTING **** RESOLVED");
	super.Resolved(Addr);
	Addr.Port = 80;
	Open(Addr);
}

event ResolveFailed()
{
//	log(" **** TESTING **** RESOLVE FAILED");
//	M.NoServerList();//1.2
	//1.3 noserverlist moved here
	NoServerList();
	super.ResolveFailed();
	Destroy();
}

event Opened()
{
	super.Opened();
//	log(" **** TESTING **** OPENED");
	SendText("GET /" $ FileName $ " HTTP/1.0" $ Chr(13) $ Chr(10) $ "Host: " $ WebAddress $ Chr(13) $ Chr(10) $ Chr(13) $ Chr(10));
}

//add each received line to a dynamic array of strings to parse later
event ReceivedText(string Text)
{
	super.ReceivedText(Text);
	buffer[buffer.length] = Text;
//	log(" **** TESTING **** RECEIVED: " $ Text);//will crash if too large
//	log(" **** TESTING **** END RECEIVED");
}

//when connection is finished, check the length of each received line.
//lines too large will crash/cause other issues
//so split lines into manageable size
//then parse them to find server info and send back to the multiplayer menu.
//strips out extra info on the ends of the string and returns a server string in this format:
//a server name",IP="44.434.4.434:7777",Locked=false,GameMode="Adver
//the function in OpenMultiPlayerWidget will parse this further to get the needed info.
//1.3 - NO LONGER parsed in OpenMultiPlayerWidget, parsed below
event Closed()
{
	local int i;//index for counting received strings
	local int j,k;
	local array<string> list;//array to send to widget
	local string s;//currently working with
	local string l;//the LAST complete server info we found
//	log(" **** TESTING **** CLOSED");
	super.Closed();
//	log(" **** TESTING **** lines received: " $ buffer.length);
	//THE FOLLOWING:
	//takes any data received from the web address
	//and splits it into chunks smaller than or equal to 85 characters.
	//these chunks are easily manageable and can be manipulated and parsed easily.
	//when strings are too large it can cause issues or crash the game
	//so to work with the received data we break it apart.
	//85 chosen because you can add up to 3 strings of that size together and will still be less than 256 chars.
	//don't know if this actually matters lol
	i = 0;
	while ( i < buffer.length )
	{
//		log(" **** TESTING **** line " $ i+1 $ " length: " $ len(buffer[i]));
		while ( len(buffer[i]) > 85 )
		{
//			log(" **** TESTING **** moving 85 characters to next array element");
			buffer.insert(i+1,1);
			buffer[i+1] = right(buffer[i],85);
			ReplaceText(buffer[i],buffer[i+1],"");//get rid of the text we moved to next array element
		}
//		log(" **** TESTING **** line " $ i $ ": " $ buffer[i]);
		i++;
	}
	//get rid of extraneous received data before the serverlist
	//NOTE: shouldn't be an issue but assumes that there's at least two entries in buffer array
	s = buffer[0] $ buffer[1];
	while ( InStr(s,"ServerName=") == -1 )
	{
//		log(" **** TESTING **** removing unneeded line: " $ buffer[0]);
		buffer.Remove(0,1);
		if ( buffer.length > 1 )
			s = buffer[0] $ buffer[1];
		else
		{
			log("	 ---- OpenRVS ----");
			log("	 ERROR: NO SERVER LIST FOUND IN FILE " $ WebAddress $ "/" $ FileName);
//			M.NoServerList();//1.2
			//1.3 noserverlist moved here
			NoServerList();
			return;
		}
	}
	//create an array of strings, each containing one server info
	i = 0;
	while ( i < buffer.length )
	{
//		log(" **** TESTING **** current buffer: " $ buffer[i]);
		//fill our temp string with up to 3 buffer strings
		k = 0;//how many buffer strings ahead to count
		s = "";//temp string init
		while ( buffer.length > i + k )
		{
			if ( k > 2 )
				break;
			s = s $ buffer[i+k];
//			log(" **** TESTING **** current k: " $ k $ ", current temp string: " $ s);
			k++;
		}
//		log(" **** TESTING **** FINAL current temp string: " $ s);
		//find the server name, eliminate any text before it
		j = InStr(s,"ServerName=");
		if ( j == -1 )//could not find another entry
		{
//			log(" **** TESTING **** DONE PARSING");
			//PARSING DONE!
			if ( List.length > 0 )
			{
				log("	 ---- OpenRVS ----");
				log("	 Loading server list at " $ WebAddress $ "/" $ FileName);
//				M.ServerListSuccess(List);//1.2
				//1.3 parsing moved here
				ServerListSuccess(List);
			}
			else
//				M.NoServerList();//1.2
				//1.3 noserverlist moved here
				NoServerList();
			return;
		}
		s = Mid(s,j+12);//truncate to start string at server name
		//if there's no closing parenthesis, add on the next buffer - note: assumes there IS a next buffer - should always be unless list formatted wrong
		j = InStr(s,")");
		while ( j == -1 )
		{
			s = s $ buffer[i+k];
			k++;
			j = InStr(s,")");
		}
		s = Mid(s,0,j-1);
		//double check in case server found is same as last server added
		//can happen because of way we add strings together
		if ( s != l )
		{
			l = s;//last server added update
			List[List.length] = s;//add server to list to send
//			log(" **** TESTING **** SERVER FOUND: " $ s);
		}
		i++;
	}
//	log(" **** TESTING **** DONE PARSING");
	//PARSING DONE!
	if ( List.length > 0 )
	{
		log("	 ---- OpenRVS ----");
		log("	 Loading server list at " $ WebAddress $ "/" $ FileName);
//		M.ServerListSuccess(List);//1.2
		//1.3 parsing moved here
		ServerListSuccess(List);
	}
	else
//		M.NoServerList();//1.2
		//1.3 noserverlist moved here
		NoServerList();
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
	local int i,j;
	local AServer Temp;
	i = 0;
	while ( i < List.length )
	{
		//get server name
		j = InStr(List[i],",");
		Temp.ServerName = Mid(List[i],0,j-1);
		List[i] = Mid(List[i],j+5);//get rid of server name and ,IP="
		//get server IP
		j = InStr(List[i],",");
		Temp.IP = Mid(List[i],0,j-1);
		List[i] = Mid(List[i],j+8);//get rid of IP and ,Locked=
		//get locked
		j = InStr(List[i],",");
		Temp.Locked = bool(Mid(List[i],0,j-1));
		List[i] = Mid(List[i],j+11);//get rid of locked and ,GameMode="
		//get coop
		Temp.GameMode = List[i];
		ServerList[ServerList.length] = Temp;
		i++;
	}
	M.ClearServerList();//clears the widget's server list
	i = 0;
	while ( i < ServerList.length )
	{
		M.ServerListSuccess(ServerList[i].ServerName,ServerList[i].IP,ServerList[i].Locked,ServerList[i].GameMode);
		i++;
	}
	M.FinishedServers();//tells widget that the list is done, display them
}

//1.3
//moved function from widget to here
//handles loading backup list
function NoServerList()
{
	local int i;
	log("	 ---- OpenRVS ----");
	log("		Loading backup file Servers.list ...");
//	bDONTQUERY = true;//0.8//commented out - we want to query backup list too
	LoadConfig("Servers.list");
	M.ClearServerList();//clears the widget's server list
	i = 0;
	while ( i < ServerList.length )
	{
		M.ServerListSuccess(ServerList[i].ServerName,ServerList[i].IP,ServerList[i].Locked,ServerList[i].GameMode);
		i++;
	}
	M.FinishedServers();//tells widget that the list is done, display them
}