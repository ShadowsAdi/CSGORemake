/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>
#include <cstrike>
#include <reapi>
#include <fakemeta>

#define PLUGIN  "[CS:GO Remake] Skin Submodel support"
#define AUTHOR  "Shadows Adi"

#define WEAPONTYPE_ELITE 				1
#define WEAPONTYPE_GLOCK18				2
#define WEAPONTYPE_FAMAS 				3
#define WEAPONTYPE_OTHER 				4
#define WEAPONTYPE_M4A1 				5
#define WEAPONTYPE_USP 					6

#define IDLE_ANIM 						0
#define KNIFE_STABMISS 					5
#define KNIFE_MIDATTACK1HIT 			6
#define KNIFE_MIDATTACK2HIT 			7
#define GLOCK18_SHOOT2 					4
#define GLOCK18_SHOOT3 					5
#define AK47_SHOOT1 					3
#define AUG_SHOOT1 						3
#define AWP_SHOOT2 						2
#define DEAGLE_SHOOT1 					2
#define ELITE_SHOOTLEFT5 				6
#define ELITE_SHOOTRIGHT5 				12
#define CLARION_SHOOT2 					4
#define CLARION_SHOOT3 					3
#define FIVESEVEN_SHOOT1 				1
#define G3SG1_SHOOT 					1
#define GALIL_SHOOT3 					5
#define M3_FIRE2 						2
#define XM1014_FIRE2 					2
#define M4A1_SHOOT3						3
#define M4A1_UNSIL_SHOOT3 				10
#define M249_SHOOT2 					2
#define MAC10_SHOOT1 					3
#define MP5N_SHOOT1 					3
#define P90_SHOOT1 						3
#define P228_SHOOT2 					2
#define SCOUT_SHOOT 					1
#define SG550_SHOOT 					1
#define SG552_SHOOT2 					4
#define TMP_SHOOT3 						5
#define UMP45_SHOOT2 					4
#define USP_UNSIL_SHOOT3 				11
#define USP_SHOOT3						3

new const g_szGEvents[25][] = 
{
    "events/awp.sc",
    "events/g3sg1.sc",
    "events/ak47.sc",
    "events/scout.sc",
    "events/m249.sc",
    "events/m4a1.sc",
    "events/sg552.sc",
    "events/aug.sc",
    "events/sg550.sc",
    "events/m3.sc",
    "events/xm1014.sc",
    "events/usp.sc",
    "events/mac10.sc",
    "events/ump45.sc",
    "events/fiveseven.sc",
    "events/p90.sc",
    "events/deagle.sc",
    "events/p228.sc",
    "events/glock18.sc",
    "events/mp5n.sc",
    "events/tmp.sc",
    "events/elite_left.sc",
    "events/elite_right.sc",
    "events/galil.sc",
    "events/famas.sc"
}

// 512 because of MAX_EVENTS const from engine. Found this as the most reasonable way to achieve it without a loop in playback event.
new bool:g_bGEventID[512]

new g_iMaxPlayers

new Trie:g_tWeaponSounds

public plugin_natives()
{
	g_tWeaponSounds = TrieCreate()

	register_native("csgor_send_weapon_anim", "native_send_weapon_anim")
}

public plugin_precache()
{
	g_iMaxPlayers = get_maxplayers()

	RegisterHookChain(RH_SV_AddResource, "RH_SV_AddResource_Post", 1)
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_forward(FM_PlaybackEvent, "FM_Hook_PlayBackEvent_Pre")
	register_forward(FM_PlaybackEvent, "FM_Hook_PlayBackEvent_Primary_Pre")

	register_forward(FM_ClientUserInfoChanged, "FM_ClientUserInfoChanged_ClientWeap_Pre")

	RegisterHookChain(RH_SV_StartSound, "RH_SV_StartSound_Pre")
}

public plugin_end()
{
	TrieDestroy(g_tWeaponSounds)
}

public csgor_read_configuration_data(szBuffer[], FileSections:iSection, iLine)
{
	if(iSection != FileSections:secWeaponSounds)
		return

	static szKey[32], szTemp[128]

	parse(szBuffer, szKey, charsmax(szKey), szTemp, charsmax(szTemp))

	precache_sound(szTemp)

	TrieSetString(g_tWeaponSounds, szKey, szTemp)
}

