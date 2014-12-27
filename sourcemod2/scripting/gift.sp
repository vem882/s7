/*
 /////////////////////////////		   //////////////			/////         /////
			/////					  ///////////////			/////       /////
			/////					 ////////////////			/////     /////
			/////					//////      /////			/////    /////
			/////				   //////       /////			/////  /////
			/////				  //////        /////			//////////
			/////				 ////////////////////			//////////
			/////				/////////////////////			/////  /////
			/////			   //////           /////			/////    /////
			/////			  //////            /////			/////     /////
			/////            //////             /////			/////       /////
			/////           //////              /////			/////         /////

	[TF2] Gift Mod 
	Author: Chaosxk (Tak)
	Alliedmodders: http://forums.alliedmods.net/member.php?u=87026
	Steam Community: http://steamcommunity.com/groups/giftmod
	Current Version: 1.2.3
	
	*** = completed
	Version Log:
	1.2.4 - Not yet done
	- Added Napalm nade
	- Added Incendiary ammo
	- Added Unusual Troll
	- Added pyrovision
	
	1.2.3 - 
	- Once again fixed medic call
	
	1.2.2 -
	- Removed superjump
	- Removed TF2Attributes until it is fixed
	
	1.2.1 - 
	- Fixed medic call not calling properly
	
	1.2.0 - 
	- Camoflage has no particle effect so it will be harder to see
	- Hyper/Snail/Ballsofsteel should reset back properly, still uses ongameframe since other methods had issues
	- Dance fever now spreads to players who attack another person with dance fever
	- Added pitfall
	- Added super jump
	- Changed button to throw nade from middle-mouse to medic call
	- Fixed call stack error for nades
	- Gifts no longer drop when players suicide during pre-round
	- Fix issue with some abilities not resetting on death
	- Fixed dejavu teleporting to old spawn points where there are multiple rounds
	- Scary bullets increased duration from 0.5 to 1 second
	- Color reset for noob mode when suiciding during effect
	
	Description:
	When a player dies, they will drop a gift/present box.  
	A player can take this gift and gain an effect
	The effect can either be bad or good or so so
	
	Dependency: 
	SDKHooks 2.1+
	Sourcemod 1.5+
	Metamod 1.9+
	Morecolors.inc for compiling
	Updater
	
	Effect List:
	Good: MiniHP, Knockers, Hyper, Camoflage, Dracula's Blood, Sentry, Balls Of Steel, BigHead, SmallHead, Feather
	Bad: Dance, Funny Feeling, Nostalgia, Brain Dead, OneHP
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <clientprefs>
//#include <tf2attributes>
#undef REQUIRE_PLUGIN
#include <updater>

//Definitions
#define PLUGIN_VERSION "1.2.3"
#define MDL "models/items/tf_gift.mdl"
#define MDL2 "models/props_halloween/halloween_gift.mdl"
#define EFFECT1 "models/items/ammopack_small_bday.mdl"
#define EFFECT2 "models/items/ammopack_large_bday.mdl"
#define MDL_FIREWORKS "mini_fireworks"
#define MDL_CONFETTI "bday_confetti"
#define SND_BRDY "misc/happy_birthday.wav"
#define MDL_NADE "models/weapons/w_models/w_cannonball.mdl"
#define spirite "spirites/zerogxplode.spr"
#define INFO "http://steamcommunity.com/groups/giftmod"
#define UPDATE_URL "http://dl.dropboxusercontent.com/u/100132876/giftupdater.txt"
////////////////////////////////////////////////////////////////////////////////////////////////////
new Handle:Enabled,
Handle:dropChance,
Handle:dieTime,
Handle:giftSize,
Handle:teamMode,
Handle:Suicide,
Handle:FakeGifts,
Handle:CoolDown,
Handle:goodChance,
Handle:adminFlag,
Handle:adminChance,
Handle:modelBoxes,
Handle:cvarDisabled,
Handle:autoUpdate,
Handle:showAds = INVALID_HANDLE;
////////////////////////////////////////////////////////////////////////////////////////////////////
new Handle:funnyFeeling,
Handle:draculaHeal,
Handle:sentryLevel,
Handle:miniHP,
Handle:alphaCamo,
Handle:featherTouch,
Handle:ballsDefence,
Handle:blindEffect,
Handle:nadeDamage,
Handle:toxicDamage,
Handle:toxicRadius,
Handle:dLevel,
Handle:PitfallEffect = INVALID_HANDLE;
//Handle:jumpHeight = INVALID_HANDLE;
////////////////////////////////////////////////////////////////////////////////////////////////////
new Handle:resetKnockTimer,
Handle:resetAlphaTimer,
Handle:resetMiniCritsTimer,
Handle:resetDraculaTimer,
Handle:resetGravityTimer,
Handle:resetSentryTimer,
Handle:resetNostalgiaTimer,
Handle:resetBHeadTimer,
Handle:resetSHeadTimer,
Handle:resetSpeedTimer,
Handle:resetBrainTimer,
Handle:resetSteelTimer,
Handle:resetInverseTimer,
Handle:resetBlindTimer,
Handle:resetShakeTimer,
Handle:resetSnailTimer,
Handle:resetToxicTimer,
Handle:resetNoobTimer,
Handle:resetScaryTimer,
Handle:resetPitfallTimer = INVALID_HANDLE;
//Handle:resetSuperjumpTimer = INVALID_HANDLE;
////////////////////////////////////////////////////////////////////////////////////////////////////
new Handle:clientTimer[MAXPLAYERS+1],
Handle:inverseTimer = INVALID_HANDLE;
////////////////////////////////////////////////////////////////////////////////////////////////////
new MiniCrits[MAXPLAYERS+1];
new knockBack[MAXPLAYERS+1];
new moreFast[MAXPLAYERS+1];
new headBig[MAXPLAYERS+1];
new headSmall[MAXPLAYERS+1];
new draculaHeart[MAXPLAYERS+1];
new sentry[MAXPLAYERS+1];
new sentrySpawn[MAXPLAYERS+1];
new bool:activeEffect[MAXPLAYERS+1];
new bool:isAlpha[MAXPLAYERS+1];
new g_timeLeft[MAXPLAYERS+1];
new playerStunned[MAXPLAYERS+1];
new playerSteel[MAXPLAYERS+1];
new canShake[MAXPLAYERS+1];
new isTaunting[MAXPLAYERS+1];
new snail[MAXPLAYERS+1];
new toxicOn[MAXPLAYERS+1];
new dispenserSpawn[MAXPLAYERS+1];
new scaryBullets[MAXPLAYERS+1];
new pitFall[MAXPLAYERS+1];
new playerIsBurried[MAXPLAYERS+1];
////////////////////////////////////////////////////////////////////////////////////////////////////
new Float:g_Ang[3];
new Float:clientAngles[MAXPLAYERS+1][3];
new isReversed[MAXPLAYERS+1] = {0,...};
new g_sEnt[MAXPLAYERS+1] = {-1,...};
////////////////////////////////////////////////////////////////////////////////////////////////////
new hasNade[MAXPLAYERS+1];
new NadeCounter[MAXPLAYERS+1];
new nadeEntity[MAXPLAYERS+1];
////////////////////////////////////////////////////////////////////////////////////////////////////
new Float:g_playerSpeed[MAXPLAYERS+1];
new playerAdCount[MAXPLAYERS+1];
new Handle:GiftCount = INVALID_HANDLE;
new playerCookie[MAXPLAYERS+1];
////////////////////////////////////////////////////////////////////////////////////////////////////
new const String:g_goodName[][] = {
	{"minihp"},
	{"knocker"},
	{"bighead"},
	{"smallhead"},
	{"hyper"},
	{"camoflage"},
	{"dracula"},
	{"feather"},
	{"sentry"},
	{"ballsofsteel"},
	{"grenade"},
	{"toxic"},
	{"dispenser"},
	{"scary"},
	{"pitfall"}
	//{"superjump"}
};
////////////////////////////////////////////////////////////////////////////////////////////////////
new const String:g_badName[][] = {
	{"dance"},
	{"funnyfeeling"},
	{"nostalgia"},
	{"onehp"},
	{"braindead"},
	{"inverse"},
	{"blind"},
	{"dejavu"},
	{"earthquake"},
	{"snail"},
	{"noob"}
};
////////////////////////////////////////////////////////////////////////////////////////////////////
new g_good[sizeof(g_goodName)+1];
new g_bad[sizeof(g_badName)+1];
////////////////////////////////////////////////////////////////////////////////////////////////////
new Float:g_pos[3];
new bool:lateLoaded;
new tauntcounter;
new bool:roundStart = false;
new Float:savePos[MAXPLAYERS+1][3];
////////////////////////////////////////////////////////////////////////////////////////////////////
public Plugin:myinfo = {
	name = "[TF2] Gift Mod",
	description = "Collect and gain a random effect from gifts that are dropped.",
	author = "Tak (Chaosxk)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	lateLoaded = late;
	if(!StrEqual(Game, "tf")) {
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart() {
	CreateConVar("sm_gift_version", PLUGIN_VERSION, "Version of Gift Mod.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Enabled = CreateConVar("sm_gift_enabled", "1", "Enable/Disable plugin, 1/0", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	dropChance = CreateConVar("sm_gift_dropchance", "0.65", "What is the chance of dropping gifts on a player death? (Default: 0.65) [0.00 - 1.00]");
	dieTime = CreateConVar("sm_gift_removetimer", "60", "How long before gifts are removed if no one picks it up. (Default: 60)");
	giftSize = CreateConVar("sm_gift_size", "1.2", "Size of gift: (Default: 1.2)");
	teamMode = CreateConVar("sm_gift_allowedteams", "1", "Which teams are allowed to pick up gifts? (0 = none, 1 = All, 2 = Red, 3 = Blue) (Default: 1)");
	Suicide = CreateConVar("sm_gift_suicide", "0", "Allow players who suicide to drop gifts. (Default: 0)");
	FakeGifts = CreateConVar("sm_gift_fake", "1", "Spawn fake gifts when a spy faked his death with the dead ringer? (Default: 1)");
	CoolDown = CreateConVar("sm_gift_cooldown", "3", "How many seconds after the gift has dropped before it can be picked up. (Default: 3)");
	goodChance = CreateConVar("sm_gift_chance", "0.65", "Chances of a good effect being picked up? (Default: 0.65)");
	adminChance = CreateConVar("sm_gift_adminchance", "0.65", "Chances of a good effect being picked up? (Default: 0.65)");
	adminFlag = CreateConVar("sm_gift_flag", "b", "What flag should be used for sm_gift_adminchance? (Default: b)");
	modelBoxes = CreateConVar("sm_gift_models", "2", "Which model box should spawn? (0 = Christmas/Blue, 1 = Halloween/Green, 2 = Both) (Default: 1)");
	cvarDisabled = CreateConVar("sm_gift_disabled", "", "What effect should be disabled?");
	autoUpdate = CreateConVar("sm_gift_update", "1", "Allow this plugin to automatically update? (Default: 1)");
	showAds = CreateConVar("sm_gift_showads", "1", "Allow this plugin tell people who first join the server about gift mod? (Default: 1)");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	funnyFeeling = CreateConVar("sm_gift_funnyfeeling_fov", "160", "What should the funny feeling FOV be? (Default: 160)");
	sentryLevel = CreateConVar("sm_gift_sentrylevel", "1", "What level should sentries spawn as? (Default: 1)");
	draculaHeal = CreateConVar("sm_gift_draculaheal", "0.3", "What percent of damage is healed towards you for Dracula's blood. (Default: 0.3)");
	miniHP = CreateConVar("sm_gift_health", "250", "How much health to give for Minihealth effect? (Default: 250)");
	alphaCamo = CreateConVar("sm_gift_camo_alpha", "30", "What should the alpha be for Camoflage? (Default: 30)");
	featherTouch = CreateConVar("sm_gift_feather_gravity", "0.15", "What should the gravity be for Feather's touch? (Default: 0.15)");
	ballsDefence = CreateConVar("sm_gift_ballsofsteel_defence", "0.5", "What percentage of damage does player recieved when they are hurt? (Default: 0.5)");
	blindEffect = CreateConVar("sm_gift_blind_darkness", "255", "How much to darkness should player be blind? (Default: 255)");
	nadeDamage = CreateConVar("sm_gift_nade_damage", "200", "How much damage should nades do? (Default: 200)");
	toxicDamage = CreateConVar("sm_gift_toxic_damage", "35", "How much damage should toxic do? (Default: 35)");
	toxicRadius = CreateConVar("sm_gift_toxic_radius", "350", "What is the radius of toxic? (Default: 350)");
	dLevel = CreateConVar("sm_gift_dispenserlevel", "3", "What level should dispensers spawn as? (Default: 3)");
	PitfallEffect = CreateConVar("sm_gift_pitfall_delay", "3", "How long are players who becomes victim to pitfall, get stuck for. (Default: 3)");
	//jumpHeight = CreateConVar("sm_gift_superjump_height", "1.5", "How much extra height should be added to player jump with superjump? (Default: 1.5)");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	resetMiniCritsTimer = CreateConVar("sm_gift_minihealth", "15", "How many seconds should Mini Health last? (Default: 15.0)");
	resetKnockTimer = CreateConVar("sm_gift_knockback", "15", "How many seconds should Knockers last? (Default: 15.0)");
	resetBHeadTimer = CreateConVar("sm_gift_bighead", "20.0", "How many seconds should big head reset back to normal? (Default: 20.0)");
	resetSHeadTimer = CreateConVar("sm_gift_smallhead", "20.0", "How many seconds should small head reset back to normal? (Default: 20.0)");
	resetSpeedTimer = CreateConVar("sm_gift_speed", "20.0", "How many seconds should speed reset back to normal? (Default: 20.0)");
	resetAlphaTimer = CreateConVar("sm_gift_camoflage", "15.0", "How many seconds for Camoflage to reset back to normal? (Default: 15.0)");
	resetDraculaTimer = CreateConVar("sm_gift_dracula", "15.0", "How many seconds should Dracula heart last? (Default: 15.0)");
	resetGravityTimer = CreateConVar("sm_gift_gravity", "15.0", "How many seconds should Gravity last? (Default: 15.0)");
	resetNostalgiaTimer = CreateConVar("sm_gift_nostalgia", "15.0", "How long should nostalgia last? (Default: 15.0)");
	resetSentryTimer = CreateConVar("sm_gift_sentry", "15.0", "How many seconds should the Sentry gun last? (Default: 15.0)");
	resetBrainTimer = CreateConVar("sm_gift_braindead", "5.0", "How many seconds should Brain dead last? (Default: 5.0)");
	resetSteelTimer = CreateConVar("sm_gift_ballsofsteel", "15.0", "How many seconds should Balls of Steel last? (Default: 15.0)");
	resetInverseTimer = CreateConVar("sm_gift_inverse", "15.0", "How many seconds Inverse view last? (Default: 15.0)");
	resetBlindTimer = CreateConVar("sm_gift_blind", "15.0", "How many seconds does blind last? (Default: 15.0)");
	resetShakeTimer = CreateConVar("sm_gift_shake", "15.0", "How many seconds does earthquake last? (Default: 15.0)");
	resetSnailTimer = CreateConVar("sm_gift_snail", "20.0", "How many seconds does snail last? (Default: 20.0)");
	resetToxicTimer = CreateConVar("sm_gift_toxic", "20.0", "How many seconds does toxic last? (Default: 20.0)");
	resetNoobTimer  = CreateConVar("sm_gift_noob", "20.0", "How many seconds does noob mode last? (Default: 20.0)");
	resetScaryTimer  = CreateConVar("sm_gift_scary", "20.0", "How many seconds does scary bullets last? (Default: 20.0)");
	resetPitfallTimer = CreateConVar("sm_gift_pitfall", "15.0", "How many seconds should pitfall last? (Default: 15.0)");
	//resetSuperjumpTimer = CreateConVar("sm_gift_superjump", "20.0", "How many seconds should superjump last? (Default: 20.0)");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", OnTeamChange);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	RegAdminCmd("sm_seteffect", SetEffect, ADMFLAG_GENERIC, "Set one of the effects on yourself. (!seteffect <player> <effectname>)");
	RegAdminCmd("sm_removeeffect", RemoveEffect, ADMFLAG_GENERIC, "Removes all effect off yourself.");
	RegAdminCmd("sm_listeffect", ListEffect, ADMFLAG_GENERIC, "List the effects in console.");
	RegAdminCmd("sm_spawngift", SpawnGift, ADMFLAG_GENERIC, "Spawns a gift at your cursor.");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	RegConsoleCmd("sm_gift", Gift, "Shows how many gift you have collected.");
	RegConsoleCmd("sm_gifthelp", GiftHelp, "Shows the Gift Community Page which has description of each effect.");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	GiftCount = RegClientCookie("giftmodcookies", "Gift Tracker Cookies", CookieAccess_Private);
	HookConVarChange(cvarDisabled, cvarChange);
	LoadDisabledAbilities();
	AddCommandListener(VoiceListener, "voicemenu");
	LoadTranslations("common.phrases");
	LoadTranslations("gift.phrases");
	AutoExecConfig(true, "gift");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	if(GetConVarInt(autoUpdate) == 1) {
		if(LibraryExists("updater")) {
			Updater_AddPlugin(UPDATE_URL);
		}
	}
}

public OnPluginEnd() {
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "item_ammopack_small")) != -1) {
		if(IsValidEntity(ent)) {
			decl String:name[32];
			GetEntPropString(ent, Prop_Data, "m_iName", name, 128, 0);
			if(StrEqual(name, "giftbox%tak")) {
				AcceptEntityInput(ent, "kill");
			}
		}
	}
}

public OnLibraryAdded(const String:name[]) {
	if(GetConVarInt(autoUpdate) == 1) {
		if(StrEqual(name, "updater")) {
			Updater_AddPlugin(UPDATE_URL);
		}
	}
}

//precache on mapstart
public OnMapStart() {
	PrecacheModel(MDL, true);
	PrecacheModel(MDL2, true);
	PrecacheModel(EFFECT1, true);
	PrecacheModel(EFFECT2, true);
	PrecacheSound(SND_BRDY, true);
	PrecacheGeneric(MDL_FIREWORKS, true);
	PrecacheGeneric(MDL_CONFETTI, true);
	PrecacheModel(MDL_NADE, true);
	PrecacheModel(spirite, true);
}

//resets the variables of player number so the next connection does not recieve effect
public OnClientConnected(client) {
	if(Enabled) {
		if(IsValidClient(client)) {
			MiniCrits[client] = 0;
			knockBack[client] = 0;
			headBig[client] = 0;
			headSmall[client] = 0;
			sentry[client] = 0;
			sentrySpawn[client] = 0;
			draculaHeart[client] = 0;
			activeEffect[client] = false;
			isAlpha[client] = false;
			g_timeLeft[client] = 0;
			playerStunned[client] = 0;
			playerSteel[client] = 0;
			isReversed[client] = 0;
			hasNade[client] = 0;
			NadeCounter[client] = 0;
			nadeEntity[client] = 0;
			canShake[client] = 0;
			snail[client] = 0;
			toxicOn[client] = 0;
			dispenserSpawn[client] = 0;
			scaryBullets[client] = 0;
			pitFall[client] = 0;
			playerIsBurried[client] = 0;
			g_playerSpeed[client] = 0.0;
			playerAdCount[client] = 0;
			//recieves the player's cookie
			playerCookie[client] = 0;
			GetCookie(client);
			//hooks the ontakedamage for newly connected players
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientDisconnect(client) {
	if(IsValidClient(client)) {
		ClearTimer(clientTimer[client]);
		ClearTimer(inverseTimer);
		//removeAttribute(client, "increased jump height");
	}
}

//used to load lateloaded stuff
public OnConfigsExecuted() {
	if(Enabled) {
		if(lateLoaded) {
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i)) {
					SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
					playerCookie[i] = 0;
					GetCookie(i);
				}
			}
			lateLoaded = false;
			roundStart = true;
		}
	}
}

//reloads when cvar changes
public cvarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(convar == cvarDisabled) {
		LoadDisabledAbilities();
	}
}

//sets effect on a player
public Action:SetEffect(client, args) {
	if(Enabled) {
		decl String:arg1[65], String:arg2[65];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		if((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		if(args < 2) {
			PrintToChat(client, "%t", "Fix");
			return Plugin_Handled;
		}
		
		if(args == 2) {
			for(new i = 0; i < target_count; i++) {
				if(IsValidClient(target_list[i])) {
					startEffect(client, target_list[i], arg2);
				}
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//removes the effect
public Action:RemoveEffect(client, args) {
	if(Enabled) {
		decl String:arg1[65];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		if((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		if(args < 1) {
			PrintToChat(client, "%t", "Fix2");
			return Plugin_Handled;
		}
		
		if(args == 1) {
			for(new i = 0; i < target_count; i++) {
				if(IsValidClient(target_list[i])) {
					resetEffects(target_list[i]);
					CPrintToChat(client, "%t", "Clear");
				}
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//finds the effect and enable it
public startEffect(client, target, const String:effect[]) {
	if(IsValidClient(target)) {
		if(IsPlayerAlive(target)) {
			if(activeEffect[target] == false) {
				if(StrEqual(effect, "minihp", false)) addMiniHealth(target, GetConVarInt(miniHP));
				else if(StrEqual(effect, "dance", false)) ForceTaunt(target);
				else if(StrEqual(effect, "knocker", false)) knockBackPlayer(target);
				else if(StrEqual(effect, "bighead", false)) resizeHeadBig(target);
				else if(StrEqual(effect, "smallhead", false)) resizeHeadSmall(target);
				else if(StrEqual(effect, "hyper", false)) SpeedMore(target);
				else if(StrEqual(effect, "camoflage", false)) setAlpha(target, GetConVarInt(alphaCamo));
				else if(StrEqual(effect, "funnyfeeling", false)) setFOV(target);
				else if(StrEqual(effect, "dracula", false)) draculaEnabled(target);
				else if(StrEqual(effect, "feather", false)) SetGravity(target, GetConVarFloat(featherTouch));
				else if(StrEqual(effect, "nostalgia", false)) SetNostalgia(target);
				else if(StrEqual(effect, "sentry", false)) SpawnSentry(target);
				else if(StrEqual(effect, "onehp", false)) addOneHP(target);
				else if(StrEqual(effect, "braindead", false)) toggleBrainDead(target);
				else if(StrEqual(effect, "ballsofsteel", false)) toggleBallsOfSteel(target);
				else if(StrEqual(effect, "inverse", false)) toggleInverse(target);
				else if(StrEqual(effect, "blind", false)) toggleBlind(target);
				else if(StrEqual(effect, "dejavu", false)) teleportToSpawn(target);
				else if(StrEqual(effect, "grenade", false)) giveNade(target);
				else if(StrEqual(effect, "earthquake", false)) shakePlayer(target);
				else if(StrEqual(effect, "snail", false)) toggleSlowdown(target);
				else if(StrEqual(effect, "toxic", false)) toggleToxic(target);
				else if(StrEqual(effect, "noob", false)) toggleNoob(target);
				else if(StrEqual(effect, "dispenser", false)) SpawnDispenser(target);
				else if(StrEqual(effect, "scary", false)) toggleScary(target);
				else if(StrEqual(effect, "pitfall", false)) togglePitfall(target);
				//else if(StrEqual(effect, "superjump", false)) toggleSuperjump(target);
				else {
					CPrintToChat(client, "%t", "ERROR");
				}
			}
			else {
				CPrintToChat(client, "%t", "Duplicate");
			}
		}
	}
}

//lists all effect names in console to be used with !seteffect
public Action:ListEffect(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			PrintToConsole(client, "%t", "List");
			PrintToChat(client, "%t", "List2");
		}
	}
	return Plugin_Handled;
}

//spawns a  gift at the player's cursor
public Action:SpawnGift(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			if(!SetTeleportEndPoint(client)) PrintToChat(client, "%t", "Spawn");
			g_pos[2] -= 10;
			createGift(client, g_pos, false);
		}
	}
	return Plugin_Handled;
}

public Action:Gift(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			CPrintToChat(client, "%t", "Collected", playerCookie[client]);
		}
	}
}

public Action:GiftHelp(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			new Handle:setup = CreateKeyValues("data");
			KvSetString(setup, "title", "Gift Info");
			KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
			KvSetString(setup, "msg", INFO);
			KvSetNum(setup, "customsvr", 1);
			ShowVGUIPanel(client, "info", setup, true);
			CloseHandle(setup);
		}
	}
}

//reset effects when player changes team
public Action:OnTeamChange(Handle:event, String:name[], bool:dontBroadcast) {
	if(Enabled) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetEventInt(event, "team");
		if(IsValidClient(client)) {
			if(GetConVarInt(showAds) == 1) {
				if(playerAdCount[client] == 0) {
					if(team == 2 || team == 3) {
						playerAdCount[client]++;
						CPrintToChat(client, "%t", "Advertise");
					}
				}
			}
		}
	}
}

//prevents player from dropping gift during waiting setup time
public Action:OnRoundStart(Handle:event, String:name[], bool:dontBroadcast) {
	CreateTimer(10.0, setRoundTrue);
}

public Action:setRoundTrue(Handle:timer) {
	roundStart = true;
}

public Action:OnRoundEnd(Handle:event, String:name[], bool:dontBroadcast) {
	roundStart = false;
}

//called when a player dies...spawns a gift
public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	if(Enabled) {
		if(roundStart == true) {
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
			new deathflags = GetEventInt(event, "death_flags");
			if(IsValidClient(client) && IsValidClient(killer)) {
				if(deathflags != TF_DEATHFLAG_DEADRINGER) {
					if(GetRandomFloat(0.0, 1.0) <= GetConVarFloat(dropChance)) {
						if(GetConVarInt(Suicide) == 1 || GetConVarInt(Suicide) == 0 && client != killer) {
							new Float:pos[3];
							GetClientAbsOrigin(client, pos);
							createGift(client, pos, false);
						}
					}
				}
				else if(deathflags == TF_DEATHFLAG_DEADRINGER) {
					if(GetConVarInt(FakeGifts) == 1) {
						new Float:pos[3];
						GetClientAbsOrigin(client, pos);
						createGift(client, pos, true);
					}
				}
				resetEffects(client);
			}
		}
	}
}

public createGift(client, Float:pos[3], bool:isFake) {
	new ent = CreateEntityByName("item_ammopack_small");
	if(IsValidEntity(ent)) {
		//generate a random gift box model
		new gen;
		if(GetConVarInt(modelBoxes) == 2) gen = GetRandomInt(0,1);
		else if(GetConVarInt(modelBoxes) == 1) gen = 1;
		else if(GetConVarInt(modelBoxes) == 0) gen = 0;
		
		if(gen == 0) {
			DispatchKeyValue(ent, "powerup_model", MDL);
			SetEntPropFloat(ent, Prop_Send, "m_flModelScale", GetConVarFloat(giftSize));
		}
		else if(gen == 1) {
			DispatchKeyValue(ent, "powerup_model", MDL2);
			//makes sure it scales with the other model, not exact but its good enough
			SetEntPropFloat(ent, Prop_Send, "m_flModelScale", GetConVarFloat(giftSize)*0.70);
		}
		DispatchKeyValue(ent, "targetname", "giftbox%tak");
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR); 
		DispatchSpawn(ent); 
		ActivateEntity(ent);
		
		CreateParticle(MDL_FIREWORKS, 5.0, ent);
		CreateParticle(MDL_CONFETTI, 5.0, ent);
		EmitAmbientSound(SND_BRDY, pos);
		
		SetEntProp(ent, Prop_Send, "m_iTeamNum", 1, 4);

		if(GetConVarInt(CoolDown) > 0) {
			SetEntityRenderMode(ent, RENDER_TRANSALPHA);
			SetEntityRenderColor(ent, _, _, _, 100);
			if(isFake == false) CreateTimer(GetConVarFloat(CoolDown), StartTouchTimer, ent);
			else if(isFake == true) CreateTimer(GetConVarFloat(CoolDown), FakeTouchTimer, ent);
		}
		else {
			if(isFake == false) SDKHook(ent, SDKHook_StartTouch, StartTouch);
			else if(isFake == true) SDKHook(ent, SDKHook_StartTouch, FakeTouch);
		}
	}
}

public Action:StartTouchTimer(Handle:timer, any:ent) { 
	if(IsValidEntity(ent)) {
		decl String:name[32];
		GetEntPropString(ent, Prop_Data, "m_iName", name, 128, 0);
		if(StrEqual(name, "giftbox%tak")) {
			SDKHook(ent, SDKHook_StartTouch, StartTouch);
			SetEntityRenderMode(ent, RENDER_NORMAL);
			SetEntityRenderColor(ent, _, _, _, 255);
			CreateTimer(GetConVarFloat(dieTime), RemoveGift, ent);
        } 
	}
}

public Action:FakeTouchTimer(Handle:timer, any:ent) { 
	if(IsValidEntity(ent)) {
		decl String:name[32];
		GetEntPropString(ent, Prop_Data, "m_iName", name, 128, 0);
		if(StrEqual(name, "giftbox%tak")) {
			SDKHook(ent, SDKHook_StartTouch, FakeTouch);
			SetEntityRenderMode(ent, RENDER_NORMAL);
			SetEntityRenderColor(ent, _, _, _, 255);
			CreateTimer(GetConVarFloat(dieTime), RemoveGift, ent);
        } 
	}
}

//remove gift when timer is done
public Action:RemoveGift(Handle:timer, any:ent) { 
    if(IsValidEntity(ent)) {
		decl String:name[32];
		GetEntPropString(ent, Prop_Data, "m_iName", name, 128, 0);
		if(StrEqual(name, "giftbox%tak")) {
			AcceptEntityInput(ent, "Kill");
        } 
    } 
}

//this function is called and picks a random case as the random effect
public Action:StartTouch(entity, client) {
	if(Enabled) {
		if(IsValidClient(client)) {
			new getCvarTeam = GetConVarInt(teamMode);
			new getTeam = GetClientTeam(client);
			if(getCvarTeam == 1 || getCvarTeam == 2 && getTeam == 2 || getCvarTeam == 3 && getTeam == 3) {
				if(activeEffect[client] == false) {
					AcceptEntityInput(entity, "Kill");
					playerCookie[client]++;
					saveCookie(client);
					new goodCount, badCount, goodEffect, badEffect = 0;
					new bool:UpOrDown = false;
					if(CheckAdminFlag(client) == false) {
						if(GetRandomFloat(0.0, 1.0) <= GetConVarFloat(goodChance)) {
							goodEffect = GetRandomInt(0, sizeof(g_goodName)-1);
							UpOrDown = true;
						}
						else {
							badEffect = GetRandomInt(0, sizeof(g_badName)-1);
							UpOrDown = false;
						}
					}
					else if(CheckAdminFlag(client) == true) {
						if(GetRandomFloat(0.0, 1.0) <= GetConVarFloat(adminChance)) {
							goodEffect = GetRandomInt(0, sizeof(g_goodName)-1);
							UpOrDown = true;
						}
						else {
							badEffect = GetRandomInt(0, sizeof(g_badName)-1);
							UpOrDown = false;
						}
					}
					if(UpOrDown == true) {
						while(g_good[goodEffect] == 1) {
							goodEffect++;
							goodCount++;
							if(goodEffect == sizeof(g_goodName)) {
								goodEffect = 0;
							}
							if(goodCount == sizeof(g_goodName)) {
								goodEffect = sizeof(g_goodName);
							}
						}
						switch(goodEffect) {
							case 0: addMiniHealth(client, GetConVarInt(miniHP));
							case 1: knockBackPlayer(client);
							case 2: resizeHeadBig(client);
							case 3: resizeHeadSmall(client);
							case 4: SpeedMore(client);
							case 5: setAlpha(client, GetConVarInt(alphaCamo));
							case 6: draculaEnabled(client);
							case 7: SetGravity(client, GetConVarFloat(featherTouch));
							case 8: SpawnSentry(client);
							case 9: toggleBallsOfSteel(client);
							case 10: giveNade(client);
							case 11: toggleToxic(client);
							case 12: SpawnDispenser(client);
							case 13: toggleScary(client);
							case 14: togglePitfall(client);
							//case 15: toggleSuperjump(client);
							case 15: {
								//do nothing
							}
						}
					}
					else if(UpOrDown == false) {
						while(g_bad[badEffect] == 1) {
							badEffect++;
							badCount++;
							if(badEffect == sizeof(g_badName)) {
								badEffect = 0;
							}
							if(badCount == sizeof(g_badName)) {
								badEffect = sizeof(g_badName);
							}
						}
						switch(badEffect) {
							case 0: ForceTaunt(client);
							case 1: setFOV(client);
							case 2: SetNostalgia(client);
							case 3: addOneHP(client);
							case 4: toggleBrainDead(client);
							case 5: toggleInverse(client);
							case 6: toggleBlind(client);
							case 7: teleportToSpawn(client);
							case 8: shakePlayer(client);
							case 9: toggleSlowdown(client);
							case 10: toggleNoob(client);
							case 11: {
								//do nothing
							}
						}
					}
				}
			}
		}
	}
}

public Action:FakeTouch(entity, client) {
	if(Enabled) {
		if(IsValidClient(client)) {
			new getCvarTeam = GetConVarInt(teamMode);
			new getTeam = GetClientTeam(client);
			if(getCvarTeam == 1 || getCvarTeam == 2 && getTeam == 2 || getCvarTeam == 3 && getTeam == 3) {
				if(activeEffect[client] == false) {
					AcceptEntityInput(entity, "Kill");
					CPrintToChat(client, "%t", "Faked");
				}
			}
		}
	}
}

//bad but easier?
public OnGameFrame() {
	if(!Enabled) return;
	for(new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			if(headBig[i] == 1) {
				SetEntPropFloat(i, Prop_Send, "m_flHeadScale", 3.0);
				headSmall[i] = 0;
			}
			else if(headSmall[i] == 1) {
				SetEntPropFloat(i, Prop_Send, "m_flHeadScale", 0.2);
				headBig[i] = 0;
			}
			//unforunately sdkhook onweaponswitchpost/tf2attribute does not work properly
			else if(playerSteel[i] == 1) {
				SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", g_playerSpeed[i]*0.7);
			}
			else if(snail[i] == 1) {
				SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 30.0);
			}
			else if(moreFast[i] == 1) {
				SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 520.0);
			}
		}
	}
}

//sdkhook ontakedamage similar to onhurt event
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if(Enabled) {
		if((1 <= attacker <= MaxClients) && IsValidClient(attacker) && IsValidClient(victim) && IsValidEntity(weapon)) {
			//This will cause the attacker to do a knockback slap on victim
			//Rockets/pipes does a higher jump
			if(knockBack[attacker] == 1) {
				new Float:aang[3], Float:vvel[3], Float:pvec[3];
				GetClientAbsAngles(attacker, aang);
				GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vvel);
				
				if (attacker == victim) {
					vvel[2] += 1000.0;
				} 
				else {
					GetAngleVectors(aang, pvec, NULL_VECTOR, NULL_VECTOR);
					vvel[0] += pvec[0] * 300.0;
					vvel[1] += pvec[1] * 300.0;
					vvel[2] = 500.0;
				}
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vvel);
			}
			else if(draculaHeart[attacker] == 1) {
				SetEntProp(attacker, Prop_Send, "m_iHealth", GetClientHealth(attacker) + RoundToNearest(damage*GetConVarFloat(draculaHeal)));
			}
			else if(playerSteel[victim] == 1) {
				damage *= GetConVarFloat(ballsDefence);
			}
			else if(scaryBullets[attacker] == 1) {
				TF2_StunPlayer(victim, 1.0, 0.0, TF_STUNFLAGS_GHOSTSCARE, 0);
			}
			else if(isTaunting[victim] == 1) {
				//spread the infection
				ForceTaunt(attacker);
			}
			else if(pitFall[attacker] == 1) {
				if(playerIsBurried[victim] == 0) {
					buryPlayer(victim);
				}
			}
		}
	}
}

//hooks the listener to voice commands
public Action:VoiceListener(client, const String:command[], argc) {
	if(Enabled) {
		if(IsValidClient(client)) {
			decl String:arguments[32];
			GetCmdArgString(arguments, sizeof(arguments));
			//medic arguements is 0 0
			if(StrEqual(arguments, "0 0", false)) {
				if(sentrySpawn[client] == 1) {
					spawnSentry(client);
					sentrySpawn[client] = 0;
					removeCond(client, 6);
					activeEffect[client] = false;
					return Plugin_Handled;
				}
				else if(dispenserSpawn[client] == 1) {
					spawnDispenser(client);
					dispenserSpawn[client] = 0;
					removeCond(client, 6);
					activeEffect[client] = false;
					return Plugin_Handled;
				}
				else if(hasNade[client] == 1) {
					if(NadeCounter[client] == 1) {
						ThrowNade(client);
						NadeCounter[client] = 0;
						activeEffect[client] = false;
						removeCond(client, 6);
					}
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

/* ----------------------------------------------------
	Stock functions effects used and is called by client methods
  -----------------------------------------------------
 */
	
