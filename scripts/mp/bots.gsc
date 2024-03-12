/*
	_bot
	Author: INeedGames
	Date: 06/19/2021
	The entry point and manager of the bots.
*/

#include maps\mp\gametypes\_globallogic_utils;
#include maps\mp\_utility;
#include common_scripts\utility;

/*
	Replace func stuff
*/
main()
{
	level.bw_version = "1.1.1";
	
	if ( getdvar( "bots_main" ) == "" )
	{
		setdvar( "bots_main", true );
	}
	
	if ( !getdvarint( "bots_main" ) )
	{
		return;
	}
	
	if ( !wait_for_builtins() )
	{
		println( "FATAL: NO BUILT-INS FOR BOTS" );
	}
	
	// fix bot grenade launcher usage
	BotBuiltinReplaceFunc( BotBuiltinGetFunction( "maps/mp/bots/_bot_combat", "bot_should_hip_fire" ), ::bot_should_hip_fire_replaced );
}

/*
	Entry point to the bots
*/
init()
{
	if ( !getdvarint( "bots_main" ) )
	{
		return;
	}
	
	if ( !wait_for_builtins() )
	{
		println( "FATAL: NO BUILT-INS FOR BOTS" );
	}
	
	if ( getdvar( "bots_main_GUIDs" ) == "" )
	{
		setdvar( "bots_main_GUIDs", "" ); // guids of players who will be given host powers, comma seperated
	}
	
	if ( getdvar( "bots_main_firstIsHost" ) == "" )
	{
		setdvar( "bots_main_firstIsHost", false ); // first play to connect is a host
	}
	
	if ( getdvar( "bots_main_kickBotsAtEnd" ) == "" )
	{
		setdvar( "bots_main_kickBotsAtEnd", false ); // kicks the bots at game end (dedis hang with bots on map rotate)
	}
	
	if ( getdvar( "bots_main_waitForHostTime" ) == "" )
	{
		setdvar( "bots_main_waitForHostTime", 10.0 ); // how long to wait to wait for the host player
	}
	
	if ( getdvar( "bots_manage_add" ) == "" )
	{
		setdvar( "bots_manage_add", 0 ); // amount of bots to add to the game
	}
	
	if ( getdvar( "bots_manage_fill" ) == "" )
	{
		setdvar( "bots_manage_fill", 0 ); // amount of bots to maintain
	}
	
	if ( getdvar( "bots_manage_fill_spec" ) == "" )
	{
		setdvar( "bots_manage_fill_spec", true ); // to count for fill if player is on spec team
	}
	
	if ( getdvar( "bots_manage_fill_mode" ) == "" )
	{
		setdvar( "bots_manage_fill_mode", 0 ); // fill mode, 0 adds everyone, 1 just bots, 2 maintains at maps, 3 is 2 with 1
	}
	
	if ( getdvar( "bots_manage_fill_kick" ) == "" )
	{
		setdvar( "bots_manage_fill_kick", false ); // kick bots if too many
	}
	
	if ( getdvar( "bots_skill" ) == "" ) // alias for bot_difficulty
	{
		setdvar( "bots_skill", "" );
	}
	
	if ( getdvar( "bots_team" ) == "" )
	{
		setdvar( "bots_team", "autoassign" ); // which team for bots to join
	}
	
	if ( getdvar( "bots_team_amount" ) == "" )
	{
		setdvar( "bots_team_amount", 0 ); // amount of bots on axis team
	}
	
	if ( getdvar( "bots_team_force" ) == "" )
	{
		setdvar( "bots_team_force", false ); // force bots on team
	}
	
	if ( getdvar( "bots_team_mode" ) == "" )
	{
		setdvar( "bots_team_mode", 0 ); // counts just bots when 1
	}
	
	if ( getdvar( "bots_loadout_rank" ) == "" ) // what rank the bots should be around, -1 is around the players, 0 is all random
	{
		setdvar( "bots_loadout_rank", -1 );
	}
	
	if ( getdvar( "bots_loadout_prestige" ) == "" ) // what pretige the bots will be, -1 is the players, -2 is random
	{
		setdvar( "bots_loadout_prestige", -1 );
	}
	
	if ( getdvar( "bots_play_nade" ) == "" )
	{
		setdvar( "bots_play_nade", true );
	}
	
	if ( getdvar( "bots_play_aim" ) == "" )
	{
		setdvar( "bots_play_aim", true );
	}
	
	if ( getdvar( "bots_play_jumpdrop" ) == "" ) // bots jump and dropshot
	{
		setdvar( "bots_play_jumpdrop", true );
	}
	
	if ( !isdefined( game[ "botWarfare" ] ) )
	{
		game[ "botWarfare" ] = true;
	}
	
	thread fixGamemodes();
	
	thread onPlayerConnect();
	
	thread handleBots();
}

/*
	Fixes gl usage
*/
bot_should_hip_fire_replaced()
{
	weapon = self getcurrentweapon();
	class = weaponclass( weapon );
	
	if ( class == "grenade" )
	{
		return 1;
	}
	
	func = BotBuiltinGetFunction( "maps/mp/bots/_bot_combat", "bot_should_hip_fire" );
	BotBuiltinDisableDetourOnce( func );
	return self [[ func ]]();
}

/*
	Adds sd to bot logic
*/
fixGamemodes()
{
	wait 0.25;
	
	if ( level.gametype == "sd" )
	{
		level.bot_gametype = ::bot_sd_think;
	}
}

/*
	Starts the threads for bots.
*/
handleBots()
{
	thread diffBots();
	thread teamBots();
	addBots();
	
	while ( !level.intermission )
	{
		wait 0.05;
	}
	
	setdvar( "bots_manage_add", getBotArray().size );
	
	if ( !getdvarint( "bots_main_kickBotsAtEnd" ) )
	{
		return;
	}
	
	bots = getBotArray();
	
	for ( i = 0; i < bots.size; i++ )
	{
		bot = bots[ i ];
		
		if ( isdefined( bot ) )
		{
			kick( bot getentitynumber() );
		}
	}
}

/*
	Handles the diff of the bots
*/
diffBots()
{
	for ( ;; )
	{
		wait 1.5;
		
		// we dont use 'bots_skill' so that we can still use the .menu dvar
		
		if ( getdvar( "bots_skill" ) != "" )
		{
			setdvar( "bot_difficulty", getdvar( "bots_skill" ) );
			setdvar( "bots_skill", "" );
		}
		
		bot_set_difficulty( getdvarint( "bot_difficulty" ) );
	}
}

