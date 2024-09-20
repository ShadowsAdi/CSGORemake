#if defined _csgo_remake_included
    #endinput
#endif

#define _csgo_remake_included

#pragma reqlib csgo_remake
#if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib csgo_remake
#endif

#define MAX_SKIN_NAME 64

#define MAX_RANK_NAME 48

#define IsPlayer(%0,%1)                    (1 <= %0 <= %1)

#define GetPlayerBit(%0,%1,%2)             ( IsPlayer(%1,%2) && ( %0 & ( 1 << ( %1 & 31 ) ) ) )
#define SetPlayerBit(%0,%1,%2)             ( IsPlayer(%1,%2) && ( %0 |= ( 1 << ( %1 & 31 ) ) ) )
#define ClearPlayerBit(%0,%1)              %0 &= ~( 1 << ( %1 & 31 ) ) 

#define VERSION "3.0.0"

enum
{
    KEY = -6,
    CASE = -5
}

enum _:FileSections
{
    secRanks = 1,
    secDefaultModels,
    secSkins,
    secPromocodes,
    secSortedMenu,
    secDynamicMenu,
    secSkipChat,
    secWeaponSounds,
    secPlayerSounds
}

enum _:MVPEvents
{
    MVP_KILLER = 0,
    MVP_PLANTER,
    MVP_DEFUSER
}

enum _:SkinData
{
    iWeaponID,
    szViewModel[MAX_SKIN_NAME],
    szWeaponModel[MAX_SKIN_NAME],
    bool:bHasWeaponModel,
    iSubModelID,
    szSkinName[MAX_SKIN_NAME],
    iSkinType,
    iSkinChance,
    iSkinCostMin,
    iSkinCostMax,
    iSkinDust,
    iSkinLock
}

enum _:PlayerSkins 
{
    iWeaponid,
    iSkinid,
    iPieces,
    iSelected,
    iKills,
    isStattrack,
    szNameTag[32]
}

/**
 * Returns a player's points.
 *
 * @param id        Player index.
 *
 * @return      Amount of points. -1 on error.
 */
native csgor_get_user_points(id);

/**
 * Sets a player's points to the desired amount.
 *
 * @param id        Player index.
 * @param amount    A valid amount of points.
 *
 * @return          1 on success, -1 otherwise.
 */
native csgor_set_user_points(id, amount);

/**
 * Returns a player's dusts.
 *
 * @param id        Player index.
 *
 * @return          Amount of dusts. -1 on error.
 */
native csgor_get_user_dusts(id);

/**
 * Sets a player's dusts to the desired amount.
 *
 * @param id        Player index.
 * @param amount    A valid amount of dusts.
 *
 * @return          1 on success, -1 otherwise.
 */
native csgor_set_user_dusts(id, amount);

/**
 * Returns a player's keys.
 *
 * @param id        Player index.
 *
 * @return          Amount of keys. -1 on error.
 */
native csgor_get_user_keys(id);

/**
 * Sets a player's keys to the desired amount.
 *
 * @param id        Player index.
 * @param amount    A valid amount of keys.
 *
 * @return          1 on success, -1 otherwise.
 */
native csgor_set_user_keys(id, amount);

/**
 * Returns a player's cases.
 *
 * @param id        Player index.
 *
 * @return      Amount of cases. -1 on error.
 */
native csgor_get_user_cases(id);

/**
 * Sets a player's cases to the desired amount.
 *
 * @param id        Player index.
 * @param amount    A valid amount of cases.
 *
 * @return      1 on success, -1 otherwise.
 */
native csgor_set_user_cases(id, amount);

/**
 * Returns a player's Rank ID. Set Rang name in output.
 *
 * @param id        Player index.
 * @param output    Output buffer for rang name.
 * @param len       Max length of a output buffer.
 *
 * @return      Player Rank ID. -1 on error. -2 if the player is not logged in.
 */
native csgor_get_user_rank(id, output[], len);

/**
 * Sets a player's Rank ID. Set the appropriate amount of kills.
 *
 * @param id        Player index.
 * @param rankid    A valid Rank ID.
 *
 * @return      1 on success, -1 otherwise.
 */
native csgor_set_user_rank(id, rangid);