//method that prints out chats stuff
stock PrintResponse(client, i) {
	switch(i) {
		case 0: CPrintToChat(client, "%t", "MiniHP", GetConVarInt(resetMiniCritsTimer));
		case 1: CPrintToChat(client, "%t", "DanceFever");
		case 2: CPrintToChat(client, "%t", "Knockers", GetConVarInt(resetKnockTimer));
		case 3: CPrintToChat(client, "%t", "BigHead", GetConVarInt(resetBHeadTimer));
		case 4: CPrintToChat(client, "%t", "SmallHead", GetConVarInt(resetSHeadTimer));
		case 5: CPrintToChat(client, "%t", "Hyper", GetConVarInt(resetSpeedTimer));
		case 6: CPrintToChat(client, "%t", "Camo", GetConVarInt(resetAlphaTimer));
		case 7: CPrintToChat(client, "%t", "Funny");
		case 8: CPrintToChat(client, "%t", "Dracula", GetConVarInt(resetDraculaTimer));
		case 9: CPrintToChat(client, "%t", "Feather", GetConVarInt(resetGravityTimer));
		case 10: CPrintToChat(client, "%t", "Nostalgia", GetConVarInt(resetNostalgiaTimer));
		case 11: CPrintToChat(client, "%t", "Sentry", GetConVarInt(resetSentryTimer));
		case 12: CPrintToChat(client, "%t", "OneHP");
		case 13: CPrintToChat(client, "%t", "BrainDead", GetConVarInt(resetBrainTimer));
		case 14: CPrintToChat(client, "%t", "BallsOfSteel", GetConVarInt(resetSteelTimer));
		case 15: CPrintToChat(client, "%t", "Inverse", GetConVarInt(resetInverseTimer));
		case 16: CPrintToChat(client, "%t", "Blind", GetConVarInt(resetBlindTimer));
		case 17: CPrintToChat(client, "%t", "Teleport");
		case 18: CPrintToChat(client, "%t", "Grenade");
		case 19: CPrintToChat(client, "%t", "Earthquake", GetConVarInt(resetShakeTimer));
		case 20: CPrintToChat(client, "%t", "Snail", GetConVarInt(resetSnailTimer));
		case 21: CPrintToChat(client, "%t", "Toxic", GetConVarInt(resetToxicTimer));
		case 22: CPrintToChat(client, "%t", "Noob", GetConVarInt(resetNoobTimer));
		case 23: CPrintToChat(client, "%t", "Dispenser");
		case 24: CPrintToChat(client, "%t", "Scary", GetConVarInt(resetScaryTimer));
		case 25: CPrintToChat(client, "%t", "Pitfall", GetConVarInt(resetPitfallTimer));
		//case 26: CPrintToChat(client, "%t", "Superjump", GetConVarInt(resetSuperjumpTimer));
	}
}

 //This method is used to add health to the desired player and set up minicrits
