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

#define PL_VERSION "0.1"
#define SERVER_TAG "wm"

#define PlayerEntity "CPVK2Player"

new LeaderLevel;
new String:LeaderName[MAX_NAME_LENGTH];
new bool:GameWon = false;

new WarmupRemaining = 0;
new bool:WarmupInProgress = false;

new ClientUserID[MAXPLAYERS + 1] = {0, ...};
new ClientPlayerLevel[MAXPLAYERS + 1] = {0, ...};
new ClientKillCounter[MAXPLAYERS + 1] = {0, ...};
new ClientSpreeCounter[MAXPLAYERS + 1] = {0, ...};
new ClientSpreeEffects[MAXPLAYERS + 1] = {0, ...};
new ClientSpawnTimer[MAXPLAYERS + 1] = {0, ...};
new ClientFirstJoin[MAXPLAYERS + 1] = {0, ...};
new ClientPlayerDead[MAXPLAYERS + 1] = {0, ...};
new ClientPlayerSpecial[MAXPLAYERS + 1] = {0, ...};

#define W_MELEE 	0
#define W_RANGED 	1
#define W_SPECIAL 	2

#define W_TYPE 		0
#define W_SLOT 		1
#define W_SPCATK	2
#define W_AMMO_QTY	3

#define W_TOTAL_COUNT   21
#define W_MAX_LEVEL	19

#define W_STRING_LEN    20

enum Weapon {
    ArcherSword = 0,
    BerserkerAxeSword,
    BerserkerAxe,
    SkirmisherCutlass,
    CaptainCutlass,
    GestirSwordShield,
    GestirSpear,
    HeavyKnightSwordShield,
    HuscarlAxe,
    HeavyKnightSword,
    HuscarlSwordShield,
    CaptainBlunderbuss,
    SkirmisherFlintlock,
    ArcherCrossbow,
    ArcherLongbow,
    GestirJavelin,
    HuscarlThrowingAxe,
    SkirmisherKeg,
    CaptainParrot,
    CaptainHook,
    CaptainPunch
};

public const String:WeaponNames[W_TOTAL_COUNT][W_STRING_LEN] = {
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
    "parrot",
    "hook",
    "punch"
};

Weapon:FindWeaponId(const String:name[]) {
    new i;
    for (i = 1; i <= W_MAX_LEVEL; i++) {
        if (StrEqual(name, WeaponNames[i])) {
            return Weapon:i;
        }
    }

    return Weapon:-1;
}

new Weapon:WeaponOrder[W_MAX_LEVEL] = {
    ArcherSword,
    BerserkerAxeSword,
    BerserkerAxe,
    SkirmisherCutlass,
    CaptainCutlass,
    GestirSwordShield,
    GestirSpear,
    HeavyKnightSwordShield,
    HuscarlAxe,
    HeavyKnightSword,
    HuscarlSwordShield,
    CaptainBlunderbuss,
    SkirmisherFlintlock,
    ArcherCrossbow,
    ArcherLongbow,
    GestirJavelin,
    HuscarlThrowingAxe,
    SkirmisherKeg,
    CaptainParrot
};

public const weapon_properties[W_MAX_LEVEL][5] = {
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
    { W_SPECIAL	, 3 , 0 , -1 },
    { W_SPECIAL	, 3 , 0 , 1  }
};

UTIL_GetRandomInt(start, end)
{
    new rand;
    #if defined URANDOM_SUPPORT
        // if sourcemod version >= 1.3.0
        rand = GetURandomInt();
    #else
        new Float:frand = GetEngineTime() + GetRandomFloat();
        rand = RoundFloat( ( frand - RoundToZero(frand) ) * 1000000 ) + GetTime();
    #endif
    return ( rand % (1 + end - start) ) + start;
}

UTIL_WeaponArrayIntRand(array[], size)
{
    if ( size < 2 )
    {
        return;
    }
    new tmpIndex, tmpValue;
    for ( new i = 0; i < size-1; i++ )
    {
        tmpIndex = UTIL_GetRandomInt(i, size-1);
        if ( tmpIndex == i )
        {
            continue;
        }
        tmpValue = array[tmpIndex];
        
        array[tmpIndex] = array[i];
        array[i] = tmpValue;
    }
}
