#if defined _cromchat_included
    #endinput
#endif

#define _cromchat_included

#include <amxmodx>
#include <fakemeta>

#if !defined replace_string
	#define replace_string replace_all
#endif

#if !defined CC_DONT_OVERWRITE_183_PRINT
	#define client_print_color CC_SendMatched
	#define print_team_default CC_COLOR_TEAM
	#define print_team_grey CC_COLOR_GREY
	#define print_team_blue CC_COLOR_BLUE
	#define print_team_red CC_COLOR_RED
#endif

#if !defined CC_DONT_OVERWRITE_COLORCHAT
	#define ColorChat CC_SendMatched
	#define NORMAL CC_COLOR_TEAM
	#define TEAM_COLOR CC_COLOR_TEAM
	#define GREEN CC_COLOR_TEAM
	#define GREY CC_COLOR_GREY
	#define BLUE CC_COLOR_BLUE
	#define RED CC_COLOR_RED
#endif

#if !defined CC_DONT_OVERWRITE_ACTIVITY
	#define show_activity CC_ShowActivity
	#define show_activity_id CC_ShowActivityId
	#define show_activity_key CC_ShowActivityKey
#endif

#if !defined CC_DONT_OVERWRITE_WPMG
	#define PrintChatColor CC_SendMatched
	#define PRINT_COLOR_GREY CC_COLOR_GREY
	#define PRINT_COLOR_RED CC_COLOR_RED
	#define PRINT_COLOR_BLUE CC_COLOR_BLUE
	#define PRINT_COLOR_PLAYERTEAM CC_COLOR_TEAM
#endif

#if !defined CC_DONT_OVERWRITE_CHATPRINT
	#define ChatPrint CC_SendMessage
#endif

#if !defined CC_PERCENT_REPLACE
	#define CC_PERCENT_REPLACE "％"
#endif

#define CromChat CC_SendMessage

const Float:CC_VERSION            = 3.3
const CC_MAX_ACT_PREFIX_SIZE      = 10
const CC_MAX_PLAYERS              = 32
const CC_MAX_PREFIX_SIZE          = 64
const CC_MAX_MESSAGE_SIZE         = 177
new const CC_LIBRARY_NAME[]       = "cromchat"
static const CC_FILTERING_FLAGS[] = "ch"

#if !defined CC_COLORS_TYPE
	#define CC_COLORS_TYPE CC_COLORS_CROMCHAT
#endif

#if !defined CC_ACTIVITY_FLAG
	#define CC_ACTIVITY_FLAG -1
#endif

#if !defined CC_ACTIVITY_PREFIX_PLAYER
	#define CC_ACTIVITY_PREFIX_PLAYER "PLAYER"
#endif

#if !defined CC_ACTIVITY_PREFIX_ADMIN
	#define CC_ACTIVITY_PREFIX_ADMIN "ADMIN"
#endif

enum
{
	CC_COLOR_TEAM = CC_MAX_PLAYERS + 25,
	CC_COLOR_GREY,
	CC_COLOR_BLUE,
	CC_COLOR_RED
}

const CC_COLOR_WHITE = CC_COLOR_GREY

enum
{
	CC_COLORS_CROMCHAT,
	CC_COLORS_SHORT,
	CC_COLORS_NAMED,
	CC_COLORS_NAMED_SHORT,
	CC_COLORS_STANDARD,
	CC_COLORS_CUSTOM
}

#define CC_SYM_MENU_YELLOW          "\y"
#define CC_SYM_MENU_WHITE           "\w"
#define CC_SYM_MENU_GREY            "\d"
#define CC_SYM_MENU_RIGHT           "\R"

#define CC_SYM_CHAT_DEF_NORMAL      "^x01"
#define CC_SYM_CHAT_DEF_TEAM        "^x03"
#define CC_SYM_CHAT_DEF_GREEN       "^x04"

static bool:CC_FIRST_TIME_ACTIVITY = true, bool:CC_IS_CSCZ, bool:CC_COLOR_FORCE
static CC_ACTIVITY_POINTER, CC_COLOR_PLAYER_INDEX

new CC_PREFIX[CC_MAX_PREFIX_SIZE]

