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

TryLevelUp(client, victim, String:weapon[W_STRING_LEN], special)
{
    if (CfgEnableWarmupRound && WarmupRemaining > 0) {
        LaunchDelayGiveWeapons(client);
        return;
    }

    ClientSpreeCounter[victim] = 0;

    if (victim == client) { // TODO: Make punishment optional
        ChangeClientLevel(client, -1);
    }

    if (CfgEnableForcedRespawn) {
        LaunchRespawnTimer(victim);
    }

    new level = ClientPlayerLevel[client];
    new Weapon:weapon_id = WeaponOrder[level];
    if (StrEqual(weapon, WeaponNames[weapon_id]) ||
        (WeaponOrder[level] == Weapon:CaptainParrot && StrEqual(weapon, WeaponNames[Weapon:CaptainPunch]))) {
        // If they killed with the weapon from this level
        ClientKillCounter[client]++;
        ClientSpreeCounter[client]++;
        if (ClientKillCounter[client] >= CfgKillsPerLevel) {
            ClientKillCounter[client] = 0;
            if (special && ClientPlayerSpecial[client] > 0) {
                ClientPlayerSpecial[client] = 2;
            }
            else {
                ChangeClientLevel(client, 1);
            }
        }
    }
    else if (StrEqual(weapon, "prop_physics") || StrEqual(weapon, "prop_physics_multiplayer")) {
        // If they landed a kill with a trap
        ChangeClientLevel(client, 1);
    }
    else {
        // Grant ammo refresh
       LaunchDelayGiveWeapons(client);
    }

    if (CfgEnableKillingSpree && ClientSpreeCounter[client] >= CfgKillsForSpree) {
        ClientSpreeCounter[client] = 0;
        if (CfgKillsForSpree > 0) {
            HandleKillingSpree(client);
        }
    }
}

ChangeClientLevel(client, difference)
{
    if (!cvar_enabled || !difference || GameWon || WarmupInProgress) {
        return;
    }

    new old_level = ClientPlayerLevel[client];
    new level = old_level + difference;
    ClientPlayerLevel[client] = level;

    if (level < old_level) {
        PlaySound(client, Sounds:Down);
        return;
        //Suicide, no further action needed
    }

    PlaySound(client, Sounds:Up);
    
    if (level >= CfgWeaponOrderCount) {
        GameWon = true;
        FreezeAllPlayers();
        decl String:name[MAX_NAME_LENGTH + 1];
        GetClientName(client, name, MAX_NAME_LENGTH);
        PrintCenterTextAll("%s is victorious!", name);
    
        LaunchChangeLevel();
        return;
    }

    RecalculateLeader(client, old_level, level);
    LaunchDelayGiveWeapons(client);
}

LaunchChangeLevel()
{
    CreateTimer(5.0, DelayChangeLevel);
}

public Action:DelayChangeLevel(Handle:timer)
{
    DelayedChangeLevel();
}

DelayedChangeLevel()
{
    decl String:nextmap[51];
    GetNextMap(nextmap, 50);
    ForceChangeLevel(nextmap, "WM_VICTORY");
}

LaunchWarmupTimer()
{
    if (CfgEnableWarmupRound) {
        WarmupRemaining = CfgWarmupRoundLength;
        for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) LaunchDelayGiveWeapons(i, 0.0);
        CreateTimer(1.0, WarmupTick);
    }
}

public Action:WarmupTick(Handle:timer)
{
    if (WarmupRemaining > 0) {
        WarmupRemaining--;
        CreateTimer(1.0, WarmupTick);
    }
    else {
        for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) LaunchDelayGiveWeapons(i, 0.0);
    }
}

LaunchRespawnTimer(client)
{
    if (!client || !IsClientInGame(client)) {
        return;
    }
    ClientSpawnTimer[client] = 0;
    CreateTimer(1.0, RespawnTick, client);
}

