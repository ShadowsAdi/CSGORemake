#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csx>
#include <csgo_remake>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>
#include <sqlx>
#include <unixtime>

/* Uncomment this if you want to enable debug informations. Be carefull, this will spam server's logs */
//#define DEBUG

/* Uncomment this if you want to setup HUD Message */
//#define HUD_POS

/* Uncomment this if you need more memory to allocate. */
#pragma dynamic 65536

#define PLUGIN "CS:GO Remake"
#define VERSION "2.2.2"
#define AUTHOR "Shadows Adi"

#define CSGO_TAG 						"[CS:GO Remake]"

/* Do NOT Modify the limit only if you know what are you doing ( Could cause some on stack problems ) */
#define MAX_SKINS						450

#define WEAPONS_NR						CSW_P90 + 1

#define IsPlayer(%0)					(1 <= %0 <= g_iMaxPlayers)

#define GetPlayerBit(%0,%1) 			( IsPlayer(%1) && ( %0 & ( 1 << ( %1 & 31 ) ) ) )
#define SetPlayerBit(%0,%1) 			( IsPlayer(%1) && ( %0 |= ( 1 << ( %1 & 31 ) ) ) )
#define ClearPlayerBit(%0,%1) 			( IsPlayer(%1) && ( %0 &= ~( 1 << ( %1 & 31 ) ) ) )

#define XO_WEAPON 						4
#define XO_PLAYER 						5
#define OFFSET_WEAPONOWNER 				41
#define OFFSET_ID						43
#define OFFSET_SECONDARY_ATTACK 		47
#define OFFSET_WEAPON_IDLE 				48
#define OFFSET_WEAPONCLIP				51
#define OFFSET_WEAPON_IN_RELOAD       	54
#define OFFSET_WEAPONSTATE				74
#define OFFSET_ACTIVE_ITEM 				373

#define OBS_IN_EYE 						4

#define WPNSTATE_USP_SILENCED 			(1<<0)
#define WPNSTATE_GLOCK18_BURST_MODE 	(1<<1)
#define WPNSTATE_M4A1_SILENCED 			(1<<2)
#define WPNSTATE_ELITE_LEFT 			(1<<3)
#define WPNSTATE_FAMAS_BURST_MODE 		(1<<4)
#define UNSIL 							0
#define SILENCED 						1

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

#define DRYFIRE_PISTOL 					"csgor/dryfire_pistol.wav"
#define DRYFIRE_RIFLE 					"csgor/dryfire_rifle.wav"
#define GLOCK18_BURST_SOUND 			"csgor/glock18-2.wav"
#define GLOCK18_SHOOT_SOUND 			"csgor/glock18-1.wav"
#define AK47_SHOOT_SOUND 				"csgor/ak47.wav"
#define AUG_SHOOT_SOUND 				"csgor/aug.wav"
#define AWP_SHOOT_SOUND 				"csgor/awp.wav"
#define DEAGLE_SHOOT_SOUND 				"csgor/deagle.wav"
#define ELITE_SHOOT_SOUND 				"csgor/elite_fire.wav"
#define CLARION_BURST_SOUND 			"csgor/famas-1.wav"
#define CLARION_SHOOT_SOUND 			"csgor/famas-1.wav"
#define FIVESEVEN_SHOOT_SOUND 			"csgor/fiveseven.wav"
#define G3SG1_SHOOT_SOUND 				"csgor/g3sg1.wav"
#define GALIL_SHOOT_SOUND 				"csgor/galil.wav"
#define M3_SHOOT_SOUND 					"csgor/m3.wav"
#define XM1014_SHOOT_SOUND 				"csgor/xm1014.wav"
#define M4A1_SILENT_SOUND 				"csgor/m4a1.wav"
#define M4A1_SHOOT_SOUND 				"csgor/m4a1_unsil.wav"
#define M249_SHOOT_SOUND 				"csgor/m249.wav"
#define MAC10_SHOOT_SOUND 				"csgor/mac10.wav"
#define MP5_SHOOT_SOUND 				"csgor/mp5.wav"
#define P90_SHOOT_SOUND 				"csgor/p90.wav"
#define P228_SHOOT_SOUND 				"csgor/p228.wav"
#define SCOUT_SHOOT_SOUND 				"csgor/scout_fire.wav"
#define SG550_SHOOT_SOUND 				"csgor/sg550.wav"
#define SG552_SHOOT_SOUND 				"csgor/sg552.wav"
#define TMP_SHOOT_SOUND 				"csgor/tmp.wav"
#define UMP45_SHOOT_SOUND 				"csgor/ump45.wav"
#define USP_SHOOT_SOUND 				"csgor/usp_unsil.wav"
#define USP_SILENT_SOUND 				"csgor/usp.wav"

#define weaponsWithoutInspect			((1<<CSW_C4) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE))
#define weaponsNotVaild					((1<<CSW_C4) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_KNIFE))
#define weaponsWithoutSkin				((1<<CSW_C4) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE))
#define NO_REFILL_WEAPONS 				((1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_C4))
#define MISC_ITEMS						((1<<CSI_DEFUSER) | (1<<CSI_NVGS) | (1<<CSI_SHIELD) | (1<<CSI_PRIAMMO) | (1<<CSI_SECAMMO) | (1<<CSI_VEST) | (1<<CSI_VESTHELM))

#define PDATA_SAFE						2

#define EVENT_SVC_INTERMISSION			"30"

/* ----------------------- TASKIDs ----------------------- */

enum (+=1404)
{
	TASK_TOMBOLA = 1000,
	TASK_HUD,
	TASK_RESET_NAME,
	TASK_RESPAWN,
	TASK_SENDDEATH,
	TASK_INFO,
	TASK_SWAP,
	TASK_JACKPOT,
	TASK_SET_ICON,
	TASK_ROULLETTE_PRE,
	TASK_ROULLETTE_POST,
	TASK_SHELLS,
	TASK_CHECK_NAME,
	TASK_MAP_END,
	TASK_FADE_BLACK,
	TASK_OBS_IN_EYE,
	TASK_UPDATE_STATTRACK,
	TASK_UPDATE_STATTRACK_KILLS,
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
	ItemID[CSW_P90]
}

enum _:EnumDynamicMenu
{
	szMenuName[32],
	szMenuCMD[32]
}

enum _:EnumStattrackInfo
{
	iWeap[MAX_SKINS + 1],
	iKillCount[MAX_SKINS + 1],
	iSelected[WEAPONS_NR],
	bool:bStattrack[WEAPONS_NR]
}

enum _:EnumBooleans
{
	bool:IsInPreview = 0,
	bool:IsInInspect,
	bool:IsChangeNotAllowed
}

enum
{
	KEY = 544,
	CASE = 545
}

enum
{
	NVAULT = 0,
	MYSQL = 1
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
	file_buffer
};

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
	iSaveType,
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
	iTimeDelete,
	iPromoTime,
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
	iTombolaCost,
	iTombolaTimer,
	iJackpotTimer,
	iShowHUD,
	iSilentWeapDamage,
	iChatTagPrice,
	iChatTagColorPrice,
	Float:flShortThrowVelocity,
	Float:flRouletteCooldown,
	iRoundEndSounds,
	iCopyRight,
	iCustomChat,
	iAntiSpam,
	szBonusValues[18],
	iCheckBonusType
}

enum _:EnumRoundStats
{
	iCTScore,
	iTeroScore,
	iRoundNum
}

new TraceBullets[][] = { "func_breakable", "func_wall", "func_door", "func_plat", "func_rotating", "worldspawn", "func_door_rotating" };

new g_iWeaponIndex[MAX_PLAYERS + 1];
new g_iUserViewBody[MAX_PLAYERS + 1][31];
new g_iUserBodyGroup[MAX_PLAYERS + 1];

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
new bool:g_bGEventID[512];

new inspectAnimation[] =
{
	0, 7, 0, 5, 0, 7, 0, 6, 6, 0, 16 ,6 ,6 ,5 ,6 ,6 ,16, 13, 6, 6, 5, 7, 14, 6, 5, 0, 6, 6, 6, 8, 6
};

new Handle:g_hSqlTuple;
new g_szSqlError[512];
new Handle:g_iSqlConnection;
new g_Vault;
new g_nVault;
new g_pVault;
new g_sVault;

new g_iRoulleteNumbers[7][8];
new g_iRoulettePlayers;
new g_iRouletteTime = 60;

new bool:g_bLogged[ MAX_PLAYERS + 1 ];
new bool:g_bSkinHasModelP[MAX_SKINS + 1];
new g_MsgSync;

new g_WarmUpSync;
new g_iLastOpenCraft[ MAX_PLAYERS + 1 ];

new g_szCfgDir[48];
new g_szConfigFile[64];

new Array:g_aRankName;
new Array:g_aRankKills;

new Array:g_aDefaultSubmodel;
new Array:g_aSkinWeaponID;
new Array:g_aSkinName;
new Array:g_aSkinModel;
new Array:g_aSkinModelP;
new Array:g_aSkinSubModel;
new Array:g_aSkinType;
new Array:g_aSkinChance;
new Array:g_aSkinCostMin;
new Array:g_aDropSkin;
new Array:g_aCraftSkin;
new Array:g_aDustsSkin;
new Array:g_aLockSkin;
new Array:g_aTombola;
new Array:g_aJackpotSkins;
new Array:g_aJackpotUsers;
new Array:g_aPromocodes;
new Array:g_aPromocodesUsage;
new Array:g_aPromocodesGift;
new Array:g_aSkinsMenu;
new Array:g_aDynamicMenu;
new Array:g_aSkipChat;

new g_iRanksNum;
new g_iSkinsNum;
new g_iPromoNum;
new g_iPromoCount[ MAX_PLAYERS + 1 ];

new g_iUserSelectedSkin[ MAX_PLAYERS + 1 ][WEAPONS_NR];
new g_iStattrackWeap[ MAX_PLAYERS + 1][ EnumStattrackInfo ];
new g_iUserSkins[ MAX_PLAYERS + 1 ][MAX_SKINS + 1];
new g_iUserPoints[ MAX_PLAYERS + 1 ];
new g_iUserDusts[ MAX_PLAYERS + 1 ];
new g_iUserKeys[ MAX_PLAYERS + 1 ];
new g_iUserCases[ MAX_PLAYERS + 1 ];
new g_iUserKills[ MAX_PLAYERS + 1 ];
new g_iUserRank[ MAX_PLAYERS + 1 ];
new g_szUserPrefix[ MAX_PLAYERS + 1 ][16];
new g_szUserPrefixColor[ MAX_PLAYERS + 1 ][16];
new g_szTemporaryCtag[ MAX_PLAYERS + 1 ][16];
new g_iDropSkinNum;
new g_iCraftSkinNum;

new g_szName[ MAX_PLAYERS + 1 ][32];
new g_szSteamID[ MAX_PLAYERS + 1][32];
new g_szUserPassword[ MAX_PLAYERS + 1 ][16];
new g_szUser_SavedPass[ MAX_PLAYERS + 1 ][16];
new g_szUserLastIP[ MAX_PLAYERS + 1 ][19];
new g_iUserPassFail[MAX_PLAYERS + 1];

new g_szUserPromocode[ MAX_PLAYERS + 1 ][32];

new g_Msg_SayText;
new g_Msg_StatusIcon;
new g_Msg_DeathMsg;

new g_iUserSellItem[ MAX_PLAYERS + 1 ];
new g_iUserItemPrice[ MAX_PLAYERS + 1 ];
new bool:g_bUserSell[ MAX_PLAYERS + 1 ];

new g_iLastPlace[ MAX_PLAYERS + 1 ];

new g_iMenuType[ MAX_PLAYERS + 1 ];

new g_iGiftTarget[ MAX_PLAYERS + 1 ];
new g_iGiftItem[ MAX_PLAYERS + 1 ];

new g_iTradeTarget[ MAX_PLAYERS + 1 ];
new g_iTradeItem[ MAX_PLAYERS + 1 ];
new bool:g_bTradeActive[ MAX_PLAYERS + 1 ];
new bool:g_bTradeSecond[ MAX_PLAYERS + 1 ];
new bool:g_bTradeAccept[ MAX_PLAYERS + 1 ];
new g_iTradeRequest[ MAX_PLAYERS + 1 ];

new g_iRouletteCost;
new bool:g_bRoulettePlay;

new g_iTombolaPlayers;
new g_iTombolaPrize;
new bool:g_bUserPlay[ MAX_PLAYERS + 1 ];
new g_iNextTombolaStart;
new bool:g_bTombolaWork = true;

new bool:g_bJackpotWork;
new g_iUserJackpotItem[ MAX_PLAYERS + 1 ];
new bool:g_bUserPlayJackpot[ MAX_PLAYERS + 1 ];
new g_iJackpotClose;

new g_iCoinflipTarget[ MAX_PLAYERS + 1 ];
new g_iCoinflipItem[ MAX_PLAYERS + 1 ];
new g_iCoinflipRequest[ MAX_PLAYERS + 1 ];
new bool:g_bCoinflipActive[ MAX_PLAYERS + 1 ];
new bool:g_bCoinflipSecond[ MAX_PLAYERS + 1 ];
new bool:g_bCoinflipAccept[ MAX_PLAYERS + 1 ];
new bool:g_bCoinflipWork;

new bool:g_bWarmUp;

new p_StartMoney;
new bool:g_bTeamSwap;
new p_Freezetime;

new bool:g_bBombExplode;
new bool:g_bBombDefused;
new g_iBombPlanter;
new g_iBombDefuser;

new g_iScore[3];
new g_iRoundKills[ MAX_PLAYERS + 1 ];
new g_iDigit[ MAX_PLAYERS + 1 ];
new g_iUserMVP[ MAX_PLAYERS + 1 ];

new g_iDealDamage[ MAX_PLAYERS + 1 ];

new pNextMap;
new szNextMap[32];

new g_iMostDamage[ MAX_PLAYERS + 1 ];
new g_iDamage[ MAX_PLAYERS + 1 ][33];
new g_iRedPoints[ MAX_PLAYERS + 1 ];
new g_iWhitePoints[ MAX_PLAYERS + 1 ];
new g_iYellowPoints[ MAX_PLAYERS + 1 ];
new g_eEnumBooleans[MAX_PLAYERS + 1][EnumBooleans];
new g_bitIsAlive;
new g_bitShortThrow;

new g_iForwards[ EnumForwards ];
new g_iForwardResult;

new g_iCvars[EnumCvars];
new g_iStats[EnumRoundStats];

new g_szTWin[] =
{
	"csgor/twin.wav"
};

new g_szCTWin[] =
{
	"csgor/ctwin.wav"
};

new g_szCaseOpen[] =
{
	"csgor/caseopen.wav"
};

new const g_szBombPlanting[] = "csgor/bomb_planting.wav";

new const g_szBombDefusing[] = "csgor/bomb_defusing.wav";

new GrenadeName[][] =
{
	"weapon_hegrenade",
	"weapon_flashbang",
	"weapon_smokegrenade"
};

new const g_szWeaponEntName[][] =
{
	"weapon_p228",
	"weapon_scout",
	"weapon_hegrenade",
	"weapon_xm1014",
	"weapon_c4",
	"weapon_mac10",
	"weapon_aug",
	"weapon_smokegrenade",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_usp",
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_flashbang",
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_knife",
	"weapon_p90"
};

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
};

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
};

new defaultModels[WEAPONS_NR][48];
new defaultCount;

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
new Float:HUD_POS_X = 0.02;
new Float:HUD_POS_Y = 0.90;
#endif

new g_iMaxPlayers;

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);

public plugin_init()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "plugin_init()");
	#endif

	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new pcvar = create_cvar("csgor_author", "Shadows Adi", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY, "DO NOT MODIFY!" );
	
	pcvar = create_cvar("csgor_savetype", "0", FCVAR_NONE, "(0|1) Save type || 0 - nVault Save  | 1 - MYSQL Save", true, 0.0, true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iSaveType]);

	pcvar = create_cvar("csgor_dbase_host", "localhost", FCVAR_SPONLY | FCVAR_PROTECTED, "Database Host");
	bind_pcvar_string(pcvar, g_iCvars[szSqlHost], charsmax(g_iCvars[szSqlHost]));

	pcvar = create_cvar("csgor_dbase_user", "username", FCVAR_SPONLY | FCVAR_PROTECTED, "Database Username");
	bind_pcvar_string(pcvar, g_iCvars[szSqlUsername], charsmax(g_iCvars[szSqlUsername]));

	pcvar = create_cvar("csgor_dbase_pass", "password", FCVAR_SPONLY | FCVAR_PROTECTED, "Database Password");
	bind_pcvar_string(pcvar, g_iCvars[szSqlPassword], charsmax(g_iCvars[szSqlPassword]));

	pcvar = create_cvar("csgor_dbase_database", "database", FCVAR_SPONLY | FCVAR_PROTECTED, "Database Name");
	bind_pcvar_string(pcvar, g_iCvars[szSqlDatabase], charsmax(g_iCvars[szSqlDatabase]));

	pcvar = create_cvar("csgor_prunedays", "60", FCVAR_NONE, "(0|∞) The accounts will be erased in X days of inactivity", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iPruneDays]);
	
	pcvar = create_cvar("csgor_default_map", "de_dust2", FCVAR_NONE, "If cvar ^"amx_nextmap^" doesn't exist, this will be the next map, only if ^"csgor_competitive_mode^" is ^"1^"");
	bind_pcvar_string(pcvar, g_iCvars[szNextMapDefault], charsmax(g_iCvars[szNextMapDefault]));
	
	pcvar = create_cvar("csgor_override_menu", "1", FCVAR_NONE, "(0|1)  Main menu will open with ^"M^" key", true, 0.0, true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iOverrideMenu]);
	
	pcvar = create_cvar("csgor_show_hud", "2", FCVAR_NONE, "(0|1|2) HUD Info^n 0 - Deactivated || 1 - Classic HUD || 2 - Advanced HUD", true, 0.0, true, 2.0 );
	bind_pcvar_num(pcvar, g_iCvars[iShowHUD]);
	
	pcvar = create_cvar("csgor_head_minpoints", "11", FCVAR_NONE, "How much points for a HeadShot kill^n(MINIMUM)", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iHMinPoints]);
	
	pcvar = create_cvar("csgor_head_maxpoints", "15", FCVAR_NONE, "How much points for a HeadShot kill^n(MAXIMUM)", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iHMaxPoints]);
	
	pcvar = create_cvar("csgor_kill_minpoints", "6", FCVAR_NONE, "How much points for a kill^n(MINIMUM)", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iKMinPoints]);
	
	pcvar = create_cvar("csgor_kill_maxpoints", "10", FCVAR_NONE, "How much points for a kill^n(MAXIMUM)", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iKMaxPoints]);
	
	pcvar = create_cvar("csgor_head_minchance", "25", FCVAR_NONE, "Drop chance ( case ) if kill is made by HeadShot^n(MINIMUM)", true, 0.0, true, 99.0 );
	bind_pcvar_num(pcvar, g_iCvars[iHMinChance]);
	
	pcvar = create_cvar("csgor_head_maxchance", "100", FCVAR_NONE, "Drop chance ( case ) if kill is made by HeadShot^n(MAXIMUM)", true, 0.0, true, 100.0 );
	bind_pcvar_num(pcvar, g_iCvars[iHMaxChance]);
	
	pcvar = create_cvar("csgor_kill_minchance", "0", FCVAR_NONE, "Drop chance ( case ) for a basic kill^n(MINIMUM)", true, 0.0, true, 99.0 );
	bind_pcvar_num(pcvar, g_iCvars[iKMinChance]);
	
	pcvar = create_cvar("csgor_kill_maxchance", "100", FCVAR_NONE, "Drop chance ( case ) for a basic kill^n(MAXIMUM)", true, 0.0, true, 100.0 );
	bind_pcvar_num(pcvar, g_iCvars[iKMaxChance]);
	
	pcvar = create_cvar("csgor_assist_minpoints", "3", FCVAR_NONE, "How much points for an assist^n(MINIMUM)", true, 0.0, true, 99.0 );
	bind_pcvar_num(pcvar, g_iCvars[iAMinPoints]);
	
	pcvar = create_cvar("csgor_assist_maxpoints", "5", FCVAR_NONE, "How much points for an assist^n(MAXIMUM)", true, 0.0, true, 100.0 );
	bind_pcvar_num(pcvar, g_iCvars[iAMaxPoints]);
	
	pcvar = create_cvar("csgor_mvp_minpoints", "20", FCVAR_NONE, "How much points the MVP receive^n(MINIMUM)", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iMVPMinPoints]);
	
	pcvar = create_cvar("csgor_mvp_maxpoints", "30", FCVAR_NONE, "How much points the MVP receive^n(MAXIMUM)", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iMVPMaxPoints]);
	
	pcvar = create_cvar("csgor_mvp_msgtype", "0", FCVAR_NONE, "(0|1|2|3) MVP Message Type^n 0 - No Message is shown^n 1 - Chat Message^n 2 - HUD Message^n 3 - DHUD Message", true, 0.0, true, 3.0 );
	bind_pcvar_num(pcvar, g_iCvars[iMVPMsgType]);
	
	pcvar = create_cvar("csgor_tombola_cost", "50", FCVAR_NONE, "Required points for joining the raffle", true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iTombolaCost]);
	
	pcvar = create_cvar("csgor_register_open", "1", FCVAR_NONE, "(0|1) Possibility to register new accounts^n 0 - New accounts can't be registered^n 1 - New accounts can be registered", true, 0.0, true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iRegOpen]);
	
	pcvar = create_cvar("csgor_best_points", "300", FCVAR_NONE, "How much points receives the best player from a half", true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iBestPoints]);
	
	pcvar = create_cvar("csgor_rangup_bonus", "kc|200", FCVAR_NONE, "Rank Up Bonus^nExample: ^"kkccc|300^". The player will get: 2 keys and 3 cases and 300 points^nMinimum value: ^"|^" - the player don't receive anything. ^"|10^" - get 10 points. ^"k|^" - get 1 key. ^"c|^" - get 1 case" );
	bind_pcvar_string(pcvar, g_iCvars[szRankUpBonus], charsmax(g_iCvars[szRankUpBonus]));
	
	pcvar = create_cvar("csgor_return_percent", "10", FCVAR_NONE, "When destroying the skins, the player receives points.^n1 / value = how much points the player receives", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iReturnPercent]);
	
	pcvar = create_cvar("csgor_drop_type", "1", FCVAR_NONE, "Drop type^n0 - drop cases and keys; 1 - drop only cases, the keys needs to be bought", true, 0.0, true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iDropType]);
	
	pcvar = create_cvar("csgor_key_price", "250", FCVAR_NONE, "Key Price^nOnly if cvar ^"csgor_drop_type^" is ^"1^"", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iKeyPrice]);
	
	pcvar = create_cvar("csgor_tombola_timer", "180", FCVAR_NONE, "Every X seconds the raffle takes place.^n 1 minute = 60 seconds", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iTombolaTimer]);
	
	pcvar = create_cvar("csgor_jackpot_timer", "120", FCVAR_NONE, "After how many seconds the Jackpot starts.^n 1 minute = 60 seconds", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iJackpotTimer]);
	
	pcvar = create_cvar("csgor_competitive_mode", "1", FCVAR_NONE, "(0|1) Two halfs each of 15 rounds are played.^nAfter the first half, the teams are changing + round restart.^nAfter the second half, map is changing.^nPay attention! This needs ^"mapcycle.txt^" configured right!", true, 0.0, true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iCompetitive]);
	
	pcvar = create_cvar("csgor_warmup_duration", "60", FCVAR_NONE, "WarmUp Time", true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iWarmUpDuration]);
	
	pcvar = create_cvar("csgor_show_dropcraft", "1", FCVAR_NONE, "(0|1) Show other player's drop.^n0 - Show the drop only to the beneficiary^n1 - Show the drop to all palyers.", true, 0.0, true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iShowDropCraft]);
	
	pcvar = create_cvar("csgor_item_cost_multiplier", "20", FCVAR_NONE, "The quota by which the minimum price of the key / box is multiplied to get the MAXIMUM price", true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iCostMultiplier]);
	
	pcvar = create_cvar("csgor_bonus_time", "24", FCVAR_NONE, "After how long the player can receive the bonus again?^nValue must be in hours.", true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iTimeDelete]);

	pcvar = create_cvar("csgor_prune_promocodes", "7", FCVAR_NONE, "The time interval when the used promocode will be reset.^nRecommended value to be greater than 1", true, 0.0 );
	bind_pcvar_num(pcvar, g_iCvars[iPromoTime]);
	
	pcvar = create_cvar("csgor_roulette_cooldown", "300", FCVAR_NONE, "The interval when the roulette starts again^nThe value needs to be in seconds.^nIt's recommended that the value can be divided by 60", true, 1.0, false );
	bind_pcvar_float(pcvar, g_iCvars[flRouletteCooldown]);
	
	pcvar = create_cvar("csgor_chattag_cost", "800", FCVAR_NONE, "The price of a chat prefix", true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iChatTagPrice]);
	
	pcvar = create_cvar("csgor_chattag_color_cost", "500", FCVAR_NONE, "The price of a color for the chat prefix", true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iChatTagColorPrice]);

	pcvar = create_cvar("csgor_silenced_weap_type", "1", FCVAR_NONE, "(0|1) Weapons with silencer will have damage similar to that of CS:GO's ones ( M4A1-S ; USP-S ).", true, 0.0, true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iSilentWeapDamage]);

	pcvar = create_cvar("csgor_respawn_enable", "0", FCVAR_NONE, "(0|1) Respawn Mode", true, 0.0, true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iRespawn]);
	
	pcvar = create_cvar("csgor_respawn_delay", "3", FCVAR_NONE, "How much seconds till player will respawn. If ^"csgor_respawn_enable^" is ^"1^".");
	bind_pcvar_num(pcvar, g_iCvars[iRespawnDelay]);
	
	pcvar = create_cvar("csgor_dropchance", "85", FCVAR_NONE, "Chance of receiving a drop^nBetween 0 and 99^nThe higher the number, the less often you receive a drop", true, 0.0, true, 99.0 );
	bind_pcvar_num(pcvar, g_iCvars[iDropChance]);
	
	pcvar = create_cvar("csgor_craft_cost", "10", FCVAR_NONE, "How many scraps do player need to create a rare skin", true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iCraftCost]);
	
	pcvar = create_cvar("csgor_craft_stattrack_cost", "30", FCVAR_NONE, "How many scraps do player need to create a StatTrack skin?", true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iStatTrackCost]);

	pcvar = create_cvar("csgor_case_min_cost", "100", FCVAR_NONE, "The minimum price for a box put up for sale", true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iCaseMinCost]);
	
	pcvar = create_cvar("csgor_key_min_cost", "100", FCVAR_NONE, "The minimum price for a key put up for sale", true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iKeyMinCost]);
	
	pcvar = create_cvar("csgor_wait_for_place", "30", FCVAR_NONE, "How many seconds do you have to wait until you can place a new ad", true, 1.0 );
	bind_pcvar_num(pcvar, g_iCvars[iWaitForPlace]);
	
	pcvar = create_cvar("csgor_freezetime", "2", FCVAR_NONE, "Players freezetime ( exepct when teams are changing and end map )", true, 0.0);
	bind_pcvar_num(pcvar, g_iCvars[iFreezetime]);

	pcvar = create_cvar("csgor_startmoney", "850", FCVAR_NONE, "Players start money", true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iStartMoney]);

	pcvar = create_cvar("csgor_preview_time", "7", FCVAR_NONE, "How much time a player can preview a skin?", true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iCPreview]);

	pcvar = create_cvar("csgor_fast_load", "1", FCVAR_NONE, "Fast resources load for players", .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iFastLoad]);

	pcvar = create_cvar("csgor_grenade_shortthrow_velocity", "0.50", FCVAR_NONE, "Velocity ( in floating value ) of a grenade when it's in short throw mode.");
	bind_pcvar_float(pcvar, g_iCvars[flShortThrowVelocity]);

	pcvar = create_cvar("csgor_enable_roundend_sounds", "1", FCVAR_NONE, "(0|1) Enable / Disable Round End sounds.", true, 0.0, true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iRoundEndSounds]);

	pcvar = create_cvar("csgor_show_copyright", "1", FCVAR_NONE, "(0|1) Show / Hide Copyright Information ( Plugin Author )", true, 0.0, true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iCopyRight]);

	pcvar = create_cvar("csgor_custom_chat", "1", FCVAR_NONE, "(0|1) Enable / Disable Mod's custom chat ( Chat rank, chat prefix, etc )", true, 0.0, true, 1.0);
	bind_pcvar_num(pcvar, g_iCvars[iCustomChat]);

	pcvar = create_cvar("csgor_antispam_drop", "1", FCVAR_NONE, "(0|1) Enable / Disable anti spam in chat while opening / crafting skins.^n ATTENTION! If ^"csgor_show_dropcraft^" is ^"1^" anti spam is always active.", true, 0.0, true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iAntiSpam]);
	
	pcvar = create_cvar("csgor_bonus_random_range", "1 10 70 93", FCVAR_NONE, "(0|∞) Drop range for bonuses in the bonus menu.^nFirst two values: Min | Max for Cases, Dusts, Points drop.^nLast two values: Min | Max for Skins drop.", true, 0.0)
	bind_pcvar_string(pcvar, g_iCvars[szBonusValues], charsmax(g_iCvars[szBonusValues]))

	pcvar = create_cvar("csgor_bonus_check_type", "0", FCVAR_NONE, "(0|1) Bonus check type.^n0 - By IP^n1 - By SteamID", true, 0.0, true, 1.0)
	bind_pcvar_num(pcvar, g_iCvars[iCheckBonusType])

	AutoExecConfig(true, "csgo_remake", "csgor" );
	
	register_cvar("csgore_version", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY);

	register_dictionary("csgor_language.txt");
	
	g_Msg_SayText = get_user_msgid("SayText");
	g_Msg_StatusIcon = get_user_msgid("StatusIcon");
	g_Msg_DeathMsg = get_user_msgid("DeathMsg");
	register_message(g_Msg_SayText, "Message_SayText");
	register_clcmd("say", "hook_say");
	register_clcmd("say_team", "hook_sayteam");
	register_message(g_Msg_DeathMsg, "Message_DeathMsg");
	register_event("HLTV", "ev_NewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "event_Game_Restart", "a", "2=#Game_will_restart_in");
	register_event("TextMsg", "event_Game_Commencing", "a", "2&#Game_C");
	register_event("SendAudio", "ev_RoundWon_T", "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "ev_RoundWon_CT", "a", "2=%!MRAD_ctwin");
	register_event(EVENT_SVC_INTERMISSION, "ev_Intermission", "a");

	register_forward(FM_PlaybackEvent, "FM_Hook_PlayBackEvent_Pre");
	register_forward(FM_PlaybackEvent, "FM_Hook_PlayBackEvent_Primary_Pre");

	for ( new i; i < sizeof(GrenadeName); i++ )
	{
		RegisterHam(Ham_Weapon_PrimaryAttack, GrenadeName[i], "Ham_GrenadePrimaryAttack_Pre");
		RegisterHam(Ham_Weapon_SecondaryAttack, GrenadeName[i], "Ham_GrenadeSecondaryAttack_Pre");
	}

	for(new i = 0; i < sizeof(g_szWeaponEntName); i++)
	{
		RegisterHam(Ham_Item_Deploy, g_szWeaponEntName[i], "Ham_Item_Deploy_Post", 1);
		RegisterHam(Ham_CS_Item_CanDrop, g_szWeaponEntName[i], "Ham_Item_Can_Drop_Pre");
		RegisterHam(Ham_CS_Weapon_SendWeaponAnim, g_szWeaponEntName[i], "HamF_CS_Weapon_SendWeaponAnim_Post", 1);
	}

	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_m4a1", "Ham_Weapon_Secondary_Pre");
	for (new i; i < sizeof(TraceBullets); i++)
	{
		RegisterHam(Ham_TraceAttack, TraceBullets[i], "HamF_TraceAttack_Post", 1);
	}

	RegisterHam(Ham_Spawn, "player", "Ham_Player_Spawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "Ham_Take_Damage_Post", 1);
	RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Pre"); 
	RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", 1);

	register_forward(FM_ClientUserInfoChanged, "FM_ClientUserInfoChanged_Pre");
	register_forward(FM_ClientUserInfoChanged, "FM_ClientUserInfoChanged_ClientWeap_Pre");

	register_event("DeathMsg", "ev_DeathMsg", "ae", "1>0");
	register_event("Damage", "ev_Damage", "be", "2!0", "3=0", "4!0");

	p_Freezetime = get_cvar_pointer("mp_freezetime");
	p_StartMoney = get_cvar_pointer("mp_startmoney");
	pNextMap = get_cvar_pointer("amx_nextmap");

	g_MsgSync = CreateHudSyncObj();
	g_WarmUpSync = CreateHudSyncObj();

	g_iMaxPlayers = get_maxplayers();

	#if defined HUD_POS
	register_clcmd("say /hudpos_menu", "clcmd_say_hudpos");
	#endif

	register_clcmd("say /reg", "clcmd_say_reg");
	register_clcmd("say /menu", "clcmd_say_menu");
	register_concmd("inventory", "clcmd_say_inventory");
	register_concmd("opencase", "clcmd_say_opencase");
	register_concmd("dustbin", "clcmd_say_dustbin");
	register_concmd("market", "clcmd_say_market");
	register_concmd("gift", "clcmd_say_gifttrade");
	register_concmd("trade", "clcmd_say_gifttrade");
	register_concmd("games", "clcmd_say_games");
	register_clcmd("preview", "clcmd_say_preview");
	register_clcmd("say /skin", "clcmd_say_skin");
	register_clcmd("say /accept", "clcmd_say_accept");
	register_clcmd("say /deny", "clcmd_say_deny");
	register_clcmd("say /acceptcoin", "clcmd_say_accept_coin");
	register_clcmd("say /denycoin", "clcmd_say_deny_coin");
	register_clcmd("say /bonus", "clcmd_say_bonus");
	register_clcmd("inspect", "inspect_weapon");

	register_impulse(100, "inspect_weapon");

	if (g_iCvars[iOverrideMenu])
	{
		register_clcmd("chooseteam", "clcmd_chooseteam");
	}

	register_concmd("UserPassword", "concmd_password");
	register_concmd("ChatTag", "concmd_chattag");
	register_concmd("ItemPrice", "concmd_itemprice");
	register_concmd("Promocode", "concmd_promocode");
	register_concmd("BetRed", "concmd_betred");
	register_concmd("BetWhite", "concmd_betwhite");
	register_concmd("BetYellow", "concmd_betyellow");
	
	g_iCvars[iCmdAccess] = create_cvar("csgor_commands_access", "a", FCVAR_NONE, "Access flags for admin commands.^nMaximum 9 flags.");
	new Flags[10];
	get_pcvar_string(g_iCvars[iCmdAccess], Flags, charsmax(Flags));
	new Access = read_flags(Flags);
	register_concmd("amx_givepoints", "concmd_givepoints", Access, "<Name> <Amount>");
	register_concmd("amx_givecases", "concmd_givecases", Access, "<Name> <Amount>");
	register_concmd("amx_givekeys", "concmd_givekeys", Access, "<Name> <Amount>");
	register_concmd("amx_givedusts", "concmd_givedusts", Access, "<Name> <Amount>");
	register_concmd("amx_setskins", "concmd_giveskins", Access, "<Name> <SkinID> <Amount>");
	register_concmd("amx_give_all_skins", "concmd_give_all_skins", Access, "<Name>");
	register_concmd("amx_setrank", "concmd_setrank", Access, "<Name> <Rank ID>");
	register_concmd("amx_finddata", "concmd_finddata", Access, "<Name>");
	register_concmd("amx_resetdata", "concmd_resetdata", Access, "<Name> <Mode>");
	register_concmd("amx_change_pass", "concmd_changepass", Access, "<Name> <New Password>");
	register_concmd("csgor_getinfo", "concmd_getinfo", Access, "<Type> <Index>");
	register_concmd("amx_nick_csgo", "concmd_nick", Access, "<Name> <New Name>");
	register_concmd("amx_skin_index", "concmd_skin_index", Access, "<Skin Name>");

	set_task(2.0, "DetectSaveType");
}

public DetectSaveType()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "DetectSaveType()")
	#endif

	switch(g_iCvars[iSaveType])
	{
		case NVAULT:
		{
			g_Vault = nvault_open("csgor_remake");
			if (g_Vault == INVALID_HANDLE)
			{
				set_fail_state("%s Could not open file csgo_remake.vault.", CSGO_TAG);
			}

			g_nVault = nvault_open("bonus_vault");
			if(g_nVault == INVALID_HANDLE)
			{
				set_fail_state("%s Error opening bonus_vault", CSGO_TAG);
			}
			
			g_pVault = nvault_open("promocode_vault");
			if(g_pVault == INVALID_HANDLE )
			{
				set_fail_state("%s Error opening promocode_vault", CSGO_TAG);
			}

			g_sVault = nvault_open("stattrack_vault");
			if(g_sVault == INVALID_HANDLE )
			{
				set_fail_state("%s Error opening stattrack_vault", CSGO_TAG);
			}
		}
		case MYSQL:
		{
			g_hSqlTuple = SQL_MakeDbTuple(g_iCvars[szSqlHost], g_iCvars[szSqlUsername], g_iCvars[szSqlPassword], g_iCvars[szSqlDatabase]);

			new iError;
			g_iSqlConnection = SQL_Connect(g_hSqlTuple, iError, g_szSqlError, charsmax(g_szSqlError));

			if(g_iSqlConnection == Empty_Handle)
			{
				log_to_file("csgo_remake_errors.log", "CSGO REMAKE Failed to connect to database. Make sure databse settings are right!");
				SQL_FreeHandle(g_iSqlConnection);
				return;
			}

			new szQueryData[600];
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
				`Promocode` INT(2) NOT NULL,\
				PRIMARY KEY(ID, Name));");

			new Handle:iQueries = SQL_PrepareQuery(g_iSqlConnection, szQueryData);
		
			if(!SQL_Execute(iQueries))
			{
				SQL_QueryError(iQueries, g_szSqlError, charsmax(g_szSqlError));
				log_amx(g_szSqlError);
			}

			formatex(szQueryData, charsmax(szQueryData), "SELECT `SteamID` FROM `csgor_data`");

			iQueries = SQL_PrepareQuery(g_iSqlConnection, szQueryData);
		
			if(!SQL_Execute(iQueries))
			{
				SQL_QueryError(iQueries, g_szSqlError, charsmax(g_szSqlError));

				if(containi(g_szSqlError, "Unknown column") != -1)
				{
					formatex(szQueryData, charsmax(szQueryData), "ALTER TABLE `csgor_data` ADD `SteamID` varchar(32) NOT NULL AFTER `Name`, \
						ADD `Last IP` varchar(19) NOT NULL AFTER `SteamID`;");

					iQueries = SQL_PrepareQuery(g_iSqlConnection, szQueryData);
			
					if(!SQL_Execute(iQueries))
					{
						SQL_QueryError(iQueries, g_szSqlError, charsmax(g_szSqlError));
						log_amx(g_szSqlError);
					}
				}
			}

			formatex(szQueryData, charsmax(szQueryData), "CREATE TABLE IF NOT EXISTS `csgor_skins` \
				(`ID` INT NOT NULL AUTO_INCREMENT,\
				`Name` VARCHAR(32) NOT NULL,\
				`Skins` VARCHAR(%d) NOT NULL,\
				`Stattrack Skins` VARCHAR(%d) NOT NULL,\
				`Stattrack Kills` VARCHAR(%d) NOT NULL,\
				`Selected Stattrack` VARCHAR(%d) NOT NULL,\
				`Selected Skins` VARCHAR(%d) NOT NULL,\
				PRIMARY KEY(ID, Name));", (MAX_SKINS * 3 + 94), (MAX_SKINS * 3 + 94), (MAX_SKINS * 3 + 94), 150, 150);

			iQueries = SQL_PrepareQuery(g_iSqlConnection, szQueryData);

			if(!SQL_Execute(iQueries))
			{
				SQL_QueryError(iQueries, g_szSqlError, charsmax(g_szSqlError));
				log_amx(g_szSqlError);
				return;
			}

			SQL_FreeHandle(iQueries);
		}
	}
}

