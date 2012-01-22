#define W_MELEE 	0
#define W_RANGED 	1
#define W_SPECIAL 	2

#define W_TYPE 		0
#define W_SLOT 		1
#define W_SPCATK	2
#define W_AMMO_QTY	3

#define W_MAX_LEVEL	18

#define W_STRING_LEN    20
public const String:weapon_names[19][W_STRING_LEN] = {
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
    { W_SPECIAL	, 3 , 0 , -1  },
    { W_SPECIAL	, 3 , 0 , 1  }
};
