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

InitSDKCalls()
{
    new Handle:conf = LoadGameConfigFile("weaponsmaster.cfg");
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GiveNamedItem");
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
    hGiveNamedItem = EndPrepSDKCall();

    if (hGiveNamedItem == INVALID_HANDLE) {
        PrintToServer("[WeaponsMaster] WARNING: Could not find SDK method: GiveNamedItem");
    }
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "Weapon_Equip");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    hWeapon_Equip = EndPrepSDKCall();

    if (hWeapon_Equip == INVALID_HANDLE) {
        PrintToServer("[WeaponsMaster] WARNING: Could not find SDK method: Weapon_Equip");
    }

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GiveAmmo");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    hGiveAmmo = EndPrepSDKCall();

    if (hGiveAmmo == INVALID_HANDLE) {
        PrintToServer("[WeaponsMaster] WARNING: Could not find SDK method: GiveAmmo");
    }

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "RemoveAllItems");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    hRemoveAllItems = EndPrepSDKCall();

    if (hRemoveAllItems == INVALID_HANDLE) {
        PrintToServer("[WeaponsMaster] WARNING: Could not find SDK method: RemoveAllItems");
    }

    /*
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "ForceRespawn");
    hForceRespawn = EndPrepSDKCall(); 
    */ 

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "Spawn");
    hSpawn = EndPrepSDKCall();

    if (hSpawn == INVALID_HANDLE) {
        PrintToServer("[WeaponsMaster] WARNING: Could not find SDK method: Spawn");
    }
    
    CloseHandle(conf);

    h_iMaxHealth	= FindSendPropInfo(PlayerEntity, "m_iMaxHealth");
    h_iHealth	   	= FindSendPropInfo(PlayerEntity, "m_iHealth");
    h_iMaxArmor		= FindSendPropInfo(PlayerEntity, "m_iMaxArmor");
    h_iArmorValue	= FindSendPropInfo(PlayerEntity, "m_ArmorValue");
    h_flMaxspeed	= FindSendPropInfo(PlayerEntity, "m_flMaxspeed");
    h_flDefaultSpeed    = FindSendPropInfo(PlayerEntity, "m_flDefaultSpeed");
    h_iPlayerClass	= FindSendPropInfo(PlayerEntity, "m_iPlayerClass");
    h_OffsetFlags       = FindSendPropOffs("CBasePlayer", "m_fFlags");
}

RemoveAllWeapons(client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
        return;
    }

    SDKCall(hRemoveAllItems, client, false);
}

/*
ForceRespawn(client)
{
    if (!IsClientInGame(client)) {
        return;
    }

    SDKCall(hForceRespawn, client, false);
}
*/

ForceSpawn(client)
{
    if (!IsClientInGame(client)) {
        return;
    }

    SDKCall(hSpawn, client, false);
}

GiveWeapon(client, String:weapon_name[W_STRING_LEN])
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
        return -1;
    }

    decl String:primary_name[W_STRING_LEN];
    Format(primary_name, W_STRING_LEN, "weapon_%s", weapon_name);

    return SDKCall(hGiveNamedItem, client, primary_name, 0);
}

GiveAmmo(client, quantity, ammo_type)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
        return -1;
    }

    return SDKCall(hGiveAmmo, client, quantity, ammo_type, true);
}

EquipWeapon(client, CBaseCombatWeapon)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
        return -1;
    }

    return SDKCall(hWeapon_Equip, client, CBaseCombatWeapon);
}