public RH_SV_StartSound_Pre(const recipients, const entity, const channel, const sample[], const volume, Float:attenuation, const fFlags, const pitch)
{
	if(!is_user_connected(entity))
		return

	static szSound[128]
	if(containi(sample, "dryfire_rifle") != -1)
	{
		TrieGetString(g_tWeaponSounds, "DRYFIRE_RIFLE", szSound, charsmax(szSound))

		SetHookChainArg(4, ATYPE_STRING, szSound)
	}
	else if(containi(sample, "dryfire_pistol") != -1)
	{
		TrieGetString(g_tWeaponSounds, "DRYFIRE_PISTOL", szSound, charsmax(szSound))

		SetHookChainArg(4, ATYPE_STRING, szSound)
	}
}

public native_send_weapon_anim(iPluginID, iParamNum)
{
	enum { arg_index = 1, arg_anim }

	new iPlayer = get_param(arg_index)

	if(!is_user_connected(iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid player (%d).", PLUGIN, iPlayer)
		return false
	}

	SendWeaponAnim(iPlayer, get_param(arg_anim))

	return true
}

public RH_SV_AddResource_Post(ResourceType_t:type, const filename[], size, flags, index)
{
	switch(type)
	{
		case t_eventscript:
		{
			for(new i; i < sizeof(g_szGEvents); i++)
			{
				if (equali(filename, g_szGEvents[i]))
				{
					g_bGEventID[index] = true
					break;
				}
			}
		}
	}
}

public FM_Hook_PlayBackEvent_Pre(iFlags, pPlayer, iEvent, Float:fDelay, Float:vecOrigin[3], Float:vecAngle[3], Float:flParam1, Float:flParam2, iParam1, iParam2, bParam1, bParam2)
{
	new i, iCount, iSpectator, iszSpectators[32]

	get_players(iszSpectators, iCount, "bch")

	for(i = 0; i < iCount; i++)
	{
		iSpectator = iszSpectators[i]

		if(pev(iSpectator, pev_iuser1) != OBS_IN_EYE || pev(iSpectator, pev_iuser2) != pPlayer)
			continue

		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}

public FM_Hook_PlayBackEvent_Primary_Pre(iFlags, id, eventid, Float:delay, Float:FlOrigin[3], Float:FlAngles[3], Float:FlParam1, Float:FlParam2, iParam1, iParam2, bParam1, bParam2)
{
	if(!is_user_connected(id) || is_nullent(id) || !IsPlayer(id, g_iMaxPlayers) || !g_bGEventID[eventid])
		return FMRES_IGNORED

	new iEnt = get_user_weapon(id)

	PrimaryAttackReplace(id, iEnt)
	return FMRES_SUPERCEDE
}

public FM_ClientUserInfoChanged_ClientWeap_Pre(id)
{
	new userInfo[6] = "cl_lw"
	new clientValue[2]
	new serverValue[2] = "0"

	if (get_user_info(id, userInfo, clientValue, charsmax(clientValue)))
	{
		set_user_info(id, userInfo, serverValue)

		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}

public csgor_weapon_deploy(iPlayer, entWeapon)
{
	SendWeaponAnim(iPlayer, WeaponDrawAnim(entWeapon))
}

WeaponDrawAnim(iEntity)
{
	if(is_nullent(iEntity))
		return -1

	static DrawAnim, WeaponState:mWeaponState

	mWeaponState = get_member(iEntity, m_Weapon_iWeaponState)

	switch(GetWeaponEntity(iEntity))
	{
		case CSW_P228, CSW_XM1014, CSW_M3: DrawAnim = 6
		case CSW_SCOUT, CSW_SG550, CSW_M249, CSW_G3SG1: DrawAnim = 4
		case CSW_MAC10, CSW_AUG, CSW_UMP45, CSW_GALIL, CSW_FAMAS, CSW_MP5NAVY, CSW_TMP, CSW_SG552, CSW_AK47, CSW_P90: DrawAnim = 2
		case CSW_ELITE: DrawAnim = 15
		case CSW_FIVESEVEN, CSW_AWP, CSW_DEAGLE: DrawAnim = 5
		case CSW_GLOCK18: DrawAnim = 8
		case CSW_KNIFE, CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE: DrawAnim = 3
		case CSW_C4: DrawAnim = 1
		case CSW_USP:
		{
			DrawAnim = (mWeaponState & WPNSTATE_USP_SILENCED) ? 6 : 14
		}
		case CSW_M4A1:
		{
			DrawAnim = (mWeaponState & WPNSTATE_M4A1_SILENCED) ? 5 : 12
		}
	}

	return DrawAnim
}

PrimaryAttackReplace(id, iEnt)
{
	switch(iEnt)
	{
		case CSW_GLOCK18: WeaponShootInfo2(id, iEnt, GLOCK18_SHOOT3, "GLOCK18_SHOOT_SOUND", 1, WEAPONTYPE_GLOCK18)
		case CSW_AK47: WeaponShootInfo2(id, iEnt, AK47_SHOOT1, "AK47_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_AUG: WeaponShootInfo2(id, iEnt, AUG_SHOOT1, "AUG_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_AWP: WeaponShootInfo2(id, iEnt, AWP_SHOOT2, "AWP_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_DEAGLE: WeaponShootInfo2(id, iEnt, DEAGLE_SHOOT1, "DEAGLE_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_ELITE: WeaponShootInfo2(id, iEnt, ELITE_SHOOTRIGHT5, "ELITE_SHOOT_SOUND", 1, WEAPONTYPE_ELITE)
		case CSW_FAMAS: WeaponShootInfo2(id, iEnt, CLARION_SHOOT3, "CLARION_SHOOT_SOUND", 1, WEAPONTYPE_FAMAS)
		case CSW_FIVESEVEN: WeaponShootInfo2(id, iEnt, FIVESEVEN_SHOOT1, "FIVESEVEN_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_G3SG1: WeaponShootInfo2(id, iEnt, G3SG1_SHOOT, "G3SG1_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_GALIL: WeaponShootInfo2(id, iEnt, GALIL_SHOOT3, "GALIL_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_M3: WeaponShootInfo2(id, iEnt, M3_FIRE2, "M3_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_XM1014: WeaponShootInfo2(id, iEnt, XM1014_FIRE2, "XM1014_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_M4A1: WeaponShootInfo2(id, iEnt, M4A1_UNSIL_SHOOT3, "M4A1_SHOOT_SOUND", 1, WEAPONTYPE_M4A1)
		case CSW_M249: WeaponShootInfo2(id, iEnt, M249_SHOOT2, "M249_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_MAC10: WeaponShootInfo2(id, iEnt, MAC10_SHOOT1, "MAC10_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_MP5NAVY: WeaponShootInfo2(id, iEnt, MP5N_SHOOT1, "MP5_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_P90: WeaponShootInfo2(id, iEnt, P90_SHOOT1, "P90_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_P228: WeaponShootInfo2(id, iEnt, P228_SHOOT2, "P228_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_SCOUT: WeaponShootInfo2(id, iEnt, SCOUT_SHOOT, "SCOUT_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_SG550: WeaponShootInfo2(id, iEnt, SG550_SHOOT, "SG550_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_SG552: WeaponShootInfo2(id, iEnt, SG552_SHOOT2, "SG552_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_TMP: WeaponShootInfo2(id, iEnt, TMP_SHOOT3, "TMP_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_UMP45: WeaponShootInfo2(id, iEnt, UMP45_SHOOT2, "UMP45_SHOOT_SOUND", 1, WEAPONTYPE_OTHER)
		case CSW_USP: WeaponShootInfo2(id, iEnt, USP_UNSIL_SHOOT3, "USP_SHOOT_SOUND", 1, WEAPONTYPE_USP)
	}
}

public WeaponShootInfo2(iPlayer, iEnt, iAnim, const szSoundFire[], iPlayAnim, iWeaponType)
{
	if(!is_user_connected(iPlayer) || is_nullent(iPlayer) || !IsPlayer(iPlayer, g_iMaxPlayers))
		return

	new iWID
	iWID = GetPlayerActiveItem(iPlayer)

	static szSound[128]

	new WeaponState:iWeaponState = get_member(iWID, m_Weapon_iWeaponState)

	TrieGetString(g_tWeaponSounds, szSoundFire, szSound, charsmax(szSound))

	if(!iWeaponState)
	{
		PlayWeaponState(iPlayer, szSound, iAnim)
		return
	}

	switch(iWeaponType)
	{
		case WEAPONTYPE_ELITE:
		{
			if(iWeaponState & WPNSTATE_ELITE_LEFT)
			{
				TrieGetString(g_tWeaponSounds, "ELITE_SHOOT_SOUND", szSound, charsmax(szSound))

				PlayWeaponState(iPlayer, szSound, ELITE_SHOOTLEFT5)
			}
		}
		case WEAPONTYPE_GLOCK18:
		{
			if(iWeaponState & WPNSTATE_GLOCK18_BURST_MODE)
			{
				TrieGetString(g_tWeaponSounds, "GLOCK18_BURST_SOUND", szSound, charsmax(szSound))

				PlayWeaponState(iPlayer, szSound, GLOCK18_SHOOT2)
			}
		}
		case WEAPONTYPE_FAMAS:
		{
			if(iWeaponState & WPNSTATE_FAMAS_BURST_MODE)
			{
				TrieGetString(g_tWeaponSounds, "CLARION_BURST_SOUND", szSound, charsmax(szSound))

				PlayWeaponState(iPlayer, szSound, CLARION_SHOOT2)
			}
		}
		case WEAPONTYPE_M4A1:
		{
			if(iWeaponState & WPNSTATE_M4A1_SILENCED)
			{
				TrieGetString(g_tWeaponSounds, "M4A1_SILENT_SOUND", szSound, charsmax(szSound))

				PlayWeaponState(iPlayer, szSound, M4A1_SHOOT3)
			}
		}
		case WEAPONTYPE_USP: 
		{
			if(iWeaponState & WPNSTATE_USP_SILENCED)
			{
				TrieGetString(g_tWeaponSounds, "USP_SILENT_SOUND", szSound, charsmax(szSound))

				PlayWeaponState(iPlayer, szSound, USP_SHOOT3)
			}
		}
	}
}

PlayWeaponState(iPlayer, const szShootSound[], iWeaponAnim = -1)
{
	rh_emit_sound2(iPlayer, 0, CHAN_WEAPON, szShootSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	if(iWeaponAnim)
		SendWeaponAnim(iPlayer, iWeaponAnim)
}

GetPlayerActiveItem(id)
{
	return get_member(id, m_pActiveItem)
}

GetWeaponEntity(iEnt)
{
	return rg_get_iteminfo(iEnt, ItemInfo_iId)
}

SendWeaponAnim(iPlayer, iAnim = 0)
{
	if(!is_user_connected(iPlayer) || !IsPlayer(iPlayer, g_iMaxPlayers))
		return

	static iCount, iSpectator, iszSpectators[MAX_PLAYERS]

	static iWeapon 
	iWeapon = GetPlayerActiveItem(iPlayer)

	if(is_nullent(iWeapon))
		return

	static iBody

	iBody = csgor_get_user_body(iPlayer, cs_get_user_weapon(iPlayer))

	set_entvar(iWeapon, var_body, iBody)
	set_pev(iPlayer, pev_weaponanim, iAnim)

	if(is_user_alive(iPlayer))
		rg_weapon_send_animation(iPlayer, iAnim)

	if(pev(iPlayer, pev_iuser1))
		return

	get_players(iszSpectators, iCount, "bch")

	for(new i = 0; i < iCount; i++)
	{
		iSpectator = iszSpectators[i]

		if(pev(iSpectator, pev_iuser1) != OBS_IN_EYE || pev(iSpectator, pev_iuser2) != iPlayer || !is_user_connected(iSpectator)) 
			continue

		set_pev(iSpectator, pev_weaponanim, iAnim)

		// Cannot send rg_weapon_send_animation to dead players.
		message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, iSpectator)
		write_byte(iAnim)
		write_byte(iBody)
		message_end()
	}
}