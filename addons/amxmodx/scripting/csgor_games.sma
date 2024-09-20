/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>
#include <reapi>
#include <unixtime>
#include <sqlx>

#define CSGO_TAG "[CS:GO Remake]"

#define PLUGIN  "[CS:GO Remake] Games"
#define AUTHOR  "Shadows Adi"

enum (+=2304)
{
	TASK_RAFFLE = 2321,
	TASK_JACKPOT,
	TASK_ROULLETTE_PRE,
	TASK_CHECKPROMO
}

enum _:Cvars
{
	iRaffleCost,
	iRaffleTimer,
	iJackpotTimer,
	Float:flRouletteCooldown,
	iCheckBonusType,
	szBonusValues[18],
	iTimeDelete,
	iPromoTime,
	szChatPrefix[20]
}

enum _:PromoCodeData
{
	szPromocode[32],
	iPromoUses,
	iPromoGift,
	iPromoActive
}

enum _:Items
{
	iItemID,
	iIsStattrack
}

enum 
{
	iNone = 0,
	iJackpot,
	iCoinflip
}

enum
{
	iNormal = 0,
	iStattrack,
}

new Array:g_aRaffle
new Array:g_aJackpotSkins
new Array:g_aJackpotUsers
new Array:g_aPromocodes

new g_iRedPoints[ MAX_PLAYERS + 1 ]
new g_iWhitePoints[ MAX_PLAYERS + 1 ]
new g_iYellowPoints[ MAX_PLAYERS + 1 ]
new g_iRoulleteNumbers[7][8]
new g_iRoulettePlayers
new g_iRouletteTime = 60
new g_iRouletteCost
new bool:g_bRoulettePlay

new g_iRafflePlayers
new g_iRafflePrize
new bool:g_bUserPlay[ MAX_PLAYERS + 1 ]
new g_iNextRaffleStart
new bool:g_bRaffleWork = true

new bool:g_bJackpotWork
new g_iUserJackpotItem[ MAX_PLAYERS + 1 ][Items]
new bool:g_bUserPlayJackpot[ MAX_PLAYERS + 1 ]
new g_iJackpotClose

new g_iCoinflipTarget[ MAX_PLAYERS + 1 ]
new g_iCoinflipItem[ MAX_PLAYERS + 1 ][ Items ]
new g_iCoinflipRequest[ MAX_PLAYERS + 1 ]
new bool:g_bCoinflipActive[ MAX_PLAYERS + 1 ]
new bool:g_bCoinflipSecond[ MAX_PLAYERS + 1 ]
new bool:g_bCoinflipAccept[ MAX_PLAYERS + 1 ]
new bool:g_bCoinflipWork

new g_szUserPromocode[ MAX_PLAYERS + 1 ][32]

new g_eCvars[Cvars]

new g_iMaxPlayers

new g_szUserLastIP[MAX_PLAYERS + 1][19], g_szSteamID[MAX_PLAYERS + 1][32]

new Handle:g_hSqlTuple
new g_szSqlError[512]
new Handle:g_iSqlConnection

new Array:g_aPlayerPromo[MAX_PLAYERS + 1]

public plugin_natives()
{
	g_aRaffle = ArrayCreate(1)
	g_aJackpotSkins = ArrayCreate(Items)
	g_aJackpotUsers = ArrayCreate(1)

	g_aPromocodes = ArrayCreate(PromoCodeData)
	
	for(new i = 1; i <= get_maxplayers(); i++)
	{
		g_aPlayerPromo[i] = ArrayCreate(32)
	}
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_concmd("games", "clcmd_say_games")
	register_clcmd("say /acceptcoin", "clcmd_say_accept_coin")
	register_clcmd("say /denycoin", "clcmd_say_deny_coin")
	register_clcmd("say /bonus", "clcmd_say_bonus")

	register_concmd("Promocode", "concmd_promocode")
	register_concmd("BetRed", "concmd_betred")
	register_concmd("BetWhite", "concmd_betwhite")
	register_concmd("BetYellow", "concmd_betyellow")

	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", 1)

	new pcvar = create_cvar("csgor_raffle_cost", "50", FCVAR_NONE, "Required points for joining the raffle", true, 1.0 )
	bind_pcvar_num(pcvar, g_eCvars[iRaffleCost])

	pcvar = create_cvar("csgor_raffle_timer", "180", FCVAR_NONE, "Every X seconds the raffle takes place.^n 1 minute = 60 seconds", true, 0.0 )
	bind_pcvar_num(pcvar, g_eCvars[iRaffleTimer])
	
	pcvar = create_cvar("csgor_jackpot_timer", "120", FCVAR_NONE, "After how many seconds the Jackpot starts.^n 1 minute = 60 seconds", true, 0.0 )
	bind_pcvar_num(pcvar, g_eCvars[iJackpotTimer])

	pcvar = create_cvar("csgor_roulette_cooldown", "300", FCVAR_NONE, "The interval when the roulette starts again^nThe value needs to be in seconds.^nIt's recommended that the value can be divided by 60", true, 1.0, false )
	bind_pcvar_float(pcvar, g_eCvars[flRouletteCooldown])

	pcvar = create_cvar("csgor_bonus_check_type", "0", FCVAR_NONE, "(0|1) Bonus check type.^n0 - By IP^n1 - By SteamID", true, 0.0, true, 1.0)
	bind_pcvar_num(pcvar, g_eCvars[iCheckBonusType])

	pcvar = create_cvar("csgor_bonus_random_range", "1 10 70 93", FCVAR_NONE, "(0|∞) Drop range for bonuses in the bonus menu.^nFirst two values: Min | Max for Cases, Dusts, Points drop.^nLast two values: Min | Max for Skins drop.", true, 0.0)
	bind_pcvar_string(pcvar, g_eCvars[szBonusValues], charsmax(g_eCvars[szBonusValues]))

	pcvar = create_cvar("csgor_bonus_time", "24", FCVAR_NONE, "After how long the player can receive the bonus again?^nValue must be in hours.", true, 1.0)
	bind_pcvar_num(pcvar, g_eCvars[iTimeDelete])

	pcvar = create_cvar("csgor_prune_promocodes", "7", FCVAR_NONE, "The time interval when the used promocode will be reset.^nRecommended value to be greater than 1", true, 0.0 )
	bind_pcvar_num(pcvar, g_eCvars[iPromoTime])

	bind_pcvar_string(get_cvar_pointer("csgor_chat_prefix"), g_eCvars[szChatPrefix], charsmax(g_eCvars[szChatPrefix]))

	AutoExecConfig(true, "csgo_remake", "csgor")

	RegisterHookChain(RG_RoundEnd, "RG_RoundEnd_Post", 1)

	g_iMaxPlayers = get_maxplayers()
}

public csgor_on_configs_executed(iSuccess)
{
	new Float:timer = float(g_eCvars[iRaffleTimer])

	set_task(timer, "TaskRunRaffle", TASK_RAFFLE, .flags = "b")

	g_iNextRaffleStart = g_eCvars[iRaffleTimer] + get_systime()

	for(new i; i < sizeof(g_iRoulleteNumbers); i++ )
	{
		formatex(g_iRoulleteNumbers[i], charsmax(g_iRoulleteNumbers[]), "\w0")
	}
}

public csgor_database_loaded()
{
	DatabaseConnect()
}

DatabaseConnect()
{
	csgor_get_database_connection(g_iSqlConnection, g_hSqlTuple)

	if(g_iSqlConnection == Empty_Handle)
	{
		log_to_file("csgor_games.log", "%s Failed to connect to database. Make sure databse settings are right!", PLUGIN)
		SQL_FreeHandle(g_iSqlConnection)

		return
	}

	InsertTable()
	set_task(5.0, "TaskCheckPromocodes", TASK_CHECKPROMO)
}

public TaskCheckPromocodes(iTaskID)
{
	if(!task_exists(TASK_CHECKPROMO))
		return

	new szQuery[100]

	new ePromocodes[PromoCodeData]

	for(new i; i < ArraySize(g_aPromocodes); i++)
	{
		ArrayGetArray(g_aPromocodes, i, ePromocodes)
		formatex(szQuery, charsmax(szQuery), "SELECT COUNT(*) as `Count` FROM csgor_promocodes WHERE `Promocode` = ^"%s^"", ePromocodes[szPromocode])

		new szData[2]
		szData[0] = i
		SQL_ThreadQuery(g_hSqlTuple, "QueryPromocodeUses", szQuery, szData, sizeof(szData))
	}

	set_task(20.0, "TaskCheckPromocodes", TASK_CHECKPROMO)
}

public QueryPromocodeUses(iFailState, Handle:iQuery, Error[], Errcode, szData[], iSize, Float:flQueueTime)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: 
		{
			log_to_file("csgor_games.log", "[SQL Error] Connection failed (%i): %s", Errcode, Error)
		}
		case TQUERY_QUERY_FAILED:
		{
			log_to_file("csgor_games.log", "[SQL Error] Query failed (%i): %s", Errcode, Error)
		}
	}

	if(SQL_NumResults(iQuery))
	{
		new iNum = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Count"))

		new ePromocodes[PromoCodeData]

		new iID = szData[0]

		ArrayGetArray(g_aPromocodes, iID, ePromocodes)

		if(ePromocodes[iPromoUses] <= iNum)
		{
			ePromocodes[iPromoActive] = 0

			ArraySetArray(g_aPromocodes, iID, ePromocodes)
		}
	}
}