public plugin_precache()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "plugin_precache()")
	#endif

	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)

	RegisterForwards();

	precache_sound(g_szTWin);
	precache_sound(g_szCTWin);
	precache_sound(g_szCaseOpen);
	precache_sound(g_szBombPlanting);
	precache_sound(g_szBombDefusing);

	new iFile = fopen(g_szConfigFile, "rt");
	if (!iFile)
	{
		set_fail_state("%s Could not open file csgor_configs.ini .", CSGO_TAG);
	}

	new szBuffer[428], FileSections:iSection, iLine;
	new szLeftpart[MAX_SKIN_NAME], szRightPart[24], iWeaponID[4], szNewModel[128], iDefaultSubmodel[8];
	new weaponid[4], szWeaponName[MAX_SKIN_NAME], szWeaponModel[MAX_SKIN_NAME], weaponP[MAX_SKIN_NAME], weapontype[4], weaponchance[8], weaponcostmin[8], weapondusts[8], weaponsubmodel[8], szLocked[3];
	new szPromocode[32], szPromocode_usage[6], szPromocode_gift[4];
	new szChatSkip[20]
	new Weapons[EnumSkinsMenuInfo];
	new MenuInfo[EnumDynamicMenu];
	new iEnd = -1;

	while (!feof(iFile))
	{
		fgets(iFile, szBuffer, charsmax(szBuffer));
		trim(szBuffer);
		iLine += 1;
		if (!(!szBuffer[0] || szBuffer[0] == ';'))
		{
			if (szBuffer[0] == '[')
			{
				iSection++;
				continue;
			}
			switch (iSection)
			{
				case secRanks:
				{
					parse(szBuffer, szLeftpart, charsmax(szLeftpart), szRightPart, charsmax(szRightPart));
					ArrayPushString(g_aRankName, szLeftpart);
					ArrayPushCell(g_aRankKills, str_to_num(szRightPart));
					g_iRanksNum += 1;
				}
				case secDefaultModels:
				{
					parse(szBuffer, iWeaponID, charsmax(iWeaponID), szNewModel, charsmax(szNewModel), iDefaultSubmodel, charsmax(iDefaultSubmodel));

					new id = str_to_num(iWeaponID);
					copy(defaultModels[id], charsmax(defaultModels[]), szNewModel);
					ArrayPushCell(g_aDefaultSubmodel, str_to_num(iDefaultSubmodel));
					defaultCount++;

					if(szNewModel[0] == '-')
						continue;

					if (file_exists(szNewModel))
					{
						precache_model(szNewModel);
					}
					else
					{
						log_to_file("csgo_remake_errors.log" ,"%s Can't find %s model on DEFAULT iSection. Line %i", CSGO_TAG, szNewModel, iLine);
						continue
					}
				}
				case secSkins:
				{
					parse(szBuffer, weaponid, charsmax(weaponid), szWeaponName, charsmax(szWeaponName), szWeaponModel, charsmax(szWeaponModel), weaponP, charsmax(weaponP), weaponsubmodel, charsmax(weaponsubmodel), weapontype, charsmax(weapontype), weaponchance, charsmax(weaponchance), weaponcostmin, charsmax(weaponcostmin), weapondusts, charsmax(weapondusts), szLocked, charsmax(szLocked));

					if (file_exists(szWeaponModel))
					{
						precache_model(szWeaponModel);
					}
					else
					{
						log_to_file("csgo_remake_errors.log" ,"%s Can't find %s v_model for SKINS. Param: 3. Line %i", CSGO_TAG, szWeaponModel, iLine);
						continue
					}

					if (16 < strlen(weaponP))
					{
						g_bSkinHasModelP[g_iSkinsNum] = true;
						precache_model(weaponP);
					}

					ArrayPushCell(g_aSkinWeaponID, str_to_num(weaponid));
					ArrayPushString(g_aSkinName, szWeaponName);
					ArrayPushString(g_aSkinModel, szWeaponModel);
					ArrayPushString(g_aSkinModelP, weaponP);
					ArrayPushCell(g_aSkinSubModel, str_to_num(weaponsubmodel));
					ArrayPushString(g_aSkinType, weapontype);
					ArrayPushCell(g_aSkinChance, str_to_num(weaponchance));
					ArrayPushCell(g_aSkinCostMin, str_to_num(weaponcostmin));
					ArrayPushCell(g_aDustsSkin, str_to_num(weapondusts));
					ArrayPushCell(g_aLockSkin, str_to_num(szLocked));

					switch (weapontype[0])
					{
						case 'c':
						{
							ArrayPushCell(g_aCraftSkin, g_iSkinsNum);
							g_iCraftSkinNum += 1;
						}
						case 'd':
						{
							ArrayPushCell(g_aDropSkin, g_iSkinsNum);
							g_iDropSkinNum += 1;
						}
					}

					g_iSkinsNum += 1;
				}
				case secPromocodes:
				{
					parse(szBuffer, szPromocode, charsmax(szPromocode), szPromocode_usage, charsmax(szPromocode_usage), szPromocode_gift, charsmax(szPromocode_gift));
					ArrayPushString(g_aPromocodes, szPromocode);
					ArrayPushCell(g_aPromocodesUsage , str_to_num(szPromocode_usage));
					ArrayPushString(g_aPromocodesGift, szPromocode_gift);
					g_iPromoNum += 1;						
				}
				case secSortedMenu:
				{
					parse(szBuffer, Weapons[ItemName], charsmax(Weapons[ItemName]), Weapons[ItemID], charsmax(Weapons[ItemID]));
					ArrayPushArray(g_aSkinsMenu, Weapons);
				}
				case secDynamicMenu:
				{
					parse(szBuffer, MenuInfo[szMenuName], charsmax(MenuInfo[szMenuName]), MenuInfo[szMenuCMD], charsmax(MenuInfo[szMenuCMD]));
					ArrayPushArray(g_aDynamicMenu, MenuInfo);
				}
				case secSkipChat:
				{
					parse(szBuffer, szChatSkip, charsmax(szChatSkip))
					ArrayPushString(g_aSkipChat, szChatSkip);
				}
			}

			ExecuteForward(g_iForwards[ file_buffer ], g_iForwardResult, szBuffer, iSection, iLine);
		}
	}
	iEnd = 1;
	fclose(iFile);
	
	precache_sound(DRYFIRE_PISTOL);
	precache_sound(DRYFIRE_RIFLE);
	precache_sound(GLOCK18_BURST_SOUND);
	precache_sound(GLOCK18_SHOOT_SOUND);
	precache_sound(AK47_SHOOT_SOUND);
	precache_sound(AUG_SHOOT_SOUND);
	precache_sound(AWP_SHOOT_SOUND);
	precache_sound(DEAGLE_SHOOT_SOUND);
	precache_sound(ELITE_SHOOT_SOUND);
	precache_sound(CLARION_BURST_SOUND);
	precache_sound(CLARION_SHOOT_SOUND);
	precache_sound(FIVESEVEN_SHOOT_SOUND);
	precache_sound(G3SG1_SHOOT_SOUND);
	precache_sound(GALIL_SHOOT_SOUND);
	precache_sound(M3_SHOOT_SOUND);
	precache_sound(XM1014_SHOOT_SOUND);
	precache_sound(M4A1_SILENT_SOUND);
	precache_sound(M4A1_SHOOT_SOUND);
	precache_sound(M249_SHOOT_SOUND);
	precache_sound(MAC10_SHOOT_SOUND);
	precache_sound(MP5_SHOOT_SOUND);
	precache_sound(P90_SHOOT_SOUND);
	precache_sound(P228_SHOOT_SOUND);
	precache_sound(SCOUT_SHOOT_SOUND);
	precache_sound(SG550_SHOOT_SOUND);
	precache_sound(SG552_SHOOT_SOUND);
	precache_sound(TMP_SHOOT_SOUND);
	precache_sound(UMP45_SHOOT_SOUND);
	precache_sound(USP_SHOOT_SOUND);
	precache_sound(USP_SILENT_SOUND);
	
	set_task(0.1, "precache_mess", iEnd);
}

public precache_mess(iEnd)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "precache_mess()")
	#endif

	log_amx("CS:GO Remake by Shadows Adi (v%s).", VERSION);
	ExecuteForward(g_iForwards[file_executed], g_iForwardResult, iEnd);
}

public fw_PrecacheEvent_Post(iType, const szEvent[])
{
	new iTemp
	for(new i; i < sizeof(g_szGEvents); i++)
	{
		if (equali(szEvent, g_szGEvents[i]))
		{
			iTemp = get_orig_retval()
			g_bGEventID[iTemp] = true
		}
	}
}

RegisterForwards()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "RegisterForwards()")
	#endif

	g_iForwards[ user_log_in ] = CreateMultiForward("csgor_user_logging_in", ET_IGNORE, FP_CELL);
	g_iForwards[ user_log_out ] = CreateMultiForward("csgor_user_logging_out", ET_IGNORE, FP_CELL);
	g_iForwards[ user_register ] = CreateMultiForward("csgor_user_register", ET_IGNORE, FP_CELL);
	g_iForwards[ user_pass_fail ] = CreateMultiForward("csgor_user_password_failed", ET_IGNORE, FP_CELL, FP_CELL);
	g_iForwards[ user_assist ] = CreateMultiForward("csgor_user_assist", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	g_iForwards[ user_mvp ] = CreateMultiForward("csgor_user_mvp", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_iForwards[ user_case_opening ] = CreateMultiForward("csgor_user_case_open", ET_IGNORE, FP_CELL);
	g_iForwards[ user_craft ] = CreateMultiForward("csgor_user_craft", ET_IGNORE, FP_CELL);
	g_iForwards[ user_level_up ] = CreateMultiForward("csgor_user_levelup", ET_IGNORE, FP_CELL, FP_STRING, FP_CELL);
	g_iForwards[ file_executed ] = CreateMultiForward("csgor_on_configs_executed", ET_IGNORE, FP_CELL);
	g_iForwards[ user_drop ] = CreateMultiForward("csgor_on_user_drop", ET_IGNORE, FP_CELL);
	g_iForwards[ file_buffer ] = CreateMultiForward("csgor_read_configuration_data", ET_IGNORE, FP_STRING, FP_CELL, FP_CELL);
}

public plugin_cfg()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "plugin_Cfg()")
	#endif

	new Float:timer = float(g_iCvars[iTombolaTimer]);
	set_task(timer, "task_TombolaRun", TASK_TOMBOLA, .flags = "b");
	g_iNextTombolaStart = g_iCvars[iTombolaTimer] + get_systime();
	for(new i; i < sizeof(g_iRoulleteNumbers); i++ )
	{
		formatex(g_iRoulleteNumbers[i], charsmax(g_iRoulleteNumbers[]), "\w0");
	}
}

public plugin_natives()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "plugin_natives()")
	#endif

	get_configsdir(g_szCfgDir, charsmax(g_szCfgDir));
	formatex(g_szConfigFile, charsmax(g_szConfigFile), "%s/csgor_configs.ini", g_szCfgDir);
	if (!file_exists(g_szConfigFile))
		set_fail_state("%s File not found: ...%s", CSGO_TAG, g_szConfigFile);
	
	register_library("csgo_remake");
	g_aRankName = ArrayCreate(MAX_RANK_NAME);
	g_aRankKills = ArrayCreate(1);
	g_aDefaultSubmodel = ArrayCreate(1);
	g_aSkinWeaponID = ArrayCreate(1);
	g_aSkinName = ArrayCreate(48);
	g_aSkinModel = ArrayCreate(MAX_SKIN_NAME);
	g_aSkinModelP = ArrayCreate(48);
	g_aSkinSubModel = ArrayCreate(1);
	g_aSkinType = ArrayCreate(2);
	g_aSkinChance = ArrayCreate(1);
	g_aSkinCostMin = ArrayCreate(1);
	g_aDropSkin = ArrayCreate(1);
	g_aCraftSkin = ArrayCreate(1);
	g_aDustsSkin = ArrayCreate(1);
	g_aLockSkin = ArrayCreate(1);
	g_aTombola = ArrayCreate(1);
	g_aJackpotSkins = ArrayCreate(1);
	g_aJackpotUsers = ArrayCreate(1);
	g_aPromocodes = ArrayCreate(32);
	g_aPromocodesUsage = ArrayCreate(1);
	g_aPromocodesGift = ArrayCreate(2);
	g_aSkinsMenu = ArrayCreate(EnumSkinsMenuInfo);
	g_aDynamicMenu = ArrayCreate(EnumDynamicMenu);
	g_aSkipChat = ArrayCreate(20);
	register_native("csgor_get_user_points", "native_get_user_points");
	register_native("csgor_set_user_points", "native_set_user_points");
	register_native("csgor_get_user_cases", "native_get_user_cases");
	register_native("csgor_set_user_cases", "native_set_user_cases");
	register_native("csgor_get_user_keys", "native_get_user_keys");
	register_native("csgor_set_user_keys", "native_set_user_keys");
	register_native("csgor_get_user_dusts", "native_get_user_dusts");
	register_native("csgor_set_user_dusts", "native_set_user_dusts");
	register_native("csgor_get_user_rank", "native_get_user_rank");
	register_native("csgor_set_user_rank", "native_set_user_rank");
	register_native("csgor_get_user_skins", "native_get_user_skins");
	register_native("csgor_set_user_all_skins", "native_set_user_all_skins");
	register_native("csgor_set_user_skins", "native_set_user_skins");
	register_native("csgor_get_skins_num", "native_get_skins_num");
	register_native("csgor_get_skin_name", "native_get_skin_name");
	register_native("csgor_is_user_logged", "native_is_user_logged");
	register_native("csgor_is_half_round", "native_is_half_round");
	register_native("csgor_is_last_round", "native_is_last_round");
	register_native("csgor_is_good_item", "native_is_good_item");
	register_native("csgor_is_item_skin", "native_is_item_skin");
	register_native("csgor_is_user_registered", "native_is_user_registered");
	register_native("csgor_is_warmup", "native_is_warmup");
	register_native("csgor_get_skin_index", "native_get_skin_index");
	register_native("csgor_ranks_num", "native_ranks_num");
	register_native("csgor_is_skin_stattrack", "native_is_skin_stattrack");
	register_native("csgor_get_user_statt_skins", "native_get_user_statt_skins");
	register_native("csgor_set_user_statt_skins", "native_set_user_statt_skins");
	register_native("csgor_get_user_statt_kills", "native_get_user_stattrack_kills");
	register_native("csgor_set_user_statt_kills", "native_set_user_stattrack_kills");
	register_native("csgor_get_user_stattrack", "native_get_user_stattrack");
	register_native("csgor_set_random_stattrack", "native_set_random_stattrack");
	register_native("csgor_get_user_body", "native_csgo_get_user_body");
	register_native("csgor_get_config_location", "native_csgo_get_config_location");
	register_native("csgor_get_user_skin", "native_csgo_get_user_skin");
	register_native("csgor_get_database_data", "native_csgo_get_database_data");
	register_native("csgor_get_rank_name", "native_get_rank_name")
}

public plugin_end()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "plugin_end() end of the plugin")
	#endif

	ArrayDestroy(g_aRankName);
	ArrayDestroy(g_aRankKills);
	ArrayDestroy(g_aDefaultSubmodel);
	ArrayDestroy(g_aSkinWeaponID);
	ArrayDestroy(g_aSkinName);
	ArrayDestroy(g_aSkinModel);
	ArrayDestroy(g_aSkinModelP);
	ArrayDestroy(g_aSkinSubModel);
	ArrayDestroy(g_aSkinType);
	ArrayDestroy(g_aSkinChance);
	ArrayDestroy(g_aSkinCostMin);
	ArrayDestroy(g_aDropSkin);
	ArrayDestroy(g_aCraftSkin);
	ArrayDestroy(g_aDustsSkin);
	ArrayDestroy(g_aLockSkin)
	ArrayDestroy(g_aPromocodes);
	ArrayDestroy(g_aPromocodesUsage);
	ArrayDestroy(g_aPromocodesGift);
	ArrayDestroy(g_aSkinsMenu);
	ArrayDestroy(g_aDynamicMenu);
	ArrayDestroy(g_aSkipChat)
	switch(g_iCvars[iSaveType])
	{
		case NVAULT:
		{
			if (g_iCvars[iPruneDays])
			{
				nvault_prune(g_sVault, 0, get_systime() - ((60 * 60 * 24) * g_iCvars[iPruneDays]));
				nvault_prune(g_Vault, 0, get_systime() - ((60 * 60 * 24) * g_iCvars[iPruneDays]));
			}
			if(g_iCvars[iTimeDelete])
			{
				nvault_prune(g_nVault,0,get_systime() - (60 * 60 * g_iCvars[iTimeDelete]));
			}
			if(g_iCvars[iPromoTime])
			{
				nvault_prune(g_pVault,0,get_systime() - ((60 * 60 * 24) * g_iCvars[iPromoTime]));
			}
			nvault_close(g_Vault);
			nvault_close(g_nVault);
			nvault_close(g_pVault);
			nvault_close(g_sVault);
		}
		case MYSQL:
		{
			SQL_FreeHandle(g_hSqlTuple);
			SQL_FreeHandle(g_iSqlConnection);
		}
	}
}

public client_connect(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "client_connect()")
	#endif

	if(g_iCvars[iFastLoad])
	{
		client_cmd(id, "fs_lazy_precache 1");
	}
}

public client_putinserver(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "client_putinserver()");
	#endif

	DestroyTask(id + TASK_INFO);

	get_user_name(id, g_szName[id], charsmax(g_szName[]));
	get_user_authid(id, g_szSteamID[id], charsmax(g_szSteamID[]));
	get_user_ip(id, g_szUserLastIP[id], charsmax(g_szUserLastIP[]) , 1);
	
	if(g_iCvars[iCopyRight])
	{
		set_task(15.0, "task_Info", id + TASK_INFO);
	}

	ResetData(id);
}

ResetData(id, bool:bWithoutPassword = false)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "ResetData()")
	#endif

	g_iMostDamage[id] = 0;
	g_iDigit[id] = 0;
	g_iDealDamage[id] = 0;
	arrayset(g_iDamage[id], 0, sizeof(g_iDamage[][]));

	if(!bWithoutPassword)
	{
		g_szUserPassword[id] = "";
		g_szUser_SavedPass[id] = "";
	}
	g_szUserPromocode[id] = "";
	g_iUserPassFail[id] = 0;
	g_bLogged[id] = false;
	g_iUserPoints[id] = 0;
	g_iUserDusts[id] = 0;
	g_iUserKeys[id] = 0;
	g_iUserCases[id] = 0;
	g_iUserKills[id] = 0;
	g_iUserRank[id] = 0;
	g_szUserPrefix[id] = "";
	g_szTemporaryCtag[id] = "";
	g_szUserPrefixColor[id] = "";
	g_iPromoCount[id] = 0;
	g_iRedPoints[id] = 0;
	g_iWhitePoints[id] = 0;
	g_iYellowPoints[id] = 0;
	
	g_bUserSell[id] = false;
	g_iUserSellItem[id] = -1;
	g_iLastPlace[id] = 0;
	
	g_iMenuType[id] = 0;
	
	g_iGiftTarget[id] = 0;
	g_iGiftItem[id] = -1;
	
	g_iTradeTarget[id] = 0;
	g_iTradeItem[id] = -1;
	g_bTradeActive[id] = false;
	g_bTradeAccept[id] = false;
	g_bTradeSecond[id] = false;
	g_iTradeRequest[id] = 0;
	
	g_bCoinflipAccept[id] = false;
	g_iCoinflipTarget[id] = 0;
	g_iCoinflipItem[id] = -1;
	g_bCoinflipActive[id] = false;
	g_iCoinflipRequest[id] = 0;
	g_bCoinflipSecond[id] = false;

	g_bUserPlay[id] = false;
	g_iUserJackpotItem[id] = -1;
	g_bUserPlayJackpot[id] = false;

	for (new iWeaponID = 1; iWeaponID <= CSW_P90; iWeaponID++)
	{
		g_iUserSelectedSkin[id][iWeaponID] = -1;
		g_iStattrackWeap[id][iSelected][iWeaponID] = -1;
		g_iStattrackWeap[id][bStattrack][iWeaponID] = false;
	}
	for (new sid = 0; sid < MAX_SKINS; sid++)
	{
		g_iUserSkins[id][sid] = 0;
		g_iStattrackWeap[id][iWeap][sid] = 0;
		g_iStattrackWeap[id][iKillCount][sid] = 0;
	}

	DestroyTask(id + TASK_HUD);
}

public task_Info(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_Info()")
	#endif

	id -= TASK_INFO;
	if (is_user_connected(id))
	{
		client_print_color(id, print_chat, "^4*^1 Playing ^4%s^1 v. ^3%s^1 powered by ^4%s", CSGO_TAG, VERSION, AUTHOR);
	}
}

public client_disconnected(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "client_disconnected()")
	#endif

	g_iRedPoints[id] = 0;
	g_iWhitePoints[id] = 0;
	g_iYellowPoints[id] = 0;

	ClearPlayerBit(g_bitIsAlive, id);
	g_eEnumBooleans[id][IsChangeNotAllowed] = false;
	ClearPlayerBit(g_bitShortThrow, id);
	if (g_iBombPlanter == id)
	{
		g_iBombPlanter = 0;
	}
	if (g_iBombDefuser == id)
	{
		g_iBombDefuser = 0;
	}

	arrayset(g_iDamage[id], 0, sizeof(g_iDamage[]));
	DestroyTask(id + TASK_SWAP);
	DestroyTask(id + TASK_RESPAWN);
	DestroyTask(id + TASK_INFO);

	if(!is_user_bot(id) && !is_user_hltv(id) && is_user_connected(id))
	{
		client_cmd(id, "fs_lazy_precache 0");

		if(g_bLogged[id])
		{
			_Save(id);
		}
	}

	return PLUGIN_HANDLED;
}

public ev_NewRound()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "ev_NewRound()")
	#endif

	g_iBombPlanter = 0;
	g_iBombDefuser = 0;
	g_bBombExplode = false;
	g_bBombDefused = false;
	arrayset(g_iRoundKills, 0, charsmax(g_iRoundKills));
	arrayset(g_iDealDamage, 0, charsmax(g_iDealDamage));
	if (g_iCvars[iCompetitive] && !g_bWarmUp && get_playersnum() > 1)
	{
		if (!IsHalf() && !IsLastRound())
		{
			client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COMPETITIVE_INFO", g_iStats[iRoundNum], g_iStats[iTeroScore], g_iStats[iCTScore]);
		}
		if (IsLastRound()) 
		{
			set_pcvar_num(p_Freezetime, 10); 
			_ShowBestPlayers();
			DoIntermission();
		}
		if (IsHalf() && !g_bTeamSwap)
		{
			client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_HALF");
			_ShowBestPlayers();
			new Float:delay;
			new iPlayer, iPlayers[MAX_PLAYERS], iNum;
			get_players(iPlayers, iNum, "ch");

			for (new i; i < iNum; i++)
			{
				iPlayer = iPlayers[i];
				if (is_user_connected(iPlayer))
				{
					delay = 0.2 * iPlayer;
					set_task(delay, "task_Delayed_Swap", iPlayer + TASK_SWAP);
				}
			}
			set_task(7.0, "task_Team_Swap");
			g_iStats[iRoundNum] = 16;
		}
	}
	return PLUGIN_HANDLED;
}

public ev_Intermission()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "ev_Intermission()")
	#endif

	if(task_exists(TASK_MAP_END))
	{
		log_to_file("csgo_remake_errors.log", "Double Intermission detected, returning...");
		return;
	}
	set_task(0.1, "task_Map_End", TASK_MAP_END);
}

public task_Map_End()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_Map_End()")
	#endif

	set_pcvar_num(p_Freezetime, g_iCvars[iFreezetime]);
	new bool:CvarExists = cvar_exists("amx_nextmap") ? true : false;
	new szTemp[48];
	SelectMap();
	if(CvarExists)
	{
		formatex(szTemp, charsmax(szTemp), "%s", szNextMap);
	}
	else 
	{
		formatex(szTemp, charsmax(szTemp), "%s", g_iCvars[szNextMapDefault]);
	}
	
	server_cmd("changelevel %s", szTemp);
}

SelectMap()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "SelectMap()")
	#endif

	if(cvar_exists("amx_nextmap"))
	{
		if(pNextMap)
		{
			get_pcvar_string(pNextMap, szNextMap, charsmax(szNextMap));
		}
		client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MAP_END_MAPNAME", szNextMap);
	}
	else
	{
		log_amx("%s cvar ^"amx_nextmap^" doesn't exists, changing map by default to %s", CSGO_TAG, g_iCvars[szNextMapDefault]);
		log_to_file("csgo_remake_errors.log", "%s cvar ^"amx_nextmap^" doesn't exists, changing map by default to %s", CSGO_TAG, g_iCvars[szNextMapDefault]);
	}
}

public task_Delayed_Swap(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_Delayed_Swap()")
	#endif

	id -= TASK_SWAP;
	if (!is_user_alive(id))
	{
		return;
	}

	switch(cs_get_user_team(id))
	{
		case CS_TEAM_T:
		{
			cs_set_user_team(id, CS_TEAM_CT);
		}
		
		case CS_TEAM_CT:
		{
			cs_set_user_team(id, CS_TEAM_T);
		}
	}
}

public task_Team_Swap()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_Team_Swap()")
	#endif

	g_bTeamSwap = true;
	new temp[2];
	temp[0] = g_iStats[iCTScore];
	temp[1] = g_iStats[iTeroScore];
	g_iStats[iTeroScore] = temp[0];
	g_iStats[iCTScore] = temp[1];

	set_pcvar_num(p_Freezetime, g_iCvars[iFreezetime]);
	client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_RESTART");

	server_cmd("sv_restart 1");
}

public bomb_planting(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "bomb_planting()")
	#endif

	new iPlayers[MAX_PLAYERS], iNum, iPlayer;
	get_players(iPlayers, iNum, "ceh", "TERRORIST");
	for (new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		client_cmd(iPlayer, "spk ^"%s^"", g_szBombPlanting);
		client_print_color(iPlayer, print_chat, "^4%s ^3(RADIO): ^4I'm planting the bomb.", g_szName[id]);
	}
}

public bomb_defusing(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "bomb_defusing()")
	#endif

	new iPlayers[MAX_PLAYERS], iNum, iPlayer;
	get_players(iPlayers, iNum, "ceh", "CT");
	for (new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		client_cmd(iPlayer, "spk ^"%s^"", g_szBombDefusing);
		client_print_color(iPlayer, print_chat, "^4%s ^3(RADIO): ^4I'm defusing the bomb.", g_szName[id]);
	}
}

public bomb_explode(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "bomb_explode()")
	#endif

	g_iBombPlanter = id;
	g_bBombExplode = true;
}

public bomb_defused(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "bomb_defused()")
	#endif

	g_iBombDefuser = id;
	g_bBombDefused = true;
}

public ev_RoundWon_T()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "ev_RoundWon_T()")
	#endif

	if(g_iCvars[iRoundEndSounds])
	{
		emit_sound(0, CHAN_AUTO, g_szTWin, VOL_NORM, ATTN_NONE, 0, PITCH_NORM);
	}

	new data[1];
	data[0] = 1;
	g_iStats[iRoundNum] += 1;
	g_iStats[iTeroScore] += 1;

	set_task(1.0, "task_Check_Conditions", 0, data, sizeof(data[]));
}

public ev_RoundWon_CT()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "ev_RoundWon_CT()")
	#endif

	if(g_iCvars[iRoundEndSounds])
	{
		emit_sound(0, CHAN_AUTO, g_szCTWin, VOL_NORM, ATTN_NONE, 0, PITCH_NORM);
	}

	new data[1];
	data[0] = 2;
	g_iStats[iRoundNum] += 1;
	g_iStats[iCTScore] += 1;

	set_task(1.0, "task_Check_Conditions", 0, data, sizeof(data[]));
}

public task_Check_Conditions(data[])
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_Check_Conditions()")
	#endif

	new team = data[0];
	switch (team)
	{
		case 1:
		{
			if (g_bBombExplode)
			{
				_ShowMVP(g_iBombPlanter, 1);
			}
			else
			{
				new top1 = _GetTopKiller(1);
				_ShowMVP(top1, 0);
			}
		}
		case 2:
		{
			if (g_bBombDefused)
			{
				_ShowMVP(g_iBombDefuser, 2);
			}
			else
			{
				new top1 = _GetTopKiller(2);
				_ShowMVP(top1, 0);
			}
		}
	}
	if (IsHalf())
	{
		set_pcvar_num(p_Freezetime, 10);
	}
}

public event_Game_Restart()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "event_Game_Restart()")
	#endif

	logev_Game_Restart();
}

public logev_Game_Restart()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "logev_Game_Restart()")
	#endif

	arrayset(g_iScore, 0, sizeof(g_iScore));
	arrayset(g_iUserMVP, 0, sizeof(g_iUserMVP));
	DestroyTask(TASK_JACKPOT);
	g_bJackpotWork = true;
	g_bCoinflipWork = true;
	set_task(float(g_iCvars[iJackpotTimer]), "task_Jackpot", TASK_JACKPOT, .flags = "b");
	g_iJackpotClose = get_systime() + g_iCvars[iJackpotTimer] ;
}

public event_Game_Commencing()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "event_Game_Commencing()")
	#endif

	logev_Game_Commencing();
}

public logev_Game_Commencing()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "logev_Game_Commencing()")
	#endif

	g_iStats[iRoundNum] = 0;
	g_iStats[iCTScore] = 0;
	g_iStats[iTeroScore] = 0;
	if (!g_iCvars[iCompetitive])
		return PLUGIN_HANDLED;
	
	g_bWarmUp = true;
	set_task(1.0, "task_WarmUp_CD");

	return PLUGIN_CONTINUE;
}

public task_WarmUp_CD()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_WarmUp_CD()")
	#endif

	if (g_iCvars[iWarmUpDuration] > 0)
	{
		set_pcvar_num(p_StartMoney, 16000);
		set_hudmessage(0, 255, 0, -1.00, 0.80, 0, 0.00, 1.10);
		ShowSyncHudMsg(0, g_WarmUpSync, "WarmUp: %d second%s", g_iCvars[iWarmUpDuration] , g_iCvars[iWarmUpDuration] == 1 ? "" : "s");
	}
	else
	{
		g_bWarmUp = false;
		g_iStats[iRoundNum] = 1;
		g_iStats[iCTScore] = 0;
		g_iStats[iTeroScore] = 0;
		set_pcvar_num(p_StartMoney, g_iCvars[iStartMoney]);
		server_cmd("sv_restart 1");
	}
	g_iCvars[iWarmUpDuration]--;
	if(g_bWarmUp)
		set_task(1.0, "task_WarmUp_CD");
}

public FM_ClientUserInfoChanged_Pre(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "fw_FM_ClientUserInfoChanged_()")
	#endif

	if(g_eEnumBooleans[id][IsChangeNotAllowed])
		return FMRES_IGNORED;
	
	static name[] = "name";
	
	new szNewName[32];
	new szOldName[32];
	pev(id, pev_netname, szOldName, charsmax(szOldName));
	
	if (szOldName[0])
	{
		get_user_info(id, name, szNewName, charsmax(szNewName));
		if (!equal(szOldName, szNewName))
		{
			set_user_info(id, name, szOldName);
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CANT_CHANGE_ACC");
			return FMRES_HANDLED;
		}
	}
	return FMRES_IGNORED;
}

public FM_ClientUserInfoChanged_ClientWeap_Pre(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "FM_ClientUserInfoChanged_ClientWeap_Pre()")
	#endif

	new userInfo[6] = "cl_lw";
	new clientValue[2];
	new serverValue[2] = "0";

	if (get_user_info(id, userInfo, clientValue, charsmax(clientValue)))
	{
		set_user_info(id, userInfo, serverValue);

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public Ham_Take_Damage_Post( iVictim, inf, iAttacker, Float:iDamage )
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Ham_Take_Damage_Post()")
	#endif

	if( !is_user_alive(iVictim) || !GetPlayerBit(g_bitIsAlive, iAttacker) || pev_valid(iAttacker) != PDATA_SAFE)
		return HAM_IGNORED;

	new weapon = get_pdata_cbase(iAttacker, OFFSET_ACTIVE_ITEM, XO_PLAYER);
	
	if(pev_valid(iAttacker) != PDATA_SAFE || pev_valid(weapon) != PDATA_SAFE)
		return HAM_IGNORED;
	
	if ( g_iCvars[iSilentWeapDamage] )
	{
		if(weapon == CSW_USP)
		{
			if(cs_get_weapon_silen(weapon))
			{
				SetHamParamFloat(4, iDamage * 1.186);
			}
			return HAM_SUPERCEDE;
		}
	}

	return HAM_IGNORED;
}

public Ham_Player_Spawn_Post(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Ham_Player_Spawn_Post()")
	#endif

	if(!is_user_alive(id))
	{
		return HAM_IGNORED;
	}

	SetPlayerBit(g_bitIsAlive, id);

	if(g_iCvars[iShowHUD])
	{
		set_task(1.0, "task_HUD", id + TASK_HUD);
	}

	set_task(0.2, "task_SetIcon", id + TASK_SET_ICON);
	new weapons[32], numweapons;
	get_user_weapons(id, weapons, numweapons);
	new weaponid;
	for (new i = 0; i < numweapons; i++)
	{
		weaponid = weapons[i];

		if ((1<<weaponid) & NO_REFILL_WEAPONS)
			return HAM_IGNORED;

		ExecuteHamB(Ham_GiveAmmo, id, g_iMaxBpAmmo[weaponid], g_szAmmoType[weaponid], g_iMaxBpAmmo[weaponid]);
	}

	DestroyTask(id + TASK_RESPAWN);

	set_task(0.2, "task_check_name", id + TASK_CHECK_NAME);

	g_iMostDamage[id] = 0;
	arrayset(g_iDamage[id], 0, sizeof(g_iDamage[]));

	if (g_bJackpotWork && !g_bWarmUp)
	{
		new time = g_iJackpotClose - get_systime();
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_PLAY_JP", time / 60, time % 60);
	}

	return HAM_IGNORED;
}