#if CC_COLORS_TYPE == CC_COLORS_CUSTOM
	#if !defined CC_SYM_CHAT_NORMAL
		#define CC_SYM_CHAT_NORMAL "&x01"
	#endif
	
	#if !defined CC_SYM_CHAT_TEAM
		#define CC_SYM_CHAT_TEAM   "&x03"
	#endif
	
	#if !defined CC_SYM_CHAT_GREEN
		#define CC_SYM_CHAT_GREEN  "&x04"
	#endif
	
	#if !defined CC_SYM_CHAT_WHITE
		#define CC_SYM_CHAT_WHITE  "&x05"
	#endif
	
	#if !defined CC_SYM_CHAT_BLUE
		#define CC_SYM_CHAT_BLUE   "&x06"
	#endif
	
	#if !defined CC_SYM_CHAT_RED
		#define CC_SYM_CHAT_RED    "&x07"
	#endif
	
	#if !defined CC_SYM_CHAT_NOPREF
		#define CC_SYM_CHAT_NOPREF "&x00"
	#endif
#else	
	#if CC_COLORS_TYPE == CC_COLORS_CROMCHAT
		#define CC_SYM_CHAT_NORMAL "&x01"
		#define CC_SYM_CHAT_TEAM   "&x03"
		#define CC_SYM_CHAT_GREEN  "&x04"
		#define CC_SYM_CHAT_WHITE  "&x05"
		#define CC_SYM_CHAT_BLUE   "&x06"
		#define CC_SYM_CHAT_RED    "&x07"
		#define CC_SYM_CHAT_NOPREF "&x00"
	#endif
	
	#if CC_COLORS_TYPE == CC_COLORS_SHORT
		#define CC_SYM_CHAT_NORMAL "!n"
		#define CC_SYM_CHAT_TEAM   "!t"
		#define CC_SYM_CHAT_GREEN  "!g"
		#define CC_SYM_CHAT_WHITE  "!w"
		#define CC_SYM_CHAT_BLUE   "!b"
		#define CC_SYM_CHAT_RED    "!r"
		#define CC_SYM_CHAT_NOPREF "!p"
	#endif
	
	#if CC_COLORS_TYPE == CC_COLORS_NAMED
		#define CC_SYM_CHAT_NORMAL "{normal}"
		#define CC_SYM_CHAT_TEAM   "{team}"
		#define CC_SYM_CHAT_GREEN  "{green}"
		#define CC_SYM_CHAT_WHITE  "{white}"
		#define CC_SYM_CHAT_BLUE   "{blue}"
		#define CC_SYM_CHAT_RED    "{red}"
		#define CC_SYM_CHAT_NOPREF "{nopref}"
	#endif
	
	#if CC_COLORS_TYPE == CC_COLORS_NAMED_SHORT
		#define CC_SYM_CHAT_NORMAL "{n}"
		#define CC_SYM_CHAT_TEAM   "{t}"
		#define CC_SYM_CHAT_GREEN  "{g}"
		#define CC_SYM_CHAT_WHITE  "{w}"
		#define CC_SYM_CHAT_BLUE   "{b}"
		#define CC_SYM_CHAT_RED    "{r}"
		#define CC_SYM_CHAT_NOPREF "{p}"
	#endif
	
	#if CC_COLORS_TYPE == CC_COLORS_STANDARD
		#define CC_SYM_CHAT_NORMAL "^1"
		#define CC_SYM_CHAT_TEAM   "^3"
		#define CC_SYM_CHAT_GREEN  "^4"
		#define CC_SYM_CHAT_WHITE  "^5"
		#define CC_SYM_CHAT_BLUE   "^6"
		#define CC_SYM_CHAT_RED    "^7"
		#define CC_SYM_CHAT_NOPREF "^0"
	#endif
#endif

