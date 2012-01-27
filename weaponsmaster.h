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
    CaptainParrot
};

public const String:WeaponNames[W_MAX_LEVEL][W_STRING_LEN] = {
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

public const weapon_properties[19][5] = {
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