public task_check_name(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_check_name()")
	#endif

	id -= TASK_CHECK_NAME
}

public task_Reset_Name(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_Reset_Name()")
	#endif

	id -= TASK_RESET_NAME;
	g_eEnumBooleans[id][IsChangeNotAllowed] = false;

	new Name[32];
	get_user_name(id, Name, charsmax(Name));
	if (!equali(Name, g_szName[id]))
	{ 
		g_eEnumBooleans[id][IsChangeNotAllowed] = true;
		set_msg_block(g_Msg_SayText, BLOCK_ONCE);
		set_user_info(id, "name", g_szName[id]);
		set_task(0.5, "task_Reset_Name", id + TASK_RESET_NAME);
	}
}

public task_SetIcon(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_SetIcon()")
	#endif

	id -= TASK_SET_ICON;
	if(is_user_connected(id))
	{
		_SetKillsIcon(id, 1);
	}
}

public Ham_Player_Killed_Pre(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Ham_Player_Killed_Pre()")
	#endif

	if(!is_user_connected(id))
	{
		return HAM_IGNORED;
	}

	new iActiveItem = get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, XO_PLAYER);
	if (pev_valid(iActiveItem) != PDATA_SAFE)
	{

		return HAM_IGNORED;
	}
	new imp = pev(iActiveItem, pev_impulse);
	if (0 < imp)
	{
		return HAM_IGNORED; 
	}

	new iId = get_pdata_int(iActiveItem, OFFSET_ID, XO_WEAPON);
	if ((1 << iId) & weaponsNotVaild)
	{
		return HAM_IGNORED;
	}

	new skin = g_iStattrackWeap[id][bStattrack][iId] ? g_iStattrackWeap[id][iSelected][iId] : g_iUserSelectedSkin[id][iId];
	if (skin != -1)
	{
		set_pev(iActiveItem, pev_impulse, skin + 1);
	}
	return HAM_IGNORED;
}

public Ham_Player_Killed_Post(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Ham_Player_Killed_Post()")
	#endif

	if(!is_user_connected(id))
	{
		return HAM_IGNORED;
	}
	
	ClearPlayerBit(g_bitIsAlive, id);
	if (g_bWarmUp)
	{
		set_task(1.0, "task_Respawn_Player", id + TASK_RESPAWN);
	}
	if (0 < g_iCvars[iRespawn])
	{
		set_hudmessage(0, 255, 60, 2.50, 0.00, 1);
		new second[64];
		if (1 > g_iCvars[iRespawnDelay])
		{
			formatex(second, charsmax(second), "%L", LANG_SERVER, "CSGOR_TOMB_TEXT_SECOND");
		}
		else
		{
			formatex(second, charsmax(second), "%L", LANG_SERVER, "CSGOR_TOMB_TEXT_SECONDS");
		}
		new temp[64];
		formatex(temp, charsmax(temp), "%L", LANG_SERVER, "CSGOR_RESPAWN_TEXT");
		ShowSyncHudMsg(id, g_MsgSync, "%s %d %s...", temp, g_iCvars[iRespawnDelay], second);
		set_task(float(g_iCvars[iRespawnDelay]), "task_Respawn_Player", id + TASK_RESPAWN);
	}
	return HAM_IGNORED;
}

public task_Respawn_Player(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_Respawn_Player()")
	#endif

	id -= TASK_RESPAWN;
	if (!is_user_connected(id) || GetPlayerBit(g_bitIsAlive, id))
		return HAM_IGNORED;

	new CsTeams:team = cs_get_user_team(id);
	if (team && team == CS_TEAM_SPECTATOR)
		return HAM_IGNORED;

	respawn_player_manually(id);

	return HAM_IGNORED;
}

public respawn_player_manually(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "respawn_player_manually()")
	#endif

	ExecuteHam(Ham_CS_RoundRespawn, id);
}

public CS_OnBuy(id, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "CS_OnBuy()")
	#endif

	if(item == CSI_SHIELD)
		return PLUGIN_HANDLED;

	if ((1<<item) & NO_REFILL_WEAPONS || (1<<item) & MISC_ITEMS)
		return PLUGIN_CONTINUE;

	ExecuteHamB(Ham_GiveAmmo, id, g_iMaxBpAmmo[item], g_szAmmoType[item], g_iMaxBpAmmo[item]);

	return PLUGIN_CONTINUE;
}

#if defined HUD_POS
public clcmd_say_hudpos(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_hudpos()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \wHUD POSITION", CSGO_TAG);
	new menu = menu_create(temp, "hudmenu_pos_handler");
	
	formatex(temp, charsmax(temp), "Move HUD Up");
	menu_additem(menu, temp, "0");
	formatex(temp, charsmax(temp), "Move HUD Down");
	menu_additem(menu, temp, "1");
	formatex(temp, charsmax(temp), "Move HUD to the Left");
	menu_additem(menu, temp, "2");
	formatex(temp, charsmax(temp), "Move HUD to the right");
	menu_additem(menu, temp, "3");
	formatex(temp, charsmax(temp), "Move HUD to center");
	menu_additem(menu, temp, "4");
	formatex(temp, charsmax(temp), "Move HUD Default");
	menu_additem(menu, temp, "5");
	formatex(temp, charsmax(temp), "Show Current HUD POS");
	menu_additem(menu, temp, "6");
	
	_DisplayMenu(id, menu);
}

public hudmenu_pos_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "hudmenu_pos_handler()")
	#endif

	switch(item)
	{
		case 0:
		{
			HUD_POS_Y -= 0.03;
			clcmd_say_hudpos(id);
		}
		case 1:
		{
			HUD_POS_Y += 0.03;
			clcmd_say_hudpos(id);
		}
		case 2:
		{
			HUD_POS_X -= 0.03;
			clcmd_say_hudpos(id);
		}
		case 3:
		{
			HUD_POS_X += 0.03;
			clcmd_say_hudpos(id);
		}
		case 4:
		{
			HUD_POS_X = -1.0;
			HUD_POS_Y =  0.26;
			clcmd_say_hudpos(id);
		}
		case 5:
		{
			HUD_POS_X = 0.02;
			HUD_POS_Y =  0.9;
			clcmd_say_hudpos(id);
		}
		case 6:
		{
			client_print(id, print_chat, "Pos X: %f Pos Y: %f", HUD_POS_X, HUD_POS_Y);
			clcmd_say_hudpos(id);
		}
	}
	return _MenuExit(menu);
}
#endif

public task_HUD(id)
{	
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_HUD()")
	#endif

	id -= TASK_HUD;

	if (!GetPlayerBit(g_bitIsAlive, id))
		return;

	if (g_bLogged[id]) 
	{
		new szRank[MAX_RANK_NAME];

		switch(g_iCvars[iShowHUD])
		{
			case iStandardHUD:
			{
				new userRank = g_iUserRank[id];
				ArrayGetString(g_aRankName, userRank, szRank, charsmax(szRank));
				set_hudmessage(0, 255, 0, 0.02, 0.9, 0, 6.00, 1.10);
				ShowSyncHudMsg(id, g_MsgSync, "%L", LANG_SERVER, "CSGOR_HUD_INFO1", g_iUserPoints[id], g_iUserKeys[id], g_iUserCases[id], szRank);
			}
			case iAdvancedHUD:
			{
				new userRank = g_iUserRank[id];
				new szSkin[MAX_SKIN_NAME], szTemp[128];
				new bool:bError = false;

				new iActiveItem = get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, XO_PLAYER);

				if(pev_valid(iActiveItem) != PDATA_SAFE)
				{
					bError = true;
				}

				new weapon = get_pdata_int(iActiveItem, OFFSET_ID, XO_WEAPON);

				if((1 << weapon) & weaponsWithoutSkin)
				{
					bError = true;
				}

				new skin

				if(!bError)
				{
					skin = GetSkinInfo(id, weapon, iActiveItem);
				}

				if(skin == -1 || bError)
				{
					formatex(szSkin, charsmax(szSkin), "%L", LANG_SERVER, "CSGOR_NO_ACTIVE_SKIN_HUD");
					copy(szTemp, charsmax(szTemp), szSkin);
				}
				else
				{
					ArrayGetString(g_aSkinName, skin, szSkin, charsmax(szSkin));
					if(g_iStattrackWeap[id][bStattrack][weapon])
					{
						formatex(szTemp, charsmax(szTemp), "StatTrack (TM) %s^n%L", szSkin, LANG_SERVER, "CSGOR_CONFIRMED_KILLS_HUD", g_iStattrackWeap[id][iKillCount][g_iStattrackWeap[id][iSelected][weapon]]);
					}
					else
					{
						formatex(szTemp, charsmax(szTemp), szSkin);
					}
				}
				ArrayGetString(g_aRankName, userRank, szRank, charsmax(szRank));
				set_hudmessage(0, 255, 0, 0.68, 0.21, 0, 6.00, 1.10);
				ShowSyncHudMsg(id, g_MsgSync, "%L", LANG_SERVER, "CSGOR_HUD_INFO2", g_iUserPoints[id], g_iUserKeys[id], g_iUserCases[id], szRank, szTemp);
			}
		}
	}
	else
	{
		set_hudmessage(255, 0, 0, 0.02, 0.9, 0, 6.00, 1.10);
		ShowSyncHudMsg(id, g_MsgSync, "%L", LANG_SERVER, "CSGOR_NOT_LOGGED");
	}

	set_task(1.0, "task_HUD", id + TASK_HUD);
}

public clcmd_say_reg(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_reg()")
	#endif

	_ShowRegMenu(id);
	return PLUGIN_HANDLED;
}

public clcmd_chooseteam(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_chooseteam()")
	#endif

	clcmd_say_menu(id);
	return PLUGIN_HANDLED;
}

_Save(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_Save()")
	#endif

	_SaveData(id);
}

_Load(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_Load()")
	#endif

	_LoadData(id)
}

public _LoadData(id)
{
	switch(g_iCvars[iSaveType])
	{
		case NVAULT:
		{
			static g_szData[MAX_SKINS * 5 + 94];
			new Timestamp;
			if (nvault_lookup(g_Vault, g_szName[id], g_szData, charsmax(g_szData), Timestamp))
			{
				new szBuffer[MAX_SKIN_NAME], weaponData[8];
				new userData[6][32];
				strtok(g_szData, g_szUser_SavedPass[id], charsmax(g_szUser_SavedPass), g_szData, charsmax(g_szData), '=');
				strtok(g_szData, g_szUserPrefix[id], charsmax(g_szUserPrefix), g_szData, charsmax(g_szData), ',');
				strtok(g_szData, g_szUserPrefixColor[id], charsmax(g_szUserPrefixColor), g_szData, charsmax(g_szData), ';');
				strtok(g_szData, szBuffer, charsmax(szBuffer), g_szData, charsmax(g_szData), '*');
				for (new i; i < sizeof userData; i++)
				{
					strtok(szBuffer, userData[i], charsmax(userData), szBuffer, charsmax(szBuffer), ',');
				}
				g_iUserPoints[id] = str_to_num(userData[0]);
				g_iUserDusts[id] = str_to_num(userData[1]);
				g_iUserKeys[id] = str_to_num(userData[2]);
				g_iUserCases[id] = str_to_num(userData[3]);
				g_iUserKills[id] = str_to_num(userData[4]);
				g_iUserRank[id] = str_to_num(userData[5]);

				static skinBuffer[MAX_SKINS];
				skinBuffer[0] = 0;
				new temp[4];
				strtok(g_szData, g_szData, charsmax(g_szData), skinBuffer, charsmax(skinBuffer), '#');
				for (new j = 1; j <= CSW_P90 && skinBuffer[0] && strtok(skinBuffer, temp, charsmax(temp), skinBuffer, charsmax(skinBuffer), ','); j++)
				{
					g_iUserSelectedSkin[id][j] = str_to_num(temp);
				}
				for (new j = 0; j < MAX_SKINS && g_szData[0] && strtok(g_szData, weaponData, 7, g_szData, charsmax(g_szData), ','); j++)
				{
					g_iUserSkins[id][j] = str_to_num(weaponData);
				}
			}

			g_szData[0] = 0;
			if(nvault_lookup(g_sVault, g_szName[id], g_szData, charsmax(g_szData), Timestamp))
			{
				new weaponData[8];
				static skinBuffer[MAX_SKINS * 2 + 94];
				static killcount[MAX_SKINS * 2];
				new iLine = 0;
				skinBuffer[0] = 0;
				killcount[0] = 0;
				new temp[2][8];
				strtok(g_szData, g_szData, charsmax(g_szData), skinBuffer, charsmax(skinBuffer), '#');
				strtok(skinBuffer, skinBuffer, charsmax(skinBuffer), killcount, charsmax(killcount), '*');
				for (new j = 1; j <= CSW_P90 && skinBuffer[0] && strtok(skinBuffer, temp[0], charsmax(temp[]), skinBuffer, charsmax(skinBuffer), ','); j++)
				{
					g_iStattrackWeap[id][iSelected][j] = str_to_num(temp[0]);
					g_iStattrackWeap[id][bStattrack][j] = str_to_num(temp[0]) != -1 ? true : false;
				}
				for (new j = 0; j < MAX_SKINS && g_szData[0] && strtok(g_szData, weaponData, 7, g_szData, charsmax(g_szData), ','); j++)
				{
					g_iStattrackWeap[id][iWeap][j] = str_to_num(weaponData);
				}
				for (new j = 0; j < MAX_SKINS && killcount[0] && strtok(killcount, temp[1], charsmax(temp[]), killcount, charsmax(killcount), ','); j++)
				{
					iLine += 1;
					g_iStattrackWeap[id][iKillCount][j] = str_to_num(temp[1]);
				}
			}
		}
		case MYSQL:
		{
			new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_data` WHERE `Name` = ^"%s^";", g_szName[id])
		

			if(!SQL_Execute(iQuery))
			{
				SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError));
				log_to_file("csgo_remake_errors.log", g_szSqlError);
				SQL_FreeHandle(iQuery);
				return PLUGIN_HANDLED
			}

			new szQuery[512];
			new bool:bFoundData = SQL_NumResults( iQuery ) > 0 ? false : true;

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
	   				`Bonus Timestamp`, \
	   				`Promocode` \
	   				) VALUES (^"%s^", ^"%s^", ^"%s^", ^"%s^",^"%s^",'0','0','0','0','0','0','0','0','0');", g_szName[id], g_szSteamID[id], g_szUserLastIP[id], g_szUser_SavedPass[id], g_szUserPrefix[id], g_szUserPrefixColor[id]);
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
   					`Bonus Timestamp`, \
   					`Promocode` \
   					FROM `csgor_data` WHERE `Name` = ^"%s^";", g_szName[id]);
   			}

   			iQuery = SQL_PrepareQuery(g_iSqlConnection, szQuery);

   			if(!SQL_Execute(iQuery))
			{
				SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError));
				log_to_file("csgo_remake_errors.log", g_szSqlError);
				return PLUGIN_HANDLED
			}

			if(!bFoundData)
			{
				if(SQL_NumResults(iQuery) > 0)
				{
					SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Password"), g_szUser_SavedPass[id], charsmax(g_szUser_SavedPass[]));
					SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "ChatTag"), g_szUserPrefix[id], charsmax(g_szUserPrefix[]));
					SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "ChatTag Color"), g_szUserPrefixColor[id], charsmax(g_szUserPrefixColor[]));
					g_iUserPoints[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Points"));
					g_iUserDusts[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Scraps"));
					g_iUserKeys[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Keys"));
					g_iUserCases[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Cases"));
					g_iUserKills[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Kills"));
					g_iUserRank[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Rank"));
					g_iPromoCount[id] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Promocode"));
				}
			}

			SQL_FreeHandle(iQuery);
		}
	}
	
	return PLUGIN_HANDLED;
}

public _LoadSkins(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_LoadSkins()")
	#endif

	new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_skins` WHERE `Name` = ^"%s^";", g_szName[id]);
			
	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError));
		log_to_file("csgo_remake_errors.log", g_szSqlError);
		SQL_FreeHandle(iQuery);
		return
	}

	new szQuery[512];
	new bool:bFoundData = SQL_NumResults( iQuery ) > 0 ? false : true;

	if(bFoundData)
	{
		formatex(szQuery, charsmax(szQuery), "INSERT INTO `csgor_skins` \
		(`Name`, \
		`Skins`, \
		`Stattrack Skins`, \
		`Stattrack Kills`, \
		`Selected Stattrack`, \
		`Selected Skins` \
		) VALUES (^"%s^",'0','0','0','0','0');", g_szName[id]);
	}
	else
	{
		formatex(szQuery, charsmax(szQuery), "SELECT \
		`Skins`, \
		`Stattrack Skins`, \
		`Stattrack Kills`, \
		`Selected Stattrack`, \
		`Selected Skins` \
		FROM `csgor_skins` WHERE `Name` = ^"%s^";", g_szName[id]);
	}

	iQuery = SQL_PrepareQuery(g_iSqlConnection, szQuery);

	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError));
		log_to_file("csgo_remake_errors.log", g_szSqlError);
		return
	}

	new szTemp[5][MAX_SKINS * 3 + 94];
	new weaponData[8];
	if(!bFoundData)
	{
		if(SQL_NumResults(iQuery) > 0)
		{
			SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Skins"), szTemp[0], charsmax(szTemp[]));
			for (new j = 0; j < MAX_SKINS && szTemp[0][0] && strtok(szTemp[0], weaponData, charsmax(weaponData), szTemp[0], charsmax(szTemp[]), ','); j++)
			{
				g_iUserSkins[id][j] = str_to_num(weaponData);
			}

			SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Stattrack Skins"), szTemp[1], charsmax(szTemp[]));
			for (new j = 0; j < MAX_SKINS && szTemp[1][0] && strtok(szTemp[1], weaponData, charsmax(weaponData), szTemp[1], charsmax(szTemp[]), ','); j++)
			{
				g_iStattrackWeap[id][iWeap][j] = str_to_num(weaponData);
			}

			SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Stattrack Kills"), szTemp[2], charsmax(szTemp[]));
			for (new j = 0; j < MAX_SKINS && szTemp[2][0] && strtok(szTemp[2], weaponData, charsmax(weaponData), szTemp[2], charsmax(szTemp[]), ','); j++)
			{
				g_iStattrackWeap[id][iKillCount][j] = str_to_num(weaponData);
			}

			SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Selected Stattrack"), szTemp[3], charsmax(szTemp[]));
			for (new j = 1; j <= CSW_P90 && szTemp[3][0] && strtok(szTemp[3], weaponData, charsmax(weaponData), szTemp[3], charsmax(szTemp[]), ','); j++)
			{
				g_iStattrackWeap[id][iSelected][j] = str_to_num(weaponData);
				g_iStattrackWeap[id][bStattrack][j] = str_to_num(weaponData) != -1 ? true : false;
			}

			SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Selected Skins"), szTemp[4], charsmax(szTemp[]));
			for (new j = 1; j <= CSW_P90 && szTemp[4][0] && strtok(szTemp[4], weaponData, charsmax(weaponData), szTemp[4], charsmax(szTemp[]), ','); j++)
			{
				g_iUserSelectedSkin[id][j] = str_to_num(weaponData);
			}
		}
	}

	SQL_FreeHandle(iQuery);
}

public _SaveData(id)
{
	static g_iWeapszBuffer[MAX_SKINS * 2 + 3];
	static skinBuffer[MAX_SKINS * 2];
	static stattszBuffer[MAX_SKINS * 2];
	g_iWeapszBuffer[0] = 0;
	skinBuffer[0] = 0;
	stattszBuffer[0] = 0;
	formatex(g_iWeapszBuffer, charsmax(g_iWeapszBuffer), "%d", g_iUserSkins[id]);

	for (new i = 1; i < MAX_SKINS; i++)
	{
		format(g_iWeapszBuffer, charsmax(g_iWeapszBuffer), "%s,%d", g_iWeapszBuffer, g_iUserSkins[id][i]);
	}

	formatex(skinBuffer, charsmax(skinBuffer), "%d", g_iUserSelectedSkin[id][1]);
	formatex(stattszBuffer, charsmax(stattszBuffer), "%d", g_iStattrackWeap[id][iSelected][1]);

	for (new i = 2; i <= CSW_P90; i++)
	{
		format(skinBuffer, charsmax(skinBuffer), "%s,%d", skinBuffer, g_iUserSelectedSkin[id][i]);
		format(stattszBuffer, charsmax(stattszBuffer), "%s,%d", stattszBuffer, g_iStattrackWeap[id][iSelected][i]);
	}

	switch(g_iCvars[iSaveType])
	{
		case NVAULT:
		{
			static g_szData[MAX_SKINS * 3 + 94];
			g_szData[0] = 0;
			new infoBuffer[MAX_SKIN_NAME];
			formatex(infoBuffer, charsmax(infoBuffer), "%s=%s,%s;%d,%d,%d,%d,%d,%d", g_szUser_SavedPass[id], g_szUserPrefix[id], g_szUserPrefixColor[id], g_iUserPoints[id], g_iUserDusts[id], g_iUserKeys[id], g_iUserCases[id], g_iUserKills[id], g_iUserRank[id]);

			formatex(g_szData, charsmax(g_szData), "%s*%s#%s", infoBuffer, g_iWeapszBuffer, skinBuffer);
			nvault_set(g_Vault, g_szName[id], g_szData);

			task_update_stattrack(id, stattszBuffer, .iType = NVAULT);
		}
		case MYSQL:
		{
			static szQuery[MAX_SKINS * 3 + 94];
			szQuery[0] = 0;
			new iTimestamp;
			IsTaken(id, iTimestamp);
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
			`Bonus Timestamp`='%i', \
			`Promocode`='%i' \
			WHERE `Name`=^"%s^";", g_szSteamID[id], g_szUserLastIP[id], g_szUser_SavedPass[id], g_szUserPrefix[id], g_szUserPrefixColor[id], g_iUserPoints[id], g_iUserDusts[id], g_iUserKeys[id], g_iUserCases[id], g_iUserKills[id], g_iUserRank[id], iTimestamp, g_iPromoCount[id], g_szName[id]);

			SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)

			formatex(szQuery, charsmax(szQuery), "UPDATE `csgor_skins` \
			SET `Skins`=^"%s^", \
			`Selected Stattrack`=^"%s^", \
			`Selected Skins`=^"%s^" \
			WHERE `Name`=^"%s^";", g_iWeapszBuffer, stattszBuffer, skinBuffer, g_szName[id]);

			SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)

			task_update_stattrack(id, "0", .iType = MYSQL);

		}
	}

	return PLUGIN_HANDLED;
}

public task_update_stattrack(id, szPassed[MAX_SKINS * 2], iType)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_update_stattrack()")
	#endif

	static szQuery[MAX_SKINS * 2 + 94];
	static g_iStattrack[MAX_SKINS * 2 + 3];
	g_iStattrack[0] = 0;
	szQuery[0] = 0;
	formatex(g_iStattrack, charsmax(g_iStattrack), "%d", g_iStattrackWeap[id][iWeap]);

	for (new i = 1; i < MAX_SKINS; i++)
	{
		format(g_iStattrack, charsmax(g_iStattrack), "%s,%d", g_iStattrack, g_iStattrackWeap[id][iWeap][i]);
	}

	switch(iType)
	{
		case NVAULT:
		{
			formatex(szQuery, charsmax(szQuery), "%s#%s", g_iStattrack, szPassed);

			task_update_stattrack_kills(id, szQuery, NVAULT);
		}
		case MYSQL:
		{
			formatex(szQuery, charsmax(szQuery), "UPDATE `csgor_skins` \
			SET `Stattrack Skins`=^"%s^" \
			WHERE `Name`=^"%s^";", g_iStattrack, g_szName[id]);

			SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)

			task_update_stattrack_kills(id, "0", .iType = MYSQL);
		}
	}
}

public QueryHandler(iFailState, Handle:iQuery, Error[], Errcode, szData[], iSize, Float:flQueueTime)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: 
		{
			log_amx("[SQL Error] Connection failed (%i): %s", Errcode, Error);
		}
		case TQUERY_QUERY_FAILED:
		{
			log_amx("[SQL Error] Query failed (%i): %s", Errcode, Error);
		}
	}
}

public task_update_stattrack_kills(id, szPassed[MAX_SKINS * 2 + 94], iType)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_update_stattrack_kills()")
	#endif

	static szQuery[MAX_SKINS * 4 + 94];
	static g_iStattKills[MAX_SKINS * 2 + 3];
	g_iStattKills[0] = 0;
	szQuery[0] = 0;

	formatex(g_iStattKills, charsmax(g_iStattKills), "%d", g_iStattrackWeap[id][iKillCount]);
	for (new i = 1; i < MAX_SKINS; i++)
	{
		format(g_iStattKills, charsmax(g_iStattKills), "%s,%d", g_iStattKills, g_iStattrackWeap[id][iKillCount][i]);
	}

	switch(iType)
	{
		case NVAULT:
		{
			formatex(szQuery, charsmax(szQuery), "%s*%s", szPassed, g_iStattKills);

			nvault_set(g_sVault, g_szName[id], szQuery);
		}
		case MYSQL:
		{
			formatex(szQuery, charsmax(szQuery), "UPDATE `csgor_skins`\
			SET `Stattrack Kills`=^"%s^"\
			WHERE `Name`=^"%s^";", g_iStattKills, g_szName[id]);

			SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)
		}
	}
}

public _ShowRegMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowRegMenu()")
	#endif

	if (1 > g_iCvars[iRegOpen])
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_REG_CLOSED");
		return PLUGIN_HANDLED;
	}
	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_REG_MENU");
	new menu = menu_create(temp, "reg_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	formatex(temp, charsmax(temp), "\r%L \w%s", LANG_SERVER, "CSGOR_REG_ACCOUNT", g_szName[id]);
	szItem[0] = 0;
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\r%L \w%s^n", LANG_SERVER, "CSGOR_REG_PASSWORD", g_szUserPassword[id]);
	szItem[0] = 1;
	menu_additem(menu, temp, szItem);
	if (!g_bLogged[id])
	{
		if (IsRegistered(id)) {
			formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_REG_LOGIN");
			szItem[0] = 3;
			menu_additem(menu, temp, szItem);
		} else {
			formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_REG_REGISTER");
			szItem[0] = 4;
			menu_additem(menu, temp, szItem);
		}
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_REG_LOGOUT");
		szItem[0] = 4;
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
	return PLUGIN_HANDLED;
}

public reg_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "reg_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	menu_item_getinfo(menu, item, dummy, itemdata, 1);
	index = itemdata[0];
	new pLen = strlen(g_szUserPassword[id]);
	switch (index)
	{
		case 0:
		{
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CANT_CHANGE_ACC");
			_ShowRegMenu(id);
		}
		case 1:
		{
			if (!g_bLogged[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_REG_INSERT_PASS", 6);
				client_cmd(id, "messagemode UserPassword");
			}
		}
		case 3:
		{
			_Load(id);
			if(g_iCvars[iSaveType] == MYSQL)
			{
				_LoadSkins(id);
			}
			new spLen = strlen(g_szUser_SavedPass[id]);
			if (strlen(g_szUserPassword[id]) <= 0) {
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_REG_INSERT_PASS", 6);
				client_cmd(id, "messagemode UserPassword");
			}
			if (!equal(g_szUserPassword[id], g_szUser_SavedPass[id], spLen))
			{
				g_iUserPassFail[id]++;
				client_print_color(id, print_chat, "^4%s ^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_PASS_FAIL");
				_ShowRegMenu(id);
				ExecuteForward(g_iForwards[ user_pass_fail ], g_iForwardResult, id, g_iUserPassFail[id]);
			}
			else if(equal(g_szUserPassword[id], g_szUser_SavedPass[id], spLen))
			{
				g_bLogged[id] = true;
				_ShowMainMenu(id);
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_LOGIN_SUCCESS");
				ExecuteForward(g_iForwards[ user_log_in ], g_iForwardResult, id);
			}
			_Load(id);
		}
		case 4:
		{
			if (!IsRegistered(id))
			{
				if (pLen < 6)
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_REG_INSERT_PASS", 6);
					_ShowRegMenu(id);
					return _MenuExit(menu);
				}
				copy(g_szUser_SavedPass[id], 15, g_szUserPassword[id]);
				g_bLogged[id] = true;
				_Load(id);
				if(g_iCvars[iSaveType] == MYSQL)
				{
					_LoadSkins(id);
				}
				_ShowMainMenu(id);
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_REG_SUCCESS", g_szUser_SavedPass[id]);
				ExecuteForward(g_iForwards[ user_register ], g_iForwardResult, id);
			}
			else
			{
				if(g_bLogged[id])
				{
					g_bLogged[id] = false;
					g_szUserPassword[id] = "";
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_LOGOUT_SUCCESS");
					_ShowRegMenu(id);
					ExecuteForward(g_iForwards[ user_log_out ], g_iForwardResult, id);
				}
			}
		}
	}
	return _MenuExit(menu);
}

public concmd_password(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_password()")
	#endif

	if (g_bLogged[id])
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ALREADY_LOGIN");
		return PLUGIN_HANDLED;
	}
	new data[32];
	read_args(data, charsmax(data));
	remove_quotes(data);
	if (6 > strlen(data))
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_REG_INSERT_PASS", 6);
		client_cmd(id, "messagemode UserPassword");
		return PLUGIN_HANDLED;
	}
	copy(g_szUserPassword[id], charsmax(g_szUserPassword[]), data);
	_ShowRegMenu(id);
	return PLUGIN_HANDLED;
}

public clcmd_say_menu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_menu()")
	#endif

	if (g_bLogged[id])
	{
		_ShowMainMenu(id);
	}
	else
	{
		_ShowRegMenu(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_LOGIN");
	}
	return PLUGIN_HANDLED;
}

public clcmd_say_inventory(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_inventory()")
	#endif

	if(g_bLogged[id])
	{
		_ShowInventoryMenu(id);
	}
	else
	{
		_ShowRegMenu(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_LOGIN");
	}
	return PLUGIN_HANDLED;
}

public clcmd_say_opencase(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_opencase()")
	#endif

	if(g_bLogged[id])
	{
		_ShowOpenCaseCraftMenu(id);
	}
	else
	{
		_ShowRegMenu(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_LOGIN");
	}
	return PLUGIN_HANDLED;
}

public clcmd_say_market(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_market()")
	#endif

	if(g_bLogged[id])
	{
		_ShowMarketMenu(id);
	}
	else
	{
		_ShowRegMenu(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_LOGIN");
	}
	return PLUGIN_HANDLED;
}

public clcmd_say_dustbin(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_dustbin()")
	#endif

	if(g_bLogged[id])
	{
		_ShowDustbinMenu(id);
	}
	else
	{
		_ShowRegMenu(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_LOGIN");
	}
	return PLUGIN_HANDLED;
}

public clcmd_say_gifttrade(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_gifttrade()")
	#endif

	if(g_bLogged[id])
	{
		_ShowGiftTradeMenu(id);
	}
	else
	{
		_ShowRegMenu(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_LOGIN");
	}
	return PLUGIN_HANDLED;
}

public clcmd_say_games(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_games()")
	#endif

	if(g_bLogged[id])
	{
		_ShowGamesMenu(id);
	}
	else
	{
		_ShowRegMenu(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_LOGIN");
	}
	return PLUGIN_HANDLED;
}

public clcmd_say_preview(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_preview()")
	#endif

	if(g_bLogged[id])
	{
		_ShowPreviewMenu(id);
	}
	else
	{
		_ShowRegMenu(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_LOGIN");
	}
	return PLUGIN_HANDLED;
}

public _ShowPreviewMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowPreviewMenu()")
	#endif

	new szTemp[MAX_SKIN_NAME];
	new weapons[EnumSkinsMenuInfo];
	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_PREVIEW_MENU");
	new menu = menu_create(szTemp, "preview_menu_handler");
	for(new i; i < ArraySize(g_aSkinsMenu) ; i++)
	{
		ArrayGetArray(g_aSkinsMenu, i, weapons);
		formatex(szTemp, charsmax(szTemp), "%s", weapons[ItemName]);
		menu_additem(menu, szTemp, weapons[ItemID]);
	}

	_DisplayMenu(id, menu);
}

public preview_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "preview_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}

	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);

	_ShowSortedSkins(id, item, iPreview);

	return _MenuExit(menu);
}

public _ShowMainMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowMainMenu()")
	#endif

	new temp[96], MenuInfo[EnumDynamicMenu];
	formatex(temp, charsmax(temp), "\r%s \w%L^n%L", CSGO_TAG, LANG_SERVER, "CSGOR_MAIN_MENU", LANG_SERVER, "CSGOR_MM_INFO", g_iUserPoints[id], g_iUserKills[id]);
	new menu = menu_create(temp, "main_menu_handler");

	for(new i; i < ArraySize(g_aDynamicMenu); i++)
	{
		ArrayGetArray(g_aDynamicMenu, i, MenuInfo);

		if (containi(MenuInfo[szMenuName], "CSGOR_") != -1)
		{
			formatex(temp, charsmax(temp), "%L", LANG_SERVER, MenuInfo[szMenuName]);
		}
		else
		{
			formatex(temp, charsmax(temp), MenuInfo[szMenuName]);
		}
		menu_additem(menu, temp);
	}

	new userRank = g_iUserRank[id];
	new szRank[MAX_RANK_NAME];
	ArrayGetString(g_aRankName, userRank, szRank, charsmax(szRank));
	if (g_iRanksNum - 1 > userRank)
	{
		new nextRank = ArrayGetCell(g_aRankKills, userRank + 1) - g_iUserKills[id];
		formatex(temp, charsmax(temp), "\w%L^n%L", LANG_SERVER, "CSGOR_MM_RANK", szRank, LANG_SERVER, "CSGOR_MM_NEXT_KILLS", nextRank);
	}
	else
	{
		formatex(temp, charsmax(temp), "\w%L^n%L", LANG_SERVER, "CSGOR_MM_RANK", szRank, LANG_SERVER, "CSGOR_MM_MAX_KILLS");
	}
	menu_addtext2(menu, temp);

	_DisplayMenu(id, menu);
}

public main_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "main_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		return _MenuExit(menu);
	}
	
	new MenuInfo[EnumDynamicMenu];

	ArrayGetArray(g_aDynamicMenu, item, MenuInfo);

	cmd_execute(id, MenuInfo[szMenuCMD]);

	return _MenuExit(menu);
}

public _ShowInventoryMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowInventoryMenu()")
	#endif

	new temp[64], szItem[32];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_MM_INVENTORY");
	new menu = menu_create(temp, "inventory_menu_handler");
	
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_SKIN_MENU");
	num_to_str(0, szItem, charsmax(szItem));
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CHAT_TAG");
	num_to_str(1, szItem, charsmax(szItem));
	menu_additem(menu, temp, szItem);
	
	_DisplayMenu(id, menu);
}

public inventory_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "inventory_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);
	switch (item)
	{
		case 0:
		{
			_ShowSkinsMenu(id);
		}
		case 1:
		{
			_ShowTagsMenu(id);
		}
	}
	return _MenuExit(menu);
}

public _ShowSkinsMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowSkinsMenu()")
	#endif

	new szTemp[64];
	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_SKIN_MENU");
	new menu = menu_create(szTemp, "skins_menu_handler");
	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_NORMAL_SKIN_MENU");
	menu_additem(menu, szTemp);

	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_SERVER, "CSGOR_STATTRACK_SKIN_MENU");
	menu_additem(menu, szTemp);

	_DisplayMenu(id, menu);
}

public skins_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "skins_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}

	switch(item)
	{
		case 0:
		{
			_ShowNormalSkinsMenu(id);
		}
		case 1:
		{
			_ShowStattrackSkinsMenu(id);
		}
	}

	return PLUGIN_CONTINUE;
}

public _ShowNormalSkinsMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowNormalSkinsMenu()")
	#endif

	new szTemp[128];
	new weapons[EnumSkinsMenuInfo];
	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_SKIN_MENU");
	new menu = menu_create(szTemp, "skins_normal_menu_handler");
	for(new i; i < ArraySize(g_aSkinsMenu) ; i++)
	{
		ArrayGetArray(g_aSkinsMenu, i, weapons);
		formatex(szTemp, charsmax(szTemp), "%s [\r%d\w/\r%d\w]", weapons[ItemName], GetUserSkinsNum(id, str_to_num(weapons[ItemID])), GetMaxSkins(str_to_num(weapons[ItemID])));
		menu_additem(menu, szTemp, weapons[ItemID]);
	}

	_DisplayMenu(id, menu);
}

public skins_normal_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "skins_normal_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}

	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);

	_ShowSortedSkins(id, item, iNormal);

	return _MenuExit(menu);
}

public _ShowStattrackSkinsMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowStattrackSkinsMenu()")
	#endif

	new szTemp[128];
	new weapons[EnumSkinsMenuInfo];
	formatex(szTemp, charsmax(szTemp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_SKIN_MENU");
	new menu = menu_create(szTemp, "skins_stattrack_menu_handler");
	for(new i; i < ArraySize(g_aSkinsMenu) ; i++)
	{
		ArrayGetArray(g_aSkinsMenu, i, weapons);
		formatex(szTemp, charsmax(szTemp), "\y(StatTrack)\w %s [\r%d\w/\r%d\w]", weapons[ItemName], GetUserSkinsNum(id, str_to_num(weapons[ItemID]), true), GetMaxSkins(str_to_num(weapons[ItemID])));
		menu_additem(menu, szTemp, weapons[ItemID]);
	}

	_DisplayMenu(id, menu);
}

public skins_stattrack_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "skins_stattrack_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}

	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);

	_ShowSortedSkins(id, item, iStattrack);

	return _MenuExit(menu);
}