static const CC_NO_PREFIX[]         =   CC_SYM_CHAT_NOPREF
static const CC_MENU_COLORS[][]     = { CC_SYM_MENU_YELLOW, CC_SYM_MENU_WHITE, CC_SYM_MENU_GREY, CC_SYM_MENU_RIGHT }
static const CC_REPLACE_COLORS[][]  = { CC_SYM_CHAT_GREEN, CC_SYM_CHAT_DEF_GREEN, CC_SYM_CHAT_TEAM, CC_SYM_CHAT_DEF_TEAM, CC_SYM_CHAT_NORMAL, CC_SYM_CHAT_DEF_NORMAL }
static const CC_PLUS_COLORS_STR[][] = { CC_SYM_CHAT_RED, CC_SYM_CHAT_BLUE, CC_SYM_CHAT_WHITE }
static const CC_PLUS_COLORS_INT[]   = { CC_COLOR_RED, CC_COLOR_BLUE, CC_COLOR_WHITE }
static const CC_COLORS_LIST[][]     = { CC_SYM_CHAT_RED, CC_SYM_CHAT_BLUE, CC_SYM_CHAT_WHITE, CC_SYM_CHAT_GREEN, CC_SYM_CHAT_TEAM, CC_SYM_CHAT_NORMAL, CC_SYM_CHAT_NOPREF }

/**
 * Sends a colored chat message.
 *
 * @param id        Client index (use 0 to send to all players)
 * @param input     The message to send
 * @param ...       Variable number of formatting parameters
 *
 * @return          Length of the printed message
 */
stock CC_SendMessage(id, const input[], any:...)
{
	_CC_ModInit()
	static iPlayers[CC_MAX_PLAYERS], iPnum
	
	if(id)
	{
		if(!is_user_connected(id))
		{
			return 0
		}
	}
	else
	{
		get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)
		
		if(!iPnum)
		{
			return 0
		}
	}
	
	static szMessage[CC_MAX_MESSAGE_SIZE], bool:bNoPrefix, i
	vformat(szMessage[1], charsmax(szMessage), input, 3)
	szMessage[0] = 0x01
	
	bNoPrefix = bool:(equal(szMessage[1], CC_NO_PREFIX, charsmax(CC_NO_PREFIX)) || equal(szMessage[2], CC_NO_PREFIX, charsmax(CC_NO_PREFIX)))
	
	if(bNoPrefix)
	{
		replace(szMessage, charsmax(szMessage), CC_NO_PREFIX, "")
	}
	else if(CC_PREFIX[0])
	{
		if(CC_IS_CSCZ)
		{
			format(szMessage, charsmax(szMessage), "%s%s %s%s", CC_SYM_CHAT_DEF_NORMAL, CC_PREFIX, CC_SYM_CHAT_DEF_NORMAL, szMessage)
		}
		else
		{
			format(szMessage, charsmax(szMessage), "%s%s %s", CC_SYM_CHAT_DEF_NORMAL, CC_PREFIX, szMessage)
		}
	}
	
	for(i = 0; i < sizeof(CC_REPLACE_COLORS) - 1; i += 2)
	{
		if(CC_IS_CSCZ)
		{
			replace_string(szMessage, charsmax(szMessage), CC_REPLACE_COLORS[i], CC_REPLACE_COLORS[i + 1])
		}
		else
		{
			replace_string(szMessage, charsmax(szMessage), CC_REPLACE_COLORS[i], "")
		}
	}
		
	for(i = 0; i < sizeof(CC_PLUS_COLORS_STR); i++)
	{
		if(contain(szMessage, CC_PLUS_COLORS_STR[i]) != -1)
		{
			if(!CC_COLOR_FORCE)
			{
				CC_COLOR_PLAYER_INDEX = CC_PLUS_COLORS_INT[i]
			}

			for(i = 0; i < 3; i++)
			{
				if(CC_IS_CSCZ)
				{
					replace_string(szMessage, charsmax(szMessage), CC_COLORS_LIST[i], CC_SYM_CHAT_DEF_TEAM)
				}
				else
				{
					replace_string(szMessage, charsmax(szMessage), CC_COLORS_LIST[i], "")
				}
			}

			break
		}
	}
	
	if(id)
	{
		_CC_WriteMessage(id, szMessage)
	}
	else
	{
		for(i = 0; i < iPnum; i++)
		{
			_CC_WriteMessage(iPlayers[i], szMessage)
		}
	}

	CC_COLOR_FORCE = false
	CC_COLOR_PLAYER_INDEX = 0

	return strlen(szMessage)
}

/**
 * Sends a colored chat message matching a specific player's color.
 *
 * @note You can use the "player" argument to set a specific color instead of matching
 *       it automtaically. To do this, you can use one of the following color arguments:
 *		 CC_COLOR_TEAM, CC_COLOR_GREY (or CC_COLOR_WHITE), CC_COLOR_BLUE, CC_COLOR_RED.
 *
 * @param id        Client index (use 0 to send to all players)
 * @param player    Matching player's index
 * @param input     The message to send
 * @param ...       Variable number of formatting parameters
 *
 * @return          Length of the printed message
 */
