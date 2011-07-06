
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "0.1"
#define SERVER_TAG "wm"

public Plugin:myinfo = {
    name        = "Weapons Master",
    author      = "MadKat",
    description = "Players fight through the full gamut of weapons",
    version     = PL_VERSION,
    url         = "http://www.github.com/madkat"
}

// GiveNamedItem(string classname, int subtype)
new Handle:hGiveNamedItem;
// Weapon_Equip(CBaseCombatWeapon * weapon)
new Handle:hWeapon_Equip;
// GiveAmmo(int, str, bool)
new Handle:hGiveAmmo;
// RemoveAllItems(bool remove_suit)
new Handle:hRemoveAllItems;
// ForceRespawn(void)
new Handle:hForceRespawn;

#define W_USERID	0
#define W_LEVEL		1
#define W_KILLCOUNT	2
new client_info[MAXPLAYERS + 1][3];
new leader_level;
new String:leader_name[MAX_NAME_LENGTH];

new cvar_enabled;
new cvar_debug;
new cvar_killstolevel;
new cvar_autorespawn;
new cvar_health;
new cvar_armor;
new Float:cvar_movespeed;

#define W_MELEE 	0
#define W_RANGED 	1
#define W_SPECIAL 	2

#define W_TYPE 		0
#define W_SLOT 		1
#define W_SPCATK	2
#define W_AMMO_QTY	3

#define W_MAX_LEVEL	18

#define W_STRING_LEN    20
static const String:weapon_names[19][W_STRING_LEN] = {
    "archersword",
    "axesword",
    "bigaxe",
    "cutlass",
    "cutlass2",
    "seaxshield",
    "spear",
    "swordshield",
    "twoaxe",
    "twosword",
    "vikingshield",
    "blunderbuss",
    "flintlock",
    "crossbow",
    "longbow",
    "javelin",
    "throwaxe",
    "powderkeg",
    "parrot"
};

static const weapon_properties[19][5] = {
    { W_MELEE	, 1 , 0 , -1 },
    { W_MELEE	, 2 , 1 , -1 },
    { W_MELEE	, 1 , 1 , -1 },
    { W_MELEE	, 1 , 1 , -1 },
    { W_MELEE	, 1 , 0 , -1 },
    { W_MELEE	, 2 , 0 , -1 },
    { W_MELEE	, 1 , 1 , -1 },
    { W_MELEE	, 2 , 0 , -1 },
    { W_MELEE	, 1 , 0 , -1 },
    { W_MELEE	, 1 , 1 , -1 },
    { W_MELEE	, 2 , 1 , -1 },
    { W_RANGED	, 2 , 1 , 10 },
    { W_RANGED	, 2 , 0 , 12 },
    { W_RANGED	, 2 , 0 , 15 },
    { W_RANGED	, 3 , 1 , 30 },
    { W_RANGED	, 3 , 0 , 3  },
    { W_RANGED	, 3 , 0 , 8  },
    { W_SPECIAL	, 3 , 0 , -1  },
    { W_SPECIAL	, 3 , 0 , 1  }
};

new h_iMaxHealth;
new h_iHealth;
new h_iMaxArmor;
new h_ArmorValue;
new h_flDefaultSpeed;
new h_flMaxspeed;

