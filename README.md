# CSGO Remake

Mod inspired by the popular Counter Strike: Global Offensive.
Running only on AmxModX 1.9.0 / 1.10.0

## Requirements
This mod were tested on Linux Distribution:
- AmxModX 1.8.3-5201
- AmxModX 1.9.0-5271
- AmxModX 1.10.0-5406

## Install
Download latest release from [releases](https://github.com/ShadowsAdi/csgoremake/releases/latest).
Extract the archive and drag and drop files in your 'Cstrike' folder.

## Config
All cvars can be found in ...amxmodx/configs/plugins/csgor/csgo_remake.cfg. This file will be created automatically after mod is installed and running.

## Commands
	# Administration Cmds
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
	
	# Public Cmds
	say /reg ( Opens the registration menu )
	say /menu ( Opens the main menu of the mod )
	say /skin ( Prints a colored message in the target chat with infos about a skin from certain target viewmodel )
	say /accept ( Accept a trade offer request )
	say /deny ( Decline a trade offer request )
	say /acceptcoin ( Accept a coinflip request )
	say /denycoin ( Decline a coinflip request )
	inspect ( Inspect a weapon from the player viewmodel ( not as spectator. This function is registered and as "impulse 100" )
## Docs
