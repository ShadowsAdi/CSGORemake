/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>
#include <reapi>

#define PLUGIN  "[CS:GO Remake] WarmUp Weapons"
#define AUTHOR  "Shadows Adi"

enum (+=33)
{
	TASK_WARM = 1920,
	TASK_GIVE_WEAPON
}

enum 
{
	TERRORIST_TEAM = 0,
	CT_TEAM,
	MAX_TEAMS
}

enum _:WarmWeapons
{
	szPrimary[32],
	szSecondary[32],
	iAmmo
}

new const g_szWarmWeapons[MAX_TEAMS][WarmWeapons] =
{
	// Here you can change the weapons. First section is for Terrorists equipment, second for CT
	//Example: 
	// {"here needs to be the primary weapon"}, {"here the secondary ( pistol )"}, { ammo }}
	{
		{"weapon_ak47"}, {"weapon_deagle"}, { 999 }
	},
	{
		{ "weapon_m4a1" }, {"weapon_deagle"}, { 999 }
	}
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	RegisterHookChain(RG_CSGameRules_PlayerSpawn, "RG_PlayerSpawn_Post", 1)
}

public RG_PlayerSpawn_Post(iPlayer)
{
	if(csgor_is_warmup() && is_user_alive(iPlayer))
	{
		set_task(1.0, "Task_Warmup", iPlayer + TASK_WARM)
	}
}

public Task_Warmup(iPlayer)
{
	iPlayer -= TASK_WARM

	if(csgor_is_warmup() && is_user_alive(iPlayer))
	{
		if(rg_get_user_armor(iPlayer) != 100)
		{
			rg_set_user_armor(iPlayer, 100, ARMOR_VESTHELM)
		}

		set_task(1.0, "task_give_weapon", iPlayer + TASK_GIVE_WEAPON)
	}
}

public task_give_weapon(id)
{
	id -= TASK_GIVE_WEAPON

	if(is_user_alive(id) && csgor_is_warmup())
	{
		new TeamName:m_Team = get_member(id, m_iTeam)

		switch(m_Team)
		{
			case TEAM_TERRORIST:
			{
				rg_give_item(id, g_szWarmWeapons[TERRORIST_TEAM][szPrimary], GT_REPLACE)
				rg_give_item(id, g_szWarmWeapons[TERRORIST_TEAM][szSecondary], GT_REPLACE)
				rg_set_user_bpammo(id, rg_get_weapon_info(g_szWarmWeapons[TERRORIST_TEAM][szPrimary], WI_ID), 999)
				rg_set_user_bpammo(id, rg_get_weapon_info(g_szWarmWeapons[TERRORIST_TEAM][szSecondary], WI_ID), 999)
			}
			case TEAM_CT:
			{
				rg_give_item(id, g_szWarmWeapons[CT_TEAM][szPrimary], GT_REPLACE)
				rg_give_item(id, g_szWarmWeapons[CT_TEAM][szSecondary], GT_REPLACE)
				rg_set_user_bpammo(id,  rg_get_weapon_info(g_szWarmWeapons[CT_TEAM][szPrimary], WI_ID), 999)
				rg_set_user_bpammo(id, rg_get_weapon_info(g_szWarmWeapons[CT_TEAM][szSecondary], WI_ID), 999)
			}
		}
	}

	return PLUGIN_HANDLED
}
