class OpenClientBeaconReceiver extends ClientBeaconReceiver transient;

//new in 0.8
//this class will handle receiving text from each server and parsing it to learn basic info about the server

var OpenMultiPlayerWidget Widget;

//call this function with the ip and server beacon port (regular port + 1000) of the server to get info from
function QuerySingleServer(OpenMultiPlayerWidget OMPW,coerce string sIP,coerce int sPort)
{
	local IpAddr Addr;
	if ( Widget == none )//get a reference to the widget to send info back to
		Widget = OMPW;
	StringToIpAddr(sIP,Addr);//turn the string to an IP
	Addr.Port = sPort;
	BroadcastBeacon(Addr);
}

//0.8
//receive text
//super it but also check if it's response to the "REPORT" broadcast
//if so, parse and send to OpenMultiPlayerWidget
event ReceivedText(IpAddr Addr,string Text)
{
	local int pos;			   // Position in the current string
	local string szSecondWord;	  // The second word in the message
	local string szThirdWord;	   // The third word in the message
	local string sNumP,sMaxP,sGMode,sMapName,sSvrName;
	//1.3
	local string sModName;
	super.ReceivedText(Addr,Text);
	if ( left(Text,len(BeaconProduct)+1) ~= (BeaconProduct$" ") )
	{
		// Decode the second word to determine the port number of the server
		szSecondWord = mid(Text,len(BeaconProduct)+1);
		Addr.Port = int(szSecondWord);
		// Check for the string KEYWORD
		szThirdWord = mid(szSecondWord,InStr(szSecondWord," ")+1);
		if ( left(szThirdWord,len(KeyWordMarker)+1) ~= ( KeyWordMarker$" " ) )
		{
			//if we got to this stage, it's a REPORT response
			//start szthirdword at the first symbol for GrabOption() to work
			szThirdWord = mid(szThirdWord,InStr(szThirdWord,"¶"));
			//debug:
			class'OpenLogger'.static.DebugLog(left(szThirdWord,20));
			//send the string to ParseOption() with it as first argument, key to look for the second
			//eg numplayers = ParseOption(szThirdWord,"keyfornumplayers");
			class'OpenLogger'.static.DebugLog("*"$mid(szThirdWord,30,50));//debug
			//need to overwrite GetKeyValue because it looks for "=" when we need to look for the space between the marker and the value
			//GrabOption also leaves a space at the end as well as strips the initial symbol
			//so need to put that symbol back on, and strip the space in GrabOption
			sNumP = ParseOption(szThirdWord,NumPlayersMarker);
			sMaxP = ParseOption(szThirdWord,MaxPlayersMarker);
			sGMode = ParseOption(szThirdWord,GameTypeMarker);
			sMapName = ParseOption(szThirdWord,MapNameMarker);
			sSvrName = ParseOption(szThirdWord,SvrNameMarker);
			//1.3
			sModName = ParseOption(szThirdWord,ModNameMarker);
			//1.3 - sModName string added to function in MP menu
			Widget.ReceiveServerInfo(IpAddrToString(Addr),sNumP,sMaxP,sGMode,sMapName,sSvrName,sModName);//send received info back to server list
			//debug:
			class'OpenLogger'.static.DebugLog("** Server " $ sSvrName $ " at " $ IpAddrToString(Addr) $ " is playing map " $ sMapName $ " in game mode type " $ sGMode $ ". Players: " $ sNumP $ "/" $ sMaxP);//debug
		}
	}
}

//overridden from parent
//need to strip out the final space from result
//also need to add the removed symbol back into result
function bool GrabOption(out string Options,out string Result)//¶I1 OBSOLETESUPERSTARS.COM ¶F1 RGM
{
	if ( Left(Options,1) == "¶" )
	{
		// Get result.
		Result = Mid(Options,1);
		if( InStr(Result,"¶") >= 0 )//I1 OBSOLETESUPERSTARS.COM ¶F1 RGM
			Result = Left(Result,InStr(Result,"¶")-1);//I1 OBSOLETESUPERSTARS.COM//0.8 strip the space
			//Result = Left(Result,InStr(Result,"¶"));//I1 OBSOLETESUPERSTARS.COM
		Result = "¶" $ Result;//0.8 add the symbol back in - ¶I1 OBSOLETESUPERSTARS.COM

		// Update options.
		Options = Mid(Options,1);//I1 OBSOLETESUPERSTARS.COM ¶F1 RGM
		if( InStr(Options,"¶") >= 0 )
			Options = Mid(Options,InStr(Options,"¶"));//¶F1 RGM
		else
			Options = "";
		//debug:
		class'OpenLogger'.static.DebugLog("** Got option pair " $ Result);
		return true;
	}
	else
	{
		//debug:
		class'OpenLogger'.static.DebugLog("* GRABOPTION FALSE");
		return false;
	}
}

//overridden from parent
//instead of looking for "=", need to look for first space
function GetKeyValue(string Pair,out string Key,out string Value)
{
	if ( InStr(Pair," ") >= 0 )
	{
		Key   = Left(Pair,InStr(Pair," "));
		Value = Mid(Pair,InStr(Pair," ")+1);
	}
	else
	{
		Key   = Pair;
		Value = "";
	}
	//debug:
	class'OpenLogger'.static.DebugLog("** key " $ Key $ " returns value " $ Value);
}