
new cvar_enabled;
new cvar_debug;
new cvar_killstolevel;
new cvar_autorespawn;
new cvar_health;
new cvar_armor;
new cvar_killsforspree;
new Float:cvar_movespeed;
new Float:cvar_spreemovespeed;

enum Sounds
{
    Welcome,
    Knife,
    Nade,
    Steal,
    Up,
    Down,
    Spree,
    AutoFF,
    MultiKill,
    Winner,
    WarmupTimerSound,
    MaxSounds
}

new String:EventSounds[Sounds:MaxSounds][64];

InitSounds()
{
    EventSounds[Welcome] = "weaponsmaster/welcome2.mp3";
    //"KnifeLevel" "gungame/knife_level.wav"
    //"NadeLevel" "gungame/nade_level.wav"
    //"LevelSteal" "gungame/smb3_1-up.wav"
    EventSounds[Up] = "weaponsmaster/smb3_powerup.wav";
    EventSounds[Down] = "weaponsmaster/smb3_powerdown.wav";
    EventSounds[Spree] = "weaponsmaster/smb_star.mp3";
    //"Autoff" "gungame/smb_warning2.mp3"
    //"MultiKill" "common/stuck1.wav"

    decl String:Hi[PLATFORM_MAX_PATH];
    for ( new Sounds:i = Welcome; i < MaxSounds; i++ )
    {
        if ( EventSounds[i][0] )
        {
            PrecacheSound(EventSounds[i]);
            Format(Hi, sizeof(Hi), "sound/%s", EventSounds[i]);
            AddFileToDownloadsTable(Hi);
        }
    }
}

InitCVARs()
{
    /*
	Cvars
    */
    CreateConVar("pvkii_wm_version", PL_VERSION, "Weapons Master for PVKII.", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_PLUGIN);
    
    new Handle:cv_enabled 	= CreateConVar("wm_enabled",		"1", "Enables/disables PVKII Weapons Master.", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);
    new Handle:cv_debug 	= CreateConVar("wm_debug",		"0", "Debug mode.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    new Handle:cv_killstolevel  = CreateConVar("wm_killstolevel",	"1", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);
    new Handle:cv_autorespawn   = CreateConVar("wm_autorespawn", 	"0", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 10.0);
    new Handle:cv_health        = CreateConVar("wm_health",		"100", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 1.0, false, 1.0);
    new Handle:cv_armor         = CreateConVar("wm_armor",		"100", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 1.0, false, 1.0);
    new Handle:cv_killsforspree = CreateConVar("wm_killsforspree",	"3", "Number of kills for a player to enter a killing spree. 0 to disable", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 10.0);
    new Handle:cv_movespeed     = CreateConVar("wm_movespeed",		"220.0", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 1.0, true, 300.0);
    new Handle:cv_spreemovespeed= CreateConVar("wm_spreemovespeed",	"100.0", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 1.0, true, 300.0);
    
    HookConVarChange(cv_enabled, 	cvHookEnabled);
    HookConVarChange(cv_debug,  	cvHookDebug);
    HookConVarChange(cv_killstolevel,  	cvHookKillsToLevel);
    HookConVarChange(cv_autorespawn,  	cvHookAutoRespawn);
    HookConVarChange(cv_health, 	cvHookHealth);
    HookConVarChange(cv_armor, 		cvHookArmor);
    HookConVarChange(cv_killsforspree, 	cvHookKillsForSpree);
    HookConVarChange(cv_movespeed, 	cvHookMoveSpeed);
    HookConVarChange(cv_spreemovespeed,	cvHookSpreeMoveSpeed);
    
    cvar_enabled 	= GetConVarBool(cv_enabled);
    cvar_debug 		= GetConVarBool(cv_debug);
    cvar_killstolevel	= GetConVarInt(cv_killstolevel);
    cvar_autorespawn	= GetConVarInt(cv_autorespawn);
    cvar_health 	= GetConVarInt(cv_health);
    cvar_armor  	= GetConVarInt(cv_armor);
    cvar_killsforspree	= GetConVarInt(cv_killsforspree);
    cvar_movespeed 	= GetConVarFloat(cv_movespeed);
    cvar_spreemovespeed	= GetConVarFloat(cv_spreemovespeed);
}

public cvHookEnabled(Handle:cvar, const String:oldVal[], const String:newVal[]) { 
    cvar_enabled = GetConVarBool(cvar);
    if (!cvar_enabled) {
	RemoveServerTag(SERVER_TAG);
    } else {
	AddServerTag(SERVER_TAG);
    }
}
public cvHookDebug(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_debug = GetConVarBool(cvar); }
public cvHookKillsToLevel(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_killstolevel = GetConVarInt(cvar); }
public cvHookAutoRespawn(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_autorespawn = GetConVarInt(cvar); }
public cvHookHealth(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_health = GetConVarInt(cvar); }
public cvHookArmor(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_armor = GetConVarInt(cvar); }
public cvHookKillsForSpree(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_killsforspree= GetConVarInt(cvar); }
public cvHookMoveSpeed(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_movespeed = GetConVarFloat(cvar); }
public cvHookSpreeMoveSpeed(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_spreemovespeed = GetConVarFloat(cvar); }