stock CC_SendMatched(id, player, const input[], any:...)
{
	static szMessage[CC_MAX_MESSAGE_SIZE]
	vformat(szMessage[1], charsmax(szMessage), input, 4)
	szMessage[0] = 0x01
	CC_COLOR_PLAYER_INDEX = player
	return CC_SendMessage(id, szMessage)
}

/**
 * Sends a colored chat message to a group of players matching the flags from the get_players() function.
 *
 * @note The filtering flags are the same that are used by the get_players() function
 *
 * @param flags     Filtering flags
 * @param params    String to match against if the flags require it
 * @param input     The message to send
 * @param ...       Variable number of formatting parameters
 *
 * @return          Length of the printed message or 0 if no players were matched
 */
stock CC_GroupMessage(const flags[] = "", const params[] = "", const input[], any:...)
{
	static szMessage[CC_MAX_MESSAGE_SIZE], iPlayers[CC_MAX_PLAYERS], iPnum
	vformat(szMessage, charsmax(szMessage), input, 4)
	get_players(iPlayers, iPnum, flags, params)
	
	if(!iPnum)
	{
		return 0
	}
	
	static bool:bForce, iColor, i

	for(bForce = CC_COLOR_FORCE, iColor = CC_COLOR_PLAYER_INDEX, i = 0; i < iPnum; i++)
	{
		CC_SetColor(iColor, bForce)
		CC_SendMessage(iPlayers[i], szMessage)
	}
	
	return strlen(szMessage)
}

/**
 * Sends a colored chat message to all players who have the specified admin flags.
 *
 * @param flags     Admin flags
 * @param allflags  If set to true it will match players who have ALL of the specified admin flags, otherwise it will match players with ANY of the flags
 * @param input     The message to send
 * @param ...       Variable number of formatting parameters
 *
 * @return          Length of the printed message or 0 if no players were matched
 */
stock CC_SendAdminMessage(const flags[] = "", bool:allflags = true, const input[], any:...)
{
	static szMessage[CC_MAX_MESSAGE_SIZE], iPlayers[CC_MAX_PLAYERS], iPnum
	vformat(szMessage, charsmax(szMessage), input, 4)
	get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)
	
	if(!iPnum)
	{
		return 0
	}
	
	static bool:bForce, iColor, iCount, iFlags, iPlayer, i
	iFlags = read_flags(flags)
	iCount = 0
	
	for(bForce = CC_COLOR_FORCE, iColor = CC_COLOR_PLAYER_INDEX, i = 0; i < iPnum; i++)
	{
		iPlayer = iPlayers[i]
		
		switch(allflags)
		{
			case true:
			{
				if(get_user_flags(iPlayer) & iFlags != iFlags)
				{
					continue
				}
			}
			case false:
			{
				if(!(get_user_flags(iPlayer) & iFlags))
				{
					continue
				}
			}
		}
		
		iCount++

		CC_SetColor(iColor, bForce)
		CC_SendMessage(iPlayer, szMessage)
	}
	
	if(!iCount)
	{
		return 0
	}
	
	return strlen(szMessage)
}

/**
 * Sends a colored chat message and logs it at the same time.
 *
 * @note If the file name is not set, the default log file will be used instead.
 *
 * @param id        Client index (use 0 to send to all players)
 * @param file      The log file that will be used
 * @param input     The message to send
 * @param ...       Variable number of formatting parameters
 *
 * @return          Length of the printed message
 */
stock CC_LogMessage(id, const file[] = "", const input[], any:...)
{
	static szMessage[CC_MAX_MESSAGE_SIZE]
	vformat(szMessage, charsmax(szMessage), input, 4)
	
	if(!CC_SendMessage(id, szMessage))
	{
		return 0
	}
		
	CC_RemoveColors(szMessage, charsmax(szMessage))
	file[0] ? log_to_file(file, szMessage) : log_amx(szMessage)
	return strlen(szMessage)
}