InsertTable()
{
	new szQueryData[256]
	formatex(szQueryData, charsmax(szQueryData), "CREATE TABLE IF NOT EXISTS `csgor_promocodes` \
		(`ID` INT NOT NULL AUTO_INCREMENT,\
		`Name` VARCHAR(32) NOT NULL,\
		`Auth` VARCHAR(32) NOT NULL,\
		`Promocode` TEXT NOT NULL,\
		PRIMARY KEY(ID));")

	new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, szQueryData)

	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError))
		log_amx(g_szSqlError)
		SQL_FreeHandle(iQuery)

		return
	}
}

public RG_RoundEnd_Post()
{
	DestroyTask(TASK_JACKPOT)

	g_bJackpotWork = true
	g_bCoinflipWork = true

	set_task(float(g_eCvars[iJackpotTimer]), "task_Jackpot", TASK_JACKPOT, .flags = "b")

	g_iJackpotClose = get_systime() + g_eCvars[iJackpotTimer] 
}

public plugin_end()
{
	ArrayDestroy(g_aRaffle)
	ArrayDestroy(g_aJackpotSkins)
	ArrayDestroy(g_aJackpotUsers)

	ArrayDestroy(g_aPromocodes)

	for(new i = 1; i <= get_maxplayers(); i++)
	{
		ArrayDestroy(g_aPlayerPromo[i])
	}
}

public csgor_read_configuration_data(szBuffer[], FileSections:iSection, iLine)
{
	static ePromocodes[PromoCodeData], szPromocodeUsage[6], szPromocodeGift[4]
	if(iSection == FileSections:secPromocodes)
	{
		parse(szBuffer, ePromocodes[szPromocode], charsmax(ePromocodes[szPromocode]), szPromocodeUsage, charsmax(szPromocodeUsage), szPromocodeGift, charsmax(szPromocodeGift))

		ePromocodes[iPromoUses] = str_to_num(szPromocodeUsage)
		ePromocodes[iPromoGift] = szPromocodeGift[0]
		ePromocodes[iPromoActive] = 1

		ArrayPushArray(g_aPromocodes, ePromocodes)
	}
}

public client_putinserver(id)
{
	g_bCoinflipAccept[id] = false
	g_iCoinflipTarget[id] = 0
	g_iCoinflipItem[id][iItemID] = -1
	g_iCoinflipItem[id][iIsStattrack] = 0
	g_bCoinflipActive[id] = false
	g_iCoinflipRequest[id] = 0
	g_bCoinflipSecond[id] = false

	g_bUserPlay[id] = false
	g_iUserJackpotItem[id][iItemID] = -1
	g_iUserJackpotItem[id][iIsStattrack] = 0
	g_bUserPlayJackpot[id] = false

	g_iRedPoints[id] = 0
	g_iWhitePoints[id] = 0
	g_iYellowPoints[id] = 0

	g_szUserPromocode[id] = ""
	ArrayClear(g_aPlayerPromo[id])

	get_user_ip(id, g_szUserLastIP[id], charsmax(g_szUserLastIP[]) , 1)
	get_user_authid(id, g_szSteamID[id], charsmax(g_szSteamID[]))

	GetUserPromocodes(id)
}

GetUserPromocodes(id)
{
	new szQueryData[150], szCheckData[32]

	switch(g_eCvars[iCheckBonusType])
	{
		case 0:
		{
			copy(szCheckData, charsmax(szCheckData), g_szUserLastIP[id])
		}
		case 1:
		{
			copy(szCheckData, charsmax(szCheckData), g_szSteamID[id])
		}
	}

	formatex(szQueryData, charsmax(szQueryData), "SELECT `Promocode` FROM `csgor_promocodes` WHERE `Auth` = ^"%s^";", szCheckData)

	new szID[2]
	szID[0] = id

	SQL_ThreadQuery(g_hSqlTuple, "QueryPromocodeHandler", szQueryData, szID, sizeof(szID))
}

public QueryPromocodeHandler(iFailState, Handle:iQuery, Error[], Errcode, szData[], iSize, Float:flQueueTime)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: 
		{
			log_to_file("csgor_games.log", "[SQL Error] Connection failed (%i): %s", Errcode, Error)
		}
		case TQUERY_QUERY_FAILED:
		{
			log_to_file("csgor_games.log", "[SQL Error] Query failed (%i): %s", Errcode, Error)
		}
	}

	new id = szData[0];

	new szTemp[32]

	while(SQL_MoreResults(iQuery))
	{
		SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Promocode"), szTemp, charsmax(szTemp))

		ArrayPushString(g_aPlayerPromo[id], szTemp)

		SQL_NextRow(iQuery)
	} 
}

public RG_CBasePlayer_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return

	if (g_bJackpotWork && !csgor_is_warmup())
	{
		new time = g_iJackpotClose - get_systime()

		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_PLAY_JP", time / 60, time % 60)
	}
}

public clcmd_say_games(id)
{
	if(csgor_is_user_logged(id))
	{
		_ShowGamesMenu(id)
	}
	else
	{
		client_cmd(id, "say /reg")
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_MUST_LOGIN")
	}

	return PLUGIN_HANDLED
}

public _ShowGamesMenu(id)
{
	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_eCvars[szChatPrefix], LANG_SERVER, "CSGOR_GAMES_MENU")
	new menu = menu_create(temp, "games_menu_handler")

	new szItem[5]
	szItem[1] = 0

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_MM_RAFFLE", g_eCvars[iRaffleCost])
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, g_bRoulettePlay == true ? "CSGOR_GAME_ROULETTE_CLOSED" : "CSGOR_GAME_ROULETTE")
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GAME_JACKPOT")
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GAME_PROMOCODE")
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GAME_COINFLIP")
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GAME_BONUS")
	menu_additem(menu, temp, szItem)

	_DisplayMenu(id, menu)
}

public games_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			client_cmd(id, "say /menu")
		}

		return _MenuExit(menu)
	}

	switch (item)
	{
		case 0:
		{
			_ShowRaffleMenu(id)
		}
		case 1:
		{
			new points = csgor_get_user_points(id)

			if (points < g_iRouletteCost)
			{
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_POINTS", g_iRouletteCost - points)
				_ShowGamesMenu(id)
			}
			else
			{
				if (g_bRoulettePlay)
				{
					csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_ROULETTE_CLOSED", floatround(g_eCvars[flRouletteCooldown]))
					_ShowGamesMenu(id)
				}
				else
				{
					_ShowRouletteMenu(id)
				}
			}
		}
		case 2:
		{
			if (g_bJackpotWork)
			{
				_ShowJackpotMenu(id)
			}
			else
			{
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_JP_CLOSED", g_eCvars[iJackpotTimer])
			}
		}
		case 3:
		{
			_ShowPromocodeMenu(id)
		}
		case 4:
		{
			_ShowCoinflipMenu(id)
		}
		case 5:
		{
			_ShowBonusMenu(id)
		}
	}

	return _MenuExit(menu)
}

public _ShowRaffleMenu(id)
{
	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_eCvars[szChatPrefix], LANG_SERVER, "CSGOR_RAFFLE_MENU")
	new menu = menu_create(temp, "raffle_menu_handler")

	new szItem[2]
	szItem[1] = 0

	new Timer[32]

	_FormatTime(Timer, charsmax(Timer), g_iNextRaffleStart)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_RAFFLE_TIMER", Timer)
	szItem[0] = 0
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_RAFFLE_PLAYERS", g_iRafflePlayers)
	szItem[0] = 0
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_RAFFLE_PRIZE", g_iRafflePrize)
	szItem[0] = 0
	menu_additem(menu, temp, szItem)

	if (g_bUserPlay[id])
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_RAFFLE_ALREADY_PLAY")
		szItem[0] = 0
		menu_additem(menu, temp, szItem)
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L^n\w%L", LANG_SERVER, "CSGOR_RAFFLE_PLAY", LANG_SERVER, "CSGOR_RAFFLE_COST", g_eCvars[iRaffleCost])
		szItem[0] = 1
		menu_additem(menu, temp, szItem)
	}

	_DisplayMenu(id, menu)
}

public raffle_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id) || !csgor_is_user_logged(id))
		return _MenuExit(menu)

	new szInfo[2]
	new iIndex

	menu_item_getinfo(menu, item, .info = szInfo, .infolen = charsmax(szInfo))

	iIndex = szInfo[0]

	switch (iIndex)
	{
		case 0:
		{
			_ShowRaffleMenu(id)
		}
		case 1:
		{
			new uPoints = csgor_get_user_points(id)

			if (!g_bRaffleWork)
			{
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_RAFFLE_NOT_WORK")
			}
			else
			{
				new szName[MAX_NAME_LENGTH]
				csgor_get_user_name(id, szName, charsmax(szName))

				if (g_eCvars[iRaffleCost] > uPoints)
				{
					csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_POINTS", g_eCvars[iRaffleCost] - uPoints)
					_ShowRaffleMenu(id)

					return _MenuExit(menu)
				}
				csgor_set_user_points(id, csgor_get_user_points(id) - g_eCvars[iRaffleCost]) 
				g_iRafflePrize = g_eCvars[iRaffleCost] + g_iRafflePrize
				g_bUserPlay[id] = true; 

				ArrayPushCell(g_aRaffle, id)

				g_iRafflePlayers += 1

				csgor_save_user_data(id)

				csgor_send_message(0, "^1%L", LANG_SERVER, "CSGOR_RAFFLE_ANNOUNCE", szName)

				_ShowRaffleMenu(id)
			}
		}
	}

	return _MenuExit(menu)
}

