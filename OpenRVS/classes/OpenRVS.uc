class OpenRVS extends Actor;

const OPENRVS_VERSION = "v1.5";
const LATEST_VERSION_URL = "http://64.225.54.237/latest-version.txt";

var OpenHTTPClient httpc;

function Init()
{
	class'OpenLogger'.static.LogStartupMessage();

	// Fire off version-checking request.
	httpc = Spawn(class'OpenHTTPClient');
	httpc.CallbackName = "version_check";
	httpc.VersionCheckCallbackProvider = self;
	httpc.SendRequest(LATEST_VERSION_URL);
}

function CheckVersion(OpenHTTPClient.HttpResponse resp)
{
	local string latest;

	// Trim the line break.
	latest = resp.Body;
	latest = Left(latest, Len(latest)-1);

	// Log the version mismatch to file.
	// TODO: Also display a popup.
	if (OPENRVS_VERSION != latest)
		class'OpenLogger'.static.Warning("OpenRVS is outdated. Your version:" @ OPENRVS_VERSION $ ", latest version:" @ latest, self);
	else
		class'OpenLogger'.static.Info("OpenRVS is up to date (" $ latest $ ")", self);
}