/**
 * Returns a player's amount of skins by specified Skin ID.
 *
 * @param id        Player index.
 * @param skinid    A valid Skin ID.
 * 
 * @return      Amount of skins. -1 on error.
 */
native csgor_get_user_skins(id, skinid);

/**
 * Sets a player's all skins.
 *
 * @param id        Player index.
 */
native csgor_set_user_all_skins(id);

/**
 * Sets a player's skins (by specific Skin ID) to desired amount.
 *
 * @param id        Player index.
 * @param skinid    A valid Skin ID.
 * @param amount    A valid amount of skins.
 *
 * @return      1 on success, -1 otherwise.
 */
native csgor_set_user_skins(id, skinid, amount);

/**
 * Returns total of skins in Array.
 *
 * @return          Amount of total skins.
 */
native csgor_get_skins_num();

/**
 * Get skin data for given skinID.
 *
 * @param skinid    Skin index.
 * @param output    Output SkinData Array buffer.
 *
 * @return      1 on success, -1 otherwise.
 */
native csgor_get_skin_data(skinid, output[]);

/**
 * Returns whether a player is logged.
 *
 * @param id        Player index.
 *
 * @return      True if it is, false otherwise.
 */
native csgor_is_user_logged(id);

/**
 * Returns if is the half round.
 * 
 * @return          True if it is, false otherwise.
 *
 */
native csgor_is_half_round();

/**
 * Returns if is the last round.
 * 
 * @return          True if it is, false otherwise.
 *
 */
native csgor_is_last_round();

/**
 * Returns if item is a skin, a case or a key.
 * 
 * @type            Bool
 *
 * @return          True if it is, false otherwise.
 *
 */
native csgor_is_good_item(item);

/**
 * Returns if item is a skin.
 * 
 * @type            Bool
 *
 * @return          True if it is, false otherwise.
 *
 */
native csgor_is_item_skin(item);

/**
 * Returns if warmup is active.
 * 
 * @type            Bool
 *
 * @return          True if it is, false otherwise.
 *
 */
native csgor_is_warmup();

/**
 * Returns ranks num from array.
 *
 * @noparam
 *
 * @return          Ranks Num from Array.
 */
native csgor_ranks_num();

/**
 * Returns skin name and skin index in array as string
 * 
 * @param skinName[]        Skin name to search for index in array.
 *
 * @return              Skin index in array.
 *
 */
native csgor_get_skin_index(skinName[]);

/**
 * Returns if player's skin is StatTrack.
 * 
 * @param id            Player index.
 * @type            Bool
 *
 * @return          True if it is, false otherwise.
 *
 */
native csgor_is_skin_stattrack(id);

/**
 * Returns amount of StatTrack Skins on certain SkinID.
 * 
 * @param id            Player index.
 * @param skinid        Skin ID.
 *
 * @return          Amount of StatTrack Skins Num.
 *
 */
native csgor_get_user_statt_skins(id, skinID);

/**
 * Sets certain StatTrack Skins with amount given.
 * 
 * @param id            Player index.
 * @param skinid        Skin ID.
 * @param amount        Amount of StatTrack Skins to set.
 *
 * @return          -1 on error.
 *
 */
native csgor_set_user_statt_skins(id, skinID, amount);

/**
 * Returns player's kills on StatTrack Weapon in his viewmodel.
 * 
 * @param id            Player index
 *
 * @return          Kills Amount.
 *
 */
native csgor_get_user_statt_kills(id);

/**
 * Sets player's kills on StatTrack Weapon in his viewmodel.
 * 
 * @param id            Player index.
 * @param amount        Amount of StatTrack skins.
 *
 * @return          Skin index in array.
 *
 */
native csgor_set_user_statt_kills(id, amount);

/**
 * Stores player's applied StatTrack skin name into a string.
 * 
 * @param id            Player index.
 * @param WeaponID      Weapon index.
 * @param skinname      Buffer to copy name of the StatTrack skin name.
 * @param len           Buffer lenght.
 *
 * @return              -1 if player is not within range, if player is not logged into his account or WeaponID is not within range.
 *
 */
native csgor_get_user_stattrack(id, WeaponID, skinname[], len);