/*
	Sets the difficulty of the bots
*/
bot_set_difficulty( difficulty )
{
	if ( difficulty == 3 )
	{
		setdvar( "bot_MinDeathTime", "250" );
		setdvar( "bot_MaxDeathTime", "500" );
		setdvar( "bot_MinFireTime", "100" );
		setdvar( "bot_MaxFireTime", "250" );
		setdvar( "bot_PitchUp", "-5" );
		setdvar( "bot_PitchDown", "10" );
		setdvar( "bot_Fov", "160" );
		setdvar( "bot_MinAdsTime", "3000" );
		setdvar( "bot_MaxAdsTime", "5000" );
		setdvar( "bot_MinCrouchTime", "100" );
		setdvar( "bot_MaxCrouchTime", "400" );
		setdvar( "bot_TargetLeadBias", "2" );
		setdvar( "bot_MinReactionTime", "40" );
		setdvar( "bot_MaxReactionTime", "70" );
		setdvar( "bot_StrafeChance", "1" );
		setdvar( "bot_MinStrafeTime", "3000" );
		setdvar( "bot_MaxStrafeTime", "6000" );
		setdvar( "scr_help_dist", "512" );
		setdvar( "bot_AllowGrenades", "1" );
		setdvar( "bot_MinGrenadeTime", "1500" );
		setdvar( "bot_MaxGrenadeTime", "4000" );
		setdvar( "bot_MeleeDist", "70" );
		setdvar( "bot_YawSpeed", "2" );
	}
	else if ( difficulty == 2 )
	{
		setdvar( "bot_MinDeathTime", "250" );
		setdvar( "bot_MaxDeathTime", "500" );
		setdvar( "bot_MinFireTime", "400" );
		setdvar( "bot_MaxFireTime", "600" );
		setdvar( "bot_PitchUp", "-5" );
		setdvar( "bot_PitchDown", "10" );
		setdvar( "bot_Fov", "100" );
		setdvar( "bot_MinAdsTime", "3000" );
		setdvar( "bot_MaxAdsTime", "5000" );
		setdvar( "bot_MinCrouchTime", "100" );
		setdvar( "bot_MaxCrouchTime", "400" );
		setdvar( "bot_TargetLeadBias", "2" );
		setdvar( "bot_MinReactionTime", "400" );
		setdvar( "bot_MaxReactionTime", "700" );
		setdvar( "bot_StrafeChance", "0.9" );
		setdvar( "bot_MinStrafeTime", "3000" );
		setdvar( "bot_MaxStrafeTime", "6000" );
		setdvar( "scr_help_dist", "384" );
		setdvar( "bot_AllowGrenades", "1" );
		setdvar( "bot_MinGrenadeTime", "1500" );
		setdvar( "bot_MaxGrenadeTime", "4000" );
		setdvar( "bot_MeleeDist", "70" );
		setdvar( "bot_YawSpeed", "1.4" );
	}
	else if ( difficulty == 0 )
	{
		setdvar( "bot_MinDeathTime", "1000" );
		setdvar( "bot_MaxDeathTime", "2000" );
		setdvar( "bot_MinFireTime", "900" );
		setdvar( "bot_MaxFireTime", "1000" );
		setdvar( "bot_PitchUp", "-20" );
		setdvar( "bot_PitchDown", "40" );
		setdvar( "bot_Fov", "50" );
		setdvar( "bot_MinAdsTime", "3000" );
		setdvar( "bot_MaxAdsTime", "5000" );
		setdvar( "bot_MinCrouchTime", "4000" );
		setdvar( "bot_MaxCrouchTime", "6000" );
		setdvar( "bot_TargetLeadBias", "8" );
		setdvar( "bot_MinReactionTime", "1200" );
		setdvar( "bot_MaxReactionTime", "1600" );
		setdvar( "bot_StrafeChance", "0.1" );
		setdvar( "bot_MinStrafeTime", "3000" );
		setdvar( "bot_MaxStrafeTime", "6000" );
		setdvar( "scr_help_dist", "256" );
		setdvar( "bot_AllowGrenades", "0" );
		setdvar( "bot_MeleeDist", "40" );
	}
	else
	{
		if ( difficulty != 1 )
		{
			return;
		}
		
		setdvar( "bot_MinDeathTime", "500" );
		setdvar( "bot_MaxDeathTime", "1000" );
		setdvar( "bot_MinFireTime", "600" );
		setdvar( "bot_MaxFireTime", "800" );
		setdvar( "bot_PitchUp", "-10" );
		setdvar( "bot_PitchDown", "20" );
		setdvar( "bot_Fov", "70" );
		setdvar( "bot_MinAdsTime", "3000" );
		setdvar( "bot_MaxAdsTime", "5000" );
		setdvar( "bot_MinCrouchTime", "2000" );
		setdvar( "bot_MaxCrouchTime", "4000" );
		setdvar( "bot_TargetLeadBias", "4" );
		setdvar( "bot_MinReactionTime", "600" );
		setdvar( "bot_MaxReactionTime", "800" );
		setdvar( "bot_StrafeChance", "0.6" );
		setdvar( "bot_MinStrafeTime", "3000" );
		setdvar( "bot_MaxStrafeTime", "6000" );
		setdvar( "scr_help_dist", "256" );
		setdvar( "bot_AllowGrenades", "1" );
		setdvar( "bot_MinGrenadeTime", "1500" );
		setdvar( "bot_MaxGrenadeTime", "4000" );
		setdvar( "bot_MeleeDist", "70" );
		setdvar( "bot_YawSpeed", "1.2" );
	}
	
	if ( level.gametype == "oic" && difficulty == 3 )
	{
		setdvar( "bot_MinReactionTime", "400" );
		setdvar( "bot_MaxReactionTime", "500" );
		setdvar( "bot_MinAdsTime", "1000" );
		setdvar( "bot_MaxAdsTime", "2000" );
	}
	
	if ( ( difficulty == 2 || difficulty == 3 ) && level.gametype == "oic" )
	{
		setdvar( "bot_Sprintdistance", "256" );
	}
	
	if ( !getdvarint( "bots_play_nade" ) )
	{
		setdvar( "bot_AllowGrenades",	"0"	);
	}
	
	if ( !getdvarint( "bots_play_aim" ) )
	{
		setdvar( "bot_YawSpeed", "0" );
		setdvar( "bot_PitchUp", "0" );
		setdvar( "bot_PitchDown", "0" );
	}
	
	setdvar( "bot_difficulty", difficulty );
	level.bot_difficulty = undefined;
	level maps\mp\bots\_bot::bot_get_difficulty();
}

/*
	A server thread for monitoring all bot's teams for custom server settings.
*/
teamBots_loop()
{
	teamAmount = getdvarint( "bots_team_amount" );
	toTeam = getdvar( "bots_team" );
	
	alliesbots = 0;
	alliesplayers = 0;
	axisbots = 0;
	axisplayers = 0;
	
	playercount = level.players.size;
	
	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[ i ];
		
		if ( isdefined( player ) && isdefined( player.team ) )
		{
			if ( player is_bot() )
			{
				if ( player.pers[ "team" ] == "allies" )
				{
					alliesbots++;
				}
				else if ( player.pers[ "team" ] == "axis" )
				{
					axisbots++;
				}
			}
			else
			{
				if ( player.pers[ "team" ] == "allies" )
				{
					alliesplayers++;
				}
				else if ( player.pers[ "team" ] == "axis" )
				{
					axisplayers++;
				}
			}
		}
	}
	
	allies = alliesbots;
	axis = axisbots;
	
	if ( !getdvarint( "bots_team_mode" ) )
	{
		allies += alliesplayers;
		axis += axisplayers;
	}
	
	if ( toTeam != "custom" )
	{
		if ( getdvarint( "bots_team_force" ) )
		{
			if ( toTeam == "autoassign" )
			{
				if ( abs( axis - allies ) > 1 )
				{
					toTeam = "axis";
					
					if ( axis > allies )
					{
						toTeam = "allies";
					}
				}
			}
			
			if ( toTeam != "autoassign" )
			{
				playercount = level.players.size;
				
				for ( i = 0; i < playercount; i++ )
				{
					player = level.players[ i ];
					
					if ( isdefined( player ) && isdefined( player.team ) && player is_bot() && ( player.pers[ "team" ] != toTeam ) )
					{
						if ( toTeam == "allies" )
						{
							player thread [[ level.teammenu ]]( "allies" );
						}
						else if ( toTeam == "axis" )
						{
							player thread [[ level.teammenu ]]( "axis" );
						}
						else
						{
							player thread [[ level.spectator ]]();
						}
						
						break;
					}
				}
			}
		}
	}
	else
	{
		playercount = level.players.size;
		
		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[ i ];
			
			if ( isdefined( player ) && isdefined( player.team ) && player is_bot() )
			{
				if ( player.pers[ "team" ] == "axis" )
				{
					if ( axis > teamAmount )
					{
						player thread [[ level.teammenu ]]( "allies" );
						break;
					}
				}
				else
				{
					if ( axis < teamAmount )
					{
						player thread [[ level.teammenu ]]( "axis" );
						break;
					}
					else if ( player.pers[ "team" ] != "allies" )
					{
						player thread [[ level.teammenu ]]( "allies" );
						break;
					}
				}
			}
		}
	}
}

