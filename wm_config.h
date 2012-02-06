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

new cvar_enabled;
new cvar_debug;
/*
new cvar_killstolevel;
new cvar_respawntimer;
new cvar_health;
new cvar_armor;
new cvar_killsforspree;
new cvar_warmuplength;
new Float:cvar_movespeed;
new Float:cvar_spreemovespeed; 
*/ 

enum Sounds
{
    Welcome,
    Up,
    Down,
    Spree,
    MaxSounds
}

new String:EventSounds[Sounds:MaxSounds][64];

enum State
{
    CONFIG_STATE_NONE,
    CONFIG_STATE_CONFIG,
    CONFIG_STATE_EQUIP,
    CONFIG_STATE_KILLS,
    CONFIG_STATE_SOUNDS,
    CONFIG_STATE_SECONDARY_LIST
}

new State:ConfigState;
new bool:ConfigReset;
new Handle:ConfigParser;
new ParseConfigCount;
new ConfigCount = 0;

/*
new bool:CfgEnableRandomWeaponOrder = false;
new CfgRandomWeaponReserveLevels[W_MAX_LEVEL];
*/

new CfgWeaponOrderCount = W_MAX_LEVEL;

new CfgKillsPerLevel = 1;

new bool:CfgEnableForcedRespawn = true;
new CfgRespawnTimer = 3;

new CfgPlayerMaxHealth = 100;
new CfgPlayerMaxArmor = 100;
new Float:CfgPlayerMoveSpeed = 220.0;

new bool:CfgEnableKillingSpree = true;
new CfgKillsForSpree = 3;
new Float:CfgKillSpreeMoveSpeedBonus = 100.0;

new bool:CfgEnableWarmupRound = true;
new CfgWarmupRoundLength = 45;
