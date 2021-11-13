# CSGO Remake V 2.10
<img align="center" src="https://i.imgur.com/ByWZCEh.jpg" alt="CS:GO Remake"/>

Mod inspired by the popular Counter Strike: Global Offensive.
Running only on AmxModX 1.8.3 / 1.9.0 / 1.10.0

## Download
[Click HERE](https://github.com/ShadowsAdi/CSGORemake/archive/master.zip)

## Requirements
This mod were tested on Linux Distribution with ReHLDS Engine, ReGameDLL and ReAPI:
- AmxModX 1.8.3-5201
- AmxModX 1.9.0-5271
- AmxModX 1.10.0-5406

## Install
Download latest release from [here](https://github.com/ShadowsAdi/CSGORemake/archive/master.zip).
Extract the archive and drag and drop files in your 'Cstrike' folder.

## Config
All cvars can be found in ...amxmodx/configs/plugins/csgor/csgo_remake.cfg. This file will be created automatically after mod is installed and running.

## Features
nVault and MySQL data saving.

Maxmimum skin amount is 441.

StatTrack System on every Weapon Skin.

Dynamic Main Menu.

RangUP only ( announces in chat those who rank up ).

Automatically weapon reload + refill at spawn.

Kills from each round will be counted on the screen using a sprite model.

MVP at end of the round ( based on best killer or the bomb planter or bomb defuser ).

CS:GO Like end round sounds.

Warmup time ( customizable by cvar )

Kill assist system.

Grenades short throw + lower the time of exploding a grenade with half when it's in short throw.

Trade offer system.

Destroy skins ( you can choose between getting dusts or points ).

Craft skins system ( allows you to craft a rare item using dusts obtained from destroing skins ).

Case opening.

Raffle system ( players join raffle and one of them is chosen randomly and win all points at raffle ).

Jackpot system ( players join jackpot and one of them is chosen randomly and win all skins placed at jackpot ).

Roulette system ( players can play roulette like on gambling sites ).

Coinflip system ( players can bet their skins with other players and the winner gets the opponent's skin ).

Promocode system ( promocodes can be setted up in config file ).

## Commands

	Administration Cmds
	
amx_givepoints <Name> <Amount> ( Give points to a certain target )

amx_givecases <Name> <Amount> ( Give cases to a certain target )
	
amx_givekeys <Name> <Amount> ( Give keys to a certain target )
	
amx_givedusts <Name> <Amount> ( Give dusts to a certain target )
	
amx_setskins <Name> <SkinID> <Amount> ( Set an amount of a SkinID to a certain target )
	
amx_give_all_skins <Name> ( Sets all skins to a certain target )
	
amx_setrank <Name> <RangID> ( Sets a rang to a certain target )
	
amx_finddata <Name> ( Search a player data in the binary data base )
	
amx_resetdata <Name> <Mode> ( Resets a player data. <Mode> 1 - Deleting the account from the binary data base ; <Mode> 0 - Reseting the account from the binary data base. )
	
amx_change_pass <Name> <New Password> ( Reseting a player password )
	
csgor_getinfo <Type> <Index> ( Gets infos about a Rank or a Skin given by RankID / SKinID )
	
amx_nick_csgo <Name> <New Name> ( Changing a player name cuz it is blocked for other plugins )
	
amx_skin_index <Skin Name> ( Returning skin id in the array )
	
	Public Cmds
	
say /reg ( Opens the registration menu )

say /menu ( Opens the main menu of the mod )

say /skin ( Prints a colored message in the target chat with infos about a skin from certain target viewmodel )

say /accept ( Accept a trade offer request )

say /deny ( Decline a trade offer request )

say /acceptcoin ( Accept a coinflip request )

say /denycoin ( Decline a coinflip request )

inspect ( Inspect a weapon from the player viewmodel ( not as spectator. This function is registered and as "impulse 100" )
	
## Docs
Mod has in total, 9 forwards and 23 natives.

More about documentation can be found in [csgo_remake.inc](https://github.com/ShadowsAdi/csgoremake/blob/master/addons/amxmodx/scripting/include/csgo_remake.inc) file .../amxmodx/scripting/include.

## Known Issues
No issue, feel free to open one [here](https://github.com/ShadowsAdi/csgoremake/issues).

## Servers using this plugin
See the list [here](https://www.gametracker.com/search/?search_by=server_variable&search_by2=csgore_version&query=&loc=_all&sort=&order=).

## Credits
[Nubo](https://www.extreamcs.com/forum/nubo-u37689.html) for the original code.

[CS:GO Ports](https://gamebanana.com/studios/34724) and @[TheDoctor0](https://github.com/TheDoctor0/) for pack of weapon textures, original models, submodels and more.

[Hanna](https://forums.alliedmods.net/member.php?u=273346), [1xAero](https://forums.alliedmods.net/member.php?u=284061) for ability to change viewmodel bodygroup that is required for submodels; and to [HamletEagle](https://forums.alliedmods.net/showpost.php?p=2709653&postcount=2) for this post.

[OciXCrom](https://forums.alliedmods.net/member.php?u=239716) for his [CromChat](https://forums.alliedmods.net/showthread.php?p=2503655) library

[GHW_Chronic](https://forums.alliedmods.net/member.php?u=2314) for [Weapon Model + Sound Replacement](https://forums.alliedmods.net/showthread.php?t=43979) script.

[The Kalu](https://www.extreamcs.com/forum/the-kalu-u23351.html) for CS:GO Remake's banner.

And many thanks for those who gave me a deep understanding into pawn: [fysiks](https://forums.alliedmods.net/member.php?u=30719), [Bugsy](https://forums.alliedmods.net/member.php?u=4234), [CrazY.](https://forums.alliedmods.net/member.php?u=260442), [HamletEagle](https://forums.alliedmods.net/member.php?u=237107), [thEsp](https://forums.alliedmods.net/member.php?u=281156).
