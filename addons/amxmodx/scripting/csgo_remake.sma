#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csgo_remake>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <sqlx>
#include <reapi>
#include <cromchat>

/* Uncomment this if you want to enable debug informations. Be carefull, this will spam server's logs */
//#define DEBUG

/* Uncomment this if you want to setup HUD Message */
//#define HUD_POS

#define PLUGIN "[CS:GO Remake] Core"
#define AUTHOR "Shadows Adi"

#define WEAPONS_NR						CSW_P90 + 1

#define weaponsWithoutInspectSkin		((1<<CSW_C4) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE))
#define weaponsNotVaild					((1<<CSW_C4) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_KNIFE))
#define MISC_ITEMS						((1<<CSI_DEFUSER) | (1<<CSI_NVGS) | (1<<CSI_PRIAMMO) | (1<<CSI_SECAMMO) | (1<<CSI_VEST) | (1<<CSI_VESTHELM))

#define EVENT_SVC_INTERMISSION			"30"

/* ----------------------- TASKIDs ----------------------- */

enum (+=1404)
{
	TASK_HUD = 1000,
	TASK_RESET_NAME,
	TASK_RESPAWN,
	TASK_SENDDEATH,
	TASK_INFO,
	TASK_SWAP,
	TASK_SET_ICON,
	TASK_SHELLS,
	TASK_CHECK_NAME,
	TASK_MAP_END,
	TASK_FADE_BLACK,
	TASK_OBS_IN_EYE,
	TASK_PREVIEW
}

enum _:EnumChat
{
	AllChat = 0,
	DeadChat,
	SpecChat,
	CTChat,
	TeroChat
}

enum _:EnumSkinsMenuInfo
{
	ItemName[32],
	ItemId[4]
}

enum _:EnumDynamicMenu
{
	szMenuName[32],
	szMenuCMD[32]
}

enum _:EnumBooleans
{
	bool:IsInPreview = 0,
	bool:IsInInspect,
	bool:IsChangeNotAllowed
}

enum
{
	iNormal = 0,
	iStattrack = 1,
	iPreview = 2
}

enum 
{
	iStandardHUD = 1,
	iAdvancedHUD
}

enum _:EnumForwards
{
	user_log_in = 0,
	user_log_out,
	user_register,
	user_pass_fail,
	user_assist,
	user_mvp,
	user_case_opening,
	user_craft,
	user_level_up,
	file_executed,
	user_drop,
	file_buffer,
	user_weapon_deploy,
	database_loaded,
	account_loaded
}

enum _:EnumCvars
{
	iRegOpen,
	iDropType,
	iKeyPrice,
	iDropChance,
	iCraftCost,
	iStatTrackCost,
	iShowDropCraft,
	szRankUpBonus[16],
	iCmdAccess,
	iOverrideMenu,
	iWarmUpDuration,
	iCompetitive,
	iBestPoints,
	iRespawn,
	iFreezetime,
	iRespawnDelay,
	iMVPMsgType,
	iAMinPoints,
	iAMaxPoints,
	iMVPMinPoints,
	iMVPMaxPoints,
	szNextMapDefault[32],
	iPruneDays,
	iHMinPoints,
	iHMaxPoints,
	iKMinPoints,
	iKMaxPoints,
	iCmdAccess,
	iHMinChance,
	iHMaxChance,
	iKMinChance,
	iKMaxChance,
	szSqlHost[32],
	szSqlUsername[32],
	szSqlPassword[32],
	szSqlDatabase[32],
	iCPreview,
	iStartMoney,
	iFastLoad,
	iWaitForPlace,
	iKeyMinCost,
	iCostMultiplier,
	iCaseMinCost,
	iReturnPercent,
	iShowHUD,
	iSilentWeapDamage,
	iChatTagPrice,
	iChatTagColorPrice,
	Float:flShortThrowVelocity,
	iRoundEndSounds,
	iCopyRight,
	iCustomChat,
	iAntiSpam,
	szUserInfoField[24],
	szChatPrefix[20],
	iNameTagPrice
}

enum _:EnumRoundStats
{
	iCTScore,
	iTeroScore,
	iRoundNum
}

enum
{
	iOpenCase,
	iCraft,
	iCraftStattrack
}

enum _:SelectedSkin
{
	iUserSelected[WEAPONS_NR],
	bool:bIsStattrack[WEAPONS_NR],
	iUserStattrack[WEAPONS_NR]
}

enum _:Items
{
	iItemID,
	iIsStattrack
}

enum _:SpecialMenu
{
	iNone = 0,
	iSell,
	iGift,
	iTrade,
	iNameTag
}

new TraceBullets[][] = { "func_breakable", "func_wall", "func_door", "func_plat", "func_rotating", "worldspawn", "func_door_rotating" }

new g_iWeaponIndex[MAX_PLAYERS + 1]
new g_iUserViewBody[MAX_PLAYERS + 1][WEAPONS_NR]

new inspectAnimation[] =
{
	0, 7, 0, 5, 0, 7, 0, 6, 6, 0, 16 ,6 ,6 ,5 ,6 ,6 ,16, 13, 6, 6, 5, 7, 14, 6, 5, 0, 6, 6, 6, 8, 6
}

new Handle:g_hSqlTuple
new g_szSqlError[512]
new Handle:g_iSqlConnection

new bool:g_bLogged[MAX_PLAYERS + 1]
new bool:g_bLoaded[MAX_PLAYERS + 1]
new g_MsgSync

new g_WarmUpSync
new g_iLastOpenCraft[ MAX_PLAYERS + 1 ]

new g_szCfgDir[48]
new g_szConfigFile[64]

new Array:g_aRankName
new Array:g_aRankKills

new Array:g_aDefaultSubmodel
new Array:g_aDropSkin
new Array:g_aCraftSkin

new Array:g_aSkinsMenu
new Array:g_aDynamicMenu
new Array:g_aSkipChat

new g_iRanksNum
new g_iSkinsNum

new g_iUserSelectedSkin[ MAX_PLAYERS + 1 ][SelectedSkin]
new g_iUserPoints[ MAX_PLAYERS + 1 ]
new g_iUserDusts[ MAX_PLAYERS + 1 ]
new g_iUserKeys[ MAX_PLAYERS + 1 ]
new g_iUserCases[ MAX_PLAYERS + 1 ]
new g_iUserKills[ MAX_PLAYERS + 1 ]
new g_iUserRank[ MAX_PLAYERS + 1 ]
new g_szUserPrefix[ MAX_PLAYERS + 1 ][16]
new g_szUserPrefixColor[ MAX_PLAYERS + 1 ][16]
new g_szTemporaryCtag[ MAX_PLAYERS + 1 ][16]
new g_iDropSkinNum
new g_iCraftSkinNum

new g_szName[ MAX_PLAYERS + 1 ][32]
new g_szSteamID[ MAX_PLAYERS + 1][32]
new g_szUserPassword[ MAX_PLAYERS + 1 ][16]
new g_szUser_SavedPass[ MAX_PLAYERS + 1 ][16]
new g_szUserLastIP[ MAX_PLAYERS + 1 ][19]
new g_iUserPassFail[MAX_PLAYERS + 1]

new g_Msg_SayText
new g_Msg_StatusIcon
new g_Msg_DeathMsg

new g_iUserSellItem[ MAX_PLAYERS + 1 ][Items]
new g_iUserItemPrice[ MAX_PLAYERS + 1 ]
new bool:g_bUserSell[ MAX_PLAYERS + 1 ]

new g_iLastPlace[ MAX_PLAYERS + 1 ]

new g_iMenuType[ MAX_PLAYERS + 1 ]

new g_iGiftTarget[ MAX_PLAYERS + 1 ]
new g_iGiftItem[ MAX_PLAYERS + 1 ][Items]

new g_iTradeTarget[ MAX_PLAYERS + 1 ]
new g_iTradeItem[ MAX_PLAYERS + 1 ][Items]

new bool:g_bTradeActive[ MAX_PLAYERS + 1 ]
new bool:g_bTradeSecond[ MAX_PLAYERS + 1 ]
new bool:g_bTradeAccept[ MAX_PLAYERS + 1 ]
new g_iTradeRequest[ MAX_PLAYERS + 1 ]

new g_iNametagItem[MAX_PLAYERS + 1][Items]
new g_szNameTag[MAX_PLAYERS + 1][20]

new bool:g_bWarmUp

new p_StartMoney
new bool:g_bTeamSwap
new p_Freezetime

new bool:g_bBombExplode
new bool:g_bBombDefused
new g_iBombPlanter
new g_iBombDefuser

new g_iScore[3]
new g_iRoundKills[ MAX_PLAYERS + 1 ]
new g_iDigit[ MAX_PLAYERS + 1 ]
new g_iUserMVP[ MAX_PLAYERS + 1 ]

new g_iDealDamage[ MAX_PLAYERS + 1 ]

new pNextMap
new szNextMap[32]

new g_iMostDamage[ MAX_PLAYERS + 1 ]
new g_iDamage[ MAX_PLAYERS + 1 ][33]

new g_eEnumBooleans[MAX_PLAYERS + 1][EnumBooleans]
new g_bitIsAlive
new g_bitShortThrow

new g_iForwards[ EnumForwards ]
new g_iForwardResult

new g_iCvars[EnumCvars]
new g_iStats[EnumRoundStats]

new g_szTWin[] =
{
	"csgor/twin.wav"
}

new g_szCTWin[] =
{
	"csgor/ctwin.wav"
}

new g_szCaseOpen[] =
{
	"csgor/caseopen.wav"
}

new const g_szBombPlanting[] = "csgor/bomb_planting.wav"

new const g_szBombDefusing[] = "csgor/bomb_defusing.wav"

new GrenadeName[][] =
{
	"weapon_hegrenade",
	"weapon_flashbang",
	"weapon_smokegrenade"
}

new const g_iMaxBpAmmo[] =
{
	0,
	52,
	0,
	90,
	1,
	32,
	1,
	100,
	90,
	1,
	120,
	100,
	100,
	90,
	90,
	90,
	100,
	120,
	30,
	120,
	200,
	21,
	90,
	120,
	90,
	2,
	35,
	90,
	90,
	0,
	100 
}

new const g_szAmmoType[][] = 
{
	"", 
	"357sig", 
	"",
	"762nato",
	"", 
	"buckshot", 
	"", 
	"45acp", 
	"556nato", 
	"", 
	"9mm", 
	"57mm", 
	"45acp",
	"556nato", 
	"556nato", 
	"556nato", 
	"45acp", 
	"9mm", 
	"338magnum", 
	"9mm", 
	"556natobox", 
	"buckshot",
	"556nato", 
	"9mm", 
	"762nato", 
	"", 
	"50ae", 
	"556nato", 
	"762nato", 
	"", 
	"57mm" 
}

new szSprite[][] =
{
	"number_0",
	"number_1",
	"number_2",
	"number_3",
	"number_4",
	"number_5",
	"number_6",
	"number_7",
	"number_8",
	"number_9",
	"dmg_rad"
};	
 
#if defined HUD_POS
new Float:HUD_POS_X = 0.02
new Float:HUD_POS_Y = 0.90
#endif

new g_iMaxPlayers

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

new Trie:g_tDataTrie

new bool:g_bSkinsRendering = true

new Array:g_aSkinData

new Array:g_aDefaultData

new Array:g_aPlayerSkins[MAX_PLAYERS + 1]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new pcvar = create_cvar("csgor_author", "Shadows Adi", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY, "DO NOT MODIFY!" )

	pcvar = create_cvar("csgor_dbase_host", "localhost", FCVAR_SPONLY | FCVAR_PROTECTED, "Database Host")
	bind_pcvar_string(pcvar, g_iCvars[szSqlHost], charsmax(g_iCvars[szSqlHost]))

	pcvar = create_cvar("csgor_dbase_user", "username", FCVAR_SPONLY | FCVAR_PROTECTED, "Database Username")
	bind_pcvar_string(pcvar, g_iCvars[szSqlUsername], charsmax(g_iCvars[szSqlUsername]))

	pcvar = create_cvar("csgor_dbase_pass", "password", FCVAR_SPONLY | FCVAR_PROTECTED, "Database Password")
	bind_pcvar_string(pcvar, g_iCvars[szSqlPassword], charsmax(g_iCvars[szSqlPassword]))

	pcvar = create_cvar("csgor_dbase_database", "database", FCVAR_SPONLY | FCVAR_PROTECTED, "Database Name")
	bind_pcvar_string(pcvar, g_iCvars[szSqlDatabase], charsmax(g_iCvars[szSqlDatabase]))

	pcvar = create_cvar("csgor_prunedays", "60", FCVAR_NONE, "(0|∞) The accounts will be erased in X days of inactivity", true, 0.0 )
	bind_pcvar_num(pcvar, g_iCvars[iPruneDays])
	
	pcvar = create_cvar("csgor_default_map", "de_dust2", FCVAR_NONE, "If cvar ^"amx_nextmap^" doesn't exist, this will be the next map, only if ^"csgor_competitive_mode^" is ^"1^"")
	bind_pcvar_string(pcvar, g_iCvars[szNextMapDefault], charsmax(g_iCvars[szNextMapDefault]))
	
	pcvar = create_cvar("csgor_override_menu", "1", FCVAR_NONE, "(0|1)  Main menu will open with ^"M^" key", true, 0.0, true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iOverrideMenu])
	
	pcvar = create_cvar("csgor_show_hud", "2", FCVAR_NONE, "(0|1|2) HUD Info^n 0 - Deactivated || 1 - Classic HUD || 2 - Advanced HUD", true, 0.0, true, 2.0 )
	bind_pcvar_num(pcvar, g_iCvars[iShowHUD])
	
	pcvar = create_cvar("csgor_head_minpoints", "11", FCVAR_NONE, "How much points for a HeadShot kill^n(MINIMUM)", true, 0.0 )
	bind_pcvar_num(pcvar, g_iCvars[iHMinPoints])
	
	pcvar = create_cvar("csgor_head_maxpoints", "15", FCVAR_NONE, "How much points for a HeadShot kill^n(MAXIMUM)", true, 0.0 )
	bind_pcvar_num(pcvar, g_iCvars[iHMaxPoints])
	
	pcvar = create_cvar("csgor_kill_minpoints", "6", FCVAR_NONE, "How much points for a kill^n(MINIMUM)", true, 0.0 )
	bind_pcvar_num(pcvar, g_iCvars[iKMinPoints])
	
	pcvar = create_cvar("csgor_kill_maxpoints", "10", FCVAR_NONE, "How much points for a kill^n(MAXIMUM)", true, 0.0 )
	bind_pcvar_num(pcvar, g_iCvars[iKMaxPoints])
	
	pcvar = create_cvar("csgor_head_minchance", "25", FCVAR_NONE, "Drop chance ( case ) if kill is made by HeadShot^n(MINIMUM)", true, 0.0, true, 99.0 )
	bind_pcvar_num(pcvar, g_iCvars[iHMinChance])
	
	pcvar = create_cvar("csgor_head_maxchance", "100", FCVAR_NONE, "Drop chance ( case ) if kill is made by HeadShot^n(MAXIMUM)", true, 0.0, true, 100.0 )
	bind_pcvar_num(pcvar, g_iCvars[iHMaxChance])
	
	pcvar = create_cvar("csgor_kill_minchance", "0", FCVAR_NONE, "Drop chance ( case ) for a basic kill^n(MINIMUM)", true, 0.0, true, 99.0 )
	bind_pcvar_num(pcvar, g_iCvars[iKMinChance])
	
	pcvar = create_cvar("csgor_kill_maxchance", "100", FCVAR_NONE, "Drop chance ( case ) for a basic kill^n(MAXIMUM)", true, 0.0, true, 100.0 )
	bind_pcvar_num(pcvar, g_iCvars[iKMaxChance])
	
	pcvar = create_cvar("csgor_assist_minpoints", "3", FCVAR_NONE, "How much points for an assist^n(MINIMUM)", true, 0.0, true, 99.0 )
	bind_pcvar_num(pcvar, g_iCvars[iAMinPoints])
	
	pcvar = create_cvar("csgor_assist_maxpoints", "5", FCVAR_NONE, "How much points for an assist^n(MAXIMUM)", true, 0.0, true, 100.0 )
	bind_pcvar_num(pcvar, g_iCvars[iAMaxPoints])
	
	pcvar = create_cvar("csgor_mvp_minpoints", "20", FCVAR_NONE, "How much points the MVP receive^n(MINIMUM)", true, 0.0 )
	bind_pcvar_num(pcvar, g_iCvars[iMVPMinPoints])
	
	pcvar = create_cvar("csgor_mvp_maxpoints", "30", FCVAR_NONE, "How much points the MVP receive^n(MAXIMUM)", true, 0.0 )
	bind_pcvar_num(pcvar, g_iCvars[iMVPMaxPoints])
	
	pcvar = create_cvar("csgor_mvp_msgtype", "0", FCVAR_NONE, "(0|1|2|3) MVP Message Type^n 0 - No Message is shown^n 1 - Chat Message^n 2 - HUD Message^n 3 - DHUD Message", true, 0.0, true, 3.0 )
	bind_pcvar_num(pcvar, g_iCvars[iMVPMsgType])
	
	pcvar = create_cvar("csgor_register_open", "1", FCVAR_NONE, "(0|1) Possibility to register new accounts^n 0 - New accounts can't be registered^n 1 - New accounts can be registered", true, 0.0, true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iRegOpen])
	
	pcvar = create_cvar("csgor_best_points", "300", FCVAR_NONE, "How much points receives the best player from a half", true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iBestPoints])
	
	pcvar = create_cvar("csgor_rangup_bonus", "kc|200", FCVAR_NONE, "Rank Up Bonus^nExample: ^"kkccc|300^". The player will get: 2 keys and 3 cases and 300 points^nMinimum value: ^"|^" - the player don't receive anything. ^"|10^" - get 10 points. ^"k|^" - get 1 key. ^"c|^" - get 1 case" )
	bind_pcvar_string(pcvar, g_iCvars[szRankUpBonus], charsmax(g_iCvars[szRankUpBonus]))
	
	pcvar = create_cvar("csgor_return_percent", "10", FCVAR_NONE, "When destroying the skins, the player receives points.^n1 / value = how much points the player receives", true, 0.0 )
	bind_pcvar_num(pcvar, g_iCvars[iReturnPercent])
	
	pcvar = create_cvar("csgor_drop_type", "1", FCVAR_NONE, "Drop type^n0 - drop cases and keys; 1 - drop only cases, the keys needs to be bought", true, 0.0, true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iDropType])
	
	pcvar = create_cvar("csgor_key_price", "250", FCVAR_NONE, "Key Price^nOnly if cvar ^"csgor_drop_type^" is ^"1^"", true, 0.0 )
	bind_pcvar_num(pcvar, g_iCvars[iKeyPrice])
	
	pcvar = create_cvar("csgor_competitive_mode", "1", FCVAR_NONE, "(0|1) Two halfs each of 15 rounds are played.^nAfter the first half, the teams are changing + round restart.^nAfter the second half, map is changing.^nPay attention! This needs ^"mapcycle.txt^" configured right!", true, 0.0, true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iCompetitive])
	
	pcvar = create_cvar("csgor_warmup_duration", "60", FCVAR_NONE, "WarmUp Time", true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iWarmUpDuration])
	
	pcvar = create_cvar("csgor_show_dropcraft", "1", FCVAR_NONE, "(0|1) Show other player's drop.^n0 - Show the drop only to the beneficiary^n1 - Show the drop to all palyers.", true, 0.0, true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iShowDropCraft])
	
	pcvar = create_cvar("csgor_item_cost_multiplier", "20", FCVAR_NONE, "The quota by which the minimum price of the key / box is multiplied to get the MAXIMUM price", true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iCostMultiplier])
	
	pcvar = create_cvar("csgor_chattag_cost", "800", FCVAR_NONE, "The price of a chat prefix", true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iChatTagPrice])
	
	pcvar = create_cvar("csgor_chattag_color_cost", "500", FCVAR_NONE, "The price of a color for the chat prefix", true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iChatTagColorPrice])

	pcvar = create_cvar("csgor_silenced_weap_type", "1", FCVAR_NONE, "(0|1) Weapons with silencer will have damage similar to that of CS:GO's ones ( M4A1-S ; USP-S ).", true, 0.0, true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iSilentWeapDamage])

	pcvar = create_cvar("csgor_respawn_enable", "0", FCVAR_NONE, "(0|1) Respawn Mode", true, 0.0, true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iRespawn])
	
	pcvar = create_cvar("csgor_respawn_delay", "3", FCVAR_NONE, "How much seconds till player will respawn. If ^"csgor_respawn_enable^" is ^"1^".")
	bind_pcvar_num(pcvar, g_iCvars[iRespawnDelay])
	
	pcvar = create_cvar("csgor_dropchance", "85", FCVAR_NONE, "Chance of receiving a drop^nBetween 0 and 99^nThe higher the number, the less often you receive a drop", true, 0.0, true, 99.0 )
	bind_pcvar_num(pcvar, g_iCvars[iDropChance])
	
	pcvar = create_cvar("csgor_craft_cost", "10", FCVAR_NONE, "How many scraps do player need to create a rare skin", true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iCraftCost])
	
	pcvar = create_cvar("csgor_craft_stattrack_cost", "30", FCVAR_NONE, "How many scraps do player need to create a StatTrack skin?", true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iStatTrackCost])

	pcvar = create_cvar("csgor_case_min_cost", "100", FCVAR_NONE, "The minimum price for a box put up for sale", true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iCaseMinCost])
	
	pcvar = create_cvar("csgor_key_min_cost", "100", FCVAR_NONE, "The minimum price for a key put up for sale", true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iKeyMinCost])
	
	pcvar = create_cvar("csgor_wait_for_place", "30", FCVAR_NONE, "How many seconds do you have to wait until you can place a new ad", true, 1.0 )
	bind_pcvar_num(pcvar, g_iCvars[iWaitForPlace])
	
	pcvar = create_cvar("csgor_freezetime", "2", FCVAR_NONE, "Players freezetime ( exepct when teams are changing and end map )", true, 0.0)
	bind_pcvar_num(pcvar, g_iCvars[iFreezetime])

	pcvar = create_cvar("csgor_startmoney", "850", FCVAR_NONE, "Players start money", true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iStartMoney])

	pcvar = create_cvar("csgor_preview_time", "7", FCVAR_NONE, "How much time a player can preview a skin?", true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iCPreview])

	pcvar = create_cvar("csgor_fast_load", "1", FCVAR_NONE, "Fast resources load for players", .has_max = true, .max_val = 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iFastLoad])

	pcvar = create_cvar("csgor_grenade_shortthrow_velocity", "0.50", FCVAR_NONE, "Velocity ( in floating value ) of a grenade when it's in short throw mode.")
	bind_pcvar_float(pcvar, g_iCvars[flShortThrowVelocity])

	pcvar = create_cvar("csgor_enable_roundend_sounds", "1", FCVAR_NONE, "(0|1) Enable / Disable Round End sounds.", true, 0.0, true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iRoundEndSounds])

	pcvar = create_cvar("csgor_show_copyright", "1", FCVAR_NONE, "(0|1) Show / Hide Copyright Information ( Plugin Author )", true, 0.0, true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iCopyRight])

	pcvar = create_cvar("csgor_custom_chat", "1", FCVAR_NONE, "(0|1) Enable / Disable Mod's custom chat ( Chat rank, chat prefix, etc )", true, 0.0, true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iCustomChat])

	pcvar = create_cvar("csgor_antispam_drop", "1", FCVAR_NONE, "(0|1) Enable / Disable anti spam in chat while opening / crafting skins.^n ATTENTION! If ^"csgor_show_dropcraft^" is ^"1^" anti spam is always active.", true, 0.0, true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iAntiSpam])

	pcvar = create_cvar("csgor_userinfo_field", "_csgorpw", FCVAR_NONE, "Userinfo field to check / store player's account password")
	bind_pcvar_string(pcvar, g_iCvars[szUserInfoField], charsmax(g_iCvars[szUserInfoField]))

	pcvar = create_cvar("csgor_chat_prefix", "[CS:GO Remake]", FCVAR_NONE, "Message's prefix in Chat")
	bind_pcvar_string(pcvar, g_iCvars[szChatPrefix], charsmax(g_iCvars[szChatPrefix]))

	pcvar = create_cvar("csgor_skin_nametag_price", "2300", FCVAR_NONE, "Price for applying a Name Tag on a Skin.")
	bind_pcvar_num(pcvar, g_iCvars[iNameTagPrice])

	pcvar = create_cvar("csgor_commands_access", "a", FCVAR_NONE, "Access flags for admin commands.^nMaximum 9 flags.")
	bind_pcvar_string(pcvar, g_iCvars[iCmdAccess], charsmax(g_iCvars[iCmdAccess]))

	AutoExecConfig(true, "csgo_remake", "csgor" )

	new szTemp[23]
	formatex(szTemp, charsmax(szTemp), "^4%s", g_iCvars[szChatPrefix])
	CC_SetPrefix(szTemp)
	
	register_cvar("csgore_version", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)

	register_dictionary("csgor_language.txt")
	
	g_Msg_SayText = get_user_msgid("SayText")
	g_Msg_StatusIcon = get_user_msgid("StatusIcon")
	g_Msg_DeathMsg = get_user_msgid("DeathMsg")

	register_message(g_Msg_SayText, "Message_SayText")
	register_message(g_Msg_DeathMsg, "Message_DeathMsg")

	register_event("HLTV", "ev_NewRound", "a", "1=0", "2=0")
	register_event("TextMsg", "event_Game_Restart", "a", "2=#Game_will_restart_in")
	register_event("TextMsg", "event_Game_Commencing", "a", "2&#Game_C")
	register_event("SendAudio", "ev_RoundWon_T", "a", "2&%!MRAD_terwin")
	register_event("SendAudio", "ev_RoundWon_CT", "a", "2=%!MRAD_ctwin")
	register_event(EVENT_SVC_INTERMISSION, "ev_Intermission", "a")
	register_event("DeathMsg", "ev_DeathMsg", "ae", "1>0")
	register_event("Damage", "ev_Damage", "be", "2!0", "3=0", "4!0")

	for ( new i; i < sizeof(GrenadeName); i++ )
	{
		RegisterHam(Ham_Weapon_PrimaryAttack, GrenadeName[i], "Ham_GrenadePrimaryAttack_Pre")
		RegisterHam(Ham_Weapon_SecondaryAttack, GrenadeName[i], "Ham_GrenadeSecondaryAttack_Pre")
	}
	
	for (new i; i < sizeof(TraceBullets); i++)
	{
		RegisterHam(Ham_TraceAttack, TraceBullets[i], "HamF_TraceAttack_Post", 1)
	}

	RegisterHam(Ham_Spawn, "player", "Ham_Player_Spawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "Ham_Take_Damage_Post", 1)
	RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Pre"); 
	RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_m4a1", "Ham_BlockSecondaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "Ham_BlockSecondaryAttack", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_m4a1" ,"Ham_BlockSecondaryAttack", 1)

	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "RG_CBasePlayerWeapon_DefaultDeploy_Post", 1)
	RegisterHookChain(RG_CBasePlayer_DropPlayerItem, "RG_CBasePlayer_DropPlayerItem_Pre")
	register_forward(FM_ClientUserInfoChanged, "FM_ClientUserInfoChanged_Pre")

	p_Freezetime = get_cvar_pointer("mp_freezetime")
	p_StartMoney = get_cvar_pointer("mp_startmoney")
	pNextMap = get_cvar_pointer("amx_nextmap")

	g_MsgSync = CreateHudSyncObj()
	g_WarmUpSync = CreateHudSyncObj()

	g_iMaxPlayers = get_maxplayers()

	#if defined HUD_POS
	register_clcmd("say /hudpos_menu", "clcmd_say_hudpos")
	#endif

	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_sayteam")
	register_clcmd("say /reg", "clcmd_say_reg")
	register_clcmd("say /menu", "clcmd_say_menu")
	register_clcmd("say /skin", "clcmd_say_skin")
	register_clcmd("say /accept", "clcmd_say_accept")
	register_clcmd("say /deny", "clcmd_say_deny")
	register_clcmd("say /savepass", "clcmd_say_savepass")

	register_concmd("inspect", "inspect_weapon")
	register_concmd("preview", "clcmd_say_preview")
	register_concmd("inventory", "clcmd_say_inventory")
	register_concmd("opencase", "clcmd_say_opencase")
	register_concmd("dustbin", "clcmd_say_dustbin")
	register_concmd("market", "clcmd_say_market")
	register_concmd("gift", "clcmd_say_gifttrade")
	register_concmd("trade", "clcmd_say_gifttrade")
	
	register_concmd("UserPassword", "concmd_password")
	register_concmd("ChatTag", "concmd_chattag")
	register_concmd("ItemPrice", "concmd_itemprice")
	register_concmd("NameTag", "concmd_nametag")

	RegisterHookChain(RG_CBasePlayer_ImpulseCommands, "RG_CBasePlayer_ImpulseCommands_Pre", 0)

	new Access = read_flags(g_iCvars[iCmdAccess])

	register_concmd("amx_givepoints", "concmd_givepoints", Access, "<Name> <Amount>")
	register_concmd("amx_givecases", "concmd_givecases", Access, "<Name> <Amount>")
	register_concmd("amx_givekeys", "concmd_givekeys", Access, "<Name> <Amount>")
	register_concmd("amx_givedusts", "concmd_givedusts", Access, "<Name> <Amount>")
	register_concmd("amx_setskins", "concmd_giveskins", Access, "<Name> <SkinID> <Amount>")
	register_concmd("amx_give_all_skins", "concmd_give_all_skins", Access, "<Name> <Stattrack>")
	register_concmd("amx_setrank", "concmd_setrank", Access, "<Name> <Rank ID>")
	register_concmd("amx_finddata", "concmd_finddata", Access, "<Name>")
	register_concmd("amx_resetdata", "concmd_resetdata", Access, "<Name> <Mode>")
	register_concmd("amx_change_pass", "concmd_changepass", Access, "<Name> <New Password>")
	register_concmd("csgor_getinfo", "concmd_getinfo", Access, "<Type> <Index>")
	register_concmd("amx_nick_csgo", "concmd_nick", Access, "<Name> <New Name>")
	register_concmd("amx_skin_index", "concmd_skin_index", Access, "<Skin Name>")

	if (g_iCvars[iOverrideMenu])
	{
		register_clcmd("chooseteam", "clcmd_chooseteam")
	}
}

public plugin_cfg()
{
	set_task(0.1, "DatabaseConnect")
}

