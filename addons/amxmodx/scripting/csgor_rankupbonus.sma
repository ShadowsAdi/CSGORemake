/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>

#define PLUGIN  "[CS:GO Remake] Rank Up Bonus"
#define VERSION "1.0"
#define AUTHOR  "Shadows Adi"

new c_RankUp

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	c_RankUp = register_cvar("csgor_bonus_rankup", "3")
}

public csgor_user_levelup(id, const szRank[], iRank)
{
	if(is_user_connected(id) && csgor_is_user_logged(id))
	{
		// Depends on player's rank
		// Example:
		// Cvar csgor_bonus_rankup is "3", so player if is ranking up from first rank, he will get 3 * iRank = 1 key + 1 case
		// If player is ranking up from the second rank, he'll get 3 * iRank = 2 keys + cases

		csgor_set_user_keys(id, csgor_get_user_keys(id) + (get_pcvar_num(c_RankUp) * iRank))
		csgor_set_user_cases(id, csgor_get_user_cases(id) + (get_pcvar_num(c_RankUp) * iRank))
	}
}
