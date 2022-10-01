class OpenRVS extends Object;

const OPENRVS_VERSION = "v1.5";
// This URL returns the latest release version from GitHub over HTTP.
const LATEST_VERSION_URL = "http://openrvs.org/latest";

var OpenHTTPClient httpc;

// Init contains the first OpenRVS code which runs. It has a different call
// location for clients and servers. Clients call Init from
// OpenCustomMissionWidget, while servers call Init from OpenServer.
function Init(Actor a)
{
	class'OpenLogger'.static.LogStartupMessage();

	// Fire off version-checking request.
	httpc = a.Spawn(class'OpenHTTPClient');
	httpc.CallbackName = "version_check";
	httpc.VersionCheckCallbackProvider = self;
	httpc.SendRequest(LATEST_VERSION_URL);
}

function CheckVersion(OpenHTTPClient.HttpResponse resp)
{
	local string latest;
	local string warning;
	local OpenPopUpWindow WarningWindow;

	if (resp.Code != 200)
	{
		class'OpenLogger'.static.Error("failed to retrieve latest version over http", self);
		return;
	}

	// Trim the line break.
	latest = resp.Body;
//	latest = Left(latest, Len(latest)-1);//WHAT IS THIS? No line break, just trims the 4 out of "v1.4"

	// Log version information to file.
	// TODO: Also display a popup.
	if (OPENRVS_VERSION != latest)
	{
		warning = "Your copy of the OpenRVS patch is outdated. Your version:" @ OPENRVS_VERSION $ ", latest version:" @ latest;
		class'OpenLogger'.static.Warning(warning, self);
		//v1.5 - add pop up box notification to main menu
		WarningWindow = class'OpenPopUp'.static.CreatePopUp("OpenRVS Patch Check");
		WarningWindow.AddText("Please note:");
		WarningWindow.AddText(warning);
		WarningWindow.AddText("Click the link below to download the latest update.");
		WarningWindow.AddText("");
		WarningWindow.MakeURLButton("https://www.moddb.com/search?q=openrvs","Download from ModDB");
	}
	else
		class'OpenLogger'.static.Info("OpenRVS is up to date (" $ latest $ ")", self);
}