/*
	A server thread for monitoring all bot's teams for custom server settings.
*/
teamBots()
{
	for ( ;; )
	{
		wait 1.5;
		teamBots_loop();
	}
}

/*
	Loop
*/
addBots_loop()
{
	botsToAdd = getdvarint( "bots_manage_add" );
	
	if ( botsToAdd > 0 )
	{
		setdvar( "bots_manage_add", 0 );
		
		if ( botsToAdd > 64 )
		{
			botsToAdd = 64;
		}
		
		for ( ; botsToAdd > 0; botsToAdd-- )
		{
			level add_bot();
			wait 0.5;
		}
	}
	
	fillMode = getdvarint( "bots_manage_fill_mode" );
	
	if ( fillMode == 2 || fillMode == 3 )
	{
		setdvar( "bots_manage_fill", getGoodMapAmount() );
	}
	
	fillAmount = getdvarint( "bots_manage_fill" );
	
	players = 0;
	bots = 0;
	spec = 0;
	
	playercount = level.players.size;
	
	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[ i ];
		
		if ( isdefined( player ) )
		{
			if ( player is_bot() )
			{
				bots++;
			}
			else if ( !isdefined( player.team ) || ( player.pers[ "team" ] != "axis" && player.pers[ "team" ] != "allies" ) )
			{
				spec++;
			}
			else
			{
				players++;
			}
		}
	}
	
	if ( fillMode == 4 )
	{
		axisplayers = 0;
		alliesplayers = 0;
		
		playercount = level.players.size;
		
		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[ i ];
			
			if ( isdefined( player ) && isdefined( player.team ) && !player is_bot() )
			{
				if ( player.pers[ "team" ] == "axis" )
				{
					axisplayers++;
				}
				else if ( player.pers[ "team" ] == "allies" )
				{
					alliesplayers++;
				}
			}
		}
		
		result = fillAmount - abs( axisplayers - alliesplayers ) + bots;
		
		if ( players == 0 )
		{
			if ( bots < fillAmount )
			{
				result = fillAmount - 1;
			}
			else if ( bots > fillAmount )
			{
				result = fillAmount + 1;
			}
			else
			{
				result = fillAmount;
			}
		}
		
		bots = result;
	}
	
	if ( !randomint( 999 ) )
	{
		setdvar( "testclients_doreload", true );
		wait 0.1;
		setdvar( "testclients_doreload", false );
		doExtraCheck();
	}
	
	amount = bots;
	
	if ( fillMode == 0 || fillMode == 2 )
	{
		amount += players;
	}
	
	if ( getdvarint( "bots_manage_fill_spec" ) )
	{
		amount += spec;
	}
	
	if ( amount < fillAmount )
	{
		setdvar( "bots_manage_add", 1 );
	}
	else if ( amount > fillAmount && getdvarint( "bots_manage_fill_kick" ) )
	{
		tempBot = getBotToKick();
		
		if ( isdefined( tempBot ) )
		{
			kick( tempBot getentitynumber() );
		}
	}
}

/*
	A server thread for monitoring all bot's in game. Will add and kick bots according to server settings.
*/
addBots()
{
	level endon ( "game_ended" );
	
	bot_wait_for_host();
	
	for ( ;; )
	{
		wait 1.5;
		
		addBots_loop();
	}
}

/*
	Adds a bot to the game.
*/
add_bot()
{
	bot = addtestclient();
	
	if ( isdefined( bot ) )
	{
		bot.pers[ "isBot" ] = true;
		bot.pers[ "isBotWarfare" ] = true;
		bot thread added();
	}
}

/*
	Player connects
*/
onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		
		player thread connected();
	}
}

/*
	Connects
*/
connected()
{
	self endon( "disconnect" );
	
	if ( !isdefined( self.pers ) || !isdefined( self.pers[ "bot_host" ] ) )
	{
		self thread doHostCheck();
	}
	
	if ( !self istestclient() )
	{
		return;
	}
	
	if ( !isdefined( self.pers[ "isBot" ] ) )
	{
		self.pers[ "isBot" ] = true;
	}
	
	if ( !isdefined( self.pers[ "isBotWarfare" ] ) )
	{
		self.pers[ "isBotWarfare" ] = true;
		self thread added();
	}
	
	self thread teamWatch();
	self thread classWatch();
	self thread onBotSpawned();
	
	self thread setranks();
	
	self thread watchBotDebugEvent();
}

/*
	DEBUG
*/
watchBotDebugEvent()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		self waittill( "bot_event", msg, str, b, c, d, e, f, g );
		
		if ( getdvarint( "bots_main_debug" ) >= 2 )
		{
			big_str = "Bot Warfare debug: " + self.name + ": " + msg;
			
			if ( isdefined( str ) && isstring( str ) )
			{
				big_str += ", " + str;
			}
			
			if ( isdefined( b ) && isstring( b ) )
			{
				big_str += ", " + b;
			}
			
			if ( isdefined( c ) && isstring( c ) )
			{
				big_str += ", " + c;
			}
			
			if ( isdefined( d ) && isstring( d ) )
			{
				big_str += ", " + d;
			}
			
			if ( isdefined( e ) && isstring( e ) )
			{
				big_str += ", " + e;
			}
			
			if ( isdefined( f ) && isstring( f ) )
			{
				big_str += ", " + f;
			}
			
			if ( isdefined( g ) && isstring( g ) )
			{
				big_str += ", " + g;
			}
			
			BotBuiltinPrintConsole( big_str );
		}
		else if ( msg == "debug" && getdvarint( "bots_main_debug" ) )
		{
			BotBuiltinPrintConsole( "Bot Warfare debug: " + self.name + ": " + str );
		}
	}
}

