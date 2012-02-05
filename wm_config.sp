/*******************************************************************************
*   This file is part of WeaponsMaster.
*
*   WeaponsMaster is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*
*   WeaponsMaster is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with WeaponsMaster.  If not, see <http://www.gnu.org/licenses/>.
*
*   Copyright (c) 2010-2012, Marty "MadKat" Lewis
*******************************************************************************/

InitSounds()
{
    EventSounds[Welcome] = "weaponsmaster/welcome2.mp3";
    EventSounds[Up] = "weaponsmaster/smb3_powerup.wav";
    EventSounds[Down] = "weaponsmaster/smb3_powerdown.wav";
    EventSounds[Spree] = "weaponsmaster/smb_star.mp3";

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
    new Handle:cv_killstolevel  = CreateConVar("wm_killstolevel",	"1", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, false, 1.0);
    new Handle:cv_respawntimer  = CreateConVar("wm_respawntimer", 	"3", "Number of seconds between respawns", FCVAR_NOTIFY | FCVAR_PLUGIN, true, -1.0, true, 20.0);
    new Handle:cv_health        = CreateConVar("wm_health",		"100", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 1.0, false, 1.0);
    new Handle:cv_armor         = CreateConVar("wm_armor",		"100", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 1.0, false, 1.0);
    new Handle:cv_killsforspree = CreateConVar("wm_killsforspree",	"3", "Number of kills for a player to enter a killing spree. 0 to disable", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 10.0);
    new Handle:cv_warmuplength  = CreateConVar("wm_warmuplength",	"45", "Length of the warmup round in seconds. 0 to disable", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 500.0);
    new Handle:cv_movespeed     = CreateConVar("wm_movespeed",		"220.0", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 1.0, true, 300.0);
    new Handle:cv_spreemovespeed= CreateConVar("wm_spreemovespeed",	"100.0", "", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 1.0, true, 300.0);
    
    HookConVarChange(cv_enabled, 	cvHookEnabled);
    HookConVarChange(cv_debug,  	cvHookDebug);
    HookConVarChange(cv_killstolevel,  	cvHookKillsToLevel);
    HookConVarChange(cv_respawntimer,  	cvHookRespawnTimer);
    HookConVarChange(cv_health, 	cvHookHealth);
    HookConVarChange(cv_armor, 		cvHookArmor);
    HookConVarChange(cv_killsforspree, 	cvHookKillsForSpree);
    HookConVarChange(cv_warmuplength, 	cvHookWarmupLength);
    HookConVarChange(cv_movespeed, 	cvHookMoveSpeed);
    HookConVarChange(cv_spreemovespeed,	cvHookSpreeMoveSpeed);
    
    cvar_enabled 	= GetConVarBool(cv_enabled);
    cvar_debug 		= GetConVarBool(cv_debug);
    cvar_killstolevel	= GetConVarInt(cv_killstolevel);
    cvar_respawntimer	= GetConVarInt(cv_respawntimer);
    cvar_health 	= GetConVarInt(cv_health);
    cvar_armor  	= GetConVarInt(cv_armor);
    cvar_killsforspree	= GetConVarInt(cv_killsforspree);
    cvar_warmuplength   = GetConVarInt(cv_warmuplength);
    cvar_movespeed 	= GetConVarFloat(cv_movespeed);
    cvar_spreemovespeed	= GetConVarFloat(cv_spreemovespeed);
}

public cvHookEnabled(Handle:cvar, const String:oldVal[], const String:newVal[]) { 
    cvar_enabled = GetConVarBool(cvar);
    if (!cvar_enabled) {
	RemoveServerTag(SERVER_TAG);
    } else {
	AddServerTag(SERVER_TAG);
        OnMapStart();
    }
}
public cvHookDebug(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_debug = GetConVarBool(cvar); }
public cvHookKillsToLevel(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_killstolevel = GetConVarInt(cvar); }
public cvHookRespawnTimer(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_respawntimer = GetConVarInt(cvar); }
public cvHookHealth(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_health = GetConVarInt(cvar); }
public cvHookArmor(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_armor = GetConVarInt(cvar); }
public cvHookKillsForSpree(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_killsforspree = GetConVarInt(cvar); }
public cvHookWarmupLength(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_warmuplength = GetConVarInt(cvar); }
public cvHookMoveSpeed(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_movespeed = GetConVarFloat(cvar); }
public cvHookSpreeMoveSpeed(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_spreemovespeed = GetConVarFloat(cvar); }


