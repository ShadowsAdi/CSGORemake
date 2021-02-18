/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>

#define PLUGIN  "[CS:GO Remake] Registration Bonus"
#define VERSION "1.0"
#define AUTHOR  "Shadows Adi"

new c_CasesNum
new c_KeysNum
new c_ScrapsNum

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	c_CasesNum = register_cvar("csgor_user_reg_cases", "10")
	c_KeysNum = register_cvar("csgor_user_reg_keys", "10")
	c_ScrapsNum = register_cvar("csgor_user_reg_scraps", "10")
}

public csgor_user_register(id)
{
	if(is_user_connected(id))
	{
		// Giving to every new player some things for registering...

		csgor_set_user_cases(id, csgor_get_user_cases(id) + get_pcvar_num(c_CasesNum))

		csgor_set_user_keys(id, csgor_get_user_keys(id) + get_pcvar_num(c_KeysNum))

		csgor_set_user_dusts(id, csgor_get_user_dusts(id) + get_pcvar_num(c_ScrapsNum))

		client_print_color(id, print_chat, "^4[CS:GO Remake] ^1Thank you for ^4registering^1, you got some ^3free^1 stuff.")
	}
}