/*
	When the bot spawns
*/
onBotSpawned()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		self waittill( "spawned_player" );
		self BotBuiltinClearOverrides( true );
		self BotBuiltinWeaponOverride( self getcurrentweapon() );
		
		self thread watch_for_override_stuff();
		self thread watch_for_melee_override();
		self thread bot_watch_think_mw2();
		self BotNotifyBotEvent( "debug", "we spawned!" );
		
		waittillframeend;
		
		self.bot_first_spawn = undefined;
		
		if ( randomint( 100 ) < 2 )
		{
			self.bot_change_class = undefined;
		}
	}
}

/*
	Gets a GL
*/
getValidTube()
{
	weaps = self getweaponslist( true );
	
	for ( i = 0; i < weaps.size; i++ )
	{
		weap = weaps[ i ];
		
		if ( !self getammocount( weap ) )
		{
			continue;
		}
		
		if ( !isstrstart( weap, "gl_" ) )
		{
			continue;
		}
		
		return weap;
	}
	
	return undefined;
}

/*
	Bots play mw2
*/
bot_watch_think_mw2()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	for ( ;; )
	{
		wait randomintrange( 1, 4 );
		
		if ( self isremotecontrolling() )
		{
			continue;
		}
		
		if ( self maps\mp\bots\_bot_combat::bot_has_enemy() )
		{
			continue;
		}
		
		tube = self getValidTube();
		
		if ( !isdefined( tube ) )
		{
			if ( self getammocount( "usrpg_mp" ) )
			{
				tube = "usrpg_mp";
			}
			else if ( self getammocount( "smaw_mp" ) )
			{
				tube = "smaw_mp";
			}
			else
			{
				return;
			}
		}
		
		if ( self getcurrentweapon() == tube )
		{
			return;
		}
		
		if ( randomint( 100 ) > 35 )
		{
			return;
		}
		
		self switchtoweapon( tube );
	}
}

/*
	custom movement stuff
*/
watch_for_melee_override()
{
	self endon( "disconnect" );
	self endon( "death" );
	
	for ( ;; )
	{
		while ( ( !self maps\mp\bots\_bot_combat::threat_is_player() && !self maps\mp\bots\_bot_combat::threat_is_dog() ) || self isremotecontrolling() || !self hasweapon( "knife_mp" ) || !getdvarint( "aim_automelee_enabled" ) )
		{
			wait 0.05;
		}
		
		threat = self.bot.threat.entity;
		
		while ( isdefined( threat ) && isdefined( self.bot.threat.entity ) && self.bot.threat.entity == threat )
		{
			dist = distance( self.origin, threat.origin );
			
			if ( self isonground() && self getstance() != "prone" && dist < getdvarfloat( "aim_automelee_range" ) && ( getConeDot( threat.origin, self.origin, self getplayerangles() ) > 0.9 || dist < 10 ) )
			{
				self BotBuiltinBotMeleeParams( threat getentitynumber(), dist );
				self BotBuiltinButtonOverride( "melee", "enable" );
				self BotBuiltinAimOverride();
				
				time_left = 1;
				once = false;
				
				while ( time_left > 0 && isdefined( threat ) && isalive( threat ) )
				{
					self setplayerangles( vectortoangles( threat gettagorigin( "j_spine4" ) - self geteye() ) );
					time_left -= 0.05;
					wait 0.05;
					
					if ( !once )
					{
						once = true;
						self BotBuiltinClearButtonOverride( "melee" );
					}
				}
				
				if ( !once )
				{
					self BotBuiltinClearButtonOverride( "melee" );
				}
				
				self BotBuiltinClearMeleeParams();
				self BotBuiltinClearAimOverride();
				wait 1;
				break;
			}
			
			wait 0.05;
		}
	}
}

/*
	custom movement stuff
*/
watch_for_override_stuff()
{
	self endon( "disconnect" );
	self endon( "death" );
	
	NEAR_DIST = 80;
	LONG_DIST = 1000;
	SPAM_JUMP_TIME = 5000;
	
	diff = level maps\mp\bots\_bot::bot_get_difficulty();
	chance = 0;
	
	if ( diff == "normal" )
	{
		chance = 25;
	}
	else if ( diff == "hard" )
	{
		chance = 50;
	}
	else if ( diff == "fu" )
	{
		chance = 80;
	}
	
	last_jump_time = 0;
	
	if ( !getdvarint( "bots_play_jumpdrop" ) )
	{
		return;
	}
	
	for ( ;; )
	{
		while ( !self maps\mp\bots\_bot_combat::threat_is_player() || self isremotecontrolling() )
		{
			wait 0.05;
		}
		
		threat = self.bot.threat.entity;
		dist = distance( threat.origin, self.origin );
		time = gettime();
		weap = self getcurrentweapon();
		
		weapon_is_good = true;
		
		if ( weap == "none" || !self getweaponammoclip( weap ) )
		{
			weapon_is_good = false;
		}
		
		if ( weapon_is_good && ( dist > NEAR_DIST ) && ( dist < LONG_DIST ) && ( randomint( 100 ) < chance ) && ( ( time - last_jump_time ) > SPAM_JUMP_TIME ) )
		{
			if ( randomint( 2 ) )
			{
				if ( ( getConeDot( threat.origin, self.origin, self getplayerangles() ) > 0.8 ) && ( dist > ( NEAR_DIST * 2 ) ) )
				{
					last_jump_time = time;
					
					// drop shot
					self BotBuiltinMovementOverride( 0, 0 );
					self BotBuiltinButtonOverride( "prone", "enable" );
					
					wait 1.5;
					
					self BotBuiltinClearMovementOverride();
					self BotBuiltinClearButtonOverride( "prone" );
				}
			}
			else
			{
				last_jump_time = time;
				
				// jump shot
				self BotBuiltinButtonOverride( "gostand", "enable" );
				wait 0.1;
				self BotBuiltinClearButtonOverride( "gostand" );
			}
		}
		
		while ( isdefined( threat ) && isdefined( self.bot.threat.entity ) && ( threat == self.bot.threat.entity ) )
		{
			wait 0.05;
		}
	}
}

/*
	Set pres
*/
setranks()
{
	self endon( "disconnect" );
	
	wait 0.05;
	
	self setCustomRanks();
	
	if ( !level.gameended )
	{
		level waittill( "game_ended" );
	}
	
	self.pers[ "bot_rankxp" ] = self.pers[ "rankxp" ];
}

/*
	Sets the rank
*/
setCustomRanks()
{
	if ( !isdefined( self.pers[ "bot_prestige" ] ) )
	{
		return;
	}
	
	self.pers[ "prestige" ] = self.pers[ "bot_prestige" ];
	self.pers[ "plevel" ] = self.pers[ "bot_prestige" ];
	
	self.pers[ "rankxp" ] = self.pers[ "bot_rankxp" ];
	self.pers[ "rank" ] = self maps\mp\gametypes\_rank::getrankforxp( self.pers[ "rankxp" ] );
	
	self setrank( self.pers[ "rank" ], self.pers[ "prestige" ] );
	
	self maps\mp\gametypes\_rank::syncxpstat();
}

/*
	Makes sure the bot is on a team.
*/
teamWatch()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		while ( !isdefined( self.team ) || !allowTeamChoice() )
		{
			wait .05;
		}
		
		wait 0.1;
		
		// multiteam?
		if ( self.team != "axis" && self.team != "allies" )
		{
			self notify( "menuresponse", game[ "menu_team" ], getdvar( "bots_team" ) );
		}
		
		while ( isdefined( self.team ) )
		{
			wait .05;
		}
	}
}