public _ShowSortedSkins(id, iItem, iMenu)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowSortedSkins()")
	#endif

	new szTemp[82], szFormatted[64];
	new szItem[32], bool:hasSkins, num, skinName[48], skintype[4], iWeaponID, apply, craft;

	switch(iMenu)
	{
		case iNormal, iStattrack:
		{
			formatex(szFormatted, charsmax(szFormatted), "\w%L", LANG_SERVER, iMenu == iNormal ? "CSGOR_SKIN_MENU" : "CSGOR_SKIN_STT_MENU");
		}
		case iPreview:
		{
			formatex(szFormatted, charsmax(szFormatted), "\w%L", LANG_SERVER, "CSGOR_PREVIEW_MENU");
		}
	}

	formatex(szTemp, charsmax(szTemp), "\r%s \w%s", CSGO_TAG, szFormatted);
	new menu = menu_create(szTemp, "skin_menu_handler");
	switch(iMenu)
	{
		case iPreview:
		{
			for (new i; i < g_iSkinsNum; i++)
			{
				iWeaponID = ArrayGetCell(g_aSkinWeaponID, i);
				if (iItem == iWeaponID)
				{
					ArrayGetString(g_aSkinName, i, skinName, charsmax(skinName));
					ArrayGetString(g_aSkinType, i, skintype, charsmax(skintype));
					if (equali(skintype, "d", 3))
					{
						craft = 0;
					}
					else
					{
						craft = 1;
					}
					formatex(szTemp, charsmax(szTemp), "%s%s\w", craft ? "\r" : "\w", skinName);
					num_to_str(i, szItem, charsmax(szItem));
					format(szItem, charsmax(szItem), "%s,%i", szItem, iMenu);
					menu_additem(menu, szTemp, szItem);
					hasSkins = true;
				}
			}
		}
		case iNormal, iStattrack:
		{
			for (new i; i < g_iSkinsNum; i++)
			{
				num = iMenu == iNormal ? g_iUserSkins[id][i] : g_iStattrackWeap[id][iWeap][i];
				if(num)
				{
					iWeaponID = ArrayGetCell(g_aSkinWeaponID, i);
					if (iItem == iWeaponID)
					{
						ArrayGetString(g_aSkinName, i, skinName, charsmax(skinName));
						ArrayGetString(g_aSkinType, i, skintype, charsmax(skintype));
						if (equali(skintype, "d", 3))
						{
							craft = 0;
						}
						else
						{
							craft = 1;
						}
						if (iMenu == iNormal ? g_iUserSelectedSkin[id][iWeaponID] == i : g_iStattrackWeap[id][iSelected][iWeaponID] == i)
						{
							apply = 1;
						}
						else
						{
							apply = 0;
						}
						formatex(szTemp, charsmax(szTemp), "%s%s\w| \y%L \r%s", iMenu == iNormal ? (craft ? "\r" : "\w") : "\w", skinName, LANG_SERVER, "CSGOR_SM_PIECES", num, apply ? "#" : "");
						num_to_str(i, szItem, charsmax(szItem));
						format(szItem, charsmax(szItem), "%s,%i", szItem, iMenu);
						menu_additem(menu, szTemp, szItem);
						hasSkins = true;
					}
				}
			}
		}
	}
	
	if (!hasSkins)
	{
		formatex(szTemp, charsmax(szTemp), "\r%L", LANG_SERVER, "CSGOR_SM_NO_SKINS");
		num_to_str(-10, szItem, charsmax(szItem));
		format(szItem, charsmax(szItem), "%s,%i", szItem, iMenu);
		menu_additem(menu, szTemp, szItem);
	}
	_DisplayMenu(id, menu);
}

public skin_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "skin_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}

	new itemdata[3];
	new data[6][32];
	new index[32];
	new szMenu[2], iMenu;
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	strtok(index, index, charsmax(index), szMenu, charsmax(szMenu), ',');
	item = str_to_num(index);
	iMenu = str_to_num(szMenu);

	switch (item)
	{
		case -10:
		{
			_ShowPreviewMenu(id);
		}
		default:
		{
			switch(iMenu)
			{
				case iPreview:
				{
					if(g_eEnumBooleans[id][IsInPreview])
					{
						client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_PREVIEW_ALREADY");
						goto _return;
					}
					new iWeaponID = ArrayGetCell(g_aSkinWeaponID, item);
					if(get_user_weapon(id) != iWeaponID)
					{
						client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_PREVIEW_NEEDS_SAME_WEAP");
						_ShowPreviewMenu(id);
						goto _return;
					}
					new szParams[50];
					szParams[48] = iWeaponID;
					szParams[49] = g_iUserSelectedSkin[id][iWeaponID];
					new sName[48];
					ArrayGetString(g_aSkinName, item, sName, charsmax(sName));
					copy(szParams, charsmax(szParams) - 3, sName);
					g_iUserSelectedSkin[id][iWeaponID] = item;
					g_iStattrackWeap[id][iSelected][iWeaponID] = -1
					g_iStattrackWeap[id][bStattrack][iWeaponID] = false;
					g_iUserViewBody[id][iWeaponID] = item;
					g_eEnumBooleans[id][IsInPreview] = true;
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_PREVIEWING_SKIN_FOR", sName, g_iCvars[iCPreview]);
					set_task(float(g_iCvars[iCPreview]), "task_stop_preview", id + TASK_PREVIEW, szParams, sizeof(szParams));
				}
				case iNormal, iStattrack:
				{
					new iWeaponID = ArrayGetCell(g_aSkinWeaponID, item);
					new bool:SameSkin;
					if (item == (g_iStattrackWeap[id][bStattrack][iWeaponID] ? g_iStattrackWeap[id][iSelected][iWeaponID] : g_iUserSelectedSkin[id][iWeaponID]))
					{
						SameSkin = true;
					}
					new sName[48];
					ArrayGetString(g_aSkinName, item, sName, charsmax(sName));
					if (!SameSkin)
					{
						switch(iMenu)
						{
							case iNormal:
							{
								g_iUserSelectedSkin[id][iWeaponID] = item;
								g_iStattrackWeap[id][iSelected][iWeaponID] = -1
								g_iStattrackWeap[id][bStattrack][iWeaponID] = false;
							}
							case iStattrack:
							{
								g_iUserSelectedSkin[id][iWeaponID] = -1
								g_iStattrackWeap[id][iSelected][iWeaponID] = item;
								g_iStattrackWeap[id][bStattrack][iWeaponID] = true;
								format(sName, charsmax(sName), "StatTrack %s", sName);
							}
						}
						g_iUserViewBody[id][iWeaponID] = item;
						client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_SELECT_SKIN", sName);
					}
					else
					{
						if(g_iStattrackWeap[id][bStattrack][iWeaponID])
						{
							g_iStattrackWeap[id][iSelected][iWeaponID] = -1;
							g_iStattrackWeap[id][bStattrack][iWeaponID] = false;
							format(sName, charsmax(sName), "StatTrack %s", sName);
						}
						else
						{
							g_iUserSelectedSkin[id][iWeaponID] = -1;
						}
						g_iUserViewBody[id][iWeaponID] = 0;
						client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DESELECT_SKIN", sName);
					}

					_Save(id);
					_ShowSkinsMenu(id);
				}
			}
			if(pev_valid(id) != PDATA_SAFE)
			{
				return PLUGIN_HANDLED;
			}
			new iActiveItem, weapon;
			iActiveItem = get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, XO_PLAYER);
			if(pev_valid(iActiveItem) != PDATA_SAFE) goto _return;

			weapon = GetWeaponEntity(iActiveItem);

			if(!pev_valid(weapon))
			{
				return _MenuExit(menu);
			}

			change_skin(id, weapon);
		}
	}
	_return:
	return _MenuExit(menu);
}

public task_stop_preview(szParam[], id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_stop_preview()")
	#endif

	id -= TASK_PREVIEW;

	new iWeaponID = szParam[48];
	new szName[48];
	copy(szName, charsmax(szName) - 1, szParam);
	g_iUserSelectedSkin[id][iWeaponID] = szParam[49];
	g_eEnumBooleans[id][IsInPreview] = false;
	client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_PREVIEWING_DONE", szName);
	change_skin(id, iWeaponID);

	return PLUGIN_HANDLED;
}

public _ShowTagsMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowTagsMenu()")
	#endif

	new temp[64];
	new szItem[32];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_CHAT_TAG");
	new menu = menu_create(temp, "tags_menu_handler");
	
	if( equal(g_szUserPrefix[id], ""))
	{
		formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_NO_CTAG");
	}
	else
	{
		formatex(temp, charsmax(temp), "\w%L^n", id, "CSGOR_YOUR_CTAG_IS", g_szUserPrefix[id]);
	}
	num_to_str(0, szItem, charsmax(szItem));
	menu_additem(menu, temp, szItem);
	
	if( equal(g_szUserPrefix[id], "") )
	{
		formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_CTAG_BUY_ONE", g_iCvars[iChatTagPrice]);
	}
	else
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CTAG_CHANGE", g_iCvars[iChatTagPrice]);
	}
	num_to_str(1, szItem, charsmax(szItem));
	menu_additem(menu, temp, szItem);
	
	if ( !equal(g_szUserPrefix[id], "") )
	{
		formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_CTAG_COLOR", g_iCvars[iChatTagColorPrice]);
		num_to_str(2, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
	}
	
	if( !equal(g_szUserPrefix[id], "") || !equal(g_szTemporaryCtag[id], "") )
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CTAG_ACCEPT_CHANGE");
		num_to_str(3, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public tags_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "tags_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);
	switch (item)
	{
		case 0:
		{
			_ShowTagsMenu(id);
		}
		case 1:
		{
			client_cmd(id, "messagemode ChatTag");
		}
		case 2:
		{
			_ShowTagsColorMenu(id);
		}
		case 3:
		{
			if(g_szTemporaryCtag[id][0] != EOS)
			{
				if ( g_iCvars[iChatTagPrice] <= g_iUserPoints[id] )
				{
					copy(g_szUserPrefix[id], 15, g_szTemporaryCtag[id]);
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CTAG_CHANGED_SUCCES", g_szUserPrefix[id]);
					g_iUserPoints[id] -= g_iCvars[iChatTagPrice];
					g_szTemporaryCtag[id] = "";
				}
				else
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CTAG_CHANGE_FAIL", (g_iCvars[iChatTagPrice] - g_iUserPoints[id]));
				}
			}
			_ShowTagsMenu(id);
		}
	}
	return _MenuExit(menu);
}

public concmd_chattag(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_chattag()")
	#endif

	new data[32];
	read_args(data, charsmax(data));
	remove_quotes(data);
	if ( strlen(data) < 3 || strlen(data) > 12 || containi(data, "%") != -1)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INSERT_CTAG", 3, 12);
		client_cmd(id, "messagemode ChatTag");
	}
	else
	{
		copy(g_szTemporaryCtag[id], 15, data);
		_ShowTagsMenu(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INSERTED_CTAG", g_szTemporaryCtag[id]);
	}
	return PLUGIN_HANDLED;
}

public _ShowTagsColorMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowTagsColorMenu()")
	#endif

	new temp[64];
	new szItem[32];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_CTAG_COLOR", g_iCvars[iChatTagColorPrice]);
	new menu = menu_create(temp, "tags_color_menu_handler");
	
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CTAG_COLOR_TEAM_COLOR");
	num_to_str(1, szItem, charsmax(szItem));
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CTAG_COLOR_GREEN");
	num_to_str(2, szItem, charsmax(szItem));
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_CTAG_COLOR_NORMAL");
	num_to_str(3, szItem, charsmax(szItem));
	menu_additem(menu, temp, szItem);
	
	_DisplayMenu(id, menu);
}

public tags_color_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "tags_color_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);
	switch (item)
	{
		case 1:
		{
			if (g_iCvars[iChatTagColorPrice] <= g_iUserPoints[id])
			{
				g_szUserPrefixColor[id] = "^3";
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CTAG_COLOR_SUCCES", LANG_SERVER, "CSGOR_CTAG_COLOR_TEAM_COLOR");
			}
			else
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CTAG_CHANGE_FAIL", (g_iCvars[iChatTagPrice] - g_iUserPoints[id]));
			}
		}
		case 2:
		{
			if (g_iCvars[iChatTagColorPrice] <= g_iUserPoints[id])
			{
				g_szUserPrefixColor[id] = "^4";
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CTAG_COLOR_SUCCES", LANG_SERVER, "CSGOR_CTAG_COLOR_GREEN");
			}
			else
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CTAG_CHANGE_FAIL", (g_iCvars[iChatTagPrice] - g_iUserPoints[id]));
			}
		}
		case 3:
		{
			if (g_iCvars[iChatTagColorPrice] <= g_iUserPoints[id])
			{
				g_szUserPrefixColor[id] = "^1";
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CTAG_COLOR_SUCCES", LANG_SERVER, "CSGOR_CTAG_COLOR_NORMAL");
			}
			else
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CTAG_CHANGE_FAIL", (g_iCvars[iChatTagPrice] - g_iUserPoints[id]));
			}
		}
	}
	return _MenuExit(menu);
}

public Ham_GrenadePrimaryAttack_Pre(ent)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Ham_GrenadePrimaryAttack_Pre()")
	#endif

	if (pev_valid(ent) != PDATA_SAFE)
	{
		return HAM_IGNORED;
	}
	new id = get_pdata_cbase(ent, OFFSET_WEAPONOWNER, XO_WEAPON);
	ClearPlayerBit(g_bitShortThrow, id);
	return HAM_IGNORED;
}

public Ham_GrenadeSecondaryAttack_Pre(ent)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Ham_GrenadeSecondaryAttack_Pre()")
	#endif

	if (pev_valid(ent) != PDATA_SAFE)
	{
		return HAM_IGNORED;
	}
	new id = get_pdata_cbase(ent, OFFSET_WEAPONOWNER, XO_WEAPON);
	ExecuteHamB(Ham_Weapon_PrimaryAttack, ent);
	SetPlayerBit(g_bitShortThrow, id);
	return HAM_IGNORED;
}

public grenade_throw(id, ent, csw)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "grenade_throw()")
	#endif

	if(!pev_valid(ent))
		return;
	
	switch (csw)
	{
		case CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_FLASHBANG:
		{
			engfunc(EngFunc_SetModel, ent, defaultModels[csw]);
		}
	}
	
	if(!GetPlayerBit(g_bitShortThrow, id))
		return;
	
	if (csw == CSW_FLASHBANG)
	{
		set_pev(ent, pev_dmgtime, 1.0 + get_gametime());
	}

	new Float:fVec[3];
	pev(ent, pev_velocity, fVec);
	fVec[0] = fVec[0] * g_iCvars[flShortThrowVelocity];
	fVec[1] = fVec[1] * g_iCvars[flShortThrowVelocity];
	fVec[2] = fVec[2] * g_iCvars[flShortThrowVelocity];
	set_pev(ent, pev_velocity, fVec);
	
	pev(ent, pev_origin, fVec);
	fVec[2] = fVec[2] - 24.00;
	set_pev(ent, pev_origin, fVec);
	ClearPlayerBit(g_bitShortThrow, id);
}

public Ham_Item_Deploy_Post(ent)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Ham_Item_Deploy_Post()")
	#endif

	if(pev_valid(ent) != PDATA_SAFE)
		return;
	
	new iPlayer = get_pdata_cbase(ent, OFFSET_WEAPONOWNER, XO_WEAPON);
	
	new weapon = GetWeaponEntity(ent);
	
	g_iWeaponIndex[iPlayer] = weapon;

	if (weapon != CSW_HEGRENADE && weapon != CSW_SMOKEGRENADE && weapon != CSW_FLASHBANG && weapon != CSW_C4) 
	{
		set_pev(iPlayer, pev_viewmodel2, "");
	}
	
	change_skin(iPlayer, weapon);
}

public HamF_CS_Weapon_SendWeaponAnim_Post(iEnt, iAnim, Skiplocal)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "HamF_CS_Weapon_SendWeaponAnim_Post()")
	#endif

	Skiplocal = false

	if(pev_valid(iEnt) != PDATA_SAFE)
		return HAM_IGNORED;

	new iPlayer, weapon;
	iPlayer = get_pdata_cbase(iEnt, OFFSET_WEAPONOWNER, XO_WEAPON);
	
	weapon = GetWeaponEntity(iEnt);

	if(!pev_valid(weapon))
		return FMRES_IGNORED;

	SendWeaponAnim(iPlayer, iAnim);
	
	return HAM_IGNORED;
}

public HamF_TraceAttack_Post(iEnt, iAttacker, Float:damage, Float:fDir[3], ptr, iDamageType)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "HamF_TraceAttack_Post()")
	#endif

	if(pev_valid(iAttacker) != PDATA_SAFE)
	{
		return HAM_IGNORED;
	}

	new iWeapon;
	static Float:vecEnd[3];
	iWeapon = get_pdata_cbase(iAttacker, OFFSET_ACTIVE_ITEM, XO_PLAYER);
	
	new iWeaponEnt = GetWeaponEntity(iWeapon);

	if(!pev_valid(iWeaponEnt) || !iWeaponEnt || iWeaponEnt == CSW_KNIFE)
		return HAM_IGNORED;

	get_tr2(ptr, TR_vecEndPos, vecEnd);

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, vecEnd[0]);
	engfunc(EngFunc_WriteCoord, vecEnd[1]);
	engfunc(EngFunc_WriteCoord, vecEnd[2]);
	write_short(iEnt);
	write_byte(random_num(41, 45));
	message_end();

	return HAM_IGNORED;
}

public Ham_Weapon_Secondary_Pre(ent)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Ham_Weapon_Secondary_Pre()")
	#endif

	if (pev_valid(ent) != PDATA_SAFE) return HAM_IGNORED;

	new skin, id;
	id = get_pdata_cbase(ent, OFFSET_WEAPONOWNER, XO_WEAPON);

	if (pev_valid(id) != PDATA_SAFE || !is_user_alive(id)) return HAM_IGNORED;
	
	new weapon = get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, XO_PLAYER);
	new weaponid = cs_get_weapon_id(weapon);
	skin = (g_iStattrackWeap[id][bStattrack][weaponid] ? g_iStattrackWeap[id][iSelected][weaponid] : g_iUserSelectedSkin[id][weaponid]);

	if (skin > -1) {
		new skinName[MAX_SKIN_NAME];

		ArrayGetString(g_aSkinName, skin, skinName, charsmax(skinName));

		if (containi(skinName, "M4A4") != -1) {
			cs_set_weapon_silen(ent, 0, 0);

			set_pdata_float(ent, OFFSET_SECONDARY_ATTACK, 9999.0, XO_WEAPON);

			return HAM_SUPERCEDE;
		}
	}

	return HAM_IGNORED;
}

public FM_Hook_PlayBackEvent_Pre(iFlags, pPlayer, iEvent, Float:fDelay, Float:vecOrigin[3], Float:vecAngle[3], Float:flParam1, Float:flParam2, iParam1, iParam2, bParam1, bParam2)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "FM_Hook_PlayBackEvent_Pre()")
	#endif

	new i, iCount, iSpectator, iszSpectators[32];

	get_players(iszSpectators, iCount, "bch");

	for(i = 0; i < iCount; i++)
	{
		iSpectator = iszSpectators[i];

		if(pev(iSpectator, pev_iuser1) != OBS_IN_EYE || pev(iSpectator, pev_iuser2) != pPlayer)
			continue;

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public pfn_playbackevent(flags, entid, eventid, Float:delay, Float:Origin[3], Float:Angles[3], Float:fparam1, Float:fparam2, iparam1, iparam2, bparam1, bparam2)
{ 
	if(g_bGEventID[eventid])
	{
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public FM_Hook_PlayBackEvent_Primary_Pre(iFlags, id, eventid, Float:delay, Float:FlOrigin[3], Float:FlAngles[3], Float:FlParam1, Float:FlParam2, iParam1, iParam2, bParam1, bParam2)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "FM_Hook_PlayBackEvent_Primary_Pre()")
	#endif

	if(!is_user_connected(id) || pev_valid(id) != PDATA_SAFE || !IsPlayer(id))
	{
		return
	}

	new iEnt = get_user_weapon(id)

	PrimaryAttackReplace(id, iEnt)
}

DeployWeaponSwitch(iPlayer)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "DeployWeaponSwitch()")
	#endif

	new weaponid, userskin, weapon; 
	weapon = get_pdata_cbase(iPlayer, OFFSET_ACTIVE_ITEM, XO_PLAYER);

	if (!weapon || !pev_valid(weapon)) return;

	weaponid = cs_get_weapon_id(weapon);
	userskin = (g_iStattrackWeap[iPlayer][bStattrack][weaponid] ? g_iStattrackWeap[iPlayer][iSelected][weaponid] : g_iUserSelectedSkin[iPlayer][weaponid]);

	new model[48];

	new imp = pev(weapon, pev_impulse);
	if (0 < imp)
	{
		ArrayGetString(g_aSkinModel, imp - 1, model, charsmax(model));
		set_pev(iPlayer, pev_viewmodel2, model);
		g_iUserViewBody[iPlayer][weaponid] = ArrayGetCell(g_aSkinSubModel, imp - 1);
		if (g_bSkinHasModelP[imp - 1])
		{
			ArrayGetString(g_aSkinModelP, imp - 1, model, charsmax(model));
			set_pev(iPlayer, pev_viewmodel2, model);
		}
	}
	else
	{
		if (userskin > -1)
		{
			if(!g_eEnumBooleans[iPlayer][IsInPreview])
			{
				if(g_iStattrackWeap[iPlayer][bStattrack][weaponid])
				{
					if(1 > g_iStattrackWeap[iPlayer][iWeap][userskin])
					{
						userskin = -1;
						g_iStattrackWeap[iPlayer][iSelected][weaponid] = -1;
					}
				}
				else
				{
					if(1 > g_iUserSkins[iPlayer][userskin])
					{
						userskin = -1
						g_iUserSelectedSkin[iPlayer][weaponid] = -1;
					}
				}
			}

		 	if(g_bLogged[iPlayer] && userskin != -1)
			{
				ArrayGetString(g_aSkinModel, userskin, model, charsmax(model));
				set_pev(iPlayer, pev_viewmodel2, model);
				g_iUserViewBody[iPlayer][weaponid] = ArrayGetCell(g_aSkinSubModel, userskin);
				if (g_bSkinHasModelP[userskin])
				{
					ArrayGetString(g_aSkinModelP, userskin, model, charsmax(model));
					set_pev(iPlayer, pev_viewmodel2, model);
				}
			}
		}

		if(!g_bLogged[iPlayer] || userskin == -1)
		{
			if(defaultModels[g_iWeaponIndex[iPlayer]][0] != '-')
			{
				set_pev(iPlayer, pev_viewmodel2, defaultModels[g_iWeaponIndex[iPlayer]]);
				g_iUserViewBody[iPlayer][weaponid] = ArrayGetCell(g_aDefaultSubmodel, g_iWeaponIndex[iPlayer]);
			}
		}
	}

	SendWeaponAnim(iPlayer, WeaponDrawAnim(weapon));
}

public Ham_Item_Can_Drop_Pre(ent)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Ham_Item_Can_Drop_Pre()")
	#endif

	if (pev_valid(ent) != PDATA_SAFE)
	{
		return HAM_IGNORED;
	}
	
	new weapon = get_pdata_int(ent, OFFSET_ID, XO_WEAPON);
	if (weapon < 1 || weapon > 30)
	{
		return HAM_IGNORED;
	}
	if ((1 << weapon) & weaponsNotVaild)
	{
		return HAM_IGNORED;
	}
	new imp = pev(ent, pev_impulse);
	if (0 < imp)
	{
		return HAM_IGNORED;
	}
	new id = get_pdata_cbase(ent, OFFSET_WEAPONOWNER, XO_WEAPON);
	if (!is_user_connected(id))
	{
		return HAM_IGNORED;
	}
	new skin = (g_iStattrackWeap[id][bStattrack][weapon] ? g_iStattrackWeap[id][iSelected][weapon] : g_iUserSelectedSkin[id][weapon]);
	if (skin != -1)
	{
		set_pev(ent, pev_impulse, skin + 1);
	}
	return HAM_IGNORED;
}

public _ShowOpenCaseCraftMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowOpenCaseCraftMenu()")
	#endif

	new temp[96];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_OC_CRAFT_MENU");
	new menu = menu_create(temp, "oc_craft_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	formatex(temp, charsmax(temp), "\w%L^n%L^n", LANG_SERVER, "CSGOR_OCC_OPENCASE", LANG_SERVER, "CSGOR_OCC_OPEN_ITEMS", g_iUserCases[id], g_iUserKeys[id]);
	szItem[0] = 0;
	menu_additem(menu, temp, szItem);
	if (0 < g_iCvars[iDropType])
	{
		formatex(temp, charsmax(temp), "\r%L^n\w%L^n", LANG_SERVER, "CSGOR_OCC_BUY_KEY", LANG_SERVER, "CSGOR_MR_PRICE", g_iCvars[iKeyPrice]);
		szItem[0] = 2;
		menu_additem(menu, temp, szItem);
		formatex(temp, charsmax(temp), "\r%L \w| %L^n", LANG_SERVER, "CSGOR_OCC_SELL_KEY", LANG_SERVER, "CSGOR_RECEIVE_POINTS", g_iCvars[iKeyPrice] / 2);
		szItem[0] = 3;
		menu_additem(menu, temp, szItem);
	}
	formatex(temp, charsmax(temp), "\w%L^n%L^n", LANG_SERVER, "CSGOR_OCC_CRAFT", LANG_SERVER, "CSGOR_OCC_CRAFT_ITEMS", g_iUserDusts[id], g_iCvars[iCraftCost]);
	szItem[0] = 1;
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L \y(StatTrack)^n%L", LANG_SERVER, "CSGOR_OCC_CRAFT", LANG_SERVER, "CSGOR_OCC_CRAFT_ITEMS", g_iUserDusts[id], g_iCvars[iStatTrackCost]);
	szItem[0] = 4;
	menu_additem(menu, temp, szItem);

	_DisplayMenu(id, menu);

	return PLUGIN_HANDLED;
}

public oc_craft_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "oc_craft_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}
	if(!g_bLogged[id])
	{
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	menu_item_getinfo(menu, item, dummy, itemdata, 1);
	index = itemdata[0];
	switch (index)
	{
		case 0:
		{
			if (g_iUserCases[id] < 1 || g_iUserKeys[id] < 1)
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_OPEN_NOT_ENOUGH");
				_ShowOpenCaseCraftMenu(id);
			}
			else 
			{
				if (get_systime() < g_iLastOpenCraft[id] + 5 && (g_iCvars[iAntiSpam] || g_iCvars[iShowDropCraft]))
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DONT_SPAM", 5);
					_ShowOpenCaseCraftMenu(id);
				}
				else
				{
					_OpenCase(id)
				}
			}
		}
		case 1:
		{
			if (g_iCvars[iCraftCost] > g_iUserDusts[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CRAFT_NOT_ENOUGH", g_iCvars[iCraftCost] - g_iUserDusts[id]);
				_ShowOpenCaseCraftMenu(id);
			}
			else
			{
				if(g_iCvars[iAntiSpam] || g_iCvars[iShowDropCraft])
				{
					if (get_systime() < g_iLastOpenCraft[id] + 5)
					{
						client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DONT_SPAM", 5);
						_ShowOpenCaseCraftMenu(id);
						return PLUGIN_HANDLED;
					}
				}
				_CraftSkin(id);
			}
		}
		case 2:
		{
			if (g_iCvars[iKeyPrice] > g_iUserPoints[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NOT_ENOUGH_POINTS", g_iCvars[iKeyPrice] - g_iUserPoints[id]);
				_ShowOpenCaseCraftMenu(id);
			}
			else
			{
				g_iUserPoints[id] -= g_iCvars[iKeyPrice];
				g_iUserKeys[id]++;
				_Save(id);
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_BUY_KEY");
				_ShowOpenCaseCraftMenu(id);
			}
		}
		case 3:
		{
			if (1 > g_iUserKeys[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NONE_KEYS");
				_ShowOpenCaseCraftMenu(id);
			}
			else
			{
				g_iUserPoints[id] += g_iCvars[iKeyPrice] / 2;
				g_iUserKeys[id]--;
				_Save(id);
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_SELL_KEY");
				_ShowOpenCaseCraftMenu(id);
			}
		}
		case 4:
		{
			if (g_iCvars[iStatTrackCost] > g_iUserDusts[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CRAFT_NOT_ENOUGH", g_iCvars[iStatTrackCost] - g_iUserDusts[id]);
				_ShowOpenCaseCraftMenu(id);
			}
			else
			{
				if(g_iCvars[iAntiSpam] || g_iCvars[iShowDropCraft])
				{
					if (get_systime() < g_iLastOpenCraft[id] + 5)
					{
						client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DONT_SPAM", 5);
						_ShowOpenCaseCraftMenu(id);
						return PLUGIN_HANDLED;
					}
				}
				_CraftStattrackSkin(id);
			}
		}
	}
	return _MenuExit(menu);
}

public _OpenCase(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_OpenCase()")
	#endif

	if(!g_bLogged[id])
	{
		return PLUGIN_HANDLED;
	}

	new timer;
	new bool:succes;
	new rSkin;
	new rChance;
	new skinID;
	new wChance;
	new run;

	if (0 >= g_iDropSkinNum)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NO_DROP_SKINS");
		_ShowOpenCaseCraftMenu(id);
		return PLUGIN_HANDLED
	}

	do {
		rSkin = random_num(0, g_iDropSkinNum -1);
		rChance = random_num(1, 100);

		skinID = ArrayGetCell(g_aDropSkin, rSkin);
		wChance = ArrayGetCell(g_aSkinChance, skinID);
		if (rChance >= wChance)
		{
			succes = true;
		}

		timer++;

		if (!(timer < 5 && !succes))
		{
			break;
		}
	} while (run);


	if (succes)
	{
		new Skin[48];
		ArrayGetString(g_aSkinName, skinID, Skin, charsmax(Skin));
		g_iUserSkins[id][skinID]++;
		g_iUserCases[id]--;
		g_iUserKeys[id]--;
		_Save(id);

		if (0 < g_iCvars[iShowDropCraft])
		{
			client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DROP_SUCCESS_ALL", g_szName[id], Skin, 100 - wChance);
		}
		else
		{
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DROP_SUCCESS", Skin, 100 - wChance);
		}

		g_iLastOpenCraft[id] = get_systime();
		_ShowOpenCaseCraftMenu(id);
		ExecuteForward(g_iForwards[ user_case_opening ], g_iForwardResult, id);
	}
	else
	{
		_ShowOpenCaseCraftMenu(id);
	}
	return PLUGIN_CONTINUE;
}

public _CraftSkin(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_CraftSkin()")
	#endif

	if(!g_bLogged[id])
	{
		return PLUGIN_HANDLED;
	}
	new timer;
	new bool:succes;
	new rSkin;
	new rChance;
	new skinID;
	new wChance;
	new run;

	if (0 >= g_iCraftSkinNum)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NO_CRAFT_SKINS");
		_ShowOpenCaseCraftMenu(id);
		return PLUGIN_HANDLED;
	}

	do {
		rSkin = random_num(0, g_iCraftSkinNum -1);
		rChance = random_num(1, 100);
		
		skinID = ArrayGetCell(g_aCraftSkin, rSkin);
		wChance = ArrayGetCell(g_aSkinChance, skinID);
		if (rChance >= wChance)
		{
			succes = true;
		}

		timer++;

		if (!(timer < 5 && !succes))
		{
			break;
		}
	} while (run);

	if (succes)
	{
		new Skin[48];
		ArrayGetString(g_aSkinName, skinID, Skin, charsmax(Skin));
		g_iUserSkins[id][skinID]++;
		g_iUserDusts[id] -= g_iCvars[iCraftCost];
		if (0 < g_iCvars[iShowDropCraft])
		{
			client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CRAFT_SUCCESS_ALL", g_szName[id], Skin, 100 - wChance);
		}
		else
		{
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CRAFT_SUCCESS", Skin, 100 - wChance);
		}
		_Save(id);
		g_iLastOpenCraft[id] = get_systime();
		_ShowOpenCaseCraftMenu(id);
		ExecuteForward(g_iForwards[ user_craft ], g_iForwardResult, id);
	}
	else
	{
		_ShowOpenCaseCraftMenu(id);
	}
	return PLUGIN_CONTINUE;
}

public _CraftStattrackSkin(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_CraftStattrackSkin()")
	#endif

	if(!g_bLogged[id])
	{
		return PLUGIN_HANDLED;
	}
	new timer;
	new bool:succes;
	new rChance;
	new skinID;
	new wChance;
	new run;

	if (0 >= g_iCraftSkinNum)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NO_CRAFT_SKINS");
		_ShowOpenCaseCraftMenu(id);
		return PLUGIN_HANDLED;
	}

	do {
		rChance = random_num(1, 100);
		
		skinID = random(g_iSkinsNum - 1);
		wChance = ArrayGetCell(g_aSkinChance, skinID);
		if (rChance >= wChance)
		{
			succes = true;
		}

		timer++;

		if (!(timer < 5 && !succes))
		{
			break;
		}
	} while (run);

	if (succes)
	{
		new Skin[MAX_SKIN_NAME], szTemp[MAX_SKIN_NAME];
		ArrayGetString(g_aSkinName, skinID, Skin, charsmax(Skin));
		FormatStattrack(Skin, charsmax(Skin), szTemp);
		g_iStattrackWeap[id][iWeap][skinID]++;
		g_iUserDusts[id] -= g_iCvars[iStatTrackCost];
		if (0 < g_iCvars[iShowDropCraft])
		{
			client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CRAFT_SUCCESS_ALL", g_szName[id], szTemp, 100 - wChance);
		}
		else
		{
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CRAFT_SUCCESS", szTemp, 100 - wChance);
		}
		_Save(id);
		g_iLastOpenCraft[id] = get_systime();
		_ShowOpenCaseCraftMenu(id);
		ExecuteForward(g_iForwards[ user_craft ], g_iForwardResult, id);
	}
	else
	{
		_ShowOpenCaseCraftMenu(id);
	}
	return PLUGIN_CONTINUE;
}

public _ShowMarketMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowMarketMenu()")
	#endif

	new temp[96];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_MARKET_MENU");
	new menu = menu_create(temp, "market_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	new szSkin[48];
	if (!_IsGoodItem(g_iUserSellItem[id]))
	{
		formatex(temp, charsmax(temp), "\y%L", LANG_SERVER, "CSGOR_MR_SELECT_ITEM");
	}
	else
	{
		_GetItemName(g_iUserSellItem[id], szSkin, 47);
		formatex(temp, charsmax(temp), "\w%L^n\w%L", LANG_SERVER, "CSGOR_MR_SELL_ITEM", szSkin, LANG_SERVER, "CSGOR_MR_PRICE", g_iUserItemPrice[id]);
	}
	szItem[0] = 33;
	menu_additem(menu, temp, szItem);
	if (g_bUserSell[id])
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_MR_CANCEL_SELL");
		szItem[0] = 35;
		menu_additem(menu, temp, szItem);
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_MR_START_SELL");
		szItem[0] = 34;
		menu_additem(menu, temp, szItem);
	}
	new Pl[32];
	new n;
	new p;
	get_players(Pl, n, "ch", "");
	if (n)
	{
		new items;
		new sType[2];
		for (new i; i < n; i++)
		{
			p = Pl[i];
			if (g_bLogged[p])
			{
				if (!(p == id))
				{
					if (g_bUserSell[p])
					{
						new index = g_iUserSellItem[p];

						_GetItemName(index, szSkin, 47);
						if (_IsItemSkin(index))
						{
							ArrayGetString(g_aSkinType, index, sType, charsmax(sType));
						}
						else
						{
							formatex(sType, charsmax(sType), "d");
						}
						formatex(temp, charsmax(temp), "\w%s | \r%s \y%s\w| \y%d %L", g_szName[p], szSkin, equal(sType, "c") ? "*" : "", g_iUserItemPrice[p], LANG_SERVER, "CSGOR_POINTS");
						szItem[0] = p;
						menu_additem(menu, temp, szItem);
						items++;
					}
				}
			}
		}
		if (!items)
		{
			formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_NOBODY_SELL");
			szItem[0] = -10;
			menu_additem(menu, temp, szItem);
		}
	}
	_DisplayMenu(id, menu);
}