/**
 * Sends a colored chat message to all players that obeys the amx_show_activity cvar.
 *
 * @note This function is made to mimic the show_activity() function, but sends a
 *		 colored chat message instead using the CC_SendMessage() function. This means
 *		 that the default AMXX function can directly be replaced with this one in order
 *		 for it to display a colored chat message rather than a default one.
 * @note By default, cromchat.inc will replace all show_activity() functions in the file
 *		 with the CC_ShowActivity() function. You can disable this feature by adding
 *		 #define CC_DONT_OVERWRITE_ACTIVITY before #include <cromchat> in your plugin.
 *
 * @param id        Client index performing the action
 * @param name      Name of client performing the action
 * @param input     Formatting rules
 * @param ...       Variable number of formatting parameters
 *
 * @noreturn
 */
stock CC_ShowActivity(id, const name[], const input[], any:...)
{
	if(CC_FIRST_TIME_ACTIVITY)
	{
		_CC_ActivityInit()
	}

	static szMessage[CC_MAX_MESSAGE_SIZE], szPrefix[CC_MAX_ACT_PREFIX_SIZE], iPlayers[CC_MAX_PLAYERS], bool:bForce, iPlayer, iPnum, iColor, i
	vformat(szMessage, charsmax(szMessage), input, 4)
	_CC_GetActivityPrefix(id, szPrefix, charsmax(szPrefix))

	switch(get_pcvar_num(CC_ACTIVITY_POINTER))
	{
		case 1: CC_SendMessage(0, "%L: %s", LANG_PLAYER, szPrefix, szMessage)
		case 2: CC_SendMessage(0, "%L %s: %s", LANG_PLAYER, szPrefix, name, szMessage)
		case 3:
		{
			get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)

			for(bForce = CC_COLOR_FORCE, iColor = CC_COLOR_PLAYER_INDEX, i = 0; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]
				CC_SetColor(iColor, bForce)

				if(_CC_IsActivityAdmin(iPlayer))
				{
					CC_SendMessage(iPlayer, "%L %s: %s", iPlayer, szPrefix, name, szMessage)
				}
				else
				{
					CC_SendMessage(iPlayer, "%L: %s", iPlayer, szPrefix, szMessage)
				}
			}
		}
		case 4:
		{
			get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)

			for(bForce = CC_COLOR_FORCE, iColor = CC_COLOR_PLAYER_INDEX, i = 0; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]

				if(_CC_IsActivityAdmin(iPlayer))
				{
					CC_SetColor(iColor, bForce)
					CC_SendMessage(iPlayer, "%L %s: %s", iPlayer, szPrefix, name, szMessage)
				}
			}
		}
		case 5:
		{
			get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)

			for(bForce = CC_COLOR_FORCE, iColor = CC_COLOR_PLAYER_INDEX, i = 0; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]

				if(_CC_IsActivityAdmin(iPlayer))
				{
					CC_SetColor(iColor, bForce)
					CC_SendMessage(iPlayer, "%L: %s", iPlayer, szPrefix, szMessage)
				}
			}
		}
	}
}

/**
 * Sends a colored chat message to a single client that obeys the amx_show_activity cvar.
 *
 * @note This function is made to mimic the show_activity_id() function, but sends a
 *		 colored chat message instead using the CC_SendMessage() function. This means
 *		 that the default AMXX function can directly be replaced with this one in order
 *		 for it to display a colored chat message rather than a default one.
 * @note By default, cromchat.inc will replace all show_activity_id() functions in the file
 *		 with the CC_ShowActivityId() function. You can disable this feature by adding
 *		 #define CC_DONT_OVERWRITE_ACTIVITY before #include <cromchat> in your plugin.
 *
 * @param target    Client index to display message to
 * @param id        Client index performing the action
 * @param name      Name of client performing the action
 * @param input     Formatting rules
 * @param ...       Variable number of formatting parameters
 *
 * @noreturn
 */
