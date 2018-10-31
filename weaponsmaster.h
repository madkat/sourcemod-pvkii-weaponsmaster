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

#define W_TOTAL_COUNT   30
#define W_MAX_LEVEL	28

#define W_STRING_LEN    20

enum Weapon {
	SharpshooterDagger = 0,
    ArcherSword,
    BerserkerAxeSword,
    BerserkerAxe,
    BondiSeax,
    SkirmisherCutlass,
    ManAtArmsHalberd,
    CaptainCutlass,
    GestirSwordShield,
    GestirSpear,
    HeavyKnightSwordShield,
    HuscarlAxe,
    ManAtArmsMaceShield,
    HeavyKnightSword,
    HuscarlSwordShield,
	SharpshooterRifle,
    ManAtArmsCrossbow,
    CaptainBlunderbuss,
    SkirmisherFlintlock,
	SharpshooterFlintlock,
    BondiFlatbow,
    ArcherCrossbow,
    ArcherLongbow,
    GestirJavelin,
    BondiAtlatl,
    HuscarlThrowingAxe,
    SkirmisherKeg,
    CaptainParrot,
    CaptainHook,
    CaptainPunch
};

public const String:WeaponNames[W_TOTAL_COUNT][W_STRING_LEN] = {
	"dagger",
    "archersword",
    "axesword",
    "bigaxe",
    "seax",
    "cutlass",
    "halberd",
    "cutlass2",
    "seaxshield",
    "spear",
    "swordshield",
    "twoaxe",
    "maceshield",
    "twosword",
    "vikingshield",
	"ssrifle",
    "crossbow2",
    "blunderbuss",
    "flintlock",
	"ssflintlock",
    "flatbow",
    "crossbow",
    "longbow",
    "javelin",
    "atlatl",
    "throwaxe",
    "powderkeg",
    "parrot",
    "hook",
    "punch"
};

Weapon:FindWeaponId(const String:name[]) {
    new i;
    for (i = 0; i < W_MAX_LEVEL; i++) {
        if (StrEqual(name, WeaponNames[i])) {
            return Weapon:i;
        }
    }

    return Weapon:-1;
}

new Weapon:WeaponOrder[W_MAX_LEVEL] = {
	SharpshooterDagger,
    ArcherSword,
    BerserkerAxeSword,
    BerserkerAxe,
    BondiSeax,
    SkirmisherCutlass,
    ManAtArmsHalberd,
    CaptainCutlass,
    GestirSwordShield,
    GestirSpear,
    HeavyKnightSwordShield,
    HuscarlAxe,
    ManAtArmsMaceShield,
    HeavyKnightSword,
    HuscarlSwordShield,
	SharpshooterRifle,
    ManAtArmsCrossbow,
    CaptainBlunderbuss,
    SkirmisherFlintlock,
	SharpshooterFlintlock,
    BondiFlatbow,
    ArcherCrossbow,
    ArcherLongbow,
    GestirJavelin,
    BondiAtlatl,
    HuscarlThrowingAxe,
    SkirmisherKeg,
    CaptainParrot
};

public const weapon_properties[W_MAX_LEVEL][5] = {
	{ W_MELEE	, 1 , 1 , -1 }, // dagger
    { W_MELEE	, 1 , 0 , -1 }, // archersword
    { W_MELEE	, 2 , 1 , -1 }, // axesword
    { W_MELEE	, 1 , 1 , -1 }, // bigaxe
    { W_MELEE	, 1 , 0 , -1 }, // seax
    { W_MELEE	, 1 , 1 , -1 }, // cutlass
    { W_MELEE	, 1 , 1 , -1 }, // halberd
    { W_MELEE	, 1 , 0 , -1 }, // cutlass2
    { W_MELEE	, 2 , 0 , -1 }, // seaxshield
    { W_MELEE	, 1 , 1 , -1 }, // spear
    { W_MELEE	, 2 , 0 , -1 }, // swordshield
    { W_MELEE	, 1 , 0 , -1 }, // twoaxe
    { W_MELEE	, 2 , 1 , -1 }, // maceshield
    { W_MELEE	, 1 , 1 , -1 }, // twosword
    { W_MELEE	, 2 , 1 , -1 }, // vikingshield
	{ W_RANGED	, 3 , 1 , 10  }, // ssrifle
    { W_RANGED	, 3 , 1 , 4  }, // crossbow2
    { W_RANGED	, 2 , 1 , 5 }, // blunderbuss
    { W_RANGED	, 2 , 0 , 12 }, // flintlock
	{ W_RANGED	, 2 , 1 , 15 }, // ssflintlock
    { W_RANGED	, 3 , 1 , 40 }, // flatbow
    { W_RANGED	, 2 , 0 , 15 }, // crossbow
    { W_RANGED	, 3 , 1 , 30 }, // longbow
    { W_RANGED	, 3 , 0 , 3  }, // javelin
    { W_RANGED	, 2 , 0 , 3  }, // atlatl
    { W_RANGED	, 3 , 0 , 8  }, // throwaxe
    { W_SPECIAL	, 3 , 0 , -1 }, // powderkeg
    { W_SPECIAL	, 3 , 0 , 1  } // parrot
};

