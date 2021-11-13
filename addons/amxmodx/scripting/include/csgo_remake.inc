#if defined _csgo_remake_included
    #endinput
#endif

#define _csgo_remake_included

#pragma reqlib csgo_remake
#if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib csgo_remake
#endif

enum _:FileSections
{
    secRanks = 1,
    secDefaultModels,
    secSkins,
    secPromocodes,
    secSortedMenu,
    secDynamicMenu
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
 * @return      True on success, false otherwise.
 */
native csgor_set_user_points(id, amount);

/**
 * Returns a player's dusts.
 *
 * @param id        Player index.
 *
 * @return      Amount of dusts. -1 on error.
 */
native csgor_get_user_dusts(id);

/**
 * Sets a player's dusts to the desired amount.
 *
 * @param id        Player index.
 * @param amount    A valid amount of dusts.
 *
 * @return      True on success, false otherwise.
 */
native csgor_set_user_dusts(id, amount);

/**
 * Returns a player's keys.
 *
 * @param id        Player index.
 *
 * @return      Amount of keys. -1 on error.
 */
native csgor_get_user_keys(id);

/**
 * Sets a player's keys to the desired amount.
 *
 * @param id        Player index.
 * @param amount    A valid amount of keys.
 *
 * @return      True on success, false otherwise.
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
 * @return      True on success, false otherwise.
 */
native csgor_set_user_cases(id, amount);

/**
 * Returns a player's Rank ID. Set Rang name in output.
 *
 * @param id        Player index.
 * @param output    Output array for rang name.
 * @param len       Max length of a output array.
 *
 * @return      Player Rank ID. -1 on error.
 */
native csgor_get_user_rank(id, output[], len);

/**
 * Sets a player's Rank ID. Set the appropriate amount of kills.
 *
 * @param id        Player index.
 * @param rankid    A valid Rank ID.
 *
 * @return      True on success, false otherwise.
 */
native csgor_set_user_rank(id, rangid);

/**
 * Returns a player's amount of skins by specified Skin ID.
 *
 * @param id        Player index.
 * @param skinid    A valid Skin ID.
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
 * @return      True on success, false otherwise.
 */
native csgor_set_user_skins(id, skinid, amount);

/**
 * Returns total of skins in Array.
 *
 * @return          Amount of total skins.
 */
native csgor_get_skins_num();

/**
 * Get skin name with given skinID.
 *
 * @param skinid    Skin index.
 * @param output    Output array for skin name.
 * @param lem       Max length of a output array.
 *
 * @return      True on success, false otherwise.
 */
native csgor_get_skin_name(skinid, output[], len);

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
 * @return          Skin index in array.
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
 * Copies player's StatTrack skin name from his viewmodel.
 * 
 * @param id            Player index.
 * @param skinname      Buffer to copy name of the StatTrack Weapon in his viewmodel.
 * @param len           Buffer lenght.
 *
 * @return              -1 on error.
 *
 */
native csgor_get_user_stattrack(id, skinname[], len);

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
native csgo_get_config_location(szLocation[64]);

/**
 * Called when a player log in account.
 *
 * @param id            Player index.
 *
 * @return              True if it is, false otherwise.
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
 * @param id           	Player index.
 * @param fails        	How many times player entered the wrong password.
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
 * @param kills             Player's kills.
 * 
 * @noreturn
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
