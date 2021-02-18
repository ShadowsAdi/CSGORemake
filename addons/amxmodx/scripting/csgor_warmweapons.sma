/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>
#include <reapi>

#define PLUGIN  "[CS:GO Remake] WarmUp Weapons"
#define VERSION "1.0"
#define AUTHOR  "Shadows Adi"

#define IsPlayer(%1) (1 <= %1 <= MAX_PLAYERS)

enum (+=33)
{
	TASK_WARM = 1920,
	TASK_GIVE_WEAPON
}

enum 
{
	TERRORIST_TEAM = 1,
	CT_TEAM
}

enum _:WarmWeapons
{
	szPrimary[32],
	szSecondary[32],
	iAmmo,
	Teams
}

new const g_szWarmWeapons[WarmWeapons] =
{
	// Here you can change the weapons.
	//Example: 
	// {"here needs to be the primary weapon", "here the secondary ( pistol )", ammo, Player_Team}
	{"weapon_ak47", "weapon_deagle", 999, TERRORIST_TEAM},
	{"weapon_m4a1", "weapon_deagle", 999, CT_TEAM}
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event_ex("HLTV", "event_NewRound", RegisterEvent_Global)
}

public event_NewRound()
{
	if(csgor_is_warmup())
	{
		new iPlayer, iPlayers[MAX_PLAYERS], iNum
		get_players(iPlayers, iNum)

		for(new i; i < iNum; i++)
		{
			iPlayer = iPlayers[i]

			set_task(2.0, "Task_Warmup", iPlayer + TASK_WARM)
		}
	}
}

public Task_Warmup(iPlayer)
{
	iPlayer -= TASK_WARM

	if(csgor_is_warmup() && IsPlayer(iPlayer))
	{
		if(!rg_get_user_armor(iPlayer))
		{
			rg_set_user_armor(iPlayer, 100, ARMOR_VESTHELM)
		}

		set_task(1.0, "task_give_weapon", iPlayer + TASK_GIVE_WEAPON)
	}
}

public task_give_weapon(id)
{
	id -= TASK_GIVE_WEAPON

	if(IsPlayer(id) && csgor_is_warmup())
	{
		new TeamName:m_Team = get_member(id, m_iTeam)
		new WeaponIdType:iWeaponID[3]

		iWeaponID[0] = rg_get_weapon_info(g_szWarmWeapons[szPrimary][TERRORIST_TEAM], WI_ID)
		iWeaponID[1] = rg_get_weapon_info(g_szWarmWeapons[szPrimary][CT_TEAM], WI_ID)
		iWeaponID[2] = rg_get_weapon_info(g_szWarmWeapons[szSecondary], WI_ID)

		switch(m_Team)
		{
			case TEAM_TERRORIST:
			{
				rg_give_item(id, g_szWarmWeapons[szPrimary][TERRORIST_TEAM], GT_REPLACE)
				rg_give_item(id, g_szWarmWeapons[szSecondary][TERRORIST_TEAM], GT_REPLACE)
				rg_set_user_bpammo(id, iWeaponID[0], 999)
				rg_set_user_bpammo(id, iWeaponID[2], 999)
			}
			case TEAM_CT:
			{
				rg_give_item(id, g_szWarmWeapons[szPrimary][CT_TEAM], GT_REPLACE)
				rg_give_item(id, g_szWarmWeapons[szSecondary][CT_TEAM], GT_REPLACE)
				rg_set_user_bpammo(id, iWeaponID[1], 999)
				rg_set_user_bpammo(id, iWeaponID[2], 999)
			}
		}
	}

	return PLUGIN_HANDLED
}