stock CC_ShowActivityId(target, id, const name[], const input[], any:...)
{
	if(!is_user_connected(target))
	{
		return
	}

	if(CC_FIRST_TIME_ACTIVITY)
	{
		_CC_ActivityInit()
	}

	static szMessage[CC_MAX_MESSAGE_SIZE], szPrefix[CC_MAX_ACT_PREFIX_SIZE]
	vformat(szMessage, charsmax(szMessage), input, 5)
	_CC_GetActivityPrefix(id, szPrefix, charsmax(szPrefix))

	switch(get_pcvar_num(CC_ACTIVITY_POINTER))
	{
		case 1: CC_SendMessage(target, "%L: %s", target, szPrefix, szMessage)
		case 2: CC_SendMessage(target, "%L %s: %s", target, szPrefix, name, szMessage)
		case 3:
		{
			if(_CC_IsActivityAdmin(target))
			{
				CC_SendMessage(target, "%L %s: %s", target, szPrefix, name, szMessage)
			}
			else
			{
				CC_SendMessage(target, "%L: %s", target, szPrefix, szMessage)
			}
		}
		case 4:
		{
			if(_CC_IsActivityAdmin(target))
			{
				CC_SendMessage(target, "%L %s: %s", target, szPrefix, name, szMessage)
			}
		}
		case 5:
		{
			if(_CC_IsActivityAdmin(target))
			{
				CC_SendMessage(target, "%L: %s", target, szPrefix, szMessage)
			}
		}
	}
}

/**
 * Sends a colored chat message to all clients using nromal language keys that obeys the amx_show_activity cvar.
 *
 * @note This function is made to mimic the show_activity_key() function, but sends a
 *		 colored chat message instead using the CC_SendMessage() function. This means
 *		 that the default AMXX function can directly be replaced with this one in order
 *		 for it to display a colored chat message rather than a default one.
 * @note By default, cromchat.inc will replace all show_activity_key() functions in the file
 *		 with the CC_ShowActivityKey() function. You can disable this feature by adding
 *		 #define CC_DONT_OVERWRITE_ACTIVITY before #include <cromchat> in your plugin.
 *
 * @param without  The language key that does not have the name field
 * @param with     The language key that does have the name field
 * @param name     The name of the person doing the action
 * @param ...      Pass any extra format arguments for the language key in the variable arguments list
 *
 * @noreturn
 */
stock CC_ShowActivityKey(const without[], const with[], const name[], any:...)
{
	#pragma unused name

	if(CC_FIRST_TIME_ACTIVITY)
	{
		_CC_ActivityInit()
	}

	static szMessage[CC_MAX_MESSAGE_SIZE], szKey[CC_MAX_MESSAGE_SIZE], iPlayers[CC_MAX_PLAYERS], bool:bForce, iPnum, iPlayer, iColor, i

	switch(get_pcvar_num(CC_ACTIVITY_POINTER))
	{
		case 1:
		{
			get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)

			for(bForce = CC_COLOR_FORCE, iColor = CC_COLOR_PLAYER_INDEX, i = 0; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]
				CC_SetColor(iColor, bForce)

				LookupLangKey(szKey, charsmax(szKey), without, iPlayer)
				vformat(szMessage, charsmax(szMessage), szKey, 4)
				CC_SendMessage(iPlayer, szMessage)
			}
		}
		case 2:
		{
			get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)

			for(bForce = CC_COLOR_FORCE, iColor = CC_COLOR_PLAYER_INDEX, i = 0; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]
				CC_SetColor(iColor, bForce)

				LookupLangKey(szKey, charsmax(szKey), with, iPlayer)
				vformat(szMessage, charsmax(szMessage), szKey, 3)
				CC_SendMessage(iPlayer, szMessage)
			}
		}
		case 3:
		{
			get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)

			for(bForce = CC_COLOR_FORCE, iColor = CC_COLOR_PLAYER_INDEX, i = 0; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]
				CC_SetColor(iColor, bForce)

				if(_CC_IsActivityAdmin(iPlayer))
				{
					LookupLangKey(szKey, charsmax(szKey), with, iPlayer)
					vformat(szMessage, charsmax(szMessage), szKey, 3)
				}
				else
				{
					LookupLangKey(szKey, charsmax(szKey), without, iPlayer)
					vformat(szMessage, charsmax(szMessage), szKey, 4)
				}

				CC_SendMessage(iPlayer, szMessage)
			}
		}
		case 4:
		{
			get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)

			for(bForce = CC_COLOR_FORCE, iColor = CC_COLOR_PLAYER_INDEX, i = 0; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]

				if(_CC_IsActivityAdmin(iPlayer))
				{
					CC_SetColor(iColor, bForce)
					LookupLangKey(szKey, charsmax(szKey), with, iPlayer)
					vformat(szMessage, charsmax(szMessage), szKey, 3)
					CC_SendMessage(iPlayer, szMessage)
				}
			}
		}
		case 5:
		{
			get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)

			for(bForce = CC_COLOR_FORCE, iColor = CC_COLOR_PLAYER_INDEX, i = 0; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]

				if(_CC_IsActivityAdmin(iPlayer))
				{
					CC_SetColor(iColor, bForce)
					LookupLangKey(szKey, charsmax(szKey), without, iPlayer)
					vformat(szMessage, charsmax(szMessage), szKey, 4)
					CC_SendMessage(iPlayer, szMessage)
				}
			}
		}
	}
}