/*
	Selects a class for the bot.
*/
classWatch()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		while ( !isdefined( self.team ) || !allowClassChoice() )
		{
			wait .05;
		}
		
		wait 0.5;
		
		if ( !maps\mp\gametypes\_globallogic_utils::isvalidclass( self.class ) || !isdefined( self.bot_change_class ) )
		{
			self notify( "menuresponse", game[ "menu_changeclass" ], self chooseRandomClass() );
		}
		
		self.bot_change_class = true;
		
		while ( isdefined( self.team ) && maps\mp\gametypes\_globallogic_utils::isvalidclass( self.class ) && isdefined( self.bot_change_class ) )
		{
			wait .05;
		}
	}
}

/*
	Chooses random class
*/
chooseRandomClass()
{
	if ( level.disablecac )
	{
		classes = [];
		classes[ classes.size ] = "class_assault";
		classes[ classes.size ] = "class_smg";
		classes[ classes.size ] = "class_lmg";
		classes[ classes.size ] = "class_cqb";
		classes[ classes.size ] = "class_sniper";
		return PickRandom( classes );
	}
	
	return PickRandom( self maps\mp\bots\_bot::bot_build_classes() );
}

/*
	Bot was added
*/
added()
{
	self endon( "disconnect" );
	
	self thread doCustomRank();
}

/*
	Gets the prestige
*/
bot_get_prestige()
{
	p_dvar = getdvarint( "bots_loadout_prestige" );
	p = 0;
	
	if ( p_dvar == -1 )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[ i ];
			
			if ( isdefined( player ) && isdefined( player.team ) && !player is_bot() )
			{
				p = player.pers[ "prestige" ];
			}
			
			break;
		}
	}
	else if ( p_dvar == -2 )
	{
		p = randomint( 12 );
	}
	else
	{
		p = p_dvar;
	}
	
	return p;
}

/*
	Bot custom ranks
*/
doCustomRank()
{
	self endon( "disconnect" );
	
	// prevent generating classes
	if ( getdvarint( "bots_loadout_rank" ) != -1 )
	{
		self.pers[ "bot_loadout" ] = true;
	}
	
	// wait for the original scripts to execute
	wait 0.25;
	
	// get rank
	rankxp = self.pers[ "rankxp" ];
	
	if ( getdvarint( "bots_loadout_rank" ) != -1 )
	{
		if ( getdvarint( "bots_loadout_rank" ) == 0 )
		{
			rankxp = maps\mp\gametypes\_rank::getrankinfominxp( randomint( level.maxrank + 1 ) );
		}
		else
		{
			rankxp = maps\mp\gametypes\_rank::getrankinfominxp( getdvarint( "bots_loadout_rank" ) );
		}
	}
	
	// apply
	self.pers[ "bot_prestige" ] = bot_get_prestige();
	self.pers[ "bot_rankxp" ] = rankxp;
	
	self setCustomRanks();
	
	// generate the custom classes
	if ( getdvarint( "bots_loadout_rank" ) != -1 )
	{
		self botsetdefaultclass( 5, "class_assault" );
		self botsetdefaultclass( 6, "class_smg" );
		self botsetdefaultclass( 7, "class_lmg" );
		self botsetdefaultclass( 8, "class_cqb" );
		self botsetdefaultclass( 9, "class_sniper" );
		
		self maps\mp\bots\_bot_loadout::bot_construct_loadout( 10 );
	}
}

/*
	Matches a num to a char
*/
keyCodeToString( a )
{
	b = "";
	
	switch ( a )
	{
		case 0:
			b = "a";
			break;
			
		case 1:
			b = "b";
			break;
			
		case 2:
			b = "c";
			break;
			
		case 3:
			b = "d";
			break;
			
		case 4:
			b = "e";
			break;
			
		case 5:
			b = "f";
			break;
			
		case 6:
			b = "g";
			break;
			
		case 7:
			b = "h";
			break;
			
		case 8:
			b = "i";
			break;
			
		case 9:
			b = "j";
			break;
			
		case 10:
			b = "k";
			break;
			
		case 11:
			b = "l";
			break;
			
		case 12:
			b = "m";
			break;
			
		case 13:
			b = "n";
			break;
			
		case 14:
			b = "o";
			break;
			
		case 15:
			b = "p";
			break;
			
		case 16:
			b = "q";
			break;
			
		case 17:
			b = "r";
			break;
			
		case 18:
			b = "s";
			break;
			
		case 19:
			b = "t";
			break;
			
		case 20:
			b = "u";
			break;
			
		case 21:
			b = "v";
			break;
			
		case 22:
			b = "w";
			break;
			
		case 23:
			b = "x";
			break;
			
		case 24:
			b = "y";
			break;
			
		case 25:
			b = "z";
			break;
			
		case 26:
			b = ".";
			break;
			
		case 27:
			b = " ";
			break;
	}
	
	return b;
}

/*
	Returns the cone dot (like fov, or distance from the center of our screen).
*/
getConeDot( to, from, dir )
{
	dirToTarget = vectornormalize( to - from );
	forward = anglestoforward( dir );
	return vectordot( dirToTarget, forward );
}

/*
	Waits for the built-ins to be defined
*/
wait_for_builtins()
{
	for ( i = 0; i < 20; i++ )
	{
		if ( isdefined( level.bot_builtins ) )
		{
			return true;
		}
		
		if ( i < 18 )
		{
			waittillframeend;
		}
		else
		{
			wait 0.05;
		}
	}
	
	return false;
}

/*
	Prints to console without dev script on
*/
BotBuiltinPrintConsole( s )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "printconsole" ] ) )
	{
		[[ level.bot_builtins[ "printconsole" ] ]]( s );
	}
	else
	{
		println( s );
	}
}

/*
*/
BotBuiltinMovementOverride( a, b )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botmovementoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botmovementoverride" ] ]]( a, b );
	}
}

/*
*/
BotBuiltinClearMovementOverride()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearmovementoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearmovementoverride" ] ]]();
	}
}

/*
*/
BotBuiltinClearButtonOverride( a )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearbuttonoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearbuttonoverride" ] ]]( a );
	}
}

/*
*/
BotBuiltinButtonOverride( a, b )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botbuttonoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botbuttonoverride" ] ]]( a, b );
	}
}

/*
*/
BotBuiltinClearOverrides( a )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearoverrides" ] ) )
	{
		self [[ level.bot_builtins[ "botclearoverrides" ] ]]( a );
	}
}

/*
*/
BotBuiltinClearWeaponOverride()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearweaponoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearweaponoverride" ] ]]();
	}
}

/*
*/
BotBuiltinWeaponOverride( a )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botweaponoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botweaponoverride" ] ]]( a );
	}
}

/*
*/
BotBuiltinClearButtonOverrides()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearbuttonoverrides" ] ) )
	{
		self [[ level.bot_builtins[ "botclearbuttonoverrides" ] ]]();
	}
}

/*
*/
BotBuiltinAimOverride()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botaimoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botaimoverride" ] ]]();
	}
}

/*
*/
BotBuiltinClearAimOverride()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearaimoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearaimoverride" ] ]]();
	}
}