public TaskRunRaffle(task)
{
	if (g_iRafflePlayers < 1)
	{
		csgor_send_message(0, "^1%L", LANG_SERVER, "CSGOR_RAFFLE_FAIL_REG")
	}
	else
	{
		if (g_iRafflePlayers < 2)
		{
			new id = ArrayGetCell(g_aRaffle, 0)

			if(is_user_connected(id) && csgor_is_user_logged(id))
			{
				csgor_set_user_points(id, csgor_get_user_points(id + g_eCvars[iRaffleCost]))
				g_bUserPlay[id] = false
			}

			csgor_send_message(0, "^1%L", LANG_SERVER, "CSGOR_RAFFLE_FAIL_NUM")
		}

		new id
		new size = ArraySize(g_aRaffle)
		new bool:succes
		new random
		new run

		new szName[MAX_NAME_LENGTH]

		do 
		{
			random = random_num(0, size - 1)
			id = ArrayGetCell(g_aRaffle, random)

			if(is_user_connected(id))
			{
				succes = true
				csgor_set_user_points(id, csgor_get_user_points(id) + g_iRafflePrize)

				if(csgor_is_user_logged(id))
				{
					csgor_save_user_data(id)
				}

				csgor_get_user_name(id, szName, charsmax(szName))

				csgor_send_message(0, "^1%L", LANG_SERVER, "CSGOR_RAFFLE_WINNER", szName, g_iRafflePrize)
			}
			else
			{
				ArrayDeleteItem(g_aRaffle, random)

				size--
			}

			if (!succes && size > 0)
			{
			}
		} while (run)
	}

	arrayset(g_bUserPlay, false, sizeof(g_bUserPlay))

	g_iRafflePlayers = 0
	g_iRafflePrize = 0

	ArrayClear(g_aRaffle)

	g_iNextRaffleStart = g_eCvars[iRaffleTimer] + get_systime()

	new Timer[32]

	_FormatTime(Timer, charsmax(Timer), g_iNextRaffleStart)
	csgor_send_message(0, "^1%L", LANG_SERVER, "CSGOR_RAFFLE_NEXT", Timer)
}

_RoulettePlay()
{
	g_iRouletteTime = 60

	csgor_send_message(0, " ^1%L", LANG_SERVER, "CSGOR_ROULETTE_PLAY", g_iRouletteTime)

	set_task(1.0, "task_check_roulette", TASK_ROULLETTE_PRE, .flags = "b")
}

public task_check_roulette()
{
	if(g_iRouletteTime != 0)
	{
		g_iRouletteTime--
	}
	else
	{
		new random = random_num(0, 100)

		if(0 <= random < 49)
		{
			for(new i = 1; i <= MAX_PLAYERS; i++)
			{
				g_iRedPoints[i] *= 2
				g_iYellowPoints[i] = 0
				g_iWhitePoints[i] = 0

				if(is_user_connected(i))
				{
					csgor_set_user_points(i, csgor_get_user_points(i) + g_iRedPoints[i] + g_iYellowPoints[i] + g_iWhitePoints[i])
				}

				g_iRedPoints[i] = 0
			}

			csgor_send_message(0, " ^1%L.", LANG_SERVER, "CSGOR_ROULETTE_COLOR", random, LANG_SERVER, "CSGOR_ROULETTE_RED")
		}
		else if(53 <= random)
		{
			for(new i = 1; i <= MAX_PLAYERS; i++)
			{
				g_iRedPoints[i] = 0
				g_iYellowPoints[i] = 0
				g_iWhitePoints[i] *= 2

				if(is_user_connected(i))
				{
					csgor_set_user_points(i, csgor_get_user_points(i) + g_iRedPoints[i] + g_iYellowPoints[i] + g_iWhitePoints[i])
				}

				g_iWhitePoints[i] = 0
			}

			csgor_send_message(0, " ^1%L.", LANG_SERVER, "CSGOR_ROULETTE_COLOR", random, LANG_SERVER, "CSGOR_ROULETTE_WHITE")
		}
		else if(49 <= random <= 52)
		{
			for(new i = 1; i <= MAX_PLAYERS; i++)
			{
				g_iRedPoints[i] = 0
				g_iYellowPoints[i] *= 14
				g_iWhitePoints[i] = 0

				if(is_user_connected(i))
				{
					csgor_set_user_points(i, csgor_get_user_points(i) + g_iRedPoints[i] + g_iYellowPoints[i] + g_iWhitePoints[i])
				}

				g_iYellowPoints[i] = 0
			}

			csgor_send_message(0, " ^1%L.", LANG_SERVER, "CSGOR_ROULETTE_COLOR", random, LANG_SERVER, "CSGOR_ROULETTE_YELLOW")
		}

		FormatRoulette(random)

		g_iRoulettePlayers = 0

		set_task(g_eCvars[flRouletteCooldown], "task_Check_Roulette_Post")

		new cooldown = floatround(g_eCvars[flRouletteCooldown])
		csgor_send_message(0, " ^1%L", LANG_SERVER, "CSGOR_ROULETTE_CLOSED_FOR", cooldown)

		DestroyTask(TASK_ROULLETTE_PRE)

		g_bRoulettePlay = true
	}
}

FormatRoulette(iRand)
{
	for(new i; i < charsmax(g_iRoulleteNumbers); i++)
	{
		formatex(g_iRoulleteNumbers[i+1], charsmax(g_iRoulleteNumbers[]), "%s", g_iRoulleteNumbers[i])
	}

	formatex(g_iRoulleteNumbers[0], charsmax(g_iRoulleteNumbers[]), "\w%d", iRand)
}

public task_Check_Roulette_Post()
{
	g_bRoulettePlay = false
	g_iRouletteTime = 60

	csgor_send_message(0, " ^1%L", LANG_SERVER, "CSGOR_ROULETTE_OPEN")
}

public _ShowRouletteMenu(id)
{
	new Temp[512]
	new LastNR[128]

	formatex(LastNR, charsmax(LastNR), "^n\w%L", LANG_SERVER, "CSGOR_LAST_NUMBERS", g_iRoulleteNumbers[0], g_iRoulleteNumbers[1], g_iRoulleteNumbers[2], g_iRoulleteNumbers[3], g_iRoulleteNumbers[4], g_iRoulleteNumbers[5], g_iRoulleteNumbers[6] )
	
	if(!g_iRedPoints[id] && !g_iWhitePoints[id] && !g_iYellowPoints[id])
	{
		if(g_iRoulettePlayers >= 2 && g_iRouletteTime >= 5)
			formatex(Temp, charsmax(Temp), "\w%L \y%s", LANG_SERVER, "CSGOR_ROULETTE_MENU_ON_IN", g_iRouletteTime, LastNR)
		else
			formatex(Temp, charsmax(Temp), "\w%L \y%s", LANG_SERVER, "CSGOR_ROULETTE_MENU_ROLLING", LastNR)
	}
	else
	{
		if(g_iRoulettePlayers >= 2 && g_iRouletteTime >= 5)
			formatex(Temp, charsmax(Temp), "\w%L \y%s", LANG_SERVER, "CSGOR_ROULETTE_MENU_COLORS_ON_IN", g_iRouletteTime, LastNR)
		else
			formatex(Temp, charsmax(Temp), "\w%L \y%s", LANG_SERVER, "CSGOR_ROULETTE_MENU_DECISION_COLORS_ROLLING", LastNR)
	}

	new Menu = menu_create(Temp, "roulette_menu_handler")
	
	new iRed, iYellow, iWhite
	new iPlayers[MAX_PLAYERS], iPlayer, iNum

	get_players(iPlayers, iNum, "ch")

	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]

		iRed += g_iRedPoints[iPlayer]
		iYellow += g_iYellowPoints[iPlayer]
		iWhite += g_iWhitePoints[iPlayer]
	}

	formatex(Temp, charsmax(Temp), "\w%L", LANG_SERVER, "CSGOR_ROULETTE_BET_RED", iRed)
	menu_additem(Menu, Temp, "1")

	formatex(Temp, charsmax(Temp), "\w%L", LANG_SERVER, "CSGOR_ROULETTE_BET_YELLOW", iYellow)
	menu_additem(Menu, Temp, "2")

	formatex(Temp, charsmax(Temp), "\w%L", LANG_SERVER, "CSGOR_ROULETTE_BET_WHITE", iWhite)
	menu_additem(Menu, Temp, "3")

	formatex(Temp, charsmax(Temp), "\w%L", LANG_SERVER, "CSGOR_ROULETTE_REFRESH")
	menu_additem(Menu, Temp, "4")

	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)

	_DisplayMenu(id, Menu)
}

public roulette_menu_handler(id, menu, item) 
{ 
	if(item == MENU_EXIT || !is_user_connected(id))
		return _MenuExit(menu)
	
	new szData[6]
	menu_item_getinfo(menu, item, .info = szData, .infolen = charsmax(szData))
	new iKey = str_to_num(szData)

	switch(iKey)
	{ 
		case 1:
		{
			client_cmd(id, "messagemode BetRed")
		}
		case 2:
		{
			client_cmd(id, "messagemode BetYellow")
		}
		case 3:
		{
			client_cmd(id, "messagemode BetWhite")
		}
		case 4:
		{
			_ShowRouletteMenu(id)
		}
	} 

	return PLUGIN_HANDLED
}