public market_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "market_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	menu_item_getinfo(menu, item, dummy, itemdata, 1);
	index = itemdata[0];
	switch (index)
	{
		case -10:
		{
			_ShowMarketMenu(id);
		}
		case 33:
		{
			if (g_bUserSell[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_CANCEL");
				_ShowMarketMenu(id);
			}
			else
			{
				_ShowItems(id);
			}
		}
		case 34:
		{
			if (!_IsGoodItem(g_iUserSellItem[id]))
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_SELECT");
				_ShowMarketMenu(id);
			}
			else
			{
				if ( g_iCvars[iWaitForPlace] > ( get_systime() - g_iLastPlace[id] ) )
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_MUST_WAIT", get_systime() - g_iLastPlace[id] );
					return PLUGIN_HANDLED;
				}
				if (g_iUserItemPrice[id] < 1)
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, id, "CSGOR_IM_SET_PRICE");
					_ShowMarketMenu(id);
				}
				new wPriceMin;
				new wPriceMax;
				_CalcItemPrice(g_iUserSellItem[id], wPriceMin, wPriceMax);
				if (!(wPriceMin <= g_iUserItemPrice[id] <= wPriceMax))
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ITEM_MIN_MAX_COST", wPriceMin, wPriceMax);
					_ShowMarketMenu(id);
					return _MenuExit(menu);
				}
				g_bUserSell[id] = true;
				g_iLastPlace[id] = get_systime();
				new Item[32];
				_GetItemName(g_iUserSellItem[id], Item, charsmax(Item));
				client_print_color(0, print_chat, "^4%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_SELL_ANNOUNCE", g_szName[id], Item, g_iUserItemPrice[id]);
			}
		}
		case 35:
		{
			g_bUserSell[id] = false;
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_CANCEL_SELL");
			_ShowMarketMenu(id);
		}
		default:
		{
			new tItem = g_iUserSellItem[index];
			new price = g_iUserItemPrice[index];
			if (!g_bLogged[index] || !is_user_connected(index))
			{
				goto _Return;
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_SELLER");
				g_bUserSell[index] = false;
				_ShowMarketMenu(id);
			}
			else
			{
				if (!_UserHasItem(index, tItem))
				{
					goto _Return;
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DONT_HAVE_ITEM");
					g_bUserSell[index] = false;
					g_iUserSellItem[index] = -1;
					_ShowMarketMenu(id);
				}
				if (price > g_iUserPoints[id] || g_iUserPoints[id] <= 0)
				{
					goto _Return;
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NOT_ENOUGH_POINTS", price - g_iUserPoints[id]);
					_ShowMarketMenu(id);
				}
				new szItem[32];
				_GetItemName(g_iUserSellItem[index], szItem, charsmax(szItem));
				switch (tItem)
				{
					case KEY:
					{
						g_iUserKeys[id]++;
						g_iUserKeys[index]--;
						g_iUserPoints[id] -= price;
						g_iUserPoints[index] += price;
						_Save(id);
						_Save(index);
						client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_X_BUY_Y", g_szName[id], szItem, g_szName[index]);
					}
					case CASE:
					{
						g_iUserCases[id]++;
						g_iUserCases[index]--;
						g_iUserPoints[id] -= price;
						g_iUserPoints[index] += price;
						_Save(id);
						_Save(index);
						client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_X_BUY_Y", g_szName[id], szItem, g_szName[index]);
					}
					default:
					{
						g_iUserSkins[id][tItem]++;
						g_iUserSkins[index][tItem]--;
						g_iUserPoints[id] -= price;
						g_iUserPoints[index] += price;
						_Save(id);
						_Save(index);
						client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_X_BUY_Y", g_szName[id], szItem, g_szName[index]);
					}
				}
				g_iUserSellItem[index] = -1;
				g_bUserSell[index] = false;
				g_iUserItemPrice[index] = 0;
				_ShowMainMenu(id);
			}
		}
	}
	_Return:
	return _MenuExit(menu);
}