public DatabaseConnect()
{
	g_hSqlTuple = SQL_MakeDbTuple(g_iCvars[szSqlHost], g_iCvars[szSqlUsername], g_iCvars[szSqlPassword], g_iCvars[szSqlDatabase])

	new iError
	g_iSqlConnection = SQL_Connect(g_hSqlTuple, iError, g_szSqlError, charsmax(g_szSqlError))

	ExecuteForward(g_iForwards[ database_loaded ])

	if(g_iSqlConnection == Empty_Handle)
	{
		log_to_file("csgo_remake_errors.log", "CSGO REMAKE Failed to connect to database. Make sure databse settings are right!")
		SQL_FreeHandle(g_iSqlConnection)

		return
	}

	new szQueryData[600]
	formatex(szQueryData, charsmax(szQueryData),"CREATE TABLE IF NOT EXISTS `csgor_data` \
		(`ID` INT NOT NULL AUTO_INCREMENT,\
		`Name` VARCHAR(32) NOT NULL,\
		`SteamID` VARCHAR(32) NOT NULL,\
		`Last IP` VARCHAR(19) NOT NULL,\
		`Password` VARCHAR(32) NOT NULL,\
		`ChatTag` VARCHAR(16) NOT NULL,\
		`ChatTag Color` VARCHAR(4) NOT NULL,\
		`Points` INT(10) NOT NULL,\
		`Scraps` INT(12) NOT NULL,\
		`Keys` INT(12) NOT NULL,\
		`Cases` INT(12) NOT NULL,\
		`Kills` INT(12) NOT NULL,\
		`Rank` INT(2) NOT NULL,\
		`Bonus Timestamp` INT NOT NULL,\
		PRIMARY KEY(ID, Name));")

	new Handle:iQueries = SQL_PrepareQuery(g_iSqlConnection, szQueryData)

	if(!SQL_Execute(iQueries))
	{
		SQL_QueryError(iQueries, g_szSqlError, charsmax(g_szSqlError))
		log_amx(g_szSqlError)
	}

	formatex(szQueryData, charsmax(szQueryData), "SELECT `SteamID` FROM `csgor_data`")

	iQueries = SQL_PrepareQuery(g_iSqlConnection, szQueryData)

	if(!SQL_Execute(iQueries))
	{
		SQL_QueryError(iQueries, g_szSqlError, charsmax(g_szSqlError))

		if(containi(g_szSqlError, "Unknown column") != -1)
		{
			formatex(szQueryData, charsmax(szQueryData), "ALTER TABLE `csgor_data` ADD `SteamID` varchar(32) NOT NULL AFTER `Name`, \
				ADD `Last IP` varchar(19) NOT NULL AFTER `SteamID`;")

			iQueries = SQL_PrepareQuery(g_iSqlConnection, szQueryData)
	
			if(!SQL_Execute(iQueries))
			{
				SQL_QueryError(iQueries, g_szSqlError, charsmax(g_szSqlError))
				log_amx(g_szSqlError)
			}
		}
	}

	formatex(szQueryData, charsmax(szQueryData), "CREATE TABLE IF NOT EXISTS `csgor_skins` \
		(`Name` VARCHAR(32) NOT NULL,\
		`WeaponID` INT NOT NULL, \
		`Skin` VARCHAR(%d) NOT NULL,\
		`Selected` INT NOT NULL DEFAULT 0, \
		`Stattrack` INT NOT NULL DEFAULT 0, \
		`Kills` INT NOT NULL DEFAULT 0, \
		`Piece` INT NOT NULL DEFAULT 0, \
		`NameTag` VARCHAR(32) NOT NULL, \
		PRIMARY KEY(Name, WeaponID, Skin, StatTrack));", MAX_SKIN_NAME)

	iQueries = SQL_PrepareQuery(g_iSqlConnection, szQueryData)

	if(!SQL_Execute(iQueries))
	{
		SQL_QueryError(iQueries, g_szSqlError, charsmax(g_szSqlError))
		log_amx(g_szSqlError)

		return
	}

	SQL_FreeHandle(iQueries)
}

public plugin_precache()
{
	RegisterForwards()

	precache_sound(g_szTWin)
	precache_sound(g_szCTWin)
	precache_sound(g_szCaseOpen)
	precache_sound(g_szBombPlanting)
	precache_sound(g_szBombDefusing)

	new iFile = fopen(g_szConfigFile, "rt")
	if (!iFile)
	{
		set_fail_state("%s Could not open file csgor_configs.ini .", g_iCvars[szChatPrefix])
	}

	new szBuffer[428], FileSections:iSection, iLine
	new szLeftpart[MAX_SKIN_NAME], szRightPart[24], iDefaultSubmodel[8]
	new weaponid[4], weapontype[4], weaponchance[8], weaponcostmin[8], weaponcostmax[8], weapondusts[8], weaponsubmodel[8], szLocked[3]

	static eSkinData[SkinData]
	
	new szChatSkip[20]
	new Weapons[EnumSkinsMenuInfo]
	new MenuInfo[EnumDynamicMenu]
	new iEnd = -1

	while (!feof(iFile))
	{
		fgets(iFile, szBuffer, charsmax(szBuffer))

		trim(szBuffer)

		iLine += 1

		if (!(!szBuffer[0] || szBuffer[0] == ';'))
		{
			if (szBuffer[0] == '[')
			{
				iSection++
				continue
			}

			switch (iSection)
			{
				case secRanks:
				{
					parse(szBuffer, szLeftpart, charsmax(szLeftpart), szRightPart, charsmax(szRightPart))

					ArrayPushString(g_aRankName, szLeftpart)
					ArrayPushCell(g_aRankKills, str_to_num(szRightPart))

					g_iRanksNum += 1
				}
				case secDefaultModels:
				{
					parse(szBuffer, weaponid, charsmax(weaponid), eSkinData[szViewModel], charsmax(eSkinData[szViewModel]), eSkinData[szWeaponModel], charsmax(eSkinData[szWeaponModel]), iDefaultSubmodel, charsmax(iDefaultSubmodel))

					eSkinData[iWeaponID] = str_to_num(weaponid)
					eSkinData[iSubModelID] = str_to_num(iDefaultSubmodel)

					if(eSkinData[szViewModel][0] != '-')
					{
						if (file_exists(eSkinData[szViewModel]))
						{
							precache_model(eSkinData[szViewModel])
						}
						else
						{
							log_to_file("csgo_remake_errors.log" ,"%s Can't find %s v_model on DEFAULT iSection. Line %i", g_iCvars[szChatPrefix], eSkinData[szViewModel], iLine)
						}
					}

					if(eSkinData[szWeaponModel][0] != '-')
					{
						if(file_exists(eSkinData[szWeaponModel]))
						{
							precache_model(eSkinData[szWeaponModel])
						}
						else
						{
							log_to_file("csgo_remake_errors.log" ,"%s Can't find %s p/w_model on DEFAULT iSection. Line %i", g_iCvars[szChatPrefix], eSkinData[szWeaponModel], iLine)

							continue
						}
					}

					ArrayPushArray(g_aDefaultData, eSkinData)
				}
				case secSkins:
				{
					parse(szBuffer, weaponid, charsmax(weaponid), eSkinData[szSkinName], charsmax(eSkinData[szSkinName]), eSkinData[szViewModel], charsmax(eSkinData[szViewModel]), eSkinData[szWeaponModel], charsmax(eSkinData[szWeaponModel]), weaponsubmodel, charsmax(weaponsubmodel), weapontype, charsmax(weapontype), weaponchance, charsmax(weaponchance), weaponcostmin, charsmax(weaponcostmin), weaponcostmax, charsmax(weaponcostmax), weapondusts, charsmax(weapondusts), szLocked, charsmax(szLocked))

					if (file_exists(eSkinData[szViewModel]))
					{
						precache_model(eSkinData[szViewModel])
					}
					else
					{
						log_to_file("csgo_remake_errors.log" ,"%s Can't find %s v_model for SKINS. Param: 3. Line %i", g_iCvars[szChatPrefix], eSkinData[szViewModel], iLine)
						continue
					}

					if (file_exists(eSkinData[szWeaponModel]))
					{
						eSkinData[bHasWeaponModel] = true
						precache_model(eSkinData[szWeaponModel])
					}

					eSkinData[iWeaponID] = str_to_num(weaponid)

					eSkinData[iSubModelID] = str_to_num(weaponsubmodel)
					eSkinData[iSkinType] = weapontype[0]
					eSkinData[iSkinChance] = str_to_num(weaponchance)
					eSkinData[iSkinCostMin] = str_to_num(weaponcostmin)
					eSkinData[iSkinCostMax] = str_to_num(weaponcostmax)
					eSkinData[iSkinDust] = str_to_num(weapondusts)
					eSkinData[iSkinLock] = str_to_num(szLocked)

					ArrayPushArray(g_aSkinData, eSkinData)

					switch (eSkinData[iSkinType])
					{
						case 'c':
						{
							ArrayPushCell(g_aCraftSkin, g_iSkinsNum)

							g_iCraftSkinNum += 1
						}
						case 'd':
						{
							ArrayPushCell(g_aDropSkin, g_iSkinsNum)

							g_iDropSkinNum += 1
						}
					}

					g_iSkinsNum += 1
				}
				case secSortedMenu:
				{
					parse(szBuffer, Weapons[ItemName], charsmax(Weapons[ItemName]), Weapons[ItemId], charsmax(Weapons[ItemId]))

					ArrayPushArray(g_aSkinsMenu, Weapons)
				}
				case secDynamicMenu:
				{
					parse(szBuffer, MenuInfo[szMenuName], charsmax(MenuInfo[szMenuName]), MenuInfo[szMenuCMD], charsmax(MenuInfo[szMenuCMD]))

					ArrayPushArray(g_aDynamicMenu, MenuInfo)
				}
				case secSkipChat:
				{
					parse(szBuffer, szChatSkip, charsmax(szChatSkip))

					ArrayPushString(g_aSkipChat, szChatSkip)
				}
			}

			ExecuteForward(g_iForwards[ file_buffer ], g_iForwardResult, szBuffer, iSection, iLine)
		}
	}

	iEnd = 1

	fclose(iFile)
	
	set_task(0.1, "precache_mess", iEnd)
}

public precache_mess(iEnd)
{
	log_amx("CS:GO Remake by Shadows Adi (v%s).", VERSION)

	ExecuteForward(g_iForwards[file_executed], g_iForwardResult, iEnd)
}