ReadConfig()
{
    ConfigParser = SMC_CreateParser();

    SMC_SetParseEnd(ConfigParser, ReadConfig_ParseEnd);
    SMC_SetReaders(ConfigParser, ReadConfig_NewSection, ReadConfig_KeyValue, ReadConfig_EndSection);

    if (ConfigParser == INVALID_HANDLE)
    {
        return;
    }

    decl String:ConfigDir[PLATFORM_MAX_PATH];
    FormatEx(ConfigDir, sizeof(ConfigDir), "cfg\\weaponsmaster");

    decl String:ConfigFile[PLATFORM_MAX_PATH], String:EquipFile[PLATFORM_MAX_PATH];
    decl String:Error[PLATFORM_MAX_PATH + 64];
    
    FormatEx(ConfigFile, sizeof(ConfigFile), "%s\\weaponsmaster.config.txt", ConfigDir);

    if(FileExists(ConfigFile))
    {
        ConfigCount++;
        PrintToServer("[WeaponsMaster] Loading weaponsmaster.config.txt config file");
    } else {
        FormatEx(Error, sizeof(Error), "[WeaponsMaster] *** ERROR *** can not find %s, using cvars", ConfigFile);
        //SetFailState(Error);
    }
    
    /*
    FormatEx(EquipFile, sizeof(EquipFile), "%s\\weaponsmaster.equip.txt", ConfigDir);
    
    if(FileExists(EquipFile))
    {
        ConfigCount++;
        PrintToServer("[WeaponsMaster] Loading weaponsmaster.equip.txt config file");
    } else {
        FormatEx(Error, sizeof(Error), "[WeaponsMaster] FATAL *** ERROR *** can not find %s", EquipFile);
        //SetFailState(Error);
    } 
    */ 
    
    /* Build map config and map prefix config*/

    decl String:Map[32];
    new len = GetCurrentMap(Map, sizeof(Map));
    
    new i, b;
    while(Map[i] != '_' && Map[i] != '\0' && i < len)
    {
        i++;
    }

    decl String:PrefixConfigFile[PLATFORM_MAX_PATH],  String:PrefixEquipFile[PLATFORM_MAX_PATH];
    new bool:EquipOne, bool:ConfigOne;
    
    if(Map[i] == '_')
    {
        b = Map[i];
        Map[i] = '\0';

        FormatEx(PrefixConfigFile, sizeof(PrefixConfigFile), "%s\\maps\\%s.config.txt", ConfigDir, Map);
        FormatEx(PrefixEquipFile, sizeof(PrefixEquipFile), "%s\\maps\\%s.equip.txt", ConfigDir, Map);

        if(FileExists(PrefixConfigFile))
        {
            ConfigOne = true;
            PrintToServer("[WeaponsMaster] Loading %s.config.txt config file", Map);
            ConfigCount++;
        }
        
        if(FileExists(PrefixEquipFile))
        {
            EquipOne = true;
            PrintToServer("[WeaponsMaster] Loading %s.equip.txt config file", Map);
            ConfigCount++;
        }

        Map[i] = b;
    }

    decl String:MapEquipFile[PLATFORM_MAX_PATH], String:MapConfigFile[PLATFORM_MAX_PATH];
    new bool:EquipTwo, bool:ConfigTwo;
    
    FormatEx(MapConfigFile, sizeof(MapConfigFile), "%s\\maps\\%s.config.txt", ConfigDir, Map);
    FormatEx(MapEquipFile, sizeof(MapEquipFile), "%s\\maps\\%s.equip.txt", ConfigDir, Map);

    if(FileExists(MapConfigFile))
    {
        PrintToServer("[WeaponsMaster] Loading %s.config.txt file", Map);
        ConfigTwo = true;
        ConfigCount++;
    }
    
    if(FileExists(MapEquipFile))
    {
        PrintToServer("[WeaponsMaster] Loading %s.equip.txt file", Map);
        EquipTwo = true;
        ConfigCount++;
    }
    
    InternalReadConfig(ConfigFile);
    InternalReadConfig(EquipFile);
    
    if(ConfigOne)
    {
        InternalReadConfig(PrefixConfigFile);
    }
    
    if(EquipOne)
    {
        InternalReadConfig(PrefixEquipFile);
    }
    
    if(ConfigTwo)
    {
        InternalReadConfig(MapConfigFile);
    }
    
    if(EquipTwo)
    {
        InternalReadConfig(MapEquipFile);
    }
}

static InternalReadConfig(const String:path[])
{
    new SMCError:status = SMC_ParseFile(ConfigParser, path);

    if (status != SMCError_Okay)
    {
        decl String:buffer[64];
        if (SMC_GetErrorString(status, buffer, sizeof(buffer)))
        {
            PrintToServer("[WeaponsMaster] %s", buffer);
        } else {
            PrintToServer("[WeaponsMaster] Fatal parse error");
        }
    }
}

public SMCResult:ReadConfig_NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
    if(name[0])
    {
        /*
        Call_StartForward(FwdConfigNewSection);
        Call_PushString(name);
        Call_Finish();
        */
    }

    return SMCParse_Continue;
}

public SMCResult:ReadConfig_KeyValue(Handle:smc,
                                        const String:key[],
                                        const String:value[],
                                        bool:key_quotes,
                                        bool:value_quotes)
{
    if(key[0] && value[0])
    {
        /*
        Call_StartForward(FwdConfigKeyValue);
        Call_PushString(key);
        Call_PushString(value);
        Call_Finish();
        */
    }

    return SMCParse_Continue;
}

public SMCResult:ReadConfig_EndSection(Handle:smc)
{
    return SMCParse_Continue;
}

public ReadConfig_ParseEnd(Handle:smc, bool:halted, bool:failed)
{
    /*
    Call_StartForward(FwdConfigParseEnd);
    Call_Finish(); 
    */ 
    
    if(ConfigCount == ++ParseConfigCount)
    {
        /*
        Call_StartForward(FwdConfigEnd);
        Call_Finish();
        */
    }
}