public Action:RespawnTick(Handle:timer, any:client)
{
    if (IsClientInGame(client)) {
        ClientSpawnTimer[client]++;
        if (ClientSpawnTimer[client] >= CfgRespawnTimer) {
            ClientSpawnTimer[client] = 0;
            ForceSpawn(client);
        }
        else {
            CreateTimer(1.0, RespawnTick, client);
        }
    }
}

LaunchHandleSpecial(client)
{
    CreateTimer(5.0, HandleSpecial, client);
}

public Action:HandleSpecial(Handle:timer, any:client)
{
    if (!client || !IsClientInGame(client))
        return;

    if (ClientPlayerSpecial[client] == 2) {
        // Make sure to set player special back to 0,
        // otherwise the ChangeLevel will ignore us.
        ChangeClientLevel(client, 1);
    }

    ClientPlayerSpecial[client] = 0;
}

LaunchDelayGiveWeapons(client, Float:delay = 0.2)
{
    CreateTimer(delay, DelayGiveWeapons, client);
}

public Action:DelayGiveWeapons(Handle:timer, any:client)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
        DelayedGiveWeapons(client);
    }
}

DelayedGiveWeapons(client)
{
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client)) {
        return;
    }
    RemoveAllWeapons(client);
    GiveWeapons(client);
}

public GiveWeapons(client)
{
    if (!IsPlayerAlive(client)) {
        return;
    }

    new weapon_object;

    if (CfgEnableWarmupRound && WarmupRemaining > 0) {
        weapon_object = GiveWeapon(client, WeaponNames[Weapon:SkirmisherKeg]);
        if (weapon_properties[Weapon:SkirmisherKeg][W_AMMO_QTY] > -1) {
    	    new ammo_type = GetEntProp(weapon_object, Prop_Data, "m_iPrimaryAmmoType", 4);
    	    GiveAmmo(client, weapon_properties[Weapon:SkirmisherKeg][W_AMMO_QTY], ammo_type);
        }
        EquipWeapon(client, weapon_object);

        weapon_object = GiveWeapon(client, WeaponNames[Weapon:ArcherSword]);
    	if (weapon_object > 0) {
    	    EquipWeapon(client, weapon_object);
    	}
        PrintToChat(client, "Warmup round is in progress");
        return;
    }

    new level = ClientPlayerLevel[client];
    new Weapon:weapon_id = WeaponOrder[level];

    weapon_object = GiveWeapon(client, WeaponNames[weapon_id]);
    if (weapon_object > 0) {
        if (weapon_properties[weapon_id][W_AMMO_QTY] > -1) {
    	    new ammo_type = GetEntProp(weapon_object, Prop_Data, "m_iPrimaryAmmoType", 4);
    	    GiveAmmo(client, weapon_properties[weapon_id][W_AMMO_QTY], ammo_type);
        }
        EquipWeapon(client, weapon_object);
    }

    // If using a ranged weapon that's not a parrot or longbow
    // Or, if they have a breakable weapon
    if ((weapon_id >= Weapon:CaptainBlunderbuss && weapon_id < Weapon:CaptainParrot && weapon_id != Weapon:ArcherLongbow)
        || weapon_id == Weapon:HeavyKnightSwordShield
        || weapon_id == Weapon:HuscarlSwordShield
        || weapon_id == Weapon:GestirSwordShield) {
    	// Give an archer sword
        weapon_object = GiveWeapon(client, WeaponNames[Weapon:ArcherSword]);
    	if (weapon_object > 0) {
    	    EquipWeapon(client, weapon_object);
    	}
    }
}

FindLeader()
{
    new leader_id = 0;
    new leader_level = 0;
    new current_level = 0;

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i))
        {
            continue;
        }

        current_level = ClientPlayerLevel[i];

        if ( current_level > leader_level )
        {
            leader_level = current_level;
            leader_id = i;
        }
    }

    LeaderLevel = leader_level;
    return leader_id;
}

public PrintLevelInfo(client) {
    new level = ClientPlayerLevel[client];
    PrintToChat(client, "You are on level %d", level + 1);

    if (CfgKillsPerLevel > 1)
    {
        new kills = ClientKillCounter[client];
        //decl String:subtext[64];
        //Format(subtext, W_STRING_LEN, "You need %d kills to advance to the next level.", CfgKillsPerLevel - kills);
        PrintToChat(client, "You need %d kills to advance to the next level", CfgKillsPerLevel - kills);
    }    
}

