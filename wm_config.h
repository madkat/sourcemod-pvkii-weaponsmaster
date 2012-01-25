new cvar_enabled;
new cvar_debug;
new cvar_killstolevel;
new cvar_respawntimer;
new cvar_health;
new cvar_armor;
new cvar_killsforspree;
new cvar_warmuplength;
new Float:cvar_movespeed;
new Float:cvar_spreemovespeed;

enum Sounds
{
    Welcome,
    Knife,
    Nade,
    Steal,
    Up,
    Down,
    Spree,
    AutoFF,
    MultiKill,
    Winner,
    WarmupTimerSound,
    MaxSounds
}

new String:EventSounds[Sounds:MaxSounds][64];