public _ShowItems(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowItems()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_ITEM_MENU");
	new menu = menu_create(temp, "item_menu_handler");
	new szItem[32];
	new total;
	if (0 < g_iUserCases[id])
	{
		formatex(temp, charsmax(temp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_CASE", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserCases[id]);
		num_to_str(CASE, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
		total++;
	}
	if (0 < g_iUserKeys[id])
	{
		formatex(temp, charsmax(temp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_KEY", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserKeys[id]);
		num_to_str(KEY, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
		total++;
	}
	new szSkin[48];
	new num;
	new type[2];
	for (new i; i < g_iSkinsNum; i++)
	{
		num = g_iUserSkins[id][i];
		if (0 < num)
		{
			ArrayGetString(g_aSkinName, i, szSkin, charsmax(szSkin));
			ArrayGetString(g_aSkinType, i, type, 1);
			formatex(temp, charsmax(temp), "\r%s \w| \y%L \r%s", szSkin, LANG_SERVER, "CSGOR_SM_PIECES", num, type[0] == 'c' ? "#" : "" );
			num_to_str(i, szItem, charsmax(szItem));
			menu_additem(menu, temp, szItem);
			total++;
		}
	}
	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_NO_ITEMS");
		num_to_str(-10, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public item_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "item_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMarketMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);
	if (item == -10)
	{
		_ShowMarketMenu(id);
		return _MenuExit(menu);
	}
	else
	{
		new szItem[32];
		_GetItemName(item, szItem, charsmax(szItem));
		new iLocked;
		iLocked = ArrayGetCell(g_aLockSkin, item)

		if(iLocked)
		{
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ITEM_LOCKED", szItem)
			_ShowMarketMenu(id)
			return _MenuExit(menu)
		}
		
		g_iUserSellItem[id] = item;
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_IM_SELECT", szItem);
		client_cmd(id, "messagemode ItemPrice");
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_IM_SET_PRICE");
	}
	return _MenuExit(menu);
}

public concmd_itemprice(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_itemprice()")
	#endif

	new item = g_iUserSellItem[id];
	if (!_IsGoodItem(item))
	{
		return PLUGIN_HANDLED;
	}
	new data[16];
	read_args(data, 15);
	remove_quotes(data);
	new uPrice;
	new wPriceMin;
	new wPriceMax;
	uPrice = str_to_num(data);
	_CalcItemPrice(item, wPriceMin, wPriceMax);
	if (uPrice < wPriceMin || uPrice > wPriceMax)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ITEM_MIN_MAX_COST", wPriceMin, wPriceMax);
		client_cmd(id, "messagemode ItemPrice");
		return PLUGIN_HANDLED;
	}
	g_iUserItemPrice[id] = uPrice;
	_ShowMarketMenu(id);
	return PLUGIN_HANDLED;
}

public clcmd_say_bonus(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_bonus()")
	#endif

	if (g_bLogged[id])
	{
		_ShowBonusMenu(id);
	}
	else
	{
		client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BONUS_NOT_LOGGED");
	}
	return PLUGIN_HANDLED;
}

public _ShowBonusMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowBonusMenu()")
	#endif

	new bool:bShow = false
	new iTimestamp, szVal[ 10 ]
	new szCheckData[35]
	new iNum = g_iCvars[iCheckBonusType]

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

	switch(g_iCvars[iSaveType])
	{
		case NVAULT:
		{
			if(!nvault_lookup( g_nVault , szCheckData , szVal , charsmax( szVal ) , iTimestamp ) || ( iTimestamp && ( ( get_systime() - iTimestamp ) >= ((60 * 60) * g_iCvars[iTimeDelete]))))
			{
				bShow = true
			}
		}
		case MYSQL:
		{
			new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_data` WHERE `%s` = ^"%s^";", iNum == 0 ? "Last IP" : "SteamID", szCheckData)
			
			if(!SQL_Execute(iQuery))
			{
				SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError))
				log_to_file("csgo_remake_errors.log", "SQL Error: %s", g_szSqlError)
				SQL_FreeHandle(iQuery)
			}

			if(SQL_NumResults(iQuery) > 0)
			{
				for(new i; i < SQL_NumResults(iQuery); i++)
				{
					iTimestamp = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Bonus Timestamp"))

					if(get_systime() - iTimestamp <= (60 * 60 * g_iCvars[iTimeDelete]))
					{
						new szQuery[128]
						formatex(szQuery, charsmax(szQuery), "UPDATE `csgor_data` \
							SET `Bonus Timestamp`=^"%d^" \
							WHERE `Name`=^"%s^";", iTimestamp, g_szName[id])

						SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)

						bShow = false
						break
					}

					bShow = true

					SQL_NextRow(iQuery)
				}
			}
		}
	}

	if(g_bLogged[id])
	{
		if(bShow)
		{
			new temp[64]
			formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_BONUS_MENU")
			new menu = menu_create(temp, "bonus_menu_handler")
			new szItem[2]
			szItem[1] = 0
			formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_BONUS_SCRAPS")
			menu_additem(menu, temp, szItem)
			formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_BONUS_CASES")
			menu_additem(menu, temp, szItem)
			formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_BONUS_POINTSM")
			menu_additem(menu, temp, szItem)
			formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_BONUS_SKIN")
			menu_additem(menu, temp, szItem)
			
			_DisplayMenu(id, menu)
		}
		else
		{
			client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BONUS_TAKEN", UnixTimeToString(iTimestamp))
			return PLUGIN_HANDLED
		}
	}
	else 
	{
		client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BONUS_NOT_LOGGED")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public bonus_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "bonus_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}
	
	new szMin[8], szMax[8], szSkinMin[8], szSkinMax[8]
	parse(g_iCvars[szBonusValues], szMin, charsmax(szMin), szMax, charsmax(szMax), szSkinMin, charsmax(szSkinMin), szSkinMax, charsmax(szSkinMax))

	new rand = random_num(str_to_num(szMin), str_to_num(szMax))
	new skinRand = random_num(str_to_num(szSkinMin), str_to_num(szSkinMax))
	new bool:bBonus

	switch(item)
	{
		case 0:
		{
			bBonus = true
			g_iUserDusts[id] += rand
			client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BONUS_GOT_DUSTS", rand)
		}
		case 1:
		{
			bBonus = true

			g_iUserCases[id] += rand
			g_iUserKeys[id] += rand
			if(rand == 1)
				client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BONUS_GOT_CASE", rand, rand)
			else
				client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BONUS_GOT_CASES", rand, rand)
		}
		case 2:
		{
			bBonus = true 

			g_iUserPoints[id] += rand
			client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BONUS_GOT_POINTS", rand)
		}
		case 3:
		{
			bBonus = true 

			new szSkin[48]
			ArrayGetString(g_aSkinName, skinRand, szSkin, charsmax(szSkin))
			g_iUserSkins[id][skinRand]++
			client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BONUS_GOT_SKIN", szSkin)
		}
	}

	if(bBonus)
	{
		switch(g_iCvars[iSaveType])
		{
			case NVAULT:
			{
				nvault_set( g_nVault, g_iCvars[iCheckBonusType] == 0 ? g_szUserLastIP[id] : g_szSteamID[id], "bonus_csgo" )
			}
			case MYSQL:
			{
				new szQuery[128]
				formatex(szQuery, charsmax(szQuery), "UPDATE `csgor_data` \
					SET `Bonus Timestamp`=^"%d^" \
					WHERE `Name`=^"%s^";", get_systime(), g_szName[id])

				SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery)
			}
		}
	}
	return PLUGIN_HANDLED;
}

public _ShowDustbinMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowDustbinMenu()")
	#endif

	new temp[MAX_SKIN_NAME];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_DB_MENU");
	new menu = menu_create(temp, "dustbin_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	formatex(temp, charsmax(temp), "\y%L\n", LANG_SERVER, "CSGOR_DB_TRANSFORM");
	szItem[0] = 1;
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_DB_DESTROY");
	szItem[0] = 2;
	menu_additem(menu, temp, szItem);
	_DisplayMenu(id, menu);
}

public dustbin_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "dustbin_menu_handlerb()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	menu_item_getinfo(menu, item, dummy, itemdata, 1);
	index = itemdata[0];
	g_iMenuType[id] = index;
	_ShowSkins(id);
	return _MenuExit(menu);
}

public _ShowSkins(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowSkins()")
	#endif

	new temp[MAX_SKIN_NAME];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_SKINS");
	new menu = menu_create(temp, "db_skins_menu_handler");
	new szItem[32];
	new szSkin[48];
	new num;
	new type[2];
	new total;
	for (new i; i < g_iSkinsNum; i++)
	{
		num = g_iUserSkins[id][i];
		if (0 < num)
		{
			ArrayGetString(g_aSkinName, i, szSkin, charsmax(szSkin));
			ArrayGetString(g_aSkinType, i, type, 1);
			new applied[3];
			switch (type[0])
			{
				case 'c':
				{
					applied = "#";
				}
				
				default:
				{
					applied = "";
				}
			}
			formatex(temp, charsmax(temp), "\r%s \w| \y%L \r%s", szSkin, LANG_SERVER, "CSGOR_SM_PIECES", num, applied);
			num_to_str(i, szItem, charsmax(szItem));
			menu_additem(menu, temp, szItem);
			total++;
		}
	}
	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_SM_NO_SKINS");
		num_to_str(-10, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public db_skins_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "db_skins_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowDustbinMenu(id);
		}
		return _MenuExit(menu);
	}
	if(!g_bLogged[id])
	{
		return _MenuExit(menu);
	}
	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);
	if (item == -10)
	{
		_ShowMainMenu(id);
		return _MenuExit(menu);
	}

	new Skin[48];
	ArrayGetString(g_aSkinName, item, Skin, charsmax(Skin));

	new iLocked = ArrayGetCell(g_aLockSkin, item);
	
	if(iLocked)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ITEM_LOCKED", Skin);
	}
	else
	{
		switch (g_iMenuType[id])
		{
			case 1:
			{
				g_iUserSkins[id][item]--;
				new DustsFromSkin = ArrayGetCell(g_aDustsSkin, item);
				g_iUserDusts[id] += DustsFromSkin;
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRANSFORM", Skin, DustsFromSkin);
				_Save(id);
			}
			case 2:
			{
				g_iUserSkins[id][item]--;
				new sPrice = ArrayGetCell(g_aSkinCostMin, item);
				new rest = sPrice / g_iCvars[iReturnPercent];
				g_iUserPoints[id] += rest;
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DESTORY", Skin, rest);
				_Save(id);
			}
		}
	}
	
	g_iMenuType[id] = 0;
	_ShowDustbinMenu(id);
	return _MenuExit(menu);
}

public _ShowGiftTradeMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowGiftTradeMenu()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_GIFT_TRADE_MENU");
	new menu = menu_create(temp, "gift_trade_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_MM_GIFT");
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_MM_TRADE");
	menu_additem(menu, temp, szItem);
	
	_DisplayMenu(id, menu);
}

public gift_trade_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "gift_trade_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		return _MenuExit(menu);
	}
	switch(item)
	{
		case 0:
		{
			_ShowGiftMenu(id);
		}
		case 1:
		{
			_ShowTradeMenu(id);
		}
	}
	return _MenuExit(menu);
}

public _ShowGiftMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowGiftMenu")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_GIFT_MENU");
	new menu = menu_create(temp, "gift_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	new bool:HasTarget;
	new bool:HasItem;
	new target = g_iGiftTarget[id];
	if (is_user_connected(target))
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GM_TARGET", g_szName[target]);
		szItem[0] = 0;
		menu_additem(menu, temp, szItem);
		HasTarget = true;
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_GM_SELECT_TARGET");
		szItem[0] = 0;
		menu_additem(menu, temp, szItem);
	}

	if (!_IsGoodItem(g_iGiftItem[id]))
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_GM_SELECT_ITEM");
		szItem[0] = 1;
		menu_additem(menu, temp, szItem);
	}
	else
	{
		new Item[32];
		_GetItemName(g_iGiftItem[id], Item, charsmax(Item));
		formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_GM_ITEM", Item);
		szItem[0] = 1;
		menu_additem(menu, temp, szItem);
		HasItem = true;
	}
	if (HasTarget && HasItem)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_GM_SEND");
		szItem[0] = 2;
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public gift_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "gift_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	menu_item_getinfo(menu, item, dummy, itemdata, 1);
	index = itemdata[0];
	if(item == -10)
	{
		_ShowGiftMenu(id);
		return _MenuExit(menu);
	}
	switch (index)
	{
		case 0:
		{
			_SelectTarget(id);
		}
		case 1:
		{
			_SelectItem(id);
		}
		case 2:
		{
			new target = g_iGiftTarget[id];
			new _item = g_iGiftItem[id];
			if (!g_bLogged[target] || !is_user_connected(target))
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_TARGET");
				g_iGiftTarget[id] = 0;
				_ShowGiftMenu(id);
			}
			else
			{
				if (!_UserHasItem(id, _item))
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NOT_ENOUGH_ITEMS");
					g_iGiftItem[id] = -1;
					_ShowGiftMenu(id);
				}

				new gift[16];
				switch (_item)
				{
					case KEY:
					{
						g_iUserKeys[id]--;
						g_iUserKeys[target]++;
						formatex(gift, 15, "%L", id, "CSGOR_ITEM_KEY");
						client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_SEND_GIFT", gift, g_szName[target]);
						client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_RECIEVE_GIFT", g_szName[id], gift);
					}
					case CASE:
					{
						g_iUserCases[id]--;
						g_iUserCases[target]++;
						formatex(gift, 15, "%L", id, "CSGOR_ITEM_CASE");
						client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_SEND_GIFT", gift, g_szName[target]);
						client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_RECIEVE_GIFT", g_szName[id], gift);
					}
					default:
					{
						g_iUserSkins[id][_item]--;
						g_iUserSkins[target][_item]++;
						new Skin[32];
						_GetItemName(g_iGiftItem[id], Skin, charsmax(Skin));
						client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_SEND_GIFT", Skin, g_szName[target]);
						client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_RECIEVE_GIFT", g_szName[id], Skin);
					}
				}
				g_iGiftTarget[id] = 0;
				g_iGiftItem[id] = -1;
				_ShowMainMenu(id);
			}
		}
	}
	return _MenuExit(menu);
}

public _SelectTarget(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_SelectTarget()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \y%L", CSGO_TAG, LANG_SERVER, "CSGOR_GM_SELECT_TARGET");
	new menu = menu_create(temp, "st_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	new Pl[32];
	new n;
	new p;
	get_players(Pl, n, "h");
	new total;
	if (n)
	{
		for (new i; i < n; i++)
		{
			p = Pl[i];
			if (g_bLogged[p])
			{
				if (!(p == id))
				{
					szItem[0] = p;
					menu_additem(menu, g_szName[p], szItem);
					total++;
				}
			}
		}
	}
	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_ST_NO_PLAYERS");
		szItem[0] = -10;
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public st_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "st_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGiftMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	new name[32];
	menu_item_getinfo(menu, item, dummy, itemdata, charsmax(itemdata), name, charsmax(name), dummy);
	index = itemdata[0];
	switch (index)
	{
		case -10:
		{
			_ShowMainMenu(id);
		}
		default:
		{
			g_iGiftTarget[id] = index;
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_YOUR_TARGET", name);
			_ShowGiftMenu(id);
		}
	}
	return _MenuExit(menu);
}

public _SelectItem(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_SelectItem()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_ITEM_MENU");
	new menu = menu_create(temp, "si_menu_handler");
	new szItem[32];
	new total;
	if (0 < g_iUserCases[id])
	{
		formatex(temp, charsmax(temp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_CASE", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserCases[id]);
		num_to_str(CASE, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
		total++;
	}
	if (0 < g_iUserKeys[id])
	{
		formatex(temp, charsmax(temp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_KEY", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserKeys[id]);
		num_to_str(KEY, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
		total++;
	}
	new szSkin[48];
	new num;
	new type[2];
	new iLocked;
	for (new i; i < g_iSkinsNum; i++)
	{
		num = g_iUserSkins[id][i];
		if (0 < num)
		{
			iLocked = ArrayGetCell(g_aLockSkin, i);

			if(iLocked == 1)
				continue

			ArrayGetString(g_aSkinName, i, szSkin, charsmax(szSkin));
			ArrayGetString(g_aSkinType, i, type, 1);

			switch (type[0])
			{
				case 99:
				{
					formatex(temp, charsmax(temp), "\r%s \w| \y%L \r#", szSkin, LANG_SERVER, "CSGOR_SM_PIECES", num);
				}
				
				default:
				{
					formatex(temp, charsmax(temp), "\r%s \w| \y%L \r", szSkin, LANG_SERVER, "CSGOR_SM_PIECES", num);
				}
			}
			num_to_str(i, szItem, charsmax(szItem));
			menu_additem(menu, temp, szItem);
			total++;
		}
	}
	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", id, "CSGOR_NO_ITEMS");
		num_to_str(-10, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public si_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "si_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGiftMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);
	switch (item)
	{
		case -10:
		{
			_ShowMainMenu(id);
		}
		default:
		{
			if (item == g_iUserSellItem[id] && g_bUserSell[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_GIFT");
				_SelectItem(id);
			}
			else
			{
				g_iGiftItem[id] = item;
				new szItem[32];
				_GetItemName(item, szItem, charsmax(szItem));
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_YOUR_GIFT", szItem);
				_ShowGiftMenu(id);
			}
		}
	}
	return _MenuExit(menu);
}

public Message_DeathMsg(msgId, msgDest, msgEnt)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Message_DeathMsg()")
	#endif

	return PLUGIN_HANDLED;
}


public hook_say(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "hook_say()")
	#endif

	if(!is_user_connected(id) || !g_iCvars[iCustomChat])
		return

	new szMessage[128]
	read_argv(1, szMessage, charsmax(szMessage))

	ProcessChat(id, szMessage, true)
}

public hook_sayteam(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "hook_sayteam()")
	#endif

	if(!is_user_connected(id) || !g_iCvars[iCustomChat])
		return

	new szMessage[128]
	read_argv(1, szMessage, charsmax(szMessage))

	ProcessChat(id, szMessage, false)
}

ProcessChat(id, szMessage[128], bool:bAllChat)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "ProcessChat()")
	#endif

	/* Fixing % chat exploits */
	if(containi(szMessage, "%") != -1)
	{
		replace_all(szMessage, charsmax(szMessage), "%", "")		
	}
	trim(szMessage)

	if(!strlen(szMessage))
		return

	new iSize = ArraySize(g_aSkipChat);

	if(iSize)
	{
		new szChatSkip[20], bool:bFound = false
		for(new i; i < iSize; i++)
		{
			ArrayGetString(g_aSkipChat, i, szChatSkip, charsmax(szChatSkip));

			if(equali(szMessage, szChatSkip, strlen(szChatSkip)))
			{
				bFound = true;
				break;
			}
		}

		if(bFound)
			return;
	}

	new iChat;
	new CsTeams:iTeams = cs_get_user_team(id)
	new szSaid[128];
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
		new szRank[MAX_RANK_NAME];
		ArrayGetString(g_aRankName, g_iUserRank[id], szRank, charsmax(szRank));
		new len = strlen(g_szUserPrefix[id]);
		new tag[20];
		if(len > 3)
		{
			formatex(tag, charsmax(tag), "[%s]", g_szUserPrefix[id]);
		}
		else
		{
			copy(tag, charsmax(tag), g_szUserPrefix[id]);
		}

		switch (iChat)
		{
			case AllChat:
			{
				formatex(szMessage, charsmax(szMessage), "^4[%s] ^1%s%s ^3%n ^1: %s", szRank, (len > 0) ? g_szUserPrefixColor[id] : "^1", tag, id, szSaid);
			}
			case DeadChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*DEAD* ^4[%s] ^1%s%s ^3%n ^1: %s", szRank, (len > 0) ? g_szUserPrefixColor[id] : "^1", tag, id, szSaid);
			}
			case SpecChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*SPEC* ^4[%s] ^1%s%s ^3%n ^1: %s", szRank, (len > 0) ? g_szUserPrefixColor[id] : "^1", tag, id, szSaid);
			}
			case CTChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*CT* ^4[%s] ^1%s%s ^3%n ^1: %s", szRank, (len > 0) ? g_szUserPrefixColor[id] : "^1", tag, id, szSaid);
			}
			case TeroChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*Terrorist* ^4[%s] ^1%s%s ^3%n ^1: %s", szRank, (len > 0) ? g_szUserPrefixColor[id] : "^1", tag, id, szSaid);
			}
		}
	}
	else
	{
		switch (iChat)
		{
			case AllChat:
			{
				formatex(szMessage, charsmax(szMessage), "^4[%L] ^3%n ^1: %s", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT", id, szSaid);
			}
			case DeadChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*DEAD* ^4[%L] ^3%n ^1: %s", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT", id, szSaid);
			}
			case SpecChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*SPEC* ^4[%L] ^3%n ^1: %s", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT", id, szSaid);
			}
			case CTChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*CT* ^4[%L] ^3%n ^1: %s", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT", id, szSaid);
			}
			case TeroChat:
			{
				formatex(szMessage, charsmax(szMessage), "^1*Terrorist* ^4[%L] ^3%n ^1: %s", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT", id, szSaid);
			}
		}
	}

	new iPlayer, iPlayers[MAX_PLAYERS], iNum
	get_players(iPlayers, iNum, "c")

	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i];

		if(!is_user_connected(iPlayer))
			continue

		if(!bAllChat)
		{
			if(get_user_team(id) != get_user_team(iPlayer))
			{
				continue
			}
		}

		message_begin(MSG_ONE_UNRELIABLE, g_Msg_SayText, .player = iPlayer);
		write_byte(id);
		write_string(szMessage);
		message_end();
	}

	return
}

public Message_SayText(msgId, msgDest, msgEnt)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "Message_SayText()")
	#endif

	return PLUGIN_HANDLED
}

public _ShowTradeMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowTradeMenu()")
	#endif

	if (g_bTradeAccept[id])
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_INFO2");
	}
	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_MENU");
	new menu = menu_create(temp, "trade_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	new bool:HasTarget;
	new bool:HasItem;
	new target = g_iTradeTarget[id];
	if (is_user_connected(target))
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GM_TARGET", g_szName[target]);
		szItem[0] = 0;
		menu_additem(menu, temp, szItem);
		HasTarget = true;
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_GM_SELECT_TARGET");
		szItem[0] = 0;
		menu_additem(menu, temp, szItem);
	}
	if (!_IsGoodItem(g_iTradeItem[id]))
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_GM_SELECT_ITEM");
		szItem[0] = 1;
		menu_additem(menu, temp, szItem);
	}
	else
	{
		new Item[32];
		_GetItemName(g_iTradeItem[id], Item, charsmax(Item));
		formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_GM_ITEM", Item);
		szItem[0] = 1;
		menu_additem(menu, temp, szItem);
		HasItem = true;
	}
	if (HasTarget && HasItem && !g_bTradeActive[id])
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_GM_SEND");
		szItem[0] = 2;
		menu_additem(menu, temp, szItem);
	}
	if (g_bTradeActive[id] || g_bTradeSecond[id])
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_TRADE_CANCEL");
		szItem[0] = 3;
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public trade_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "trade_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if (g_bTradeSecond[id])
		{
			clcmd_say_deny(id);
		}
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	menu_item_getinfo(menu, item, dummy, itemdata, 1);
	index = itemdata[0];
	switch (index)
	{
		case 0:
		{
			if (g_bTradeActive[id] || g_bTradeSecond[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_LOCKED");
				_ShowTradeMenu(id);
			}
			else
			{
				_SelectTradeTarget(id);
			}
		}
		case 1:
		{
			if (g_bTradeActive[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_LOCKED");
				_ShowTradeMenu(id);
			}
			else
			{
				_SelectTradeItem(id);
			}
		}
		case 2:
		{
			new target = g_iTradeTarget[id];
			new _item = g_iTradeItem[id];
			if (!g_bLogged[target] || !is_user_connected(target))
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_TARGET");
				_ResetTradeData(id);
				_ShowTradeMenu(id);
			}
			else
			{
				if (!_UserHasItem(id, _item))
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NOT_ENOUGH_ITEMS");
					g_iTradeItem[id] = -1;
					_ShowTradeMenu(id);
				}
				if (g_bTradeSecond[id] && !_UserHasItem(target, g_iTradeItem[target]))
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_FAIL");
					client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_FAIL");
					_ResetTradeData(id);
					_ResetTradeData(target);
					_ShowTradeMenu(id);
				}
				g_bTradeActive[id] = true;
				g_iTradeRequest[target] = id;
				new szItem[32];
				_GetItemName(g_iTradeItem[id], szItem, charsmax(szItem));
				if (!g_bTradeSecond[id])
				{
					client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_INFO1", g_szName[id], szItem);
					client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_INFO2");
				}
				else
				{
					new yItem[32];
					_GetItemName(g_iTradeItem[target], yItem, charsmax(yItem));
					client_print_color(target, print_chat, "^4%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_INFO3", g_szName[id], szItem, yItem);
					client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_INFO2");
					g_bTradeAccept[target] = true;
				}
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_SEND", g_szName[target]);
			}
		}
		case 3:
		{
			if (g_bTradeSecond[id])
			{
				clcmd_say_deny(id);
			}
			else
			{
				_ResetTradeData(id);
			}
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_CANCELED");
			_ShowTradeMenu(id);
		}
	}
	return _MenuExit(menu);
}

public _SelectTradeTarget(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_SelectTradeTarget()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \y%L", CSGO_TAG, LANG_SERVER, "CSGOR_GM_SELECT_TARGET");
	new menu = menu_create(temp, "tst_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	new Pl[32];
	new n;
	new p;
	get_players(Pl, n, "h");
	new total;
	if (n)
	{
		for (new i; i < n; i++)
		{
			p = Pl[i];
			if (g_bLogged[p])
			{
				if (!(p == id))
				{
					szItem[0] = p;
					menu_additem(menu, g_szName[p], szItem);
					total++;
				}
			}
		}
	}
	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_ST_NO_PLAYERS");
		szItem[0] = -10;
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public tst_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "tst_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowTradeMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	new name[32];
	menu_item_getinfo(menu, item, dummy, itemdata, charsmax(itemdata), name, charsmax(name), dummy);
	index = itemdata[0];
	switch (index)
	{
		case -10:
		{
			_ShowMainMenu(id);
		}
		default:
		{
			if (g_iTradeRequest[index])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TARGET_TRADE_ACTIVE", name);
			}
			else
			{
				g_iTradeTarget[id] = index;
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_YOUR_TARGET", name);
			}
			_ShowTradeMenu(id);
		}
	}
	return _MenuExit(menu);
}

public _SelectTradeItem(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_SelectTradeItem()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_ITEM_MENU");
	new menu = menu_create(temp, "tsi_menu_handler");
	new szItem[32];
	new total;
	if (0 < g_iUserCases[id])
	{
		formatex(temp, charsmax(temp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_CASE", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserCases[id]);
		num_to_str(CASE, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
		total++;
	}
	if (0 < g_iUserKeys[id])
	{
		formatex(temp, charsmax(temp), "\r%L \w| \y%L", LANG_SERVER, "CSGOR_ITEM_KEY", LANG_SERVER, "CSGOR_SM_PIECES", g_iUserKeys[id]);
		num_to_str(KEY, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
		total++;
	}
	new szSkin[48];
	new num;
	new type[2];
	new iLocked;
	for (new i; i < g_iSkinsNum; i++)
	{
		num = g_iUserSkins[id][i];
		if (0 < num)
		{
			iLocked = ArrayGetCell(g_aLockSkin, i);

			if(iLocked == 1)
				continue

			ArrayGetString(g_aSkinName, i, szSkin, charsmax(szSkin));
			ArrayGetString(g_aSkinType, i, type, 1);

			new applied[3];
			switch (type[0])
			{
				case 99:
				{
					applied = "#";
				}
				
				default:
				{
					applied = "";
				}
			}
			formatex(temp, charsmax(temp), "\r%s \w| \y%L \r%s", szSkin, LANG_SERVER, "CSGOR_SM_PIECES", num, applied);
			num_to_str(i, szItem, charsmax(szItem));
			menu_additem(menu, temp, szItem);
			total++;
		}
	}
	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_NO_ITEMS");
		num_to_str(-10, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public tsi_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "tsi_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowTradeMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);
	switch (item)
	{
		case -10:
		{
			_ShowTradeMenu(id);
		}
		default:
		{
			if (item == g_iUserSellItem[id] && g_bUserSell[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_ITEM");
				_SelectTradeItem(id);
			}
			else
			{
				g_iTradeItem[id] = item;
				new szItem[32];
				_GetItemName(item, szItem, charsmax(index));
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_ITEM", szItem);
				_ShowTradeMenu(id);
			}
		}
	}
	return _MenuExit(menu);
}

public clcmd_say_accept(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_accept()")
	#endif

	new sender = g_iTradeRequest[id];
	if (sender < 1 || sender > 32)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DONT_HAVE_REQ");
		return;
	}
	if (!g_bLogged[sender] || !is_user_connected(sender))
	{
		_ResetTradeData(id);
		_ResetTradeData(sender);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_SENDER");
		return;
	}
	if (!g_bTradeActive[sender] && id == g_iTradeTarget[sender])
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_IS_CANCELED");
		_ResetTradeData(id);
		_ResetTradeData(sender);
		return;
	}
	if (g_bTradeAccept[id])
	{
		new sItem = g_iTradeItem[sender];
		new tItem = g_iTradeItem[id];
		if (!_UserHasItem(id, tItem) || !_UserHasItem(sender, sItem))
		{
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_FAIL2");
			client_print_color(sender, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_FAIL2");
			_ResetTradeData(id);
			_ResetTradeData(sender);
			return;
		}
		switch (sItem)
		{
			case KEY:
			{
				g_iUserKeys[id]++;
				g_iUserKeys[sender]--;
			}
			case CASE:
			{
				g_iUserCases[id]++;
				g_iUserCases[sender]--;
			}
			default:
			{
				g_iUserSkins[id][sItem]++;
				g_iUserSkins[sender][sItem]--;
			}
		}
		switch (tItem)
		{
			case KEY:
			{
				g_iUserKeys[id]--;
				g_iUserKeys[sender]++;
			}
			case CASE:
			{
				g_iUserCases[id]--;
				g_iUserCases[sender]++;
			}
			default:
			{
				g_iUserSkins[id][tItem]--;
				g_iUserSkins[sender][tItem]++;
			}
		}
		new sItemsz[32];
		new tItemsz[32];
		_GetItemName(tItem, tItemsz, charsmax(tItemsz));
		_GetItemName(sItem, sItemsz, charsmax(sItemsz));
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_SUCCESS", tItemsz, sItemsz);
		client_print_color(sender, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_SUCCESS", sItemsz, tItemsz);
		_ResetTradeData(id);
		_ResetTradeData(sender);
	}
	else
	{
		if (!g_bTradeSecond[id])
		{
			g_iTradeTarget[id] = sender;
			g_iTradeItem[id] = -1;
			g_bTradeSecond[id] = true;
			_ShowTradeMenu(id);
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_SELECT_ITEM");
		}
	}
}

public clcmd_say_deny(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_deny()")
	#endif

	new sender = g_iTradeRequest[id];
	if (1 < sender || sender > 32)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DONT_HAVE_REQ");
	}
	if (!g_bLogged[sender] || !is_user_connected(sender))
	{
		_ResetTradeData(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_SENDER");
	}
	if (!g_bTradeActive[sender] && id == g_iTradeTarget[sender])
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TRADE_IS_CANCELED");
		_ResetTradeData(id);
	}
	_ResetTradeData(id);
	_ResetTradeData(sender);
	client_print_color(sender, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TARGET_REFUSE_TRADE", g_szName[id]);
	client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_YOU_REFUSE_TRADE", g_szName[sender]);
}

public _ShowGamesMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowGamesMenu()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_GAMES_MENU");
	new menu = menu_create(temp, "games_menu_handler");
	new szItem[5];
	szItem[1] = 0;
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_MM_TOMBOLA", g_iCvars[iTombolaCost]);
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, g_bRoulettePlay == true ? "CSGOR_GAME_ROULETTE_CLOSED" : "CSGOR_GAME_ROULETTE");
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GAME_JACKPOT");
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GAME_PROMOCODE");
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GAME_COINFLIP");
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_GAME_BONUS");
	menu_additem(menu, temp, szItem);
	_DisplayMenu(id, menu);
}

public games_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "games_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowMainMenu(id);
		}
		return _MenuExit(menu);
	}
	switch (item)
	{
		case 0:
		{
			_ShowTombolaMenu(id);
		}
		case 1:
		{
			new points = g_iUserPoints[id];
			if (points < g_iRouletteCost)
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NOT_ENOUGH_POINTS", g_iRouletteCost - points);
				_ShowGamesMenu(id);
			}
			else
			{
				if (g_bRoulettePlay)
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ROULETTE_CLOSED", floatround(g_iCvars[flRouletteCooldown]));
					_ShowGamesMenu(id);
				}
				else
				{
					_ShowRouletteMenu(id);
				}
			}
		}
		case 2:
		{
			if (g_bJackpotWork)
			{
				_ShowJackpotMenu(id);
			}
			else
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_JP_CLOSED", g_iCvars[iJackpotTimer]);
			}
		}
		case 3:
		{
			_ShowPromocodeMenu(id);
		}
		case 4:
		{
			_ShowCoinflipMenu(id);
		}
		case 5:
		{
			_ShowBonusMenu(id);
		}
	}
	return _MenuExit(menu);
}

public _ShowTombolaMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowTombolaMenu()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_TOMBOLA_MENU");
	new menu = menu_create(temp, "tombola_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	new Timer[32];
	_FormatTime(Timer, charsmax(Timer), g_iNextTombolaStart);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_TOMB_TIMER", Timer);
	szItem[0] = 0;
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_TOMB_PLAYERS", g_iTombolaPlayers);
	szItem[0] = 0;
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L^n", LANG_SERVER, "CSGOR_TOMB_PRIZE", g_iTombolaPrize);
	szItem[0] = 0;
	menu_additem(menu, temp, szItem);
	if (g_bUserPlay[id])
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_TOMB_ALREADY_PLAY");
		szItem[0] = 0;
		menu_additem(menu, temp, szItem);
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L^n\w%L", LANG_SERVER, "CSGOR_TOMB_PLAY", LANG_SERVER, "CSGOR_TOMB_COST", g_iCvars[iTombolaCost]);
		szItem[0] = 1;
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public tombola_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "tombola_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		return _MenuExit(menu);
	}
	if(!g_bLogged[id])
	{
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	menu_item_getinfo(menu, item, dummy, itemdata, 1);
	index = itemdata[0];
	switch (index)
	{
		case 0:
		{
			_ShowTombolaMenu(id);
		}
		case 1:
		{
			new uPoints = g_iUserPoints[id];
			if (!g_bTombolaWork)
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TOMB_NOT_WORK");
			}
			else
			{
				if (g_iCvars[iTombolaCost] > uPoints)
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NOT_ENOUGH_POINTS", g_iCvars[iTombolaCost] - uPoints);
					_ShowTombolaMenu(id);
					return _MenuExit(menu);
				}
				g_iUserPoints[id] -= g_iCvars[iTombolaCost];
				g_iTombolaPrize = g_iCvars[iTombolaCost] + g_iTombolaPrize;
				g_bUserPlay[id] = true; 
				ArrayPushCell(g_aTombola, id);
				g_iTombolaPlayers += 1;
				_Save(id);
				client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TOMB_ANNOUNCE", g_szName[id]);
				_ShowTombolaMenu(id);
			}
		}
	}
	return _MenuExit(menu);
}

public task_TombolaRun(task)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_TombolaRun()")
	#endif

	if (g_iTombolaPlayers < 1)
	{
		client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TOMB_FAIL_REG");
	}
	else
	{
		if (g_iTombolaPlayers < 2)
		{
			new id = ArrayGetCell(g_aTombola, 0);
			if(is_user_connected(id))
			{
				g_iUserPoints[id] += g_iCvars[iTombolaCost];
				g_bUserPlay[id] = false;
			}
			client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TOMB_FAIL_NUM");
		}
		new id;
		new size = ArraySize(g_aTombola);
		new bool:succes;
		new random;
		new run;
		do {
			random = random_num(0, size - 1);
			id = ArrayGetCell(g_aTombola, random);
			if(is_user_connected(id))
			{
				succes = true;
				g_iUserPoints[id] += g_iTombolaPrize;
				if(g_bLogged[id])
				{
					_Save(id);
				}
				client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TOMB_WINNER", g_szName[id], g_iTombolaPrize);
			}
			else
			{
				ArrayDeleteItem(g_aTombola, random);
				size--;
			}

			if (!succes && size > 0)
			{
			}
		} while (run);
	}
	arrayset(g_bUserPlay, false, sizeof(g_bUserPlay));
	g_iTombolaPlayers = 0;
	g_iTombolaPrize = 0;
	ArrayClear(g_aTombola);
	g_iNextTombolaStart = g_iCvars[iTombolaTimer] + get_systime();
	new Timer[32];
	_FormatTime(Timer, charsmax(Timer), g_iNextTombolaStart);
	client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TOMB_NEXT", Timer);
}

_RoulettePlay()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_RoulettePlay()")
	#endif

	g_iRouletteTime = 60;
	client_print_color(0, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_ROULETTE_PLAY", g_iRouletteTime);
	set_task(1.0, "task_check_roulette", TASK_ROULLETTE_PRE, .flags = "b");
}

public task_check_roulette()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_check_roulette()")
	#endif

	if(g_iRouletteTime != 0)
	{
		g_iRouletteTime--;
	}
	else
	{
		new random = random_num(0, 100);

		if(0 <= random < 49)
		{
			for(new i = 1; i <= MAX_PLAYERS; i++)
			{
				g_iRedPoints[i] *= 2;
				g_iYellowPoints[i] = 0;
				g_iWhitePoints[i] = 0;
				if(is_user_connected(i))
				{
					g_iUserPoints[i] += g_iRedPoints[i] + g_iYellowPoints[i] + g_iWhitePoints[i];
				}
				g_iRedPoints[i] = 0;
			}
			client_print_color(0, print_chat, "^4%s ^1%L.", CSGO_TAG, LANG_SERVER, "CSGOR_ROULETTE_COLOR", random, LANG_SERVER, "CSGOR_ROULETTE_RED");
		}
		else if(53 <= random)
		{
			for(new i = 1; i <= MAX_PLAYERS; i++)
			{
				g_iRedPoints[i] = 0;
				g_iYellowPoints[i] = 0;
				g_iWhitePoints[i] *= 2;
				if(is_user_connected(i))
				{
					g_iUserPoints[i] += g_iRedPoints[i] + g_iYellowPoints[i] + g_iWhitePoints[i];
				}
				g_iWhitePoints[i] = 0;
			}
			client_print_color(0, print_chat, "^4%s ^1%L.", CSGO_TAG, LANG_SERVER, "CSGOR_ROULETTE_COLOR", random, LANG_SERVER, "CSGOR_ROULETTE_WHITE");
		}
		else if(49 <= random <= 52)
		{
			for(new i = 1; i <= MAX_PLAYERS; i++)
			{
				g_iRedPoints[i] = 0;
				g_iYellowPoints[i] *= 14;
				g_iWhitePoints[i] = 0;
				if(is_user_connected(i))
				{
					g_iUserPoints[i] += g_iRedPoints[i] + g_iYellowPoints[i] + g_iWhitePoints[i];
				}
				g_iYellowPoints[i] = 0;
			}
			client_print_color(0, print_chat, "^4%s ^1%L.", CSGO_TAG, LANG_SERVER, "CSGOR_ROULETTE_COLOR", random, LANG_SERVER, "CSGOR_ROULETTE_YELLOW");
		}

		FormatRoulette(random);
		g_iRoulettePlayers = 0;

		set_task(g_iCvars[flRouletteCooldown], "task_Check_Roulette_Post", TASK_ROULLETTE_POST);

		new cooldown = floatround(g_iCvars[flRouletteCooldown]);
		client_print_color(0, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_ROULETTE_CLOSED_FOR", cooldown);

		DestroyTask(TASK_ROULLETTE_PRE);
		g_bRoulettePlay = true;
	}
}

FormatRoulette(iRand)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "FormatRoulette()")
	#endif

	for(new i; i < charsmax(g_iRoulleteNumbers); i++)
	{
		formatex(g_iRoulleteNumbers[i+1], charsmax(g_iRoulleteNumbers[]), "%s", g_iRoulleteNumbers[i]);
	}

	formatex(g_iRoulleteNumbers[0], charsmax(g_iRoulleteNumbers[]), "\w%d", iRand);
}

public task_Check_Roulette_Post()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_Check_Roulette_Post()")
	#endif

	g_bRoulettePlay = false;
	g_iRouletteTime = 60;
	client_print_color(0, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_ROULETTE_OPEN");
}

public _ShowRouletteMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowRouletteMenu()")
	#endif

	new Temp[512];
	new LastNR[128];

	formatex(LastNR, charsmax(LastNR), "^n\w%L", LANG_SERVER, "CSGOR_LAST_NUMBERS", g_iRoulleteNumbers[0], g_iRoulleteNumbers[1], g_iRoulleteNumbers[2], g_iRoulleteNumbers[3], g_iRoulleteNumbers[4], g_iRoulleteNumbers[5], g_iRoulleteNumbers[6] );
	
	if(!g_iRedPoints[id] && !g_iWhitePoints[id] && !g_iYellowPoints[id])
	{
		if(g_iRoulettePlayers >= 2 && g_iRouletteTime >= 5)
			formatex(Temp, charsmax(Temp), "\w%L \y%s", LANG_SERVER, "CSGOR_ROULETTE_MENU_ON_IN", g_iRouletteTime, LastNR);
		else
			formatex(Temp, charsmax(Temp), "\w%L \y%s", LANG_SERVER, "CSGOR_ROULETTE_MENU_ROLLING", LastNR);
	}
	else
	{
		if(g_iRoulettePlayers >= 2 && g_iRouletteTime >= 5)
			formatex(Temp, charsmax(Temp), "\w%L \y%s", LANG_SERVER, "CSGOR_ROULETTE_MENU_COLORS_ON_IN", g_iRouletteTime, LastNR);
		else
			formatex(Temp, charsmax(Temp), "\w%L \y%s", LANG_SERVER, "CSGOR_ROULETTE_MENU_DECISION_COLORS_ROLLING", LastNR);
	}

	new Menu = menu_create(Temp, "roulette_menu_handler");
	
	new iRed, iYellow, iWhite;
	new iPlayers[MAX_PLAYERS], iPlayer, iNum;
	get_players(iPlayers, iNum, "ch");

	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i];

		iRed += g_iRedPoints[iPlayer];
		iYellow += g_iYellowPoints[iPlayer];
		iWhite += g_iWhitePoints[iPlayer];
	}

	formatex(Temp, charsmax(Temp), "\w%L", LANG_SERVER, "CSGOR_ROULETTE_BET_RED", iRed);
	menu_additem(Menu, Temp, "1");

	formatex(Temp, charsmax(Temp), "\w%L", LANG_SERVER, "CSGOR_ROULETTE_BET_YELLOW", iYellow);
	menu_additem(Menu, Temp, "2");

	formatex(Temp, charsmax(Temp), "\w%L", LANG_SERVER, "CSGOR_ROULETTE_BET_WHITE", iWhite);
	menu_additem(Menu, Temp, "3");

	formatex(Temp, charsmax(Temp), "\w%L", LANG_SERVER, "CSGOR_ROULETTE_REFRESH");
	menu_additem(Menu, Temp, "4");
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL);
	_DisplayMenu(id, Menu);
}

public roulette_menu_handler(id, menu, item) 
{ 
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "roulette_menu_handler()")
	#endif

	if(item == MENU_EXIT || !is_user_connected(id))
	{
		return _MenuExit(menu);	
	}
	
	new Data[6], Name[64];
	new Access, CallBack;
	menu_item_getinfo(menu, item, Access, Data, 5, Name, charsmax(Name), CallBack);
	new Key = str_to_num(Data);
	switch(Key)
	{ 
		case 1:
		{
			client_cmd(id, "messagemode BetRed");
		}
		case 2:
		{
			client_cmd(id, "messagemode BetYellow");
		}
		case 3:
		{
			client_cmd(id, "messagemode BetWhite");
		}
		case 4:
		{
			_ShowRouletteMenu(id);
		}
	} 
	return PLUGIN_HANDLED;
}


public _ShowJackpotMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowJackpotMenu()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_JACKPOT_MENU");
	new menu = menu_create(temp, "jackpot_menu_handler", 0);
	new szItem[2];
	szItem[1] = 0;
	if (!_IsGoodItem(g_iUserJackpotItem[id]))
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_SKINS");
		szItem[0] = 1;
		menu_additem(menu, temp, szItem);
	}
	else
	{
		new Item[32];
		_GetItemName(g_iUserJackpotItem[id], Item, charsmax(Item));
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_JP_ITEM", Item);
		szItem[0] = 1;
		menu_additem(menu, temp, szItem);
	}
	if (g_bUserPlayJackpot[id])
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_JP_ALREADY_PLAY");
		szItem[0] = 0;
		menu_additem(menu, temp, szItem);
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_JP_PLAY");
		szItem[0] = 2;
		menu_additem(menu, temp, szItem);
	}
	new Timer[32];
	_FormatTime(Timer, charsmax(Timer), g_iJackpotClose);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_TOMB_TIMER", Timer);
	szItem[0] = 0;
	menu_additem(menu, temp, szItem);
	_DisplayMenu(id, menu);
}

public jackpot_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "jackpot_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGamesMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	menu_item_getinfo(menu, item, dummy, itemdata, 1);
	index = itemdata[0];
	if (!g_bJackpotWork)
	{
		_ShowGamesMenu(id);
		return _MenuExit(menu);
	}
	switch (index)
	{
		case 0:
		{
			_ShowJackpotMenu(id);
		}
		case 1:
		{
			if (g_bUserPlayJackpot[id])
			{
				_ShowJackpotMenu(id);
			}
			else
			{
				_SelectJackpotSkin(id);
			}
		}
		case 2:
		{
			new skin = g_iUserJackpotItem[id];
			if (!_IsGoodItem(skin))
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_SKINS");
				_ShowJackpotMenu(id);
			}
			else
			{
				if (!_UserHasItem(id, skin))
				{
					client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_NOT_ENOUGH_ITEMS");
					g_iUserJackpotItem[id] = -1;
				}
				g_bUserPlayJackpot[id] = true;
				g_iUserSkins[id][skin]--;
				ArrayPushCell(g_aJackpotSkins, skin);
				ArrayPushCell(g_aJackpotUsers, id);
				new szItem[32];
				_GetItemName(skin, szItem, charsmax(szItem));
				client_print_color(0, print_chat, "^4%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_JP_JOIN", g_szName[id], szItem);
			}
		}
	}
	return _MenuExit(menu);
}

public _SelectJackpotSkin(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_SelectJackpotSkin()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_SKINS");
	new menu = menu_create(temp, "jp_skins_menu_handler", 0);
	new szItem[32];
	new szSkin[48];
	new num;
	new type[2];
	new total;
	for (new i; i < g_iSkinsNum; i++)
	{
		num = g_iUserSkins[id][i];
		if (0 < num)
		{
			ArrayGetString(g_aSkinName, i, szSkin, charsmax(szSkin));
			ArrayGetString(g_aSkinType, i, type, 1);
			formatex(temp, charsmax(temp), "\r%s \w| \y%L \r%s", szSkin, LANG_SERVER, "CSGOR_SM_PIECES", num, type[0] == 'c' ? "*" : "");
			num_to_str(i, szItem, charsmax(szItem));
			menu_additem(menu, temp, szItem);
			total++;
		}
	}
	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_SM_NO_SKINS");
		num_to_str(-10, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public jp_skins_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "jp_skins_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowJackpotMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);
	if (item == -10)
	{
		_ShowGamesMenu(id);
		return _MenuExit(menu);
	}
	g_iUserJackpotItem[id] = item;
	_ShowJackpotMenu(id);
	return _MenuExit(menu);
}

public task_Jackpot()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_Jackpot()")
	#endif

	if (!g_bJackpotWork)
	{
		return PLUGIN_HANDLED;
	}
	new id;
	new size = ArraySize(g_aJackpotUsers);
	if (1 > size)
	{
		client_print_color(0, print_chat, "^4%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_JP_NO_ONE");
		_ClearJackpot();
		return PLUGIN_HANDLED;
	}
	if (2 > size)
	{
		client_print_color(0, print_chat, "^4%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_JP_ONLY_ONE");
		new id;
		new k;
		id = ArrayGetCell(g_aJackpotUsers, 0);
		if (0 < id && 32 >= id || !is_user_connected(id))
		{
			k = ArrayGetCell(g_aJackpotSkins, 0);
			g_iUserSkins[id][k]++;
		}
		_ClearJackpot();
		return PLUGIN_HANDLED;
	}
	new bool:succes;
	new random;
	new run;
	do {
		random = random_num(0, size - 1);
		id = ArrayGetCell(g_aJackpotUsers, random);
		if (0 < id && 32 >= id || !is_user_connected(id))
		{
			succes = true;
			new i;
			new k;
			i = ArraySize(g_aJackpotSkins);
			for (new j; j < i; j++)
			{
				k = ArrayGetCell(g_aJackpotSkins, j);
				g_iUserSkins[id][k]++;
			}
			if(g_bLogged[id])
			{
				_Save(id);
			}
			client_print_color(0, print_chat, "^4%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_JP_WINNER", g_szName[id]);
		}
		else
		{
			ArrayDeleteItem(g_aJackpotUsers, random);
			size--;
		}
		if (!(!succes && size > 0))
		{
			_ClearJackpot();
			return PLUGIN_HANDLED;
		}
	} while (run);
	_ClearJackpot();

	return PLUGIN_HANDLED;
}

public _ShowPromocodeMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowPromocodeMenu()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_PROMOCODE_MENU");
	new menu = menu_create(temp, "promocode_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	formatex(temp, charsmax(temp), "\w%L \w%s^n", LANG_SERVER, "CSGOR_PROMOCODE_CODE", g_szUserPromocode[id]);
	menu_additem(menu, temp, szItem);
	formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_PROMOCODE_GET");
	menu_additem(menu, temp, szItem);
	
	_DisplayMenu(id, menu);
}

public promocode_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "promocode_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGamesMenu(id);
		}
		return _MenuExit(menu);
	}
	
	switch(item)
	{
		case 0:
		{
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_PROMOCODE_INSERT");
			client_cmd(id, "messagemode Promocode");
			_ShowPromocodeMenu(id);
			return PLUGIN_HANDLED;
		}
		case 1:
		{
			for(new i; i < g_iPromoNum; i++)
			{
				new szPromocode[32];
				new szPromocodeGift[6];
				ArrayGetString(g_aPromocodes, i, szPromocode, charsmax(szPromocode));
				ArrayGetString(g_aPromocodesGift, i, szPromocodeGift, charsmax(szPromocodeGift));
				if(equal(g_szUserPromocode[id], szPromocode))
				{
					if(g_iPromoCount[id])
					{
						client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_PROMOCODE_ALREADY_USED");
						_ShowPromocodeMenu(id);
						return PLUGIN_HANDLED;
					}
					if(equal(szPromocodeGift, "k"))
					{
						new random = random_num(1, 10);
						g_iUserKeys[id] += random;
						client_print_color(id, print_chat, "^4%s ^1Ai primit ^4%d ^1chei!", CSGO_TAG, random);
						_ShowPromocodeMenu(id);
						g_iPromoCount[id] = 1;
						if(g_iCvars[iSaveType] == NVAULT)
						{
							_SavePromocodes(id);
						}
						break;
					}
					else if(equal(szPromocodeGift, "c"))
					{
						new random = random_num(1, 10);
						g_iUserCases[id] += random;
						client_print_color(id, print_chat, "^4%s ^1Ai primit ^4%d ^1cutii!", CSGO_TAG, random);
						_ShowPromocodeMenu(id);
						g_iPromoCount[id] = 1;
						if(g_iCvars[iSaveType] == NVAULT)
						{
							_SavePromocodes(id);
						}
						break;
					}
					else if(equal(szPromocodeGift, "s"))
					{
						new random = random_num(0, 99);
						new szSkin[48];
						ArrayGetString(g_aSkinName, random, szSkin, charsmax(szSkin));
						g_iUserSkins[id][random] += 1;
						client_print_color(id, print_chat, "^4%s ^1Ai primit skin-ul ^4%s", CSGO_TAG, szSkin);
						_ShowPromocodeMenu(id);
						g_iPromoCount[id] = 1;
						if(g_iCvars[iSaveType] == NVAULT)
						{
							_SavePromocodes(id);
						}
						break;
					}
					return PLUGIN_HANDLED;
				}
				else 
				{
					_ShowPromocodeMenu(id);
				}
			}
		}
	}
	return _MenuExit(menu);
}

public _SavePromocodes(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_SavePromocodes()")
	#endif

	if(g_iCvars[iSaveType] == NVAULT)
	{	
		new szVaultData[64];
		
		formatex( szVaultData, charsmax(szVaultData), "%i", g_iPromoCount[id]);
		nvault_set(g_pVault, g_szName[id], szVaultData);
	}
}

public _LoadPromocodes(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_LoadPromocodes()")
	#endif

	if(g_iCvars[iSaveType] == NVAULT)
	{
		new szVaultData[64];
		
		formatex( szVaultData, charsmax(szVaultData), "%i", g_iPromoCount[id]);
		nvault_get( g_pVault, g_szName[id], szVaultData, charsmax(szVaultData) );
		
		new promo[32];
		parse( szVaultData, promo, charsmax(promo) );
		g_iPromoCount[id] = str_to_num(promo);
	}
}

public _ShowCoinflipMenu(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowCoinflipMenu()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_MENU");
	new menu = menu_create(temp, "coinflip_menu_handler", true);
	new bool:HasTarget;
	new bool:HasItem;
	new target = g_iCoinflipTarget[id];
	if (is_user_connected(target))
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_COINFLIP_TARGET", g_szName[target]);
		menu_additem(menu, temp, "0");
		HasTarget = true;
	}
	else
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_COINFLIP_SELECT_TARGET");
		menu_additem(menu, temp, "0");
	}
	if (!_IsGoodItem(g_iCoinflipItem[id]))
	{
		formatex(temp, charsmax(temp), "\w%L", LANG_SERVER, "CSGOR_SKINS");
		menu_additem(menu, temp, "1");
	}
	else
	{
		new Item[32];
		_GetItemName(g_iCoinflipItem[id], Item, charsmax(Item));
		formatex(temp, charsmax(temp), "\w%L \y%s", LANG_SERVER, "CSGOR_COINFLIP_ITEM", Item);
		menu_additem(menu, temp, "1");
		HasItem = true;
	}
	if (HasTarget && HasItem && !g_bCoinflipActive[id])
	{
		formatex(temp, charsmax(temp), "\r%L^n", LANG_SERVER, "CSGOR_COINFLIP_PLAY");
		menu_additem(menu, temp, "2");
	}
	if (g_bCoinflipActive[id])
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_COINFLIP_CANCEL");
		menu_additem(menu, temp, "3");
	}

	_DisplayMenu(id, menu);
}

public coinflip_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "coinflip_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowGamesMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);
	if (!g_bCoinflipWork)
	{
		_ShowGamesMenu(id);
		return _MenuExit(menu);
	}
	switch (item)
	{
		case 0:
		{
			if (g_bCoinflipActive[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_LOCKED");
				_ShowCoinflipMenu(id);
			}
			else
			{
				_SelectCoinflipTarget(id);
			}
		}
		case 1:
		{
			if (g_bCoinflipActive[id])
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_LOCKED");
			}
			else
			{
				_SelectCoinflipSkin(id);
			}
		}
		case 2:
		{
			new target = g_iCoinflipTarget[id];
			new _item = g_iCoinflipItem[id];
			if(!g_bLogged[target] || !IsPlayer(target))
			{
				client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_TARGET");
				_ResetCoinflipData(id);
				_ShowCoinflipMenu(id);
			}
			else 
			{
				if(!_UserHasItem(id, _item))
				{
					client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_NOT_ENOUGH_ITEMS");
					g_iCoinflipItem[id] = -1;
					_ShowCoinflipMenu(id);
				}
				if(g_bCoinflipSecond[id] && !_UserHasItem(target, g_iCoinflipItem[target]))
				{
					client_print_color(id, print_chat, "^4%s ^1%L", LANG_SERVER, "CSGOR_COINFLIP_FAIL");
					client_print_color(target, print_chat, "^4%s ^1%L", LANG_SERVER, "CSGOR_COINFLIP_FAIL");
					_ResetCoinflipData(id);		
					_ResetCoinflipData(target);									
				}
				g_bCoinflipActive[id] = true;
				g_iCoinflipRequest[target] = id;
				new szItem[32];
				_GetItemName(g_iCoinflipItem[id], szItem, charsmax(szItem));
				if(!g_bCoinflipSecond[id])
				{
					client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_INFO1", g_szName[id], szItem);
					client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_INFO2");
				}
				else
				{
					new zItem[32];
					_GetItemName(g_iCoinflipItem[target], zItem, charsmax(zItem));
					client_print_color(target, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_INFO3", g_szName[id], szItem, szItem );
					client_print_color(target, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_INFO2");
					g_bCoinflipAccept[target] = true;
				}
				client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_SEND", g_szName[target]);
			}
		}
		case 3:
		{
			if(g_bCoinflipSecond[id])
			{
				clcmd_say_deny_coin(id);
			}
			else
			{
				_ResetCoinflipData(id);
			}
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_CANCEL");
			_ShowCoinflipMenu(id);
		}
	}
	return _MenuExit(menu);
}

public _SelectCoinflipSkin(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_SelectCoinflipSkin()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \w%L", CSGO_TAG, LANG_SERVER, "CSGOR_SKINS");
	new menu = menu_create(temp, "cf_skins_menu_handler");
	new szItem[32];
	new szSkin[48];
	new num;
	new type[2];
	new total;
	for (new i; i < g_iSkinsNum; i++)
	{
		num = g_iUserSkins[id][i];
		if (0 < num)
		{
			ArrayGetString(g_aSkinName, i, szSkin, charsmax(szSkin));
			ArrayGetString(g_aSkinType, i, type, 1);
			formatex(temp, charsmax(temp), "\r%s \w| \y%L \r%s", szSkin, LANG_SERVER, "CSGOR_SM_PIECES", num, type[0] == 'c' ? "*" : "");
			num_to_str(i, szItem, charsmax(szItem));
			menu_additem(menu, temp, szItem);
			total++;
		}
	}
	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_SM_NO_SKINS");
		num_to_str(-10, szItem, charsmax(szItem));
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public cf_skins_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "cf_skins_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowCoinflipMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[3];
	new data[6][32];
	new index[32];
	menu_item_getinfo(menu, item, itemdata[0], data[0], charsmax(data), data[1], charsmax(data), itemdata[1]);
	parse(data[0], index, charsmax(index));
	item = str_to_num(index);
	if (item == -10)
	{
		_ShowGamesMenu(id);
		return _MenuExit(menu);
	}
	g_iCoinflipItem[id] = item;
	_ShowCoinflipMenu(id);
	return _MenuExit(menu);
}

public _SelectCoinflipTarget(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_SelectCoinflipTarget()")
	#endif

	new temp[64];
	formatex(temp, charsmax(temp), "\r%s \y%L", CSGO_TAG, LANG_SERVER, "CSGOR_GM_SELECT_TARGET");
	new menu = menu_create(temp, "cft_menu_handler");
	new szItem[2];
	szItem[1] = 0;
	new Pl[32];
	new n;
	new p; 
	get_players(Pl, n, "h");
	new total;
	if (n)
	{
		for (new i; i < n; i++)
		{
			p = Pl[i];
			if (g_bLogged[p])
			{
				if (!(p == id))
				{
					szItem[0] = p;
					menu_additem(menu, g_szName[p], szItem);
					total++;
				}
			}
		}
	}
	if (!total)
	{
		formatex(temp, charsmax(temp), "\r%L", LANG_SERVER, "CSGOR_ST_NO_PLAYERS");
		szItem[0] = -10;
		menu_additem(menu, temp, szItem);
	}
	_DisplayMenu(id, menu);
}

public cft_menu_handler(id, menu, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "cft_menu_handler()")
	#endif

	if (item == MENU_EXIT || !is_user_connected(id))
	{
		if(is_user_connected(id))
		{
			_ShowCoinflipMenu(id);
		}
		return _MenuExit(menu);
	}
	new itemdata[2];
	new dummy;
	new index;
	new name[32];
	menu_item_getinfo(menu, item, dummy, itemdata, charsmax(itemdata), name, charsmax(index), dummy);
	index = itemdata[0];
	switch (index)
	{
		case -10:
		{
			_ShowCoinflipMenu(id);
		}
		default:
		{
			if (g_iCoinflipRequest[index] == 1)
			{
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TARGET_COINFLIP_ACTIVE", name);
			}
			else
			{
				g_iCoinflipTarget[id] = index;
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_YOUR_TARGET", name);
			}
			_ShowCoinflipMenu(id);
		}
	}
	return _MenuExit(menu);
}

public clcmd_say_accept_coin(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_accept_coin()")
	#endif

	new sender = g_iCoinflipRequest[id];
	if(sender < 1 || sender > 32)
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DONT_HAVE_COIN_REQ");
		return;
	}

	if (!g_bLogged[sender] || !is_user_connected(sender))
	{
		_ResetCoinflipData(id);
		_ResetCoinflipData(sender);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_SENDER");
		return;
	}

	if (!g_bCoinflipActive[sender] && id == g_iCoinflipTarget[sender])
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_IS_CANCELED");
		_ResetCoinflipData(id);
		_ResetCoinflipData(sender);
		return;
	}

	if (g_bCoinflipAccept[id])
	{
		new sItem = g_iCoinflipItem[sender];
		new zItem = g_iCoinflipItem[id];
		new sItemsz[32];
		new zItemsz[32];
		_GetItemName(sItem, sItemsz, charsmax(sItemsz));
		_GetItemName(zItem, zItemsz, charsmax(zItemsz));
		if(!_UserHasItem(id, zItem) || !_UserHasItem(sender, sItem))
		{
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_FAIL2");
			client_print_color(sender, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_FAIL2");
			_ResetCoinflipData(id);
			_ResetCoinflipData(sender);
			return;
		}
		new coin = random_num(1, 2);
		switch(coin)
		{
			case 1:
			{
				g_iUserSkins[sender][zItem]++;
				g_iUserSkins[id][zItem]--;
				client_print_color(sender, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_YOU_WON_X_WITH_X", g_szName[id], zItemsz);
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_YOU_LOSE_X_WITH_X", g_szName[sender], zItemsz);
			}
			case 2:
			{ 
				g_iUserSkins[id][sItem]++;
				g_iUserSkins[sender][sItem]--;
				client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_YOU_WON_X_WITH_X", g_szName[sender], sItemsz);
				client_print_color(sender, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_YOU_LOSE_X_WITH_X", g_szName[id], sItemsz);
			}
		}
		_ResetCoinflipData(id);
		_ResetCoinflipData(sender);
	}
	else
	{
		if (!g_bCoinflipSecond[id])
		{
			g_iCoinflipTarget[id] = sender;
			g_iCoinflipItem[id] = -1;
			g_bCoinflipSecond[id] = true;
			_ShowCoinflipMenu(id);
			client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_SELECT_ITEM");
		}
	}
}

public clcmd_say_deny_coin(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_deny_coin()")
	#endif

	new sender = g_iCoinflipRequest[id];
	if ( !IsPlayer(sender) )
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_DONT_HAVE_COIN_REQ");
		return;
	}
	if (!g_bLogged[sender] || !IsPlayer(sender))
	{
		_ResetCoinflipData(id);
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_SENDER");
		return;
	}
	if (!g_bCoinflipActive[sender] && id == g_iCoinflipTarget[sender])
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_COINFLIP_IS_CANCELED");
		_ResetCoinflipData(id);
		return;
	}
	_ResetCoinflipData(id);
	_ResetCoinflipData(sender);
	client_print_color(sender, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_TARGET_REFUSE_COINFLIP", g_szName[id]);
	client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_YOU_REFUSE_COINFLIP", g_szName[sender]);
}

public ev_DeathMsg()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "ev_DeathMsg()")
	#endif

	new killer = read_data(1);
	new victim = read_data(2);
	new head = read_data(3);
	new szWeapon[24];
	read_data(4, szWeapon, charsmax(szWeapon));

	if(!IsPlayer(victim))
	{
		_Send_DeathMsg(killer, victim, head, szWeapon);
		return PLUGIN_CONTINUE;
	}

	ClearPlayerBit(g_bitIsAlive, victim)

	if(!IsPlayer(killer))
	{
		_Send_DeathMsg(killer, victim, head, szWeapon);
		return PLUGIN_CONTINUE;
	}

	new assist = g_iMostDamage[victim];

	if(is_user_connected(assist) && assist != killer && killer != victim)
	{
		_GiveBonus(assist, 0);
		ExecuteForward(g_iForwards[ user_assist ], g_iForwardResult, assist, killer, victim, head);
		
		new kName[32];
		new szName1[32];
		new szName2[32];
		new iName1Len = strlen(g_szName[killer]);
		new iName2Len = strlen(g_szName[assist]);
		
		if (iName1Len < 14)
		{
			formatex(szName1, iName1Len, "%s", g_szName[killer]);
			formatex(szName2, 28 - iName1Len, "%s", g_szName[assist]);
		}
		else
		{
			if (iName2Len < 14)
			{
				formatex(szName1, 28 - iName2Len, "%s", g_szName[killer]);
				formatex(szName2, iName2Len, "%s", g_szName[assist]);
			}
			formatex(szName1, 13, "%s", g_szName[killer]);
			formatex(szName2, 13, "%s", g_szName[assist]);
		}
		formatex(kName, charsmax(kName), "%s + %s", szName1, szName2);
		g_eEnumBooleans[killer][IsChangeNotAllowed] = true;
		set_msg_block(g_Msg_SayText, BLOCK_ONCE);
		set_user_info(killer, "name", kName);
		new szWeaponLong[24];
		
		if (equali(szWeapon, "grenade"))
		{
			formatex(szWeaponLong, charsmax(szWeaponLong), "%s", "weapon_hegrenade");
		}
		else
		{
			formatex(szWeaponLong, charsmax(szWeaponLong), "weapon_%s", szWeapon);
		}

		new args[4];
		args[0] = killer;
		args[1] = victim;
		args[2] = head;
		args[3] = get_weaponid(szWeaponLong);
		set_task(0.1, "task_Send_DeathMsg", TASK_SENDDEATH, args, sizeof(args));
	}
	else
	{
		_Send_DeathMsg(killer, victim, head, szWeapon);
	}

	g_iDigit[killer]++;
	_SetKillsIcon(killer, 0);
	g_iRoundKills[killer]++;
	
	if (!g_bLogged[killer])
	{
		client_print_color(killer, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_REGISTER");
		return PLUGIN_HANDLED;
	}
	
	if (killer == victim)
		return PLUGIN_CONTINUE;
	
	g_iUserKills[killer]++;
	new iWeaponID = get_user_weapon(killer);
	if(g_iStattrackWeap[killer][bStattrack][iWeaponID])
	{
		g_iStattrackWeap[killer][iKillCount][g_iStattrackWeap[killer][iSelected][iWeaponID]]++
	}
	new bool:levelup;
	if (g_iRanksNum - 1 > g_iUserRank[killer])
	{
		if (ArrayGetCell(g_aRankKills, g_iUserRank[killer] +1) <= g_iUserKills[killer])
		{
			g_iUserRank[killer]++;
			levelup = true;

			new szRank[MAX_RANK_NAME];
			ArrayGetString(g_aRankName, g_iUserRank[killer], szRank, charsmax(szRank));

			client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_LEVELUP_ALL", g_szName[killer], szRank);

			ExecuteForward(g_iForwards[ user_level_up ], g_iForwardResult, killer, szRank, g_iUserRank[killer]);
		}
	}
	new rpoints;
	new rchance;
	if (head)
	{
		rpoints = random_num(g_iCvars[iHMinPoints], g_iCvars[iHMaxPoints]);
		rchance = random_num(g_iCvars[iHMinChance], g_iCvars[iHMaxChance]);
	}
	else
	{
		rpoints = random_num(g_iCvars[iKMinPoints], g_iCvars[iKMaxPoints]);
		rchance = random_num(g_iCvars[iKMinChance], g_iCvars[iKMaxChance]);
	}
	g_iUserPoints[killer] += rpoints;
	set_hudmessage(255, 255, 255, -1.0, 0.2, 0, 6.0, 2.0);
	show_hudmessage(killer, "%L", LANG_SERVER, "CSGOR_REWARD_POINTS", rpoints);
	if (rchance > g_iCvars[iDropChance])
	{
		new r;
		if (0 < g_iCvars[iDropType])
		{
			r = 1;
		}
		else
		{
			r = random_num(1, 2);
		}
		switch (r)
		{
			case 1:
			{
				g_iUserCases[killer]++;
				if (0 < g_iCvars[iDropType])
				{
					client_print_color(killer, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_REWARD_CASE2");
				}
				else
				{
					client_print_color(killer, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_REWARD_CASE");
				}
			}
			case 2:
			{
				g_iUserKeys[killer]++;
				client_print_color(killer, print_chat, "^4%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_REWARD_KEY");
			}
		}
		ExecuteForward(g_iForwards[user_drop], g_iForwardResult, killer);
	}
	if (levelup)
	{
		new szBonus[16];
		get_cvar_string("csgor_rangup_bonus", szBonus, charsmax(szBonus));
		new keys;
		new cases;
		new points;
		for (new i; szBonus[i] != '|'; i++)
		{
			switch (szBonus[i])
			{
				case 'c':
				{
					cases++;
				}
				case 'k':
				{
					keys++;
				}
			}
		}
		new temp[8];
		strtok(szBonus, temp, charsmax(temp), szBonus, charsmax(szBonus), '|');
		if (szBonus[0])
		{
			points = str_to_num(szBonus);
		}
		if (0 < keys)
		{
			g_iUserKeys[killer] += keys;
		}
		if (0 < cases)
		{
			g_iUserCases[killer] += cases;
		}
		if (0 < points)
		{
			g_iUserPoints[killer] += points;
		}
		client_print_color(killer, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_RANKUP_BONUS", keys, cases, points);
	}
	return PLUGIN_HANDLED;
}

public ev_Damage( victim )
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "ev_Damage()")
	#endif

	static attacker, damage;
	if(victim && victim <= MAX_PLAYERS && is_user_connected(victim))
	{
		attacker = get_user_attacker(victim);
		
		if(attacker && attacker <= MAX_PLAYERS && is_user_connected(attacker))
		{
			damage = read_data(2);

			g_iDealDamage[attacker] += damage;
			g_iDamage[victim][attacker] += damage;
			
			new topDamager = g_iMostDamage[victim];
			if (g_iDamage[victim][attacker] > g_iDamage[victim][topDamager])
			{
				g_iMostDamage[victim] = attacker;
			}
		}
	}
}

public task_Send_DeathMsg(arg[])
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "task_Send_DeathMsg()")
	#endif

	new szWeapon[24];
	new weapon = arg[3];
	get_weaponname(weapon, szWeapon, charsmax(szWeapon));
	
	if (weapon == CSW_HEGRENADE)
	{
		replace_string(szWeapon, charsmax(szWeapon), "weapon_he", "");
	}
	else
	{
		replace_string(szWeapon, charsmax(szWeapon), "weapon_", "");
	}

	_Send_DeathMsg(arg[0], arg[1], arg[2], szWeapon);
	set_msg_block(g_Msg_SayText, BLOCK_ONCE);
	set_user_info(arg[0], "name", g_szName[arg[0]]);

	set_task(0.1, "task_Reset_Name", arg[0] + TASK_RESET_NAME);
}

public concmd_givepoints(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_givepoints()")
	#endif

	if (!cmd_access(id, level, cid, 3))
	{
		return PLUGIN_HANDLED;
	}
	new arg1[32];
	new arg2[16];
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));
	new target;
	if (arg1[0] == '@')
	{
		_GiveToAll(id, arg1, arg2, 0);
		return PLUGIN_HANDLED;
	}
	target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
	if (!target)
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1);
		return PLUGIN_HANDLED;
	}
	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1);
		return PLUGIN_HANDLED;
	}

	new amount = str_to_num(arg2);
	if (0 > amount)
	{
		g_iUserPoints[target] += amount;
		if (0 > g_iUserPoints[target])
		{
			g_iUserPoints[target] = 0;
		}
		console_print(id, "%s %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_SUBSTRACT", arg1, amount, LANG_SERVER, "CSGOR_POINTS");
		client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_POINTS");
	}
	else
	{
		if (0 < amount)
		{
			g_iUserPoints[target] += amount;
			console_print(id, "%s You gave %s %d points", CSGO_TAG, arg1, amount);
			client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_POINTS");
		}
	}
	_Save(target);

	return PLUGIN_HANDLED;
}

public concmd_givecases(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_givecases()")
	#endif

	if (!cmd_access(id, level, cid, 3))
	{
		return PLUGIN_HANDLED;
	}
	new arg1[32];
	new arg2[16];
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));
	new target;
	if (arg1[0] == '@')
	{
		_GiveToAll(id, arg1, arg2, 1);
		return PLUGIN_HANDLED;
	}
	target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
	if (!target)
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1);
		return PLUGIN_HANDLED;
	}
	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1);
		return PLUGIN_HANDLED;
	}
	new amount = str_to_num(arg2);
	if (0 > amount)
	{
		g_iUserCases[target] -= amount;
		if (0 > g_iUserCases[target])
		{
			g_iUserCases[target] = 0;
		}
		console_print(id, "%s %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_SUBSTRACT", arg1, amount, LANG_SERVER, "CSGOR_CASES");
		client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_CASES");
	}
	else
	{
		if (0 < amount)
		{
			g_iUserCases[target] += amount;
			console_print(id, "%s %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADD", arg1, amount, LANG_SERVER, "CSGOR_CASES");
			client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_CASES");
		}
	}
	_Save(target);

	return PLUGIN_HANDLED;
}

public concmd_givekeys(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_givekeys()")
	#endif

	if (!cmd_access(id, level, cid, 3, false))
	{
		return PLUGIN_HANDLED;
	}
	new arg1[32];
	new arg2[16];
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));
	new target;
	if (arg1[0] == '@')
	{
		_GiveToAll(id, arg1, arg2, 2);
		return PLUGIN_HANDLED;
	}
	target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
	if (!target)
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1);
		return PLUGIN_HANDLED;
	}
	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1);
		return PLUGIN_HANDLED;
	}
	new amount = str_to_num(arg2);
	if (0 > amount)
	{
		g_iUserKeys[target] -= amount;
		if (0 > g_iUserKeys[target])
		{
			g_iUserKeys[target] = 0;
		}
		console_print(id, "%s %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_SUBSTRACT", arg1, amount, LANG_SERVER, "CSGOR_KEYS");
		client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_KEYS");
	}
	else
	{
		if (0 < amount)
		{
			g_iUserKeys[target] += amount;
			console_print(id, "%s %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADD", arg1, amount, LANG_SERVER, "CSGOR_KEYS");
			client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_KEYS");
		}
	}
	_Save(target);

	return PLUGIN_HANDLED;
}

public concmd_givedusts(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_givedusts()")
	#endif

	if (!cmd_access(id, level, cid, 3, false))
	{
		return PLUGIN_HANDLED;
	}
	new arg1[32];
	new arg2[16];
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));
	new target;
	if (arg1[0] == '@')
	{
		_GiveToAll(id, arg1, arg2, 3);
		return PLUGIN_HANDLED;
	}
	target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
	if (!target)
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1);
		return PLUGIN_HANDLED;
	}
	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1);
		return PLUGIN_HANDLED;  
	}
	new amount = str_to_num(arg2);
	if (0 > amount)
	{
		g_iUserDusts[target] -= amount;
		if (0 > g_iUserDusts[target])
		{
			g_iUserDusts[target] = 0;
		}
		console_print(id, "%s %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_SUBSTRACT", arg1, amount, LANG_SERVER, "CSGOR_DUSTS");
		client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_DUSTS");
	}
	else
	{
		if (0 < amount)
		{
			g_iUserDusts[target] += amount;
			console_print(id, "%s %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADD", arg1, amount, LANG_SERVER, "CSGOR_DUSTS");
			client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_DUSTS");
		}
	}
	_Save(target);

	return PLUGIN_HANDLED;
}

public concmd_setrank(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_setrank()")
	#endif

	if (!cmd_access(id, level, cid, 3, false))
	{
		return PLUGIN_HANDLED;
	}
	new arg1[32];
	new arg2[8];
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));
	new target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
	if (!target)
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1);
		return PLUGIN_HANDLED;
	}
	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1);
		return PLUGIN_HANDLED;
	}
	new rank = str_to_num(arg2);
	if (rank < 0 || rank >= g_iRanksNum)
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_RANKID", g_iRanksNum - 1);
		return PLUGIN_HANDLED;
	}
	g_iUserRank[target] = rank;
	if (rank)
	{
		g_iUserKills[target] = ArrayGetCell(g_aRankKills, rank - 1);
	}
	else
	{
		g_iUserKills[target] = 0;
	}

	_Save(target);

	new szRank[MAX_RANK_NAME];
	ArrayGetString(g_aRankName, g_iUserRank[target], szRank, charsmax(szRank));

	console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_SET_RANK", arg1, szRank);

	client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_SET_RANK", g_szName[id], szRank);

	return PLUGIN_HANDLED;
}

public concmd_giveskins(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_giveskins()")
	#endif

	if (!cmd_access(id, level, cid, 4, false))
	{
		return PLUGIN_HANDLED;
	}
	new arg1[32];
	new arg2[8];
	new arg3[16];
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));
	read_argv(3, arg3, charsmax(arg3));
	new target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
	if (!target)
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1);
		return PLUGIN_HANDLED;
	}
	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1);
		return PLUGIN_HANDLED;
	}
	new skin = str_to_num(arg2);
	if (skin < 0 || skin >= g_iSkinsNum)
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_INVALID_SKINID", g_iSkinsNum - 1);
		return PLUGIN_HANDLED;
	}

	new amount = str_to_num(arg3);
	new szSkin[48];
	ArrayGetString(g_aSkinName, skin, szSkin, charsmax(szSkin));
	if (0 > amount)
	{
		g_iUserSkins[target][skin] -= amount;
		if (0 > g_iUserSkins[target][skin])
		{
			g_iUserSkins[target][skin] -= amount;
		}
		console_print(id, "%s %L %s", CSGO_TAG, LANG_SERVER, "CSGOR_SUBSTRACT", arg1, amount, szSkin);
		client_print_color(target, print_chat, "^4%s^1 %L ^3%s", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, szSkin);
	}
	else
	{
		if (0 < amount)
		{
			g_iUserSkins[target][skin] += amount;
			console_print(id, "%s %L x %s", CSGO_TAG, LANG_SERVER, "CSGOR_ADD", arg1, amount, szSkin);
			client_print_color(target, print_chat, "^4%s^1 %L ^3%s", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, szSkin);
		}
	}
	_Save(target);

	return PLUGIN_HANDLED;
}

public concmd_give_all_skins(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_give_all_skins()")
	#endif

	if (!cmd_access(id, level, cid, 2, false))
	{
		return PLUGIN_HANDLED;
	}
	
	new arg1[32];
	read_argv(1, arg1, charsmax(arg1));
	new target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
	if(!target) 
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1);
		return PLUGIN_HANDLED;
	}
	if(!g_bLogged[target])
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_LOGGED", arg1);
		return PLUGIN_HANDLED;
	}

	for (new i; i < g_iSkinsNum; i++)
	{
		g_iUserSkins[target][i]++;
		g_iStattrackWeap[target][iWeap][i]++;
	}

	console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_GAVE_ALL_SKINS_TO", g_szName[target]);
	client_print_color(target, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_ALL_SKINS", g_szName[id]);
	_Save(target);

	return PLUGIN_HANDLED;
}

public native_get_user_points(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_user_points()")
	#endif

	if (iParamNum != 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	return g_iUserPoints[id];
}

public native_set_user_points(iPluginID, iParamNum)
{
	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	new amount = get_param(2);
	if (0 > amount)
	{
		new szName[32];
		get_user_name(id, szName, charsmax(szName));
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d) Player (%s)", CSGO_TAG, amount, szName);
		return -1;
	}
	if(!g_bLogged[id])
	{
		return -1;
	}
	g_iUserPoints[id] = amount;
	_Save(id);

	return PLUGIN_HANDLED;
}

public native_get_user_cases(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_user_cases()")
	#endif

	if (iParamNum != 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	return g_iUserCases[id];
}

public native_set_user_cases(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_set_user_cases()")
	#endif

	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	new amount = get_param(2);
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", CSGO_TAG, amount);
		return -1;
	}
	if(!g_bLogged[id])
	{
		return -1;
	}
	g_iUserCases[id] = amount;
	_Save(id);

	return PLUGIN_HANDLED;
}

public native_get_user_keys(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_user_keys()")
	#endif

	if (iParamNum != 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	return g_iUserKeys[id];
}

public native_set_user_keys(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_set_user_keys()")
	#endif

	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	new amount = get_param(2);
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", CSGO_TAG, amount);
		return -1;
	}
	if(!g_bLogged[id])
	{
		return -1;
	}
	g_iUserKeys[id] = amount;
	_Save(id);
	return PLUGIN_HANDLED;
}

public native_get_user_dusts(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_user_dusts()")
	#endif

	if (iParamNum != 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	return g_iUserDusts[id];
}

public native_set_user_dusts(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_set_user_dusts()")
	#endif

	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	new amount = get_param(2);
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", CSGO_TAG, amount);
		return -1;
	}
	if(!g_bLogged[id])
	{
		return -1;
	}
	g_iUserDusts[id] = amount;
	_Save(id);

	return PLUGIN_HANDLED;
}

public native_get_user_rank(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_user_rank()")
	#endif

	if (iParamNum != 3)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Output, Len)", CSGO_TAG);
		return -1;
	}
	
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	new szRank[MAX_RANK_NAME]
	new rank = -2

	if(g_bLogged[id])
	{
		rank = g_iUserRank[id];
		ArrayGetString(g_aRankName, rank, szRank, charsmax(szRank));
	}
	else
	{
		formatex(szRank, charsmax(szRank), "%L", LANG_SERVER, "CSGOR_NOT_LOGGED_CHAT")
	}

	set_string(2, szRank, get_param(3));

	return rank;
}

public native_set_user_rank(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_set_user_rank()")
	#endif

	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, RankID)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	new rank = get_param(2);
	if (rank < 0 || rank >= g_iRanksNum)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid RankID (%d)", CSGO_TAG, rank);
		return -1;
	}
	if(!g_bLogged[id])
	{
		return -1;
	}
	g_iUserRank[id] = rank;
	g_iUserKills[id] = ArrayGetCell(g_aRankKills, rank - 1);
	_Save(id);

	return PLUGIN_HANDLED;
}

public native_get_user_skins(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_user_skins()")
	#endif

	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, SkinID)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	new skin = get_param(2);
	if (skin < 0 || skin >= g_iSkinsNum)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d)", CSGO_TAG, skin);
		return -1;
	}
	new amount = g_iUserSkins[id][skin];
	return amount;
}

public native_set_user_skins(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_set_user_skins()")
	#endif

	if (iParamNum != 3)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, SkinID, Amount)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	new skin = get_param(2);
	if (skin < 0 || skin >= g_iSkinsNum)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d)", CSGO_TAG, skin);
		return -1;
	}
	new amount = get_param(3);
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", CSGO_TAG, amount);
		return -1;
	}
	if(!g_bLogged[id])
	{
		return -1;
	}
	g_iUserSkins[id][skin] = amount;
	_Save(id);

	return PLUGIN_HANDLED;
}

public native_get_skins_num(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_skins_num()")
	#endif

	return g_iSkinsNum;
}

public native_get_skin_name(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_skin_name()")
	#endif

	if (iParamNum != 3)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (SkinID, Output[], Len)", CSGO_TAG);
		return -1;
	}

	new skin = get_param(1);
	if (0 > skin > g_iSkinsNum - 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d).", CSGO_TAG, skin);
		return -1;
	}
	new szSkin[48];
	ArrayGetString(g_aSkinName, skin, szSkin, charsmax(szSkin));

	set_string(2, szSkin, get_param(3));

	return PLUGIN_HANDLED;
}

public native_is_user_logged(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_is_user_logged()")
	#endif

	if (iParamNum != 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID)", CSGO_TAG, CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}
	return g_bLogged[id];
}

public native_set_user_all_skins(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_set_user_all_skins()")
	#endif

	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}
	if(!g_bLogged[id])
	{
		return -1;
	}
	for (new i; i < g_iSkinsNum; i++)
	{
		g_iUserSkins[id][i]++;
	}
	_Save(id);

	return PLUGIN_HANDLED;
}

public native_is_half_round(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_is_half_round()")
	#endif

	return IsHalf();
}

public native_is_last_round(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_is_last_round()")
	#endif

	return IsLastRound();
}

public native_is_good_item(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_is_good_item()")
	#endif

	return _IsGoodItem(get_param(1));
}

public native_is_item_skin(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_is_item_skin()")
	#endif

	return _IsItemSkin(get_param(1));
}

public native_is_user_registered(iPluginID, iParam)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_is_user_registered()")
	#endif

	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	return IsRegistered(id);
}

public native_is_warmup(iPluginID, iParam)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_is_warmup()")
	#endif

	return g_bWarmUp;
}

public native_get_skin_index(iPluginID, iParam)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_skin_index()")
	#endif

	new szSkinName[48], szSkin[48];
	get_string(1, szSkinName, charsmax(szSkinName));

	new iReturn = -1, iIndex = -1;

	for(new i; i < g_iSkinsNum; i++)
	{
		ArrayGetString(g_aSkinName, i, szSkin, charsmax(szSkin));
		iIndex = containi(szSkin, szSkinName);

		if(iIndex != -1)
		{
			iReturn = i;
			break;
		}
	}

	if(iReturn == -1)
	{
		log_error(AMX_ERR_NATIVE, "[%s] Skin id can't be found. Skin pattern: ^"%s^"", CSGO_TAG, szSkinName);
	}
	return iReturn;
}

public native_ranks_num(iPluginID, iParam)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_ranks_num()")
	#endif

	return g_iRanksNum;
}

public native_is_skin_stattrack(iPluginID, iParam)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_is_skin_stattrack()")
	#endif

	new id = get_param(1);

	if(!IsPlayer(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return false;
	}

	new iWeaponID = get_user_weapon(id);

	return g_iStattrackWeap[id][bStattrack][iWeaponID];
}

public native_get_user_statt_skins(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_user_statt_skins()")
	#endif

	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, SkinID)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	new skin = get_param(2);
	if (skin < 0 || skin >= g_iSkinsNum)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d)", CSGO_TAG, skin);
		return -1;
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", CSGO_TAG, id);
		return -1;
	}
	return g_iStattrackWeap[id][iWeap][skin];
}

public native_set_user_statt_skins(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_set_user_statt_skins()")
	#endif

	if (iParamNum != 3)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, SkinID, Amount)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	new skin = get_param(2);
	if (skin < 0 || skin >= g_iSkinsNum)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid SkinID (%d)", CSGO_TAG, skin);
		return -1;
	}

	new amount = get_param(3);
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", CSGO_TAG, amount);
		return -1;
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", CSGO_TAG, id);
		return -1;
	}

	g_iStattrackWeap[id][iWeap][skin] += amount;
	_Save(id);

	return PLUGIN_HANDLED;
}

public native_get_user_stattrack_kills(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_user_stattrack_kills()")
	#endif

	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", CSGO_TAG, id);
		return -1;
	}

	new iWeaponID = get_user_weapon(id);

	if(!g_iStattrackWeap[id][bStattrack][iWeaponID])
	{
		log_error(AMX_ERR_NATIVE, "%s Player's (%d) skin is not StatTrack", CSGO_TAG, id);
		return -1;
	}

	return g_iStattrackWeap[id][iKillCount][g_iStattrackWeap[id][iSelected][iWeaponID]];
}

public native_set_random_stattrack(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_set_random_stattrack()")
	#endif

	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)", CSGO_TAG);
		return -1;
	}
	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", CSGO_TAG, id);
		return -1;
	}

	new amount = get_param(3);
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", CSGO_TAG, amount);
		return -1;
	}

	new iRand = random_num(0, g_iSkinsNum - 1)

	g_iStattrackWeap[id][iWeap][iRand] += amount;
	_Save(id);
	return PLUGIN_HANDLED;
}

public native_set_user_stattrack_kills(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_set_user_stattrack_kills()")
	#endif

	if (iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, Amount)", CSGO_TAG);
		return -1;
	}

	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", CSGO_TAG, id);
		return -1;
	}

	new amount = get_param(3);
	if (0 > amount)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid amount value (%d)", CSGO_TAG, amount);
		return -1;
	}

	new iWeaponID = get_user_weapon(id);

	if(!g_iStattrackWeap[id][bStattrack][iWeaponID])
	{
		log_error(AMX_ERR_NATIVE, "%s Player's (%d) skin is not StatTrack", CSGO_TAG, id);
		return -1;
	}

	g_iStattrackWeap[id][iKillCount][g_iStattrackWeap[id][iSelected][iWeaponID]] = amount;
	return PLUGIN_HANDLED;
}

public native_get_user_stattrack(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_get_user_stattrack()")
	#endif

	if (iParamNum != 4)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, WeaponID, SkinName, iLen)", CSGO_TAG);
		return -1;
	}

	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", CSGO_TAG, id);
		return -1;
	}

	new iWeaponID = get_param(2);

	if( iWeaponID <= CSW_NONE || iWeaponID > CSW_P90 )
	{
		log_error(AMX_ERR_NATIVE, "%s Weapon ID (%d) is not a valid one!", CSGO_TAG, iWeaponID);
		return -1;
	}

	if(!g_iStattrackWeap[id][bStattrack][iWeaponID])
	{
		set_string(3, "NONE", get_param(4));
		return -1;
	}

	new szSkin[48];
	ArrayGetString(g_aSkinName, g_iStattrackWeap[id][iSelected][iWeaponID], szSkin, charsmax(szSkin));
	format(szSkin, charsmax(szSkin), "StatTrack %s", szSkin);

	set_string(3, szSkin, get_param(4));
	return PLUGIN_HANDLED;
}

public native_csgo_get_user_body(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "csgo_get_user_body()")
	#endif

	return g_iUserViewBody[get_param(1)][get_param(2)]
}

public native_csgo_get_config_location(iPluginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "csgo_get_config_location()")
	#endif

	set_string(1, g_szConfigFile, charsmax(g_szConfigFile));
}

public native_csgo_get_user_skin(iPLuginID, iParamNum)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "native_csgo_get_user_skin()")
	#endif

	if (iParamNum != 4)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (PlayerID, iWeaponID, SkinName, iLen)", CSGO_TAG);
		return -1;
	}

	new id = get_param(1);
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not connected (%d)", CSGO_TAG, id);
		return -1;
	}

	if(!g_bLogged[id])
	{
		log_error(AMX_ERR_NATIVE, "%s Player is not logged into account (%d)", CSGO_TAG, id);
		return -1;
	}

	new iWeaponID = get_param(2);

	if( iWeaponID <= CSW_NONE || iWeaponID > CSW_P90 )
	{
		log_error(AMX_ERR_NATIVE, "%s Weapon ID (%d) is not a valid one!", CSGO_TAG, iWeaponID);
		return -1;
	}

	if(g_iUserSelectedSkin[id][iWeaponID] < 0)
	{
		set_string(3, "NONE", get_param(4));
		return -1;
	}

	new szSkin[MAX_SKIN_NAME];
	ArrayGetString(g_aSkinName, g_iUserSelectedSkin[id][iWeaponID], szSkin, charsmax(szSkin));

	set_string(3, szSkin, get_param(4));
	return PLUGIN_HANDLED;
}

public native_csgo_get_database_data(iPluginID, iParamNum)
{
	if (iParamNum != 8)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (szHostname[], iHostLen, szUsername[], iUserLen, szPassword[], iPassLen, szDatabase[], iDbLen)", CSGO_TAG);
		return -1;
	}

	set_string(1, g_iCvars[szSqlHost], get_param(2))
	set_string(3, g_iCvars[szSqlUsername], get_param(4))
	set_string(5, g_iCvars[szSqlPassword], get_param(6))
	set_string(7, g_iCvars[szSqlDatabase], get_param(8))

	return 1;
}

public native_get_rank_name(iPluginID, iParamNum)
{
	if(iParamNum != 2)
	{
		log_error(AMX_ERR_NATIVE, "%s Invalid param num ! Valid: (iRankNum, szBuffer[])", CSGO_TAG)
		return -1
	}

	new iRank = get_param(1)
	new szRank[MAX_RANK_NAME]

	ArrayGetString(g_aRankName, iRank, szRank, charsmax(szRank))

	set_string(2, szRank, charsmax(szRank))

	return 1
}

public concmd_finddata(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_finddata()")
	#endif

	if (!cmd_access(id, level, cid, 2, false))
	{
		return PLUGIN_HANDLED;
	}

	new arg1[32];
	read_argv(1, arg1, charsmax(arg1));

	new bool:bFound;

	new szRank[MAX_RANK_NAME];
	new userData[6];
	new password[32];

	switch(g_iCvars[iSaveType])
	{
		case NVAULT:
		{
			if (g_Vault == INVALID_HANDLE)
			{
				console_print(id, "%s Reading from vault has failed !", CSGO_TAG);
				return PLUGIN_HANDLED;
			}

			new Data[64];
			new Timestamp;
			if (nvault_lookup(g_Vault, arg1, Data, charsmax(Data), Timestamp))
			{
				new pData[6][16]
				new szBuffer[48];
				strtok(Data, password, charsmax(password), Data, charsmax(Data), '=');
				strtok(Data, szBuffer, charsmax(szBuffer), Data, charsmax(Data), '*');
				replace_all(szBuffer, charsmax(szBuffer), ",;", "")

				for (new i; i < sizeof pData; i++)
				{
					strtok(szBuffer, pData[i], charsmax(pData[]), szBuffer, charsmax(szBuffer), ',');
					userData[i] = str_to_num(pData[i])
				}

				bFound = true;
			}
		}
		case MYSQL:
		{
			new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_data` WHERE `Name` = ^"%s^";", arg1);
			
			if(!SQL_Execute(iQuery))
			{
				SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError));
				log_to_file("csgo_remake_errors.log", "test %s", g_szSqlError);
				SQL_FreeHandle(iQuery);
			}

			if(SQL_NumResults(iQuery) > 0)
			{
				new szQuery[512];
				formatex(szQuery, charsmax(szQuery), "SELECT \
   					`Password`,\
   					`Points`,\
   					`Scraps`,\
   					`Keys`,\
   					`Cases`,\
   					`Kills`,\
   					`Rank`\
   					FROM `csgor_data` WHERE `Name` = ^"%s^";", g_szName[id]);

	   			iQuery = SQL_PrepareQuery(g_iSqlConnection, szQuery);

	   			if(!SQL_Execute(iQuery))
				{
					SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError));
					log_to_file("csgo_remake_errors.log", "test2 %s", g_szSqlError);
				}

				if(SQL_NumResults(iQuery) > 0)
				{
					SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Password"), password, charsmax(password));
					userData[0] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Points"));
					userData[1] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Scraps"));
					userData[2] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Keys"));
					userData[3] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Cases"));
					userData[4] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Kills"));
					userData[5] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Rank"));
				}

				bFound = true;
			}
		}
	}

	if(bFound)
	{
		ArrayGetString(g_aRankName, userData[5], szRank, charsmax(szRank));
		console_print(id, "%s Name: %s Password: %s", CSGO_TAG, arg1, password);
		console_print(id, "%s Points: %i | Rank: %s", CSGO_TAG, userData[0], szRank);
		console_print(id, "%s Keys: %i | Cases: %i", CSGO_TAG, userData[2], userData[3]);
		console_print(id, "%s Dusts: %i | Kills: %i", CSGO_TAG, userData[1], userData[4]);
	}
	else
	{
		console_print(id, "%s The account was not found: %s", CSGO_TAG, arg1);
	}

	return PLUGIN_HANDLED;
}

public concmd_resetdata(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_resetdata()")
	#endif

	if (!cmd_access(id, level, cid, 3, false) || !is_user_connected(id))
	{
		return PLUGIN_HANDLED;
	}
	new arg1[32];
	new arg2[4];
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));
	new type = str_to_num(arg2);
	if (g_Vault == INVALID_HANDLE)
	{
		console_print(id, "%s Reading from vault has failed !", CSGO_TAG);
		return PLUGIN_HANDLED;
	}

	new g_szData[MAX_SKINS * 3 + 94];
	new g_iWeapszBuffer[MAX_SKINS * 2];
	new Timestamp;
	if (nvault_lookup(g_Vault, arg1, g_szData, charsmax(g_szData), Timestamp))
	{
		new index = get_user_index(arg1)
		if(index)
		{
			g_bLogged[index] = false;
		}

		if (0 < type)
		{
			nvault_remove(g_Vault, arg1);
			nvault_remove(g_nVault, arg1);
			nvault_remove(g_sVault, arg1);
			nvault_remove(g_pVault, arg1);
			ResetData(id, true);
			console_print(id, "%s The account has been removed: %s", CSGO_TAG, arg1);
			return PLUGIN_HANDLED;
		}
		new infoBuffer[MAX_SKIN_NAME];
		new skinBuffer[MAX_SKINS];
		new password[16];
		strtok(g_szData, password, charsmax(password), g_szData, charsmax(g_szData), '=', 0);
		formatex(infoBuffer, charsmax(infoBuffer), "%s=,;%d,%d,%d,%d,%d,%d", password, 0, 0, 0, 0, 0, 0);
		formatex(g_iWeapszBuffer, charsmax(g_iWeapszBuffer), "%d", 0);
		for (new i = 1; i < MAX_SKINS; i++)
		{
			format(g_iWeapszBuffer, charsmax(g_iWeapszBuffer), "%s,0", g_iWeapszBuffer);
		}
		formatex(skinBuffer, charsmax(skinBuffer), "%d", 0);
		for (new i = 2; i <= 30; i++)
		{
			format(skinBuffer, charsmax(skinBuffer), "%s,0", skinBuffer);
		}
		formatex(g_szData, charsmax(g_szData), "%s*%s#%s", infoBuffer, g_iWeapszBuffer, skinBuffer);
		nvault_set(g_Vault, arg1, g_szData);
		console_print(id, "%s The account has been reseted: %s", CSGO_TAG, arg1);
		ResetData(id, true);
		_Save(index);
	}
	else
	{
		console_print(id, "%s The account was not found: %s", CSGO_TAG, arg1);
	}
	return PLUGIN_HANDLED;
}

