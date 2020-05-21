//class to replace UdpBeacon in serveractors list
//should allow respondprejoinquery() regardless of server registration state
//this fixes issues in non-n4 admin servers
//IMPORTANT: Servers with N4 Admin should not install this class
//debug - should log any time an initial connection with client opens
//installed server side

class OpenBeacon extends UdpBeacon transient;

event ReceivedText(IpAddr Addr,string Text)
{
	local R6ServerInfo pServerOptions;
	local BOOL bServerResistered;
	pServerOptions = class'Actor'.static.GetServerOptions();
	class'OpenLogger'.static.DebugLog(" **** TESTING **** RECEVED TEXT " $ Text);
	if( Text == "REPORT" )
		BroadcastBeacon(Addr);
	if( Text == "REPORTQUERY" )
		BroadcastBeaconQuery(Addr);
	if ( Text == "PREJOIN" )
		RespondPreJoinQuery(Addr);
}