stock addMiniHealth(client, health) {
	MiniCrits[client] = 1;
	addCond(client, 31, -1.0);
	SetEntProp(client, Prop_Send, "m_iHealth", GetClientHealth(client) + health);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetMiniCritsTimer), resetMiniCrits, GetClientUserId(client));
	activeEffect[client] = true;
	PrintResponse(client, 0);
	countDown(client, GetConVarInt(resetMiniCritsTimer));
}

//resets minicrits when timer is called
public Action:resetMiniCrits(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		MiniCrits[client] = 0;
		removeCond(client, 31);
		activeEffect[client] = false;
		clientTimer[client] = INVALID_HANDLE;
	}
}

//This method is used to force a fake taunt command to player
stock ForceTaunt(client) {
	if(tauntcounter == 0) {
		PrintResponse(client, 1);
		tauntcounter = 1;
	}
	if(GetEntityFlags(client) & FL_ONGROUND) {
		FakeClientCommand(client, "taunt");
		isTaunting[client] = 1;
		addCond(client, 6, -1.0);
	}
	else {
		CreateTimer(0.1, tauntDetect, GetClientUserId(client));
	}
}

//call back timer for fake taunt method
//makes sure the players taunt when they land back down
public Action:tauntDetect(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		ForceTaunt(client);
	}
}

