/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 06-12-08
*
*  ============
*   Changelog:
*  ============
*
*  v1.3
*    -Bug Fixes
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION	"1.3"

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define MAX_SOUNDS	50
#define MAX_p_MODELS	50
#define MAX_v_MODELS	50
#define MAX_w_MODELS	50

#define MAP_CONFIGS	1

new new_sounds[MAX_SOUNDS][48]
new old_sounds[MAX_SOUNDS][48]
new sounds_team[MAX_SOUNDS]
new soundsnum

new new_p_models[MAX_p_MODELS][48]
new old_p_models[MAX_p_MODELS][48]
new p_models_team[MAX_p_MODELS]
new p_modelsnum

new new_v_models[MAX_v_MODELS][48]
new old_v_models[MAX_v_MODELS][48]
new v_models_team[MAX_p_MODELS]
new v_modelsnum

new new_w_models[MAX_w_MODELS][48]
new old_w_models[MAX_w_MODELS][48]
new w_models_team[MAX_p_MODELS]
new w_modelsnum

new maxplayers

public plugin_init()
{
	register_plugin("Weapon Model + Sound Replacement",VERSION,"GHW_Chronic")
	register_forward(FM_EmitSound,"Sound_Hook")
	register_forward(FM_SetModel,"W_Model_Hook",1)
	register_logevent("newround",2,"1=Round_Start")
	register_event("CurWeapon","Changeweapon_Hook","be","1=1")
	maxplayers = get_maxplayers()
}

public plugin_precache()
{
	new configfile[200]
	new configsdir[200]
	new map[32]
	get_configsdir(configsdir,199)
	get_mapname(map,31)
	format(configfile,199,"%s/new_weapons_%s.ini",configsdir,map)
	if(file_exists(configfile))
	{
		load_models(configfile)
	}
	else
	{
		format(configfile,199,"%s/new_weapons.ini",configsdir)
		load_models(configfile)
	}
}