public _ShowJackpotMenu(id)
{
	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_eCvars[szChatPrefix], LANG_SERVER, "CSGOR_JACKPOT_MENU")
	new menu = menu_create(temp, "jackpot_menu_handler", 0)

	new szItem[2]
	szItem[1] = 0

	if (!_IsGoodItem(g_iUserJackpotItem[id][iItemID]))
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_SKINS")
		szItem[0] = 1
		menu_additem(menu, temp, szItem)
	}
	else
	{
		new Item[MAX_SKIN_NAME]
		_GetItemName(g_iUserJackpotItem[id][iItemID], Item, charsmax(Item))
		if(g_iUserJackpotItem[id][iIsStattrack])
		{
			FormatStattrack(Item, charsmax(Item))
		}

		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_JP_ITEM", Item)
		szItem[0] = 1
		menu_additem(menu, temp, szItem)
	}

	if (g_bUserPlayJackpot[id])
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_JP_ALREADY_PLAY")
		szItem[0] = 0
		menu_additem(menu, temp, szItem)
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_JP_PLAY")
		szItem[0] = 2
		menu_additem(menu, temp, szItem)
	}

	new Timer[32]

	_FormatTime(Timer, charsmax(Timer), g_iJackpotClose)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_RAFFLE_TIMER", Timer)
	szItem[0] = 0
	menu_additem(menu, temp, szItem)

	_DisplayMenu(id, menu)
}

public jackpot_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGamesMenu(id)
		}

		return _MenuExit(menu)
	}

	new szInfo[2]
	new iIndex

	menu_item_getinfo(menu, item, .info = szInfo, .infolen = charsmax(szInfo))

	iIndex = szInfo[0]

	if (!g_bJackpotWork)
	{
		_ShowGamesMenu(id)
		return _MenuExit(menu)
	}
	switch (iIndex)
	{
		case 0:
		{
			_ShowJackpotMenu(id)
		}
		case 1:
		{
			if (g_bUserPlayJackpot[id])
			{
				_ShowJackpotMenu(id)
			}
			else
			{
				_SelectJackpotSkin(id)
			}
		}
		case 2:
		{
			new skin = g_iUserJackpotItem[id][iItemID]

			if (!_IsGoodItem(skin))
			{
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_SKINS")
				_ShowJackpotMenu(id)
			}
			else
			{
				new szName[MAX_NAME_LENGTH]
				csgor_get_user_name(id, szName, charsmax(szName))
				if (!csgor_user_has_item(id, skin, g_iUserJackpotItem[id][iIsStattrack]))
				{
					csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_ITEMS")
					g_iUserJackpotItem[id][iItemID] = -1
				}

				g_bUserPlayJackpot[id] = true
				new iNum

				switch(g_iUserJackpotItem[id][iIsStattrack])
				{
					case 0:
					{
						iNum = csgor_get_user_skins(id, skin)
						csgor_set_user_skins(id, skin, iNum ? iNum - 1 : 0)
					}
					case 1:
					{
						iNum = csgor_get_user_statt_skins(id, skin)
						csgor_set_user_statt_skins(id, skin, iNum ? iNum - 1 : 0)
					}
				}

				new eJackpot[Items]
				eJackpot[iItemID] = skin
				eJackpot[iIsStattrack] = g_iUserJackpotItem[id][iIsStattrack]

				ArrayPushArray(g_aJackpotSkins, eJackpot)
				ArrayPushCell(g_aJackpotUsers, id)

				new szItem[MAX_SKIN_NAME]

				_GetItemName(skin, szItem, charsmax(szItem))

				if(g_iUserJackpotItem[id][iIsStattrack])
				{
					FormatStattrack(szItem, charsmax(szItem))
				}

				csgor_send_message(0, " %L", LANG_SERVER, "CSGOR_JP_JOIN", szName, szItem)
			}
		}
	}

	return _MenuExit(menu)
}

_ShowNormalSkinsMenu(id, iSpecial = iNone)
{
	new szTemp[128]
	new szWeapon[32], szWeaponID[4]
	new szItem[10]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_eCvars[szChatPrefix], LANG_SERVER, "CSGOR_SKIN_MENU")
	new menu = menu_create(szTemp, "skins_normal_menu_handler")

	for(new i; i < csgor_get_dyn_menu_num() ; i++)
	{
		csgor_get_dyn_menu_item(i, szWeapon, szWeaponID)

		formatex(szTemp, charsmax(szTemp), "%s [\r%d\w/\r%d\w]",  szWeapon, csgor_get_user_skinsnum(id, str_to_num(szWeaponID)), GetMaxSkins(str_to_num(szWeaponID)))
		formatex(szItem, charsmax(szItem), "%d,%d", str_to_num(szWeaponID), iSpecial)
		menu_additem(menu, szTemp, szItem)
	}

	_DisplayMenu(id, menu)
}

public skins_normal_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGamesMenu(id)
		}

		return _MenuExit(menu)
	}

	new data[10], szSplit[2][3]
	new index

	menu_item_getinfo(menu, item, .info = data, .infolen = sizeof(data))

	strtok(data, szSplit[0], charsmax(szSplit[]), szSplit[1], charsmax(szSplit[]), ',')

	index = str_to_num(szSplit[0])

	_ShowSortedSkins(id, index, iNormal, str_to_num(szSplit[1]))

	return _MenuExit(menu)
}

_ShowStattrackSkinsMenu(id, iSpecial = iNone)
{
	new szTemp[128]
	new szWeapon[32], szWeaponID[4]
	new szItem[10]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_eCvars[szChatPrefix], LANG_SERVER, "CSGOR_SKIN_MENU")
	new menu = menu_create(szTemp, "skins_stattrack_menu_handler")

	for(new i; i < csgor_get_dyn_menu_num() ; i++)
	{
		csgor_get_dyn_menu_item(i, szWeapon, szWeaponID)

		formatex(szTemp, charsmax(szTemp), "\y(StatTrack)\w %s [\r%d\w/\r%d\w]", szWeapon, csgor_get_user_skinsnum(id, str_to_num(szWeaponID), true), GetMaxSkins(str_to_num(szWeaponID)))
		formatex(szItem, charsmax(szItem), "%d,%d", str_to_num(szWeaponID), iSpecial)
		menu_additem(menu, szTemp, szItem)
	}

	_DisplayMenu(id, menu)
}

public skins_stattrack_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGamesMenu(id)
		}

		return _MenuExit(menu)
	}

	new data[10], szSplit[2][5]
	new index

	menu_item_getinfo(menu, item, .info = data, .infolen = sizeof(data))

	strtok(data, szSplit[0], charsmax(szSplit[]), szSplit[1], charsmax(szSplit[]), ',')

	index = str_to_num(szSplit[0])

	_ShowSortedSkins(id, index, iStattrack, str_to_num(szSplit[1]))

	return _MenuExit(menu)
}

_ShowSortedSkins(id, iItem, iMenu, iSpecial = iNone)
{
	new szTemp[82], szFormatted[64]
	new szItem[9], bool:hasSkins, iWID

	formatex(szFormatted, charsmax(szFormatted), "\w%L", LANG_SERVER, iMenu == iNormal ? "CSGOR_SKIN_MENU" : "CSGOR_SKIN_STT_MENU")

	formatex(szTemp, charsmax(szTemp), "\r%s \w%s", g_eCvars[szChatPrefix], szFormatted)

	new menu

	switch(iSpecial)
	{
		case iJackpot:
		{
			menu = menu_create(szTemp, "jp_skins_menu_handler")
		}
		case iCoinflip:
		{
			menu = menu_create(szTemp, "cf_skins_menu_handler")
		}
	}

	static eSkinData[SkinData], ePlayerSkins[PlayerSkins]

	new iFound = -1

	for (new i; i < csgor_get_skins_num(); i++)
	{
		iFound = csgor_get_user_skin_data(id, i, iMenu, ePlayerSkins)

		if(0 < ePlayerSkins[iPieces])
		{
			if(iFound < 0 || ePlayerSkins[iSkinid] != i)
				continue

			csgor_get_skin_data(i, eSkinData)

			iWID = ePlayerSkins[iWeaponid]

			if (iItem != iWID)
				continue
		
			if(ePlayerSkins[isStattrack])
			{
				FormatStattrack(eSkinData[szSkinName], charsmax(eSkinData[szSkinName]))
			}

			formatex(szTemp, charsmax(szTemp), "%s%s\w| \y%L", iMenu == iNormal ? (eSkinData[iSkinType] == 'd' ? "\r" : "\w") : "\w", eSkinData[szSkinName], LANG_SERVER, "CSGOR_SM_PIECES", ePlayerSkins[iPieces])
			formatex(szItem, charsmax(szItem), "%d;%d", i, ePlayerSkins[isStattrack])
			menu_additem(menu, szTemp, szItem)

			hasSkins = true
		}
	}
	
	if (!hasSkins)
	{
		formatex(szTemp, charsmax(szTemp), "\r%L", LANG_SERVER, "CSGOR_SM_NO_SKINS")
		num_to_str(-10, szItem, charsmax(szItem))
		format(szItem, charsmax(szItem), "%s;%d", szItem, iMenu)
		menu_additem(menu, szTemp, szItem)
	}

	_DisplayMenu(id, menu)
}