/**
 * Stores player's applied skin name into a string.
 * 
 * @param id            Player index.
 * @param WeaponID      Weapon index.
 * @param skinname      Buffer to copy skin name.
 * @param len           Buffer lenght.
 *
 * @return              -1 if player is not within range, if player is not logged into his account or WeaponID is not within range.
 *
 */
native csgor_get_user_skin(id, WeaponID, skinname[], len);

/**
 * Sets a random StatTrack skin by given amount.
 * 
 * @param id            Player index.
 * @param amount        Amount of StatTrack Skins.
 *
 * @return              -1 on error.
 *
 */
native csgor_set_random_stattrack(id, amount);

/**
 * Returns location of configuration file.
 * 
 * @param szLocation    Buffer to copy config location
 *
 * @noreturn
 *
 */
native csgor_get_config_location(szLocation[64]);

/**
 * Stores database connection information into strings.
 * 
 * @param szHostname    String to retrieve Sql Hostname information.
 * @param iHostLen      Buffer lenght for szHostname parameter.
 * 
 * @param szUsername    String to retrieve Sql Username information.
 * @param iUserLen      Buffer lenght for szUsername parameter.
 * 
 * @param szPassword    String to retrieve Sql Password information.
 * @param iPassLen      Buffer lenght for szPassword parameter.
 * 
 * @param szDatabase    String to retrieve Sql Database information.
 * @param iDbLen        Buffer lenght for szDatabase parameter.
 * 
 * @return              -1 if invalid parameters num is passed, 1 on success.
 */
native csgor_get_database_data(szHostname[], iHostLen, szUsername[], iUserLen, szPassword[], iPassLen, szDatabase[], iDbLen)

/**
 * Converts Rank ID to Rank name. 
 * 
 * @param iRankNum      Rank index.
 * @param szBuffer      Buffer to copy rank name.
 *
 * @return              -1 on error, 1 on success.
 *
 */
native csgor_get_rank_name(iRankNum, szBuffer[])

/**
 * Returns player's weapon body index. 
 * 
 * @param iPlayer       Player index.
 * @param iWID          Weapon index.
 *
 * @return              Player's weapon body index
 *
 */
native csgor_get_user_body(iPlayer, iWID)

/**
 * Calls internal SendWeaponAnim function. 
 * 
 * @param iPlayer       Player index.
 * @param iAnim         Weapon animation to play.
 *
 * @return              0 on error, 1 on success.
 *
 */
native csgor_send_weapon_anim(iPlayer, iAnim)

/**
 * Retrieves current player name stored in Core plugin. 
 * 
 * @param id            Player index.
 * @param szName        Buffer to copy player's name.
 * @param iLen          Buffer length.
 * 
 * @return              -1 on error, 1 on success.
 *
 */
native csgor_get_user_name(id, szName[], iLen)

/**
 * Calls Save function for player's data. 
 * 
 * @param id            Player index.
 *
 * @return              -1 on error, 1 on success.
 *
 */
native csgor_save_user_data(id)

/**
 * Returns if the player has certain item in inventory. 
 * 
 * @param id            Player index.
 * @param item          Item index.
 * @param iStattrack    Check if the searched skin should be Stattrack or not.
 *
 * @note iStattrack parameter should be treated as a boolean value ( 1 or 0 )

 * @return              1 if the item exists, 0 otherwise.
 *
 */
native csgor_user_has_item(id, item, iStattrack)

/**
 * Retrieves the database handles. 
 * 
 * @param iSqlConnection  Handle to store connection in.
 * @param hSqlTuple       Handle to store tuple in.
 *
 * @noreturn
 *
 */
native csgor_get_database_connection(&Handle:iSqlConnection, &Handle:hSqlTuple)

/**
 * Sends a chat message through internal chat format. 
 * 
 * @param id            Receiver index or 0 for all players.
 * @param text          Formatting rules.
 * @param ...           Variable number of formatting parameters.
 *
 * @return              Number of printed characters
 *
 */
native csgor_send_message(id, text[], any:...)

/**
 * Retrieves data of player's skinid. 
 * 
 * @param id            Receiver index or 0 for all players.
 * @param skinid        Skin Index.
 * @param stattrack     If the skin looking for should be stattrack
 * @param ePlayerSkins  Array to copy player's skin data.
 *
 * @return             -1 if not found, index of entry otherwise
 *
 */