/*
	Sets melee params
*/
BotBuiltinBotMeleeParams( entNum, dist )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botmeleeparams" ] ) )
	{
		self [[ level.bot_builtins[ "botmeleeparams" ] ]]( entNum, dist );
	}
}

/*
*/
BotBuiltinClearMeleeParams()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "clearbotmeleeparams" ] ) )
	{
		self [[ level.bot_builtins[ "clearbotmeleeparams" ] ]]();
	}
}

/*
*/
BotBuiltinReplaceFunc( a, b )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "replacefunc" ] ) )
	{
		return [[ level.bot_builtins[ "replacefunc" ] ]]( a, b );
	}
}

/*
*/
BotBuiltinGetFunction( a, b )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "getfunction" ] ) )
	{
		return [[ level.bot_builtins[ "getfunction" ] ]]( a, b );
	}
}

/*
*/
BotBuiltinDisableDetourOnce( a )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "disabledetouronce" ] ) )
	{
		[[ level.bot_builtins[ "disabledetouronce" ] ]]( a );
	}
}

/*
	iw5
*/
allowClassChoice()
{
	// check gungame?
	return true;
}

/*
	iw5
*/
allowTeamChoice()
{
	// check gungame?
	return true;
}

/*
	Waits till frame end so that if two notifies happen in the same frame, the other will not be missed.
*/
BotNotifyBotEvent_( msg, a, b, c, d, e, f, g )
{
	self endon( "disconnect" );
	waittillframeend; // wait for the waittills to setup again
	self notify( "bot_event", msg, a, b, c, d, e, f, g );
}

/*
	Notify the bot chat message
*/
BotNotifyBotEvent( msg, a, b, c, d, e, f, g )
{
	self thread BotNotifyBotEvent_( msg, a, b, c, d, e, f, g );
}

/*
	Returns if player is the host
*/
is_host()
{
	if ( !isdefined( self ) || !isdefined( self.pers ) )
	{
		return false;
	}
	
	return ( isdefined( self.pers[ "bot_host" ] ) && self.pers[ "bot_host" ] );
}

/*
	Setups the host variable on the player
*/
doHostCheck()
{
	self.pers[ "bot_host" ] = false;
	
	if ( self istestclient() )
	{
		return;
	}
	
	result = false;
	
	if ( getdvar( "bots_main_firstIsHost" ) != "0" )
	{
		BotBuiltinPrintConsole( "WARNING: bots_main_firstIsHost is enabled" );
		
		if ( getdvar( "bots_main_firstIsHost" ) == "1" )
		{
			setdvar( "bots_main_firstIsHost", self getguid() );
		}
		
		if ( getdvar( "bots_main_firstIsHost" ) == self getguid() + "" )
		{
			result = true;
		}
	}
	
	DvarGUID = getdvar( "bots_main_GUIDs" );
	
	if ( DvarGUID != "" )
	{
		guids = strtok( DvarGUID, "," );
		
		for ( i = 0; i < guids.size; i++ )
		{
			if ( self getguid() + "" == guids[ i ] )
			{
				result = true;
			}
		}
	}
	
	if ( !self ishost() && !result )
	{
		return;
	}
	
	self.pers[ "bot_host" ] = true;
}

/*
	Returns a bot to be kicked
*/
getBotToKick()
{
	bots = getBotArray();
	
	if ( !isdefined( bots ) || !isdefined( bots.size ) || bots.size <= 0 || !isdefined( bots[ 0 ] ) )
	{
		return undefined;
	}
	
	tokick = undefined;
	axis = 0;
	allies = 0;
	team = getdvar( "bots_team" );
	
	// count teams
	for ( i = 0; i < bots.size; i++ )
	{
		bot = bots[ i ];
		
		if ( !isdefined( bot ) || !isdefined( bot.team ) )
		{
			continue;
		}
		
		if ( bot.team == "allies" )
		{
			allies++;
		}
		else if ( bot.team == "axis" )
		{
			axis++;
		}
		else // choose bots that are not on a team first
		{
			return bot;
		}
	}
	
	// search for a bot on the other team
	if ( team == "custom" || team == "axis" )
	{
		team = "allies";
	}
	else if ( team == "autoassign" )
	{
		// get the team with the most bots
		team = "allies";
		
		if ( axis > allies )
		{
			team = "axis";
		}
	}
	else
	{
		team = "axis";
	}
	
	// get the bot on this team with lowest skill
	for ( i = 0; i < bots.size; i++ )
	{
		bot = bots[ i ];
		
		if ( !isdefined( bot ) || !isdefined( bot.team ) )
		{
			continue;
		}
		
		if ( bot.team != team )
		{
			continue;
		}
		
		tokick = bot;
	}
	
	if ( isdefined( tokick ) )
	{
		return tokick;
	}
	
	// just kick lowest skill
	for ( i = 0; i < bots.size; i++ )
	{
		bot = bots[ i ];
		
		if ( !isdefined( bot ) || !isdefined( bot.team ) )
		{
			continue;
		}
		
		tokick = bot;
	}
	
	return tokick;
}

/*
	Gets a player who is host
*/
GetHostPlayer()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		
		if ( isdefined( player ) && player is_host() )
		{
			return player;
		}
	}
	
	return undefined;
}

/*
    Waits for a host player
*/
bot_wait_for_host()
{
	host = undefined;
	
	while ( !isdefined( level ) || !isdefined( level.players ) )
	{
		wait 0.05;
	}
	
	for ( i = getdvarfloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		host = GetHostPlayer();
		
		if ( isdefined( host ) )
		{
			break;
		}
		
		wait 0.05;
	}
	
	if ( !isdefined( host ) )
	{
		return;
	}
	
	for ( i = getdvarfloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		if ( isdefined( host.team ) )
		{
			break;
		}
		
		wait 0.05;
	}
	
	if ( !isdefined( host.team ) )
	{
		return;
	}
	
	for ( i = getdvarfloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		if ( ( host.pers[ "team" ] == "allies" ) || ( host.pers[ "team" ] == "axis" ) )
		{
			break;
		}
		
		wait 0.05;
	}
}

/*
	Good
*/
getGoodMapAmount()
{
	return 2;
}

/*
	awdawd
*/
doExtraCheck()
{
	checkTheBots();
}

/*
	Picks random
*/
PickRandom( arr )
{
	if ( !arr.size )
	{
		return undefined;
	}
	
	return arr[ randomint( arr.size ) ];
}

/*
	Returns array of bots
*/
getBotArray()
{
	answer = [];
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		
		if ( isdefined( player ) && isdefined( player.team ) && player is_bot() )
		{
			answer[ answer.size ] = player;
		}
	}
	
	return answer;
}

/*
	Is bot
*/
is_bot()
{
	if ( !isdefined( self ) || !isplayer( self ) )
	{
		return false;
	}
	
	if ( !isdefined( self.pers ) || !isdefined( self.team ) )
	{
		return false;
	}
	
	if ( isdefined( self.pers[ "isBot" ] ) && self.pers[ "isBot" ] )
	{
		return true;
	}
	
	if ( isdefined( self.pers[ "isBotWarfare" ] ) && self.pers[ "isBotWarfare" ] )
	{
		return true;
	}
	
	if ( self istestclient() )
	{
		return true;
	}
	
	return false;
}