RegisterForwards()
{
	g_iForwards[ user_log_in ] = CreateMultiForward("csgor_user_logging_in", ET_IGNORE, FP_CELL)
	g_iForwards[ user_log_out ] = CreateMultiForward("csgor_user_logging_out", ET_IGNORE, FP_CELL)
	g_iForwards[ user_register ] = CreateMultiForward("csgor_user_register", ET_IGNORE, FP_CELL)
	g_iForwards[ user_pass_fail ] = CreateMultiForward("csgor_user_password_failed", ET_IGNORE, FP_CELL, FP_CELL)
	g_iForwards[ user_assist ] = CreateMultiForward("csgor_user_assist", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL)
	g_iForwards[ user_mvp ] = CreateMultiForward("csgor_user_mvp", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_iForwards[ user_case_opening ] = CreateMultiForward("csgor_user_case_open", ET_IGNORE, FP_CELL)
	g_iForwards[ user_craft ] = CreateMultiForward("csgor_user_craft", ET_IGNORE, FP_CELL)
	g_iForwards[ user_level_up ] = CreateMultiForward("csgor_user_levelup", ET_IGNORE, FP_CELL, FP_STRING, FP_CELL)
	g_iForwards[ file_executed ] = CreateMultiForward("csgor_on_configs_executed", ET_IGNORE, FP_CELL)
	g_iForwards[ user_drop ] = CreateMultiForward("csgor_on_user_drop", ET_IGNORE, FP_CELL)
	g_iForwards[ file_buffer ] = CreateMultiForward("csgor_read_configuration_data", ET_IGNORE, FP_STRING, FP_CELL, FP_CELL)
	g_iForwards[ user_weapon_deploy ] = CreateMultiForward("csgor_weapon_deploy", ET_IGNORE, FP_CELL, FP_CELL)
	g_iForwards[ database_loaded ] = CreateMultiForward("csgor_database_loaded", ET_IGNORE)
	g_iForwards[ account_loaded ] = CreateMultiForward("csgor_account_loaded", ET_IGNORE, FP_CELL)
}

public plugin_natives()
{
	get_configsdir(g_szCfgDir, charsmax(g_szCfgDir))

	formatex(g_szConfigFile, charsmax(g_szConfigFile), "%s/csgor_configs.ini", g_szCfgDir)

	if (!file_exists(g_szConfigFile))
		set_fail_state("%s File not found: ...%s", g_iCvars[szChatPrefix], g_szConfigFile)
	
	g_aRankName = ArrayCreate(MAX_RANK_NAME)
	g_aRankKills = ArrayCreate(1)
	g_aDefaultSubmodel = ArrayCreate(1)
	g_aDropSkin = ArrayCreate(1)
	g_aCraftSkin = ArrayCreate(1)

	g_aSkinsMenu = ArrayCreate(EnumSkinsMenuInfo)
	g_aDynamicMenu = ArrayCreate(EnumDynamicMenu)
	g_aSkipChat = ArrayCreate(20)

	g_tDataTrie = TrieCreate()
	g_aSkinData = ArrayCreate(SkinData)

	g_aDefaultData = ArrayCreate(iSubModelID)

	for(new i = 1; i <= get_maxplayers(); i++)
	{
		g_aPlayerSkins[i] = ArrayCreate(PlayerSkins)
	}

	register_library("csgo_remake")

	register_native("csgor_get_user_points", "native_get_user_points")
	register_native("csgor_set_user_points", "native_set_user_points")
	register_native("csgor_get_user_cases", "native_get_user_cases")
	register_native("csgor_set_user_cases", "native_set_user_cases")
	register_native("csgor_get_user_keys", "native_get_user_keys")
	register_native("csgor_set_user_keys", "native_set_user_keys")
	register_native("csgor_get_user_dusts", "native_get_user_dusts")
	register_native("csgor_set_user_dusts", "native_set_user_dusts")
	register_native("csgor_get_user_rank", "native_get_user_rank")
	register_native("csgor_set_user_rank", "native_set_user_rank")
	register_native("csgor_get_user_skinsnum", "native_csgor_get_user_skinsnum")
	register_native("csgor_get_user_skins", "native_get_user_skins")
	register_native("csgor_set_user_all_skins", "native_set_user_all_skins")
	register_native("csgor_set_user_skins", "native_set_user_skins")
	register_native("csgor_get_skins_num", "native_get_skins_num")
	register_native("csgor_get_skin_data", "native_get_skin_data")
	register_native("csgor_is_user_logged", "native_is_user_logged")
	register_native("csgor_is_half_round", "native_is_half_round")
	register_native("csgor_is_last_round", "native_is_last_round")
	register_native("csgor_is_good_item", "native_is_good_item")
	register_native("csgor_is_item_skin", "native_is_item_skin")
	register_native("csgor_is_user_registered", "native_is_user_registered")
	register_native("csgor_is_warmup", "native_is_warmup")
	register_native("csgor_get_skin_index", "native_get_skin_index")
	register_native("csgor_ranks_num", "native_ranks_num")
	register_native("csgor_is_skin_stattrack", "native_is_skin_stattrack")
	register_native("csgor_get_user_skin_data", "native_csgor_get_user_skin_data")
	register_native("csgor_get_user_statt_skins", "native_get_user_statt_skins")
	register_native("csgor_set_user_statt_skins", "native_set_user_statt_skins")
	register_native("csgor_get_user_statt_kills", "native_get_user_stattrack_kills")
	register_native("csgor_set_user_statt_kills", "native_set_user_stattrack_kills")
	register_native("csgor_get_user_stattrack", "native_get_user_stattrack")
	register_native("csgor_set_random_stattrack", "native_set_random_stattrack")
	register_native("csgor_get_user_body", "native_csgo_get_user_body")
	register_native("csgor_get_config_location", "native_csgo_get_config_location")
	register_native("csgor_get_user_skin", "native_csgo_get_user_skin")
	register_native("csgor_get_rank_name", "native_get_rank_name")
	register_native("csgor_get_user_name", "native_csgor_get_user_name")
	register_native("csgor_save_user_data", "native_csgor_save_user_data")
	register_native("csgor_user_has_item", "native_csgor_user_has_item")
	register_native("csgor_get_database_connection", "native_csgor_get_database_connection")
	register_native("csgor_get_database_data", "native_csgo_get_database_data")
	register_native("csgor_send_message", "native_csgor_send_message")
	register_native("csgor_get_dyn_menu_num", "native_csgor_get_dyn_menu_num")
	register_native("csgor_get_dyn_menu_item", "native_csgor_get_dyn_menu_item")

	set_native_filter("native_filter")
}

public native_filter(szName[], index, trap)
{
	if(!trap)
	{
		if(equal(szName, "csgor_send_weapon_anim"))
		{
			g_bSkinsRendering = false
		}
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public plugin_end()
{
	ArrayDestroy(g_aRankName)
	ArrayDestroy(g_aRankKills)
	ArrayDestroy(g_aDefaultSubmodel)
	ArrayDestroy(g_aDropSkin)
	ArrayDestroy(g_aCraftSkin)
	
	ArrayDestroy(g_aSkinsMenu)
	ArrayDestroy(g_aDynamicMenu)
	ArrayDestroy(g_aSkipChat)

	TrieDestroy(g_tDataTrie)
	ArrayDestroy(g_aSkinData)
	ArrayDestroy(g_aDefaultData)

	for(new i = 1; i <= get_maxplayers(); i++)
	{
		ArrayDestroy(g_aPlayerSkins[i])
	}

	SQL_FreeHandle(g_hSqlTuple)
	SQL_FreeHandle(g_iSqlConnection)
}

public client_connect(id)
{
	if(g_iCvars[iFastLoad])
	{
		client_cmd(id, "fs_lazy_precache 1")
	}
}

public client_putinserver(id)
{
	DestroyTask(id + TASK_INFO)

	get_user_name(id, g_szName[id], charsmax(g_szName[]))
	get_user_authid(id, g_szSteamID[id], charsmax(g_szSteamID[]))
	get_user_ip(id, g_szUserLastIP[id], charsmax(g_szUserLastIP[]) , 1)
	
	if(g_iCvars[iCopyRight])
	{
		set_task(15.0, "task_Info", id + TASK_INFO)
	}

	ResetData(id)
	CheckUserInfo(id)
}

ResetData(id, bool:bWithoutPassword = false)
{
	g_iMostDamage[id] = 0
	g_iDigit[id] = 0
	g_iDealDamage[id] = 0

	arrayset(g_iDamage[id], 0, sizeof(g_iDamage[][]))

	if(!bWithoutPassword)
	{
		g_szUserPassword[id] = ""
		g_szUser_SavedPass[id] = ""
	}
	
	g_iUserPassFail[id] = 0
	g_bLogged[id] = false
	g_iUserPoints[id] = 0
	g_iUserDusts[id] = 0
	g_iUserKeys[id] = 0
	g_iUserCases[id] = 0
	g_iUserKills[id] = 0
	g_iUserRank[id] = 0
	g_szUserPrefix[id] = ""
	g_szTemporaryCtag[id] = ""
	g_szUserPrefixColor[id] = ""
	
	g_bUserSell[id] = false
	g_iUserSellItem[id][iItemID] = -1
	g_iUserSellItem[id][iIsStattrack] = 0
	g_iLastPlace[id] = 0
	
	g_iMenuType[id] = 0
	
	g_iGiftTarget[id] = 0
	g_iGiftItem[id][iItemID] = -1
	g_iGiftItem[id][iIsStattrack] = 0
	
	g_iTradeTarget[id] = 0
	g_iTradeItem[id][iItemID] = -1
	g_iTradeItem[id][iIsStattrack] = 0
	g_bTradeActive[id] = false
	g_bTradeAccept[id] = false
	g_bTradeSecond[id] = false
	g_iTradeRequest[id] = 0

	g_iNametagItem[id][iItemID] = -1
	g_iNametagItem[id][iIsStattrack] = 0
	g_szNameTag[id] = ""

	ArrayClear(g_aPlayerSkins[id])

	for (new iWID = 1; iWID <= CSW_P90; iWID++)
	{
		g_iUserSelectedSkin[id][iUserSelected][iWID] = -1
		g_iUserSelectedSkin[id][iUserStattrack][iWID] = -1
		g_iUserSelectedSkin[id][bIsStattrack][iWID] = false
	}

	DestroyTask(id + TASK_HUD)
}

public CheckUserInfo(id)
{
	get_user_info(id, g_iCvars[szUserInfoField], g_szUserPassword[id], charsmax(g_szUserPassword[]))
}

public task_Info(id)
{
	id -= TASK_INFO

	if (is_user_connected(id))
	{
		CC_SendMessage(id, "^4*^1 Playing ^4%s^1 v. ^3%s^1 powered by ^4%s", g_iCvars[szChatPrefix], VERSION, AUTHOR)
	}
}

public client_disconnected(id)
{
	ClearPlayerBit(g_bitIsAlive, id)
	ClearPlayerBit(g_bitShortThrow, id)

	g_eEnumBooleans[id][IsChangeNotAllowed] = false

	if (g_iBombPlanter == id)
	{
		g_iBombPlanter = 0
	}
	if (g_iBombDefuser == id)
	{
		g_iBombDefuser = 0
	}

	arrayset(g_iDamage[id], 0, sizeof(g_iDamage[]))

	DestroyTask(id + TASK_SWAP)
	DestroyTask(id + TASK_RESPAWN)
	DestroyTask(id + TASK_INFO)

	if(!is_user_bot(id) && !is_user_hltv(id) && is_user_connected(id))
	{
		client_cmd(id, "fs_lazy_precache 0")

		if(g_bLogged[id])
		{
			_Save(id)
		}
	}

	return PLUGIN_HANDLED
}

public ev_NewRound()
{
	g_iBombPlanter = 0
	g_iBombDefuser = 0
	g_bBombExplode = false
	g_bBombDefused = false

	arrayset(g_iRoundKills, 0, charsmax(g_iRoundKills))
	arrayset(g_iDealDamage, 0, charsmax(g_iDealDamage))

	if (g_iCvars[iCompetitive] && !g_bWarmUp && get_playersnum() > 1)
	{
		if (!IsHalf() && !IsLastRound())
		{
			CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_COMPETITIVE_INFO", g_iStats[iRoundNum], g_iStats[iTeroScore], g_iStats[iCTScore])
		}

		if (IsLastRound()) 
		{
			set_pcvar_num(p_Freezetime, 10); 

			_ShowBestPlayers()

			DoIntermission()
		}

		if (IsHalf() && !g_bTeamSwap)
		{
			CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_HALF")

			_ShowBestPlayers()

			new Float:delay

			new iPlayer, iPlayers[MAX_PLAYERS], iNum
			get_players(iPlayers, iNum, "ch")

			for (new i; i < iNum; i++)
			{
				iPlayer = iPlayers[i]

				if (is_user_connected(iPlayer))
				{
					delay = 0.2 * iPlayer
					set_task(delay, "task_Delayed_Swap", iPlayer + TASK_SWAP)
				}
			}

			set_task(7.0, "task_Team_Swap")

			g_iStats[iRoundNum] = 16
		}
	}
	return PLUGIN_HANDLED
}

public ev_Intermission()
{
	if(task_exists(TASK_MAP_END))
	{
		log_to_file("csgo_remake_errors.log", "Double Intermission detected, returning...")
		return
	}

	set_task(0.1, "task_Map_End", TASK_MAP_END)
}

public task_Map_End()
{
	set_pcvar_num(p_Freezetime, g_iCvars[iFreezetime])

	new bool:CvarExists = cvar_exists("amx_nextmap") ? true : false

	new szTemp[48]

	SelectMap()

	if(CvarExists)
	{
		formatex(szTemp, charsmax(szTemp), "%s", szNextMap)
	}
	else 
	{
		formatex(szTemp, charsmax(szTemp), "%s", g_iCvars[szNextMapDefault])
	}
	
	server_cmd("changelevel %s", szTemp)
}

SelectMap()
{
	if(cvar_exists("amx_nextmap"))
	{
		if(pNextMap)
		{
			get_pcvar_string(pNextMap, szNextMap, charsmax(szNextMap))
		}

		CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_MAP_END_MAPNAME", szNextMap)
	}
	else
	{
		log_amx("%s cvar ^"amx_nextmap^" doesn't exists, changing map by default to %s", g_iCvars[szChatPrefix], g_iCvars[szNextMapDefault])
		log_to_file("csgo_remake_errors.log", "%s cvar ^"amx_nextmap^" doesn't exists, changing map by default to %s", g_iCvars[szChatPrefix], g_iCvars[szNextMapDefault])
	}
}

public task_Delayed_Swap(id)
{
	id -= TASK_SWAP

	if (!is_user_alive(id))
	{
		return
	}

	switch(cs_get_user_team(id))
	{
		case CS_TEAM_T:
		{
			cs_set_user_team(id, CS_TEAM_CT)
		}
		
		case CS_TEAM_CT:
		{
			cs_set_user_team(id, CS_TEAM_T)
		}
	}
}

public task_Team_Swap()
{
	g_bTeamSwap = true

	new temp[2]
	temp[0] = g_iStats[iCTScore]
	temp[1] = g_iStats[iTeroScore]
	g_iStats[iTeroScore] = temp[0]
	g_iStats[iCTScore] = temp[1]

	set_pcvar_num(p_Freezetime, g_iCvars[iFreezetime])

	CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_RESTART")

	server_cmd("sv_restart 1")
}

public bomb_planting(id)
{
	new iPlayers[MAX_PLAYERS], iNum, iPlayer
	get_players(iPlayers, iNum, "ceh", "TERRORIST")

	for (new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]

		client_cmd(iPlayer, "spk ^"%s^"", g_szBombPlanting)

		CC_SendMessage(iPlayer, "^3(RADIO): ^4I'm planting the bomb.", g_szName[id])
	}
}

public bomb_defusing(id)
{
	new iPlayers[MAX_PLAYERS], iNum, iPlayer
	get_players(iPlayers, iNum, "ceh", "CT")

	for (new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]

		client_cmd(iPlayer, "spk ^"%s^"", g_szBombDefusing)

		CC_SendMessage(iPlayer, "^3(RADIO): ^4I'm defusing the bomb.", g_szName[id])
	}
}

public bomb_explode(id)
{
	g_iBombPlanter = id
	g_bBombExplode = true
}

public bomb_defused(id)
{
	g_iBombDefuser = id
	g_bBombDefused = true
}

public ev_RoundWon_T()
{
	if(g_iCvars[iRoundEndSounds])
	{
		emit_sound(0, CHAN_AUTO, g_szTWin, VOL_NORM, ATTN_NONE, 0, PITCH_NORM)
	}

	new data[1]
	data[0] = 1
	g_iStats[iRoundNum] += 1
	g_iStats[iTeroScore] += 1

	set_task(1.0, "task_Check_Conditions", 0, data, sizeof(data[]))
}

public ev_RoundWon_CT()
{
	if(g_iCvars[iRoundEndSounds])
	{
		emit_sound(0, CHAN_AUTO, g_szCTWin, VOL_NORM, ATTN_NONE, 0, PITCH_NORM)
	}

	new data[1]
	data[0] = 2
	g_iStats[iRoundNum] += 1
	g_iStats[iCTScore] += 1

	set_task(1.0, "task_Check_Conditions", 0, data, sizeof(data[]))
}

public task_Check_Conditions(data[])
{
	new team = data[0]
	switch (team)
	{
		case 1:
		{
			if (g_bBombExplode)
			{
				_ShowMVP(g_iBombPlanter, MVP_PLANTER)
			}
			else
			{
				new top1 = _GetTopKiller(1)
				_ShowMVP(top1, MVP_KILLER)
			}
		}
		case 2:
		{
			if (g_bBombDefused)
			{
				_ShowMVP(g_iBombDefuser, MVP_DEFUSER)
			}
			else
			{
				new top1 = _GetTopKiller(2)
				_ShowMVP(top1, MVP_KILLER)
			}
		}
	}

	if (IsHalf())
	{
		set_pcvar_num(p_Freezetime, 10)
	}
}

public event_Game_Restart()
{
	logev_Game_Restart()
}

public logev_Game_Restart()
{
	arrayset(g_iScore, 0, sizeof(g_iScore))
	arrayset(g_iUserMVP, 0, sizeof(g_iUserMVP))
}

public event_Game_Commencing()
{
	logev_Game_Commencing()
}

public logev_Game_Commencing()
{
	g_iStats[iRoundNum] = 0
	g_iStats[iCTScore] = 0
	g_iStats[iTeroScore] = 0

	if (!g_iCvars[iCompetitive])
		return PLUGIN_HANDLED
	
	g_bWarmUp = true

	set_task(1.0, "task_WarmUp_CD")

	return PLUGIN_CONTINUE
}

public task_WarmUp_CD()
{
	if (g_iCvars[iWarmUpDuration] > 0)
	{
		set_pcvar_num(p_StartMoney, 16000)
		set_hudmessage(0, 255, 0, -1.00, 0.80, 0, 0.00, 1.10)
		ShowSyncHudMsg(0, g_WarmUpSync, "WarmUp: %d second%s", g_iCvars[iWarmUpDuration] , g_iCvars[iWarmUpDuration] == 1 ? "" : "s")
	}
	else
	{
		g_bWarmUp = false
		g_iStats[iRoundNum] = 1
		g_iStats[iCTScore] = 0
		g_iStats[iTeroScore] = 0

		set_pcvar_num(p_StartMoney, g_iCvars[iStartMoney])

		server_cmd("sv_restart 1")
	}

	g_iCvars[iWarmUpDuration]--

	if(g_bWarmUp)
		set_task(1.0, "task_WarmUp_CD")
}

public FM_ClientUserInfoChanged_Pre(id)
{
	if(g_eEnumBooleans[id][IsChangeNotAllowed])
		return FMRES_IGNORED
	
	static name[] = "name"
	
	new szNewName[32]
	new szOldName[32]

	pev(id, pev_netname, szOldName, charsmax(szOldName))
	
	if (szOldName[0])
	{
		get_user_info(id, name, szNewName, charsmax(szNewName))

		if (!equal(szOldName, szNewName))
		{
			set_user_info(id, name, szOldName)

			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CANT_CHANGE_ACC")

			return FMRES_HANDLED
		}
	}
	return FMRES_IGNORED
}

public Ham_Take_Damage_Post( iVictim, inf, iAttacker, Float:iDamage )
{
	if( !is_user_alive(iVictim) || !GetPlayerBit(g_bitIsAlive, iAttacker, g_iMaxPlayers) || !is_user_alive(iAttacker) )
		return HAM_IGNORED

	new weapon = GetPlayerActiveItem(iAttacker)
	
	if(is_nullent(iAttacker) || is_nullent(weapon))
		return HAM_IGNORED
	
	if ( g_iCvars[iSilentWeapDamage] )
	{
		if(weapon == CSW_USP)
		{
			if(cs_get_weapon_silen(weapon))
			{
				SetHamParamFloat(4, iDamage * 1.186)
			}
			return HAM_SUPERCEDE
		}
	}

	return HAM_IGNORED
}

public Ham_Player_Spawn_Post(id)
{
	if(!is_user_alive(id))
	{
		return HAM_IGNORED
	}

	SetPlayerBit(g_bitIsAlive, id, g_iMaxPlayers)

	if(g_iCvars[iShowHUD])
	{
		set_task(1.0, "task_HUD", id + TASK_HUD)
	}

	set_task(0.2, "task_SetIcon", id + TASK_SET_ICON)

	new weapons[32], numweapons
	get_user_weapons(id, weapons, numweapons)

	new weaponid

	for (new i = 0; i < numweapons; i++)
	{
		weaponid = weapons[i]

		if ((1<<weaponid) & weaponsNotVaild)
			return HAM_IGNORED

		ExecuteHamB(Ham_GiveAmmo, id, g_iMaxBpAmmo[weaponid], g_szAmmoType[weaponid], g_iMaxBpAmmo[weaponid])
	}

	DestroyTask(id + TASK_RESPAWN)

	set_task(0.2, "task_check_name", id + TASK_CHECK_NAME)

	g_iMostDamage[id] = 0

	arrayset(g_iDamage[id], 0, sizeof(g_iDamage[]))

	return HAM_IGNORED
}

public task_check_name(id)
{
	id -= TASK_CHECK_NAME
}

public task_Reset_Name(id)
{
	id -= TASK_RESET_NAME
	g_eEnumBooleans[id][IsChangeNotAllowed] = false

	new Name[32]
	get_user_name(id, Name, charsmax(Name))

	if (!equali(Name, g_szName[id]))
	{ 
		g_eEnumBooleans[id][IsChangeNotAllowed] = true

		set_msg_block(g_Msg_SayText, BLOCK_ONCE)
		set_user_info(id, "name", g_szName[id])

		set_task(0.5, "task_Reset_Name", id + TASK_RESET_NAME)
	}
}

public task_SetIcon(id)
{
	id -= TASK_SET_ICON

	if(is_user_connected(id))
	{
		_SetKillsIcon(id, 1)
	}
}

public Ham_Player_Killed_Pre(id)
{
	if(!is_user_connected(id))
	{
		return
	}

	new iActiveItem = GetPlayerActiveItem(id)

	if (is_nullent(iActiveItem))
		return

	new imp = pev(iActiveItem, pev_impulse)

	if (0 < imp)
	{
		return; 
	}

	new iId = GetWeaponEntity(iActiveItem)

	if ((1 << iId) & weaponsNotVaild)
	{
		return
	}

	new skin = g_iUserSelectedSkin[id][bIsStattrack][iId] ? g_iUserSelectedSkin[id][iUserStattrack][iId] : g_iUserSelectedSkin[id][iUserSelected][iId]

	if (skin != -1)
	{
		set_pev(iActiveItem, pev_impulse, skin + 1)
	}
}

public Ham_Player_Killed_Post(id)
{
	if(!is_user_connected(id))
	{
		return HAM_IGNORED
	}
	
	ClearPlayerBit(g_bitIsAlive, id)

	if (g_bWarmUp)
	{
		set_task(1.0, "task_Respawn_Player", id + TASK_RESPAWN)
	}
	if (0 < g_iCvars[iRespawn])
	{
		set_hudmessage(0, 255, 60, 2.50, 0.00, 1)

		new second[64]

		if (1 > g_iCvars[iRespawnDelay])
		{
			formatex(second, charsmax(second), "%L", LANG_SERVER, "CSGOR_RAFFLE_TEXT_SECONDS")
		}
		else
		{
			formatex(second, charsmax(second), "%L", LANG_SERVER, "CSGOR_RAFFLE_TEXT_SECONDS")
		}

		new temp[64]

		formatex(temp, charsmax(temp), "%L", LANG_SERVER, "CSGOR_RESPAWN_TEXT")
		ShowSyncHudMsg(id, g_MsgSync, "%s %d %s...", temp, g_iCvars[iRespawnDelay], second)

		set_task(float(g_iCvars[iRespawnDelay]), "task_Respawn_Player", id + TASK_RESPAWN)
	}
	return HAM_IGNORED
}

public task_Respawn_Player(id)
{
	id -= TASK_RESPAWN

	if (!is_user_connected(id) || GetPlayerBit(g_bitIsAlive, id, g_iMaxPlayers))
		return HAM_IGNORED

	new CsTeams:team = cs_get_user_team(id)

	if (team && team == CS_TEAM_SPECTATOR)
		return HAM_IGNORED

	respawn_player_manually(id)

	return HAM_IGNORED
}

public respawn_player_manually(id)
{
	ExecuteHam(Ham_CS_RoundRespawn, id)
}

public CS_OnBuy(id, item)
{
	if(item == CSI_SHIELD)
		return PLUGIN_HANDLED

	if ((1<<item) & weaponsNotVaild || (1<<item) & MISC_ITEMS)
		return PLUGIN_CONTINUE

	ExecuteHamB(Ham_GiveAmmo, id, g_iMaxBpAmmo[item], g_szAmmoType[item], g_iMaxBpAmmo[item])

	return PLUGIN_CONTINUE
}

#if defined HUD_POS
public clcmd_say_hudpos(id)
{
	new temp[64]
	formatex(temp, charsmax(temp), "\r%s \wHUD POSITION", g_iCvars[szChatPrefix])
	new menu = menu_create(temp, "hudmenu_pos_handler")
	
	formatex(temp, charsmax(temp), "Move HUD Up")
	menu_additem(menu, temp, "0")
	formatex(temp, charsmax(temp), "Move HUD Down")
	menu_additem(menu, temp, "1")
	formatex(temp, charsmax(temp), "Move HUD to the Left")
	menu_additem(menu, temp, "2")
	formatex(temp, charsmax(temp), "Move HUD to the right")
	menu_additem(menu, temp, "3")
	formatex(temp, charsmax(temp), "Move HUD to center")
	menu_additem(menu, temp, "4")
	formatex(temp, charsmax(temp), "Move HUD Default")
	menu_additem(menu, temp, "5")
	formatex(temp, charsmax(temp), "Show Current HUD POS")
	menu_additem(menu, temp, "6")
	
	_DisplayMenu(id, menu)
}

public hudmenu_pos_handler(id, menu, item)
{
	switch(item)
	{
		case 0:
		{
			HUD_POS_Y -= 0.03
			clcmd_say_hudpos(id)
		}
		case 1:
		{
			HUD_POS_Y += 0.03
			clcmd_say_hudpos(id)
		}
		case 2:
		{
			HUD_POS_X -= 0.03
			clcmd_say_hudpos(id)
		}
		case 3:
		{
			HUD_POS_X += 0.03
			clcmd_say_hudpos(id)
		}
		case 4:
		{
			HUD_POS_X = -1.0
			HUD_POS_Y =  0.26
			clcmd_say_hudpos(id)
		}
		case 5:
		{
			HUD_POS_X = 0.02
			HUD_POS_Y =  0.9
			clcmd_say_hudpos(id)
		}
		case 6:
		{
			client_print(id, print_chat, "Pos X: %f Pos Y: %f", HUD_POS_X, HUD_POS_Y)
			clcmd_say_hudpos(id)
		}
	}
	return _MenuExit(menu)
}
#endif

public task_HUD(id)
{	
	id -= TASK_HUD

	if (!GetPlayerBit(g_bitIsAlive, id, g_iMaxPlayers))
		return

	if (g_bLogged[id]) 
	{
		new szRank[MAX_RANK_NAME]

		switch(g_iCvars[iShowHUD])
		{
			case iStandardHUD:
			{
				new userRank = g_iUserRank[id]

				ArrayGetString(g_aRankName, userRank, szRank, charsmax(szRank))

				set_hudmessage(0, 255, 0, 0.02, 0.9, 0, 6.00, 1.10)
				ShowSyncHudMsg(id, g_MsgSync, "%L", LANG_SERVER, "CSGOR_HUD_INFO1", g_iUserPoints[id], g_iUserKeys[id], g_iUserCases[id], szRank)
			}
			case iAdvancedHUD:
			{
				new userRank = g_iUserRank[id]
				static eSkinData[SkinData], szTemp[128], ePlayerSkins[PlayerSkins]

				new bool:bError = false

				new iActiveItem = GetPlayerActiveItem(id)

				if(is_nullent(iActiveItem))
				{
					bError = true
				}

				new weapon
				
				if(!bError)
				{
					weapon = GetWeaponEntity(iActiveItem)

					if((1 << weapon) & weaponsWithoutInspectSkin)
					{
						bError = true
					}
				}

				new skin

				if(!bError)
				{
					skin = GetSkinInfo(id, weapon, iActiveItem)
				}

				if(skin == -1 || bError)
				{
					formatex(szTemp, charsmax(szTemp), "%L", LANG_SERVER, "CSGOR_NO_ACTIVE_SKIN_HUD")
				}
				else
				{
					ArrayGetArray(g_aSkinData, skin, eSkinData)

					if(!g_eEnumBooleans[id][IsInPreview])
					{
						new iFound = -1
						ePlayerSkins = GetPlayerSkin(id, skin, iFound, g_iUserSelectedSkin[id][bIsStattrack][weapon])

						if(0 <= iFound)
						{
							if(g_iUserSelectedSkin[id][bIsStattrack][weapon])
							{
								formatex(szTemp, charsmax(szTemp), "StatTrack (TM) %s^n%L", eSkinData[szSkinName], LANG_SERVER, "CSGOR_CONFIRMED_KILLS_HUD", ePlayerSkins[iKills])
							}
							else
							{
								formatex(szTemp, charsmax(szTemp), eSkinData[szSkinName])
							}

							if(ePlayerSkins[szNameTag][0] != EOS)
							{
								format(szTemp, charsmax(szTemp), "%s^n%L", szTemp, LANG_SERVER, "CSGOR_SKIN_NAMETAG_IS", ePlayerSkins[szNameTag])
							}
						}
					}
					else 
					{
						formatex(szTemp, charsmax(szTemp), eSkinData[szSkinName])
					}
				}

				ArrayGetString(g_aRankName, userRank, szRank, charsmax(szRank))

				set_hudmessage(0, 255, 0, 0.68, 0.21, 0, 6.00, 1.10)
				ShowSyncHudMsg(id, g_MsgSync, "%L", LANG_SERVER, "CSGOR_HUD_INFO2", g_iUserPoints[id], g_iUserKeys[id], g_iUserCases[id], szRank, szTemp)
			}
		}
	}
	else
	{
		set_hudmessage(255, 0, 0, 0.02, 0.9, 0, 6.00, 1.10)
		ShowSyncHudMsg(id, g_MsgSync, "%L", LANG_SERVER, "CSGOR_NOT_LOGGED")
	}

	set_task(1.0, "task_HUD", id + TASK_HUD)
}

public clcmd_say_reg(id)
{
	_ShowRegMenu(id)

	return PLUGIN_HANDLED
}

public clcmd_chooseteam(id)
{
	clcmd_say_menu(id)

	return PLUGIN_HANDLED
}

_Save(id)
{
	_SaveData(id)
}

_Load(id)
{
	_LoadData(id)
}

public _LoadData(id)
{
	new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_data` WHERE `Name` = ^"%s^";", g_szName[id])

	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError))
		log_to_file("csgo_remake_errors.log", g_szSqlError)
		SQL_FreeHandle(iQuery)

		return
	}

	new szQuery[512]
	new bool:bFoundData = SQL_NumResults( iQuery ) > 0 ? false : true

	if(bFoundData)
	{
		formatex(szQuery, charsmax(szQuery), "INSERT INTO `csgor_data` \
			(`Name`, \
			`SteamID`, \
			`Last IP`, \
			`Password`, \
			`ChatTag`, \
			`ChatTag Color`, \
			`Points`, \
			`Scraps`, \
			`Keys`, \
			`Cases`, \
			`Kills`, \
			`Rank`, \
			`Bonus Timestamp` \
			) VALUES (^"%s^", ^"%s^", ^"%s^", ^"%s^",^"%s^",'0','0','0','0','0','0','0','0');", g_szName[id], g_szSteamID[id], g_szUserLastIP[id], g_szUser_SavedPass[id], g_szUserPrefix[id], g_szUserPrefixColor[id])
	}
	else
	{
		formatex(szQuery, charsmax(szQuery), "SELECT \
			`Password`, \
			`ChatTag`, \
			`ChatTag Color`, \
			`Points`, \
			`Scraps`, \
			`Keys`, \
			`Cases`, \
			`Kills`, \
			`Rank`, \
			`Bonus Timestamp` \
			FROM `csgor_data` WHERE `Name` = ^"%s^";", g_szName[id])
	}

	iQuery = SQL_PrepareQuery(g_iSqlConnection, szQuery)

	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError))
		log_to_file("csgo_remake_errors.log", g_szSqlError)

		return
	}

	if(!bFoundData)
	{
		if(SQL_NumResults(iQuery) > 0)
		{
			SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Password"), g_szUser_SavedPass[id], charsmax(g_szUser_SavedPass[]))
			SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "ChatTag"), g_szUserPrefix[id], charsmax(g_szUserPrefix[]))
			SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "ChatTag Color"), g_szUserPrefixColor[id], charsmax(g_szUserPrefixColor[]))
			g_iUserPoints[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Points"))
			g_iUserDusts[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Scraps"))
			g_iUserKeys[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Keys"))
			g_iUserCases[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Cases"))
			g_iUserKills[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Kills"))
			g_iUserRank[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Rank"))
		}
	}

	SQL_FreeHandle(iQuery)
}

public _LoadSkins(id)
{
	new szQuery[90]
	formatex(szQuery, charsmax(szQuery), "SELECT * FROM `csgor_skins` WHERE `Name` = ^"%s^";", g_szName[id])

	new szData[2]
	szData[0] = id

	SQL_ThreadQuery(g_hSqlTuple, "QueryPlayerSkins", szQuery, szData, charsmax(szData))
}

public QueryPlayerSkins(iFailState, Handle:iQuery, Error[], Errcode, szData[], iSize, Float:flQueueTime)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: 
		{
			log_to_file("csgo_remake_errors.log", "[SQL Error] Connection failed (%i): %s", Errcode, Error)
		}
		case TQUERY_QUERY_FAILED:
		{
			log_to_file("csgo_remake_errors.log", "[SQL Error] Query failed (%i): %s", Errcode, Error)
		}
	}

	new id = szData[0]

	if(!is_user_connected(id))
		return

	if(!SQL_NumResults(iQuery))
		goto _loaded

	new ePlayerSkins[PlayerSkins], szSkin[MAX_SKIN_NAME]

	while(SQL_MoreResults(iQuery))
	{
		ePlayerSkins[iWeaponid] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "WeaponID"))

		SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Skin"), szSkin, charsmax(szSkin))

		ePlayerSkins[iSkinid] = GetSkinID(szSkin)

		if(ePlayerSkins[iSkinid] < 0)
		{
			SQL_NextRow(iQuery)
			continue
		}

		ePlayerSkins[iSelected] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Selected"))

		ePlayerSkins[iKills] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Kills"))

		ePlayerSkins[iPieces] =  SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Piece"))

		ePlayerSkins[isStattrack] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Stattrack"))

		if(ePlayerSkins[iSelected] == 1 && ePlayerSkins[isStattrack] == 1)
		{
			g_iUserSelectedSkin[id][iUserStattrack][ePlayerSkins[iWeaponid]] = ePlayerSkins[iSkinid]
			g_iUserSelectedSkin[id][bIsStattrack][ePlayerSkins[iWeaponid]] = true
		} 
		else if(ePlayerSkins[iSelected] == 1)
		{
			g_iUserSelectedSkin[id][iUserSelected][ePlayerSkins[iWeaponid]] = ePlayerSkins[iSkinid]
		}

		SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "NameTag"), ePlayerSkins[szNameTag], charsmax(ePlayerSkins[szNameTag]))

		ArrayPushArray(g_aPlayerSkins[id], ePlayerSkins)

		SQL_NextRow(iQuery)
	}

	_loaded:
	if(g_bLogged[id])
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_DATA_LOADED")
		g_bLoaded[id] = true

		new iRet
		ExecuteForward(g_iForwards[ account_loaded ], iRet, id)
		_ShowMainMenu(id)
	}
}

public _SaveData(id)
{
	static szQuery[512]
	new iTimestamp

	IsTaken(id, iTimestamp)

	formatex(szQuery, charsmax(szQuery), "UPDATE `csgor_data` \
	SET `SteamID`=^"%s^", \
	`Last IP`=^"%s^", \
	`Password`=^"%s^", \
	`ChatTag`=^"%s^", \
	`ChatTag Color`=^"%s^", \
	`Points`='%i', \
	`Scraps`='%i', \
	`Keys`='%i', \
	`Cases`='%i', \
	`Kills`='%i', \
	`Rank`='%i', \
	`Bonus Timestamp`='%i' \
	WHERE `Name`=^"%s^";", g_szSteamID[id], g_szUserLastIP[id], g_szUser_SavedPass[id], g_szUserPrefix[id], g_szUserPrefixColor[id], g_iUserPoints[id], g_iUserDusts[id], g_iUserKeys[id], g_iUserCases[id], g_iUserKills[id], g_iUserRank[id], iTimestamp, g_szName[id])

	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)

	return PLUGIN_HANDLED
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

public _ShowRegMenu(id)
{
	if (1 > g_iCvars[iRegOpen])
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_REG_CLOSED")
		return PLUGIN_HANDLED
	}

	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_REG_MENU")

	new menu = menu_create(temp, "reg_menu_handler")
	new szItem[2]

	szItem[1] = 0

	formatex(temp, charsmax(temp), "\r%L \w%s", LANG_SERVER, "CSGOR_REG_ACCOUNT", g_szName[id])
	szItem[0] = 0
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\r%L \w%s^n", LANG_SERVER, "CSGOR_REG_PASSWORD", g_szUserPassword[id])
	szItem[0] = 1
	menu_additem(menu, temp, szItem)

	if (!g_bLogged[id])
	{
		if (IsRegistered(id)) 
		{
			formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_REG_LOGIN")
			szItem[0] = 3
			menu_additem(menu, temp, szItem)
		} 
		else 
		{
			formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_REG_REGISTER")
			szItem[0] = 4
			menu_additem(menu, temp, szItem)
		}
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_REG_LOGOUT")
		szItem[0] = 4
		menu_additem(menu, temp, szItem)
	}

	_DisplayMenu(id, menu)

	return PLUGIN_HANDLED
}

public reg_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		return _MenuExit(menu)
	}

	new itemdata[2]
	new dummy
	new index

	menu_item_getinfo(menu, item, dummy, itemdata, 1)

	index = itemdata[0]

	new pLen = strlen(g_szUserPassword[id])

	switch (index)
	{
		case 0:
		{
			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CANT_CHANGE_ACC")
			_ShowRegMenu(id)
		}
		case 1:
		{
			if (!g_bLogged[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_REG_INSERT_PASS", 6)
				client_cmd(id, "messagemode UserPassword")
			}
		}
		case 3:
		{
			_Load(id)

			_LoadSkins(id)

			new spLen = strlen(g_szUserPassword[id])

			if (strlen(g_szUserPassword[id]) <= 0) 
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_REG_INSERT_PASS", 6)
				client_cmd(id, "messagemode UserPassword")
			}

			if (!equal(g_szUserPassword[id], g_szUser_SavedPass[id], spLen))
			{
				g_iUserPassFail[id]++
				CC_SendMessage(id, " ^1%L", LANG_SERVER, "CSGOR_PASS_FAIL")
				_ShowRegMenu(id)
				ExecuteForward(g_iForwards[ user_pass_fail ], g_iForwardResult, id, g_iUserPassFail[id])
			}
			else
			{
				g_bLogged[id] = true
				CC_SendMessage(id, " ^1%L", LANG_SERVER, "CSGOR_LOGIN_SUCCESS")
				ExecuteForward(g_iForwards[ user_log_in ], g_iForwardResult, id)
			}

			_Load(id)
		}
		case 4:
		{
			if (!IsRegistered(id))
			{
				if (pLen < 6)
				{
					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_REG_INSERT_PASS", 6)

					_ShowRegMenu(id)

					return _MenuExit(menu)
				}

				copy(g_szUser_SavedPass[id], 15, g_szUserPassword[id])

				g_bLogged[id] = true

				_Load(id)

				_LoadSkins(id)

				_ShowMainMenu(id)

				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_REG_SUCCESS", g_szUser_SavedPass[id])

				ExecuteForward(g_iForwards[ user_register ], g_iForwardResult, id)
			}
			else
			{
				if(g_bLogged[id])
				{
					g_bLogged[id] = false
					g_szUserPassword[id] = ""

					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_LOGOUT_SUCCESS")

					_ShowRegMenu(id)

					ExecuteForward(g_iForwards[ user_log_out ], g_iForwardResult, id)
				}
			}
		}
	}

	return _MenuExit(menu)
}

public concmd_password(id)
{
	if (g_bLogged[id])
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_ALREADY_LOGIN")
		return PLUGIN_HANDLED
	}

	new data[32]

	read_args(data, charsmax(data))
	remove_quotes(data)

	if (6 > strlen(data))
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_REG_INSERT_PASS", 6)
		client_cmd(id, "messagemode UserPassword")

		return PLUGIN_HANDLED
	}

	copy(g_szUserPassword[id], charsmax(g_szUserPassword[]), data)

	_ShowRegMenu(id)

	return PLUGIN_HANDLED
}

public clcmd_say_menu(id)
{
	if (g_bLogged[id])
	{
		_ShowMainMenu(id)
	}
	else
	{
		_ShowRegMenu(id)
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_LOGIN")
	}

	return PLUGIN_HANDLED
}

public clcmd_say_inventory(id)
{
	if(g_bLogged[id])
	{
		_ShowInventoryMenu(id)
	}
	else
	{
		_ShowRegMenu(id)
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_LOGIN")
	}

	return PLUGIN_HANDLED
}

public clcmd_say_opencase(id)
{
	if(g_bLogged[id])
	{
		_ShowOpenCaseCraftMenu(id)
	}
	else
	{
		_ShowRegMenu(id)
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_LOGIN")
	}

	return PLUGIN_HANDLED
}

public clcmd_say_market(id)
{
	if(g_bLogged[id])
	{
		_ShowMarketMenu(id)
	}
	else
	{
		_ShowRegMenu(id)
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_LOGIN")
	}

	return PLUGIN_HANDLED
}

public clcmd_say_dustbin(id)
{
	if(g_bLogged[id])
	{
		_ShowDustbinMenu(id)
	}
	else
	{
		_ShowRegMenu(id)
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_LOGIN")
	}

	return PLUGIN_HANDLED
}

public clcmd_say_gifttrade(id)
{
	if(g_bLogged[id])
	{
		_ShowGiftTradeMenu(id)
	}
	else
	{
		_ShowRegMenu(id)
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_LOGIN")
	}

	return PLUGIN_HANDLED
}

public clcmd_say_preview(id)
{
	if(g_bLogged[id])
	{
		_ShowPreviewMenu(id)
	}
	else
	{
		_ShowRegMenu(id)
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_LOGIN")
	}

	return PLUGIN_HANDLED
}

public _ShowPreviewMenu(id)
{
	new szTemp[MAX_SKIN_NAME]
	new weapons[EnumSkinsMenuInfo]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_PREVIEW_MENU")

	new menu = menu_create(szTemp, "preview_menu_handler")

	for(new i; i < ArraySize(g_aSkinsMenu) ; i++)
	{
		ArrayGetArray(g_aSkinsMenu, i, weapons)

		formatex(szTemp, charsmax(szTemp), "%s", weapons[ItemName])

		menu_additem(menu, szTemp, weapons[ItemId])
	}

	_DisplayMenu(id, menu)
}

public preview_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}

	new itemdata[3]
	new data[6][32]
	new index[32]

	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1])

	parse(data[0], index, charsmax(index))

	item = str_to_num(index)

	_ShowSortedSkins(id, item, iPreview)

	return _MenuExit(menu)
}

public _ShowMainMenu(id)
{
	if(!g_bLoaded[id])
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_LOADING_DATA")
		return
	}

	new temp[96], MenuInfo[EnumDynamicMenu]

	formatex(temp, charsmax(temp), "\r%s \w%L^n%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_MAIN_MENU", LANG_SERVER, "CSGOR_MM_INFO", g_iUserPoints[id], g_iUserKills[id])
	new menu = menu_create(temp, "main_menu_handler")

	for(new i; i < ArraySize(g_aDynamicMenu); i++)
	{
		ArrayGetArray(g_aDynamicMenu, i, MenuInfo)

		if (containi(MenuInfo[szMenuName], "CSGOR_") != -1)
		{
			formatex(temp, charsmax(temp), "%L", LANG_SERVER, MenuInfo[szMenuName])
		}
		else
		{
			formatex(temp, charsmax(temp), MenuInfo[szMenuName])
		}
		menu_additem(menu, temp)
	}

	new userRank = g_iUserRank[id]
	new szRank[MAX_RANK_NAME]

	ArrayGetString(g_aRankName, userRank, szRank, charsmax(szRank))

	if (g_iRanksNum - 1 > userRank)
	{
		new nextRank = ArrayGetCell(g_aRankKills, userRank + 1) - g_iUserKills[id]
		formatex(temp, charsmax(temp), "\w%L^n%L", LANG_SERVER, "CSGOR_MM_RANK", szRank, LANG_SERVER, "CSGOR_MM_NEXT_KILLS", nextRank)
	}
	else
	{
		formatex(temp, charsmax(temp), "\w%L^n%L", LANG_SERVER, "CSGOR_MM_RANK", szRank, LANG_SERVER, "CSGOR_MM_MAX_KILLS")
	}

	menu_addtext2(menu, temp)

	_DisplayMenu(id, menu)
}

public main_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		return _MenuExit(menu)
	}
	
	new MenuInfo[EnumDynamicMenu]

	ArrayGetArray(g_aDynamicMenu, item, MenuInfo)

	cmd_execute(id, MenuInfo[szMenuCMD])

	return _MenuExit(menu)
}

public _ShowInventoryMenu(id)
{
	new temp[64], szItem[3]
	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_MM_INVENTORY")
	new menu = menu_create(temp, "inventory_menu_handler")
	
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_SKIN_MENU")
	num_to_str(0, szItem, charsmax(szItem))
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CHAT_TAG")
	num_to_str(1, szItem, charsmax(szItem))
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_SKIN_NAMETAG_MENU")
	num_to_str(2, szItem, charsmax(szItem))
	menu_additem(menu, temp, szItem)
	
	_DisplayMenu(id, menu)
}

public inventory_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}

	new itemdata[3]
	new data[6][32]
	new index[32]

	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1])

	parse(data[0], index, charsmax(index))

	item = str_to_num(index)

	switch (item)
	{
		case 0:
		{
			_ShowSkinsMenu(id)
		}
		case 1:
		{
			_ShowTagsMenu(id)
		}
		case 2:
		{
			_ShowNameTagsMenu(id)
		}
	}

	return _MenuExit(menu)
}

public _ShowSkinsMenu(id)
{
	new szTemp[64]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SKIN_MENU")
	new menu = menu_create(szTemp, "skins_menu_handler")

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_NORMAL_SKIN_MENU")
	menu_additem(menu, szTemp)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_STATTRACK_SKIN_MENU")
	menu_additem(menu, szTemp)

	_DisplayMenu(id, menu)
}

public skins_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}

	switch(item)
	{
		case 0:
		{
			_ShowNormalSkinsMenu(id)
		}
		case 1:
		{
			_ShowStattrackSkinsMenu(id)
		}
	}

	return PLUGIN_CONTINUE
}

_ShowNormalSkinsMenu(id, iSpecial = iNone)
{
	new szTemp[128]
	new weapons[EnumSkinsMenuInfo]
	new szItem[10]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SKIN_MENU")
	new menu = menu_create(szTemp, "skins_normal_menu_handler")

	for(new i; i < ArraySize(g_aSkinsMenu) ; i++)
	{
		ArrayGetArray(g_aSkinsMenu, i, weapons)

		formatex(szTemp, charsmax(szTemp), "%s [\r%d\w/\r%d\w]", weapons[ItemName], GetUserSkinsNum(id, str_to_num(weapons[ItemId])), GetMaxSkins(str_to_num(weapons[ItemId])))
		formatex(szItem, charsmax(szItem), "%d,%d", str_to_num(weapons[ItemId]), iSpecial)
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
			_ShowMainMenu(id)
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
	new weapons[EnumSkinsMenuInfo]
	new szItem[10]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SKIN_MENU")
	new menu = menu_create(szTemp, "skins_stattrack_menu_handler")

	for(new i; i < ArraySize(g_aSkinsMenu) ; i++)
	{
		ArrayGetArray(g_aSkinsMenu, i, weapons)

		formatex(szTemp, charsmax(szTemp), "\y(StatTrack)\w %s [\r%d\w/\r%d\w]", weapons[ItemName], GetUserSkinsNum(id, str_to_num(weapons[ItemId]), true), GetMaxSkins(str_to_num(weapons[ItemId])))
		formatex(szItem, charsmax(szItem), "%d,%d", str_to_num(weapons[ItemId]), iSpecial)
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
			_ShowMainMenu(id)
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

	switch(iMenu)
	{
		case iNormal, iStattrack:
		{
			formatex(szFormatted, charsmax(szFormatted), "\w%L", LANG_SERVER, iMenu == iNormal ? "CSGOR_SKIN_MENU" : "CSGOR_SKIN_STT_MENU")
		}
		case iPreview:
		{
			formatex(szFormatted, charsmax(szFormatted), "\w%L", LANG_SERVER, "CSGOR_PREVIEW_MENU")
		}
	}

	formatex(szTemp, charsmax(szTemp), "\r%s \w%s", g_iCvars[szChatPrefix], szFormatted)

	new menu

	switch(iSpecial)
	{
		case iNone:
		{
			menu = menu_create(szTemp, "skin_menu_handler")
		}
		case iSell:
		{
			menu = menu_create(szTemp, "item_menu_handler")
		}
		case iGift:
		{
			menu = menu_create(szTemp, "gifting_menu_handler")
		}
		case iTrade:
		{
			menu = menu_create(szTemp, "trading_menu_handler")
		}
		case iNameTag:
		{
			menu = menu_create(szTemp, "nt_select_menu_handler")
		}
	}

	new eSkinData[SkinData]

	switch(iMenu)
	{
		case iPreview:
		{
			for (new i; i < ArraySize(g_aSkinData); i++)
			{
				ArrayGetArray(g_aSkinData, i, eSkinData)
				iWID = eSkinData[iWeaponID]

				if (iItem == iWID)
				{
					formatex(szTemp, charsmax(szTemp), "%s%s\w", eSkinData[iSkinType] == 'd' ? "\r" : "\w", eSkinData[szSkinName])
					formatex(szItem, charsmax(szItem), "%d;%d", i, iMenu)
					menu_additem(menu, szTemp, szItem)

					hasSkins = true
				}
			}
		}
		case iNormal, iStattrack:
		{
			new ePlayerSkins[PlayerSkins], iTemp, iFound = -1

			for (new i; i < ArraySize(g_aSkinData); i++)
			{
				ePlayerSkins = GetPlayerSkin(id, i, iFound, iMenu)

				if(0 < ePlayerSkins[iPieces])
				{
					if(iFound < 0 || ePlayerSkins[iSkinid] != i)
						continue

					ArrayGetArray(g_aSkinData, i, eSkinData)
					iWID = ePlayerSkins[iWeaponid]

					if (iItem != iWID)
						continue
				
					iTemp = (iMenu == iNormal) ? g_iUserSelectedSkin[id][iUserSelected][iWID] : g_iUserSelectedSkin[id][iUserStattrack][iWID]

					if(ePlayerSkins[isStattrack])
					{
						FormatStattrack(eSkinData[szSkinName], charsmax(eSkinData[szSkinName]))
					}

					formatex(szTemp, charsmax(szTemp), "%s%s\w| \y%L \r%s", iMenu == iNormal ? (eSkinData[iSkinType] == 'd' ? "\r" : "\w") : "\w", eSkinData[szSkinName], LANG_SERVER, "CSGOR_SM_PIECES", ePlayerSkins[iPieces], iTemp == i ? "#" : "")
					formatex(szItem, charsmax(szItem), "%d;%d", i, ePlayerSkins[isStattrack])
					menu_additem(menu, szTemp, szItem)

					hasSkins = true
				}
			}
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

public skin_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}

	new itemdata[3]
	new data[6][32]
	new index[32]
	new szMenu[2], iMenu

	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1])
	
	parse(data[0], index, charsmax(index))

	strtok(index, index, charsmax(index), szMenu, charsmax(szMenu), ';')

	item = str_to_num(index)

	iMenu = str_to_num(szMenu)

	switch (item)
	{
		case -10:
		{
			_ShowPreviewMenu(id)
		}
		default:
		{
			new eSkinData[SkinData]

			ArrayGetArray(g_aSkinData, item, eSkinData)

			switch(iMenu)
			{
				case iPreview:
				{
					if(g_eEnumBooleans[id][IsInPreview])
					{
						CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_PREVIEW_ALREADY")

						return _MenuExit(menu)
					}

					new iWID = eSkinData[iWeaponID]

					if(get_user_weapon(id) != iWID)
					{
						CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_PREVIEW_NEEDS_SAME_WEAP")

						_ShowPreviewMenu(id)

						return _MenuExit(menu)
					}

					new szParams[5]

					szParams[4] = item
					szParams[3] = g_iUserSelectedSkin[id][bIsStattrack][iWID]
					szParams[2] = iWID
					szParams[1] = g_iUserSelectedSkin[id][bIsStattrack][iWID] ? g_iUserSelectedSkin[id][iUserStattrack][iWID] : g_iUserSelectedSkin[id][iUserSelected][iWID]

					g_iUserSelectedSkin[id][iUserSelected][iWID] = item
					g_iUserSelectedSkin[id][iUserStattrack][iWID] = -1
					g_iUserSelectedSkin[id][bIsStattrack][iWID] = false
					g_iUserViewBody[id][iWID] = item
					g_eEnumBooleans[id][IsInPreview] = true

					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_PREVIEWING_SKIN_FOR", eSkinData[szSkinName], g_iCvars[iCPreview])

					_ShowPreviewMenu(id)

					set_task(float(g_iCvars[iCPreview]), "task_stop_preview", id + TASK_PREVIEW, szParams, sizeof(szParams))
				}
				case iNormal, iStattrack:
				{
					new iWID = eSkinData[iWeaponID]
					new bool:SameSkin
					new iFound = -1
					static ePlayerSkins[PlayerSkins]

					new iLastItem = g_iUserSelectedSkin[id][bIsStattrack][iWID] ? g_iUserSelectedSkin[id][iUserStattrack][iWID] : g_iUserSelectedSkin[id][iUserSelected][iWID]

					if (item == iLastItem)
					{
						SameSkin = true
					}
					else if(iLastItem > -1)
					{
						ArrayGetArray(g_aSkinData, iLastItem, eSkinData)
						ePlayerSkins = GetPlayerSkin(id, iLastItem, iFound, g_iUserSelectedSkin[id][bIsStattrack][iWID])
						ePlayerSkins[iSelected] = 0
						UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins)
					}

					ArrayGetArray(g_aSkinData, item, eSkinData)
					ePlayerSkins = GetPlayerSkin(id, item, iFound, iMenu)

					if(iFound > -1)
					{
						ePlayerSkins[iSelected] = (SameSkin == true ? 0 : 1)
						ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)
						UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins)
					}

					if (!SameSkin)
					{
						switch(iMenu)
						{
							case iNormal:
							{
								g_iUserSelectedSkin[id][iUserSelected][iWID] = item
								g_iUserSelectedSkin[id][iUserStattrack][iWID] = -1
								g_iUserSelectedSkin[id][bIsStattrack][iWID] = false
							}
							case iStattrack:
							{
								g_iUserSelectedSkin[id][iUserSelected][iWID] = -1
								g_iUserSelectedSkin[id][iUserStattrack][iWID] = item
								g_iUserSelectedSkin[id][bIsStattrack][iWID] = true
								FormatStattrack(eSkinData[szSkinName], charsmax(eSkinData[szSkinName]))
							}
						}

						g_iUserViewBody[id][iWID] = item

						CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_SELECT_SKIN", eSkinData[szSkinName])
					}
					else
					{
						if(g_iUserSelectedSkin[id][bIsStattrack][iWID])
						{
							FormatStattrack(eSkinData[szSkinName], charsmax(eSkinData[szSkinName]))
						}

						g_iUserSelectedSkin[id][iUserSelected][iWID] = -1
						g_iUserSelectedSkin[id][iUserStattrack][iWID] = -1
						g_iUserSelectedSkin[id][bIsStattrack][iWID] = false

						g_iUserViewBody[id][iWID] = 0

						CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_DESELECT_SKIN", eSkinData[szSkinName])
					}

					_Save(id)
					_ShowSkinsMenu(id)
				}
			}

			new iActiveItem, weapon

			iActiveItem = GetPlayerActiveItem(id)

			if(is_nullent(iActiveItem)) 
				return _MenuExit(menu)

			weapon = GetWeaponEntity(iActiveItem)

			if(!IsValidWeapon(weapon))
				return _MenuExit(menu)

			change_skin(id, weapon)
		}
	}

	return _MenuExit(menu)
}

public task_stop_preview(szParams[], id)
{
	id -= TASK_PREVIEW

	new iWID = szParams[2]

	new skinid = szParams[4]

	g_iUserSelectedSkin[id][bIsStattrack][iWID] = bool:szParams[3]

	if(g_iUserSelectedSkin[id][bIsStattrack][iWID])
	{
		g_iUserSelectedSkin[id][iUserStattrack][iWID] = szParams[1]
	}
	else
	{
		g_iUserSelectedSkin[id][iUserSelected][iWID] = szParams[1]
	}
	g_eEnumBooleans[id][IsInPreview] = false

	static eSkinData[SkinData]
	ArrayGetArray(g_aSkinData, skinid, eSkinData)

	CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_PREVIEWING_DONE", eSkinData[szSkinName])

	change_skin(id, iWID)

	_ShowPreviewMenu(id)

	return PLUGIN_HANDLED
}

public _ShowTagsMenu(id)
{
	new temp[64]
	new szItem[32]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_CHAT_TAG")
	new menu = menu_create(temp, "tags_menu_handler")
	
	if( equal(g_szUserPrefix[id], ""))
	{
		formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_NO_CTAG")
	}
	else
	{
		formatex(temp, charsmax(temp), "\w%L^n", id, "CSGOR_YOUR_CTAG_IS", g_szUserPrefix[id])
	}

	num_to_str(0, szItem, charsmax(szItem))
	menu_additem(menu, temp, szItem)
	
	if( equal(g_szUserPrefix[id], "") )
	{
		formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_CTAG_BUY_ONE", g_iCvars[iChatTagPrice])
	}
	else
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CTAG_CHANGE", g_iCvars[iChatTagPrice])
	}

	num_to_str(1, szItem, charsmax(szItem))
	menu_additem(menu, temp, szItem)
	
	if ( !equal(g_szUserPrefix[id], "") )
	{
		formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_CTAG_COLOR", g_iCvars[iChatTagColorPrice])
		num_to_str(2, szItem, charsmax(szItem))
		menu_additem(menu, temp, szItem)
	}
	
	if( !equal(g_szUserPrefix[id], "") || !equal(g_szTemporaryCtag[id], "") )
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CTAG_ACCEPT_CHANGE")
		num_to_str(3, szItem, charsmax(szItem))
		menu_additem(menu, temp, szItem)
	}

	_DisplayMenu(id, menu)
}

public tags_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}

	new itemdata[3]
	new data[6][32]
	new index[32]

	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1])

	parse(data[0], index, charsmax(index))

	item = str_to_num(index)

	switch (item)
	{
		case 0:
		{
			_ShowTagsMenu(id)
		}
		case 1:
		{
			client_cmd(id, "messagemode ChatTag")
		}
		case 2:
		{
			_ShowTagsColorMenu(id)
		}
		case 3:
		{
			if(g_szTemporaryCtag[id][0] != EOS)
			{
				if ( g_iCvars[iChatTagPrice] <= g_iUserPoints[id] )
				{
					copy(g_szUserPrefix[id], 15, g_szTemporaryCtag[id])

					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CTAG_CHANGED_SUCCES", g_szUserPrefix[id])

					g_iUserPoints[id] -= g_iCvars[iChatTagPrice]
					g_szTemporaryCtag[id] = ""
				}
				else
				{
					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CTAG_CHANGE_FAIL", (g_iCvars[iChatTagPrice] - g_iUserPoints[id]))
				}
			}
			_ShowTagsMenu(id)
		}
	}

	return _MenuExit(menu)
}

public concmd_chattag(id)
{
	new data[32]

	read_args(data, charsmax(data))
	remove_quotes(data)

	if ( strlen(data) < 3 || strlen(data) > 12 || containi(data, "%") != -1)
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_INSERT_CTAG", 3, 12)

		client_cmd(id, "messagemode ChatTag")
	}
	else
	{
		copy(g_szTemporaryCtag[id], 15, data)

		_ShowTagsMenu(id)

		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_INSERTED_CTAG", g_szTemporaryCtag[id])
	}
	return PLUGIN_HANDLED
}

public _ShowTagsColorMenu(id)
{
	new temp[64]
	new szItem[32]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_CTAG_COLOR", g_iCvars[iChatTagColorPrice])
	new menu = menu_create(temp, "tags_color_menu_handler")
	
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CTAG_COLOR_TEAM_COLOR")
	num_to_str(1, szItem, charsmax(szItem))
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CTAG_COLOR_GREEN")
	num_to_str(2, szItem, charsmax(szItem))
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CTAG_COLOR_NORMAL")
	num_to_str(3, szItem, charsmax(szItem))
	menu_additem(menu, temp, szItem)
	
	_DisplayMenu(id, menu)
}

public tags_color_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}
	new itemdata[3]
	new data[6][32]
	new index[32]

	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1])

	parse(data[0], index, charsmax(index))

	item = str_to_num(index)

	switch (item)
	{
		case 1:
		{
			if (g_iCvars[iChatTagColorPrice] <= g_iUserPoints[id])
			{
				g_szUserPrefixColor[id] = "^3"

				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CTAG_COLOR_SUCCES", LANG_SERVER, "CSGOR_CTAG_COLOR_TEAM_COLOR")
			}
			else
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CTAG_CHANGE_FAIL", (g_iCvars[iChatTagPrice] - g_iUserPoints[id]))
			}
		}
		case 2:
		{
			if (g_iCvars[iChatTagColorPrice] <= g_iUserPoints[id])
			{
				g_szUserPrefixColor[id] = "^4"

				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CTAG_COLOR_SUCCES", LANG_SERVER, "CSGOR_CTAG_COLOR_GREEN")
			}
			else
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CTAG_CHANGE_FAIL", (g_iCvars[iChatTagPrice] - g_iUserPoints[id]))
			}
		}
		case 3:
		{
			if (g_iCvars[iChatTagColorPrice] <= g_iUserPoints[id])
			{
				g_szUserPrefixColor[id] = "^1"

				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CTAG_COLOR_SUCCES", LANG_SERVER, "CSGOR_CTAG_COLOR_NORMAL")
			}
			else
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CTAG_CHANGE_FAIL", (g_iCvars[iChatTagPrice] - g_iUserPoints[id]))
			}
		}
	}

	return _MenuExit(menu)
}

public _ShowNameTagsMenu(id)
{
	new szTemp[64]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SKIN_NAMETAG_MENU")
	new menu = menu_create(szTemp, "nametag_menu_handler")

	new szItem[4]

	new item = g_iNametagItem[id][iItemID]
	new bool:bHasItem = false, bool:bHasNameTag = false

	if (strlen(g_szNameTag[id]) > 1)
	{
		formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_NT_TAG", g_szNameTag[id])
		num_to_str(0, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)

		bHasNameTag = true
	}
	else
	{
		formatex(szTemp, charsmax(szTemp), "\r%L", LANG_SERVER, "CSGOR_NT_INSERT_TAG")
		num_to_str(0, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
	}

	if (!_IsItemSkin(item))
	{
		formatex(szTemp, charsmax(szTemp), "\r%L^n", LANG_SERVER, "CSGOR_NT_SELECT_ITEM")
		num_to_str(1, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
	}
	else
	{
		new Item[MAX_SKIN_NAME]

		_GetItemName(g_iNametagItem[id][iItemID], Item, charsmax(Item))

		if(g_iGiftItem[id][iIsStattrack])
		{
			FormatStattrack(Item, charsmax(Item))
		}

		formatex(szTemp, charsmax(szTemp), "\w%L^n", LANG_SERVER, "CSGOR_NT_ITEM", Item)
		num_to_str(1, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)

		bHasItem = true
	}

	if (bHasNameTag && bHasItem)
	{
		formatex(szTemp, charsmax(szTemp), "\r%L", LANG_SERVER, "CSGOR_NT_SEND")
		num_to_str(2, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
	}

	_DisplayMenu(id, menu)
}

public nametag_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}
	new szData[3]
	new index

	menu_item_getinfo(menu, item, .info = szData, .infolen = sizeof(szData))

	index = str_to_num(szData)

	if(index == -10)
	{
		_ShowNameTagsMenu(id)
		return _MenuExit(menu)
	}

	switch (index)
	{
		case 0:
		{
			client_cmd(id, "messagemode NameTag")
		}
		case 1:
		{
			_SelectNametagItem(id)
		}
		case 2:
		{
			if (g_iCvars[iNameTagPrice] > g_iUserPoints[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_POINTS", g_iCvars[iNameTagPrice] - g_iUserPoints[id])
				_ShowNameTagsMenu(id)

				return _MenuExit(menu)
			}

			new item = g_iNametagItem[id][iItemID]

			if (!_UserHasItem(id, item, g_iNametagItem[id][iIsStattrack]))
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_ITEMS")
				g_iNametagItem[id][iItemID] = -1
				g_iNametagItem[id][iIsStattrack] = 0
				g_szNameTag[id] = ""

				_ShowNameTagsMenu(id)
				return _MenuExit(menu)
			}

			new Skin[MAX_SKIN_NAME]

			_GetItemName(g_iNametagItem[id][iItemID], Skin, charsmax(Skin))

			new ePlayerSkins[PlayerSkins], iFound = -1

			ePlayerSkins = GetPlayerSkin(id, item, iFound, g_iNametagItem[id][iIsStattrack])

			if(iFound < 0)
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_ITEMS")
				g_iNametagItem[id][iItemID] = -1
				g_iNametagItem[id][iIsStattrack] = 0
				g_szNameTag[id] = ""

				_ShowNameTagsMenu(id)
				return _MenuExit(menu)
			}

			copy(ePlayerSkins[szNameTag], charsmax(ePlayerSkins[szNameTag]), g_szNameTag[id])

			ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)

			UpdatePlayerSkin(id, Skin, ePlayerSkins)

			if(ePlayerSkins[isStattrack])
			{
				FormatStattrack(Skin, charsmax(Skin))
			}

			g_iUserPoints[id] -= g_iCvars[iNameTagPrice]

			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_NT_APPLIED", g_szNameTag[id], Skin)

			g_iNametagItem[id][iItemID] = -1
			g_iNametagItem[id][iIsStattrack] = 0
			g_szNameTag[id] = ""

			_ShowNameTagsMenu(id)
		}
	}

	return _MenuExit(menu)
}

public Ham_GrenadePrimaryAttack_Pre(ent)
{
	if (is_nullent(ent))
		return

	new id = GetEntityOwner(ent)

	ClearPlayerBit(g_bitShortThrow, id)
}

public Ham_GrenadeSecondaryAttack_Pre(ent)
{
	if (is_nullent(ent) || !IsGrenadeClassName(ent))
		return

	new id = GetEntityOwner(ent)

	ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)

	SetPlayerBit(g_bitShortThrow, id, g_iMaxPlayers)
}

public grenade_throw(id, ent, csw)
{
	if(is_nullent(ent))
		return

	new eDefaultData[iSubModelID + 1]
	
	switch (csw)
	{
		case CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_FLASHBANG:
		{
			ArrayGetArray(g_aDefaultData, csw, eDefaultData)

			engfunc(EngFunc_SetModel, ent, eDefaultData[szWeaponModel])
		}
	}
	
	if(!GetPlayerBit(g_bitShortThrow, id, g_iMaxPlayers))
		return
	
	if (csw == CSW_FLASHBANG)
	{
		set_pev(ent, pev_dmgtime, 1.0 + get_gametime())
	}

	new Float:fVec[3]

	pev(ent, pev_velocity, fVec)

	fVec[0] = fVec[0] * g_iCvars[flShortThrowVelocity]
	fVec[1] = fVec[1] * g_iCvars[flShortThrowVelocity]
	fVec[2] = fVec[2] * g_iCvars[flShortThrowVelocity]

	set_pev(ent, pev_velocity, fVec)
	
	pev(ent, pev_origin, fVec)

	fVec[2] = fVec[2] - 24.00

	set_pev(ent, pev_origin, fVec)

	ClearPlayerBit(g_bitShortThrow, id)
}

public RG_CBasePlayerWeapon_DefaultDeploy_Post(ent, sViewModel[], sWeaponModel[], iAnim, szAnimExt[], skiplocal)
{
	if(is_nullent(ent))
		return
	
	new iPlayer = GetEntityOwner(ent)
	
	new weapon = GetWeaponEntity(ent)

	if(!(CSW_P228 <= weapon <= CSW_P90))
		return
	
	g_iWeaponIndex[iPlayer] = weapon
	
	change_skin(iPlayer, weapon)
}

public HamF_TraceAttack_Post(iEnt, iAttacker, Float:damage, Float:fDir[3], ptr, iDamageType)
{
	if(is_nullent(iAttacker))
		return

	new iWeapon
	static Float:vecEnd[3]

	iWeapon = GetPlayerActiveItem(iAttacker)
	
	new iWeaponEnt = GetWeaponEntity(iWeapon)

	if(!IsValidWeapon(iWeaponEnt) || !iWeaponEnt || iWeaponEnt == CSW_KNIFE)
		return

	get_tr2(ptr, TR_vecEndPos, vecEnd)

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2])
	write_short(iEnt)
	write_byte(random_num(41, 45))
	message_end()
}

public Ham_BlockSecondaryAttack(ent)
{
	if (is_nullent(ent)) 
		return HAM_IGNORED

	static skin, id, weapon, weaponid, bool:bFound

	bFound = false 

	id = GetEntityOwner(ent)

	if (is_nullent(id) || !is_user_alive(id))
		return HAM_IGNORED
	
	weapon = GetPlayerActiveItem(id)

	weaponid = cs_get_weapon_id(weapon)

	skin = (g_iUserSelectedSkin[id][bIsStattrack][weaponid] ? g_iUserSelectedSkin[id][iUserStattrack][weaponid] : g_iUserSelectedSkin[id][iUserSelected][weaponid])

	if (skin > -1) 
	{
		new eSkinData[SkinData]

		ArrayGetArray(g_aSkinData, skin, eSkinData)

		if (containi(eSkinData[szSkinName], "m4a4") != -1) 
		{
			bFound = true
		}
	}
	else
	{
		new szTemp[64]
		pev(id, pev_viewmodel2, szTemp, charsmax(szTemp))

		if (containi(szTemp, "m4a4") != -1) 
		{
			bFound = true
		}
	}

	if(bFound)
	{
		set_member(ent, m_Weapon_flNextSecondaryAttack, 9999.0)
		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

DeployWeaponSwitch(iPlayer)
{
	new weaponid, userskin; 

	new weapon = GetPlayerActiveItem(iPlayer)

	if (is_nullent(weapon))
		return

	weaponid = GetWeaponEntity(weapon)
	userskin = (g_iUserSelectedSkin[iPlayer][bIsStattrack][weaponid] ? g_iUserSelectedSkin[iPlayer][iUserStattrack][weaponid] : g_iUserSelectedSkin[iPlayer][iUserSelected][weaponid])

	new imp = pev(weapon, pev_impulse)

	new eSkinData[SkinData]

	if (0 < imp)
	{
		ArrayGetArray(g_aSkinData, imp - 1, eSkinData)

		SetWeaponModel(iPlayer, true, eSkinData[szViewModel])

		g_iUserViewBody[iPlayer][weaponid] = eSkinData[iSubModelID]

		if (eSkinData[bHasWeaponModel])
		{
			SetWeaponModel(iPlayer, false, eSkinData[szWeaponModel])
		}
	}
	else
	{
		if (userskin > -1)
		{
			new ePlayerSkins[PlayerSkins]

			ePlayerSkins = GetPlayerSkin(iPlayer, userskin, .iSTT = g_iUserSelectedSkin[iPlayer][bIsStattrack][weaponid])

			if(!g_eEnumBooleans[iPlayer][IsInPreview])
			{
				if(g_iUserSelectedSkin[iPlayer][bIsStattrack][weaponid])
				{
					if(1 > ePlayerSkins[iPieces])
					{
						userskin = -1
						g_iUserSelectedSkin[iPlayer][iUserStattrack][weaponid] = -1
						g_iUserSelectedSkin[iPlayer][bIsStattrack][weaponid] = false
					}
				}
				else
				{
					if(1 > ePlayerSkins[iPieces])
					{
						userskin = -1
						g_iUserSelectedSkin[iPlayer][iUserSelected][weaponid] = -1
					}
				}
			}

		 	if(g_bLogged[iPlayer] && userskin != -1)
			{
				ArrayGetArray(g_aSkinData, userskin, eSkinData)

				SetWeaponModel(iPlayer, true, eSkinData[szViewModel])

				g_iUserViewBody[iPlayer][weaponid] = eSkinData[iSubModelID]

				if (eSkinData[bHasWeaponModel])
				{
					SetWeaponModel(iPlayer, false, eSkinData[szWeaponModel])
				}
			}
		}

		if (containi(eSkinData[szSkinName], "m4a4") != -1) 
		{
			new iEnt = GetPlayerActiveItem(iPlayer)

			if(!is_nullent(iEnt))
			{
				cs_set_weapon_silen(iEnt, 0, 0)
			}
		}

		if(!g_bLogged[iPlayer] || userskin == -1)
		{
			new eDefaultData[iSubModelID + 1]

			ArrayGetArray(g_aDefaultData, g_iWeaponIndex[iPlayer], eDefaultData)

			if(eDefaultData[szViewModel][0] != '-')
			{
				SetWeaponModel(iPlayer, true, eDefaultData[szViewModel])
				g_iUserViewBody[iPlayer][weaponid] = eDefaultData[iSubModelID]
			}

			if(eDefaultData[szWeaponModel][0] != '-')
			{
				SetWeaponModel(iPlayer, false, eDefaultData[szWeaponModel])
			}
		}
	}

	new iRet
	ExecuteForward(g_iForwards[user_weapon_deploy], iRet, iPlayer, weapon)
}

public RG_CBasePlayer_DropPlayerItem_Pre(id)
{
	if (!is_user_connected(id))
		return

	new ent = GetPlayerActiveItem(id)

	if(is_nullent(ent))
		return
	
	new weapon = GetWeaponEntity(ent)

	if (!IsValidWeapon(weapon) || (1 << weapon) & weaponsNotVaild)
		return

	new imp = pev(ent, pev_impulse)

	if (0 < imp)
		return

	new skin = (g_iUserSelectedSkin[id][bIsStattrack][weapon] ? g_iUserSelectedSkin[id][iUserStattrack][weapon] : g_iUserSelectedSkin[id][iUserSelected][weapon])

	if (skin != -1)
	{
		set_pev(ent, pev_impulse, skin + 1)
	}
}

public _ShowOpenCaseCraftMenu(id)
{
	new temp[96]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_OC_CRAFT_MENU")
	new menu = menu_create(temp, "oc_craft_menu_handler")

	new szItem[2]
	szItem[1] = 0

	formatex(temp, charsmax(temp), "\w%L^n%L^n", LANG_SERVER, "CSGOR_OCC_OPENCASE", LANG_SERVER, "CSGOR_OCC_OPEN_ITEMS", g_iUserCases[id], g_iUserKeys[id])
	szItem[0] = 0
	menu_additem(menu, temp, szItem)

	if (0 < g_iCvars[iDropType])
	{
		formatex(temp, charsmax(temp), "\r%L^n\w%L^n", LANG_SERVER, "CSGOR_OCC_BUY_KEY", LANG_SERVER, "CSGOR_MR_PRICE", g_iCvars[iKeyPrice])
		szItem[0] = 2
		menu_additem(menu, temp, szItem)

		formatex(temp, charsmax(temp), "\r%L \w| %L^n", LANG_SERVER, "CSGOR_OCC_SELL_KEY", LANG_SERVER, "CSGOR_RECEIVE_POINTS", g_iCvars[iKeyPrice] / 2)
		szItem[0] = 3
		menu_additem(menu, temp, szItem)
	}

	formatex(temp, charsmax(temp), "\w%L^n%L^n", LANG_SERVER, "CSGOR_OCC_CRAFT", LANG_SERVER, "CSGOR_OCC_CRAFT_ITEMS", g_iUserDusts[id], g_iCvars[iCraftCost])
	szItem[0] = 1
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L \y(StatTrack)^n%L", LANG_SERVER, "CSGOR_OCC_CRAFT", LANG_SERVER, "CSGOR_OCC_CRAFT_ITEMS", g_iUserDusts[id], g_iCvars[iStatTrackCost])
	szItem[0] = 4
	menu_additem(menu, temp, szItem)

	_DisplayMenu(id, menu)

	return PLUGIN_HANDLED
}

public oc_craft_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}

	if(!g_bLogged[id])
	{
		return _MenuExit(menu)
	}

	new itemdata[2]
	new dummy
	new index

	menu_item_getinfo(menu, item, dummy, itemdata, 1)

	index = itemdata[0]

	switch (index)
	{
		case 0:
		{
			if (g_iUserCases[id] < 1 || g_iUserKeys[id] < 1)
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_OPEN_NOT_ENOUGH")
				_ShowOpenCaseCraftMenu(id)
			}
			else 
			{
				if (get_systime() < g_iLastOpenCraft[id] + 5 && (g_iCvars[iAntiSpam] || g_iCvars[iShowDropCraft]))
				{
					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_DONT_SPAM", 5)
					_ShowOpenCaseCraftMenu(id)
				}
				else
				{
					_OpenCraftSkin(id, iOpenCase)
				}
			}
		}
		case 1:
		{
			if (g_iCvars[iCraftCost] > g_iUserDusts[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CRAFT_NOT_ENOUGH", g_iCvars[iCraftCost] - g_iUserDusts[id])
				_ShowOpenCaseCraftMenu(id)
			}
			else
			{
				if(g_iCvars[iAntiSpam] || g_iCvars[iShowDropCraft])
				{
					if (get_systime() < g_iLastOpenCraft[id] + 5)
					{
						CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_DONT_SPAM", 5)
						_ShowOpenCaseCraftMenu(id)

						return PLUGIN_HANDLED
					}
				}
				_OpenCraftSkin(id, iCraft)
			}
		}
		case 2:
		{
			if (g_iCvars[iKeyPrice] > g_iUserPoints[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_POINTS", g_iCvars[iKeyPrice] - g_iUserPoints[id])
				_ShowOpenCaseCraftMenu(id)
			}
			else
			{
				g_iUserPoints[id] -= g_iCvars[iKeyPrice]
				g_iUserKeys[id]++

				_Save(id)

				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_BUY_KEY")
				_ShowOpenCaseCraftMenu(id)
			}
		}
		case 3:
		{
			if (1 > g_iUserKeys[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_NONE_KEYS")
				_ShowOpenCaseCraftMenu(id)
			}
			else
			{
				g_iUserPoints[id] += g_iCvars[iKeyPrice] / 2
				g_iUserKeys[id]--

				_Save(id)

				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_SELL_KEY")
				_ShowOpenCaseCraftMenu(id)
			}
		}
		case 4:
		{
			if (g_iCvars[iStatTrackCost] > g_iUserDusts[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CRAFT_NOT_ENOUGH", g_iCvars[iStatTrackCost] - g_iUserDusts[id])
				_ShowOpenCaseCraftMenu(id)
			}
			else
			{
				if(g_iCvars[iAntiSpam] || g_iCvars[iShowDropCraft])
				{
					if (get_systime() < g_iLastOpenCraft[id] + 5)
					{
						CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_DONT_SPAM", 5)
						_ShowOpenCaseCraftMenu(id)

						return PLUGIN_HANDLED
					}
				}
				_OpenCraftSkin(id, iCraftStattrack)
			}
		}
	}

	return _MenuExit(menu)
}

public _OpenCraftSkin(id, iType)
{
	if(!g_bLogged[id])
		return

	new bool:succes
	new rSkin
	new rChance
	new skinID

	new eSkinData[SkinData]
	new iCraftType

	switch(iType)
	{
		case iOpenCase:
		{
			iCraftType = g_iDropSkinNum
		}
		case iCraft:
		{
			iCraftType = g_iCraftSkinNum
		}
		case iCraftStattrack:
		{
			iCraftType = ArraySize(g_aSkinData) - 1
		}
	}

	if (!iCraftType)
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, iType == iOpenCase ? "CSGOR_NO_DROP_SKINS": "CSGOR_NO_CRAFT_SKINS")
		_ShowOpenCaseCraftMenu(id)
		return
	}

	do 
	{
		rSkin = random_num(0, iCraftType - 1)
		rChance = random_num(1, 100)

		switch(iType)
		{
			case iOpenCase:
			{
				skinID = ArrayGetCell(g_aDropSkin, rSkin)
			}
			case iCraft:
			{
				skinID = ArrayGetCell(g_aCraftSkin, rSkin)
			}
			case iCraftStattrack:
			{
				skinID = random_num(0, ArraySize(g_aSkinData) - 1)
			}
		}

		ArrayGetArray(g_aSkinData, skinID, eSkinData)

		if (rChance >= eSkinData[iSkinChance])
		{
			succes = true
		}
	}while (!succes)

	if (succes)
	{
		new ePlayerSkins[PlayerSkins], iFound = -1

		ePlayerSkins = GetPlayerSkin(id, skinID, iFound)
		
		if(iFound < 0)
		{
			iFound = SetPlayerSkin(id, skinID, ePlayerSkins)
		}

		switch(iType)
		{
			case iOpenCase:
			{
				ePlayerSkins[iPieces] += 1
				g_iUserCases[id]--
				g_iUserKeys[id]--
			}
			case iCraft:
			{
				ePlayerSkins[iPieces] += 1
				g_iUserDusts[id] -= g_iCvars[iCraftCost]
			}
			case iCraftStattrack:
			{
				ePlayerSkins[iPieces] += 1
				ePlayerSkins[isStattrack] = 1
				g_iUserDusts[id] -= g_iCvars[iStatTrackCost]
			}
		}

		ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)

		UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins)

		_Save(id)

		if(iType == iCraftStattrack)
		{
			FormatStattrack(eSkinData[szSkinName], charsmax(eSkinData[szSkinName]))
		}

		if (0 < g_iCvars[iShowDropCraft])
		{
			CC_SendMessage(0, "^1%L", LANG_SERVER, iType == iOpenCase ? "CSGOR_DROP_SUCCESS_ALL" : "CSGOR_CRAFT_SUCCESS_ALL", g_szName[id], eSkinData[szSkinName], 100 - eSkinData[iSkinChance])
		}
		else
		{
			CC_SendMessage(id, "^1%L", LANG_SERVER, iType == iOpenCase ? "CSGOR_DROP_SUCCESS" : "CSGOR_CRAFT_SUCCESS", eSkinData[szSkinName], 100 - eSkinData[iSkinChance])
		}

		g_iLastOpenCraft[id] = get_systime()

		_ShowOpenCaseCraftMenu(id)

		ExecuteForward(g_iForwards[ user_case_opening ], g_iForwardResult, id)
	}
	else
	{
		_ShowOpenCaseCraftMenu(id)
	}
}

public _ShowMarketMenu(id)
{
	new temp[96]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_MARKET_MENU")
	new menu = menu_create(temp, "market_menu_handler")

	new szItem[3]

	new szSkinSell[MAX_SKIN_NAME]

	if (!_IsGoodItem(g_iUserSellItem[id][iItemID]))
	{
		formatex(temp, charsmax(temp), "\y%L", LANG_SERVER, "CSGOR_MR_SELECT_ITEM")
	}
	else
	{
		_GetItemName(g_iUserSellItem[id][iItemID], szSkinSell, charsmax(szSkinSell))
		if(g_iUserSellItem[id][iIsStattrack])
		{
			FormatStattrack(szSkinSell, charsmax(szSkinSell))
		}

		formatex(temp, charsmax(temp), "\w%L^n\w%L", LANG_SERVER, "CSGOR_MR_SELL_ITEM", szSkinSell, LANG_SERVER, "CSGOR_MR_PRICE", g_iUserItemPrice[id])
	}

	num_to_str(33, szItem, sizeof(szItem))
	menu_additem(menu, temp, szItem)

	if (g_bUserSell[id])
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_MR_CANCEL_SELL")
		num_to_str(35, szItem, sizeof(szItem))
		menu_additem(menu, temp, szItem)
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_MR_START_SELL")
		num_to_str(34, szItem, sizeof(szItem))
		menu_additem(menu, temp, szItem)
	}

	new Pl[32]
	new n
	new p

	get_players(Pl, n, "ch")

	if (n)
	{
		new items
		new eSkinData[SkinData]

		for (new i; i < n; i++)
		{
			p = Pl[i]

			if (g_bLogged[p])
			{
				if (!(p == id))
				{
					if (g_bUserSell[p])
					{
						new index = g_iUserSellItem[p][iItemID]

						_GetItemName(index, szSkinSell, charsmax(szSkinSell))

						if (_IsItemSkin(index))
						{
							ArrayGetArray(g_aSkinData, index, eSkinData)

							if(g_iUserSellItem[p][iIsStattrack])
							{
								FormatStattrack(szSkinSell, charsmax(szSkinSell))
							}
						}

						formatex(temp, charsmax(temp), "\w%s | \r%s \y%s\w| \y%d %L", g_szName[p], szSkinSell, eSkinData[iSkinType] == 'c' ? "*" : "", g_iUserItemPrice[p], LANG_SERVER, "CSGOR_POINTS")
						num_to_str(p, szItem, sizeof(szItem))
						menu_additem(menu, temp, szItem)
						items++
					}
				}
			}
		}

		if (!items)
		{
			formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_NOBODY_SELL")
			num_to_str(0, szItem, sizeof(szItem))
			menu_additem(menu, temp, szItem)
		}
	}

	_DisplayMenu(id, menu)
}

public market_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}

	new szData[3]
	new index

	menu_item_getinfo(menu, item, .info = szData, .infolen = sizeof(szData))

	index = str_to_num(szData)

	switch (index)
	{
		case 0:
		{
			_ShowMarketMenu(id)
			return _MenuExit(menu)
		}
		case 33:
		{
			if (g_bUserSell[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_CANCEL")
				_ShowMarketMenu(id)
			}
			else
			{
				_ShowItems(id)
			}
		}
		case 34:
		{
			if (!_IsGoodItem(g_iUserSellItem[id][iItemID]))
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_SELECT")
				_ShowMarketMenu(id)
			}
			else
			{
				if ( ( get_systime() - g_iLastPlace[id] ) < g_iCvars[iWaitForPlace] )
				{
					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_WAIT", floatround(float(g_iCvars[iWaitForPlace]) - (get_systime() - g_iLastPlace[id])))
					return _MenuExit(menu)
				}

				if (g_iUserItemPrice[id] < 1)
				{
					CC_SendMessage(id, "^1%L", id, "CSGOR_IM_SET_PRICE")
					_ShowMarketMenu(id)
				}

				new wPriceMin
				new wPriceMax

				_CalcItemPrice(g_iUserSellItem[id][iItemID], wPriceMin, wPriceMax)

				if (!(wPriceMin <= g_iUserItemPrice[id] <= wPriceMax))
				{
					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_ITEM_MIN_MAX_COST", wPriceMin, wPriceMax)
					_ShowMarketMenu(id)

					return _MenuExit(menu)
				}

				g_bUserSell[id] = true
				g_iLastPlace[id] = get_systime()

				new Item[MAX_SKIN_NAME]
				_GetItemName(g_iUserSellItem[id][iItemID], Item, charsmax(Item))

				if(g_iUserSellItem[id][iIsStattrack])
				{
					FormatStattrack(Item, charsmax(Item))
				}

				CC_SendMessage(0, " %L", LANG_SERVER, "CSGOR_SELL_ANNOUNCE", g_szName[id], Item, g_iUserItemPrice[id])
			}
		}
		case 35:
		{
			g_bUserSell[id] = false
			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_CANCEL_SELL")

			_ShowMarketMenu(id)
		}
		default:
		{
			new tItem = g_iUserSellItem[index][iItemID]
			new price = g_iUserItemPrice[index]

			if (!g_bLogged[index] || !is_user_connected(index))
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_INVALID_SELLER")

				g_bUserSell[index] = false

				_ShowMarketMenu(id)

				return _MenuExit(menu)
			}
			else
			{
				if (!_UserHasItem(index, tItem, g_iUserSellItem[index][iIsStattrack]))
				{
					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_DONT_HAVE_ITEM")

					g_bUserSell[index] = false
					g_iUserSellItem[index][iItemID] = -1
					g_iUserSellItem[index][iIsStattrack] = 0

					_ShowMarketMenu(id)

					return _MenuExit(menu)
				}

				if (price > g_iUserPoints[id] || g_iUserPoints[id] <= 0)
				{

					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_POINTS", price - g_iUserPoints[id])

					_ShowMarketMenu(id)

					return _MenuExit(menu)
				}

				new szItem[MAX_SKIN_NAME]
				_GetItemName(g_iUserSellItem[index][iItemID], szItem, charsmax(szItem))

				switch (tItem)
				{
					case KEY:
					{
						g_iUserKeys[id]++
						g_iUserKeys[index]--
						g_iUserPoints[id] -= price
						g_iUserPoints[index] += price

						_Save(id)
						_Save(index)

						CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_X_BUY_Y", g_szName[id], szItem, g_szName[index])
					}
					case CASE:
					{
						g_iUserCases[id]++
						g_iUserCases[index]--
						g_iUserPoints[id] -= price
						g_iUserPoints[index] += price

						_Save(id)
						_Save(index)

						CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_X_BUY_Y", g_szName[id], szItem, g_szName[index])
					}
					default:
					{
						new ePlayerSkins[PlayerSkins], iFound = -1

						ePlayerSkins = GetPlayerSkin(id, tItem, iFound, g_iUserSellItem[index][iIsStattrack])

						if(iFound < 0)
						{
							iFound = SetPlayerSkin(id, tItem, ePlayerSkins, g_iUserSellItem[index][iIsStattrack])
						}

						ePlayerSkins[iPieces] += 1
						ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)

						UpdatePlayerSkin(id, szItem, ePlayerSkins)

						ePlayerSkins = GetPlayerSkin(index, tItem, iFound, g_iUserSellItem[index][iIsStattrack])

						ePlayerSkins[iPieces] -= 1
						if(ePlayerSkins[iPieces] <= 0)
						{
							ArrayDeleteItem(g_aPlayerSkins[index], iFound)

							UpdatePlayerSkin(index, szItem, ePlayerSkins, true)
						}
						else
						{
							ArraySetArray(g_aPlayerSkins[index], iFound, ePlayerSkins)
							UpdatePlayerSkin(index, szItem, ePlayerSkins)
						}

						g_iUserPoints[id] -= price
						g_iUserPoints[index] += price

						if(g_iUserSellItem[index][iIsStattrack])
						{
							FormatStattrack(szItem, charsmax(szItem))
						}

						CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_X_BUY_Y", g_szName[id], szItem, g_szName[index])
					}
				}

				g_iUserSellItem[index][iItemID] = -1
				g_iUserSellItem[index][iIsStattrack] = 0
				g_bUserSell[index] = false
				g_iUserItemPrice[index] = 0

				_ShowMainMenu(id)
			}
		}
	}

	return _MenuExit(menu)
}

public _ShowItems(id)
{
	new szTemp[64]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_ITEM_MENU")
	new menu = menu_create(szTemp, "sell_menu_handler")

	new szItem[8]
	new total

	if (0 < g_iUserCases[id])
	{
		formatex(szTemp, charsmax(szTemp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_CASE", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserCases[id])
		num_to_str(CASE, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
		total++
	}

	if (0 < g_iUserKeys[id])
	{
		formatex(szTemp, charsmax(szTemp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_KEY", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserKeys[id])
		num_to_str(KEY, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)

		total++
	}

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_NORMAL_SKIN_MENU")
	num_to_str(0, szItem, charsmax(szItem))
	menu_additem(menu, szTemp, szItem)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_STATTRACK_SKIN_MENU")
	num_to_str(1, szItem, charsmax(szItem))
	menu_additem(menu, szTemp, szItem)

	if (!total)
	{
		formatex(szTemp, charsmax(szTemp), "\r%L", LANG_SERVER, "CSGOR_NO_ITEMS")
		num_to_str(-10, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
	}

	_DisplayMenu(id, menu)
}

public sell_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMarketMenu(id)
		}
		return _MenuExit(menu)
	}

	new data[8]
	new index

	menu_item_getinfo(menu, item, .info = data, .infolen = sizeof(data))

	index = str_to_num(data)

	switch(index)
	{
		case -10:
		{
			_ShowMarketMenu(id)
			return _MenuExit(menu)
		}
		case 0:
		{
			_ShowNormalSkinsMenu(id, iSell)
		}
		case 1:
		{
			_ShowStattrackSkinsMenu(id, iSell)
		}
		case KEY, CASE:
		{
			new szItem[MAX_SKIN_NAME]

			_GetItemName(index, szItem, charsmax(szItem))

			g_iUserSellItem[id][iItemID] = index
			g_iUserSellItem[id][iIsStattrack] = 0

			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_IM_SELECT", szItem)

			client_cmd(id, "messagemode ItemPrice")

			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_IM_SET_PRICE")
		}
	}

	return _MenuExit(menu)
}

public item_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMarketMenu(id)
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
		_ShowMarketMenu(id)
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

		if(_IsItemSkin(index))
		{
			if(iLocked)
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_ITEM_LOCKED", szItem)
				_ShowMarketMenu(id)

				return _MenuExit(menu)
			}
		}
		
		g_iUserSellItem[id][iItemID] = index
		g_iUserSellItem[id][iIsStattrack] = iStt

		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_IM_SELECT", szItem)

		client_cmd(id, "messagemode ItemPrice")

		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_IM_SET_PRICE")
	}

	return _MenuExit(menu)
}

public nt_select_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowNameTagsMenu(id)
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
		_ShowNameTagsMenu(id)
		return _MenuExit(menu)
	}
	else
	{
		new szItem[MAX_SKIN_NAME], iLocked, iStt = str_to_num(szSplit[1])

		_GetItemName(index, szItem, charsmax(szItem), iLocked)

		if(!_IsItemSkin(index))
			return _MenuExit(menu)
		
		new ePlayerSkins[PlayerSkins], iFound = -1

		ePlayerSkins = GetPlayerSkin(id, index, iFound, iStt)

		if(iFound < 0)
		{
			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_SM_NO_SKINS")

			return _MenuExit(menu)
		}

		g_iNametagItem[id][iItemID] = index
		g_iNametagItem[id][iIsStattrack] = iStt

		_ShowNameTagsMenu(id)
	}

	return _MenuExit(menu)
}

public gifting_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMarketMenu(id)
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
		_ShowGiftMenu(id)
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

		if(_IsItemSkin(index))
		{
			if(iLocked)
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_ITEM_LOCKED", szItem)
				_ShowMarketMenu(id)

				return _MenuExit(menu)
			}
		}
		
		g_iGiftItem[id][iItemID] = index
		g_iGiftItem[id][iIsStattrack] = iStt

		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_YOUR_GIFT", szItem)

		_ShowGiftMenu(id)
	}

	return _MenuExit(menu)
}

public trading_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMarketMenu(id)
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
		_ShowMarketMenu(id)
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

		if(_IsItemSkin(index))
		{
			if(iLocked)
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_ITEM_LOCKED", szItem)
				_ShowMarketMenu(id)

				return _MenuExit(menu)
			}
		}
		
		g_iTradeItem[id][iItemID] = index
		g_iTradeItem[id][iIsStattrack] = iStt

		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_ITEM", szItem)
		_ShowTradeMenu(id)
	}

	return _MenuExit(menu)
}

public concmd_itemprice(id)
{
	new item = g_iUserSellItem[id][iItemID]

	if (!_IsGoodItem(item))
	{
		return PLUGIN_HANDLED
	}

	new data[16]

	read_args(data, 15)
	remove_quotes(data)

	new uPrice
	new wPriceMin
	new wPriceMax

	uPrice = str_to_num(data)
	_CalcItemPrice(item, wPriceMin, wPriceMax)

	if (uPrice < wPriceMin || uPrice > wPriceMax)
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_ITEM_MIN_MAX_COST", wPriceMin, wPriceMax)
		client_cmd(id, "messagemode ItemPrice")

		return PLUGIN_HANDLED
	}

	g_iUserItemPrice[id] = uPrice
	_ShowMarketMenu(id)

	return PLUGIN_HANDLED
}

public concmd_nametag(id)
{
	new data[32]

	read_args(data, charsmax(data))
	remove_quotes(data)

	if ( strlen(data) < 1 || strlen(data) > 20 || containi(data, "%") != -1)
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_NT_INSERT_TAG")

		client_cmd(id, "messagemode NameTag")
	}
	else
	{
		copy(g_szNameTag[id], charsmax(g_szNameTag[]), data)

		_ShowNameTagsMenu(id)

		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_INSERTED_NAMETAG", g_szTemporaryCtag[id])
	}
	return PLUGIN_HANDLED
}

public _ShowDustbinMenu(id)
{
	new temp[MAX_SKIN_NAME]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_DB_MENU")
	new menu = menu_create(temp, "dustbin_menu_handler")

	new szItem[2]
	szItem[1] = 0

	formatex(temp, charsmax(temp), "\y%L\n", LANG_SERVER, "CSGOR_DB_TRANSFORM")
	szItem[0] = 1
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_DB_DESTROY")
	szItem[0] = 2
	menu_additem(menu, temp, szItem)

	_DisplayMenu(id, menu)
}

public dustbin_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}

	new itemdata[2]
	new dummy
	new index

	menu_item_getinfo(menu, item, dummy, itemdata, 1)

	index = itemdata[0]

	g_iMenuType[id] = index

	_ShowSkins(id)

	return _MenuExit(menu)
}

public _ShowSkins(id)
{
	new temp[MAX_SKIN_NAME]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SKINS")
	new menu = menu_create(temp, "db_skins_menu_handler")

	new szItem[32]
	new eSkinData[SkinData], ePlayerSkins[PlayerSkins], iFound = -1
	new total

	for (new i; i < ArraySize(g_aSkinData); i++)
	{
		ePlayerSkins = GetPlayerSkin(id, i, iFound)

		if(iFound < 0)
			continue

		if (0 < ePlayerSkins[iPieces])
		{
			ArrayGetArray(g_aSkinData, i, eSkinData)

			new applied[3]

			switch (eSkinData[iSkinType])
			{
				case 'c':
				{
					applied = "#"
				}
				default:
				{
					applied = ""
				}
			}

			if(ePlayerSkins[isStattrack])
			{
				FormatStattrack(eSkinData[szSkinName], charsmax(eSkinData[szSkinName]))
			}

			formatex(temp, charsmax(temp), "\r%s \w| \y%L \r%s", eSkinData[szSkinName], LANG_SERVER, "CSGOR_SM_PIECES", ePlayerSkins[iPieces], applied)
			formatex(szItem, charsmax(szItem), "%d,%d", i, ePlayerSkins[isStattrack])
			menu_additem(menu, temp, szItem)
			total++
		}
	}

	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_SM_NO_SKINS")
		formatex(szItem, charsmax(szItem), "%d,", -10)
		menu_additem(menu, temp, szItem)
	}

	_DisplayMenu(id, menu)
}

public db_skins_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowDustbinMenu(id)
		}

		return _MenuExit(menu)
	}

	if(!g_bLogged[id])
	{
		return _MenuExit(menu)
	}

	new data[6]
	new index
	new szSplit[2][6]

	menu_item_getinfo(menu, item, .info = data, .infolen = sizeof(data))

	strtok(data, szSplit[0], sizeof(szSplit[]), szSplit[1], sizeof(szSplit[]), ',')

	index = str_to_num(szSplit[0])

	if(item == -10)
	{
		_ShowMainMenu(id)

		return _MenuExit(menu)
	}

	new eSkinData[SkinData]

	ArrayGetArray(g_aSkinData, index, eSkinData)
	
	if(eSkinData[iSkinLock])
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_ITEM_LOCKED", eSkinData[szSkinName])
	}
	else
	{
		new ePlayerSkins[PlayerSkins], iFound = -1

		ePlayerSkins = GetPlayerSkin(id, index, iFound, str_to_num(szSplit[1]))

		if(iFound < 0)
		{
			g_iMenuType[id] = 0
			_ShowDustbinMenu(id)

			return _MenuExit(menu)
		}

		new rest

		switch (g_iMenuType[id])
		{
			case 1:
			{
				ePlayerSkins[iPieces] -= 1

				g_iUserDusts[id] += eSkinData[iSkinDust]

				_Save(id)
			}
			case 2:
			{
				ePlayerSkins[iPieces] -= 1

				rest = eSkinData[iSkinCostMin] / g_iCvars[iReturnPercent]

				g_iUserPoints[id] += rest

				_Save(id)
			}
		}

		if(!ePlayerSkins[iPieces])
		{
			ArrayDeleteItem(g_aPlayerSkins[id], iFound)
			UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins, true)
		}
		else
		{
			ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)
			UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins)
		}

		if(ePlayerSkins[isStattrack])
		{
			FormatStattrack(eSkinData[szSkinName], charsmax(eSkinData[szSkinName]))
		}

		switch(g_iMenuType[id])
		{
			case 1:
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRANSFORM", eSkinData[szSkinName], eSkinData[iSkinDust])
			}
			case 2:
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_DESTORY", eSkinData[szSkinName], rest)
			}
		}
	}
	
	g_iMenuType[id] = 0
	_ShowDustbinMenu(id)

	return _MenuExit(menu)
}

public _ShowGiftTradeMenu(id)
{
	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_GIFT_TRADE_MENU")
	new menu = menu_create(temp, "gift_trade_menu_handler")

	new szItem[2]
	szItem[1] = 0

	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_MM_GIFT")
	menu_additem(menu, temp, szItem)

	formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_MM_TRADE")
	menu_additem(menu, temp, szItem)
	
	_DisplayMenu(id, menu)
}

public gift_trade_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
		return _MenuExit(menu)

	switch(item)
	{
		case 0:
		{
			_ShowGiftMenu(id)
		}
		case 1:
		{
			_ShowTradeMenu(id)
		}
	}

	return _MenuExit(menu)
}

public _ShowGiftMenu(id)
{
	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_GIFT_MENU")
	new menu = menu_create(temp, "gift_menu_handler")

	new szItem[2]
	szItem[1] = 0

	new bool:HasTarget
	new bool:HasItem
	new target = g_iGiftTarget[id]

	if (is_user_connected(target))
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GM_TARGET", g_szName[target])
		szItem[0] = 0
		menu_additem(menu, temp, szItem)

		HasTarget = true
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_GM_SELECT_TARGET")
		szItem[0] = 0
		menu_additem(menu, temp, szItem)
	}

	if (!_IsGoodItem(g_iGiftItem[id][iItemID]))
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_GM_SELECT_ITEM")
		szItem[0] = 1
		menu_additem(menu, temp, szItem)
	}
	else
	{
		new Item[MAX_SKIN_NAME]

		_GetItemName(g_iGiftItem[id][iItemID], Item, charsmax(Item))

		if(g_iGiftItem[id][iIsStattrack])
		{
			FormatStattrack(Item, charsmax(Item))
		}

		formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_GM_ITEM", Item)
		szItem[0] = 1
		menu_additem(menu, temp, szItem)

		HasItem = true
	}

	if (HasTarget && HasItem)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_GM_SEND")
		szItem[0] = 2
		menu_additem(menu, temp, szItem)
	}

	_DisplayMenu(id, menu)
}

public gift_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}
	new itemdata[2]
	new dummy
	new index

	menu_item_getinfo(menu, item, dummy, itemdata, 1)

	index = itemdata[0]

	if(item == -10)
	{
		_ShowGiftMenu(id)
		return _MenuExit(menu)
	}

	switch (index)
	{
		case 0:
		{
			_SelectTarget(id)
		}
		case 1:
		{
			_SelectItem(id)
		}
		case 2:
		{
			new target = g_iGiftTarget[id]
			new _item = g_iGiftItem[id][iItemID]
			if (!g_bLogged[target] || !is_user_connected(target))
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_INVALID_TARGET")
				g_iGiftTarget[id] = 0

				_ShowGiftMenu(id)
			}
			else
			{
				if (!_UserHasItem(id, _item, g_iGiftItem[id][iIsStattrack]))
				{
					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_ITEMS")
					g_iGiftItem[id][iItemID] = -1

					_ShowGiftMenu(id)
				}

				new gift[16]

				switch (_item)
				{
					case KEY:
					{
						g_iUserKeys[id]--
						g_iUserKeys[target]++

						formatex(gift, charsmax(gift), "%L", id, "CSGOR_ITEM_KEY")

						CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_SEND_GIFT", gift, g_szName[target])
						CC_SendMessage(target, "^1%L", LANG_SERVER, "CSGOR_RECIEVE_GIFT", g_szName[id], gift)
					}
					case CASE:
					{
						g_iUserCases[id]--
						g_iUserCases[target]++

						formatex(gift, charsmax(gift), "%L", id, "CSGOR_ITEM_CASE")

						CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_SEND_GIFT", gift, g_szName[target])
						CC_SendMessage(target, "^1%L", LANG_SERVER, "CSGOR_RECIEVE_GIFT", g_szName[id], gift)
					}
					default:
					{
						new Skin[MAX_SKIN_NAME]

						_GetItemName(g_iGiftItem[id][iItemID], Skin, charsmax(Skin))

						new ePlayerSkins[PlayerSkins], iFound = -1

						ePlayerSkins = GetPlayerSkin(target, _item, iFound, g_iGiftItem[id][iIsStattrack])

						if(iFound < 0)
						{
							iFound = SetPlayerSkin(target, _item, ePlayerSkins, g_iGiftItem[id][iIsStattrack])
							ePlayerSkins[iPieces] += 1
						}

						ArraySetArray(g_aPlayerSkins[target], iFound, ePlayerSkins)

						UpdatePlayerSkin(target, Skin, ePlayerSkins)

						ePlayerSkins = GetPlayerSkin(id, _item, iFound, g_iGiftItem[id][iIsStattrack])

						ePlayerSkins[iPieces] -= 1
						if(0 <= ePlayerSkins[iPieces])
						{
							ArrayDeleteItem(g_aPlayerSkins[id], iFound)

							UpdatePlayerSkin(id, Skin, ePlayerSkins, true)
						}
						else
						{
							ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)
							UpdatePlayerSkin(id, Skin, ePlayerSkins)
						}

						if(ePlayerSkins[isStattrack])
						{
							FormatStattrack(Skin, charsmax(Skin))
						}

						CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_SEND_GIFT", Skin, g_szName[target])
						CC_SendMessage(target, "^1%L", LANG_SERVER, "CSGOR_RECIEVE_GIFT", g_szName[id], Skin)
					}
				}

				g_iGiftTarget[id] = 0
				g_iGiftItem[id][iItemID] = -1

				_ShowMainMenu(id)
			}
		}
	}

	return _MenuExit(menu)
}

public _SelectTarget(id)
{
	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \y%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_GM_SELECT_TARGET")
	new menu = menu_create(temp, "st_menu_handler")

	new szItem[3]

	new Pl[32]
	new n
	new p

	get_players(Pl, n, "h")

	new total

	if (n)
	{
		for (new i; i < n; i++)
		{
			p = Pl[i]

			if (g_bLogged[p])
			{
				if (!(p == id))
				{
					num_to_str(p, szItem, sizeof(szItem))
					menu_additem(menu, g_szName[p], szItem)
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

public st_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGiftMenu(id)
		}

		return _MenuExit(menu)
	}

	new szData[3]
	new index
	new name[32]

	menu_item_getinfo(menu, item, .info = szData, .infolen = sizeof(szData), .name = name, .namelen = sizeof(name))

	index = str_to_num(szData)

	switch (index)
	{
		case -10:
		{
			_ShowMainMenu(id)
		}
		default:
		{
			g_iGiftTarget[id] = index
			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_YOUR_TARGET", name)

			_ShowGiftMenu(id)
		}
	}

	return _MenuExit(menu)
}

public _SelectNametagItem(id)
{
	new szTemp[64]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_ITEM_MENU")
	new menu = menu_create(szTemp, "nt_select_item_handler")

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_NORMAL_SKIN_MENU")
	menu_additem(menu, szTemp)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_STATTRACK_SKIN_MENU")
	menu_additem(menu, szTemp)

	_DisplayMenu(id, menu)
}

public nt_select_item_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowNameTagsMenu(id)
		}

		return _MenuExit(menu)
	}

	switch (item)
	{
		case 0:
		{
			_ShowNormalSkinsMenu(id, iNameTag)
		}
		case 1:
		{
			_ShowStattrackSkinsMenu(id, iNameTag)
		}
	}

	return _MenuExit(menu)
}

public _SelectItem(id)
{
	new szTemp[64]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_ITEM_MENU")
	new menu = menu_create(szTemp, "si_menu_handler")

	new szItem[32]
	new total

	if (0 < g_iUserCases[id])
	{
		formatex(szTemp, charsmax(szTemp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_CASE", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserCases[id])
		num_to_str(CASE, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
		total++
	}

	if (0 < g_iUserKeys[id])
	{
		formatex(szTemp, charsmax(szTemp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_KEY", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserKeys[id])
		num_to_str(KEY, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
		total++
	}

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_NORMAL_SKIN_MENU")
	num_to_str(0, szItem, charsmax(szItem))
	menu_additem(menu, szTemp, szItem)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_STATTRACK_SKIN_MENU")
	num_to_str(1, szItem, charsmax(szItem))
	menu_additem(menu, szTemp, szItem)

	if (!total)
	{
		formatex(szTemp, charsmax(szTemp), "\r%L", LANG_SERVER, "CSGOR_NO_ITEMS")
		num_to_str(-10, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
	}

	_DisplayMenu(id, menu)
}

public si_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGiftMenu(id)
		}

		return _MenuExit(menu)
	}

	new itemdata[3]
	new data[6][32]
	new index[32]

	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1])

	parse(data[0], index, charsmax(index))

	item = str_to_num(index)

	switch (item)
	{
		case -10:
		{
			_ShowMainMenu(id)
		}
		case 0:
		{
			_ShowNormalSkinsMenu(id, iGift)
		}
		case 1:
		{
			_ShowStattrackSkinsMenu(id, iGift)
		}
		case KEY, CASE:
		{
			if (item == g_iUserSellItem[id][iItemID] && g_bUserSell[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_INVALID_GIFT")
				_SelectItem(id)
			}
			else
			{
				g_iGiftItem[id][iItemID] = item
				new szItem[MAX_SKIN_NAME]
				_GetItemName(item, szItem, charsmax(szItem))

				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_YOUR_GIFT", szItem)

				_ShowGiftMenu(id)
			}
		}
	}

	return _MenuExit(menu)
}

public Message_DeathMsg(msgId, msgDest, msgEnt)
{
	return PLUGIN_HANDLED
}


public hook_say(id)
{
	if(!is_user_connected(id) || !g_iCvars[iCustomChat])
		return

	new szMessage[128]
	read_argv(1, szMessage, charsmax(szMessage))

	ProcessChat(id, szMessage, true)
}

public hook_sayteam(id)
{
	if(!is_user_connected(id) || !g_iCvars[iCustomChat])
		return

	new szMessage[128]
	read_argv(1, szMessage, charsmax(szMessage))

	ProcessChat(id, szMessage, false)
}

ProcessChat(id, szMessage[128], bool:bAllChat)
{
	/* Fixing % chat exploits */
	if(containi(szMessage, "%") != -1)
	{
		replace_all(szMessage, charsmax(szMessage), "%", "")		
	}

	trim(szMessage)

	if(!strlen(szMessage))
		return

	new iSize = ArraySize(g_aSkipChat)

	if(iSize)
	{
		new szChatSkip[20], bool:bFound = false
		for(new i; i < iSize; i++)
		{
			ArrayGetString(g_aSkipChat, i, szChatSkip, charsmax(szChatSkip))

			if(equali(szMessage, szChatSkip, strlen(szChatSkip)))
			{
				bFound = true
				break
			}
		}

		if(bFound)
			return
	}

	new iChat
	new CsTeams:iTeams = cs_get_user_team(id)
	new szSaid[128]

	copy(szSaid, charsmax(szSaid), szMessage)

	if(bAllChat)
	{
		iChat = AllChat

		if(!is_user_alive(id))
		{
			iChat = DeadChat

			if(iTeams == CS_TEAM_SPECTATOR)
			{
				iChat = SpecChat
			}
		}
	}
	else
	{
		switch(iTeams)
		{
			case CS_TEAM_CT:
			{
				iChat = CTChat
			}
			case CS_TEAM_T:
			{
				iChat = TeroChat
			}
			case CS_TEAM_SPECTATOR:
			{
				iChat = SpecChat
			}
		}
	}
	
	if(g_bLogged[id])
	{
		new szRank[MAX_RANK_NAME]

		ArrayGetString(g_aRankName, g_iUserRank[id], szRank, charsmax(szRank))

		new len = strlen(g_szUserPrefix[id])
		new tag[20]

		if(len > 3)
		{
			formatex(tag, charsmax(tag), "[%s]", g_szUserPrefix[id])
		}
		else
		{
			copy(tag, charsmax(tag), g_szUserPrefix[id])
		}

		switch (iChat)
		{
			case AllChat:
			{
				formatex(szMessage, charsmax(szMessage), "^4[%s] ^1%s%s ^3%n ^1: %s", szRank, (len > 0) ? g_szUserPrefixColor[id] : "^1", tag, id, szSaid)
			}
			case DeadChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*DEAD* ^4[%s] ^1%s%s ^3%n ^1: %s", szRank, (len > 0) ? g_szUserPrefixColor[id] : "^1", tag, id, szSaid)
			}
			case SpecChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*SPEC* ^4[%s] ^1%s%s ^3%n ^1: %s", szRank, (len > 0) ? g_szUserPrefixColor[id] : "^1", tag, id, szSaid)
			}
			case CTChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*CT* ^4[%s] ^1%s%s ^3%n ^1: %s", szRank, (len > 0) ? g_szUserPrefixColor[id] : "^1", tag, id, szSaid)
			}
			case TeroChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*Terrorist* ^4[%s] ^1%s%s ^3%n ^1: %s", szRank, (len > 0) ? g_szUserPrefixColor[id] : "^1", tag, id, szSaid)
			}
		}
	}
	else
	{
		switch (iChat)
		{
			case AllChat:
			{
				formatex(szMessage, charsmax(szMessage), "^4[%L] ^3%n ^1: %s", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT", id, szSaid)
			}
			case DeadChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*DEAD* ^4[%L] ^3%n ^1: %s", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT", id, szSaid)
			}
			case SpecChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*SPEC* ^4[%L] ^3%n ^1: %s", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT", id, szSaid)
			}
			case CTChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*CT* ^4[%L] ^3%n ^1: %s", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT", id, szSaid)
			}
			case TeroChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*Terrorist* ^4[%L] ^3%n ^1: %s", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT", id, szSaid)
			}
		}
	}

	new iPlayer, iPlayers[MAX_PLAYERS], iNum
	get_players(iPlayers, iNum, "c")

	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]

		if(!is_user_connected(iPlayer))
			continue

		if(!bAllChat)
		{
			if(get_user_team(id) != get_user_team(iPlayer))
				continue
		}

		_CC_WriteMessage(iPlayer, szMessage)
	}
}

public Message_SayText(msgId, msgDest, msgEnt)
{
	return PLUGIN_HANDLED
}

public _ShowTradeMenu(id)
{
	if (g_bTradeAccept[id])
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_INFO2")
	}

	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_TRADE_MENU")
	new menu = menu_create(temp, "trade_menu_handler")

	new szItem[2]
	szItem[1] = 0

	new bool:HasTarget
	new bool:HasItem

	new target = g_iTradeTarget[id]

	if (is_user_connected(target))
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GM_TARGET", g_szName[target])
		szItem[0] = 0
		menu_additem(menu, temp, szItem)

		HasTarget = true
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_GM_SELECT_TARGET")
		szItem[0] = 0
		menu_additem(menu, temp, szItem)
	}

	if (!_IsGoodItem(g_iTradeItem[id][iItemID]))
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_GM_SELECT_ITEM")
		szItem[0] = 1
		menu_additem(menu, temp, szItem)
	}
	else
	{
		new Item[MAX_SKIN_NAME]

		_GetItemName(g_iTradeItem[id][iItemID], Item, charsmax(Item))

		if(g_iTradeItem[id][iIsStattrack])
		{
			FormatStattrack(Item, charsmax(Item))
		}

		formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_GM_ITEM", Item)
		szItem[0] = 1
		menu_additem(menu, temp, szItem)
		HasItem = true
	}

	if (HasTarget && HasItem && !g_bTradeActive[id])
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_GM_SEND")
		szItem[0] = 2
		menu_additem(menu, temp, szItem)
	}

	if (g_bTradeActive[id] || g_bTradeSecond[id])
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_TRADE_CANCEL")
		szItem[0] = 3
		menu_additem(menu, temp, szItem)
	}

	_DisplayMenu(id, menu)
}

public trade_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if (g_bTradeSecond[id])
		{
			clcmd_say_deny(id)
		}

		if(is_user_connected(id))
		{
			_ShowMainMenu(id)
		}

		return _MenuExit(menu)
	}

	new itemdata[2]
	new dummy
	new index

	menu_item_getinfo(menu, item, dummy, itemdata, 1)

	index = itemdata[0]

	switch (index)
	{
		case 0:
		{
			if (g_bTradeActive[id] || g_bTradeSecond[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_LOCKED")
				
				_ShowTradeMenu(id)
			}
			else
			{
				_SelectTradeTarget(id)
			}
		}
		case 1:
		{
			if (g_bTradeActive[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_LOCKED")
				
				_ShowTradeMenu(id)
			}
			else
			{
				_SelectTradeItem(id)
			}
		}
		case 2:
		{
			new target = g_iTradeTarget[id]
			new _item = g_iTradeItem[id][iItemID]

			if (!g_bLogged[target] || !is_user_connected(target))
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_INVALID_TARGET")

				_ResetTradeData(id)

				_ShowTradeMenu(id)
			}
			else
			{
				if (!_UserHasItem(id, _item, g_iTradeItem[id][iIsStattrack]))
				{
					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_NOT_ENOUGH_ITEMS")

					g_iTradeItem[id][iItemID] = -1

					_ShowTradeMenu(id)
				}

				if (g_bTradeSecond[id] && !_UserHasItem(target, g_iTradeItem[target][iItemID], g_iTradeItem[target][iIsStattrack]))
				{
					CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_FAIL")
					CC_SendMessage(target, "^1%L", LANG_SERVER, "CSGOR_TRADE_FAIL")

					_ResetTradeData(id)
					_ResetTradeData(target)
					_ShowTradeMenu(id)
				}
				
				g_bTradeActive[id] = true
				g_iTradeRequest[target] = id

				new szItem[MAX_SKIN_NAME]

				_GetItemName(g_iTradeItem[id][iItemID], szItem, charsmax(szItem))

				if(g_iTradeItem[id][iIsStattrack])
				{
					FormatStattrack(szItem, charsmax(szItem))
				}

				if (!g_bTradeSecond[id])
				{
					CC_SendMessage(target, "^1%L", LANG_SERVER, "CSGOR_TRADE_INFO1", g_szName[id], szItem)
					CC_SendMessage(target, "^1%L", LANG_SERVER, "CSGOR_TRADE_INFO2")
				}
				else
				{
					new yItem[MAX_SKIN_NAME]

					_GetItemName(g_iTradeItem[target][iItemID], yItem, charsmax(yItem))

					if(g_iTradeItem[target][iIsStattrack])
					{
						FormatStattrack(yItem, charsmax(yItem))
					}

					CC_SendMessage(target, " %L", LANG_SERVER, "CSGOR_TRADE_INFO3", g_szName[id], szItem, yItem)
					CC_SendMessage(target, "^1%L", LANG_SERVER, "CSGOR_TRADE_INFO2")

					g_bTradeAccept[target] = true
				}
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_SEND", g_szName[target])
			}
		}
		case 3:
		{
			if (g_bTradeSecond[id])
			{
				clcmd_say_deny(id)
			}
			else
			{
				_ResetTradeData(id)
			}

			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_CANCELED")
			_ShowTradeMenu(id)
		}
	}

	return _MenuExit(menu)
}

public _SelectTradeTarget(id)
{
	new temp[64]

	formatex(temp, charsmax(temp), "\r%s \y%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_GM_SELECT_TARGET")
	new menu = menu_create(temp, "tst_menu_handler")

	new szItem[3]

	new Pl[32]
	new n
	new p

	get_players(Pl, n, "h")

	new total

	if (n)
	{
		for (new i; i < n; i++)
		{
			p = Pl[i]

			if (g_bLogged[p])
			{
				if (!(p == id))
				{
					num_to_str(p, szItem, charsmax(szItem))
					menu_additem(menu, g_szName[p], szItem)
					total++
				}
			}
		}
	}

	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_ST_NO_PLAYERS")
		num_to_str(-10, szItem, charsmax(szItem))
		menu_additem(menu, temp, szItem)
	}

	_DisplayMenu(id, menu)
}

public tst_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowTradeMenu(id)
		}

		return _MenuExit(menu)
	}

	new data[3]
	new index
	new name[32]

	menu_item_getinfo(menu, item, _, data, charsmax(data), name, charsmax(name))

	index = str_to_num(data)

	switch (index)
	{
		case -10:
		{
			_ShowMainMenu(id)
		}
		default:
		{
			if (g_iTradeRequest[index])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TARGET_TRADE_ACTIVE", name)
			}
			else
			{
				g_iTradeTarget[id] = index
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_YOUR_TARGET", name)
			}
			_ShowTradeMenu(id)
		}
	}

	return _MenuExit(menu)
}

public _SelectTradeItem(id)
{
	new szTemp[64]

	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_ITEM_MENU")
	new menu = menu_create(szTemp, "tsi_menu_handler")

	new szItem[6]
	new total

	if (0 < g_iUserCases[id])
	{
		formatex(szTemp, charsmax(szTemp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_CASE", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserCases[id])
		num_to_str(CASE, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
		total++
	}

	if (0 < g_iUserKeys[id])
	{
		formatex(szTemp, charsmax(szTemp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_KEY", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserKeys[id])
		num_to_str(KEY, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
		total++
	}

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_NORMAL_SKIN_MENU")
	num_to_str(0, szItem, charsmax(szItem))
	menu_additem(menu, szTemp, szItem)

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_STATTRACK_SKIN_MENU")
	num_to_str(1, szItem, charsmax(szItem))
	menu_additem(menu, szTemp, szItem)

	if (!total)
	{
		formatex(szTemp, charsmax(szTemp), "\r%L", LANG_SERVER, "CSGOR_NO_ITEMS")
		num_to_str(-10, szItem, charsmax(szItem))
		menu_additem(menu, szTemp, szItem)
	}

	_DisplayMenu(id, menu)
}

public tsi_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowTradeMenu(id)
		}

		return _MenuExit(menu)
	}

	new data[6]
	new index

	menu_item_getinfo(menu, item, .info = data, .infolen = sizeof(data))

	index = str_to_num(data)

	switch (index)
	{
		case -10:
		{
			_ShowTradeMenu(id)
		}
		case 0:
		{
			_ShowNormalSkinsMenu(id, iTrade)
		}
		case 1:
		{
			_ShowStattrackSkinsMenu(id, iTrade)
		}
		case KEY, CASE:
		{
			if (item == g_iUserSellItem[id][iItemID] && g_bUserSell[id])
			{
				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_INVALID_ITEM")
				_SelectTradeItem(id)
			}
			else
			{
				g_iTradeItem[id][iItemID] = item
				g_iTradeItem[id][iIsStattrack] = 0

				new szItem[MAX_SKIN_NAME]

				_GetItemName(item, szItem, charsmax(index))

				CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_ITEM", szItem)
				_ShowTradeMenu(id)
			}
		}
	}

	return _MenuExit(menu)
}

public clcmd_say_savepass(id)
{
	if(g_bLogged[id])
	{
		new szTemp[64]

		formatex(szTemp, charsmax(szTemp), "setinfo ^"%s^" ^"%s^"", g_iCvars[szUserInfoField], g_szUserPassword[id])
		client_cmd(id, szTemp)

		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_PASSWORD_SAVED", szTemp)
	}
	else 
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_MUST_LOGIN")
	}

	return PLUGIN_HANDLED
}

public clcmd_say_accept(id)
{
	new sender = g_iTradeRequest[id]

	if (sender < 1 || sender > 32)
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_DONT_HAVE_REQ")
		return
	}

	if (!g_bLogged[sender] || !is_user_connected(sender))
	{
		_ResetTradeData(id)
		_ResetTradeData(sender)

		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_INVALID_SENDER")

		return
	}

	if (!g_bTradeActive[sender] && id == g_iTradeTarget[sender])
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_IS_CANCELED")

		_ResetTradeData(id)
		_ResetTradeData(sender)

		return
	}

	if (g_bTradeAccept[id])
	{
		new sItem = g_iTradeItem[sender][iItemID]
		new tItem = g_iTradeItem[id][iItemID]

		if (!_UserHasItem(id, tItem, g_iTradeItem[id][iIsStattrack]) || !_UserHasItem(sender, sItem, g_iTradeItem[sender][iIsStattrack]))
		{
			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_FAIL2")
			CC_SendMessage(sender, "^1%L", LANG_SERVER, "CSGOR_TRADE_FAIL2")

			_ResetTradeData(id)
			_ResetTradeData(sender)

			return
		}

		static ePlayerSkins[PlayerSkins]
		new iFound = -1

		new sItemsz[MAX_SKIN_NAME]
		new tItemsz[MAX_SKIN_NAME]

		_GetItemName(tItem, tItemsz, charsmax(tItemsz))
		_GetItemName(sItem, sItemsz, charsmax(sItemsz))

		switch (sItem)
		{
			case KEY:
			{
				g_iUserKeys[id]++
				g_iUserKeys[sender]--
			}
			case CASE:
			{
				g_iUserCases[id]++
				g_iUserCases[sender]--
			}
			default:
			{
				ePlayerSkins = GetPlayerSkin(id, sItem, iFound, g_iTradeItem[sender][iIsStattrack])

				if(iFound < 0)
				{
					iFound = SetPlayerSkin(id, sItem, ePlayerSkins, g_iTradeItem[sender][iIsStattrack])
				}

				ePlayerSkins[iPieces] += 1

				ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)
				UpdatePlayerSkin(id, sItemsz, ePlayerSkins)

				ePlayerSkins = GetPlayerSkin(sender, sItem, iFound, g_iTradeItem[sender][iIsStattrack])

				ePlayerSkins[iPieces] -= 1
				if(0 <= ePlayerSkins[iPieces])
				{
					ArrayDeleteItem(g_aPlayerSkins[sender], iFound)

					UpdatePlayerSkin(sender, sItemsz, ePlayerSkins, true)
				}
				else
				{
					ArraySetArray(g_aPlayerSkins[sender], iFound, ePlayerSkins)
					UpdatePlayerSkin(sender, sItemsz, ePlayerSkins)
				}
			}
		}

		switch (tItem)
		{
			case KEY:
			{
				g_iUserKeys[id]--
				g_iUserKeys[sender]++
			}
			case CASE:
			{
				g_iUserCases[id]--
				g_iUserCases[sender]++
			}
			default:
			{
				ePlayerSkins = GetPlayerSkin(sender, tItem, iFound, g_iTradeItem[id][iIsStattrack])

				if(iFound < 0)
				{
					iFound = SetPlayerSkin(sender, tItem, ePlayerSkins, g_iTradeItem[id][iIsStattrack])
				}

				ePlayerSkins[iPieces] += 1

				ArraySetArray(g_aPlayerSkins[sender], iFound, ePlayerSkins)
				UpdatePlayerSkin(sender, tItemsz, ePlayerSkins)

				ePlayerSkins = GetPlayerSkin(id, tItem, iFound, g_iTradeItem[id][iIsStattrack])

				ePlayerSkins[iPieces] -= 1
				if(0 <= ePlayerSkins[iPieces])
				{
					ArrayDeleteItem(g_aPlayerSkins[id], iFound)

					UpdatePlayerSkin(id, tItemsz, ePlayerSkins, true)
				}
				else
				{
					ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)
					UpdatePlayerSkin(id, tItemsz, ePlayerSkins)
				}
			}
		}

		if(g_iTradeItem[sender][iIsStattrack])
		{
			FormatStattrack(sItemsz, charsmax(sItemsz))
		}

		if(g_iTradeItem[id][iIsStattrack])
		{
			FormatStattrack(tItemsz, charsmax(tItemsz))
		}

		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_SUCCESS", tItemsz, sItemsz)
		CC_SendMessage(sender, "^1%L", LANG_SERVER, "CSGOR_TRADE_SUCCESS", sItemsz, tItemsz)

		_ResetTradeData(id)
		_ResetTradeData(sender)
	}
	else
	{
		if (!g_bTradeSecond[id])
		{
			g_iTradeTarget[id] = sender
			g_iTradeItem[id][iItemID] = -1
			g_iTradeItem[id][iIsStattrack] = -1
			g_bTradeSecond[id] = true

			_ShowTradeMenu(id)

			CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_SELECT_ITEM")
		}
	}
}

public clcmd_say_deny(id)
{
	new sender = g_iTradeRequest[id]

	if (1 < sender || sender > 32)
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_DONT_HAVE_REQ")
	}

	if (!g_bLogged[sender] || !is_user_connected(sender))
	{
		_ResetTradeData(id)
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_INVALID_SENDER")
	}

	if (!g_bTradeActive[sender] && id == g_iTradeTarget[sender])
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_TRADE_IS_CANCELED")
		_ResetTradeData(id)
	}

	_ResetTradeData(id)
	_ResetTradeData(sender)

	CC_SendMessage(sender, "^1%L", LANG_SERVER, "CSGOR_TARGET_REFUSE_TRADE", g_szName[id])
	CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_YOU_REFUSE_TRADE", g_szName[sender])
}

public ev_DeathMsg()
{
	new killer = read_data(1)
	new victim = read_data(2)
	new head = read_data(3)
	new szWeapon[24]

	read_data(4, szWeapon, charsmax(szWeapon))

	if(!IsPlayer(victim, g_iMaxPlayers))
	{
		_Send_DeathMsg(killer, victim, head, szWeapon)

		return PLUGIN_CONTINUE
	}

	ClearPlayerBit(g_bitIsAlive, victim)

	if(!IsPlayer(killer, g_iMaxPlayers))
	{
		_Send_DeathMsg(killer, victim, head, szWeapon)

		return PLUGIN_CONTINUE
	}

	new assist = g_iMostDamage[victim]

	if(is_user_connected(assist) && assist != killer && killer != victim)
	{
		_GiveBonus(assist, 0)
		ExecuteForward(g_iForwards[ user_assist ], g_iForwardResult, assist, killer, victim, head)
		
		new kName[32]
		new szName1[32]
		new szName2[32]
		new iName1Len = strlen(g_szName[killer])
		new iName2Len = strlen(g_szName[assist])
		
		if (iName1Len < 14)
		{
			formatex(szName1, iName1Len, "%s", g_szName[killer])
			formatex(szName2, 28 - iName1Len, "%s", g_szName[assist])
		}
		else
		{
			if (iName2Len < 14)
			{
				formatex(szName1, 28 - iName2Len, "%s", g_szName[killer])
				formatex(szName2, iName2Len, "%s", g_szName[assist])
			}

			formatex(szName1, 13, "%s", g_szName[killer])
			formatex(szName2, 13, "%s", g_szName[assist])
		}
		formatex(kName, charsmax(kName), "%s + %s", szName1, szName2)

		g_eEnumBooleans[killer][IsChangeNotAllowed] = true

		set_msg_block(g_Msg_SayText, BLOCK_ONCE)
		set_user_info(killer, "name", kName)

		new szWeaponLong[24]
		
		if (equali(szWeapon, "grenade"))
		{
			formatex(szWeaponLong, charsmax(szWeaponLong), "%s", "weapon_hegrenade")
		}
		else
		{
			formatex(szWeaponLong, charsmax(szWeaponLong), "weapon_%s", szWeapon)
		}

		new args[4]
		args[0] = killer
		args[1] = victim
		args[2] = head
		args[3] = get_weaponid(szWeaponLong)

		set_task(0.1, "task_Send_DeathMsg", TASK_SENDDEATH, args, sizeof(args))
	}
	else
	{
		_Send_DeathMsg(killer, victim, head, szWeapon)
	}

	g_iDigit[killer]++

	_SetKillsIcon(killer, 0)

	g_iRoundKills[killer]++
	
	if (!g_bLogged[killer])
	{
		CC_SendMessage(killer, "^1%L", LANG_SERVER, "CSGOR_REGISTER")
		return PLUGIN_HANDLED
	}
	
	if (killer == victim)
		return PLUGIN_CONTINUE
	
	g_iUserKills[killer]++

	new iWID = get_user_weapon(killer)

	if(g_iUserSelectedSkin[killer][bIsStattrack][iWID])
	{
		new ePlayerSkins[PlayerSkins]
		ArrayGetArray(g_aPlayerSkins[killer], g_iUserSelectedSkin[killer][iUserStattrack][iWID], ePlayerSkins)

		ePlayerSkins[iKills]++

		ArrayPushArray(g_aPlayerSkins[killer], ePlayerSkins)
	}

	new bool:levelup

	if (g_iRanksNum - 1 > g_iUserRank[killer])
	{
		if (ArrayGetCell(g_aRankKills, g_iUserRank[killer] +1) <= g_iUserKills[killer])
		{
			g_iUserRank[killer]++
			levelup = true

			new szRank[MAX_RANK_NAME]
			ArrayGetString(g_aRankName, g_iUserRank[killer], szRank, charsmax(szRank))

			CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_LEVELUP_ALL", g_szName[killer], szRank)

			ExecuteForward(g_iForwards[ user_level_up ], g_iForwardResult, killer, szRank, g_iUserRank[killer])
		}
	}

	new rpoints
	new rchance
	if (head)
	{
		rpoints = random_num(g_iCvars[iHMinPoints], g_iCvars[iHMaxPoints])
		rchance = random_num(g_iCvars[iHMinChance], g_iCvars[iHMaxChance])
	}
	else
	{
		rpoints = random_num(g_iCvars[iKMinPoints], g_iCvars[iKMaxPoints])
		rchance = random_num(g_iCvars[iKMinChance], g_iCvars[iKMaxChance])
	}

	g_iUserPoints[killer] += rpoints

	set_hudmessage(255, 255, 255, -1.0, 0.2, 0, 6.0, 2.0)
	show_hudmessage(killer, "%L", LANG_SERVER, "CSGOR_REWARD_POINTS", rpoints)

	if (rchance > g_iCvars[iDropChance])
	{
		new r

		if (0 < g_iCvars[iDropType])
		{
			r = 1
		}
		else
		{
			r = random_num(1, 2)
		}
		switch (r)
		{
			case 1:
			{
				g_iUserCases[killer]++

				if (0 < g_iCvars[iDropType])
				{
					CC_SendMessage(killer, "^1%L", LANG_SERVER, "CSGOR_REWARD_CASE2")
				}
				else
				{
					CC_SendMessage(killer, "^1%L", LANG_SERVER, "CSGOR_REWARD_CASE")
				}
			}
			case 2:
			{
				g_iUserKeys[killer]++

				CC_SendMessage(killer, " %L", LANG_SERVER, "CSGOR_REWARD_KEY")
			}
		}

		ExecuteForward(g_iForwards[user_drop], g_iForwardResult, killer)
	}

	if (levelup)
	{
		new szBonus[16]
		get_cvar_string("csgor_rangup_bonus", szBonus, charsmax(szBonus))

		new keys
		new cases
		new points

		for (new i; szBonus[i] != '|'; i++)
		{
			switch (szBonus[i])
			{
				case 'c':
				{
					cases++
				}
				case 'k':
				{
					keys++
				}
			}
		}

		new temp[8]
		strtok(szBonus, temp, charsmax(temp), szBonus, charsmax(szBonus), '|')

		if (szBonus[0])
		{
			points = str_to_num(szBonus)
		}
		if (0 < keys)
		{
			g_iUserKeys[killer] += keys
		}
		if (0 < cases)
		{
			g_iUserCases[killer] += cases
		}
		if (0 < points)
		{
			g_iUserPoints[killer] += points
		}

		CC_SendMessage(killer, "^1%L", LANG_SERVER, "CSGOR_RANKUP_BONUS", keys, cases, points)
	}

	return PLUGIN_HANDLED
}

public ev_Damage( victim )
{
	static attacker, damage

	if(victim && victim <= MAX_PLAYERS && is_user_connected(victim))
	{
		attacker = get_user_attacker(victim)
		
		if(attacker && attacker <= MAX_PLAYERS && is_user_connected(attacker))
		{
			damage = read_data(2)

			g_iDealDamage[attacker] += damage
			g_iDamage[victim][attacker] += damage
			
			new topDamager = g_iMostDamage[victim]
			if (g_iDamage[victim][attacker] > g_iDamage[victim][topDamager])
			{
				g_iMostDamage[victim] = attacker
			}
		}
	}
}

public task_Send_DeathMsg(arg[])
{
	new szWeapon[24]
	new weapon = arg[3]
	get_weaponname(weapon, szWeapon, charsmax(szWeapon))
	
	if (weapon == CSW_HEGRENADE)
	{
		replace_string(szWeapon, charsmax(szWeapon), "weapon_he", "")
	}
	else
	{
		replace_string(szWeapon, charsmax(szWeapon), "weapon_", "")
	}

	_Send_DeathMsg(arg[0], arg[1], arg[2], szWeapon)

	set_msg_block(g_Msg_SayText, BLOCK_ONCE)
	set_user_info(arg[0], "name", g_szName[arg[0]])

	set_task(0.1, "task_Reset_Name", arg[0] + TASK_RESET_NAME)
}

public concmd_givepoints(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED

	new arg1[32]
	new arg2[16]

	read_argv(1, arg1, charsmax(arg1))
	read_argv(2, arg2, charsmax(arg2))

	new target

	if (arg1[0] == '@')
	{
		_GiveToAll(id, arg1, arg2, 0)
		return PLUGIN_HANDLED
	}

	target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)

	if (!target)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1)
		return PLUGIN_HANDLED
	}

	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1)
		return PLUGIN_HANDLED
	}

	new amount = str_to_num(arg2)

	if (0 > amount)
	{
		g_iUserPoints[target] += amount

		if (0 > g_iUserPoints[target])
		{
			g_iUserPoints[target] = 0
		}

		console_print(id, "%s %L %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SUBSTRACT", arg1, amount, LANG_SERVER, "CSGOR_POINTS")

		CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_POINTS")
	}
	else
	{
		if (0 < amount)
		{
			g_iUserPoints[target] += amount
			console_print(id, "%s You gave %s %d points", g_iCvars[szChatPrefix], arg1, amount)
			CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_POINTS")
		}
	}

	_Save(target)

	return PLUGIN_HANDLED
}

public concmd_givecases(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED

	new arg1[32]
	new arg2[16]

	read_argv(1, arg1, charsmax(arg1))
	read_argv(2, arg2, charsmax(arg2))

	new target

	if (arg1[0] == '@')
	{
		_GiveToAll(id, arg1, arg2, 1)

		return PLUGIN_HANDLED
	}

	target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)

	if (!target)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1)

		return PLUGIN_HANDLED
	}

	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1)

		return PLUGIN_HANDLED
	}

	new amount = str_to_num(arg2)

	if (0 > amount)
	{
		g_iUserCases[target] -= amount

		if (0 > g_iUserCases[target])
		{
			g_iUserCases[target] = 0
		}

		console_print(id, "%s %L %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SUBSTRACT", arg1, amount, LANG_SERVER, "CSGOR_CASES")

		CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_CASES")
	}
	else
	{
		if (0 < amount)
		{
			g_iUserCases[target] += amount

			console_print(id, "%s %L %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_ADD", arg1, amount, LANG_SERVER, "CSGOR_CASES")

			CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_CASES")
		}
	}
	
	_Save(target)

	return PLUGIN_HANDLED
}

public concmd_givekeys(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3, false))
		return PLUGIN_HANDLED

	new arg1[32]
	new arg2[16]
	new target

	read_argv(1, arg1, charsmax(arg1))
	read_argv(2, arg2, charsmax(arg2))

	if (arg1[0] == '@')
	{
		_GiveToAll(id, arg1, arg2, 2)
		return PLUGIN_HANDLED
	}

	target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)

	if (!target)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1)
		return PLUGIN_HANDLED
	}

	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1)
		return PLUGIN_HANDLED
	}

	new amount = str_to_num(arg2)

	if (0 > amount)
	{
		g_iUserKeys[target] -= amount

		if (0 > g_iUserKeys[target])
		{
			g_iUserKeys[target] = 0
		}

		console_print(id, "%s %L %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SUBSTRACT", arg1, amount, LANG_SERVER, "CSGOR_KEYS")
		CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_KEYS")
	}
	else
	{
		if (0 < amount)
		{
			g_iUserKeys[target] += amount
			console_print(id, "%s %L %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_ADD", arg1, amount, LANG_SERVER, "CSGOR_KEYS")
			CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_KEYS")
		}
	}
	_Save(target)

	return PLUGIN_HANDLED
}

public concmd_givedusts(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3, false))
		return PLUGIN_HANDLED

	new arg1[32]
	new arg2[16]

	read_argv(1, arg1, charsmax(arg1))
	read_argv(2, arg2, charsmax(arg2))
	new target

	if (arg1[0] == '@')
	{
		_GiveToAll(id, arg1, arg2, 3)
		return PLUGIN_HANDLED
	}

	target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)

	if (!target)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1)
		return PLUGIN_HANDLED
	}

	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1)
		return PLUGIN_HANDLED;  
	}

	new amount = str_to_num(arg2)

	if (0 > amount)
	{
		g_iUserDusts[target] -= amount
		if (0 > g_iUserDusts[target])
		{
			g_iUserDusts[target] = 0
		}
		console_print(id, "%s %L %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SUBSTRACT", arg1, amount, LANG_SERVER, "CSGOR_DUSTS")
		CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_DUSTS")
	}
	else
	{
		if (0 < amount)
		{
			g_iUserDusts[target] += amount
			console_print(id, "%s %L %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_ADD", arg1, amount, LANG_SERVER, "CSGOR_DUSTS")
			CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_DUSTS")
		}
	}

	_Save(target)

	return PLUGIN_HANDLED
}

public concmd_setrank(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3, false))
		return PLUGIN_HANDLED

	new arg1[32]
	new arg2[8]

	read_argv(1, arg1, charsmax(arg1))
	read_argv(2, arg2, charsmax(arg2))
	new target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)

	if (!target)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1)
		return PLUGIN_HANDLED
	}

	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1)
		return PLUGIN_HANDLED
	}

	new rank = str_to_num(arg2)

	if (rank < 0 || rank >= g_iRanksNum)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_INVALID_RANKID", g_iRanksNum - 1)
		return PLUGIN_HANDLED
	}

	g_iUserRank[target] = rank

	if (rank)
	{
		g_iUserKills[target] = ArrayGetCell(g_aRankKills, rank - 1)
	}
	else
	{
		g_iUserKills[target] = 0
	}

	_Save(target)

	new szRank[MAX_RANK_NAME]
	ArrayGetString(g_aRankName, g_iUserRank[target], szRank, charsmax(szRank))

	console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SET_RANK", arg1, szRank)

	CC_SendMessage(target, "^1%L", LANG_SERVER, "CSGOR_ADMIN_SET_RANK", g_szName[id], szRank)

	return PLUGIN_HANDLED
}

public concmd_giveskins(id, level, cid)
{
	if (!cmd_access(id, level, cid, 4, false))
		return PLUGIN_HANDLED

	new arg1[32]
	new arg2[8]
	new arg3[16]

	read_argv(1, arg1, charsmax(arg1))
	read_argv(2, arg2, charsmax(arg2))
	read_argv(3, arg3, charsmax(arg3))

	new target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)

	if (!target)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1)
		return PLUGIN_HANDLED
	}

	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1)
		return PLUGIN_HANDLED
	}

	new skin = str_to_num(arg2)

	if (skin < 0 || skin >= ArraySize(g_aSkinData))
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_INVALID_SKINID", ArraySize(g_aSkinData))
		return PLUGIN_HANDLED
	}

	new amount = str_to_num(arg3)

	static eSkinData[SkinData], ePlayerSkins[PlayerSkins]
	new iFound = -1
	ArrayGetArray(g_aSkinData, skin, eSkinData)

	ePlayerSkins = GetPlayerSkin(id, skin, iFound)

	if(iFound < 0)
	{
		iFound = SetPlayerSkin(id, skin, ePlayerSkins)
	}

	if (0 > amount)
	{
		ePlayerSkins[iPieces] -= amount

		console_print(id, "%s %L %s", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_SUBSTRACT", arg1, amount, eSkinData[szSkinName])
		CC_SendMessage(target, "^1%L ^3%s", LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, eSkinData[szSkinName])

		if(!ePlayerSkins[iPieces])
		{
			ArrayDeleteItem(g_aPlayerSkins[target], iFound)
			UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins, true)
		}
	}
	else
	{
		if (0 < amount)
		{
			ePlayerSkins[iPieces] += amount
			console_print(id, "%s %L x %s", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_ADD", arg1, amount, eSkinData[szSkinName])
			CC_SendMessage(target, "^1%L ^3%s", LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, eSkinData[szSkinName])

			ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)
			UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins)
		}
	}

	return PLUGIN_HANDLED
}

public concmd_give_all_skins(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3, false))
		return PLUGIN_HANDLED
	
	new arg1[32], arg2[3]
	read_argv(1, arg1, charsmax(arg1))
	read_argv(2, arg2, charsmax(arg2))

	new target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)

	if(!target) 
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1)
		return PLUGIN_HANDLED
	}

	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1)
		return PLUGIN_HANDLED
	}

	new iShouldSTT = str_to_num(arg2)

	static ePlayerSkins[PlayerSkins], eSkinData[SkinData]
	new iFound = -1

	for (new i; i < ArraySize(g_aSkinData); i++)
	{
		ArrayGetArray(g_aSkinData, i, eSkinData)
		ePlayerSkins = GetPlayerSkin(target, i, iFound, iShouldSTT)

		if(iFound < 0)
		{
			iFound = SetPlayerSkin(target, i, ePlayerSkins, iShouldSTT)
		}

		ePlayerSkins[iPieces] += 1

		ArraySetArray(g_aPlayerSkins[target], iFound, ePlayerSkins)

		UpdatePlayerSkin(target, eSkinData[szSkinName], ePlayerSkins)
	}

	console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_GAVE_ALL_SKINS_TO", g_szName[target])
	CC_SendMessage(target, "^1%L", LANG_SERVER, "CSGOR_ADMIN_ALL_SKINS", g_szName[id])

	return PLUGIN_HANDLED
}

public native_get_user_points(iPluginID, iParamNum)
{
	enum { arg_index = 1 }
	if (iParamNum != 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID)")
		return -1
	}
	new id = get_param(arg_index)

	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	return g_iUserPoints[id]
}

public native_set_user_points(iPluginID, iParamNum)
{
	enum { arg_index = 1, arg_amount }
	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)")
		return -1
	}

	new id = get_param(arg_index)

	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	new amount = get_param(arg_amount)

	if (0 > amount)
	{
		new szName[32]
		get_user_name(id, szName, charsmax(szName))
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d) Player (%s)", amount, szName)
		return -1
	}

	if(!g_bLogged[id])
	{
		return -1
	}

	g_iUserPoints[id] = amount
	_Save(id)

	return PLUGIN_HANDLED
}

public native_get_user_cases(iPluginID, iParamNum)
{
	enum { arg_index = 1 }

	if (iParamNum != 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID)")
		return -1
	}

	new id = get_param(arg_index)

	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	return g_iUserCases[id]
}

public native_set_user_cases(iPluginID, iParamNum)
{
	enum { arg_index = 1, arg_amount }

	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)")
		return -1
	}
	new id = get_param(arg_index)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	new amount = get_param(arg_amount)
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", amount)
		return -1
	}
	if(!g_bLogged[id])
	{
		return -1
	}
	g_iUserCases[id] = amount
	_Save(id)

	return PLUGIN_HANDLED
}

public native_get_user_keys(iPluginID, iParamNum)
{
	if (iParamNum != 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID)")
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	return g_iUserKeys[id]
}

public native_set_user_keys(iPluginID, iParamNum)
{
	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)")
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	new amount = get_param(2)
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", amount)
		return -1
	}
	if(!g_bLogged[id])
	{
		return -1
	}
	g_iUserKeys[id] = amount
	_Save(id)
	return PLUGIN_HANDLED
}

public native_get_user_dusts(iPluginID, iParamNum)
{
	if (iParamNum != 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID)")
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	return g_iUserDusts[id]
}

public native_set_user_dusts(iPluginID, iParamNum)
{
	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)")
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	new amount = get_param(2)
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", amount)
		return -1
	}
	if(!g_bLogged[id])
	{
		return -1
	}
	g_iUserDusts[id] = amount
	_Save(id)

	return PLUGIN_HANDLED
}

public native_get_user_rank(iPluginID, iParamNum)
{
	if (iParamNum != 3)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Output, Len)")
		return -1
	}
	
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	new szRank[MAX_RANK_NAME]
	new rank = -2

	if(g_bLogged[id])
	{
		rank = g_iUserRank[id]
		ArrayGetString(g_aRankName, rank, szRank, charsmax(szRank))
	}
	else
	{
		formatex(szRank, charsmax(szRank), "%L", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT")
	}

	set_string(2, szRank, get_param(3))

	return rank
}

public native_set_user_rank(iPluginID, iParamNum)
{
	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, RankID)")
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	new rank = get_param(2)
	if (rank < 0 || rank >= g_iRanksNum)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid RankID (%d)", rank)
		return -1
	}
	if(!g_bLogged[id])
	{
		return -1
	}
	g_iUserRank[id] = rank
	g_iUserKills[id] = ArrayGetCell(g_aRankKills, rank - 1)
	_Save(id)

	return PLUGIN_HANDLED
}

public native_csgor_get_user_skinsnum(iPluginID, iParamNum)
{
	enum { arg_index = 1, arg_weaponid, arg_stattrack }

	new id = get_param(arg_index)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	new wid = get_param(arg_weaponid)

	if(!(CSW_P228 <= wid <= CSW_P90))
	{
		log_error(AMX_ERR_NATIVE, "%s Weapon ID is not valid (%d)", wid)
		return -1
	}

	return GetUserSkinsNum(id, wid, bool:get_param(arg_stattrack))
}

public native_get_user_skins(iPluginID, iParamNum)
{
	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, SkinID)")
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	new skin = get_param(2)
	if (skin < 0 || skin > ArraySize(g_aSkinData))
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d)", skin)
		return -1
	}

	new ePlayerSkins[PlayerSkins], iFound = -1
	ePlayerSkins = GetPlayerSkin(id, skin, iFound, 0)

	if(iFound < 0)
		return -1

	return ePlayerSkins[iPieces]
}

public native_set_user_skins(iPluginID, iParamNum)
{
	if (iParamNum != 3)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, SkinID, Amount)", PLUGIN)
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", PLUGIN, id)
		return -1
	}

	new skin = get_param(2)
	if (skin < 0 || skin > ArraySize(g_aSkinData))
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d)", PLUGIN, skin)
		return -1
	}
	new amount = get_param(3)
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", PLUGIN, amount)
		return -1
	}
	if(!g_bLogged[id])
	{
		return -1
	}
	new ePlayerSkins[PlayerSkins], iFound = -1

	ePlayerSkins = GetPlayerSkin(id, skin, iFound, 0)

	if(iFound < 0)
	{
		iFound = SetPlayerSkin(id, skin, ePlayerSkins, 0)
	}

	ePlayerSkins[iPieces] = amount

	if(ePlayerSkins[iPieces] <= 0)
	{
		ArrayDeleteItem(g_aPlayerSkins[id], iFound)
	}
	else
	{
		ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)
	}

	new sSkin[MAX_SKIN_NAME]

	_GetItemName(skin, sSkin, charsmax(sSkin))

	UpdatePlayerSkin(id, sSkin, ePlayerSkins, ePlayerSkins[iPieces] <= 0 ? true : false)

	return PLUGIN_HANDLED
}

public native_get_skins_num(iPluginID, iParamNum)
{
	return ArraySize(g_aSkinData)
}

public native_get_skin_data(iPluginID, iParamNum)
{
	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (SkinID, Output[])", PLUGIN)
		return -1
	}

	new skin = get_param(1)
	if (0 > skin > ArraySize(g_aSkinData))
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d).", PLUGIN, skin)
		return -1
	}

	new eSkinData[SkinData]
	ArrayGetArray(g_aSkinData, skin, eSkinData)

	set_array(2, eSkinData, sizeof(eSkinData))

	return PLUGIN_HANDLED
}

public native_is_user_logged(iPluginID, iParamNum)
{
	if (iParamNum != 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID)")
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", PLUGIN, id)
		return -1
	}
	return g_bLogged[id]
}

public native_set_user_all_skins(iPluginID, iParamNum)
{
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", PLUGIN, id)
		return -1
	}
	if(!g_bLogged[id])
	{
		return -1
	}

	new stt = get_param(2)

	static ePlayerSkins[PlayerSkins], eSkinData[SkinData]
	new iFound = -1

	for (new i; i < ArraySize(g_aSkinData); i++)
	{
		ArrayGetArray(g_aSkinData, i, eSkinData)

		ePlayerSkins = GetPlayerSkin(id, i, iFound, stt)

		if(iFound)
		{
			iFound = SetPlayerSkin(id, i, ePlayerSkins, stt)
		}

		ePlayerSkins[iPieces] += 1

		ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)

		UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins)
	}

	return PLUGIN_HANDLED
}

public native_is_half_round(iPluginID, iParamNum)
{
	return IsHalf()
}

public native_is_last_round(iPluginID, iParamNum)
{
	return IsLastRound()
}

public native_is_good_item(iPluginID, iParamNum)
{
	return _IsGoodItem(get_param(1))
}

public native_is_item_skin(iPluginID, iParamNum)
{
	return _IsItemSkin(get_param(1))
}

public native_is_user_registered(iPluginID, iParam)
{
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	return IsRegistered(id)
}

public native_is_warmup(iPluginID, iParam)
{
	return g_bWarmUp
}

public native_get_skin_index(iPluginID, iParam)
{
	new szTemp[48], eSkinData[SkinData]
	get_string(1, szTemp, charsmax(szTemp))

	new iReturn = -1, iIndex = -1

	for(new i; i < ArraySize(g_aSkinData); i++)
	{
		ArrayGetArray(g_aSkinData, i, eSkinData)
		iIndex = containi(eSkinData[szSkinName], szTemp)

		if(iIndex != -1)
		{
			iReturn = i
			break
		}
	}

	if(iReturn == -1)
	{
		log_error(AMX_ERR_NATIVE, "[%s] Skin id can't be found. Skin pattern: ^"%s^"", szTemp)
	}
	return iReturn
}

public native_ranks_num(iPluginID, iParam)
{
	return g_iRanksNum
}

public native_is_skin_stattrack(iPluginID, iParam)
{
	new id = get_param(1)

	if(!IsPlayer(id, g_iMaxPlayers))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return false
	}

	new iWID = get_user_weapon(id)

	return g_iUserSelectedSkin[id][bIsStattrack][iWID]
}

public native_csgor_get_user_skin_data(iPluginID, iParamNum)
{
	enum { arg_index = 1, arg_skinid, arg_stattrack, arg_skindata }

	new id = get_param(arg_index)

	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	new skin = get_param(arg_skinid)

	if (skin < 0 || skin > ArraySize(g_aSkinData))
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d)", skin)
		return -1
	}
	new iFound = -1, ePlayerSkins[PlayerSkins]

	ePlayerSkins = GetPlayerSkin(id, skin, iFound, get_param(arg_stattrack))

	set_array(arg_skindata, ePlayerSkins, sizeof(ePlayerSkins))

	return iFound
}

public native_get_user_statt_skins(iPluginID, iParamNum)
{
	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, SkinID)")
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	new skin = get_param(2)
	if (skin < 0 || skin > ArraySize(g_aSkinData))
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d)", skin)
		return -1
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", id)
		return -1
	}

	static ePlayerSkins[PlayerSkins]
	new iFound = -1

	ePlayerSkins = GetPlayerSkin(id, skin, iFound, 1)

	if(iFound < 0 || !ePlayerSkins[isStattrack])
	{
		log_error(AMX_ERR_NATIVE, "%s Player (%d) skinid (%d) is not StatTrack.", PLUGIN, id, skin)
		return -1
	}

	return ePlayerSkins[iPieces]
}

public native_set_user_statt_skins(iPluginID, iParamNum)
{
	if (iParamNum != 3)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, SkinID, Amount)", PLUGIN)
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", PLUGIN, id)
		return -1
	}

	new skin = get_param(2)
	if (skin < 0 || skin > ArraySize(g_aSkinData))
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d)", PLUGIN, skin)
		return -1
	}

	new amount = get_param(3)
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", PLUGIN, amount)
		return -1
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", PLUGIN, id)
		return -1
	}

	static ePlayerSkins[PlayerSkins], eSkinData[SkinData]
	new iFound = -1

	ePlayerSkins = GetPlayerSkin(id, skin, iFound, 1)

	if(iFound < 0)
	{
		iFound = SetPlayerSkin(id, skin, ePlayerSkins, 1)
	}

	ePlayerSkins[iPieces] = amount

	ArrayGetArray(g_aSkinData, skin, eSkinData)

	if(ePlayerSkins[iPieces] <= 0)
	{
		ArrayDeleteItem(g_aPlayerSkins[id], iFound)
	}
	else
	{
		ArraySetArray(g_aPlayerSkins[id], iFound, ePlayerSkins)
	}

	UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins, ePlayerSkins[iPieces] <= 0 ? true : false)

	return PLUGIN_HANDLED
}

public native_get_user_stattrack_kills(iPluginID, iParamNum)
{
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", id)
		return -1
	}

	new iSkin = get_param(2)

	static ePlayerSkins[PlayerSkins]
	new iFound = -1

	ePlayerSkins = GetPlayerSkin(id, iSkin, iFound, 1)

	if(iFound < 0)
	{
		log_error(AMX_ERR_BOUNDS, "Skin index (%d) not found for player (%d)", iSkin, id)
		return -1
	}

	return ePlayerSkins[iKills]
}

public native_set_random_stattrack(iPluginID, iParamNum)
{
	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)")
		return -1
	}
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", id)
		return -1
	}

	new amount = get_param(3)
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", amount)
		return -1
	}

	new iRand = random_num(0, ArraySize(g_aSkinData))

	static ePlayerSkins[PlayerSkins], eSkinData[SkinData]
	new iFound = -1

	ePlayerSkins = GetPlayerSkin(id, iRand, iFound, 1)

	if(iFound < 0 || !ePlayerSkins[isStattrack])
	{
		SetPlayerSkin(id, iRand, ePlayerSkins, 1)
	}

	ArrayGetArray(g_aSkinData, iRand, eSkinData)

	ePlayerSkins[iPieces] += amount
	UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins)

	return PLUGIN_HANDLED
}

public native_set_user_stattrack_kills(iPluginID, iParamNum)
{
	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)")
		return -1
	}

	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", id)
		return -1
	}

	new amount = get_param(3)
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", amount)
		return -1
	}

	new iSkin = get_param(2)

	static ePlayerSkins[PlayerSkins], eSkinData[SkinData]
	new iFound = -1

	ePlayerSkins = GetPlayerSkin(id, iSkin, iFound, 1)

	if(iFound < 0)
	{
		log_error(AMX_ERR_BOUNDS, "Skin index (%d) not found for player (%d)", iSkin, id)
		return -1
	}

	ePlayerSkins[iKills] = amount

	ArrayGetArray(g_aSkinData, iSkin, eSkinData)

	UpdatePlayerSkin(id, eSkinData[szSkinName], ePlayerSkins)

	return PLUGIN_HANDLED
}

public native_get_user_stattrack(iPluginID, iParamNum)
{
	if (iParamNum != 4)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, WeaponID, SkinName, iLen)")
		return -1
	}

	new id = get_param(1)
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", id)
		return -1
	}

	new iWID = get_param(2)

	if( iWID <= CSW_NONE || iWID > CSW_P90 )
	{
		log_error(AMX_ERR_NATIVE, "%s Weapon ID (%d) is not a valid one!", iWID)
		return -1
	}

	if(!g_iUserSelectedSkin[id][bIsStattrack][iWID])
	{
		set_string(3, "NONE", get_param(4))
		return -1
	}

	new eSkinData[SkinData]
	ArrayGetArray(g_aSkinData, g_iUserSelectedSkin[id][iUserStattrack][iWID], eSkinData)

	format(eSkinData[szSkinName], charsmax(eSkinData[szSkinName]), "StatTrack %s", eSkinData[szSkinName])

	set_string(3, eSkinData[szSkinName], get_param(4))
	return PLUGIN_HANDLED
}

public native_csgo_get_user_body(iPluginID, iParamNum)
{
	return g_iUserViewBody[get_param(1)][get_param(2)]
}

public native_csgo_get_config_location(iPluginID, iParamNum)
{
	set_string(1, g_szConfigFile, charsmax(g_szConfigFile))
}

public native_csgo_get_user_skin(iPLuginID, iParamNum)
{
	if (iParamNum != 4)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, iWeaponID, SkinName, iLen)")
		return -1
	}

	new id = get_param(1)

	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", id)
		return -1
	}

	new iWID = get_param(2)

	if( iWID <= CSW_NONE || iWID > CSW_P90 )
	{
		log_error(AMX_ERR_NATIVE, "%s Weapon ID (%d) is not a valid one!", iWID)
		return -1
	}

	if(g_iUserSelectedSkin[id][iUserSelected][iWID] == -1)
	{
		set_string(3, "NONE", get_param(4))
		return -1
	}

	new eSkinData[SkinData]
	ArrayGetArray(g_aSkinData, g_iUserSelectedSkin[id][iUserSelected][iWID], eSkinData)

	set_string(3, eSkinData[szSkinName], get_param(4))
	return PLUGIN_HANDLED
}

public native_csgo_get_database_data(iPluginID, iParamNum)
{
	if (iParamNum != 8)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (szHostname[], iHostLen, szUsername[], iUserLen, szPassword[], iPassLen, szDatabase[], iDbLen)")
		return -1
	}

	set_string(1, g_iCvars[szSqlHost], get_param(2))
	set_string(3, g_iCvars[szSqlUsername], get_param(4))
	set_string(5, g_iCvars[szSqlPassword], get_param(6))
	set_string(7, g_iCvars[szSqlDatabase], get_param(8))

	return 1
}

public native_csgor_get_database_connection(iPluginID, iParamNum)
{
	enum { arg_connection = 1, arg_tuple }

	set_param_byref(arg_connection, any:g_iSqlConnection)
	set_param_byref(arg_tuple, any:g_hSqlTuple)
}

public native_get_rank_name(iPluginID, iParamNum)
{
	if(iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (iRankNum, szBuffer[])")
		return -1
	}

	new iRank = get_param(1)
	new szRank[MAX_RANK_NAME]

	ArrayGetString(g_aRankName, iRank, szRank, charsmax(szRank))

	set_string(2, szRank, charsmax(szRank))

	return 1
}

public native_csgor_get_user_name(iPluginID, iParamNum)
{
	enum { arg_index = 1, arg_name, arg_namelen }

	if(iParamNum != arg_namelen)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (iRankNum, szBuffer[])")
		return -1
	}

	set_string(arg_name, g_szName[get_param(arg_index)], get_param(arg_namelen))

	return 1
}

public native_csgor_save_user_data(iPluginID, iParamNum)
{
	enum { arg_index = 1 }

	new id = get_param(arg_index)

	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", id)
		return -1
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged in (%d)", id)
		return -1
	}

	_Save(id)

	return 1
}

public native_csgor_user_has_item(iPluginID, iParamNum)
{
	enum { arg_index = 1, arg_item, arg_stattrack }

	new id = get_param(arg_index)
	new item = get_param(arg_item)
	new iStat = get_param(arg_stattrack) 

	return _UserHasItem(id, item, iStat)
}

public native_csgor_send_message(iPluginID, iParamNum)
{
	enum { arg_index = 1, arg_text, arg_args }

	new iPlayer = get_param(arg_index)
	new szBuffer[190]

	vdformat(szBuffer, charsmax(szBuffer), arg_text, arg_args)
	return CC_SendMessage(iPlayer, "%s", szBuffer)
}

public native_csgor_get_dyn_menu_num(iPluginID, iParamNum)
{
	return ArraySize(g_aSkinsMenu)
}

public native_csgor_get_dyn_menu_item(iPluginID, iParamNum)
{
	enum { arg_menuid = 1 , arg_itemname, arg_itemid }
	new weapons[EnumSkinsMenuInfo]

	new iMenuID = get_param(arg_menuid)

	if(0 > iMenuID || iMenuID > ArraySize(g_aSkinsMenu))
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid Menu Index (%d) %d", PLUGIN, iMenuID, ArraySize(g_aSkinsMenu))
		return -1
	}
	
	ArrayGetArray(g_aSkinsMenu, iMenuID, weapons)
	set_string(arg_itemname, weapons[ItemName], charsmax(weapons[ItemName]))
	set_string(arg_itemid, weapons[ItemId], charsmax(weapons[ItemId]))

	return 1
}

public concmd_finddata(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2, false))
		return PLUGIN_HANDLED

	new arg1[32]
	read_argv(1, arg1, charsmax(arg1))

	new bool:bFound

	new szRank[MAX_RANK_NAME]
	new userData[6]
	new password[32]

	new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_data` WHERE `Name` = ^"%s^";", arg1)
	
	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError))
		log_to_file("csgo_remake_errors.log", "SQL Error: %s", g_szSqlError)
		SQL_FreeHandle(iQuery)
	}

	if(SQL_NumResults(iQuery) > 0)
	{
		new szQuery[512]
		formatex(szQuery, charsmax(szQuery), "SELECT \
				`Password`,\
				`Points`,\
				`Scraps`,\
				`Keys`,\
				`Cases`,\
				`Kills`,\
				`Rank`\
				FROM `csgor_data` WHERE `Name` = ^"%s^";", g_szName[id])

		iQuery = SQL_PrepareQuery(g_iSqlConnection, szQuery)

		if(!SQL_Execute(iQuery))
		{
			SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError))
			log_to_file("csgo_remake_errors.log", "%s", g_szSqlError)
		}

		if(SQL_NumResults(iQuery) > 0)
		{
			SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Password"), password, charsmax(password))
			userData[0] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Points"))
			userData[1] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Scraps"))
			userData[2] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Keys"))
			userData[3] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Cases"))
			userData[4] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Kills"))
			userData[5] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Rank"))
		}

		bFound = true
	}

	if(bFound)
	{
		ArrayGetString(g_aRankName, userData[5], szRank, charsmax(szRank))
		console_print(id, "%s Name: %s Password: %s", g_iCvars[szChatPrefix], arg1, password)
		console_print(id, "%s Points: %i | Rank: %s", g_iCvars[szChatPrefix], userData[0], szRank)
		console_print(id, "%s Keys: %i | Cases: %i", g_iCvars[szChatPrefix], userData[2], userData[3])
		console_print(id, "%s Dusts: %i | Kills: %i", g_iCvars[szChatPrefix], userData[1], userData[4])
	}
	else
	{
		console_print(id, "%s The account was not found: %s", g_iCvars[szChatPrefix], arg1)
	}

	return PLUGIN_HANDLED
}