//stock to enable knockback effect
stock knockBackPlayer(client) {
	knockBack[client] = 1;
	clientTimer[client] = CreateTimer(GetConVarFloat(resetKnockTimer), resetKnockback, GetClientUserId(client));
	PrintResponse(client, 2);
	activeEffect[client] = true;
	countDown(client, GetConVarInt(resetKnockTimer));
	addCond(client, 6, -1.0);
}

//resets the knockback after a few seconds with 
public Action:resetKnockback(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(knockBack[client] == 1) {
		knockBack[client] = 0;
		activeEffect[client] = false;
		removeCond(client, 6);
		clientTimer[client] = INVALID_HANDLE;
	}
}

//sets the player size head
stock resizeHeadBig(client) {
	headBig[client] = 1;
	clientTimer[client] = CreateTimer(GetConVarFloat(resetBHeadTimer), resetBHead, GetClientUserId(client));
	PrintResponse(client, 3);
	activeEffect[client] = true;
	countDown(client, GetConVarInt(resetBHeadTimer));
	addCond(client, 6, -1.0);
	SetVariantInt(1);
}

//timer resets big head
public Action:resetBHead(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(headBig[client] == 1) {
			headBig[client] = 0;
			activeEffect[client] = false;
			removeCond(client, 6);
			SetVariantInt(0);
			clientTimer[client] = INVALID_HANDLE;
		}
	}
}