public _SelectJackpotSkin(id)
{
	new szTemp[64]
	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_eCvars[szChatPrefix], LANG_SERVER, "CSGOR_SKINS")

	new menu = menu_create(szTemp, "jp_select_menu_handler", 0)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_NORMAL_SKIN_MENU")
	menu_additem(menu, szTemp)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_STATTRACK_SKIN_MENU")
	menu_additem(menu, szTemp)

	_DisplayMenu(id, menu)
}

public jp_select_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowJackpotMenu(id)
		}

		return _MenuExit(menu)
	}

	switch(item)
	{
		case 0:
		{
			_ShowNormalSkinsMenu(id, iJackpot)
		}
		case 1:
		{
			_ShowStattrackSkinsMenu(id, iJackpot)
		}
	}

	return _MenuExit(menu)
}

public jp_skins_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowJackpotMenu(id)
		}
		return _MenuExit(menu)
	}

	new data[8], szName[MAX_SKIN_NAME]
	new index
	new szSplit[2][6]

	menu_item_getinfo(menu, item, .info = data, .infolen = sizeof(data), .name = szName, .namelen = sizeof(szName))

	strtok(data, szSplit[0], sizeof(szSplit[]), szSplit[1], sizeof(szSplit[]), ';')

	index = str_to_num(szSplit[0])

	if (index == -10)
	{
		_ShowJackpotMenu(id)
		return _MenuExit(menu)
	}
	else
	{
		new szItem[MAX_SKIN_NAME], iLocked, iStt = str_to_num(szSplit[1])

		_GetItemName(index, szItem, charsmax(szItem), iLocked)

		if(iStt)
		{
			FormatStattrack(szItem, charsmax(szItem))
		}

		if(csgor_is_item_skin(index))
		{
			if(iLocked)
			{
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_ITEM_LOCKED", szItem)
				_ShowJackpotMenu(id)

				return _MenuExit(menu)
			}
		}
		
		g_iUserJackpotItem[id][iItemID] = index
		g_iUserJackpotItem[id][iIsStattrack] = iStt
	}

	_ShowJackpotMenu(id)

	return _MenuExit(menu)
}

public task_Jackpot()
{
	if (!g_bJackpotWork)
		return

	new id
	new size = ArraySize(g_aJackpotUsers)

	if (1 > size)
	{
		csgor_send_message(0, " %L", LANG_SERVER, "CSGOR_JP_NO_ONE")
		_ClearJackpot()

		return
	}
	if (2 > size)
	{
		csgor_send_message(0, " %L", LANG_SERVER, "CSGOR_JP_ONLY_ONE")

		new id
		new eJackpot[Items]

		id = ArrayGetCell(g_aJackpotUsers, 0)

		if (0 < id && 32 >= id || !is_user_connected(id))
		{
			ArrayGetArray(g_aJackpotSkins, 0, eJackpot)

			switch(eJackpot[iIsStattrack])
			{
				case 0:
				{
					if(csgor_user_has_item(id, eJackpot[iItemID], 0))
					{
						csgor_set_user_skins(id, eJackpot[iItemID], csgor_get_user_skins(id, eJackpot[iItemID]) + 1)
					}
					else 
					{
						csgor_set_user_skins(id, eJackpot[iItemID], 1)
					}
				}
				case 1:
				{
					if(csgor_user_has_item(id, eJackpot[iItemID], eJackpot[iIsStattrack]))
					{
						csgor_set_user_statt_skins(id,  eJackpot[iItemID], csgor_get_user_statt_skins(id, eJackpot[iItemID]) + 1)
					}
					else
					{
						csgor_set_user_statt_skins(id, eJackpot[iItemID], 1)
					}
				}
			}
		}

		_ClearJackpot()

		return
	}

	new bool:succes
	new random
	new run
	new szName[MAX_NAME_LENGTH]

	do 
	{
		random = random_num(0, size - 1)
		id = ArrayGetCell(g_aJackpotUsers, random)

		if (0 < id && 32 >= id || !is_user_connected(id))
		{
			succes = true

			new i
			new eJackpot[Items]

			i = ArraySize(g_aJackpotSkins)

			for (new j; j < i; j++)
			{
				ArrayGetArray(g_aJackpotSkins, j, eJackpot)

				switch(eJackpot[iIsStattrack])
				{
					case 0:
					{
						if(csgor_user_has_item(id, eJackpot[iItemID], 0))
						{
							csgor_set_user_skins(id, eJackpot[iItemID], csgor_get_user_skins(id, eJackpot[iItemID]) + 1)
						}
						else 
						{
							csgor_set_user_skins(id, eJackpot[iItemID], 1)
						}
					}
					case 1:
					{
						if(csgor_user_has_item(id, eJackpot[iItemID], eJackpot[iIsStattrack]))
						{
							csgor_set_user_statt_skins(id,  eJackpot[iItemID], csgor_get_user_statt_skins(id, eJackpot[iItemID]) + 1)
						}
						else
						{
							csgor_set_user_statt_skins(id, eJackpot[iItemID], 1)
						}
					}
				}
			}

			if(csgor_is_user_logged(id))
			{
				csgor_save_user_data(id)
			}

			csgor_get_user_name(id, szName, charsmax(szName))

			csgor_send_message(0, " %L", LANG_SERVER, "CSGOR_JP_WINNER", szName)
		}
		else
		{
			ArrayDeleteItem(g_aJackpotUsers, random)

			size--
		}
		if (!(!succes && size > 0))
		{
			_ClearJackpot()

			return
		}
	} while (run)

	_ClearJackpot()
}

public concmd_promocode(id)
{
	new data[32]
	read_args(data, charsmax(data))
	remove_quotes(data)

	if (equal(data, ""))
	{
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_PROMOCODE_NOT_VALID")
		client_cmd(id, "messagemode Promocode")
		return PLUGIN_HANDLED
	}

	g_szUserPromocode[id] = data
	_ShowPromocodeMenu(id)

	return PLUGIN_HANDLED
}

public concmd_betred(id)
{
	if(!csgor_is_user_logged(id) || g_iRedPoints[id] || g_iWhitePoints[id] || g_iYellowPoints[id])
		return PLUGIN_HANDLED
		
	if(g_bRoulettePlay)
	{
		new cooldown = floatround(g_eCvars[flRouletteCooldown])
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BET_WHILE_ROULETTE_ACTIVE", cooldown)
		return PLUGIN_HANDLED
	}

	new data[32], amount
	read_args(data, charsmax(data))
	remove_quotes(data)
	
	amount = str_to_num(data)
	
	if(amount <= 0 || amount > csgor_get_user_points(id) || amount == 0)
	{
		client_cmd(id, "messagemode BetRed")
		return PLUGIN_HANDLED
	}
	
	g_iRedPoints[id] = amount
	csgor_set_user_points(id, csgor_get_user_points(id) - amount)

	_ShowRouletteMenu(id)

	g_iRoulettePlayers++

	if(g_iRoulettePlayers == 2 && g_iRouletteTime == 60)
		_RoulettePlay()
	
	return PLUGIN_HANDLED
}

public concmd_betwhite(id)
{
	if(!csgor_is_user_logged(id) || g_iRedPoints[id] || g_iWhitePoints[id] || g_iYellowPoints[id])
		return PLUGIN_HANDLED
	
	if(g_bRoulettePlay)
	{
		new cooldown = floatround(g_eCvars[flRouletteCooldown])
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BET_WHILE_ROULETTE_ACTIVE", cooldown)
		return PLUGIN_HANDLED
	}

	new data[32], amount
	read_args(data, charsmax(data))
	remove_quotes(data)
	
	amount = str_to_num(data)
	
	if(amount <= 0 || amount > csgor_get_user_points(id) || amount == 0)
	{
		client_cmd(id, "messagemode BetWhite")
		return PLUGIN_HANDLED
	}
	
	g_iWhitePoints[id] = amount
	csgor_set_user_points(id, csgor_get_user_points(id) - amount)

	_ShowRouletteMenu(id)

	g_iRoulettePlayers++

	if(g_iRoulettePlayers == 2 && g_iRouletteTime == 60)
		_RoulettePlay()
			
	return PLUGIN_HANDLED
}

public concmd_betyellow(id)
{
	if(!csgor_is_user_logged(id) || g_iRedPoints[id] || g_iWhitePoints[id] || g_iYellowPoints[id])
		return PLUGIN_HANDLED

	if(g_bRoulettePlay)
	{
		new cooldown = floatround(g_eCvars[flRouletteCooldown])
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BET_WHILE_ROULETTE_ACTIVE", cooldown)
		return PLUGIN_HANDLED
	}

	new data[32], amount
	read_args(data, charsmax(data))
	remove_quotes(data)
	
	amount = str_to_num(data)
	
	if(amount <= 0 || amount > csgor_get_user_points(id) || amount == 0)
	{
		client_cmd(id, "messagemode BetYellow")
		return PLUGIN_HANDLED
	}

	g_iYellowPoints[id] = amount
	csgor_set_user_points(id, csgor_get_user_points(id) - amount)

	_ShowRouletteMenu(id)

	g_iRoulettePlayers++

	if(g_iRoulettePlayers == 2 && g_iRouletteTime == 60)
		_RoulettePlay()

	return PLUGIN_HANDLED
}

