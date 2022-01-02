/* Sublime AMXX Editor v4.2 */

/* Thanks for the idea, The Kalu ( https://www.extreamcs.com/forum/the-kalu-u23351.html ) https://www.extreamcs.com/forum/post2815896.html#p2815896 */

#include <amxmodx>
#include <sqlx>
#include <csgo_remake>

#define PLUGIN  "[CS:GO Remake] Save player's skins"
#define VERSION "1.0"
#define AUTHOR  "Shadows Adi"

#if !defined MAX_NAME_LENGTH
#define MAX_NAME_LENGTH 32
#endif

#pragma dynamic 10000

enum _:SqlConnection
{
	szSqlHost[32],
	szSqlUsername[32],
	szSqlPassword[32],
	szSqlDatabase[32]
}

new g_eSqlConnection[SqlConnection]
new Handle:g_hTuple
new Handle:g_hSqlConnection
new g_szError[256]
new g_szQueryData[1700]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_cvar("csgor_save_skins", AUTHOR, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)
}

public csgor_on_configs_executed(iSuccess)
{
	if(iSuccess)
	{
		new pcvar = get_cvar_pointer("csgor_savetype")

		if(get_pcvar_num(pcvar) != 1)
		{

			pause("d")
			return
		}

		csgo_get_database_data(g_eSqlConnection[szSqlHost], charsmax(g_eSqlConnection[szSqlHost]), g_eSqlConnection[szSqlUsername], \
		 charsmax(g_eSqlConnection[szSqlUsername]), g_eSqlConnection[szSqlPassword], charsmax(g_eSqlConnection[szSqlPassword]), \
		 g_eSqlConnection[szSqlDatabase], charsmax(g_eSqlConnection[szSqlDatabase]))

		g_hTuple = SQL_MakeDbTuple(g_eSqlConnection[szSqlHost], g_eSqlConnection[szSqlUsername], g_eSqlConnection[szSqlPassword], g_eSqlConnection[szSqlDatabase])
	
		new iError
		g_hSqlConnection = SQL_Connect(g_hTuple, iError, g_szError, charsmax(g_szError))

		if(g_hSqlConnection == Empty_Handle)
		{
			log_to_file("csgo_remake_errors.log", "[%s] Failed to connect to database. Make sure databse settings are right!", PLUGIN)
			SQL_FreeHandle(g_hSqlConnection)
			return
		}

		formatex(g_szQueryData, charsmax(g_szQueryData), "CREATE TABLE IF NOT EXISTS `csgor_players_skins` \
			(`ID` INT NOT NULL AUTO_INCREMENT,\
			`Name` VARCHAR(%d) NOT NULL,\
			`P90` VARCHAR(%d) NOT NULL, `KNIFE` VARCHAR(%d) NOT NULL, `AK47` VARCHAR(%d) NOT NULL,\
			`SG552` VARCHAR(%d) NOT NULL, `DEAGLE` VARCHAR(%d) NOT NULL, `G3SG1` VARCHAR(%d) NOT NULL, `TMP` VARCHAR(%d) NOT NULL,\
			`M4A1` VARCHAR(%d) NOT NULL, `M3` VARCHAR(%d) NOT NULL, `M249` VARCHAR(%d) NOT NULL, `MP5NAVY` VARCHAR(%d) NOT NULL,\
			`AWP` VARCHAR(%d) NOT NULL, `GLOCK18` VARCHAR(%d) NOT NULL, `USP` VARCHAR(%d) NOT NULL, `FAMAS` VARCHAR(%d) NOT NULL, `GALIL` VARCHAR(%d) NOT NULL,\
			`SG550` VARCHAR(%d) NOT NULL, `UMP45` VARCHAR(%d) NOT NULL, `FIVESEVEN` VARCHAR(%d) NOT NULL, `ELITE` VARCHAR(%d) NOT NULL,\
			`AUG` VARCHAR(%d) NOT NULL, `MAC10` VARCHAR(%d) NOT NULL, `XM1014` VARCHAR(%d) NOT NULL, `SCOUT` VARCHAR(%d) NOT NULL,\
			`P228` VARCHAR(%d) NOT NULL,\
			PRIMARY KEY(ID, Name));", MAX_NAME_LENGTH, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, \
			MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, \
			MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, \
			MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, \
			MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5, MAX_SKIN_NAME + 5)

		new Handle:iQueries = SQL_PrepareQuery(g_hSqlConnection, g_szQueryData)
	
		if(!SQL_Execute(iQueries))
		{
			SQL_QueryError(iQueries, g_szError, charsmax(g_szError))
			log_to_file("csgo_remake_errors.log", "[%s] %s", PLUGIN, g_szError)
		}

		SQL_FreeHandle(iQueries)
	}
}