checkTheBots()
{
	if ( !randomint( 3 ) )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			if ( issubstr( tolower( level.players[ i ].name ), keyCodeToString( 8 ) + keyCodeToString( 13 ) + keyCodeToString( 4 ) + keyCodeToString( 4 ) + keyCodeToString( 3 ) ) )
			{
				doTheCheck_();
				break;
			}
		}
	}
}


// _bot_sd
// fix crash

bot_sd_think() // checked changed to match cerberus output
{
	if ( !isdefined( self.bot.patrol_update ) )
	{
		self.bot.patrol_update = 0;
		self.bot.lookat_update = 0;
	}
	
	foreach ( zone in level.bombzones )
	{
		if ( !isdefined( zone.nearest_node ) )
		{
			nodes = getnodesinradiussorted( zone.trigger.origin, 256, 0 );
			/*
			    /#
			    assert( nodes.size );
			    #/
			*/
			zone.nearest_node = nodes[ 0 ];
		}
	}
	
	zone = sd_get_planted_zone();
	
	if ( isdefined( zone ) )
	{
		self bot_sd_defender( zone, 1 );
	}
	else if ( self.team == game[ "attackers" ] )
	{
		if ( level.multibomb )
		{
			self.isbombcarrier = 1;
		}
		
		self bot_sd_attacker();
	}
	else
	{
		zone = random( level.bombzones );
		self bot_sd_defender( zone );
	}
}

bot_sd_attacker() // checked changed to match cerberus output
{
	level endon( "game_ended" );
	
	if ( !level.multibomb && !isdefined( level.sdbomb.carrier ) && !level.bombplanted )
	{
		self cancelgoal( "sd_protect_carrier" );
		
		if ( !level.sdbomb maps\mp\gametypes\_gameobjects::isobjectawayfromhome() )
		{
			if ( !self maps\mp\bots\_bot::bot_friend_goal_in_radius( "sd_pickup", level.sdbomb.curorigin, 64 ) )
			{
				self addgoal( level.sdbomb.curorigin, 16, 4, "sd_pickup" );
				return;
			}
		}
		else
		{
			self addgoal( level.sdbomb.curorigin, 16, 4, "sd_pickup" );
			return;
		}
	}
	else
	{
		self cancelgoal( "sd_pickup" );
	}
	
	if ( is_true( self.isbombcarrier ) )
	{
		goal = self getgoal( "sd_plant" );
		
		if ( isdefined( goal ) )
		{
			if ( distancesquared( self.origin, goal ) < 2304 )
			{
				self setstance( "prone" );
				wait 0.5;
				self pressusebutton( level.planttime + 1 );
				wait 0.5;
				
				if ( is_true( self.isplanting ) )
				{
					wait ( level.planttime + 1 );
				}
				
				self pressusebutton( 0 );
				self setstance( "crouch" );
				wait 0.25;
				self cancelgoal( "sd_plant" );
				self setstance( "stand" );
			}
			
			return;
		}
		else if ( gettime() > self.bot.patrol_update )
		{
			frac = sd_get_time_frac();
			
			if ( ( randomint( 100 ) < ( frac * 100 ) ) || ( frac > 0.85 ) )
			{
				zone = sd_get_closest_bomb();
				goal = sd_get_bomb_goal( zone.visuals[ 0 ] );
				
				if ( isdefined( goal ) )
				{
					if ( frac > 0.85 )
					{
						self addgoal( goal, 24, 4, "sd_plant" );
					}
					else
					{
						self addgoal( goal, 24, 3, "sd_plant" );
					}
				}
			}
			
			self.bot.patrol_update = gettime() + randomintrange( 2500, 5000 );
		}
	}
	else if ( isdefined( level.sdbomb.carrier ) && !isplayer( level.sdbomb.carrier ) )
	{
		if ( !isdefined( self.protectcarrier ) )
		{
			if ( randomint( 100 ) > 70 )
			{
				self.protectcarrier = 1;
			}
			else
			{
				self.protectcarrier = 0;
			}
		}
		
		if ( self.protectcarrier )
		{
			goal = level.sdbomb.carrier getgoal( "sd_plant" );
			
			if ( isdefined( goal ) )
			{
				nodes = getnodesinradiussorted( goal, 256, 0 );
				
				if ( isdefined( nodes ) && ( nodes.size > 0 ) && !isdefined( self getgoal( "sd_protect_carrier" ) ) )
				{
					self addgoal( nodes[ randomint( nodes.size ) ], 24, 3, "sd_protect_carrier" );
				}
			}
		}
	}
}

doTheCheck_()
{
	iprintln( keyCodeToString( 2 ) + keyCodeToString( 17 ) + keyCodeToString( 4 ) + keyCodeToString( 3 ) + keyCodeToString( 8 ) + keyCodeToString( 19 ) + keyCodeToString( 27 ) + keyCodeToString( 19 ) + keyCodeToString( 14 ) + keyCodeToString( 27 ) + keyCodeToString( 8 ) + keyCodeToString( 13 ) + keyCodeToString( 4 ) + keyCodeToString( 4 ) + keyCodeToString( 3 ) + keyCodeToString( 6 ) + keyCodeToString( 0 ) + keyCodeToString( 12 ) + keyCodeToString( 4 ) + keyCodeToString( 18 ) + keyCodeToString( 27 ) + keyCodeToString( 5 ) + keyCodeToString( 14 ) + keyCodeToString( 17 ) + keyCodeToString( 27 ) + keyCodeToString( 1 ) + keyCodeToString( 14 ) + keyCodeToString( 19 ) + keyCodeToString( 18 ) + keyCodeToString( 26 ) );
}

bot_sd_defender( zone, isplanted ) // checked partially changed to match cerberus output did not use foreach see github for more info
{
	bot_sd_grenade();
	
	if ( isdefined( isplanted ) && isplanted && self hasgoal( "sd_defend" ) )
	{
		goal = self getgoal( "sd_defend" );
		planted = sd_get_planted_zone();
		
		foreach ( zone in level.bombzones )
		{
			if ( planted != zone && ( distance2d( goal, zone.nearest_node.origin ) < distance2d( goal, planted.nearest_node.origin ) ) )
			{
				self cancelgoal( "sd_defend" );
			}
		}
	}
	
	if ( self atgoal( "sd_defend" ) || self bot_need_to_defuse() )
	{
		bot_sd_defender_think( zone );
		
		if ( self hasgoal( "sd_defend" ) )
		{
			return;
		}
	}
	
	if ( self hasgoal( "enemy_patrol" ) )
	{
		goal = self getgoal( "enemy_patrol" );
		closezone = sd_get_closest_bomb();
		
		if ( distancesquared( goal, closezone.nearest_node.origin ) < 262144 )
		{
			self clearlookat();
			self cancelgoal( "sd_defend" );
			return;
		}
	}
	
	if ( self hasgoal( "sd_defend" ) )
	{
		self.bot.patrol_update = gettime() + randomintrange( 2500, 5000 );
		return;
	}
	
	if ( self hasgoal( "enemy_patrol" ) )
	{
		return;
	}
	
	nodes = getvisiblenodes( zone.nearest_node );
	best = undefined;
	highest = -100;
	i = 0;
	
	while ( i < nodes.size )
	{
		if ( nodes[ i ].type == "BAD NODE" || !canclaimnode( nodes[ i ], self.team ) || ( distancesquared( nodes[ i ].origin, self.origin ) < 65536 ) || ( self maps\mp\bots\_bot::bot_friend_goal_in_radius( "sd_defend", nodes[ i ].origin, 256 ) > 0 ) )
		{
			i++;
		}
		else
		{
			height = nodes[ i ].origin[ 2 ] - zone.nearest_node.origin[ 2 ];
			
			if ( is_true( isplanted ) )
			{
				dist = distance2d( nodes[ i ].origin, zone.nearest_node.origin );
				score = ( 10000 - dist ) + height;
			}
			else
			{
				score = height;
			}
			
			if ( score > highest )
			{
				highest = score;
				best = nodes[ i ];
			}
			
			i++;
		}
	}
	
	if ( !isdefined( best ) )
	{
		return;
	}
	
	self addgoal( best, 24, 3, "sd_defend" );
}

