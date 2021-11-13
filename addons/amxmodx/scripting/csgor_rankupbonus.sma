/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>

#define PLUGIN  "[CS:GO Remake] Rank Up Bonus"
#define VERSION "1.1"
#define AUTHOR  "Shadows Adi"

new g_iRankUp

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	bind_pcvar_num(create_cvar("csgor_bonus_rankup", "3", FCVAR_NONE, "Multiplicator factor for rankup bonus.", true, 0.0), g_iRankUp)
}

public csgor_user_levelup(id, szRank[], iRank)
{
	if(is_user_connected(id) && csgor_is_user_logged(id))
	{
		// Depends on player's rank
		// Example:
		// Cvar csgor_bonus_rankup is "3", so player if is ranking up from first rank, he will get 3 * iRank = 1 key + 1 case
		// If player is ranking up from the second rank, he'll get 3 * iRank = 2 keys + cases

		csgor_set_user_keys(id, csgor_get_user_keys(id) + (g_iRankUp * iRank))
		csgor_set_user_cases(id, csgor_get_user_cases(id) + (g_iRankUp * iRank))
	}
}