public concmd_changepass(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_changepass()")
	#endif

	if (!cmd_access(id, level, cid, 3, false))
	{
		return PLUGIN_HANDLED;
	}

	new arg1[MAX_NAME_LENGTH];
	new arg2[32];
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));
	new target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
	if (!target)
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1);
		return PLUGIN_HANDLED;
	}
	
	new len = strlen(g_szUser_SavedPass[target]);
	if (len > 6)
	{
		copy(g_szUser_SavedPass[target], charsmax(g_szUser_SavedPass[]), arg2);
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_PASSWORD_CHANGED", target, arg2);
		client_print_color(target, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_CHANGED_PASSWORD", g_szName[id], arg2);
	}
	else
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_FOUND_IN_DBASE", target);
	}
	_Save(target);
	return PLUGIN_HANDLED;
}

public concmd_getinfo(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_getinfo()")
	#endif

	if (!cmd_access(id, level, cid, 3, false))
	{
		return PLUGIN_HANDLED;
	}
	new arg1[8];
	new arg2[8];
	read_argv(1, arg1, 7);
	read_argv(2, arg2, 7);
	new num = str_to_num(arg2);
	switch (arg1[0])
	{
		case 'r', 'R':
		{
			if (num < 0 || num >= g_iRanksNum)
			{
				console_print(id, "%s Wrong index. Please choose a number between 0 and %d.", CSGO_TAG, g_iRanksNum - 1);
			}
			else
			{
				new Name[MAX_RANK_NAME];
				ArrayGetString(g_aRankName, num, Name, charsmax(Name));
				new Kills = ArrayGetCell(g_aRankKills, num);
				console_print(id, "%s Information about RANK with index: %d", CSGO_TAG, num);
				console_print(id, "%s Name: %s | Required kills: %d", CSGO_TAG, Name, Kills);
			}
		}
		case 's', 'S':
		{
			if (num < 0 || num >= g_iSkinsNum)
			{
				console_print(id, "%s Wrong index. Please choose a number between 0 and %d.", CSGO_TAG, g_iSkinsNum - 1);
			}
			else
			{
				new Name[48];
				ArrayGetString(g_aSkinName, num, Name, charsmax(Name));
				new Type[2];
				ArrayGetString(g_aSkinType, num, Type, charsmax(Type));
				console_print(id, "%s Information about SKIN with index: %d", CSGO_TAG, num);
				switch (Type[0])
				{
					case 'd':
					{
						console_print(id, "%s Name: %s | Type: drop", CSGO_TAG, Name);
					}
					
					default:
					{
						console_print(id, "%s Name: %s | Type: craft", CSGO_TAG, Name);
					}
				}
			}
		}
		default:
		{
			console_print(id, "%s Wrong index. Please choose R or S.", CSGO_TAG);
		}
	}
	return PLUGIN_HANDLED;
}

public concmd_nick(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_nick()")
	#endif

	if (!cmd_access(id, level, cid, 3, false))
	{
		return PLUGIN_HANDLED;
	}	
	new arg1[32], arg2[32];

	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));

	new player = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
	
	if (!player)
	{
		console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_T_NOT_FOUND", arg1);
		return PLUGIN_HANDLED;
	}

	g_eEnumBooleans[player][IsChangeNotAllowed] = true;
	set_user_info(player, "name", arg2);
	client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_CHANGE_X_NICK", g_szName[id], g_szName[player], arg2);
	set_task(0.5, "task_Reset_Name", id + TASK_RESET_NAME);

	console_print(id, "%s %L", CSGO_TAG, LANG_SERVER, "CSGOR_CHANGED_NICK", g_szName[player], arg2);

	return PLUGIN_HANDLED;
}

public concmd_skin_index(id, level, cid)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_skin_index()")
	#endif

	if (!cmd_access(id, level, cid, 2, false))
	{
		return PLUGIN_HANDLED;
	}	
	new arg[48], iIndex, temp[MAX_SKIN_NAME];

	read_argv(1, arg, charsmax(arg));
	remove_quotes(arg);

	for(new i; i < ArraySize(g_aSkinName); i++)
	{
		new szSkin[48];
		ArrayGetString(g_aSkinName, i, szSkin, charsmax(szSkin));
		iIndex = containi(szSkin, arg);

		if(iIndex > -1)
		{
			formatex(temp, charsmax(temp), "Skin Name: %s^nSkin ID: %i", szSkin, i);
			break;
		}
		else
		{
			formatex(temp, charsmax(temp), "%L", LANG_SERVER, "CSGOR_NO_SKIN_FOUND");
		}
	}
	console_print(id, temp);

	return PLUGIN_HANDLED;
}

public clcmd_say_skin(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "clcmd_say_skin()")
	#endif

	new player = id;
	if(!is_user_alive(player))
	{
		player = pev(player, pev_iuser2);
		if (!is_user_alive(player))
		{
			return PLUGIN_HANDLED;
		}
	}
	if(!g_bLogged[player])
	{
		return PLUGIN_HANDLED;
	}
	new iActiveItem = get_pdata_cbase(player, OFFSET_ACTIVE_ITEM, XO_PLAYER);
	if(pev_valid(iActiveItem) != PDATA_SAFE)
	{
		return PLUGIN_HANDLED;
	}
	new weapon = get_pdata_int(iActiveItem, OFFSET_ID, XO_WEAPON);
	if((1 << weapon) & weaponsWithoutSkin)
	{
		return PLUGIN_HANDLED;
	}

	new skin = GetSkinInfo(player, weapon, iActiveItem);
	
	if(skin == -1)
	{
		client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_NO_ACTIVE_SKIN");
		return PLUGIN_HANDLED;
	}
	new sName[48];
	new sType[4];
	new bool:craft;
	new sChance;
	new sDusts;
	new pMin ;
	new pMax ;
	ArrayGetString(g_aSkinName, skin, sName, charsmax(sName));
	if(g_iStattrackWeap[player][bStattrack][weapon])
	{
		format(sName, charsmax(sName), "(StatTrack) %s", sName);
	}
	ArrayGetString(g_aSkinType, skin, sType, charsmax(sType));
	if (equali(sType, "c"))
	{
		craft = true;
	}
	sChance = ArrayGetCell(g_aSkinChance, skin);
	pMin = ArrayGetCell(g_aSkinCostMin, skin);
	sDusts = ArrayGetCell(g_aDustsSkin, skin);
	pMax = pMin * 2;
	client_print_color(id, print_chat, "^4%s^1 Skin: ^3%s^1 | ^3%s^1 | ^3%d%%^1 | ^3%d - %d^1 points^1 | ^3%d ^1Dusts", CSGO_TAG, sName, g_iStattrackWeap[player][bStattrack][weapon] ? "StatTrack" : (craft ? "Craft" : "Drop"), 100 - sChance, pMin, pMax, sDusts);
	return PLUGIN_HANDLED;
}

public concmd_promocode(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_promocode()")
	#endif

	new data[32];
	read_args(data, charsmax(data));
	remove_quotes(data);
	if (equal(data, ""))
	{
		client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_PROMOCODE_NOT_VALID");
		client_cmd(id, "messagemode Promocode");
		return PLUGIN_HANDLED;
	}
	if(g_iCvars[iSaveType] == NVAULT)
	{
		_LoadPromocodes(id);
	}
	g_szUserPromocode[id] = data;
	_ShowPromocodeMenu(id);
	return PLUGIN_HANDLED;
}

public concmd_betred(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_betred()")
	#endif

	if(!g_bLogged[id] || g_iRedPoints[id] || g_iWhitePoints[id] || g_iYellowPoints[id])
		return PLUGIN_HANDLED;
		
	if(g_bRoulettePlay)
	{
		new cooldown = floatround(g_iCvars[flRouletteCooldown]);
		client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BET_WHILE_ROULETTE_ACTIVE", cooldown);
		return PLUGIN_HANDLED;
	}

	new data[32], amount;
	read_args(data, charsmax(data));
	remove_quotes(data);
	
	amount = str_to_num(data);
	
	if(amount <= 0 || amount > g_iUserPoints[id] || amount == 0)
	{
		client_cmd(id, "messagemode BetRed");
		return PLUGIN_HANDLED;
	}
	
	g_iRedPoints[id] = amount;
	g_iUserPoints[id] -= amount;
	_ShowRouletteMenu(id);
	g_iRoulettePlayers++;
	if(g_iRoulettePlayers == 2 && g_iRouletteTime == 60)
		_RoulettePlay();
	
	return PLUGIN_HANDLED;
}