/**
 * Removes the color codes from a message.
 *
 * @param message   The message to remove colors from
 * @param len       Maximum message length
 * @param chat      If set to true, it will remove the chat color codes
 * @param menu      If set to true, it will remove the menu color codes
 *
 * @noreturn
 */
stock CC_RemoveColors(message[], len, bool:chat = true, bool:menu = false)
{
	static i
	
	if(chat)
	{
		for(i = 0; i < sizeof(CC_COLORS_LIST); i++)
		{
			replace_string(message, len, CC_COLORS_LIST[i], "")
		}
	}
	
	if(menu)
	{
		for(i = 0; i < sizeof(CC_MENU_COLORS); i++)
		{
			replace_string(message, len, CC_MENU_COLORS[i], "")
		}
	}
}

/**
 * Removes exploits from the message.
 *
 * @note You can change the '%' replacement symbol by adding #define CC_PERCENT_REPLACE "symbol here" before #include <cromchat>
 * @note It is strongly advised to use this function whenever you're sending messages based on hooking "say" or "say_team"
 *
 * @param message   The message to remove exploits from
 * @param len       Maximum message length
 * @param colors    If set to true, it will remove the ETX, EOT & SOH chat color codes;
 *                  this prevents player from manually changing their chat color when they have the chance to
 * @param percent   If set to true, it will replace the '%' symbol with '％'
 *
 * @noreturn
 */
stock CC_RemoveExploits(message[], len, bool:colors = true, bool:percent = true)
{
	static i

	if(colors)
	{
		static const CC_COLOR_EXPLOITS[][] = { "", "", "" }

		for(i = 0; i < sizeof(CC_COLOR_EXPLOITS); i++)
		{
			replace_string(message, len, CC_COLOR_EXPLOITS[i], "")
		}
	}

	if(percent)
	{
		static const CC_PERCENT_FIND[] = "%"
		replace_string(message, len, CC_PERCENT_FIND, CC_PERCENT_REPLACE)
	}
}

/**
 * Sets a global prefix that will be used for all sent messages.
 *
 * @note The prefix can be removed in a given message if the prefix-removing symbol is
 *       used in the beginning of the message. By default, this symbol is equal to &x00.
 *
 * @param prefix    Prefix to set
 *
 * @noreturn
 */
stock CC_SetPrefix(const prefix[])
{
	_CC_ModInit()
	copy(CC_PREFIX, charsmax(CC_PREFIX), prefix)

	if(!CC_IS_CSCZ)
	{
		CC_RemoveColors(CC_PREFIX, charsmax(CC_PREFIX))
	}
}
	
/**
 * Removes the global message prefix.
 *
 * @noreturn
 */
stock CC_RemovePrefix()
{
	CC_PREFIX[0] = EOS
}

/**
 * Sets the team color for the next message that's going to be sent.
 *
 * @param index     CC_COLOR_* or player index to get color from
 * @param force     If set to true, custom colors in the code will be ignored
 *                  and the message will be forced to use the color set here
 *
 * @noreturn
 */
stock CC_SetColor(index, bool:force = false)
{
	CC_COLOR_PLAYER_INDEX = index
	CC_COLOR_FORCE = force
}

/**
 * This function is used by the other stocks in order to send a raw message.
 *
 * @param id        Client index
 * @param message   The message to send
 *
 * @noreturn
 */