public load_models(configfile[])
{
	if(file_exists(configfile))
	{
		new read[96], left[48], right[48], right2[32], trash, team
		for(new i=0;i<file_size(configfile,1);i++)
		{
			read_file(configfile,i,read,95,trash)
			if(containi(read,";")!=0 && containi(read," ")!=-1)
			{
				strbreak(read,left,47,right,47)
				team=0
				if(containi(right," ")!=-1)
				{
					strbreak(right,right,47,right2,31)
					replace_all(right2,31,"^"","")
					if(
					equali(right2,"T") ||
					equali(right2,"Terrorist") ||
					equali(right2,"Terrorists") ||
					equali(right2,"Blue") ||
					equali(right2,"B") ||
					equali(right2,"Allies") ||
					equali(right2,"1")
					) team=1
					else if(
					equali(right2,"CT") ||
					equali(right2,"Counter") ||
					equali(right2,"Counter-Terrorist") ||
					equali(right2,"Counter-Terrorists") ||
					equali(right2,"CounterTerrorists") ||
					equali(right2,"CounterTerrorist") ||
					equali(right2,"Red") ||
					equali(right2,"R") ||
					equali(right2,"Axis") ||
					equali(right2,"2")
					) team=2
					else if(
					equali(right2,"Yellow") ||
					equali(right2,"Y") ||
					equali(right2,"3")
					) team=3
					else if(
					equali(right2,"Green") ||
					equali(right2,"G") ||
					equali(right2,"4")
					) team=4
				}
				replace_all(right,47,"^"","")
				if(file_exists(right))
				{
					if(containi(right,".mdl")==strlen(right)-4)
					{
						if(!precache_model(right))
						{
							log_amx("Error attempting to precache model: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
						}
						else if(containi(left,"models/p_")==0)
						{
							format(new_p_models[p_modelsnum],47,right)
							format(old_p_models[p_modelsnum],47,left)
							p_models_team[p_modelsnum]=team
							p_modelsnum++
						}
						else if(containi(left,"models/v_")==0)
						{
							format(new_v_models[v_modelsnum],47,right)
							format(old_v_models[v_modelsnum],47,left)
							v_models_team[v_modelsnum]=team
							v_modelsnum++
						}
						else if(containi(left,"models/w_")==0)
						{
							format(new_w_models[w_modelsnum],47,right)
							format(old_w_models[w_modelsnum],47,left)
							w_models_team[w_modelsnum]=team
							w_modelsnum++
						}
						else
						{
							log_amx("Model type(p_ / v_ / w_) unknown for model: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
						}
					}
					else if(containi(right,".wav")==strlen(right)-4 || containi(right,".mp3")==strlen(right)-4)
					{
						replace(right,47,"sound/","")
						replace(left,47,"sound/","")
						if(!precache_sound(right))
						{
							log_amx("Error attempting to precache sound: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
						}
						else
						{
							format(new_sounds[soundsnum],47,right)
							format(old_sounds[soundsnum],47,left)
							sounds_team[soundsnum]=team
							soundsnum++
						}
					}
					else
					{
						log_amx("Invalid File: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
					}
				}
				else
				{
					log_amx("File Inexistent: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
				}
				/*if(!file_exists(left))
				{
					log_amx("Warning: File Inexistent: ^"%s^" (Line %d of new_weapons.ini). ONLY A WARNING. PLUGIN WILL STILL WORK!!!!",left,i+1)
				}*/
			}
		}
	}
}

public Changeweapon_Hook(id)
{
	if(!is_user_alive(id))
	{
		return PLUGIN_CONTINUE
	}
	static model[32], i, team

	team = get_user_team(id)

	pev(id,pev_viewmodel2,model,31)
	for(i=0;i<v_modelsnum;i++)
	{
		if(equali(model,old_v_models[i]))
		{
			if(v_models_team[i]==team || !v_models_team[i])
			{
				set_pev(id,pev_viewmodel2,new_v_models[i])
				break;
			}
		}
	}

	pev(id,pev_weaponmodel2,model,31)
	for(i=0;i<p_modelsnum;i++)
	{
		if(equali(model,old_p_models[i]))
		{
			if(p_models_team[i]==team || !p_models_team[i])
			{
				set_pev(id,pev_weaponmodel2,new_p_models[i])
				break;
			}
		}
	}
	return PLUGIN_CONTINUE
}

public Sound_Hook(id,channel,sample[])
{
	if(!is_user_alive(id))
	{
		return FMRES_IGNORED
	}
	if(channel!=CHAN_WEAPON && channel!=CHAN_ITEM)
	{
		return FMRES_IGNORED
	}

	static i, team

	team = get_user_team(id)

	for(i=0;i<soundsnum;i++)
	{
		if(equali(sample,old_sounds[i]))
		{
			if(sounds_team[i]==team || !sounds_team[i])
			{
				engfunc(EngFunc_EmitSound,id,CHAN_WEAPON,new_sounds[i],1.0,ATTN_NORM,0,PITCH_NORM)
				return FMRES_SUPERCEDE
			}
		}
	}
	return FMRES_IGNORED
}

public W_Model_Hook(ent,model[])
{
	if(!pev_valid(ent))
	{
		return FMRES_IGNORED
	}
	static i
	for(i=0;i<w_modelsnum;i++)
	{
		if(equali(model,old_w_models[i]))
		{
			engfunc(EngFunc_SetModel,ent,new_w_models[i])
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public newround()
{
	static ent, classname[8], model[32]
	ent = engfunc(EngFunc_FindEntityInSphere,maxplayers,Float:{0.0,0.0,0.0},4800.0)
	while(ent)
	{
		if(pev_valid(ent))
		{
			pev(ent,pev_classname,classname,7)
			if(containi(classname,"armoury")!=-1)
			{
				pev(ent,pev_model,model,31)
				W_Model_Hook(ent,model)
			}
		}
		ent = engfunc(EngFunc_FindEntityInSphere,ent,Float:{0.0,0.0,0.0},4800.0)
	}
}