public concmd_resetdata(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3, false))
		return PLUGIN_HANDLED
	
	new arg1[32]
	new arg2[4]
	new arg3[17]
	read_argv(1, arg1, charsmax(arg1))
	read_argv(2, arg2, charsmax(arg2))

	new type = str_to_num(arg2)
	new szQuery[200]

	new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_data` WHERE `Name` = ^"%s^"", arg1)
	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError))
		log_to_file("csgo_remake_errors.log", "SQL Error: %s", g_szSqlError)
	}

	if(!SQL_NumResults(iQuery))
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], id, "CSOGR_ACCOUNT_NOT_FOUND", arg1)
		return PLUGIN_HANDLED
	}

	switch(type)
	{
		case 0:
		{
			formatex(szQuery, charsmax(szQuery), "DELETE FROM `csgor_skins` WHERE `Name` = ^"%s^";", arg1)
		}
		case 1:
		{
			formatex(szQuery, charsmax(szQuery), "SET SQL_SAFE_UPDATES = 0; \
				DELETE FROM `csgor_data` WHERE `Name` = ^"%s^"; \
				DELETE FROM `csgor_skins` WHERE `Name` = ^"%s^"; \
				SET SQL_SAFE_UPDATES = 1;", arg1, arg1)
		}
		case 2:
		{
			read_argv(3, arg3, charsmax(arg3))

			if(strlen(arg3) < 4)
			{
				console_print(id, "%L", id, "CSGOR_INVALID_ARGUMENT", 3, arg3)
				return PLUGIN_HANDLED
			}

			formatex(szQuery, charsmax(szQuery), "UPDATE `csgor_data` SET `%s`= 0 WHERE `Name` = ^"%s^";", arg3, arg1)
		}
	}

	new index = get_user_index(arg1)
	if(index)
		g_bLogged[index] = false

	new szData[MAX_NAME_LENGTH + 5 + 6 + 18]
	formatex(szData, charsmax(szData), "%s;%s#%s=%d", arg1, arg2, arg3, id)

	SQL_ThreadQuery(g_hSqlTuple, "QueryResetData", szQuery, szData, charsmax(szData))

	return PLUGIN_HANDLED
}

public QueryResetData(iFailState, Handle:iQuery, Error[], Errcode, szData[], iSize, Float:flQueueTime)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: 
		{
			log_to_file("csgo_remake_errors.log", "[SQL Error] Connection failed (%i): %s", Errcode, Error)
		}
		case TQUERY_QUERY_FAILED:
		{
			log_to_file("csgo_remake_errors.log", "[SQL Error] Query failed (%i): %s", Errcode, Error)
		}
	}

	new arg1[MAX_NAME_LENGTH], arg2[4], arg3[17], index[3], id

	strtok(szData, arg1, charsmax(arg1), szData, iSize, ';')

	strtok(szData, arg2, charsmax(arg2), szData, iSize, '#')

	strtok(szData, arg3, charsmax(arg3), szData, iSize, '=')

	strtok(szData, index, charsmax(index), szData, iSize)

	id = str_to_num(index)

	if(iFailState)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_ERROR_QUERYING")
		return
	}

	switch(arg2[0])
	{
		case '0':
		{
			console_print(id, "%s %L", g_iCvars[szChatPrefix], id, "CSGOR_ACCOUNT_RESET", arg1)
		}
		case '1':
		{
			console_print(id, "%s %L", g_iCvars[szChatPrefix], id, "CSGOR_ACCOUNT_REMOVED", arg1)
		}
		case '2':
		{
			console_print(id, "%s %L", g_iCvars[szChatPrefix], id, "CSGOR_ACCOUNT_RESET_ITEM", arg1, arg3)
		}
	}

	new pid = get_user_index(arg1)
	if(pid)
		_Load(pid)
}

public concmd_changepass(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3, false))
		return PLUGIN_HANDLED

	new arg1[MAX_NAME_LENGTH]
	new arg2[32]
	read_argv(1, arg1, charsmax(arg1))
	read_argv(2, arg2, charsmax(arg2))

	if (strlen(arg2) < 6)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_PASSWORD_SHORT", arg2)
		return PLUGIN_HANDLED
	}

	new szQuery[95]
	formatex(szQuery, charsmax(szQuery), "SELECT `Password` FROM `csgor_data` WHERE `Name` = ^"%s^";", arg1)

	new szData[35 + MAX_NAME_LENGTH]
	formatex(szData, charsmax(szData), "%d;%s=%s", id, arg1, arg2)

	SQL_ThreadQuery(g_hSqlTuple, "QueryPlayerChangePW", szQuery, szData, charsmax(szData))

	return PLUGIN_HANDLED
}

public QueryPlayerChangePW(iFailState, Handle:iQuery, Error[], Errcode, szData[], iSize, Float:flQueueTime)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: 
		{
			log_to_file("csgo_remake_errors.log", "[SQL Error] Connection failed (%i): %s", Errcode, Error)
		}
		case TQUERY_QUERY_FAILED:
		{
			log_to_file("csgo_remake_errors.log", "[SQL Error] Query failed (%i): %s", Errcode, Error)
		}
	}

	new arg1[MAX_NAME_LENGTH], arg2[32], index[3], id

	strtok(szData, index, charsmax(index), szData, iSize, ';')

	id = str_to_num(index)

	strtok(szData, arg1, charsmax(arg1), szData, iSize, '=')

	strtok(szData, arg2, charsmax(arg2), szData, iSize)

	if(iFailState)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_ERROR_QUERYING")
		return
	}

	console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_PASSWORD_CHANGED", arg1, arg2)

	new target = get_user_index(arg1)
	if(is_user_connected(target))
	{
		CC_SendMessage(target, " ^1%L", LANG_SERVER, "CSGOR_ADMIN_CHANGED_PASSWORD", id ? g_szName[id] : "Administrator", arg2)
	}

	new szQuery[95]
	formatex(szQuery, charsmax(szQuery), "UPDATE `csgor_data` SET `Password` = ^"%s%^" WHERE `Name` = ^"%s^";", arg2, arg1)

	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)
}

public concmd_getinfo(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3, false))
	{
		return PLUGIN_HANDLED
	}

	new arg1[8]
	new arg2[8]
	read_argv(1, arg1, 7)
	read_argv(2, arg2, 7)

	new num = str_to_num(arg2)

	switch (arg1[0])
	{
		case 'r', 'R':
		{
			if (num < 0 || num >= g_iRanksNum)
			{
				console_print(id, "%s Wrong index. Please choose a number between 0 and %d.", g_iCvars[szChatPrefix], g_iRanksNum - 1)
			}
			else
			{
				new Name[MAX_RANK_NAME]
				ArrayGetString(g_aRankName, num, Name, charsmax(Name))
				new Kills = ArrayGetCell(g_aRankKills, num)
				console_print(id, "%s Information about RANK with index: %d", g_iCvars[szChatPrefix], num)
				console_print(id, "%s Name: %s | Required kills: %d", g_iCvars[szChatPrefix], Name, Kills)
			}
		}
		case 's', 'S':
		{
			if (num < 0 || num > ArraySize(g_aSkinData))
			{
				console_print(id, "%s Wrong index. Please choose a number between 0 and %d.", g_iCvars[szChatPrefix], ArraySize(g_aSkinData))
			}
			else
			{
				new eSkinData[SkinData]
				ArrayGetArray(g_aSkinData, num, eSkinData)

				console_print(id, "%s Information about SKIN with index: %d", g_iCvars[szChatPrefix], num)
				switch (eSkinData[iSkinType])
				{
					case 'd':
					{
						console_print(id, "%s Name: %s | Type: drop", g_iCvars[szChatPrefix], eSkinData[szSkinName])
					}
					
					default:
					{
						console_print(id, "%s Name: %s | Type: craft", g_iCvars[szChatPrefix], eSkinData[szSkinName])
					}
				}
			}
		}
		default:
		{
			console_print(id, "%s Wrong index. Please choose R or S.", g_iCvars[szChatPrefix])
		}
	}

	return PLUGIN_HANDLED
}

public concmd_nick(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3, false))
	{
		return PLUGIN_HANDLED
	}	
	new arg1[32], arg2[32]

	read_argv(1, arg1, charsmax(arg1))
	read_argv(2, arg2, charsmax(arg2))

	new player = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)
	
	if (!player)
	{
		console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1)
		return PLUGIN_HANDLED
	}

	g_eEnumBooleans[player][IsChangeNotAllowed] = true

	CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_ADMIN_CHANGE_X_NICK", g_szName[id], g_szName[player], arg2)

	console_print(id, "%s %L", g_iCvars[szChatPrefix], LANG_SERVER, "CSGOR_CHANGED_NICK", g_szName[player], arg2)

	copy(g_szName[player], charsmax(g_szName[]), arg2)

	set_task(0.5, "task_Reset_Name", id + TASK_RESET_NAME)

	return PLUGIN_HANDLED
}

public concmd_skin_index(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2, false))
		return PLUGIN_HANDLED

	new arg[48], iIndex, temp[MAX_SKIN_NAME]

	read_argv(1, arg, charsmax(arg))
	remove_quotes(arg)

	new eSkinData[SkinData]

	for(new i; i < ArraySize(g_aSkinData); i++)
	{
		ArrayGetArray(g_aSkinData, i, eSkinData)

		iIndex = containi(eSkinData[szSkinName], arg)

		if(iIndex > -1)
		{
			formatex(temp, charsmax(temp), "Skin Name: %s^nSkin ID: %i", eSkinData[szSkinName], i)
			break
		}
		else
		{
			formatex(temp, charsmax(temp), "%L", LANG_SERVER, "CSGOR_NO_SKIN_FOUND")
		}
	}

	console_print(id, temp)

	return PLUGIN_HANDLED
}

public clcmd_say_skin(id)
{
	new player = id

	if(!is_user_alive(player))
	{
		player = pev(player, pev_iuser2)

		if (!is_user_alive(player))
		{
			return PLUGIN_HANDLED
		}
	}

	if(!g_bLogged[player])
	{
		return PLUGIN_HANDLED
	}

	new iActiveItem = GetPlayerActiveItem(player)

	if(is_nullent(iActiveItem))
	{
		return PLUGIN_HANDLED
	}

	new weapon = GetWeaponEntity(iActiveItem)

	if((1 << weapon) & weaponsWithoutInspectSkin)
	{
		return PLUGIN_HANDLED
	}

	new skin = GetSkinInfo(player, weapon, iActiveItem)
	
	if(skin == -1)
	{
		CC_SendMessage(id, " ^1%L", LANG_SERVER, "CSGOR_NO_ACTIVE_SKIN")
		return PLUGIN_HANDLED
	}

	new eSkinData[SkinData]

	ArrayGetArray(g_aSkinData, skin, eSkinData)

	if(g_iUserSelectedSkin[player][bIsStattrack][weapon])
	{
		format(eSkinData[szSkinName], charsmax(eSkinData[szSkinName]), "(StatTrack) %s", eSkinData[szSkinName])
	}

	CC_SendMessage(id, "^1 Skin: ^3%s^1 | ^3%s^1 | ^3%d%%^1 | ^3%d - %d^1 points^1 | ^3%d ^1Dusts", eSkinData[szSkinName], g_iUserSelectedSkin[player][bIsStattrack][weapon] ? "StatTrack" : (eSkinData[iSkinType] == 'c' ? "Craft" : "Drop"), 100 - eSkinData[iSkinChance], eSkinData[iSkinCostMin], eSkinData[iSkinCostMax], eSkinData[iSkinDust])
	
	return PLUGIN_HANDLED
}

public RG_CBasePlayer_ImpulseCommands_Pre(id)
{
	if(!is_user_connected(id))
		return

	if(get_entvar(id, var_impulse) == 100)
	{
		inspect_weapon(id)
	}
}

public inspect_weapon(id)
{
	new iWeaponEnt
	new iAnim = GetPlayerInspectAnim(id, iWeaponEnt)

	if(iAnim < 0)
		return PLUGIN_HANDLED

	set_member(GetPlayerActiveItem(id), m_Weapon_flTimeWeaponIdle, 6.5)

	if(g_bSkinsRendering)
	{
		csgor_send_weapon_anim(id, iAnim)
	}
	else
	{
		rg_weapon_send_animation(iWeaponEnt, iAnim)
	}

	return PLUGIN_HANDLED
}

bool:IsHalf()
{
	if (g_iCvars[iCompetitive] && !g_bTeamSwap && g_iStats[iRoundNum] == 16)
	{
		return true
	}

	return false
}

bool:IsLastRound()
{
	if (g_iCvars[iCompetitive] && g_bTeamSwap && g_iStats[iRoundNum] == 31)
	{
		return true
	}

	return false
}

_ShowBestPlayers()
{
	new Pl[MAX_PLAYERS]
	new n
	new p
	new BestPlayer
	new Frags
	new BestFrags
	new MVP
	new BestMVP
	new bonus = g_iCvars[iBestPoints]

	get_players(Pl, n, "he", "TERRORIST")

	if (0 < n)
	{
		for (new i; i < n; i++)
		{
			p = Pl[i]
			MVP = g_iUserMVP[p]

			if (MVP < 1 || MVP < BestMVP)
			{
			}
			else
			{
				Frags = get_user_frags(p)

				if (MVP > BestMVP)
				{
					BestPlayer = p
					BestMVP = MVP
					BestFrags = Frags
				}
				else
				{
					if (Frags > BestFrags)
					{
						BestPlayer = p
						BestFrags = Frags
					}
				}
			}
		}
	}

	if (BestPlayer && BestPlayer <= 32)
	{
		CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_BEST_T", g_szName[BestPlayer], BestMVP, bonus)
	}
	else
	{
		CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_ZERO_MVP", "Terrorist")
	}

	if (g_bLogged[BestPlayer])
	{
		g_iUserPoints[BestPlayer] += bonus
	}

	get_players(Pl, n, "he", "CT")
	BestPlayer = 0
	BestMVP = 0
	BestFrags = 0

	if (0 < n)
	{
		for (new i; i < n; i++)
		{
			p = Pl[i]
			MVP = g_iUserMVP[p]

			if (MVP < 1 || MVP < BestMVP)
			{
			}
			else
			{
				Frags = get_user_frags(p)

				if (MVP > BestMVP)
				{
					BestPlayer = p
					BestMVP = MVP
					BestFrags = Frags
				}
				else
				{
					if (Frags > BestFrags)
					{
						BestPlayer = p
						BestFrags = Frags
					} 
				}
			}
		}
	}

	if (BestPlayer && BestPlayer <= 32)
	{
		CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_BEST_CT", g_szName[BestPlayer], BestMVP, bonus)
	}
	else
	{
		CC_SendMessage(0, "^1%L", LANG_SERVER, "CSGOR_ZERO_MVP", "Counter-Terrorist")
	}

	if (g_bLogged[BestPlayer])
	{
		g_iUserPoints[BestPlayer] += bonus
	}
}

_ShowMVP(id, event)
{
	if(!is_user_connected(id))
	{
		return PLUGIN_HANDLED
	}

	if (event < 1 && g_iRoundKills[id] < 1 )
	{
		return PLUGIN_HANDLED
	}

	g_iUserMVP[id]++

	new iRet
	ExecuteForward(g_iForwards[ user_mvp ], iRet, id, event, g_iRoundKills[id])

	if(iRet > PLUGIN_CONTINUE)
	{
		return PLUGIN_HANDLED
	}

	_GiveBonus(id, 1)
	
	switch (g_iCvars[iMVPMsgType])
	{
		case 1:
		{
			switch (event)
			{
				case 0:
				{
					CC_SendMessage(0, "^1 Round MVP: ^3%s^1%L: ^4%d", g_szName[id], LANG_SERVER, "CSGOR_MOST_KILL", g_iRoundKills[id])
				}
				case 1:
				{
					CC_SendMessage(0, "^1 Round MVP: ^3%s^1%L", g_szName[id], LANG_SERVER, "CSGOR_PLANTING")
				}
				case 2:
				{
					CC_SendMessage(0, "^1 Round MVP: ^3%s^1%L", g_szName[id], LANG_SERVER, "CSGOR_DEFUSING")
				}
			}
		}
		case 2:
		{
			set_hudmessage(0, 255, 10, -1.0, 0.1, 0, 0.00, 5.00)
			switch (event)
			{
				case 0:
				{
					show_hudmessage(0, "Round MVP : %s ^n%L (%d).", g_szName[id], LANG_SERVER, "CSGOR_MOST_KILL", g_iRoundKills[id])
				}
				case 1:
				{
					show_hudmessage(0, "Round MVP : %s ^n%L", g_szName[id], LANG_SERVER, "CSGOR_PLANTING")
				}
				case 2:
				{
					show_hudmessage(0, "Round MVP : %s ^n%L", g_szName[id], LANG_SERVER, "CSGOR_DEFUSING")
				}
			}
		}
		case 3:
		{
			set_dhudmessage(0, 255, 10, -1.0, 0.1, 0, 0.00, 5.00)
			switch (event)
			{
				case 0:
				{
					show_dhudmessage(0, "Round MVP : %s ^n%L (%d).", g_szName[id], LANG_SERVER, "CSGOR_MOST_KILL", g_iRoundKills[id])
				}
				case 1:
				{
					show_dhudmessage(0, "Round MVP : %s ^n%L", g_szName[id], LANG_SERVER, "CSGOR_PLANTING")
				}
				case 2:
				{
					show_dhudmessage(0, "Round MVP : %s ^n%L", g_szName[id], LANG_SERVER, "CSGOR_DEFUSING")
				}
			}
		}
	}
	
	return PLUGIN_HANDLED
}

_GetTopKiller(team)
{
	new Pl[MAX_PLAYERS]
	new n

	switch(team)
	{
		case 1:
		{
			get_players(Pl, n, "h", "T")
		}
		case 2:
		{
			get_players(Pl, n, "h", "CT")
		}
	}

	new p
	new pFrags
	new pDamage
	new tempF
	new tempD
	new tempID

	for (new i; i < n; i++)
	{
		p = Pl[i]
		pFrags = g_iRoundKills[p]

		if (!(pFrags < tempF))
		{
			pDamage = g_iDealDamage[p]

			if (pFrags > tempF || pDamage > tempD)
			{
				tempID = p
				tempF = pFrags
				tempD = pDamage
			}
		}
	}

	if (0 < tempF)
	{
		return tempID
	}

	return PLUGIN_CONTINUE
}

_GiveBonus(id, type)
{
	if (!g_bLogged[id])
	{
		CC_SendMessage(id, "^1%L", LANG_SERVER, "CSGOR_REGISTER")
		return -1
	}

	new rpoints

	switch (type)
	{
		case 0:
		{
			rpoints = random_num(g_iCvars[iAMinPoints], g_iCvars[iAMaxPoints])
		}
		case 1:
		{
			rpoints = random_num(g_iCvars[iMVPMinPoints], g_iCvars[iMVPMaxPoints])
		}
	}

	if(g_bLogged[id])
	{
		g_iUserPoints[id] += rpoints
		_Save(id)
	}

	return rpoints
}

_SetKillsIcon(id, reset)
{
	if(!is_user_connected(id))
		return

	switch (reset)
	{
		case 0:
		{
			new num = g_iDigit[id]

			if (num > 10)
			{
				return
			}

			num--
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, _, id)
			write_byte(0)
			write_string(szSprite[num])
			message_end()
			num++
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, _, id)
			write_byte(1)

			if (num > 9)
			{
				write_string(szSprite[10])
			}
			else
			{
				write_string(szSprite[num])
			}

			write_byte(0)
			write_byte(200)
			write_byte(0)
			message_end()
		}
		case 1:
		{
			new num = g_iDigit[id]
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, _, id)
			write_byte(0)

			if (num > 9)
			{
				write_string(szSprite[10])
			}
			else
			{
				write_string(szSprite[num])
			}

			message_end()
			g_iDigit[id] = 0
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, _, id)
			write_byte(1)
			write_string(szSprite[0])
			write_byte(0)
			write_byte(200)
			write_byte(0)
			message_end()
		}
	}
}

_DisplayMenu(id, menu)
{
	if(!is_user_connected(id))
		return

	menu_display(id, menu)
}

bool:IsRegistered(id)
{
	new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_data` WHERE `Name` = ^"%s^";", g_szName[id])
	
	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError))
		log_to_file("csgo_remake_errors.log", g_szSqlError)
		SQL_FreeHandle(iQuery)
	}

	new bool:bFoundData = SQL_NumResults( iQuery ) > 0 ? true : false

	SQL_FreeHandle(iQuery)

	return bFoundData
}

