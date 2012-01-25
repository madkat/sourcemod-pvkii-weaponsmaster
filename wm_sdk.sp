InitSDKCalls()
{
    new Handle:conf = LoadGameConfigFile("weaponsmaster.cfg");
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GiveNamedItem");
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
    hGiveNamedItem = EndPrepSDKCall();
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "Weapon_Equip");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    hWeapon_Equip = EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GiveAmmo");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    hGiveAmmo = EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "RemoveAllItems");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    hRemoveAllItems = EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "ForceRespawn");
    hForceRespawn = EndPrepSDKCall();
    
    CloseHandle(conf);

    h_iMaxHealth	= FindSendPropInfo(PlayerEntity, "m_iMaxHealth");
    h_iHealth	   	= FindSendPropInfo(PlayerEntity, "m_iHealth");
    h_iMaxArmor		= FindSendPropInfo(PlayerEntity, "m_iMaxArmor");
    h_iArmorValue	= FindSendPropInfo(PlayerEntity, "m_ArmorValue");
    h_flMaxspeed	= FindSendPropInfo(PlayerEntity, "m_flMaxspeed");
    h_flDefaultSpeed= FindSendPropInfo(PlayerEntity, "m_flDefaultSpeed");
    h_iPlayerClass	= FindSendPropInfo(PlayerEntity, "m_iPlayerClass");
    h_OffsetFlags     = FindSendPropOffs("CBasePlayer", "m_fFlags");
}

RemoveAllWeapons(client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
        return;
    }

    SDKCall(hRemoveAllItems, client, false);
}

ForceRespawn(client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
        return;
    }

    SDKCall(hForceRespawn, client, false);
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
