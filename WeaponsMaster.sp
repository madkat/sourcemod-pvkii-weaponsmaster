
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "include/colors.sp"

#include "weaponsmaster.h"
#include "wm_config.h"
#include "wm_sdk.h"

#include "wm_config.sp"
#include "wm_logic.sp"
#include "wm_sdk.sp"

public Plugin:myinfo = {
    name        = "Weapons Master",
    author      = "MadKat",
    description = "Players fight through the full gamut of weapons for total victory.",
    version     = PL_VERSION,
    url         = "http://www.github.com/madkat"
}

public OnPluginStart() {

    InitSDKCalls();
    InitCVARs();
    InitSounds();
    
    /*
	Event Hooks
    */
    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("player_changeteam", OnPlayerChangeTeam);
    HookEvent("player_changeclass", OnPlayerChangeClass);
    HookEvent("player_special", OnPlayerSpecial);

    HookEvent("round_end",			OnBlanketDisabledEvent, EventHookMode_Pre);
    HookEvent("gamemode_roundrestart",		OnBlanketDisabledEvent, EventHookMode_Pre);
    HookEvent("gamemode_territory_capture",	OnBlanketDisabledEvent, EventHookMode_Pre);
    HookEvent("gamemode_territory_guard",	OnBlanketDisabledEvent, EventHookMode_Pre);
    HookEvent("gamemode_territory_contested",	OnBlanketDisabledEvent, EventHookMode_Pre);
    HookEvent("game_end", 			OnBlanketDisabledEvent, EventHookMode_Pre);
    HookEvent("grail_pickup", 			OnBlanketDisabledEvent, EventHookMode_Pre);
    HookEvent("chest_respawn", 			OnBlanketDisabledEvent, EventHookMode_Pre);
    HookEvent("chest_pickup", 			OnBlanketDisabledEvent, EventHookMode_Pre);

    HookEvent("gamemode_firstround_wait_begin",	OnGameModeFirstRoundBegin, EventHookMode_Pre);
    HookEvent("gamemode_firstround_wait_end",	OnGameModeFirstRoundEnd, EventHookMode_Pre);

    HookEvent("gamemode_suddendeath_begin",	OnUnhandledEvent, EventHookMode_Pre);
    
    RegAdminCmd("wm_levelplayer", AdminCommand_LevelPlayer, ADMFLAG_SLAY);
    RegAdminCmd("wm_levelallplayers", AdminCommand_LevelAllPlayers, ADMFLAG_SLAY);
    RegAdminCmd("wm_testsound", AdminCommand_TestSound, ADMFLAG_SLAY);
    RegAdminCmd("wm_testspree", AdminCommand_TestSpree, ADMFLAG_SLAY);

    AddServerTag(SERVER_TAG);
}

Debug(String:message[1024])
{
    if (cvar_debug) {
        PrintToServer(message);
    }
}

public Action:OnBlanketDisabledEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    //Debug("Eating a %s event", name);
    return Plugin_Handled;
}

public Action:OnGameModeFirstRoundBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
    LaunchWarmupTimer();
    Debug("FirstRoundBegins");
    WarmupInProgress = true;
    return Plugin_Continue;
}

public Action:OnGameModeFirstRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    Debug("FirstRoundEnds");
    if (WarmupRemaining > 0) {
        WarmupRemaining = 0;
    }
    WarmupInProgress = false;
    return Plugin_Continue;
}

public Action:OnUnhandledEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    return Plugin_Continue;
}

public Action:AdminCommand_LevelPlayer(client, args) {
    TryLevelUp(client, 0, WeaponNames[ClientPlayerLevel[client]]);
    return Plugin_Handled;
}

public Action:AdminCommand_TestSound(client, args) {
    PlaySound(client, Welcome);
    return Plugin_Handled;
}

public Action:AdminCommand_TestSpree(client, args) {
    HandleKillingSpree(client);
    return Plugin_Handled;
}