public _ShowPromocodeMenu(id)
{
	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_eCvars[szChatPrefix], LANG_SERVER, "CSGOR_PROMOCODE_MENU")
	new menu = menu_create(temp, "promocode_menu_handler")

	new szItem[2]
	szItem[1] = 0

	formatex(temp, charsmax(temp), "\w%L \w%s^n", LANG_SERVER, "CSGOR_PROMOCODE_CODE", g_szUserPromocode[id])
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_PROMOCODE_GET")
	menu_additem(menu, temp, szItem)
	
	_DisplayMenu(id, menu)
}

public promocode_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGamesMenu(id)
		}

		return _MenuExit(menu)
	}
	
	switch(item)
	{
		case 0:
		{
			csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_PROMOCODE_INSERT")
			client_cmd(id, "messagemode Promocode")

			return _MenuExit(menu)
		}
		case 1:
		{
			new ePromocodes[PromoCodeData]

			for(new i; i < ArraySize(g_aPlayerPromo[id]); i++)
			{
				ArrayGetString(g_aPlayerPromo[id], i, ePromocodes[szPromocode], charsmax(ePromocodes[szPromocode]))

				if(equal(g_szUserPromocode[id], ePromocodes[szPromocode]))
				{
					csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_PROMOCODE_ALREADY_USED")
					_ShowPromocodeMenu(id)

					return _MenuExit(menu)
				}
			}

			new szItemName[MAX_SKIN_NAME]

			for(new i; i < ArraySize(g_aPromocodes); i++)
			{
				ArrayGetArray(g_aPromocodes, i, ePromocodes)

				if(equal(g_szUserPromocode[id], ePromocodes[szPromocode]))
				{
					if(!ePromocodes[iPromoActive])
					{
						csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_PROMOCODE_MAX_USES", ePromocodes[szPromocode])
						break
					}

					switch(ePromocodes[iPromoGift])
					{
						case 'k':
						{
							new random = random_num(1, 10)
							csgor_set_user_keys(id, csgor_get_user_keys(id) + random)

							_GetItemName(KEY, szItemName, charsmax(szItemName))

							csgor_send_message(id, "^1%L ^4%d ^1%s", LANG_SERVER, "CSGOR_PROMOCODE_RECEIVED", random, szItemName)

							_ShowPromocodeMenu(id)

							UpdatePromocode(id, g_szUserPromocode[id])

							break
						}
						case 'c':
						{
							new random = random_num(1, 10)
							csgor_set_user_cases(id, csgor_get_user_cases(id) + random)
							_GetItemName(CASE, szItemName, charsmax(szItemName))

							csgor_send_message(id, "^1%L ^4%d ^1%s!", LANG_SERVER, "CSGOR_PROMOCODE_RECEIVED", random, szItemName)

							_ShowPromocodeMenu(id)

							UpdatePromocode(id, g_szUserPromocode[id])

							break
						}
						case 's':
						{
							new random = random_num(0, 99)

							csgor_set_user_skins(id, random, csgor_get_user_skins(id, random) + 1)

							_GetItemName(random, szItemName, charsmax(szItemName))

							csgor_send_message(id, "^1%L ^4%s", LANG_SERVER, "CSGOR_PROMOCODE_RECEIVED", szItemName)

							_ShowPromocodeMenu(id)

							UpdatePromocode(id, g_szUserPromocode[id])

							break
						}
					}
				}
			}
		}
	}

	if(is_user_connected(id))
	{
		_ShowGamesMenu(id)
	}

	return _MenuExit(menu)
}

UpdatePromocode(id, szPromo[])
{
	ArrayPushString(g_aPlayerPromo[id], szPromo)

	new szQueryData[128], szCheckData[32]

	switch(g_eCvars[iCheckBonusType])
	{
		case 0:
		{
			copy(szCheckData, charsmax(szCheckData), g_szUserLastIP[id])
		}
		case 1:
		{
			copy(szCheckData, charsmax(szCheckData), g_szSteamID[id])
		}
	}

	formatex(szQueryData, charsmax(szQueryData), "INSERT INTO `csgor_promocodes` \
		(`Name`, `Auth`, `Promocode`) VALUES(^"%n^", ^"%s^", ^"%s^")", id, szCheckData, szPromo)

	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQueryData)
}

public clcmd_say_bonus(id)
{
	if (csgor_is_user_logged(id))
	{
		_ShowBonusMenu(id)
	}
	else
	{
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BONUS_NOT_LOGGED")
	}

	return PLUGIN_HANDLED
}

public _ShowBonusMenu(id)
{
	new bool:bShow = true
	new iTimestamp
	new szCheckData[35]
	new iNum = g_eCvars[iCheckBonusType]

	switch(iNum)
	{
		case 0:
		{
			copy(szCheckData, charsmax(szCheckData), g_szUserLastIP[id])
		}
		case 1:
		{
			copy(szCheckData, charsmax(szCheckData), g_szSteamID[id])
		}
	}

	new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT `Bonus Timestamp` FROM `csgor_data` WHERE `%s` = ^"%s^";", iNum == 0 ? "Last IP" : "SteamID", szCheckData)
	
	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError))
		log_to_file("csgo_remake_errors.log", "SQL Error: %s", g_szSqlError)
		SQL_FreeHandle(iQuery)
	}

	if(SQL_NumResults(iQuery) > 0)
	{
		new szName[MAX_NAME_LENGTH]
		csgor_get_user_name(id, szName, charsmax(szName))

		iTimestamp = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Bonus Timestamp"))

		if(get_systime() - iTimestamp <= (60 * 60 * g_eCvars[iTimeDelete]))
		{
			new szQuery[128]
			formatex(szQuery, charsmax(szQuery), "UPDATE `csgor_data` \
				SET `Bonus Timestamp`=^"%d^" \
				WHERE `Name`=^"%s^";", iTimestamp, szName)

			SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)

			bShow = false
		}
	}

	if(csgor_is_user_logged(id))
	{
		if(bShow)
		{
			new temp[64]

			formatex(temp, charsmax(temp), "\w%L", g_eCvars[szChatPrefix], "CSGOR_BONUS_MENU")
			new menu = menu_create(temp, "bonus_menu_handler")

			formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_BONUS_SCRAPS")
			menu_additem(menu, temp)

			formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_BONUS_CASES")
			menu_additem(menu, temp)

			formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_BONUS_POINTSM")
			menu_additem(menu, temp)

			formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_BONUS_SKIN")
			menu_additem(menu, temp)
			
			_DisplayMenu(id, menu)
		}
		else
		{
			csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BONUS_TAKEN", UnixTimeToString(iTimestamp))
			return
		}
	}
	else 
	{
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BONUS_NOT_LOGGED")
		return
	}
}

public bonus_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			client_cmd(id, "say /menu")
		}

		return _MenuExit(menu)
	}
	
	new szMin[8], szMax[8], szSkinMin[8], szSkinMax[8]
	parse(g_eCvars[szBonusValues], szMin, charsmax(szMin), szMax, charsmax(szMax), szSkinMin, charsmax(szSkinMin), szSkinMax, charsmax(szSkinMax))

	new rand = random_num(str_to_num(szMin), str_to_num(szMax))
	new skinRand = random_num(str_to_num(szSkinMin), str_to_num(szSkinMax))
	new bool:bBonus

	switch(item)
	{
		case 0:
		{
			bBonus = true
			csgor_set_user_dusts(id, csgor_get_user_dusts(id) + rand)

			csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BONUS_GOT_DUSTS", rand)
		}
		case 1:
		{
			bBonus = true

			csgor_set_user_cases(id, csgor_get_user_cases(id) + rand)
			csgor_set_user_keys(id, csgor_get_user_keys(id) + rand)

			if(rand == 1)
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BONUS_GOT_CASE", rand, rand)
			else
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BONUS_GOT_CASES", rand, rand)
		}
		case 2:
		{
			bBonus = true 
			csgor_set_user_points(id, csgor_get_user_points(id) + rand)

			csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BONUS_GOT_POINTS", rand)
		}
		case 3:
		{
			bBonus = true 

			new eSkinData[SkinData]

			csgor_get_skin_data(skinRand, eSkinData)

			csgor_set_user_skins(id, skinRand, csgor_get_user_skins(id, skinRand) + 1)

			csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_BONUS_GOT_SKIN", eSkinData[szSkinName])
		}
	}

	if(bBonus)
	{
		new szName[MAX_NAME_LENGTH]
		csgor_get_user_name(id, szName, charsmax(szName))

		new szQuery[128]
		formatex(szQuery, charsmax(szQuery), "UPDATE `csgor_data` \
			SET `Bonus Timestamp`=^"%d^" \
			WHERE `Name`=^"%s^";", get_systime(), szName)

		SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)
	}
	return PLUGIN_HANDLED
}