public OnPluginStart() {
    /*
	SDK
    */

    new Handle:conf = LoadGameConfigFile("weaponsmaster.cfg");
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GiveNamedItem");
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
    hGiveNamedItem = EndPrepSDKCall();
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "Weapon_Equip");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    hWeapon_Equip = EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GiveAmmo");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    hGiveAmmo = EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "RemoveAllItems");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    hRemoveAllItems = EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "ForceRespawn");
    hForceRespawn = EndPrepSDKCall();
    
    CloseHandle(conf);

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
    new Handle:cv_movespeed     = CreateConVar("wm_movespeed",		"220.0", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 1.0, true, 255.0);
    
    HookConVarChange(cv_enabled, 	cvHookEnabled);
    HookConVarChange(cv_debug,  	cvHookDebug);
    HookConVarChange(cv_killstolevel,  	cvHookKillsToLevel);
    HookConVarChange(cv_autorespawn,  	cvHookAutoRespawn);
    HookConVarChange(cv_health, 	cvHookHealth);
    HookConVarChange(cv_armor, 		cvHookArmor);
    HookConVarChange(cv_movespeed, 	cvHookMoveSpeed);
    
    cvar_enabled 	= GetConVarBool(cv_enabled);
    cvar_debug 		= GetConVarBool(cv_debug);
    cvar_killstolevel	= GetConVarInt(cv_killstolevel);
    cvar_autorespawn	= GetConVarInt(cv_autorespawn);
    cvar_health 	= GetConVarInt(cv_health);
    cvar_armor  	= GetConVarInt(cv_armor);
    cvar_movespeed 	= GetConVarFloat(cv_movespeed);
    
    /*
	Event Hooks
    */
    HookEvent("player_spawn", player_spawn);
    HookEvent("player_death", player_death);
    HookEvent("player_changeteam", player_changeteam);
    HookEvent("player_changeclass", player_changeclass);
    HookEvent("round_end", round_end);
    HookEvent("gamemode_roundrestart", gamemode_roundrestart);
    
    RegAdminCmd("wm_levelplayer", Command_LevelPlayer, ADMFLAG_SLAY);
    RegAdminCmd("wm_levelallplayers", Command_LevelAllPlayers, ADMFLAG_SLAY);

    AddServerTag(SERVER_TAG);

    h_iMaxHealth	= FindSendPropInfo("CPVK2Player", "m_iMaxHealth");
    h_iHealth	   	= FindSendPropInfo("CPVK2Player", "m_iHealth");
    h_iMaxArmor		= FindSendPropInfo("CPVK2Player", "m_iMaxArmor");
    h_ArmorValue	= FindSendPropInfo("CPVK2Player", "m_ArmorValue");
    h_flMaxspeed	= FindSendPropInfo("CPVK2Player", "m_flMaxspeed");
    h_flDefaultSpeed	= FindSendPropInfo("CPVK2Player", "m_flDefaultSpeed");
}

public Action:Command_LevelPlayer(client, args) {
    LevelUp(client, weapon_names[client_info[client][W_LEVEL]]);
    return Plugin_Handled;
}

public Action:Command_LevelAllPlayers(client, args) {
    for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) GiveWeapons(client);
    return Plugin_Handled;
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
public cvHookMoveSpeed(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_movespeed = GetConVarFloat(cvar); }

public OnClientPutInServer(client) {
    if (cvar_enabled) {
	// Welcome message?
	client_info[client][W_LEVEL] = 0;
	client_info[client][W_KILLCOUNT] = 0;
    }
}

/**
 * RemoveWeapons wraps the SDKCall for RemoveAllItems(). It
 * verifies that the player is alive and able to have this occur
 * without causing a server error.
 */
public RemoveWeapons(client)
{
    if (!IsPlayerAlive(client)) {
	return;
    }

    SDKCall(hRemoveAllItems, client, false);
}

public GiveWeapons(client)
{
    if (!IsPlayerAlive(client)) {
	return;
    }

    new weapon_id;
    new weapon_object;
    decl String:primary_name[W_STRING_LEN];
    decl String:secondary_name[W_STRING_LEN];

    weapon_id = client_info[client][W_LEVEL];
    Format(primary_name, W_STRING_LEN, "weapon_%s", weapon_names[weapon_id]);

    weapon_object = SDKCall(hGiveNamedItem, client, primary_name, 0);
    if (weapon_object == -1) {
	// Client probably already had it
    }
    else {
	if (weapon_properties[weapon_id][W_AMMO_QTY] > -1) {
	    new ammo_type = GetEntProp(weapon_object, Prop_Data, "m_iPrimaryAmmoType", 4);
	    SDKCall(hGiveAmmo, client, weapon_properties[weapon_id][W_AMMO_QTY], ammo_type, true);
	}
	SDKCall(hWeapon_Equip, client, weapon_object);
    }

    // If using a ranged weapon that's not a parrot or longbow
    if (weapon_id > 10 && weapon_id < 18 && weapon_id != 14) {
	// Give an archer sword
	Format(secondary_name, W_STRING_LEN, "weapon_%s", weapon_names[0]);
	weapon_object = SDKCall(hGiveNamedItem, client, secondary_name, 0);
	if (weapon_object == -1) {
	    // Client probably already had it
	}
	SDKCall(hWeapon_Equip, client, weapon_object);
    }
}

public OnSuicide(client) {
    // Suicide results in level loss
    if (client_info[client][W_LEVEL] > 0) {
	client_info[client][W_LEVEL]--;
    }
}

public OnVictory(client) {
    decl String:name[MAX_NAME_LENGTH + 1];
    GetClientName(client, name, MAX_NAME_LENGTH);
    PrintCenterTextAll("%s has won!", name);

    decl String:nextmap[51];
    GetNextMap(nextmap, 50);
    ForceChangeLevel(nextmap, "Player won Weapons Master");
}