_MenuExit(menu)
{
	menu_destroy(menu)

	return PLUGIN_HANDLED
}

_GetItemName(item, temp[], len, &iLocked = -1)
{
	if(item == -1)
	{
		return PLUGIN_HANDLED
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
			static eSkinData[SkinData]
			ArrayGetArray(g_aSkinData, item, eSkinData)
			copy(temp, len, eSkinData[szSkinName])
			iLocked = eSkinData[iSkinLock]
		}
	}

	return PLUGIN_HANDLED
}

_GetSkinWID(iSkin)
{
	static eSkinData[SkinData]
	ArrayGetArray(g_aSkinData, iSkin, eSkinData)

	return eSkinData[iWeaponID]
}

change_skin(iPlayer, weapon)
{	
	if (!weapon || weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_C4) return
	
	DeployWeaponSwitch(iPlayer)
}

bool:_UserHasItem(id, item, iSTT)
{
	if (!_IsGoodItem(item))
	{
		return false
	}

	switch (item)
	{
		case KEY:
		{
			if (g_iUserKeys[id])
			{
				return true
			}
		}
		case CASE:
		{
			if (g_iUserCases[id])
			{
				return true
			}
		}
		default:
		{
			static ePlayerSkins[PlayerSkins]
			new iFound = -1
			ePlayerSkins = GetPlayerSkin(id, item, iFound, iSTT)
			if (ePlayerSkins[iPieces] > 0 && iFound >= 0)
			{
				return true
			}
		}
	}

	return false
}