//sets the player size head
stock resizeHeadSmall(client) {
	headSmall[client] = 1;
	clientTimer[client] = CreateTimer(GetConVarFloat(resetSHeadTimer), resetSHead, GetClientUserId(client));
	PrintResponse(client, 4);
	activeEffect[client] = true;
	countDown(client, GetConVarInt(resetSHeadTimer));
	addCond(client, 6, -1.0);
	SetVariantInt(1);
}

public Action:resetSHead(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(headSmall[client] == 1) {
			headSmall[client] = 0;
			activeEffect[client] = false;
			removeCond(client, 6);
			SetVariantInt(0);
			clientTimer[client] = INVALID_HANDLE;
		}
	}
}

//sets the player speed
stock SpeedMore(client) {
	g_playerSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	moreFast[client] = 1;
	addCond(client, 6, -1.0);
	addCond(client, 32, -1.0);
	PrintResponse(client, 5);
	activeEffect[client] = true;
	countDown(client, GetConVarInt(resetSpeedTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetSpeedTimer), resetSpeed, GetClientUserId(client));
}

//resets speed
public Action:resetSpeed(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		moreFast[client] = 0;
		removeCond(client, 6);
		removeCond(client, 32);
		ResetPlayerSpeed(client);
		activeEffect[client] = false;
		clientTimer[client] = INVALID_HANDLE;
	}
}

//set the players alpha to a fade
stock setAlpha(client, alpha) {
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
	SetEntityRenderColor(client, _, _, _, alpha);
	new hat = -1;
	while((hat = FindEntityByClassname(hat, "tf_wearable")) != -1) {
		if(IsValidEntity(hat)) {
			if(GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client) {
				SetEntityRenderMode(hat, RENDER_TRANSALPHA);
				SetEntityRenderColor(hat, _, _, _, alpha);
			}
		}
	}
	for(new i=0; i<5; i++) {
		new weapon = GetPlayerWeaponSlot(client, i);
		if(weapon > MaxClients && IsValidEntity(weapon)) {
			SetEntityRenderMode(weapon, RENDER_TRANSALPHA);
			SetEntityRenderColor(weapon, _, _, _, alpha);
		}
	}
	new removeCan = -1;
	while((removeCan = FindEntityByClassname(removeCan, "tf_powerup_bottle")) != -1) {
		new i = GetEntPropEnt(removeCan, Prop_Send, "m_hOwnerEntity");
		if(i == client) {
			SetEntityRenderMode(removeCan, RENDER_TRANSALPHA);
			SetEntityRenderColor(removeCan, _, _, _, alpha);
		}
	}
	isAlpha[client] = true;
	clientTimer[client] = CreateTimer(GetConVarFloat(resetAlphaTimer), resetAlpha, GetClientUserId(client));
	PrintResponse(client, 6);
	activeEffect[client] = true;
	countDown(client, GetConVarInt(resetAlphaTimer));
}

//timer reset for alpha color
public Action:resetAlpha(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(isAlpha[client] == true) {
			removeAlpha(client, 255);
			activeEffect[client] = false;
			clientTimer[client] = INVALID_HANDLE;
		}
	}
}

