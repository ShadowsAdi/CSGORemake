/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>

#define PLUGIN  "[CS:GO Remake] Registration Bonus"
#define VERSION "1.1"
#define AUTHOR  "Shadows Adi"

new g_iCasesNum
new g_iKeysNum
new g_iScrapsNum

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	bind_pcvar_num(create_cvar("csgor_user_reg_cases", "10", FCVAR_NONE, "Quantity of cases which a new player receives when register an account."), g_iCasesNum)
	bind_pcvar_num(create_cvar("csgor_user_reg_keys", "10", FCVAR_NONE, "Quantity of keys which a new player receives when register an account."), g_iKeysNum)
	bind_pcvar_num(create_cvar("csgor_user_reg_scraps", "10", FCVAR_NONE, "Quantity of scraps which a new player receives when register an account."), g_iScrapsNum)
}

public csgor_user_register(id)
{
	if(is_user_connected(id))
	{
		// Giving to every new player some things for registering...

		csgor_set_user_cases(id, csgor_get_user_cases(id) + g_iCasesNum)

		csgor_set_user_keys(id, csgor_get_user_keys(id) + g_iKeysNum)

		csgor_set_user_dusts(id, csgor_get_user_dusts(id) + g_iScrapsNum)

		client_print_color(id, print_chat, "^4[CS:GO Remake] ^1Thank you for ^4registering^1, you got some ^3free^1 stuff.")
	}
}