_CalcItemPrice(item, &min, &max)
{
	switch (item)
	{
		case KEY:
		{
			min = g_iCvars[iKeyMinCost]
			max = g_iCvars[iCostMultiplier] * g_iCvars[iKeyMinCost]
		}
		case CASE:
		{
			min = g_iCvars[iCaseMinCost]
			max = g_iCvars[iCostMultiplier] * g_iCvars[iCaseMinCost]
		}
		default:
		{
			new eSkinData[SkinData]
			ArrayGetArray(g_aSkinData, item, eSkinData)
			min = eSkinData[iSkinCostMin]
			max = eSkinData[iSkinCostMax]
		}
	}
}

IsTaken(id, &iTimestamp)
{
	new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_data` WHERE `Name` = ^"%s^";", g_szName[id])

	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError))
		log_to_file("csgo_remake_errors.log", g_szSqlError)
		SQL_FreeHandle(iQuery)
	}

	iTimestamp = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Bonus Timestamp"))

	SQL_FreeHandle(iQuery)
}

_Send_DeathMsg(killer, victim, hs, weapon[])
{
	message_begin(MSG_BROADCAST, g_Msg_DeathMsg)
	write_byte(killer)
	write_byte(victim)
	write_byte(hs)
	write_string(weapon)
	message_end()
}

_ResetTradeData(id)
{
	g_bTradeActive[id] = false
	g_bTradeSecond[id] = false
	g_bTradeAccept[id] = false
	g_iTradeTarget[id] = 0
	g_iTradeItem[id][iItemID] = -1
	g_iTradeRequest[id] = 0
}

_GiveToAll(id, arg1[], arg2[], type)
{
	new Pl[32]
	new n
	new target
	new amount = str_to_num(arg2)

	if (amount)
	{
		switch (arg1[1])
		{
			case 'A', 'a':
			{
				get_players(Pl, n, "h")
			}
			case 'C', 'c':
			{
				get_players(Pl, n, "eh", "CT")
			}
			case 'T', 't':
			{
				get_players(Pl, n, "eh", "TERRORIST")
			}
		}

		if (!n)
		{
			console_print(id, "%s No players found in the chosen category: %s", g_iCvars[szChatPrefix], arg1)
			return PLUGIN_HANDLED
		}
		
		switch (type)
		{
			case 0:
			{
				for (new i; i < n; i++)
				{
					target = Pl[i]

					if (g_bLogged[target])
					{
						if (0 > amount)
						{
							g_iUserPoints[target] -= amount
							if (0 > g_iUserPoints[target])
							{
								g_iUserPoints[target] = 0
							}

							CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_POINTS")
						}
						else
						{
							g_iUserPoints[target] += amount

							CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_POINTS")
						}
					}
				}

				new temp[64]

				if (0 < amount)
				{
					if (amount == 1)
					{
						formatex(temp, charsmax(temp), "You gave 1 point to players !")
					}
					else
					{
						formatex(temp, charsmax(temp), "You gave %d points to players !", amount)
					}

					console_print(id, "%s %s", g_iCvars[szChatPrefix], temp)
				}
				else
				{
					if (amount == -1)
					{
						formatex(temp, charsmax(temp), "You got 1 point from players !")
					}
					else
					{
						formatex(temp, charsmax(temp), "You got %d points from players !", amount *= -1)
					}

					console_print(id, "%s %s", g_iCvars[szChatPrefix], temp)
				}
			}
			case 1:
			{
				for (new i; i < n; i++)
				{
					target = Pl[i]

					if (g_bLogged[target])
					{
						if (0 > amount)
						{
							g_iUserCases[target] -= amount
							if (0 > g_iUserCases[target])
							{
								g_iUserCases[target] = 0
							}

							CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_CASES")
						}
						else
						{
							g_iUserCases[target] += amount

							CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_CASES")
						}
					}
				}

				new temp[64]

				if (0 < amount)
				{
					if (amount == 1)
					{
						formatex(temp, charsmax(temp), "You gave 1 case to players !")
					}
					else
					{
						formatex(temp, charsmax(temp), "You gave %d cases to players !", amount)
					}

					console_print(id, "%s %s", g_iCvars[szChatPrefix], temp)
				}
				else
				{
					if (amount == -1)
					{
						formatex(temp, charsmax(temp), "You got 1 case from players !")
					}
					else
					{
						formatex(temp, charsmax(temp), "You got %d cases from players !", amount *= -1)
					}

					console_print(id, "%s %s", g_iCvars[szChatPrefix], temp)
				}
			}
			case 2:
			{
				for (new i; i < n; i++)
				{
					target = Pl[i]

					if (g_bLogged[target])
					{
						if (0 > amount)
						{
							g_iUserKeys[target] -= amount
							if (0 > g_iUserKeys[target])
							{
								g_iUserKeys[target] = 0
							}

							CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_KEYS")
						}
						else
						{
							g_iUserKeys[target] += amount

							CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_KEYS")
						}
					}
				}

				new temp[64]

				if (0 < amount)
				{
					if (amount == 1)
					{
						formatex(temp, charsmax(temp), "You gave 1 key to players !")
					}
					else
					{
						formatex(temp, charsmax(temp), "You gave %d keys to players !", amount)
					}

					console_print(id, "%s %s", g_iCvars[szChatPrefix], temp)
				}
				else
				{
					if (amount == -1)
					{
						formatex(temp, charsmax(temp), "You got 1 key from players !")
					}
					else
					{
						formatex(temp, charsmax(temp), "You got %d keys from players !", amount *= -1)
					}

					console_print(id, "%s %s", g_iCvars[szChatPrefix], temp)
				}
			}
			case 3:
			{
				for (new i; i < n; i++)
				{
					target = Pl[i]

					if (g_bLogged[target])
					{
						if (0 > amount)
						{
							g_iUserDusts[target] -= amount
							if (0 > g_iUserDusts[target])
							{
								g_iUserDusts[target] = 0
							}

							CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_DUSTS")
						}
						else
						{
							g_iUserDusts[target] += amount

							CC_SendMessage(target, "^1%L %L", LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_DUSTS")
						}
					}
				}

				new temp[64]

				if (0 < amount)
				{
					if (amount == 1)
					{
						formatex(temp, charsmax(temp), "You gave 1 dust to players !")
					}
					else
					{
						formatex(temp, charsmax(temp), "You gave %d dusts to players !", amount)
					}

					console_print(id, "%s %s", g_iCvars[szChatPrefix], temp)
				}
				else
				{
					if (amount == -1)
					{
						formatex(temp, charsmax(temp), "You got 1 dust from players !")
					}
					else
					{
						formatex(temp, charsmax(temp), "You got %d dusts from players !", amount *= -1)
					}

					console_print(id, "%s %s", g_iCvars[szChatPrefix], temp)
				}
			}
		}
	}

	console_print(id, "%s <Amount> It must not be 0 (zero)!", g_iCvars[szChatPrefix])

	return PLUGIN_HANDLED
}

bool:_IsItemSkin(item)
{
	if (0 <= item < ArraySize(g_aSkinData))
	{
		return true
	}

	return false
}

bool:_IsGoodItem(item)
{
	if (0 <= item <= ArraySize(g_aSkinData) || item == CASE || item == KEY)
	{
		return true
	}

	return false
}

GetUserSkinsNum(id, iWeapon, bool:bStatTrack = false)
{
	static eSkinData[SkinData], ePlayerSkins[PlayerSkins]
	new num
	new iSkins = 0, iFound = -1

	for (new i; i < ArraySize(g_aSkinData); i++)
	{
		ArrayGetArray(g_aSkinData, i, eSkinData)

		ePlayerSkins = GetPlayerSkin(id, i, iFound, bStatTrack ? 1 : 0)

		if(iFound < 0)
			continue

		num = ePlayerSkins[iPieces]
		
		if (eSkinData[iWeaponID] == iWeapon && i == ePlayerSkins[iSkinid] && num > 0)
		{
			{
				iSkins += 1
				continue
			}
		}
	}

	return iSkins
}

GetMaxSkins(iWeapon)
{
	new eSkinData[SkinData]
	new iSkins
	for (new i; i < ArraySize(g_aSkinData); i++)
	{
		ArrayGetArray(g_aSkinData, i, eSkinData)
		if (iWeapon == eSkinData[iWeaponID])
		{
			iSkins++
		}
	}
	return iSkins
}

GetSkinID(szSkin[])
{
	static eSkinData[SkinData]

	for(new i; i < ArraySize(g_aSkinData); i++)
	{
		ArrayGetArray(g_aSkinData, i, eSkinData)

		if(equali(eSkinData[szSkinName], szSkin))
			return i
	}

	return -1
}

GetPlayerActiveItem(id)
{
	return get_member(id, m_pActiveItem)
}

GetEntityOwner(iEnt)
{
	return get_member(iEnt, m_pPlayer)
}

bool:IsValidWeapon(iWeapon)
{
	if(iWeapon < 1 || iWeapon > 30)
		return false

	return true
}

GetWeaponEntity(iEnt)
{
	return rg_get_iteminfo(iEnt, ItemInfo_iId)
}

bool:IsGrenadeClassName(iEnt)
{
	new bool:bFound = false
	for(new i; i < sizeof(GrenadeName); i++)
	{
		if(FClassnameIs(iEnt, GrenadeName[i]))
		{
			bFound = true
			break
		}
	}
	return bFound
}

DestroyTask(iTaskID)
{
	if(task_exists(iTaskID))
	{
		remove_task(iTaskID)
	}
}

FormatStattrack(szName[], iLen)
{
	format(szName, iLen, "(StatTrack) %s", szName)
}

GetPlayerInspectAnim(id, &weapon)
{
	if (is_nullent(id) || !is_user_alive(id) || cs_get_user_shield(id) || cs_get_user_zoom(id) > 1) return -1
	
	weapon = GetPlayerActiveItem(id)
	new weaponId = GetWeaponEntity(weapon)

	if(weaponsWithoutInspectSkin & (1<<weaponId) || is_nullent(weapon) || get_member(weapon, m_Weapon_fInReload))
		return -1

	new animation = inspectAnimation[weaponId]

	switch (weaponId) 
	{
		case CSW_M4A1:
		{
			if (!cs_get_weapon_silen(weapon)) animation = 15
			else animation = 14
		} 
		case CSW_USP: 
		{
			if (!cs_get_weapon_silen(weapon)) animation = 17
			else animation = 16
		}
	}

	g_eEnumBooleans[id][IsInInspect] = true

	return animation
}

cmd_execute(id, const text[], any:...)
{
	if (!is_user_connected(id)) return

	#pragma unused text

	new szMessage[256]

	format_args(szMessage, charsmax(szMessage), 1)

	message_begin(id == 0 ? MSG_BROADCAST : MSG_ONE_UNRELIABLE, SVC_DIRECTOR, _, id)
	write_byte(strlen(szMessage) + 2)
	write_byte(10)
	write_string(szMessage)
	message_end()
}

DoIntermission()
{
	emessage_begin(MSG_BROADCAST, SVC_INTERMISSION)
	emessage_end()
}

SetWeaponModel(id, bool:bViewModel, model[])
{
	set_pev(id, bViewModel ? pev_viewmodel2 : pev_weaponmodel2, model)
}

GetSkinInfo(player, weapon, iActiveItem)
{
	new skin = -1

	switch (weapon)
	{
		case CSW_KNIFE:
		{
			if(g_iUserSelectedSkin[player][bIsStattrack][weapon])
			{
				if(g_iUserSelectedSkin[player][iUserStattrack][weapon] != -1)
				{
					skin = g_iUserSelectedSkin[player][iUserStattrack][weapon]
				}
			}
			else
			{
				if(g_iUserSelectedSkin[player][iUserSelected][weapon] != -1)
				{
					skin = g_iUserSelectedSkin[player][iUserSelected][weapon]
				}
			}
		}
		default:
		{
			new imp = pev(iActiveItem, pev_impulse)

			if (imp)
			{
				skin = imp - 1
			}
			else if (!imp)
			{
				skin = (g_iUserSelectedSkin[player][bIsStattrack][weapon] ? g_iUserSelectedSkin[player][iUserStattrack][weapon] : g_iUserSelectedSkin[player][iUserSelected][weapon])
			}
			else
			{
				if(g_iUserSelectedSkin[player][bIsStattrack][weapon])
				{
					if(g_iUserSelectedSkin[player][iUserStattrack][weapon] != -1)
					{
						skin = g_iUserSelectedSkin[player][iUserStattrack][weapon]
					}
				}
				else
				{
					if(g_iUserSelectedSkin[player][iUserSelected][weapon] != -1)
					{
						skin = g_iUserSelectedSkin[player][iUserSelected][weapon]
					}
				}
			}
		}
	}

	return skin
}

GetPlayerSkin(id, skinid, &iFound = -1, iSTT = 2)
{
	static ePlayerSkins[PlayerSkins]
	iFound = -1
	new bool:bCondition

	for(new j; j < ArraySize(g_aPlayerSkins[id]); j++)
	{
		ArrayGetArray(g_aPlayerSkins[id], j, ePlayerSkins)

		switch(iSTT)
		{
			case 2:
			{
				bCondition = (ePlayerSkins[iSkinid] == skinid)
			}
			default:
			{
				bCondition = (ePlayerSkins[iSkinid] == skinid && ePlayerSkins[isStattrack] == iSTT)
			}
		}

		if(bCondition)
		{
			iFound = j
			break
		}
	}

	return ePlayerSkins
}

SetPlayerSkin(id, iSkin, ePlayerSkins[PlayerSkins], iSTT = 0)
{
	ePlayerSkins[iWeaponid] = _GetSkinWID(iSkin)
	ePlayerSkins[iSkinid] = iSkin
	ePlayerSkins[iPieces] = 0
	ePlayerSkins[iSelected] = 0
	ePlayerSkins[iKills] = 0
	ePlayerSkins[isStattrack] = iSTT
	ePlayerSkins[szNameTag] = ""

	return ArrayPushArray(g_aPlayerSkins[id], ePlayerSkins)
}

UpdatePlayerSkin(id, szSkin[], ePlayerSkins[PlayerSkins], bool:bDelete = false)
{
	if (!g_bLoaded[id]) 
		return

	static szQuery[512]

	if(bDelete)
	{
		formatex(szQuery, charsmax(szQuery), "DELETE FROM `csgor_skins` WHERE `Skin` = ^"%s^" \
			AND `Name` = ^"%s^"", szSkin, g_szName[id])
	}
	else
	{
		formatex(szQuery, charsmax(szQuery), "INSERT INTO `csgor_skins` (`Name`, `WeaponID`, `Skin`, `Selected`,\
			`Stattrack`, `Kills`, `Piece`, `NameTag`) VALUES (^"%s^", '%d', ^"%s^", '%d', '%d', '%d', '%d', ^"%s^") \
			ON DUPLICATE KEY UPDATE `Piece` = '%d', `Selected` = '%d', `Kills` = '%d', `NameTag` = ^"%s^";", g_szName[id], ePlayerSkins[iWeaponid], szSkin,
			ePlayerSkins[iSelected], ePlayerSkins[isStattrack], ePlayerSkins[iKills], ePlayerSkins[iPieces],
			ePlayerSkins[szNameTag], ePlayerSkins[iPieces], ePlayerSkins[iSelected], ePlayerSkins[iKills], ePlayerSkins[szNameTag])
	}

	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)
}