public Action:AdminCommand_LevelAllPlayers(client, args) {
    for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) GiveWeapons(client);
    return Plugin_Handled;
}

public OnClientPutInServer(client) {
    if (cvar_enabled) {
	// Welcome message?
	ClientUserID[client] = 0;
	ClientPlayerLevel[client] = 0;
	ClientKillCounter[client] = 0;
	ClientSpreeCounter[client] = 0;
	ClientSpreeEffects[client] = 0;
        ClientPlayerDead[client] = 1;
	ClientFirstJoin[client] = 1;
        ClientPlayerSpecial[client] = 0;

	SetEntData(client, h_iMaxHealth,	-1, 4, true);
	SetEntData(client, h_iHealth,		-1, 4, true);
	SetEntData(client, h_iMaxArmor,		-1, 4, true);
	SetEntData(client, h_iArmorValue,	-1, 4, true);
	SetEntDataFloat(client, h_flMaxspeed,	  -1.0, true);
	SetEntDataFloat(client, h_flDefaultSpeed, -1.0, true);
    }
}

public OnMapStart() {
    for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) OnClientPutInServer(i);
    LeaderLevel = 0;
    LeaderName = "";
    GameWon = false;

    if (EventSounds[Welcome][0] == '\0') {
        InitSounds();
    }
}

public OnMapEnd() {
    for ( new Sounds:i = Welcome; i < MaxSounds; i++ )
    {
        EventSounds[i][0] = '\0';
    }
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client || !IsPlayerAlive(client) || !IsClientInGame(client) || !cvar_enabled)
	return;

    if (!ClientFirstJoin[client] || !ClientPlayerDead[client]) {
        if (!IsFakeClient(client)) {
            PrintLevelInfo(client);
        }
    }
    else {
        ClientPlayerDead[client] = 0;
    }

    new current_class = GetEntData(client, h_iPlayerClass);
    if (current_class >= 0) {
        if (!IsFakeClient(client)) {
            if (ClientFirstJoin[client]) {
                ClientFirstJoin[client] = 0;
                PlaySound(client, Welcome);
            }
        }
    }

    /*
    new current_health = GetEntData(client, h_iHealth);
    if (current_health <= 0) {
        return;
    }
    */

    SetEntData(client, h_iMaxHealth,	cvar_health, 4, true);
    SetEntData(client, h_iHealth,	cvar_health, 4, true);
    SetEntData(client, h_iMaxArmor,	cvar_armor, 4, true);
    SetEntData(client, h_iArmorValue,	cvar_armor, 4, true);
    SetEntDataFloat(client, h_flMaxspeed,	cvar_movespeed, true);
    SetEntDataFloat(client, h_flDefaultSpeed,	cvar_movespeed, true);

    if (GameWon) {
	FreezeClient(client);
	return;
    }

    LaunchDelayGiveWeapons(client);
}

public OnPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "client"));
    if (!client || !IsPlayerAlive(client) || !IsClientInGame(client) || !cvar_enabled)
	return;

    ClientPlayerDead[client] = 1;
}

public OnPlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "client"));
    if (!client || !IsPlayerAlive(client) || !IsClientInGame(client) || !cvar_enabled)
	return;

    ClientPlayerDead[client] = 1;
}

public OnPlayerSpecial(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client || !IsPlayerAlive(client) || !IsClientInGame(client) || !cvar_enabled)
	return;

    Debug("Player special, attempting to retrieve client weapon");
    decl String:weapon[1024];
    GetClientWeapon(client, weapon, 1024);
    Debug(weapon);
    
    ClientPlayerSpecial[client] = 0;
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new client = GetClientOfUserId(GetEventInt(event, "attacker"));
    if (!client || !IsPlayerAlive(client) || !IsClientInGame(client) || !cvar_enabled)
	return;

    ClientPlayerDead[victim] = 1;

    decl String:weapon[W_STRING_LEN];
    GetEventString(event, "weapon", weapon, W_STRING_LEN);
    
    TryLevelUp(client, victim, weapon);
}