//return alpha back to normal
stock removeAlpha(client, alpha) {
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, _, _, _, alpha);
	new hat = -1;
	while((hat = FindEntityByClassname(hat, "tf_wearable")) != -1) {
		if(IsValidEntity(hat)) {
			if(GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client) {
				SetEntityRenderMode(hat, RENDER_NORMAL);
				SetEntityRenderColor(hat, _, _, _, alpha);
			}
		}
	}
	for(new i=0; i<5; i++) {
		new weapon = GetPlayerWeaponSlot(client, i);
		if(weapon > MaxClients && IsValidEntity(weapon)) {
			SetEntityRenderMode(weapon, RENDER_NORMAL);
			SetEntityRenderColor(weapon, _, _, _, alpha);
		}
	}
	new removeCan = -1;
	while((removeCan = FindEntityByClassname(removeCan, "tf_powerup_bottle")) != -1) {
		new i = GetEntPropEnt(removeCan, Prop_Send, "m_hOwnerEntity");
		if(i == client) {
			SetEntityRenderMode(removeCan, RENDER_NORMAL);
			SetEntityRenderColor(removeCan, _, _, _, alpha);
		}
	}
	isAlpha[client] = false;
}

//sets the FOB to the convar and creates another timer that normalizes it back to normal fov
stock setFOV(client) {
	SetEntProp(client, Prop_Send, "m_iFOV", GetConVarInt(funnyFeeling));
	clientTimer[client] = CreateTimer(0.5, normalize, GetClientUserId(client));
	PrintResponse(client, 7);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
}

//normalize the FOV back to it's original state
public Action:normalize(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		new current = GetEntProp(client, Prop_Send, "m_iFOV");
		new exact = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
		if(exact < current) {
			SetEntProp(client, Prop_Send, "m_iFOV", current - 1);
			clientTimer[client] = CreateTimer(0.5, normalize, GetClientUserId(client));
		}
		else if(exact > current) {
			SetEntProp(client, Prop_Send, "m_iFOV", current + 1);
			clientTimer[client] = CreateTimer(0.5, normalize, GetClientUserId(client));
		}
		else if(exact == current) {
			SetEntProp(client, Prop_Send, "m_iFOV", exact);
			activeEffect[client] = false;
			removeCond(client, 6);
			clientTimer[client] = INVALID_HANDLE;
		}
	}
}

//enables dracula's heart
stock draculaEnabled(client) {
	draculaHeart[client] = 1;
	clientTimer[client] = CreateTimer(GetConVarFloat(resetDraculaTimer), resetDracula, GetClientUserId(client));
	PrintResponse(client, 8);
	activeEffect[client] = true;
	countDown(client, GetConVarInt(resetDraculaTimer));
	addCond(client, 6, -1.0);
}

//timer callback to disable dracula effect when timer is done
public Action:resetDracula(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(draculaHeart[client] == 1) {
			draculaHeart[client] = 0;
			activeEffect[client] = false;
			removeCond(client, 6);
			clientTimer[client] = INVALID_HANDLE;
		}
	}
}

//sets player gravity
stock SetGravity(client, Float:grav) {
	SetEntityGravity(client, grav);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetGravityTimer), resetGravity, GetClientUserId(client));
	PrintResponse(client, 9);
	activeEffect[client] = true;
	countDown(client, GetConVarInt(resetGravityTimer));
	addCond(client, 6, -1.0);
}

//resets gravity when timer is called
public Action:resetGravity(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		SetEntityGravity(client, 1.0);
		activeEffect[client] = false;
		removeCond(client, 6);
		clientTimer[client] = INVALID_HANDLE;
	}
}

//sets nostalgia on player
stock SetNostalgia(client) {
	setOverlay("debug/yuv", client);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetNostalgiaTimer), resetNostalgia, GetClientUserId(client));
	PrintResponse(client, 10);
	activeEffect[client] = true;
	countDown(client, GetConVarInt(resetNostalgiaTimer));
	addCond(client, 6, -1.0);
}

//reset nostalgia effect when called
public Action:resetNostalgia(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		removeOverlay(client);
		activeEffect[client] = false;
		removeCond(client, 6);
		clientTimer[client] = INVALID_HANDLE;
	}
}

//spawns a sentry gun
stock SpawnSentry(client) {
	sentrySpawn[client] = 1;
	PrintResponse(client, 11);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
}

//sets client health to 1
stock addOneHP(client) {
	SetEntProp(client, Prop_Send, "m_iHealth", 1);
	PrintResponse(client, 12);
	addCond(client, 6, -1.0);
}

//toggles the brain dead effect on client
stock toggleBrainDead(client) {
	playerStunned[client] = 1;
	TF2_StunPlayer(client, GetConVarFloat(resetBrainTimer), 0.0, TF_STUNFLAGS_NORMALBONK, 0);
	countDown(client, GetConVarInt(resetBrainTimer));
	PrintResponse(client, 13);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	addCond(client, 50, -1.0);
}

//for brain dead reset
public TF2_OnConditionRemoved(client, TFCond:condition) {
	if(!Enabled && !IsValidClient(client)) return;
	if(playerStunned[client] == 1) {
		activeEffect[client] = false;
		removeCond(client, 6);
		removeCond(client, 50);
		playerStunned[client] = 0;
	}
	if(condition == TFCond_Taunting) {
		tauntcounter = 0;
		isTaunting[client] = 0;
		removeCond(client, 6);
	}
}

stock toggleBallsOfSteel(client) {
	g_playerSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	playerSteel[client] = 1;
	PrintResponse(client, 14);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	countDown(client, GetConVarInt(resetSteelTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetSteelTimer), resetSteel, GetClientUserId(client));
}

public Action:resetSteel(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		playerSteel[client] = 0;
		activeEffect[client] = false;
		removeCond(client, 6);
		ResetPlayerSpeed(client);
		clientTimer[client] = INVALID_HANDLE;
	}
}

stock toggleInverse(client) {
	Reverse(client);
	PrintResponse(client, 15);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	countDown(client, GetConVarInt(resetInverseTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetInverseTimer), resetInverse, GetClientUserId(client));
}

public Action:resetInverse(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		Reverse(client);
		activeEffect[client] = false;
		removeCond(client, 6);
		clientTimer[client] = INVALID_HANDLE;
	}
}

stock toggleBlind(client) {
	BlindPlayer(client, GetConVarInt(blindEffect));
	PrintResponse(client, 16);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	countDown(client, GetConVarInt(resetBlindTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetBlindTimer), resetBlind, GetClientUserId(client));
}

public Action:resetBlind(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		BlindPlayer(client, 0);
		activeEffect[client] = false;
		removeCond(client, 6);
		clientTimer[client] = INVALID_HANDLE;
	}
}

//credit to rtd
stock BlindPlayer(client, iAmount) {
	new iTargets[2];
	iTargets[0] = client;
	new UserMsg:g_FadeUserMsgId = GetUserMessageId("Fade");
	new Handle:message = StartMessageEx(g_FadeUserMsgId, iTargets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if(iAmount == 0) {
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else {
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, iAmount);
	
	EndMessage();
}

stock teleportToSpawn(client) {
	new Float:pos[3];
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "info_player_teamspawn")) != -1) {
		if(IsValidEntity(ent)) {
			new disabled = GetEntProp(ent, Prop_Data, "m_bDisabled");
			if(disabled == 0) {
				new team = GetEntProp(ent, Prop_Data, "m_iTeamNum");
				if(team == GetClientTeam(client)) {
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
					break;
				}
			}
		}
	}
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	PrintResponse(client, 17);
}

//gives a client a nade to throw at people :)
stock giveNade(client) {
	hasNade[client] = 1;
	PrintResponse(client, 18);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	NadeCounter[client] = 1;
}

//Throws the nade at player
stock ThrowNade(client) {
	new nade = CreateEntityByName("prop_physics_override");
	if (IsValidEntity(nade)) {
		SetEntPropEnt(nade, Prop_Data, "m_hOwnerEntity", client);
		SetEntityMoveType(nade, MOVETYPE_VPHYSICS);
		SetEntProp(nade, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(nade, Prop_Send, "m_usSolidFlags", 16);
		SetEntPropFloat(nade, Prop_Data, "m_flFriction", 10000.0);
		SetEntPropFloat(nade, Prop_Data, "m_massScale", 100.0);
		DispatchKeyValue(nade, "targetname", "tf2nade@tak");
		SetEntityModel(nade, MDL_NADE);
		DispatchSpawn(nade);
		
		new Float:pos[3], Float:ang[3], Float:vec[3], Float:svec[3], Float:pvec[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, ang);
		
		ang[1] += 2.0;
		pos[2] -= 20.0;
		GetAngleVectors(ang, vec, svec, NULL_VECTOR);
		ScaleVector(vec, 500.0);
		ScaleVector(svec, 30.0);
		AddVectors(pos, svec, pos);
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", pvec);
		AddVectors(pvec, vec, vec);
		TeleportEntity(nade, pos, ang, vec);
		
		nadeEntity[client] = nade;
		
		CreateTimer(3.5, ExplodeNade, GetClientUserId(client));
	}
}

public Action:ExplodeNade(Handle:hTimer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		new explode = CreateEntityByName("env_explosion");
		if(IsValidEntity(explode)) {
			if(IsValidEntity(nadeEntity[client])) {
				DispatchKeyValue(explode, "targetname", "explode");	
				DispatchKeyValue(explode, "spawnflags", "2");
				DispatchKeyValue(explode, "rendermode", "5");
				DispatchKeyValue(explode, "fireballsprite", spirite);
				
				SetEntPropEnt(explode, Prop_Data, "m_hOwnerEntity", client);
				SetEntProp(explode, Prop_Data, "m_iMagnitude", GetConVarInt(nadeDamage));
				SetEntProp(explode, Prop_Data, "m_iRadiusOverride", 200);
				
				new Float:pos[3];
				GetEntPropVector(nadeEntity[client], Prop_Send, "m_vecOrigin", pos);
				TeleportEntity(explode, pos, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(explode);
				ActivateEntity(explode);	
				AcceptEntityInput(explode, "Explode");
				AcceptEntityInput(explode, "Kill");
				AcceptEntityInput(nadeEntity[client], "Kill");
			}
		}
	}
}

stock shakePlayer(client) {
	canShake[client] = 1;
	PrintResponse(client, 19);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	CreateTimer(0.25, repeatShake, GetClientUserId(client));
	countDown(client, GetConVarInt(resetShakeTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetShakeTimer), resetShake, GetClientUserId(client));
}

public Action:repeatShake(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(canShake[client] == 1) {
			EarthQuakeEffect(client);
			CreateTimer(0.25, repeatShake, GetClientUserId(client));
		}
	}
}