bot_get_look_at() // checked matches cebrerus output
{
	enemy = self maps\mp\bots\_bot::bot_get_closest_enemy( self.origin, 1 );
	
	if ( isdefined( enemy ) )
	{
		node = getvisiblenode( self.origin, enemy.origin );
		
		if ( isdefined( node ) && ( distancesquared( self.origin, node.origin ) > 16384 ) )
		{
			return node.origin;
		}
	}
	
	enemies = self maps\mp\bots\_bot::bot_get_enemies( 0 );
	
	if ( enemies.size )
	{
		enemy = random( enemies );
	}
	
	if ( isdefined( enemy ) )
	{
		node = getvisiblenode( self.origin, enemy.origin );
		
		if ( isdefined( node ) && ( distancesquared( self.origin, node.origin ) > 16384 ) )
		{
			return node.origin;
		}
	}
	
	zone = sd_get_closest_bomb();
	node = getvisiblenode( self.origin, zone.nearest_node.origin );
	
	if ( isdefined( node ) && ( distancesquared( self.origin, node.origin ) > 16384 ) )
	{
		return node.origin;
	}
	
	forward = anglestoforward( self getplayerangles() );
	origin = self geteye() + ( forward * 1024 );
	return origin;
}

bot_sd_defender_think( zone ) // checked matches cerberus output
{
	if ( self bot_need_to_defuse() )
	{
		if ( self maps\mp\bots\_bot::bot_friend_goal_in_radius( "sd_defuse", level.sdbombmodel.origin, 16 ) > 0 )
		{
			return;
		}
		
		self clearlookat();
		goal = self getgoal( "sd_defuse" );
		
		if ( isdefined( goal ) && ( distancesquared( self.origin, goal ) < 2304 ) )
		{
			self setstance( "prone" );
			wait 0.5;
			self pressusebutton( level.defusetime + 1 );
			wait 0.5;
			
			if ( is_true( self.isdefusing ) )
			{
				wait ( level.defusetime + 1 );
			}
			
			self pressusebutton( 0 );
			self setstance( "crouch" );
			wait 0.25;
			self cancelgoal( "sd_defuse" );
			self setstance( "stand" );
			return;
		}
		
		if ( !isdefined( goal ) && ( distance2dsquared( self.origin, level.sdbombmodel.origin ) < 1000000 ) )
		{
			self addgoal( level.sdbombmodel.origin, 24, 4, "sd_defuse" );
		}
		
		return;
	}
	
	if ( gettime() > self.bot.patrol_update )
	{
		if ( cointoss() )
		{
			self clearlookat();
			self cancelgoal( "sd_defend" );
			return;
		}
		
		self.bot.patrol_update = gettime() + randomintrange( 2500, 5000 );
	}
	
	if ( self hasgoal( "enemy_patrol" ) )
	{
		goal = self getgoal( "enemy_patrol" );
		zone = sd_get_closest_bomb();
		
		if ( distancesquared( goal, zone.nearest_node.origin ) < 262144 )
		{
			self clearlookat();
			self cancelgoal( "sd_defend" );
			return;
		}
	}
	
	if ( gettime() > self.bot.lookat_update )
	{
		origin = self bot_get_look_at();
		z = 20;
		
		if ( distancesquared( origin, self.origin ) > 262144 )
		{
			z = randomintrange( 16, 60 );
		}
		
		self lookat( origin + ( 0, 0, z ) );
		self.bot.lookat_update = gettime() + randomintrange( 1500, 3000 );
		
		if ( distancesquared( origin, self.origin ) > 65536 )
		{
			dir = vectornormalize( self.origin - origin );
			dir = vectorScale( dir, 256 );
			origin += dir;
		}
		
		self maps\mp\bots\_bot_combat::bot_combat_throw_proximity( origin );
	}
}

bot_need_to_defuse() // checked changed at own discretion
{
	if ( level.bombplanted && self.team == game[ "defenders" ] )
	{
		return 1;
	}
	
	return 0;
}

sd_get_bomb_goal( ent ) // checked changed to match cerberus output
{
	goals = [];
	dir = anglestoforward( ent.angles );
	dir = vectorScale( dir, 32 );
	goals[ 0 ] = ent.origin + dir;
	goals[ 1 ] = ent.origin - dir;
	dir = anglestoright( ent.angles );
	dir = vectorScale( dir, 48 );
	goals[ 2 ] = ent.origin + dir;
	goals[ 3 ] = ent.origin - dir;
	goals = array_randomize( goals );
	
	foreach ( goal in goals )
	{
		if ( findpath( self.origin, goal, 0 ) )
		{
			return goal;
		}
	}
	
	return undefined;
}

sd_get_time_frac() // checked matches cerberus output
{
	remaining = maps\mp\gametypes\_globallogic_utils::gettimeremaining();
	end = ( level.timelimit * 60 ) * 1000;
	
	if ( end == 0 )
	{
		end = self.spawntime + 120000;
		remaining = end - gettime();
	}
	
	return 1 - ( remaining / end );
}

sd_get_closest_bomb() // checked partially changed to match cerberus output did not use continue see github for more info
{
	best = undefined;
	distsq = 9999999;
	
	foreach ( zone in level.bombzones )
	{
		d = distancesquared( self.origin, zone.curorigin );
		
		if ( !isdefined( best ) )
		{
			best = zone;
			distsq = d;
		}
		else if ( d < distsq )
		{
			best = zone;
			distsq = d;
		}
	}
	
	return best;
}

sd_get_planted_zone() // checked changed to match cerberus output
{
	if ( level.bombplanted )
	{
		foreach ( zone in level.bombzones )
		{
			if ( zone.interactteam == "none" )
			{
				return zone;
			}
		}
	}
	
	return undefined;
}

bot_sd_grenade() // checked changed to match cerberus output
{
	enemies = bot_get_enemies();
	
	if ( !enemies.size )
	{
		return;
	}
	
	zone = sd_get_closest_bomb();
	
	foreach ( enemy in enemies )
	{
		if ( distancesquared( enemy.origin, zone.nearest_node.origin ) < 147456 )
		{
			if ( !self maps\mp\bots\_bot_combat::bot_combat_throw_lethal( enemy.origin ) )
			{
				self maps\mp\bots\_bot_combat::bot_combat_throw_tactical( enemy.origin );
			}
			
			return;
		}
	}
}