public RecalculateLeader(client, old_level, new_level) {
    decl String:name[MAX_NAME_LENGTH];
    GetClientName(client, name, MAX_NAME_LENGTH);

    if (new_level > LeaderLevel) {
        // New Leader
        LeaderName = name;
        LeaderLevel = new_level;
        PrintToChatAll("%s is leading on level %d", name, LeaderLevel + 1);
    }
    else if (new_level == LeaderLevel) {
        // New Tie
        if (StrEqual(LeaderName, "")) {
            PrintToChatAll("%s is tied with the other leaders on level %d", name, LeaderLevel + 1);
        }
        else {
            PrintToChatAll("%s is tied with %s on level %d", name, LeaderName, LeaderLevel + 1);
            LeaderName = "";
        }
    }
    else if (old_level == LeaderLevel) {
        // No longer in lead
        if (StrEqual(LeaderName, "")) {
            PrintToChatAll("%s is no longer tied for the lead.", name);
        }
        else {
            new new_leader = FindLeader();
            if (new_leader > 0) {
                GetClientName(new_leader, LeaderName, MAX_NAME_LENGTH);
            }
            PrintToChatAll("%s forfeits the lead to %s", name, LeaderName);
        }
    }
    else {
        if (IsClientInGame(client) && !IsFakeClient(client)) {
            new trail = LeaderLevel - new_level;
            if (trail > 1) {
                PrintToChat(client, "You are trailing the leader by %d levels.", trail);
            }
            else {
                PrintToChat(client, "You are trailing the leader by %d level.", trail);
            }
        }
    }
}

PlaySound(client, Sounds:type)
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

HandleKillingSpree(client)
{
    decl String:name[MAX_NAME_LENGTH];
    GetClientName(client, name, MAX_NAME_LENGTH);
    PrintToChatAll("%s is on a killing spree!", name);
    StartKillingSpreeEffects(client);
    CreateTimer(10.0, RemoveKillingSpreeBonus, client);
}

public Action:RemoveKillingSpreeBonus(Handle:timer, any:client)
{
    if (IsClientInGame(client))
    {
        StopKillingSpreeEffects(client);
    }
}

StartKillingSpreeEffects(client)
{
    if ( ClientSpreeEffects[client] ) {
        return;
    }
    ClientSpreeEffects[client] = 1;

    if ( CfgKillSpreeMoveSpeedBonus ) {
        SetEntDataFloat(client, h_flDefaultSpeed, CfgKillSpreeMoveSpeedBonus + CfgPlayerMoveSpeed);
        SetEntDataFloat(client, h_flMaxspeed, CfgKillSpreeMoveSpeedBonus + CfgPlayerMoveSpeed);
    }
    if ( EventSounds[Spree][0] ) {
        EmitSoundToAll(EventSounds[Spree], client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
    }
}

StopKillingSpreeEffects(client)
{
    if (!ClientSpreeEffects[client]) {
        return;
    }
    ClientSpreeEffects[client] = 0;
    
    if (CfgKillSpreeMoveSpeedBonus) {
        SetEntDataFloat(client, h_flDefaultSpeed, CfgPlayerMoveSpeed);
        SetEntDataFloat(client, h_flMaxspeed, CfgPlayerMoveSpeed);
    }
    if (EventSounds[Spree][0]) {
        EmitSoundToAll(EventSounds[Spree], client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL);
    }
}

FreezeAllPlayers()
{
    new client;
    
    for (client = 1; client <= MaxClients; client++)
    {
        FreezeClient(client);
    }
}

FreezeClient(client)
{
    if (IsClientInGame(client))
    {
        new flags;
        flags = GetEntData(client, h_OffsetFlags)|FL_FROZEN;
        SetEntData(client, h_OffsetFlags, flags);
    }
}
