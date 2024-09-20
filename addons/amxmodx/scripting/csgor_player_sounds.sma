/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <csgo_remake>
#include <reapi>

#define STEP_CONCRETE		0
#define STEP_METAL			1
#define STEP_DIRT			2
#define STEP_VENT			3
#define STEP_GRATE			4
#define STEP_TILE			5
#define STEP_SLOSH			6
#define STEP_WADE			7
#define STEP_LADDER			8
#define STEP_SNOW			9

#define PLUGIN  "[CS:GO Remake] Player custom sounds"
#define AUTHOR  "Shadows Adi"

new Trie:g_tCustomSounds

new g_iPcvarFootsteps

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	RegisterHookChain(RH_SV_StartSound, "RH_SV_StartSound_Pre")

	RegisterHookChain(RG_PM_PlayStepSound, "RG_PM_PlayStepSound_Pre")

	g_iPcvarFootsteps = get_cvar_pointer("mp_footsteps")

	hook_cvar_change(g_iPcvarFootsteps, "CvarChange_FootSteps")
}

public plugin_cfg()
{
	set_pcvar_num(g_iPcvarFootsteps, 0)
}

public CvarChange_FootSteps(pcvar, const old_value[], const new_value[])
{
	set_pcvar_num(pcvar, 0)
}

public plugin_end()
{
	TrieDestroy(g_tCustomSounds)
}

public plugin_natives()
{
	g_tCustomSounds = TrieCreate()
}

public csgor_read_configuration_data(szBuffer[], FileSections:iSection, iLine)
{
	if(iSection != FileSections:secPlayerSounds)
		return 

	static szKey[38], szSound[128]

	parse(szBuffer, szKey, charsmax(szKey), szSound, charsmax(szSound))

	precache_sound(szSound)
	TrieSetString(g_tCustomSounds, szKey, szSound)
}

public RG_PM_PlayStepSound_Pre(iStep, Float:flVol, const iPlayer)
{
	switch(iStep)
	{
		case STEP_METAL:
		{
			emit_sound( iPlayer, CHAN_BODY, TrieFindRandom("pl_metal"), flVol, ATTN_NORM, 0, PITCH_NORM );
		}
		case STEP_DIRT:
		{
			emit_sound( iPlayer, CHAN_BODY, TrieFindRandom("pl_dirt"), flVol, ATTN_NORM, 0, PITCH_NORM );
		}
		case STEP_VENT:
		{
			emit_sound( iPlayer, CHAN_BODY, TrieFindRandom("pl_duct"), flVol, ATTN_NORM, 0, PITCH_NORM );
		}
		case STEP_GRATE:
		{
			emit_sound( iPlayer, CHAN_BODY, TrieFindRandom("pl_grate"), flVol, ATTN_NORM, 0, PITCH_NORM );
		}
		case STEP_TILE:
		{
			emit_sound( iPlayer, CHAN_BODY, TrieFindRandom("pl_tile"), flVol, ATTN_NORM, 0, PITCH_NORM );
		}
		case STEP_SLOSH:
		{
			emit_sound( iPlayer, CHAN_BODY, TrieFindRandom("pl_slosh"), flVol, ATTN_NORM, 0, PITCH_NORM );
		}
		case STEP_WADE:
		{
			emit_sound( iPlayer, CHAN_BODY, TrieFindRandom("pl_wade"), flVol, ATTN_NORM, 0, PITCH_NORM );
		}
		case STEP_LADDER:
		{
			emit_sound( iPlayer, CHAN_BODY, TrieFindRandom("pl_ladder"), flVol, ATTN_NORM, 0, PITCH_NORM );
		}
		case STEP_SNOW:
		{
			emit_sound( iPlayer, CHAN_BODY, TrieFindRandom("pl_snow"), flVol, ATTN_NORM, 0, PITCH_NORM );
		}
		default:
		{
			emit_sound( iPlayer, CHAN_BODY, TrieFindRandom("pl_step"), flVol, ATTN_NORM, 0, PITCH_NORM );
		}
	}
}

public RH_SV_StartSound_Pre(recipients, entity, channel, sample[], volume, Float:attenuation, fFlags, pitch)
{
	if(!TrieKeyExists(g_tCustomSounds, sample))
		return

	if(!is_user_connected(entity))
		return

	static szSound[128]

	TrieGetString(g_tCustomSounds, sample, szSound, charsmax(szSound))

	SetHookChainArg(4, ATYPE_STRING, szSound)
}

TrieFindRandom(szSound[])
{
	new szKey[48]
	new TrieIter:tIter = TrieIterCreate(g_tCustomSounds)
	new Array:aRandomSound = ArrayCreate(48)
	for(new i; i < TrieIterGetSize(tIter); i++)
	{
		TrieIterGetKey(tIter, szKey, charsmax(szKey))
		if(containi(szKey, szSound) != -1)
		{
			ArrayPushString(aRandomSound, szKey)
		}

		TrieIterNext(tIter)
	}

	ArrayGetString(aRandomSound, random_num(0, ArraySize(aRandomSound) - 1), szKey, charsmax(szKey))

	TrieIterDestroy(tIter)
	ArrayDestroy(aRandomSound)

	return szKey
}