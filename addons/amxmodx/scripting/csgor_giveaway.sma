/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>

#define CSGO_TAG "[CS:GO Remake]"

#define PLUGIN  "[CS:GO Remake] Skin GiveAway"
#define VERSION "1.1"
#define AUTHOR  "Shadows Adi"

enum _:SkinInfo
{
	iSkin,
	szSkin[64]
}

enum _:PlayerInfo
{
	bool:bJoined[MAX_PLAYERS + 1],
	iNum
}

enum _:CvarInfo
{
	iType = 0,
	iCountdown,
	iMinPlayers
}

new g_eCvars[CvarInfo]

new g_eSkin[SkinInfo]
new g_ePdata[PlayerInfo]
new bool:g_bOpened = true
new Array:g_aParticipants

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	create_cvar("csgor_giveaway_author", AUTHOR, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_CLIENTDLL)

	bind_pcvar_num(create_cvar("csgor_giveaway_stattrack", "1", FCVAR_NONE, "GiveAway a StatTrack skin?",
		.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0), g_eCvars[iType])

	bind_pcvar_num(create_cvar("csgor_giveaway_countdown", "13", FCVAR_NONE, "Number of rounds when giveaway is finising.",
		.has_min = true, .min_val = 1.0), g_eCvars[iCountdown])

	bind_pcvar_num(create_cvar("csgor_giveaway_minplayers", "2", FCVAR_NONE, "Number of required players to start a giveaway.",
		.has_min = true, .min_val = 2.0), g_eCvars[iMinPlayers])

	register_concmd("giveaway", "cmd_giveaway")
	register_clcmd("say /giveaway", "cmd_giveaway")

	register_event("HLTV", "ev_NewRound", "a", "1=0", "2=0");
}

public csgor_on_configs_executed(iSuccess)
{
	if(iSuccess)
	{
		g_eSkin[iSkin] = random(csgor_get_skins_num())
		csgor_get_skin_name(g_eSkin[iSkin], g_eSkin[szSkin], charsmax(g_eSkin[szSkin]))
		if(g_eCvars[iType])
		{
			format(g_eSkin[szSkin], charsmax(g_eSkin[szSkin]), "StatTrack %s", g_eSkin[szSkin])
		}
	}
}

public plugin_natives()
{
	g_aParticipants = ArrayCreate(1, 1)
}

public plugin_end()
{
	ArrayDestroy(g_aParticipants)
}

public client_putinserver(id)
{
	g_ePdata[bJoined][id] = false
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	if(g_ePdata[bJoined][id] && g_bOpened)
	{
		ArrayDeleteItem(g_aParticipants, ArrayFindValue(g_aParticipants, id))
		g_ePdata[iNum]--
		g_ePdata[bJoined][id] = false
	}
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
	if(!g_bOpened)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_GIVEAWAY_CLOSED")
		return;
	}

	new szTemp[128]
	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_GIVEAWAY_MENU")
	new menu = menu_create(szTemp, "handle_giveaway_menu")

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_GIVEAWAY_SKIN", g_eSkin[szSkin])
	menu_additem(menu, szTemp)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_GIVEAWAY_PLAYERS", g_ePdata[iNum])
	menu_additem(menu, szTemp)

	formatex(szTemp, charsmax(szTemp), "\w%L^n", LANG_SERVER, "CSGOR_GIVEAWAY_COUNTDOWN", g_eCvars[iCountdown])
	menu_additem(menu, szTemp)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, !g_ePdata[bJoined][id] ? "CSGOR_GIVEAWAY_JOIN" : "CSGOR_GIVEAWAY_JOINED")
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
			if(!g_ePdata[bJoined][id])
			{
				g_ePdata[bJoined][id] = true
				g_ePdata[iNum] += 1
				ArrayPushCell(g_aParticipants, id)
				client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_GIVEAWAY_PLAYER_JOINED", id, g_eSkin[szSkin])
			}
			_ShowGiveawayMenu(id)
		}
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public ev_NewRound()
{
	if(g_ePdata[iNum] >= g_eCvars[iMinPlayers] && g_bOpened)
	{
		g_eCvars[iCountdown]--

		if(g_eCvars[iCountdown] == 0)
		{
			new index = GetWinner()
			
			if(index != -1)
			{
				client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_GIVEAWAY_WON_BY", index, g_eSkin[szSkin])
				g_eCvars[iType] ? csgor_set_user_statt_skins(index, g_eSkin[iSkin], csgor_get_user_statt_skins(index, g_eSkin[iSkin]) + 1) : csgor_set_user_skins(index, g_eSkin[iSkin], csgor_get_user_skins(index, g_eSkin[iSkin]))
				g_bOpened = false
			}
		}
	}
}

stock GetWinner()
{
	static iWinner = -1

	if(g_ePdata[iNum] < g_eCvars[iMinPlayers])
	{
		return iWinner
	}

	new bool:bChoosen = false
	new iSize = ArraySize(g_aParticipants)
	new iRandom

	do 
	{
		iRandom = random_num(0, iSize - 1)
		iWinner = ArrayGetCell(g_aParticipants, iRandom)

		if(!is_user_connected(iWinner))
		{
			ArrayDeleteItem(g_aParticipants, iRandom)
			iSize--
		}
		else
		{
			bChoosen = true
			return iWinner
		}
	} 
	while(!bChoosen && iSize > 0)

	return -1
}