public concmd_betwhite(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_betwhite()")
	#endif

	if(!g_bLogged[id] || g_iRedPoints[id] || g_iWhitePoints[id] || g_iYellowPoints[id])
		return PLUGIN_HANDLED;
	
	if(g_bRoulettePlay)
	{
		new cooldown = floatround(g_iCvars[flRouletteCooldown]);
		client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BET_WHILE_ROULETTE_ACTIVE", cooldown);
		return PLUGIN_HANDLED;
	}

	new data[32], amount;
	read_args(data, charsmax(data));
	remove_quotes(data);
	
	amount = str_to_num(data);
	
	if(amount <= 0 || amount > g_iUserPoints[id] || amount == 0)
	{
		client_cmd(id, "messagemode BetWhite");
		return PLUGIN_HANDLED;
	}
	
	g_iWhitePoints[id] = amount;
	g_iUserPoints[id] -= amount;
	_ShowRouletteMenu(id);
	g_iRoulettePlayers++;
	if(g_iRoulettePlayers == 2 && g_iRouletteTime == 60)
		_RoulettePlay();
			
	return PLUGIN_HANDLED;
}

public concmd_betyellow(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "concmd_betyellow()")
	#endif

	if(!g_bLogged[id] || g_iRedPoints[id] || g_iWhitePoints[id] || g_iYellowPoints[id])
		return PLUGIN_HANDLED;

	if(g_bRoulettePlay)
	{
		new cooldown = floatround(g_iCvars[flRouletteCooldown]);
		client_print_color(id, print_chat, "^4%s ^1%L", CSGO_TAG, LANG_SERVER, "CSGOR_BET_WHILE_ROULETTE_ACTIVE", cooldown);
		return PLUGIN_HANDLED;
	}

	new data[32], amount;
	read_args(data, charsmax(data));
	remove_quotes(data);
	
	amount = str_to_num(data);
	
	if(amount <= 0 || amount > g_iUserPoints[id] || amount == 0)
	{
		client_cmd(id, "messagemode BetYellow");
		return PLUGIN_HANDLED;
	}

	g_iYellowPoints[id] = amount;
	g_iUserPoints[id] -= amount;
	_ShowRouletteMenu(id);
	g_iRoulettePlayers++;
	if(g_iRoulettePlayers == 2 && g_iRouletteTime == 60)
		_RoulettePlay();

	return PLUGIN_HANDLED;
}

public inspect_weapon(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "inspect_weapon()")
	#endif

	if (pev_valid(id) != PDATA_SAFE || !is_user_alive(id) || cs_get_user_shield(id) || cs_get_user_zoom(id) > 1) return PLUGIN_HANDLED;

	new weaponId = get_user_weapon(id);
	new weapon; 
	weapon = get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, XO_PLAYER);
	
	if(weaponsWithoutInspect & (1<<weaponId) || pev_valid(weapon) != PDATA_SAFE || get_pdata_int(weapon, OFFSET_WEAPON_IN_RELOAD, XO_WEAPON))
		return PLUGIN_HANDLED;

	new animation = inspectAnimation[weaponId];

	switch (weaponId) {
		case CSW_M4A1:
		{
			if (!cs_get_weapon_silen(weapon)) animation = 15;
			else animation = 14;
		} 
		case CSW_USP: 
		{
			if (!cs_get_weapon_silen(weapon)) animation = 17;
			else animation = 16;
		}
	}
	g_eEnumBooleans[id][IsInInspect] = true
	set_pdata_float(weapon, OFFSET_WEAPON_IDLE, 6.5, XO_WEAPON);
	SendWeaponAnim(id, animation);
	return PLUGIN_HANDLED;
}

public WeaponShootInfo2(iPlayer, iEnt, iAnim, const szSoundEmpty[], const szSoundFire[], iPlayAnim, iWeaponType)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "WeaponShootInfo2()")
	#endif

	if(!is_user_connected(iPlayer) || pev_valid(iPlayer) != PDATA_SAFE || !IsPlayer(iPlayer))
		return FMRES_IGNORED;

	static iWeaponID, iClip;
	iWeaponID = get_pdata_cbase(iPlayer, 373, XO_PLAYER);

	iClip = get_pdata_int(iWeaponID, OFFSET_WEAPONCLIP, XO_WEAPON);

	if(!iClip)
	{
		emit_sound(iPlayer, CHAN_WEAPON, szSoundEmpty, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		if(iPlayAnim)
		{
			PlayWeaponState(iPlayer, szSoundFire, iAnim);
		}
		return FMRES_SUPERCEDE;
	}

	if(!pev_valid(iWeaponType))
	{
		return FMRES_SUPERCEDE;
	}

	switch(iWeaponType)
	{
		case WEAPONTYPE_ELITE:
		{
			if(get_pdata_int(iWeaponID, OFFSET_WEAPONSTATE, XO_WEAPON) & WPNSTATE_ELITE_LEFT)
				PlayWeaponState(iPlayer, ELITE_SHOOT_SOUND, ELITE_SHOOTLEFT5);
		}
		case WEAPONTYPE_GLOCK18:
		{
			if(get_pdata_int(iWeaponID, OFFSET_WEAPONSTATE, XO_WEAPON) & WPNSTATE_GLOCK18_BURST_MODE)
				PlayWeaponState(iPlayer, GLOCK18_BURST_SOUND, GLOCK18_SHOOT2);
		}
		case WEAPONTYPE_FAMAS:
		{
			if(get_pdata_int(iWeaponID, OFFSET_WEAPONSTATE, XO_WEAPON) & WPNSTATE_FAMAS_BURST_MODE)
				PlayWeaponState(iPlayer, CLARION_BURST_SOUND, CLARION_SHOOT2);
		}
		case WEAPONTYPE_M4A1:
		{
			if(get_pdata_int(iWeaponID, OFFSET_WEAPONSTATE, XO_WEAPON) & WPNSTATE_M4A1_SILENCED)
				PlayWeaponState(iPlayer, M4A1_SILENT_SOUND, M4A1_SHOOT3);
		}
		case WEAPONTYPE_USP: 
		{
			if(get_pdata_int(iWeaponID, OFFSET_WEAPONSTATE, XO_WEAPON) & WPNSTATE_USP_SILENCED)
				PlayWeaponState(iPlayer, USP_SILENT_SOUND, USP_SHOOT3);
		}
	}

	if(!(get_pdata_int(iWeaponID, OFFSET_WEAPONSTATE, XO_WEAPON)))
		PlayWeaponState(iPlayer, szSoundFire, iAnim);

	return FMRES_SUPERCEDE;
}

bool:IsHalf()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "IsHalf()")
	#endif

	if (g_iCvars[iCompetitive] && !g_bTeamSwap && g_iStats[iRoundNum] == 16)
	{
		return true;
	}
	return false;
}

bool:IsLastRound()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "IsLastRound()")
	#endif

	if (g_iCvars[iCompetitive] && g_bTeamSwap && g_iStats[iRoundNum] == 31)
	{
		return true;
	}
	return false;
}

_ShowBestPlayers()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowBestPlayers()")
	#endif

	new Pl[MAX_PLAYERS];
	new n;
	new p;
	new BestPlayer;
	new Frags;
	new BestFrags;
	new MVP;
	new BestMVP;
	new bonus = g_iCvars[iBestPoints];
	get_players(Pl, n, "he", "TERRORIST");
	if (0 < n)
	{
		for (new i; i < n; i++)
		{
			p = Pl[i];
			MVP = g_iUserMVP[p];
			if (MVP < 1 || MVP < BestMVP)
			{
			}
			else
			{
				Frags = get_user_frags(p);
				if (MVP > BestMVP)
				{
					BestPlayer = p;
					BestMVP = MVP;
					BestFrags = Frags;
				}
				else
				{
					if (Frags > BestFrags)
					{
						BestPlayer = p;
						BestFrags = Frags;
					}
				}
			}
		}
	}

	if (BestPlayer && BestPlayer <= 32)
	{
		client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_BEST_T", g_szName[BestPlayer], BestMVP, bonus);
	}
	else
	{
		client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ZERO_MVP", "Terrorist");
	}
	if (g_bLogged[BestPlayer])
	{
		g_iUserPoints[BestPlayer] += bonus;
	}

	get_players(Pl, n, "he", "CT");
	BestPlayer = 0;
	BestMVP = 0;
	BestFrags = 0;
	if (0 < n)
	{
		for (new i; i < n; i++)
		{
			p = Pl[i];
			MVP = g_iUserMVP[p];
			if (MVP < 1 || MVP < BestMVP)
			{
			}
			else
			{
				Frags = get_user_frags(p);
				if (MVP > BestMVP)
				{
					BestPlayer = p;
					BestMVP = MVP;
					BestFrags = Frags;
				}
				else
				{
					if (Frags > BestFrags)
					{
						BestPlayer = p;
						BestFrags = Frags;
					} 
				}
			}
		}
	}

	if (BestPlayer && BestPlayer <= 32)
	{
		client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_BEST_CT", g_szName[BestPlayer], BestMVP, bonus);
	}
	else
	{
		client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_ZERO_MVP", "Counter-Terrorist");
	}
	if (g_bLogged[BestPlayer])
	{
		g_iUserPoints[BestPlayer] += bonus;
	}
}

_ShowMVP(id, event)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ShowMVP()")
	#endif

	if(!is_user_connected(id))
	{
		return PLUGIN_HANDLED;
	}
	if (event < 1 && g_iRoundKills[id] < 1 )
	{
		return PLUGIN_HANDLED;
	}
	g_iUserMVP[id]++;
	switch (g_iCvars[iMVPMsgType])
	{
		case 0:
		{
			goto _End;
		}
		case 1:
		{
			switch (event)
			{
				case 0:
				{
					client_print_color(0, print_chat, "^4%s^1 Round MVP: ^3%s^1 %L: ^4%d", CSGO_TAG, g_szName[id], LANG_SERVER, "CSGOR_MOST_KILL", g_iRoundKills[id]);
				}
				case 1:
				{
					client_print_color(0, print_chat, "^4%s^1 Round MVP: ^3%s^1 %L", CSGO_TAG, g_szName[id], LANG_SERVER, "CSGOR_PLANTING");
				}
				case 2:
				{
					client_print_color(0, print_chat, "^4%s^1 Round MVP: ^3%s^1 %L", CSGO_TAG, g_szName[id], LANG_SERVER, "CSGOR_DEFUSING");
				}
			}
		}
		case 2:
		{
			set_hudmessage(0, 255, 10, -1.0, 0.1, 0, 0.00, 5.00);
			switch (event)
			{
				case 0:
				{
					show_hudmessage(0, "Round MVP : %s ^n%L (%d).", g_szName[id], LANG_SERVER, "CSGOR_MOST_KILL", g_iRoundKills[id]);
				}
				case 1:
				{
					show_hudmessage(0, "Round MVP : %s ^n%L", g_szName[id], LANG_SERVER, "CSGOR_PLANTING");
				}
				case 2:
				{
					show_hudmessage(0, "Round MVP : %s ^n%L", g_szName[id], LANG_SERVER, "CSGOR_DEFUSING");
				}
			}
		}
		case 3:
		{
			set_dhudmessage(0, 255, 10, -1.0, 0.1, 0, 0.00, 5.00);
			switch (event)
			{
				case 0:
				{
					show_dhudmessage(0, "Round MVP : %s ^n%L (%d).", g_szName[id], LANG_SERVER, "CSGOR_MOST_KILL", g_iRoundKills[id]);
				}
				case 1:
				{
					show_dhudmessage(0, "Round MVP : %s ^n%L", g_szName[id], LANG_SERVER, "CSGOR_PLANTING");
				}
				case 2:
				{
					show_dhudmessage(0, "Round MVP : %s ^n%L", g_szName[id], LANG_SERVER, "CSGOR_DEFUSING");
				}
			}
		}
	}

	_End:
	ExecuteForward(g_iForwards[ user_mvp ], g_iForwardResult, id, event, g_iRoundKills[id]);
	_GiveBonus(id, 1);

	return PLUGIN_HANDLED;
}

_GetTopKiller(team)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_GetTopKiller()")
	#endif

	new Pl[MAX_PLAYERS];
	new n;
	switch(team)
	{
		case 1:
		{
			get_players(Pl, n, "h", "T");
		}
		case 2:
		{
			get_players(Pl, n, "h", "CT");
		}
	}
	new p;
	new pFrags;
	new pDamage;
	new tempF;
	new tempD;
	new tempID;
	for (new i; i < n; i++)
	{
		p = Pl[i];
		pFrags = g_iRoundKills[p];
		if (!(pFrags < tempF))
		{
			pDamage = g_iDealDamage[p];
			if (pFrags > tempF || pDamage > tempD)
			{
				tempID = p;
				tempF = pFrags;
				tempD = pDamage;
			}
		}
	}
	if (0 < tempF)
	{
		return tempID;
	}
	return PLUGIN_CONTINUE;
}

_GiveBonus(id, type)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_GiveBonus()")
	#endif

	if (!g_bLogged[id])
	{
		client_print_color(id, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_REGISTER");
		return PLUGIN_HANDLED;
	}
	new rpoints;
	switch (type)
	{
		case 0:
		{
			rpoints = random_num(g_iCvars[iAMinPoints], g_iCvars[iAMaxPoints]);
		}
		case 1:
		{
			rpoints = random_num(g_iCvars[iMVPMinPoints], g_iCvars[iMVPMaxPoints]);
		}
	}
	if(g_bLogged[id])
	{
		g_iUserPoints[id] += rpoints;
		_Save(id);
	}
	return PLUGIN_CONTINUE;
}

_SetKillsIcon(id, reset)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_SetKillsIcon()")
	#endif

	if(!is_user_connected(id))
	{
		return PLUGIN_HANDLED;
	}

	switch (reset)
	{
		case 0:
		{
			new num = g_iDigit[id];
			if (num > 10)
			{
				return PLUGIN_HANDLED;
			}
			num--;
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, _, id);
			write_byte(0);
			write_string(szSprite[num]);
			message_end();
			num++;
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, _, id);
			write_byte(1);
			if (num > 9)
			{
				write_string(szSprite[10]);
			}
			else
			{
				write_string(szSprite[num]);
			}
			write_byte(0);
			write_byte(200);
			write_byte(0);
			message_end();
		}
		case 1:
		{
			new num = g_iDigit[id];
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, _, id);
			write_byte(0);
			if (num > 9)
			{
				write_string(szSprite[10]);
			}
			else
			{
				write_string(szSprite[num]);
			}
			message_end();
			g_iDigit[id] = 0;
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, _, id);
			write_byte(1);
			write_string(szSprite[0]);
			write_byte(0);
			write_byte(200);
			write_byte(0);
			message_end();
		}
	}
	return PLUGIN_HANDLED;
}

_DisplayMenu(id, menu)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_DisplayMenu()")
	#endif

	if(!is_user_connected(id))
		return;

	menu_display(id, menu);
}

bool:IsRegistered(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "IsRegistered()")
	#endif

	switch(g_iCvars[iSaveType])
	{
		case NVAULT:
		{
			static g_szData[MAX_SKINS * 3 + 94];
			g_szData[0] = 0;
			new Timestamp;
			if (nvault_lookup(g_Vault, g_szName[id], g_szData, charsmax(g_szData), Timestamp))
			{
				return true;
			}
			return false;
		}
		case MYSQL:
		{
			new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_data` WHERE `Name` = ^"%s^";", g_szName[id]);
			
			if(!SQL_Execute(iQuery))
			{
				SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError));
				log_to_file("csgo_remake_errors.log", g_szSqlError);
				SQL_FreeHandle(iQuery);
			}

			new bool:bFoundData = SQL_NumResults( iQuery ) > 0 ? true : false;

			SQL_FreeHandle(iQuery);

			return bFoundData;
		}
	}
	return false;
}

_MenuExit(menu)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_MenuExit()")
	#endif

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

_GetItemName(item, temp[], len)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_GetItemName()")
	#endif

	if(item == -1)
	{
		return PLUGIN_HANDLED;
	}
	switch (item)
	{
		case KEY:
		{
			formatex(temp, len, "%L", item, "CSGOR_ITEM_KEY");
		}
		case CASE:
		{
			formatex(temp, len, "%L", item, "CSGOR_ITEM_CASE");
		}
		default:
		{
			ArrayGetString(g_aSkinName, item, temp, len);
		}
	}
	return PLUGIN_HANDLED;
}

change_skin(iPlayer, weapon)
{	
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "change_skin()")
	#endif

	if (!weapon || weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_C4) return;
	
	DeployWeaponSwitch(iPlayer);
}

bool:_UserHasItem(id, item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_UserHasItem()")
	#endif

	if (!_IsGoodItem(item))
	{
		return false;
	}
	switch (item)
	{
		case KEY:
		{
			if (g_iUserKeys[id])
			{
				return true;
			}
		}
		case CASE:
		{
			if (g_iUserCases[id])
			{
				return true;
			}
		}
		default:
		{
			if (g_iUserSkins[id][item])
			{
				return true;
			}
		}
	}
	return false;
}

_CalcItemPrice(item, &min, &max)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_CalcItemPrice()")
	#endif

	switch (item)
	{
		case KEY:
		{
			min = g_iCvars[iKeyMinCost];
			max = g_iCvars[iCostMultiplier] * g_iCvars[iKeyMinCost];
		}
		case CASE:
		{
			min = g_iCvars[iCaseMinCost];
			max = g_iCvars[iCostMultiplier] * g_iCvars[iCaseMinCost];
		}
		default:
		{
			min = ArrayGetCell(g_aSkinCostMin, item);
			new i = min;
			max = i * 2;
		}
	}
}

IsTaken(id, &iTimestamp)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "IsTaken()")
	#endif

	switch(g_iCvars[iSaveType])
	{
		case NVAULT:
		{
			new g_szData[24];
			if (nvault_lookup(g_Vault, g_szName[id], g_szData, charsmax(g_szData), iTimestamp))
			{
				return PLUGIN_HANDLED;
			}
		}
		case MYSQL:
		{
			new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `csgor_data` WHERE `Name` = ^"%s^";", g_szName[id]);
			
			if(!SQL_Execute(iQuery))
			{
				SQL_QueryError(iQuery, g_szSqlError, charsmax(g_szSqlError));
				log_to_file("csgo_remake_errors.log", g_szSqlError);
				SQL_FreeHandle(iQuery);
			}

			iTimestamp = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Bonus Timestamp"));

			SQL_FreeHandle(iQuery);

			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

_Send_DeathMsg(killer, victim, hs, weapon[])
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_Send_DeathMsg()")
	#endif

	message_begin(MSG_BROADCAST, g_Msg_DeathMsg);
	write_byte(killer);
	write_byte(victim);
	write_byte(hs);
	write_string(weapon);
	message_end();
}

_ResetTradeData(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ResetTradeData()")
	#endif

	g_bTradeActive[id] = false;
	g_bTradeSecond[id] = false;
	g_bTradeAccept[id] = false;
	g_iTradeTarget[id] = 0;
	g_iTradeItem[id] = -1;
	g_iTradeRequest[id] = 0;
}

_FormatTime(timer[], len, nextevent)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_FormatTime()")
	#endif

	new seconds = nextevent - get_systime();
	new minutes;
	while (seconds >= 60)
	{
		seconds += -60;
		minutes++;
	}
	new bool:add_before;
	new temp[32];
	if (seconds)
	{
		formatex(temp, charsmax(temp), "%i %s", seconds, seconds == 1 ? "second" : "seconds");
		add_before = true;
	}
	if (minutes)
	{
		if (add_before)
		{
			format(temp, charsmax(temp), "%i %s, %s",minutes, minutes == 1 ? "minute" : "minutes", temp);
		}
		else
		{
			formatex(temp, charsmax(temp), "%i %s", minutes, minutes == 1 ? "minute" : "minutes");
			add_before = true;
		}
	}
	if (!add_before)
	{
		copy(timer, len, "Now!");
	}
	else
	{
		formatex(timer, len, "%s", temp);
	}
}

_ClearJackpot()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ClearJackpot()")
	#endif

	ArrayClear(g_aJackpotSkins);
	ArrayClear(g_aJackpotUsers);
	arrayset(g_bUserPlayJackpot, false, sizeof(g_bUserPlayJackpot));
	g_bJackpotWork = false;
	client_print_color(0, print_chat, "^4%s^1 %L", CSGO_TAG, LANG_SERVER, "CSGOR_JP_NEXT");
}

_ResetCoinflipData(id)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_ResetCoinflipData()")
	#endif

	g_bCoinflipActive[id] = false;
	g_bCoinflipSecond[id] = false;
	g_bCoinflipAccept[id] = false;
	g_iCoinflipTarget[id] = 0;
	g_iCoinflipItem[id] = -1;
	g_iCoinflipRequest[id] = 0;
}

_GiveToAll(id, arg1[], arg2[], type)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_GiveToAll()")
	#endif

	new Pl[32];
	new n;
	new target;
	new amount = str_to_num(arg2);
	if (amount)
	{
		switch (arg1[1])
		{
			case 'A', 'a':
			{
				get_players(Pl, n, "h");
			}
			case 'C', 'c':
			{
				get_players(Pl, n, "eh", "CT");
			}
			case 'T', 't':
			{
				get_players(Pl, n, "eh", "TERRORIST");
			}
		}
		if (n)
		{
			switch (type)
			{
				case 0:
				{
					for (new i; i < n; i++)
					{
						target = Pl[i];
						if (g_bLogged[target])
						{
							if (0 > amount)
							{
								g_iUserPoints[target] -= amount;
								if (0 > g_iUserPoints[target])
								{
									g_iUserPoints[target] = 0;
								}
								client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_POINTS");
							}
							else
							{
								g_iUserPoints[target] += amount;
								client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_POINTS");
							}
						}
					}
					new temp[64];
					if (0 < amount)
					{
						if (amount == 1)
						{
							formatex(temp, charsmax(temp), "You gave 1 point to players !");
						}
						else
						{
							formatex(temp, charsmax(temp), "You gave %d points to players !", amount);
						}
						console_print(id, "%s %s", CSGO_TAG, temp);
					}
					else
					{
						if (amount == -1)
						{
							formatex(temp, charsmax(temp), "You got 1 point from players !");
						}
						else
						{
							formatex(temp, charsmax(temp), "You got %d points from players !", amount *= -1);
						}
						console_print(id, "%s %s", CSGO_TAG, temp);
					}
				}
				case 1:
				{
					for (new i; i < n; i++)
					{
						target = Pl[i];
						if (g_bLogged[target])
						{
							if (0 > amount)
							{
								g_iUserCases[target] -= amount;
								if (0 > g_iUserCases[target])
								{
									g_iUserCases[target] = 0;
								}
								client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_CASES");
							}
							else
							{
								g_iUserCases[target] += amount;
								client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_CASES");
							}
						}
					}
					new temp[64];
					if (0 < amount)
					{
						if (amount == 1)
						{
							formatex(temp, charsmax(temp), "You gave 1 case to players !");
						}
						else
						{
							formatex(temp, charsmax(temp), "You gave %d cases to players !", amount);
						}
						console_print(id, "%s %s", CSGO_TAG, temp);
					}
					else
					{
						if (amount == -1)
						{
							formatex(temp, charsmax(temp), "You got 1 case from players !");
						}
						else
						{
							formatex(temp, charsmax(temp), "You got %d cases from players !", amount *= -1);
						}
						console_print(id, "%s %s", CSGO_TAG, temp);
					}
				}
				case 2:
				{
					for (new i; i < n; i++)
					{
						target = Pl[i];
						if (g_bLogged[target])
						{
							if (0 > amount)
							{
								g_iUserKeys[target] -= amount;
								if (0 > g_iUserKeys[target])
								{
									g_iUserKeys[target] = 0;
								}
								client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_KEYS");
							}
							else
							{
								g_iUserKeys[target] += amount;
								client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_KEYS");
							}
						}
					}
					new temp[64];
					if (0 < amount)
					{
						if (amount == 1)
						{
							formatex(temp, charsmax(temp), "You gave 1 key to players !");
						}
						else
						{
							formatex(temp, charsmax(temp), "You gave %d keys to players !", amount);
						}
						console_print(id, "%s %s", CSGO_TAG, temp);
					}
					else
					{
						if (amount == -1)
						{
							formatex(temp, charsmax(temp), "You got 1 key from players !");
						}
						else
						{
							formatex(temp, charsmax(temp), "You got %d keys from players !", amount *= -1);
						}
						console_print(id, "%s %s", CSGO_TAG, temp);
					}
				}
				case 3:
				{
					for (new i; i < n; i++)
					{
						target = Pl[i];
						if (g_bLogged[target])
						{
							if (0 > amount)
							{
								g_iUserDusts[target] -= amount;
								if (0 > g_iUserDusts[target])
								{
									g_iUserDusts[target] = 0;
								}
								client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_SUB_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_DUSTS");
							}
							else
							{
								g_iUserDusts[target] += amount;
								client_print_color(target, print_chat, "^4%s^1 %L %L", CSGO_TAG, LANG_SERVER, "CSGOR_ADMIN_ADD_YOU", g_szName[id], amount, LANG_SERVER, "CSGOR_DUSTS");
							}
						}
					}
					new temp[64];
					if (0 < amount)
					{
						if (amount == 1)
						{
							formatex(temp, charsmax(temp), "You gave 1 dust to players !");
						}
						else
						{
							formatex(temp, charsmax(temp), "You gave %d dusts to players !", amount);
						}
						console_print(id, "%s %s", CSGO_TAG, temp);
					}
					else
					{
						if (amount == -1)
						{
							formatex(temp, charsmax(temp), "You got 1 dust from players !");
						}
						else
						{
							formatex(temp, charsmax(temp), "You got %d dusts from players !", amount *= -1);
						}
						console_print(id, "%s %s", CSGO_TAG, temp);
					}
				}
				default:
				{
				}
			}
		}
		else
		{
			console_print(id, "%s No players found in the chosen category: %s", CSGO_TAG, arg1);
		}
		return PLUGIN_HANDLED;
	}
	console_print(id, "%s <Amount> It must not be 0 (zero)!", CSGO_TAG);
	return PLUGIN_HANDLED;
}

bool:_IsItemSkin(item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_IsItemSkin()")
	#endif

	if (0 <= item < g_iSkinsNum)
	{
		return true;
	}
	return false;
}

bool:_IsGoodItem(item)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "_IsGoodItem()")
	#endif

	if (0 <= item < g_iSkinsNum || item == CASE || item == KEY)
	{
		return true;
	}
	return false;
}

GetUserSkinsNum(id, iWeapon, bool:bStatTrack = false)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "GetUserSkinsNum()")
	#endif

	new iWeaponID;
	new num;
	new iSkins = 0;
	for (new i; i < g_iSkinsNum; i++)
	{
		num = bStatTrack ? g_iStattrackWeap[id][iWeap][i] : g_iUserSkins[id][i];
		iWeaponID = ArrayGetCell(g_aSkinWeaponID, i);
		if (iWeapon == iWeaponID && num > 0)
		{
			iSkins += 1;
		}
	}
	return iSkins;
}

GetMaxSkins(iWeapon)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "GetMaxSkins()")
	#endif

	new iWeaponID;
	new iSkins;
	for (new i; i < g_iSkinsNum; i++)
	{
		iWeaponID = ArrayGetCell(g_aSkinWeaponID, i);
		if (iWeapon == iWeaponID)
		{
			iSkins++;
		}
	}
	return iSkins;
}

SendWeaponAnim(iPlayer, iAnim = 0)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "SendWeaponAnim()")
	#endif

	if(!is_user_connected(iPlayer) || pev_valid(iPlayer) != PDATA_SAFE || !IsPlayer(iPlayer))
		return

	g_iUserBodyGroup[iPlayer] = g_iUserViewBody[iPlayer][cs_get_user_weapon(iPlayer)]

	static iBody
	iBody = g_iUserBodyGroup[iPlayer]

	static iCount, iSpectator, iszSpectators[MAX_PLAYERS];

	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(iBody);
	message_end();

	if(pev(iPlayer, pev_iuser1))
		return;

	get_players(iszSpectators, iCount, "bch");

	for(new i = 0; i < iCount; i++)
	{
		iSpectator = iszSpectators[i];

		if(pev(iSpectator, pev_iuser1) != OBS_IN_EYE || pev(iSpectator, pev_iuser2) != iPlayer || !is_user_connected(iSpectator)) 
			continue;

		set_pev(iSpectator, pev_weaponanim, iAnim);

		message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, iSpectator);
		write_byte(iAnim);
		write_byte(iBody);
		message_end();
	}
}

WeaponDrawAnim(iEntity)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "WeaponDrawAnim()")
	#endif

	static DrawAnim, iWeaponState;

	if(get_pdata_int(iEntity, OFFSET_WEAPONSTATE, XO_WEAPON) & WPNSTATE_USP_SILENCED || get_pdata_int(iEntity, OFFSET_WEAPONSTATE, XO_WEAPON) & WPNSTATE_M4A1_SILENCED)
		iWeaponState = SILENCED;
	else
		iWeaponState = UNSIL;

	if(!pev_valid(GetWeaponEntity(iEntity)))
		return PLUGIN_HANDLED;

	switch(GetWeaponEntity(iEntity))
	{
		case CSW_P228, CSW_XM1014, CSW_M3: DrawAnim = 6;
		case CSW_SCOUT, CSW_SG550, CSW_M249, CSW_G3SG1: DrawAnim = 4;
		case CSW_MAC10, CSW_AUG, CSW_UMP45, CSW_GALIL, CSW_FAMAS, CSW_MP5NAVY, CSW_TMP, CSW_SG552, CSW_AK47, CSW_P90: DrawAnim = 2;
		case CSW_ELITE: DrawAnim = 15;
		case CSW_FIVESEVEN, CSW_AWP, CSW_DEAGLE: DrawAnim = 5;
		case CSW_GLOCK18: DrawAnim = 8;
		case CSW_KNIFE, CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE: DrawAnim = 3;
		case CSW_C4: DrawAnim = 1;
		case CSW_USP:
		{
			switch(iWeaponState)
			{
				case SILENCED: DrawAnim = 6;
				case UNSIL: DrawAnim = 14;
			}
		}
		case CSW_M4A1:
		{
			switch(iWeaponState)
			{
				case SILENCED: DrawAnim = 5;
				case UNSIL: DrawAnim = 12;
			}
		}
	}
	return DrawAnim;
}

PrimaryAttackReplace(id, iEnt)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "PrimaryAttackReplace()")
	#endif

	switch(iEnt)
	{
		case CSW_GLOCK18: WeaponShootInfo2(id, iEnt, GLOCK18_SHOOT3, DRYFIRE_PISTOL, GLOCK18_SHOOT_SOUND, 1, WEAPONTYPE_GLOCK18);
		case CSW_AK47: WeaponShootInfo2(id, iEnt, AK47_SHOOT1, DRYFIRE_RIFLE, AK47_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_AUG: WeaponShootInfo2(id, iEnt, AUG_SHOOT1, DRYFIRE_RIFLE, AUG_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_AWP: WeaponShootInfo2(id, iEnt, AWP_SHOOT2, DRYFIRE_RIFLE, AWP_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_DEAGLE: WeaponShootInfo2(id, iEnt, DEAGLE_SHOOT1, DRYFIRE_PISTOL, DEAGLE_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_ELITE: WeaponShootInfo2(id, iEnt, ELITE_SHOOTRIGHT5, DRYFIRE_PISTOL, ELITE_SHOOT_SOUND, 1, WEAPONTYPE_ELITE);
		case CSW_FAMAS: WeaponShootInfo2(id, iEnt, CLARION_SHOOT3, DRYFIRE_RIFLE, CLARION_SHOOT_SOUND, 1, WEAPONTYPE_FAMAS);
		case CSW_FIVESEVEN: WeaponShootInfo2(id, iEnt, FIVESEVEN_SHOOT1, DRYFIRE_PISTOL, FIVESEVEN_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_G3SG1: WeaponShootInfo2(id, iEnt, G3SG1_SHOOT, DRYFIRE_RIFLE, G3SG1_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_GALIL: WeaponShootInfo2(id, iEnt, GALIL_SHOOT3, DRYFIRE_RIFLE, GALIL_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_M3: WeaponShootInfo2(id, iEnt, M3_FIRE2, DRYFIRE_RIFLE, M3_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_XM1014: WeaponShootInfo2(id, iEnt, XM1014_FIRE2, DRYFIRE_RIFLE, XM1014_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_M4A1: WeaponShootInfo2(id, iEnt, M4A1_UNSIL_SHOOT3, DRYFIRE_RIFLE, M4A1_SHOOT_SOUND, 1, WEAPONTYPE_M4A1);
		case CSW_M249: WeaponShootInfo2(id, iEnt, M249_SHOOT2, DRYFIRE_RIFLE, M249_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_MAC10: WeaponShootInfo2(id, iEnt, MAC10_SHOOT1, DRYFIRE_RIFLE, MAC10_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_MP5NAVY: WeaponShootInfo2(id, iEnt, MP5N_SHOOT1, DRYFIRE_RIFLE, MP5_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_P90: WeaponShootInfo2(id, iEnt, P90_SHOOT1, DRYFIRE_RIFLE, P90_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_P228: WeaponShootInfo2(id, iEnt, P228_SHOOT2, DRYFIRE_PISTOL, P228_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_SCOUT: WeaponShootInfo2(id, iEnt, SCOUT_SHOOT, DRYFIRE_RIFLE, SCOUT_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_SG550: WeaponShootInfo2(id, iEnt, SG550_SHOOT, DRYFIRE_RIFLE, SG550_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_SG552: WeaponShootInfo2(id, iEnt, SG552_SHOOT2, DRYFIRE_RIFLE, SG552_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_TMP: WeaponShootInfo2(id, iEnt, TMP_SHOOT3, DRYFIRE_RIFLE, TMP_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_UMP45: WeaponShootInfo2(id, iEnt, UMP45_SHOOT2, DRYFIRE_RIFLE, UMP45_SHOOT_SOUND, 1, WEAPONTYPE_OTHER);
		case CSW_USP: WeaponShootInfo2(id, iEnt, USP_UNSIL_SHOOT3, DRYFIRE_PISTOL, USP_SHOOT_SOUND, 0, WEAPONTYPE_USP);
	}
}

GetWeaponEntity(iEnt)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "GetWeaponEntity()")
	#endif

	return get_pdata_int(iEnt, OFFSET_ID, XO_WEAPON)
}

PlayWeaponState(iPlayer, const szShootSound[], iWeaponAnim)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "PlayWeaponState()")
	#endif

	emit_sound(iPlayer, CHAN_WEAPON, szShootSound, VOL_NORM, 0.50, 0, PITCH_NORM);

	SendWeaponAnim(iPlayer, iWeaponAnim);
}

DestroyTask(iTaskID)
{
	if(task_exists(iTaskID))
	{
		remove_task(iTaskID);
	}
}

UnixTimeToString(const TimeUnix) 
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "UnixTimeToString()")
	#endif

    new szBuffer[64];
    szBuffer[0] = EOS;
    
    if(!TimeUnix) {
        return szBuffer;
    }
    
    new iYear;
    new iMonth;
    new iDay;
    new iHour;
    new iMinute;
    new iSecond;
    
    UnixToTime(TimeUnix, iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);    
    formatex(szBuffer, charsmax(szBuffer), "%02d:%02d:%02d", iHour, iMinute, iSecond);
    
    return szBuffer;
}

FormatStattrack(szName[], iLen, szTemp[])
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "FormatStattrack()")
	#endif

	formatex(szTemp, iLen, "(StatTrack) %s", szName);
}

cmd_execute(id, const text[], any:...)
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "cmd_execute()")
	#endif

	if (!is_user_connected(id)) return;

	#pragma unused text

	new szMessage[256];

	format_args(szMessage, charsmax(szMessage), 1);

	message_begin(id == 0 ? MSG_BROADCAST : MSG_ONE_UNRELIABLE, SVC_DIRECTOR, _, id);
	write_byte(strlen(szMessage) + 2);
	write_byte(10);
	write_string(szMessage);
	message_end();
}

DoIntermission()
{
	#if defined DEBUG
	log_to_file("csgor_debug_logs.log", "DoIntermission()")
	#endif

    emessage_begin(MSG_BROADCAST, SVC_INTERMISSION);
    emessage_end();
}

GetSkinInfo(player, weapon, iActiveItem)
{
	new skin = -1;

	switch (weapon)
	{
		case 29:
		{
			if(g_iStattrackWeap[player][bStattrack][weapon])
			{
				if(g_iStattrackWeap[player][iSelected][weapon] != -1)
				{
					skin = g_iStattrackWeap[player][iSelected][weapon];
				}
			}
			else
			{
				if(g_iUserSelectedSkin[player][weapon] != -1)
				{
					skin = g_iUserSelectedSkin[player][weapon];
				}
			}
			
		}
		default:
		{
			new imp = pev(iActiveItem, pev_impulse);

			if (imp)
			{
				skin = imp - 1;
			}
			else if (!imp)
			{
				skin = (g_iStattrackWeap[player][bStattrack][weapon] ? g_iStattrackWeap[player][iSelected][weapon] : g_iUserSelectedSkin[player][weapon]);
			}
			else
			{
				if(g_iStattrackWeap[player][bStattrack][weapon])
				{
					if(g_iStattrackWeap[player][iSelected][weapon] != -1)
					{
						skin = g_iStattrackWeap[player][iSelected][weapon];
					}
				}
				else
				{
					if(g_iUserSelectedSkin[player][weapon] != -1)
					{
						skin = g_iUserSelectedSkin[player][weapon];
					}
				}
			}
		}
	}

	return skin
}