public Action:resetShake(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		canShake[client] = 0;
		activeEffect[client] = false;
		removeCond(client, 6);
		clientTimer[client] = INVALID_HANDLE;
	}
}

stock toggleSlowdown(client) {
	g_playerSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	snail[client] = 1;
	PrintResponse(client, 20);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	countDown(client, GetConVarInt(resetSnailTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetSnailTimer), resetSnail, GetClientUserId(client));
}

public Action:resetSnail(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		snail[client] = 0;
		removeCond(client, 6);
		ResetPlayerSpeed(client);
		activeEffect[client] = false;
		clientTimer[client] = INVALID_HANDLE;
	}
}

stock toggleToxic(client) {
	toxicOn[client] = 1;
	PrintResponse(client, 21);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	addCond(client, 24, -1.0);
	countDown(client, GetConVarInt(resetToxicTimer));
	CreateTimer(1.0, repeatToxic, GetClientUserId(client));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetToxicTimer), resetToxic, GetClientUserId(client));
}

public Action:resetToxic(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		toxicOn[client] = 0;
		removeCond(client, 6);
		removeCond(client, 24);
		activeEffect[client] = false;
		clientTimer[client] = INVALID_HANDLE;
	}
}

public Action:repeatToxic(Handle:timer, any:userID) {
	new i = GetClientOfUserId(userID);
	if(IsValidClient(i)) {
		if(toxicOn[i] == 1) {
			for(new j = 1; j <= MaxClients; j++) {
				if(i != j) {
					if(IsValidClient(j)) {
						new Float:ipos[3], Float:jpos[3];
						GetClientAbsOrigin(i, ipos);
						GetClientAbsOrigin(j, jpos);
						new Float:distance = GetVectorDistance(ipos, jpos);
						if(distance <= GetConVarInt(toxicRadius)) {
							SDKHooks_TakeDamage(j, 0, i, GetConVarFloat(toxicDamage), DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB);
						}
					}
				}
			}
			CreateTimer(1.0, repeatToxic, GetClientUserId(i));
		}
	}
}

stock toggleNoob(client) {
	SetEntityRenderColor(client, 0, 0, 0, _);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
	PrintResponse(client, 22);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	countDown(client, GetConVarInt(resetNoobTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetNoobTimer), resetNoob, GetClientUserId(client));
}

public Action:resetNoob(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		SetEntityRenderColor(client, 255, 255, 255, _);
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		removeCond(client, 6);
		activeEffect[client] = false;
		clientTimer[client] = INVALID_HANDLE;
	}
}

stock SpawnDispenser(client) {
	dispenserSpawn[client] = 1;
	PrintResponse(client, 23);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
}

stock toggleScary(client) {
	scaryBullets[client] = 1;
	PrintResponse(client, 24);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	countDown(client, GetConVarInt(resetScaryTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetScaryTimer), resetScary, GetClientUserId(client));
}

public Action:resetScary(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		scaryBullets[client] = 0;
		removeCond(client, 6);
		activeEffect[client] = false;
		clientTimer[client] = INVALID_HANDLE;
	}
}

stock togglePitfall(client) {
	pitFall[client] = 1;
	PrintResponse(client, 25);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	countDown(client, GetConVarInt(resetPitfallTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetPitfallTimer), resetPitfall, GetClientUserId(client));
}

stock buryPlayer(client) {
	if(GetEntityFlags(client) & FL_ONGROUND) {
		SetEntityGravity(client, 10.0);
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] -= 50;
		TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientAbsOrigin(client, savePos[client]);
		playerIsBurried[client] = 1;
		CreateTimer(GetConVarFloat(PitfallEffect), unBuryPlayer, GetClientUserId(client));
	}
	else {
		CreateTimer(0.1, groundChecker, GetClientUserId(client));
	}
}

public Action:groundChecker(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		buryPlayer(client);
	}
}

public Action:unBuryPlayer(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		new Float:currentPos[3];
		GetClientAbsOrigin(client, currentPos);
		if(GetVectorDistance(currentPos, savePos[client]) == 0) {
			currentPos[2] += 50;
			TeleportEntity(client, currentPos, NULL_VECTOR, NULL_VECTOR);
			SetEntityGravity(client, 1.0);
			playerIsBurried[client] = 0;
		}
	}
}

public Action:resetPitfall(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		pitFall[client] = 0;
		removeCond(client, 6);
		activeEffect[client] = false;
		clientTimer[client] = INVALID_HANDLE;
	}
}

/*
stock toggleSuperjump(client) {
	addAttribute(client, "increased jump height", GetConVarFloat(jumpHeight));
	PrintResponse(client, 26);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	countDown(client, GetConVarInt(resetSuperjumpTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetSuperjumpTimer), resetSuperjump, GetClientUserId(client));
}

public Action:resetSuperjump(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		removeAttribute(client, "increased jump height");
		removeCond(client, 6);
		activeEffect[client] = false;
		clientTimer[client] = INVALID_HANDLE;
	}
}*/


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //addCond method
stock addCond(client, condition, Float:duration) {
	if(IsValidClient(client)) {
		TF2_AddCondition(client, TFCond:condition, duration);
	}
}

//removecond method
stock removeCond(client, condition) {
	if(IsValidClient(client)) {
		TF2_RemoveCondition(client, TFCond:condition);
	}
}

//timer hinttext counter
//--------------------------------------------------------------------------------------------
stock countDown(client, time) {
	PrintHintText(client, "Duration: %d", time);
	StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
	g_timeLeft[client] = time;
	CreateTimer(1.0, Timer_Countdown, GetClientUserId(client));
}

public Action:Timer_Countdown(Handle:hTimer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(g_timeLeft[client] > 0 ) {
			g_timeLeft[client]--;
			PrintHintText(client, "Duration: %d", g_timeLeft[client]);
			//blocks the annoying tick sound
			StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
			CreateTimer(1.0, Timer_Countdown, GetClientUserId(client));
		}
		else {
			PrintHintText(client, "		");
			PrintHintText(client, "");
			StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

//--------------------------------------------------------------------------------------------

//emit sounds at the location
stock EmitSoundClient(String:sound[], client) {
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	EmitAmbientSound(sound, pos, client);
}

//creates a particle at the location of positon
stock Handle:CreateParticle(String:type[], Float:time, entity, attach=0, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0) {
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(particle)) {
		new Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);

		if(attach != 0) {
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);
		
			if(attach == 2) {
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}
		DispatchKeyValue(particle, "targetname", "part%dp@tak");

		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		return CreateTimer(time, DeleteParticle, particle);
	} 
	else {
		LogError("Presents (CreateParticle): Could not create info_particle_system");
	}
	return INVALID_HANDLE;
}

//delete the particle that was created from the method before after a few seconds
public Action:DeleteParticle(Handle:timer, any:particle) {
	if(IsValidEntity(particle)) {
		decl String:name[32];
		GetEntPropString(particle, Prop_Data, "m_iName", name, 128, 0);
		//makes sure i don't kill off the wrong particle
		if(StrEqual(name, "part%dp@tak")) {
			AcceptEntityInput(particle, "Kill");
		}
	}
}

//sets the overlay of a client
stock setOverlay(String:overlay[], client) {
	ClientCommand(client, "r_screenoverlay \"%s.vtf\"", overlay);
}

//remove the overlay from client
stock removeOverlay(client) {
	ClientCommand(client, "r_screenoverlay \"\"");
}