stock _CC_WriteMessage(id, const message[])
{
	static CC_INIT, CC_MSG_SAYTEXT

	if(!CC_INIT)
	{
		CC_INIT = true
		CC_MSG_SAYTEXT = get_user_msgid("SayText")

		// Credits to WPMGPRoSToTeMa
		if(!LibraryExists(CC_LIBRARY_NAME, LibType_Library))
		{
			register_library(CC_LIBRARY_NAME)

			if(CC_IS_CSCZ)
			{
				new iCacheList[] = { CC_COLOR_GREY, CC_COLOR_BLUE, CC_COLOR_RED }
				new szCacheList[][] = { "", "CT", "TERRORIST" }
				new CC_MSG_TEAMINFO = get_user_msgid("TeamInfo")

				for(new i; i < sizeof(iCacheList); i++)
				{
					engfunc(EngFunc_MessageBegin, MSG_INIT, CC_MSG_TEAMINFO, 0, 0)
					write_byte(iCacheList[i])
					write_string(szCacheList[i])
					message_end()
				}

				new iPlayers[CC_MAX_PLAYERS], iPnum
				get_players(iPlayers, iPnum, CC_FILTERING_FLAGS)

				for(new iPlayer, i, j; i < iPnum; i++)
				{
					iPlayer = iPlayers[i]

					for(j = 0; j < sizeof(iCacheList); j++)
					{
						message_begin(MSG_ONE, CC_MSG_TEAMINFO, _, iPlayer)
						write_byte(iCacheList[j])
						write_string(szCacheList[j])
						message_end()
					}
				}
			}
		}
	}

	static const CC_PLAYER_ITEM_PHRASE[] = "#Spec_PlayerItem" // Credits to WPMGPRoSToTeMa

	message_begin(MSG_ONE, CC_MSG_SAYTEXT, _, id)

	if(CC_IS_CSCZ)
	{
		write_byte(CC_COLOR_PLAYER_INDEX && CC_COLOR_PLAYER_INDEX != CC_COLOR_TEAM ? CC_COLOR_PLAYER_INDEX : id)
	}
	else
	{
		write_byte(id)
	}

	write_string(CC_PLAYER_ITEM_PHRASE) 
	write_string(message)
	message_end()
}

/**
 * Checks if the server is running Counter-Strike.
 *
 * @noreturn
 */
stock _CC_ModInit()
{
	static bool:CC_MOD_INIT

	if(!CC_MOD_INIT)
	{
		CC_MOD_INIT = true

		static const CC_CSTRIKE_MODNAME[] = "cstrike"
		static const CC_CZERO_MODNAME[] = "czero"

		new szModName[sizeof(CC_CSTRIKE_MODNAME)]
		get_modname(szModName, charsmax(szModName))

		if(equal(szModName, CC_CSTRIKE_MODNAME) || equal(szModName, CC_CZERO_MODNAME))
		{
			CC_IS_CSCZ = true
		}
	}
}

/**
 * Stores the amx_show_activity pointer for use with "ShowActivity" functions.     	
 *
 * @noreturn
 */
stock _CC_ActivityInit()
{
	CC_FIRST_TIME_ACTIVITY = false
	CC_ACTIVITY_POINTER = get_cvar_pointer("amx_show_activity")

	if(!CC_ACTIVITY_POINTER)
	{
		CC_ACTIVITY_POINTER = register_cvar("amx_show_activity", "2", FCVAR_PROTECTED)
	}
}

/**
 * Returns the player prefix used with "ShowActivity" functions.
 *
 * @param id        Client index
 * @param buffer    Buffer to store the prefix in
 * @param len       Maximum buffer length
 *
 * @noreturn
 */
stock _CC_GetActivityPrefix(id, buffer[CC_MAX_ACT_PREFIX_SIZE], len)
{
	copy(buffer, len, _CC_IsActivityAdmin(id) ? CC_ACTIVITY_PREFIX_ADMIN : CC_ACTIVITY_PREFIX_PLAYER)
}

/**
 * Checks whether the client has the required flag to be marked as an admin for the "ShowActivity" functions.
 *
 * @param id        Client index
 *
 * @return          True if he has, false otherwise
 */
stock bool:_CC_IsActivityAdmin(const id)
{
	#if CC_ACTIVITY_FLAG == -1
	static iFlags
	iFlags = get_user_flags(id)
	return (iFlags > 0 && !(iFlags & ADMIN_USER))
	#else
	return bool:(get_user_flags(id) & CC_ACTIVITY_FLAG)
	#endif
}