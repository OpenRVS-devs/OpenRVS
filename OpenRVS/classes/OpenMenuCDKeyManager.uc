// Installed client side through ClassMenuCDKeyManager in R6ClassDefines.ini.
class OpenMenuCDKeyManager extends R6MenuCDKeyManager;

// Retained across menu recreation on failed travel; never saved to disk.
var string JoinCompatibilityInfo;

function StartCDKeyProcess(optional R6WindowUbiCDKeyCheck.eJoinRoomChoice _eJoinUbiComRoom,
    optional ClientBeaconReceiver.PreJoinResponseInfo _preJResponseInfo)
{
    // A saved activation ID skips UP_ENTER_CD_KEY, which OpenCDKeyCheck
    // intercepts to bypass the retired Ubisoft validation service. Reset it
    // here for every pre-join entry point, including listen-server creation.
    m_pCDKeyCheckWindow.m_GameService.m_bValidActivationID = false;
    super.StartCDKeyProcess(_eJoinUbiComRoom, _preJResponseInfo);
}

// In 1.60 the CD-key manager owns the final browser/Join IP travel step.
function JoinServer(string _szIPAddress, optional string _szPassword)
{
    local OpenMultiPlayerWidget Browser;
    local R6MenuRootWindow MenuRoot;

    default.JoinCompatibilityInfo = "";
    MenuRoot = R6MenuRootWindow(Root);
    if ( MenuRoot != None )
        Browser = OpenMultiPlayerWidget(MenuRoot.m_MultiPlayerWidget);
    if ( Browser != None )
        default.JoinCompatibilityInfo = Browser.GetJoinCompatibilityInfo(_szIPAddress);

    Root.Console.ConsoleCommand("NETSPEED 100000");
    // NETSPEED can clamp CurrentNetSpeed to the existing connection's cap.
    // Seed both the live viewport and defaults for the connection about to open.
    class'Player'.default.ConfiguredInternetSpeed = 100000;
    class'Player'.default.ConfiguredLanSpeed = 100000;
    Root.Console.ViewportOwner.ConfiguredInternetSpeed = 100000;
    Root.Console.ViewportOwner.ConfiguredLanSpeed = 100000;
    Root.Console.ViewportOwner.CurrentNetSpeed = 100000;

    class'OpenLogger'.static.Info("Joining server with client netspeed " $
        Root.Console.ViewportOwner.CurrentNetSpeed, self);
    super.JoinServer(_szIPAddress, _szPassword);
}