//spawn a sentry gun at the clients location
stock spawnSentry(client) {
	if(!SetTeleportEndPoint(client)) PrintToChat(client, "%t", "Spawn");
	new iLevel = GetConVarInt(sentryLevel);
	new iShells, iHealth, iRockets;
	switch (iLevel) {
		case 1: {
			iShells = 100;
			iHealth = 150;
		}
		case 2: {
			iShells = 120;
			iHealth = 180;
		}
		case 3: {
			iShells = 144;
			iHealth = 216;
			iRockets = 20;
		}
	}
	decl String:sShells[3],String:sHealth[3],String:sRockets[3],String:sLevel[3];
	IntToString(iShells, sShells, sizeof(sShells));
	IntToString(iHealth, sHealth, sizeof(sHealth));
	IntToString(iRockets, sRockets, sizeof(sRockets));
	IntToString(iLevel, sLevel, sizeof(sLevel));
	sentry[client] = CreateEntityByName("obj_sentrygun");
	if(IsValidEntity(sentry[client])) {
		if(GetClientTeam(client) == 3) {
			DispatchKeyValue(sentry[client], "TeamNum", "3");
		}
		else if(GetClientTeam(client) == 2) {
			DispatchKeyValue(sentry[client], "TeamNum", "2");
		}
		DispatchKeyValue(sentry[client], "m_iHealth", sHealth);
		DispatchKeyValue(sentry[client], "m_iAmmoShells", sShells);
		DispatchKeyValue(sentry[client], "m_iUpgradeLevel", sLevel);
		if(iLevel == 3) DispatchKeyValue(sentry[client], "m_iAmmoRockets", sRockets);
		g_pos[2] -= 10.0;
		TeleportEntity(sentry[client], g_pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(sentry[client]);
		ActivateEntity(sentry[client]);
		SetEntPropEnt(sentry[client], Prop_Send, "m_hBuilder", client, 0);
		CreateTimer(GetConVarFloat(resetSentryTimer), removeSentry, GetClientUserId(client));
	}
}

stock spawnDispenser(client) {
	if(!SetTeleportEndPoint(client)) PrintToChat(client, "%t", "Spawn");
	new String:strModel[100];
	decl String:name[60];
	GetClientName(client,name,sizeof(name));
	new iTeam = GetClientTeam(client);
	new iHealth;
	new iAmmo = 400;
	new iLevel = GetConVarInt(dLevel);
	switch(iLevel) {
		case 1:	{
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser.mdl");
			iHealth = 150;
		}
		case 2: {
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl2.mdl");
			iHealth = 180;
		}
		case 3:{
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl3.mdl");
			iHealth = 216;
		}
	}
	
	new iDispenser = CreateEntityByName("obj_dispenser");
	if(iDispenser > MaxClients && IsValidEntity(iDispenser)) {
		SetVariantInt(iTeam);
		AcceptEntityInput(iDispenser, "TeamNum");
		SetVariantInt(iTeam);
		AcceptEntityInput(iDispenser, "SetTeam");
		SetEntityModel(iDispenser, strModel);
		DispatchSpawn(iDispenser);
		TeleportEntity(iDispenser, g_pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(iDispenser);
		
		SetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal", iAmmo);
		SetEntProp(iDispenser, Prop_Send, "m_iHealth", iHealth);
		SetEntProp(iDispenser, Prop_Send, "m_iMaxHealth", iHealth);
		SetEntProp(iDispenser, Prop_Send, "m_iObjectType", _:TFObject_Dispenser);
		SetEntProp(iDispenser, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(iDispenser, Prop_Send, "m_nSkin", iTeam-2);
		SetEntProp(iDispenser, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
		SetEntPropFloat(iDispenser, Prop_Send, "m_flPercentageConstructed", 1.0);
		SetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder", client);		
	}
}

SetTeleportEndPoint(client) {
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) {   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else {
		CloseHandle(trace);
		return false;
	}
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
	return entity > GetMaxClients() || !entity;
}

//remove sentry after a few seconds
public Action:removeSentry(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(IsValidEntity(sentry[client])) {
			SetVariantInt(1000); AcceptEntityInput(sentry[client], "RemoveHealth");
			activeEffect[client] = false;
		}
	}
}

stock Reverse(client) {
	new Float:ePos[3];
	if(isReversed[client]) {
		isReversed[client] = 0;
	}
	else {
		isReversed[client] = 1;
		GetClientEyeAngles(client, clientAngles[client]);
		GetClientEyePosition(client, ePos);
		new ent = CreateEntityByName("env_sprite");
		if(IsValidEntity(ent)) {
			DispatchKeyValue(ent, "model", "materials/sprites/dot.vmt");
			DispatchKeyValue(ent, "renderamt", "0");
			DispatchKeyValue(ent, "renderamt", "0");
			DispatchKeyValue(ent, "rendercolor", "0 0 0");
			DispatchSpawn(ent);
			TeleportEntity(client, NULL_VECTOR, Float:{0.0,0.0,0.0}, NULL_VECTOR);
			TeleportEntity(ent, ePos, Float:{0.0,0.0,0.0}, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(ent, "SetParent", client, ent, 0);
			TeleportEntity(client, NULL_VECTOR, clientAngles[client], NULL_VECTOR);

			SetClientViewEntity(client, ent);
		}
		g_sEnt[client] = ent;
		inverseTimer = CreateTimer(0.1, Timer_Roll, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_Roll(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if(IsValidEntity(g_sEnt[client])) {
		new Float:eAng[3];
		GetClientEyeAngles(client, g_Ang);
		//GetEntPropVector(g_sEnt[client], Prop_Send, "m_angRotation", eAng);
		if(isReversed[client]) {
			eAng[2] = 180.0;
			TeleportEntity(g_sEnt[client], NULL_VECTOR, eAng, NULL_VECTOR);
		}
		else {
			removeView(client);
			inverseTimer = INVALID_HANDLE;
		}
	}
	return Plugin_Continue;
}

stock removeView(client) {
	if(IsValidEntity(g_sEnt[client])) {
		g_Ang[2] = 0.0;
		SetClientViewEntity(client, client);
		TeleportEntity(client, NULL_VECTOR, g_Ang, NULL_VECTOR);
		isReversed[client] = 0;
		AcceptEntityInput(g_sEnt[client], "Kill");//predeath setup
	}
}

//taken from rtd, credits to pheadxdll
stock EarthQuakeEffect(client) {
	new iFlags = GetCommandFlags("shake") & (~FCVAR_CHEAT);
	SetCommandFlags("shake", iFlags);
	FakeClientCommand(client, "shake");
	iFlags = GetCommandFlags("shake") | (FCVAR_CHEAT);
	SetCommandFlags("shake", iFlags);
}

/*	
stock addAttribute(client, String:attribute[], Float:value) {
	if(IsValidClient(client)) {
		TF2Attrib_SetByName(client, attribute, value);
	}
}

stock removeAttribute(client, String:attribute[]) {
	if(IsValidClient(client)) {
		TF2Attrib_RemoveByName(client, attribute);
	}
}*/

//resets the effects to prevent multiple effects at once and/or on death
stock resetEffects(client) {
	ClearTimer(clientTimer[client]);
	ClearTimer(inverseTimer);
	headBig[client] = 0;
	headSmall[client] = 0;
	knockBack[client] = 0;
	ResetPlayerSpeed(client);
	draculaHeart[client] = 0;
	SetEntityGravity(client, 1.0);
	removeOverlay(client);
	SetEntProp(client, Prop_Send, "m_iFOV",  GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
	g_timeLeft[client] = 0;
	if(isAlpha[client] == true) removeAlpha(client, 255); //method sets isAlpha = false already
	sentrySpawn[client] = 0;
	playerStunned[client] = 0;
	playerSteel[client] = 0;
	hasNade[client] = 0;
	SetEntityRenderColor(client, 255, 255, 255, _);
	NadeCounter[client] = 0;
	nadeEntity[client] = 0;
	canShake[client] = 0;
	snail[client] = 0;
	moreFast[client] = 0;
	toxicOn[client] = 0;
	dispenserSpawn[client] = 0;
	scaryBullets[client] = 0;
	pitFall[client] = 0;
	playerIsBurried[client] = 0;
	removeView(client);
	activeEffect[client]  = false;
	removeCond(client, 32);
	removeCond(client, 6);
	//removeAttribute(client, "increased jump height");
}

stock ResetPlayerSpeed(client) {
	SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", g_playerSpeed[client]);
}

//taken and fixed from playpoints ability pack
stock LoadDisabledAbilities() {
	new String:disabled[258];
	GetConVarString(cvarDisabled, disabled, sizeof(disabled));
	for(new i = 0; i < sizeof(g_goodName); i++) {
		g_good[i] = 0;
		if(StrContains(disabled, g_goodName[i], false) != -1) {
			g_good[i] = 1;
		}
	}
	for(new i = 0; i < sizeof(g_badName); i++) {
		g_bad[i] = 0;
		if(StrContains(disabled, g_badName[i], false) != -1) {
			g_bad[i] = 1;
		}
	}
}

stock GetCookie(client) {
	if(IsValidClient(client)) {
		new String:cookie[PLATFORM_MAX_PATH];
		GetClientCookie(client, GiftCount, cookie, sizeof(cookie));
		playerCookie[client] = StringToInt(cookie);
	}
} 

stock saveCookie(client) {
	if(IsValidClient(client)) {
		new String:cookies[PLATFORM_MAX_PATH];
		IntToString(playerCookie[client], cookies, sizeof(cookies));
		SetClientCookie(client, GiftCount, cookies);
	}
}

stock ClearTimer(&Handle:timer) {  
	if (timer != INVALID_HANDLE) {  
		KillTimer(timer);  
	}  
	timer = INVALID_HANDLE;  
}  

//taken from rtd credit to pheadxdll
stock bool:CheckAdminFlag(client) {
	decl String:strCvar[20];
	strCvar[0] = '\0';
	GetConVarString(adminFlag, strCvar, sizeof(strCvar));
	if(strlen(strCvar) > 0) {
		if(GetUserFlagBits(client) & (ReadFlagString(strCvar) | ADMFLAG_ROOT)) {
			return true;
		}
	}
	return false;
}

//isvalidclient check to make sure the client is not invalid
stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}