native csgor_get_user_skin_data(id, skinid, stattrack, ePlayerSkins[PlayerSkins])

/**
 * Returns number of skins for a WeaponID in Player's array.
 *
 * @param id        Player index.
 * @param wid       Weapon Index.
 * @param stattrack If the skins looking for should be stattrack
 * 
 * @return          Number of total skins for a WeaponID in Player's array.
 */
native csgor_get_user_skinsnum(id, wid, stattrack = 0)

/**
 * Returns the number of Weapons in dynamic menu.
 *
 * @noparam
 * 
 * @return          Number of Weapons in dynamic menu.
 */
native csgor_get_dyn_menu_num()

/**
 * Returns the information of Weapons dynamic menu.
 *
 * @param iMenuID   Menu index in array.
 * @param szItem    Variable to store the weapon's menu name
 * @param szItemID  Variable to store the weapon's WeaponID
 * 
 * @return          Number of Weapons in dynamic menu.
 */
native csgor_get_dyn_menu_item(iMenuID, szItem[], szItemID[])

/**
 * Called when a player log in account.
 *
 * @param id            Player index.
 * 
 * @noreturn
 */
forward csgor_user_logging_in(id);

/**
 * Called when a player log out from his account.
 *
 * @param id            Player index.
 * 
 * @noreturn
 */
forward csgor_user_logging_out(id);

/**
 * Called when a player register a new account.
 *
 * @param id            Player index.
 * 
 * @noreturn
 */
forward csgor_user_register(id);

/**
 * Called when a player is entering a wrong password.
 *
 * @param id            Player index.
 * @param fails         How many times player entered the wrong password.
 * 
 * @noreturn
 */
forward csgor_user_password_failed(id, iFail);

/**
 * Called when a player make assist.
 *
 * @param id                Assist index.
 * @param killer            Killer index.
 * @param victim            Victim index.
 * @param head              1 if HeadShot, 0 otherwise.
 * 
 * @noreturn
 */
forward csgor_user_assist(id, killer, victim, head);

/**
 * Called when a player is MVP.
 *
 * @param id                MVP index.
 * @param event             Event type. (0 - Top Killer, 1 - Planter, 2 - Defuser)
 * @param kills             MVP's kills.
 * 
 * @return                  PLUGIN_HANDLED to prevent showing integrated MVP announcer,
 *                          PLUGIN_CONTINUE to do nothing
 */
forward csgor_user_mvp(id, event, kills);

/**
 * Called when a player is opening a case successfuly.
 *
 * @param id                Player index.
 * 
 * @noreturn
 */
forward csgor_user_case_open(id);

/**
 * Called when a player is crafting a weapon successfuly.
 *
 * @param id                Player index.
 * 
 * @noreturn
 */
forward csgor_user_craft(id);

/**
 * Called when a player is leveling up.
 *
 * @param id                Player index.
 * @param szRank            Buffer to copy rank name to.
 * @param iRank             Rank index in Array.
 * 
 * @noreturn
 */
forward csgor_user_levelup(id, szRank[], iRank);

/**
 * Called when mod has read all the configuration files.
 *
 * @param iSuccess          1 on success, 0 otherwise.
 * 
 * @noreturn
 */
forward csgor_on_configs_executed(iSuccess);

/**
 * Called when a player is eligible for drop.
 *
 * @param id                Player index.
 * 
 * @noreturn
 */
forward csgor_on_user_drop(id)

/** Called while the configuration file is currently in reading
 * 
 * @param szBuffer[]        Buffer which stores data from every line.
 * @param iSection          Indicates currently section from file.
 * @param iLine             Indicates line number in file.
 * 
 * @noreturn
 */
forward csgor_read_configuration_data(szBuffer[], FileSections:iSection, iLine)

/** Called when a weapon has been deployed in player's viewmodel
 * 
 * @param iPlayer           Player index.
 * @param entWeapon         Weapon entity index.
 * 
 * @noreturn
 */
forward csgor_weapon_deploy(iPlayer, entWeapon)

/** Called when connection to database has been established
 * 
 * @noparam
 * 
 * @noreturn
 */
forward csgor_database_loaded()

/** Called when player's account has been fully loaded.
 * 
 * @param iPlayer           Player index.
 * 
 * @noreturn
 */
forward csgor_account_loaded(id)