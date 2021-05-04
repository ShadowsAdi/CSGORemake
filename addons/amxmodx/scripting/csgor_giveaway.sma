/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>

#define CSGO_TAG "[CS:GO Remake]"

#define PLUGIN  "[CS:GO Remake] Skin GiveAway"
#define VERSION "1.0"
#define AUTHOR  "Author"

new g_szSkin[64]
new g_iSkin
new g_cType
new bool:g_bJoined[MAX_PLAYERS + 1]
new g_iPlayersNum
new g_cCountDown
new bool:g_bOpened = true

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	create_cvar("csgor_giveaway_author", AUTHOR, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_CLIENTDLL)

	bind_pcvar_num(create_cvar("csgor_giveaway_stattrack", "1", FCVAR_NONE, "GiveAway a StatTrack skin?",
		.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0), g_cType)

	bind_pcvar_num(create_cvar("csgor_giveaway_countdown", "13", FCVAR_NONE, "Number of rounds when giveaway is finising.",
		.has_min = true, .min_val = 1.0), g_cCountDown)

	register_concmd("giveaway", "cmd_giveaway")
	register_clcmd("say /giveaway", "cmd_giveaway")

	register_event("HLTV", "ev_NewRound", "a", "1=0", "2=0");
}

public csgor_on_configs_executed(iSuccess)
{
	if(iSuccess)
	{
		g_iSkin = random(csgor_get_skins_num())
		csgor_get_skin_name(g_iSkin, g_szSkin, charsmax(g_szSkin))
		if(g_cType)
		{
			format(g_szSkin, charsmax(g_szSkin), "StatTrack %s", g_szSkin)
		}
	}
}

public client_putinserver(id)
{
	g_bJoined[id] = false
}

public cmd_giveaway(id)
{
	if(!csgor_is_user_logged(id))
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_LOGIN");
		return;
	}

	if(!g_bOpened)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_GIVEAWAY_CLOSED")
		return;
	}

	_ShowGiveawayMenu(id);
}

public _ShowGiveawayMenu(id)
{
	new szTemp[128]
	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_GIVEAWAY_MENU")
	new menu = menu_create(szTemp, "handle_giveaway_menu")

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_GIVEAWAY_SKIN", g_szSkin)
	menu_additem(menu, szTemp)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_GIVEAWAY_PLAYERS", g_iPlayersNum)
	menu_additem(menu, szTemp)

	formatex(szTemp, charsmax(szTemp), "\w%L^n", LANG_SERVER, "CSGOR_GIVEAWAY_COUNTDOWN", g_cCountDown)
	menu_additem(menu, szTemp)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, !g_bJoined[id] ? "CSGOR_GIVEAWAY_JOIN" : "CSGOR_GIVEAWAY_JOINED")
	menu_additem(menu, szTemp)

	menu_display(id, menu)
}

public handle_giveaway_menu(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{
		case 0, 1, 2:
		{
			_ShowGiveawayMenu(id)
		}
		case 3:
		{
			if(!g_bJoined[id])
			{
				g_bJoined[id] = true
				g_iPlayersNum += 1
				client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_GIVEAWAY_PLAYER_JOINED", id, g_szSkin)
			}
			_ShowGiveawayMenu(id)
		}
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public ev_NewRound()
{
	if(g_iPlayersNum > 0 && g_bOpened)
	{
		g_cCountDown -= 1

		if(g_cCountDown == 0)
		{
			new index = GetWinner()
			if(is_user_connected(index))
			{
				client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_GIVEAWAY_WON_BY", g_bJoined[index], g_szSkin)
				g_cType ? csgor_set_user_statt_skins(index, g_iSkin, 1) : csgor_set_user_skins(index, g_iSkin, 1)
				g_bOpened = false
			}
		}
	}
}

stock GetWinner()
{
	static iWinner = -1

	if(!g_iPlayersNum || iWinner)
	{
		return PLUGIN_HANDLED
	}

	new iPlayer, iPlayers[MAX_PLAYERS], iNum
	get_players(iPlayers, iNum, "ch")
	new iRand = random(iNum)

	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]

		if(!g_bJoined[iPlayer])
		{
			continue
		}

		iWinner = g_bJoined[iPlayers[iRand]]
	}

	return iWinner
}