public _ShowCoinflipMenu(id)
{
	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_eCvars[szChatPrefix], LANG_SERVER, "CSGOR_COINFLIP_MENU")
	new menu = menu_create(temp, "coinflip_menu_handler", true)

	new bool:HasTarget
	new bool:HasItem

	new target = g_iCoinflipTarget[id]

	if (is_user_connected(target))
	{
		new szName[MAX_NAME_LENGTH]
		csgor_get_user_name(target, szName, charsmax(szName))

		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_COINFLIP_TARGET", szName)
		menu_additem(menu, temp, "0")

		HasTarget = true
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_COINFLIP_SELECT_TARGET")
		menu_additem(menu, temp, "0")
	}

	if (!_IsGoodItem(g_iCoinflipItem[id][iItemID]))
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_SKINS")
		menu_additem(menu, temp, "1")
	}
	else
	{
		new Item[MAX_SKIN_NAME]

		_GetItemName(g_iCoinflipItem[id][iItemID], Item, charsmax(Item))

		if(g_iCoinflipItem[id][iIsStattrack])
		{
			FormatStattrack(Item, charsmax(Item))
		}

		formatex(temp, charsmax(temp), "\w%L \y%s", LANG_SERVER, "CSGOR_COINFLIP_ITEM", Item)
		menu_additem(menu, temp, "1")

		HasItem = true
	}

	if (HasTarget && HasItem && !g_bCoinflipActive[id])
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_COINFLIP_PLAY")
		menu_additem(menu, temp, "2")
	}

	if (g_bCoinflipActive[id])
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_COINFLIP_CANCEL")
		menu_additem(menu, temp, "3")
	}

	_DisplayMenu(id, menu)
}

public coinflip_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGamesMenu(id)
		}

		return _MenuExit(menu)
	}

	new szData[3]
	new iIndex

	menu_item_getinfo(menu, item, .info = szData, .infolen = charsmax(szData))

	iIndex = str_to_num(szData)

	if (!g_bCoinflipWork)
	{
		_ShowGamesMenu(id)
		return _MenuExit(menu)
	}

	switch (iIndex)
	{
		case 0:
		{
			if (g_bCoinflipActive[id])
			{
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_LOCKED")
				_ShowCoinflipMenu(id)
			}
			else
			{
				_SelectCoinflipTarget(id)
			}
		}
		case 1:
		{
			if (g_bCoinflipActive[id])
			{
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_LOCKED")
			}
			else
			{
				_SelectCoinflipSkin(id)
			}
		}
		case 2:
		{
			new target = g_iCoinflipTarget[id]
			new _item = g_iCoinflipItem[id][iItemID]

			if(!csgor_is_user_logged(target) || !IsPlayer(target, g_iMaxPlayers))
			{
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_INVALID_TARGET")
				_ResetCoinflipData(id)
				_ShowCoinflipMenu(id)
			}
			else 
			{
				if(!csgor_user_has_item(id, _item, g_iCoinflipItem[id][iIsStattrack]))
				{
					csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_ITEMS")

					g_iCoinflipItem[id][iItemID] = -1
					g_iCoinflipItem[id][iIsStattrack] = 0

					_ShowCoinflipMenu(id)
				}
				if(g_bCoinflipSecond[id] && !csgor_user_has_item(target, g_iCoinflipItem[target][iItemID], g_iCoinflipItem[target][iIsStattrack]))
				{
					csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_FAIL")
					csgor_send_message(target, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_FAIL")

					_ResetCoinflipData(id);
					_ResetCoinflipData(target);					
				}

				g_bCoinflipActive[id] = true
				g_iCoinflipRequest[target] = id

				new szItem[MAX_SKIN_NAME]

				_GetItemName(g_iCoinflipItem[id][iItemID], szItem, charsmax(szItem))

				if(g_iCoinflipItem[id][iIsStattrack])
				{
					FormatStattrack(szItem, charsmax(szItem))
				}

				new szName[MAX_NAME_LENGTH]
				csgor_get_user_name(id, szName, charsmax(szName))

				if(!g_bCoinflipSecond[id])
				{
					csgor_send_message(target, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_INFO1", szName, szItem)
					csgor_send_message(target, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_INFO2")
				}
				else
				{
					new zItem[MAX_SKIN_NAME]

					_GetItemName(g_iCoinflipItem[target][iItemID], zItem, charsmax(zItem))

					if(g_iCoinflipItem[target][iIsStattrack])
					{
						FormatStattrack(zItem, charsmax(zItem))
					}

					csgor_send_message(target, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_INFO3", szName, szItem, szItem )
					csgor_send_message(target, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_INFO2")

					g_bCoinflipAccept[target] = true
				}

				csgor_get_user_name(target, szName, charsmax(szName))
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_SEND", szName)
			}
		}
		case 3:
		{
			if(g_bCoinflipSecond[id])
			{
				clcmd_say_deny_coin(id)
			}
			else
			{
				_ResetCoinflipData(id)
			}
			csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_CANCEL")

			_ShowCoinflipMenu(id)
		}
	}

	return _MenuExit(menu)
}

public _SelectCoinflipSkin(id)
{
	new szTemp[64]
	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_eCvars[szChatPrefix], LANG_SERVER, "CSGOR_SKINS")

	new menu = menu_create(szTemp, "cf_select_menu_handler", 0)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_NORMAL_SKIN_MENU")
	menu_additem(menu, szTemp)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_STATTRACK_SKIN_MENU")
	menu_additem(menu, szTemp)
	
	_DisplayMenu(id, menu)
}

public cf_select_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowCoinflipMenu(id)
		}

		return _MenuExit(menu)
	}

	switch(item)
	{
		case 0:
		{
			_ShowNormalSkinsMenu(id, iCoinflip)
		}
		case 1:
		{
			_ShowStattrackSkinsMenu(id, iCoinflip)
		}
	}

	return _MenuExit(menu)
}

public cf_skins_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowCoinflipMenu(id)
		}

		return _MenuExit(menu)
	}

	new data[8], szName[MAX_SKIN_NAME]
	new index
	new szSplit[2][6]

	menu_item_getinfo(menu, item, .info = data, .infolen = sizeof(data), .name = szName, .namelen = sizeof(szName))

	strtok(data, szSplit[0], sizeof(szSplit[]), szSplit[1], sizeof(szSplit[]), ';')

	index = str_to_num(szSplit[0])

	if (index == -10)
	{
		_ShowCoinflipMenu(id)
		return _MenuExit(menu)
	}
	else
	{
		new szItem[MAX_SKIN_NAME], iLocked, iStt = str_to_num(szSplit[1])

		_GetItemName(index, szItem, charsmax(szItem), iLocked)

		if(iStt)
		{
			FormatStattrack(szItem, charsmax(szItem))
		}

		if(csgor_is_item_skin(index))
		{
			if(iLocked)
			{
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_ITEM_LOCKED", szItem)
				_ShowCoinflipMenu(id)

				return _MenuExit(menu)
			}
		}
		
		g_iCoinflipItem[id][iItemID] = index
		g_iCoinflipItem[id][iIsStattrack] = iStt
	}

	_ShowCoinflipMenu(id)

	return _MenuExit(menu)
}

public _SelectCoinflipTarget(id)
{
	new temp[64]
	formatex(temp, charsmax(temp), "\r%s \y%L", g_eCvars[szChatPrefix], LANG_SERVER, "CSGOR_GM_SELECT_TARGET")

	new menu = menu_create(temp, "cft_menu_handler")
	new szItem[4]
	new Pl[32]
	new n
	new p;

	get_players(Pl, n, "h")

	new total

	new szName[MAX_NAME_LENGTH]

	if (n)
	{
		for (new i; i < n; i++)
		{
			p = Pl[i]

			if (csgor_is_user_logged(p))
			{
				if (!(p == id))
				{
					csgor_get_user_name(p, szName, charsmax(szName))
					num_to_str(p, szItem, sizeof(szItem))
					menu_additem(menu, szName, szItem)

					total++
				}
			}
		}
	}

	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_ST_NO_PLAYERS")
		num_to_str(-10, szItem, sizeof(szItem))
		menu_additem(menu, temp, szItem)
	}

	_DisplayMenu(id, menu)
}

public cft_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowCoinflipMenu(id)
		}

		return _MenuExit(menu)
	}

	new szData[4]
	new index
	new szName[MAX_NAME_LENGTH]

	menu_item_getinfo(menu, item, .info = szData, .infolen = sizeof(szData), .name = szName, .namelen = charsmax(szName))
	index = str_to_num(szData)

	if(index == -10)
	{
		_ShowCoinflipMenu(id)
	}
	else
	{
		if (g_iCoinflipRequest[index] == 1)
		{
			csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_TARGET_COINFLIP_ACTIVE", szName)
		}
		else
		{
			g_iCoinflipTarget[id] = index
			csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_YOUR_TARGET", szName)
		}

		_ShowCoinflipMenu(id)
	}
	return _MenuExit(menu)
}

