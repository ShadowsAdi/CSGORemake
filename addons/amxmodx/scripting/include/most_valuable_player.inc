/* Sublime AMXX Editor v4.2 */

#if defined _most_valuable_player_included
	#endinput
#endif
#define _most_valuable_player_included

#pragma reqlib most_valuable_player
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib most_valuable_player
#endif

enum WinScenario
{
	NO_SCENARIO = -1,
	TERO_MVP = 0,
	CT_MVP,
	KILLER_MVP_TERO,
	KILLER_MVP_CT,
	KILLER_MVP /* Just for default: case in PlayTrack(), unusable */
}

/**
 * @description			Multiforward called when a round end.
 *
 * @param scenario		Scenario index. See WinScenario enum
 * 
 * @return				Scenario index.
 */
forward mvp_scenario(WinScenario:scenario);

/**
 * @description     	Returns player's MVP kills.
 *
 * @param id			Player index.
 * 
 * @return				Amount of kills. -1 on error.
 */
native get_user_mvp_kills(id);

/**
 * @description    		Returns top killer's index.
 *
 * @param id			Top killer index.
 * 
 * @return				Top killer's index. -1 on error.
 */
native get_user_mvp_topkiller(id);

/**
 * @description     	Returns player's MVP damage.
 *
 * @param id			Player index.
 * 
 * @return				Player index. -1 on error.
 */
native get_user_mvp_damage(id);

/**
 * @description     	Returns player's MVP damage made with headshot.
 *
 * @param id			Player index.
 * 
 * @return				Player index. -1 on error.
 */
native get_user_mvp_hs_damage(id);

/**
 * @description     	Returns Player's MVPs.
 *
 * @param id			Player index.
 * 
 * @return				Player index. -1 on error.
 */
native get_user_mvps(id);

/**
 * @description     	Returns Player's selected Track.
 *
 * @param id        	Player index.
 * 
 * @return          	Player index. -1 on error.
 */
native get_user_mvp_track(id);

/**
 * @description     	Returns informations about certain Track.
 *
 * @param iTrackID		Track index.
 * @param szName[]		Variable to store track name.
 * @param iNameLen 		Track name lenght.
 * @param szPath[]		Variable to store track's path.
 * @param iPathLen     	Track path lenght.
 * @param iVipOnly		Vip only track ( 1 / 0 )
 * @param iCost			Track cost
 * @param flDuration	Track duration
 * 
 * @return          	1 on success. -1 if TrackID is invalid or on error.
 */
native get_mvp_track_info(iTrackID, szName[], iNameLen, szPath[], iPathLen, iVipOnly, iCost, Float:flDuration)