
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "0.1"
#define SERVER_TAG "wm"

#include "wm_config.sp"
#include "wm_weapondata.sp"

public Plugin:myinfo = {
    name        = "Weapons Master",
    author      = "MadKat",
    description = "Players fight through the full gamut of weapons for total victory.",
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

#define C_USERID	0
#define C_LEVEL		1
#define C_KILLCOUNT	2
#define C_SPREECOUNT	3
#define C_FIRSTJOIN     4
new client_info[MAXPLAYERS + 1][5];
new leader_level;
new String:leader_name[MAX_NAME_LENGTH];

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

    InitCVARs();
    InitSounds();
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
    LevelUp(client, weapon_names[client_info[client][C_LEVEL]]);
    return Plugin_Handled;
}

public Action:Command_LevelAllPlayers(client, args) {
    for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) GiveWeapons(client);
    return Plugin_Handled;
}

public OnClientPutInServer(client) {
    if (cvar_enabled) {
	// Welcome message?
	client_info[client][C_LEVEL] = 0;
	client_info[client][C_KILLCOUNT] = 0;
        client_info[client][C_SPREECOUNT] = 0;
        client_info[client][C_FIRSTJOIN] = 1;
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

    weapon_id = client_info[client][C_LEVEL];
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

public OnMapEnd() {
    for ( new Sounds:i = Welcome; i < MaxSounds; i++ )
    {
        EventSounds[i][0] = '\0';
    }
}

public OnSuicide(client) {
    // Suicide results in level loss
    if (client_info[client][C_LEVEL] > 0) {
	client_info[client][C_LEVEL]--;
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
    new level = client_info[client][C_LEVEL] + 1;

    if (level >= leader_level) {
	new ties = 0;
	for (new i = 1; i <= MaxClients; i++) {
	    if ((client_info[i][C_LEVEL] == leader_level)
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
    new level = client_info[client][C_LEVEL] + 1;
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

    if (weapon[0] == weapon_names[client_info[client][C_LEVEL]][0]) {
	client_info[client][C_KILLCOUNT]++;
        client_info[client][C_SPREECOUNT]++;
	if (cvar_debug) { PrintToServer("WM Kill count increased."); }
    }
    else {
	give_ammo = true;
	if (cvar_debug) { PrintToServer("WM Ammo."); }
    }

    if (client_info[client][C_KILLCOUNT] >= cvar_killstolevel) {
	if (cvar_debug) { PrintToServer("WM Level up met."); }
	level_up = true;
	client_info[client][C_LEVEL]++;
	client_info[client][C_KILLCOUNT] = 0;
	if (client_info[client][C_LEVEL] > W_MAX_LEVEL) {
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

    if (client_info[client][C_SPREECOUNT] >= cvar_killsforspree) {
        client_info[client][C_SPREECOUNT] = 0;
        if (cvar_killsforspree > 0) {
            // Grant killing spree bonus
        }
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

    if ( !IsFakeClient(client) ) {
        if (client_info[client][C_FIRSTJOIN]) {
            client_info[client][C_FIRSTJOIN] = 0;
            UTIL_PlaySound(client, Welcome);
        }
    }

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

UTIL_PlaySound(client, Sounds:type)
{
    if (!EventSounds[type][0])
    {
        return;
    }
    if (client && !IsClientInGame(client))
    {
        return;
    }
    if (!client) {
        EmitSoundToAll(EventSounds[type]);
    } else {
        EmitSoundToClient(client, EventSounds[type]);
    }
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