public clcmd_say_accept_coin(id)
{
	new sender = g_iCoinflipRequest[id]
	if(sender < 1 || sender > 32)
	{
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_DONT_HAVE_COIN_REQ")

		return
	}

	if (!csgor_is_user_logged(sender) || !is_user_connected(sender))
	{
		_ResetCoinflipData(id)
		_ResetCoinflipData(sender)

		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_INVALID_SENDER")

		return
	}

	if (!g_bCoinflipActive[sender] && id == g_iCoinflipTarget[sender])
	{
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_IS_CANCELED")

		_ResetCoinflipData(id)
		_ResetCoinflipData(sender)

		return
	}

	if (g_bCoinflipAccept[id])
	{
		new sItem = g_iCoinflipItem[sender][iItemID]
		new zItem = g_iCoinflipItem[id][iItemID]
		new sItemsz[MAX_SKIN_NAME]
		new zItemsz[MAX_SKIN_NAME]

		_GetItemName(sItem, sItemsz, charsmax(sItemsz))
		_GetItemName(zItem, zItemsz, charsmax(zItemsz))

		if(!csgor_user_has_item(id, zItem, g_iCoinflipItem[id][iIsStattrack]) || !csgor_user_has_item(sender, sItem, g_iCoinflipItem[sender][iIsStattrack]))
		{
			csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_FAIL2")
			csgor_send_message(sender, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_FAIL2")

			_ResetCoinflipData(id)
			_ResetCoinflipData(sender)

			return
		}

		new coin = random_num(1, 2)

		new szName[MAX_NAME_LENGTH]
		csgor_get_user_name(id, szName, charsmax(szName))

		if(g_iCoinflipItem[sender][iIsStattrack])
		{
			FormatStattrack(zItemsz, charsmax(zItemsz))
		}

		if(g_iCoinflipItem[id][iIsStattrack])
		{
			FormatStattrack(sItemsz, charsmax(sItemsz))
		}

		switch(coin)
		{
			case 1:
			{
				switch(g_iCoinflipItem[sender][iIsStattrack])
				{
					case 0:
					{
						if(csgor_user_has_item(sender, zItem, 0))
						{
							csgor_set_user_skins(sender, zItem, csgor_get_user_skins(sender, zItem) + 1)
						}
						else 
						{
							csgor_set_user_skins(sender, zItem, 1)
						}

						new iTempNum = csgor_get_user_skins(id, zItem) - 1
						csgor_set_user_skins(id, zItem, ( iTempNum ) < 0 ? 0 : iTempNum)
					}
					case 1:
					{
						if(csgor_user_has_item(sender, zItem, 1))
						{
							csgor_set_user_statt_skins(sender, zItem, csgor_get_user_statt_skins(sender, zItem) + 1)
						}
						else 
						{
							csgor_set_user_statt_skins(sender, zItem, 1)
						}

						new iTempNum = csgor_get_user_statt_skins(id, zItem) - 1
						csgor_set_user_statt_skins(id, zItem, ( iTempNum ) < 0 ? 0 : iTempNum)
					}
				}
				
				csgor_get_user_name(id, szName, charsmax(szName))
				csgor_send_message(sender, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_YOU_WON_X_WITH_X", szName, zItemsz)

				csgor_get_user_name(sender, szName, charsmax(szName))
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_YOU_LOSE_X_WITH_X", szName, zItemsz)
			}
			case 2:
			{ 
				switch(g_iCoinflipItem[sender][iIsStattrack])
				{
					case 0:
					{
						if(csgor_user_has_item(id, sItem, 0))
						{
							csgor_set_user_skins(id, sItem, csgor_get_user_skins(id, sItem) + 1)
						}
						else 
						{
							csgor_set_user_skins(id, sItem, 1)
						}

						new iTempNum = csgor_get_user_skins(sender, sItem) - 1
						csgor_set_user_skins(sender, sItem, ( iTempNum ) < 0 ? 0 : iTempNum)
					}
					case 1:
					{
						if(csgor_user_has_item(id, sItem, 1))
						{
							csgor_set_user_statt_skins(id, sItem, csgor_get_user_statt_skins(id, sItem) + 1)
						}
						else 
						{
							csgor_set_user_statt_skins(id, sItem, 1)
						}

						new iTempNum = csgor_get_user_statt_skins(sender, sItem) - 1
						csgor_set_user_statt_skins(sender, sItem, ( iTempNum ) < 0 ? 0 : iTempNum)
					}
				}

				csgor_get_user_name(sender, szName, charsmax(szName))
				csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_YOU_WON_X_WITH_X", szName, sItemsz)
				
				csgor_get_user_name(id, szName, charsmax(szName))
				csgor_send_message(sender, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_YOU_LOSE_X_WITH_X", szName, sItemsz)
			}
		}

		_ResetCoinflipData(id)
		_ResetCoinflipData(sender)
	}
	else
	{
		if (!g_bCoinflipSecond[id])
		{
			g_iCoinflipTarget[id] = sender
			g_iCoinflipItem[id][iItemID] = -1
			g_iCoinflipItem[id][iIsStattrack] = 0
			g_bCoinflipSecond[id] = true

			_ShowCoinflipMenu(id)

			csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_SELECT_ITEM")
		}
	}
}

public clcmd_say_deny_coin(id)
{
	new sender = g_iCoinflipRequest[id]

	if ( !IsPlayer(sender, g_iMaxPlayers) )
	{
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_DONT_HAVE_COIN_REQ")

		return
	}

	if (!csgor_is_user_logged(sender) || !IsPlayer(sender, g_iMaxPlayers))
	{
		_ResetCoinflipData(id)

		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_INVALID_SENDER")

		return
	}

	if (!g_bCoinflipActive[sender] && id == g_iCoinflipTarget[sender])
	{
		csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_COINFLIP_IS_CANCELED")

		_ResetCoinflipData(id)

		return
	}

	_ResetCoinflipData(id)
	_ResetCoinflipData(sender)

	new szName[MAX_NAME_LENGTH]
	csgor_get_user_name(id, szName, charsmax(szName))
	csgor_send_message(sender, "^1%L", LANG_SERVER, "CSGOR_TARGET_REFUSE_COINFLIP", szName)

	csgor_get_user_name(sender, szName, charsmax(szName))
	csgor_send_message(id, "^1%L", LANG_SERVER, "CSGOR_YOU_REFUSE_COINFLIP", szName)
}

public QueryHandler(iFailState, Handle:iQuery, Error[], Errcode, szData[], iSize, Float:flQueueTime)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: 
		{
			log_amx("[SQL Error] Connection failed (%i): %s", Errcode, Error)
		}
		case TQUERY_QUERY_FAILED:
		{
			log_amx("[SQL Error] Query failed (%i): %s", Errcode, Error)
		}
	}
}

_FormatTime(timer[], len, nextevent)
{
	new seconds = nextevent - get_systime()
	new minutes

	while (seconds >= 60)
	{
		seconds += -60
		minutes++
	}

	new bool:add_before
	new temp[32]

	if (seconds)
	{
		formatex(temp, charsmax(temp), "%i %s", seconds, seconds == 1 ? "second" : "seconds")
		add_before = true
	}

	if (minutes)
	{
		if (add_before)
		{
			format(temp, charsmax(temp), "%i %s, %s",minutes, minutes == 1 ? "minute" : "minutes", temp)
		}
		else
		{
			formatex(temp, charsmax(temp), "%i %s", minutes, minutes == 1 ? "minute" : "minutes")
			add_before = true
		}
	}

	if (!add_before)
	{
		copy(timer, len, "Now!")
	}
	else
	{
		formatex(timer, len, "%s", temp)
	}
}

_ClearJackpot()
{
	ArrayClear(g_aJackpotSkins)
	ArrayClear(g_aJackpotUsers)
	arrayset(g_bUserPlayJackpot, false, sizeof(g_bUserPlayJackpot))

	g_bJackpotWork = false

	csgor_send_message(0, "^1%L", LANG_SERVER, "CSGOR_JP_NEXT")
}

_ResetCoinflipData(id)
{
	g_bCoinflipActive[id] = false
	g_bCoinflipSecond[id] = false
	g_bCoinflipAccept[id] = false
	g_iCoinflipTarget[id] = 0
	g_iCoinflipItem[id][iItemID] = -1
	g_iCoinflipItem[id][iIsStattrack] = 0
	g_iCoinflipRequest[id] = 0
}

DestroyTask(iTaskID)
{
	if(task_exists(iTaskID))
	{
		remove_task(iTaskID)
	}
}

_DisplayMenu(id, menu)
{
	if(!is_user_connected(id))
		return

	menu_display(id, menu)
}

_MenuExit(menu)
{
	menu_destroy(menu)

	return PLUGIN_HANDLED
}

UnixTimeToString(const TimeUnix) 
{
    new szBuffer[64]
    szBuffer[0] = EOS
    
    if(!TimeUnix) {
        return szBuffer
    }
    
    new iYear
    new iMonth
    new iDay
    new iHour
    new iMinute
    new iSecond
    
    UnixToTime(TimeUnix, iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);    
    formatex(szBuffer, charsmax(szBuffer), "%02d:%02d:%02d", iHour, iMinute, iSecond)
    
    return szBuffer
}

bool:_IsGoodItem(item)
{
	if (0 <= item < csgor_get_skins_num() || item == CASE || item == KEY)
	{
		return true
	}

	return false
}

_GetItemName(item, temp[], len, &iLocked = -1)
{
	if(item == -1)
	{
		return
	}

	switch (item)
	{
		case KEY:
		{
			formatex(temp, len, "%L", item, "CSGOR_ITEM_KEY")
		}
		case CASE:
		{
			formatex(temp, len, "%L", item, "CSGOR_ITEM_CASE")
		}
		default:
		{
			new eSkinData[SkinData]

			csgor_get_skin_data(item, eSkinData)
			copy(temp, len, eSkinData[szSkinName])
			iLocked = eSkinData[iSkinLock]
		}
	}
}

GetMaxSkins(iWeapon)
{
	new eSkinData[SkinData]
	new iSkins
	for (new i; i < csgor_get_skins_num(); i++)
	{
		csgor_get_skin_data(i, eSkinData)
		if (iWeapon == eSkinData[iWeaponID])
		{
			iSkins++
		}
	}
	return iSkins
}

FormatStattrack(szName[], iLen)
{
	format(szName, iLen, "(StatTrack) %s", szName)
}