public PrintLevelInfo(client) {
    new level = client_info[client][W_LEVEL] + 1;

    if (level >= leader_level) {
	new ties = 0;
	for (new i = 1; i <= MaxClients; i++) {
	    if ((client_info[i][W_LEVEL] == leader_level)
		&& (i != client))
	    {
		ties++;
	    }
	}
	if (ties == 0) {
	    PrintToChat(client, "You are leading on level %d.", level);
	}
	else if (ties == 1) {
	    PrintToChat(client, "You tied with the other leader on level %d.", level);
	}
	else {
	    PrintToChat(client, "You tied with the other leaders on level %d.", level);
	}
    }
    else {
	new trail = leader_level - level - 1;
	PrintToChat(client, "You are currently on level %d.", level);
	PrintToChat(client, "You are trailing the leader by %d.", trail);
    }
    
}

public CheckLeaderboard(client) {
    new level = client_info[client][W_LEVEL] + 1;
    decl String:name[MAX_NAME_LENGTH];
    GetClientName(client, name, MAX_NAME_LENGTH);
    // Leader info
    if (level > leader_level) {
	leader_name = name;
	leader_level = level;
	PrintToChatAll("%s is now leading on level %d.", name, level);
    }
    else if (level == leader_level) {
	PrintToChatAll("%s is now tied with the other leaders on level %d.", name, level);
    }
}

public LevelUp(client, String:weapon[W_STRING_LEN]) {
    if (cvar_debug) { PrintToServer("WM Entering LevelUp."); }
    new give_ammo = false;
    new level_up = false;
    if (cvar_debug) { PrintToServer("WM Kill with weapon %s", weapon); }

    if (weapon[0] == weapon_names[client_info[client][W_LEVEL]][0]) {
	client_info[client][W_KILLCOUNT]++;
	if (cvar_debug) { PrintToServer("WM Kill count increased."); }
    }
    else {
	give_ammo = true;
	if (cvar_debug) { PrintToServer("WM Ammo."); }
    }

    if (client_info[client][W_KILLCOUNT] >= cvar_killstolevel) {
	if (cvar_debug) { PrintToServer("WM Level up met."); }
	level_up = true;
	client_info[client][W_LEVEL]++;
	client_info[client][W_KILLCOUNT] = 0;
	if (client_info[client][W_LEVEL] > W_MAX_LEVEL) {
	    if (cvar_debug) { PrintToServer("WM Victory met."); }
	    OnVictory(client);
	    return;
	}
	else {
	    if (cvar_debug) { PrintToServer("WM Check Leaderboard."); }
	    CheckLeaderboard(client);
	}
    }

    if (level_up || give_ammo) {
	if (cvar_debug) { PrintToServer("WM RemoveWeapons."); }
	RemoveWeapons(client);
	if (cvar_debug) { PrintToServer("WM GiveWeapons."); }
	GiveWeapons(client);
    }
}

public OnMapStart() {
    for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) OnClientPutInServer(i);
    leader_level = 1;
    leader_name = "";
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client || !IsPlayerAlive(client) || !IsClientInGame(client) || !cvar_enabled)
	return;

    SetEntData(client, h_iMaxHealth,	cvar_health, 4, true);
    SetEntData(client, h_iHealth,	cvar_health, 4, true);
    SetEntData(client, h_iMaxArmor,	cvar_armor, 4, true);
    SetEntData(client, h_ArmorValue,	cvar_armor, 4, true);
    SetEntDataFloat(client, h_flMaxspeed,	cvar_movespeed, true);
    SetEntDataFloat(client, h_flDefaultSpeed,	cvar_movespeed, true);
    RemoveWeapons(client);
    GiveWeapons(client);
    PrintLevelInfo(client);
}

public player_changeteam(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client) return;
}
public player_changeclass(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client) return;
}
public player_death(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    //new assistid = GetClientOfUserId(GetEventInt(event, "assistid"));
    decl String:weapon[W_STRING_LEN]; GetEventString(event, "weapon", weapon, W_STRING_LEN);
    
    if (client == attacker) {
	OnSuicide(client);
    }
    else {
	LevelUp(attacker, weapon);
    }

    if (cvar_autorespawn > 0) {
	SDKCall(hForceRespawn, client);
    }
}
public round_end(Handle:event, const String:name[], bool:dontBroadcast) {
    
}
public gamemode_roundrestart(Handle:event, const String:name[], bool:dontBroadcast) {
    
}

/*
    Client joins game
        Set killcount to 0
        Set client level to 0
        (if match_low, set to lowest other client level)
 
    Player kills a player
        If weapon == weapon level
	    Increment killcount
        If killcount >= killstolevel
            Increment level
            Remove weapon
            Assign new weapon
            Assign ammo
            Reset killcount
 
    Player kills self
        Decrement level
        Remove weapon
        Assign new weapon
        Assign ammo
	Reset killcount
 
*/