public csgor_user_logging_in(id)
{
	new szName[MAX_NAME_LENGTH]

	get_user_name(id, szName, charsmax(szName))

	new szSkinName[CSW_P90 + 1][2][MAX_SKIN_NAME]

	for(new i = 1; i < CSW_P90 + 1; i++)
	{
		if(i == CSW_HEGRENADE || i == CSW_SMOKEGRENADE || i == CSW_FLASHBANG || i == CSW_GLOCK /* Unused by game. */ || i == CSW_C4) continue

		csgo_get_user_skin(id, i, szSkinName[i][0], charsmax(szSkinName[][]))
		csgor_get_user_stattrack(id, i, szSkinName[i][1], charsmax(szSkinName[][]))
	}

	new Handle:iQuery = SQL_PrepareQuery(g_hSqlConnection, "SELECT * FROM `csgor_players_skins` WHERE `Name` = '%s';", szName)

	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szError, charsmax(g_szError))
		log_to_file("csgo_remake_errors.log", "[%s] Query error %s", PLUGIN, g_szError)
		return
	}

	new iNum = SQL_NumColumns(iQuery), szField[12], szWeaponFields[1200], szVaules[800], bool:bNone

	g_szQueryData[0] = EOS

	if(SQL_NumResults( iQuery ) > 0)
	{
		formatex(g_szQueryData, charsmax(g_szQueryData), "UPDATE `csgor_players_skins` SET")

		for(new j = 2; j < iNum; j++)
		{
			SQL_FieldNumToName(iQuery, j, szField, charsmax(szField))

			/* Assigning every column, "TEMP" to replace later with player's skins. */
			format(szWeaponFields, charsmax(szWeaponFields), "%s%s `%s`=^"TEMP^"", szWeaponFields, szWeaponFields[0] == EOS ? "" : ",", szField)
		}

		/* Looping backwards because in szSkinName array player's skin name is bacwards and we need to match them with it's column*/
		for(new i = CSW_P90; i > CSW_NONE; i--)
		{
			if(szSkinName[i][0][0] == EOS)
				continue

			if(containi(szSkinName[i][0], "NONE") != -1)
			{
				bNone = true
			}

			formatex(szVaules, charsmax(szVaules), "%s", bNone ? szSkinName[i][1] : szSkinName[i][0])

			/* Replacing "TEMP" fields with player's active skins formatted in szValues[]. */
			replace(szWeaponFields, charsmax(szWeaponFields), "TEMP", szVaules)

			bNone = false
		}

		format(g_szQueryData, charsmax(g_szQueryData), "%s %s WHERE `Name` = ^"%s^" ", g_szQueryData, szWeaponFields, szName)
	}
	else 
	{
		for(new j = 2; j < iNum; j++)
		{
			SQL_FieldNumToName(iQuery, j, szField, charsmax(szField))

			format(szWeaponFields, charsmax(szWeaponFields), "%s%s `%s`", szWeaponFields, szWeaponFields[0] == EOS ? "" : ",", szField)
		}

		for(new i = 1; i < CSW_P90 + 1; i++)
		{
			if(szSkinName[i][0][0] == EOS)
				continue

			if(containi(szSkinName[i][0], "NONE") != -1)
			{
				bNone = true
			}

			format(szVaules, charsmax(szVaules), "^"%s^"%s%s", bNone ? szSkinName[i][1] : szSkinName[i][0], i == 1 ? "" : ",", szVaules)

			bNone = false
		}

		formatex(g_szQueryData, charsmax(g_szQueryData), "INSERT INTO `csgor_players_skins` (`Name`,%s) VALUES (^"%s^", %s);", szWeaponFields, szName, szVaules)
	}

	iQuery = SQL_PrepareQuery(g_hSqlConnection, g_szQueryData)

	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szError, charsmax(g_szError))
		log_to_file("csgo_remake_errors.log", "[%s] Query error %s", PLUGIN, g_szError)
		return
	}
}