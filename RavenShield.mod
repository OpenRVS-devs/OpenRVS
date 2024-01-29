[Engine.R6Mod]
Version=1
MinorVersion=60
BuildVersion=412
m_szKeyword=RavenShield
m_fPriority=1
m_szCampaignIniFile=RavenShieldCampaign
m_szServerIni=server
m_szUserIni=user
m_ConfigClass=Engine.R6ModConfig
m_bUseCustomOperatives=true

//Default pawn classes
m_DefaultLightPawn=R6Characters.R6RainbowLight
m_DefaultMediumPawn=R6Characters.R6RainbowMedium
m_DefaultHeavyPawn=R6Characters.R6RainbowHeavy
m_DefaultPilotPawn=R6Characters.R6RainbowPilot
m_DefaultRainbowAI=R6Engine.R6RainbowAI

m_PlayerCtrlToSpawn=R6Engine.R6PlayerController

// Background Root Directory
m_szBackgroundRootDir=Backgrounds

// Videos Root
m_szVideosRootDir=Videos

// Credits
m_szCreditsFile=R6Credits

//Menu class defines
m_szMenuDefinesFile=R6ClassDefines

//Reticule list
m_aReticuleList=(m_szReticuleId="WITHWEAPON",m_szReticuleClassName="R6Weapons.R6WithWeaponReticule")
m_aReticuleList=(m_szReticuleId="WITHWEAPONDOT",m_szReticuleClassName="R6Weapons.R6WithWeaponDotReticule")
m_aReticuleList=(m_szReticuleId="CROSS",m_szReticuleClassName="R6Weapons.R6CrossReticule")
m_aReticuleList=(m_szReticuleId="CIRCLE",m_szReticuleClassName="R6Weapons.R6CircleReticule")
m_aReticuleList=(m_szReticuleId="WRETICULE",m_szReticuleClassName="R6Weapons.R6WReticule")
m_aReticuleList=(m_szReticuleId="RIFLE",m_szReticuleClassName="R6Weapons.R6RifleReticule")
m_aReticuleList=(m_szReticuleId="SNIPER",m_szReticuleClassName="R6Weapons.R6SniperReticule")
m_aReticuleList=(m_szReticuleId="CIRCLEDOT",m_szReticuleClassName="R6Weapons.R6CircleDotReticule")
m_aReticuleList=(m_szReticuleId="CIRCLEDOTLINE",m_szReticuleClassName="R6Weapons.R6CircleDotLineReticule")
m_aReticuleList=(m_szReticuleId="DOT",m_szReticuleClassName="R6Weapons.R6DotReticule")
m_aReticuleList=(m_szReticuleId="GRENADE",m_szReticuleClassName="R6Weapons.R6GrenadeReticule")

// Localization files

//Extra Packages
m_aDescriptionPackage=R6Description

// Games Modes
m_szGameTypes="RGM_StoryMode"
m_szGameTypes="RGM_PracticeMode"
m_szGameTypes="RGM_MissionMode"
m_szGameTypes="RGM_TerroristHuntMode"
m_szGameTypes="RGM_TerroristHuntCoopMode"
m_szGameTypes="RGM_HostageRescueMode"
m_szGameTypes="RGM_HostageRescueCoopMode"
m_szGameTypes="RGM_HostageRescueAdvMode"
m_szGameTypes="RGM_DeathmatchMode"
m_szGameTypes="RGM_TeamDeathmatchMode"
m_szGameTypes="RGM_BombAdvMode"
m_szGameTypes="RGM_EscortAdvMode"
m_szGameTypes="RGM_LoneWolfMode"

[Engine.GameEngine]
CacheSizeMegs=32
UseSound=True
ServerActors=IpDrv.UdpBeacon
ServerPackages=GamePlay
ServerPackages=R6Abstract
ServerPackages=R6Engine
ServerPackages=R6Characters
ServerPackages=R6GameService
ServerPackages=R6Game
ServerPackages=R61stWeapons
ServerPackages=R6Weapons
ServerPackages=R6WeaponGadgets
ServerPackages=R63rdWeapons
