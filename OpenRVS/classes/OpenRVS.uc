class OpenRVS extends Object;

const OPENRVS_VERSION = "v1.5";
// This URL returns the latest release version from GitHub over HTTP.
const LATEST_VERSION_URL = "http://64.225.54.237/latest";

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

	if (resp.Code != 200)
	{
		class'OpenLogger'.static.Error("failed to retrieve latest version over http", self);
		return;
	}

	// Trim the line break.
	latest = resp.Body;
	latest = Left(latest, Len(latest)-1);

	// Log version information to file.
	// TODO: Also display a popup.
	if (OPENRVS_VERSION != latest)
		class'OpenLogger'.static.Warning("OpenRVS is outdated. Your version:" @ OPENRVS_VERSION $ ", latest version:" @ latest, self);
	else
		class'OpenLogger'.static.Info("OpenRVS is up to date (" $ latest $ ")", self);
}