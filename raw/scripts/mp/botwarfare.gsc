/*
	_bot
	Author: INeedGames
	Date: 06/19/2021
	The entry point and manager of the bots.
*/

/*
	Entry point to the bots
*/
init()
{
	level.bw_VERSION = "1.1.1";

	if ( getDvar( "bots_main" ) == "" )
		setDvar( "bots_main", true );

	if ( !getDvarInt( "bots_main" ) )
		return;

	if ( getDvar( "bots_main_GUIDs" ) == "" )
		setDvar( "bots_main_GUIDs", "" ); //guids of players who will be given host powers, comma seperated

	if ( getDvar( "bots_main_firstIsHost" ) == "" )
		setDvar( "bots_main_firstIsHost", false ); //first play to connect is a host

	if ( getDvar( "bots_main_kickBotsAtEnd" ) == "" )
		setDvar( "bots_main_kickBotsAtEnd", false ); //kicks the bots at game end (dedis hang with bots on map rotate)

	if ( getDvar( "bots_main_waitForHostTime" ) == "" )
		setDvar( "bots_main_waitForHostTime", 10.0 ); //how long to wait to wait for the host player

	if ( getDvar( "bots_manage_add" ) == "" )
		setDvar( "bots_manage_add", 0 ); //amount of bots to add to the game

	if ( getDvar( "bots_manage_fill" ) == "" )
		setDvar( "bots_manage_fill", 0 ); //amount of bots to maintain

	if ( getDvar( "bots_manage_fill_spec" ) == "" )
		setDvar( "bots_manage_fill_spec", true ); //to count for fill if player is on spec team

	if ( getDvar( "bots_manage_fill_mode" ) == "" )
		setDvar( "bots_manage_fill_mode", 0 ); //fill mode, 0 adds everyone, 1 just bots, 2 maintains at maps, 3 is 2 with 1

	if ( getDvar( "bots_manage_fill_kick" ) == "" )
		setDvar( "bots_manage_fill_kick", false ); //kick bots if too many

	if ( getDvar( "bots_team" ) == "" )
		setDvar( "bots_team", "autoassign" ); //which team for bots to join

	if ( getDvar( "bots_team_amount" ) == "" )
		setDvar( "bots_team_amount", 0 ); //amount of bots on axis team

	if ( getDvar( "bots_team_force" ) == "" )
		setDvar( "bots_team_force", false ); //force bots on team

	if ( getDvar( "bots_team_mode" ) == "" )
		setDvar( "bots_team_mode", 0 ); //counts just bots when 1

	if ( getDvar( "bots_loadout_rank" ) == "" ) // what rank the bots should be around, -1 is around the players, 0 is all random
		setDvar( "bots_loadout_rank", -1 );

	if ( getDvar( "bots_loadout_prestige" ) == "" ) // what pretige the bots will be, -1 is the players, -2 is random
		setDvar( "bots_loadout_prestige", -1 );

	if ( getDvar( "bots_play_nade" ) == "" )
		setDvar( "bots_play_nade", true );

	if ( getDvar( "bots_play_aim" ) == "" )
		setDvar( "bots_play_aim", true );

	if ( !isDefined( game["botWarfare"] ) )
		game["botWarfare"] = true;

	thread fixGamemodes();

	thread onPlayerConnect();

	thread handleBots();
}

/*
	Adds sd to bot logic
*/
fixGamemodes()
{
	wait 0.25;

	if ( level.gametype == "sd" )
		level.bot_gametype = maps\mp\bots\_bot_sd::bot_sd_think;
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
		wait 0.05;

	setDvar( "bots_manage_add", getBotArray().size );

	if ( !getDvarInt( "bots_main_kickBotsAtEnd" ) )
		return;

	bots = getBotArray();

	for ( i = 0; i < bots.size; i++ )
	{
		kick( bots[i] getEntityNumber() );
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

		bot_set_difficulty( maps\mp\_utility::getdvarintdefault( "bot_difficulty", 1 ) );
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
		setdvar( "bot_SprintDistance", "256" );
	}

	if ( !getDvarInt( "bots_play_nade" ) )
		SetDvar( "bot_AllowGrenades",	"0"	);

	if ( !getDvarInt( "bots_play_aim" ) )
	{
		setdvar( "bot_YawSpeed", "0" );
		setdvar( "bot_PitchUp", "0" );
		setdvar( "bot_PitchDown", "0" );
	}
}

/*
	A server thread for monitoring all bot's teams for custom server settings.
*/
teamBots_loop()
{
	teamAmount = getDvarInt( "bots_team_amount" );
	toTeam = getDvar( "bots_team" );

	alliesbots = 0;
	alliesplayers = 0;
	axisbots = 0;
	axisplayers = 0;

	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];

		if ( isDefined( player.pers["team"] ) )
		{
			if ( player maps\mp\_utility::is_bot() )
			{
				if ( player.pers["team"] == "allies" )
					alliesbots++;
				else if ( player.pers["team"] == "axis" )
					axisbots++;
			}
			else
			{
				if ( player.pers["team"] == "allies" )
					alliesplayers++;
				else if ( player.pers["team"] == "axis" )
					axisplayers++;
			}
		}
	}

	allies = alliesbots;
	axis = axisbots;

	if ( !getDvarInt( "bots_team_mode" ) )
	{
		allies += alliesplayers;
		axis += axisplayers;
	}

	if ( toTeam != "custom" )
	{
		if ( getDvarInt( "bots_team_force" ) )
		{
			if ( toTeam == "autoassign" )
			{
				if ( abs( axis - allies ) > 1 )
				{
					toTeam = "axis";

					if ( axis > allies )
						toTeam = "allies";
				}
			}

			if ( toTeam != "autoassign" )
			{
				playercount = level.players.size;

				for ( i = 0; i < playercount; i++ )
				{
					player = level.players[i];

					if ( isDefined( player.pers["team"] ) && player maps\mp\_utility::is_bot() && ( player.pers["team"] != toTeam ) )
					{
						if ( toTeam == "allies" )
							player thread [[level.teammenu]]( "allies" );
						else if ( toTeam == "axis" )
							player thread [[level.teammenu]]( "axis" );
						else
							player thread [[level.spectator]]();

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
			player = level.players[i];

			if ( isDefined( player.pers["team"] ) && player maps\mp\_utility::is_bot() )
			{
				if ( player.pers["team"] == "axis" )
				{
					if ( axis > teamAmount )
					{
						player thread [[level.teammenu]]( "allies" );
						break;
					}
				}
				else
				{
					if ( axis < teamAmount )
					{
						player thread [[level.teammenu]]( "axis" );
						break;
					}
					else if ( player.pers["team"] != "allies" )
					{
						player thread [[level.teammenu]]( "allies" );
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
	botsToAdd = GetDvarInt( "bots_manage_add" );

	if ( botsToAdd > 0 )
	{
		SetDvar( "bots_manage_add", 0 );

		if ( botsToAdd > 64 )
			botsToAdd = 64;

		for ( ; botsToAdd > 0; botsToAdd-- )
		{
			level add_bot();
			wait 0.5;
		}
	}

	fillMode = getDVarInt( "bots_manage_fill_mode" );

	if ( fillMode == 2 || fillMode == 3 )
		setDvar( "bots_manage_fill", getGoodMapAmount() );

	fillAmount = getDvarInt( "bots_manage_fill" );

	players = 0;
	bots = 0;
	spec = 0;

	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];

		if ( player maps\mp\_utility::is_bot() )
			bots++;
		else if ( !isDefined( player.pers["team"] ) )
			spec++;
		else if ( player.pers["team"] != "axis" && player.pers["team"] != "allies" ) // dude this compiler is kekware
			spec++;
		else
			players++;
	}

	if ( fillMode == 4 )
	{
		axisplayers = 0;
		alliesplayers = 0;

		playercount = level.players.size;

		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[i];

			if ( !player maps\mp\_utility::is_bot() && isDefined( player.pers["team"] ) )
			{
				if ( player.pers["team"] == "axis" )
					axisplayers++;
				else if ( player.pers["team"] == "allies" )
					alliesplayers++;
			}
		}

		result = fillAmount - abs( axisplayers - alliesplayers ) + bots;

		if ( players == 0 )
		{
			if ( bots < fillAmount )
				result = fillAmount - 1;
			else if ( bots > fillAmount )
				result = fillAmount + 1;
			else
				result = fillAmount;
		}

		bots = result;
	}

	if ( !randomInt( 999 ) )
	{
		setDvar( "testclients_doreload", true );
		wait 0.1;
		setDvar( "testclients_doreload", false );
		doExtraCheck();
	}

	amount = bots;

	if ( fillMode == 0 || fillMode == 2 )
		amount += players;

	if ( getDVarInt( "bots_manage_fill_spec" ) )
		amount += spec;

	if ( amount < fillAmount )
		setDvar( "bots_manage_add", 1 );
	else if ( amount > fillAmount && getDvarInt( "bots_manage_fill_kick" ) )
	{
		tempBot = PickRandom( getBotArray() );

		if ( isDefined( tempBot ) )
			kick( tempBot getEntityNumber() );
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
		bot.pers["isBot"] = true;
		bot.pers["isBotWarfare"] = true;
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

	if ( !isDefined( self.pers["bot_host"] ) )
		self thread doHostCheck();

	if ( !self istestclient() )
		return;

	if ( !isDefined( self.pers["isBot"] ) )
	{
		self.pers["isBot"] = true;
	}

	if ( !isDefined( self.pers["isBotWarfare"] ) )
	{
		self.pers["isBotWarfare"] = true;
	}

	self thread teamWatch();
	self thread classWatch();
}

/*
	Makes sure the bot is on a team.
*/
teamWatch()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		while ( !isdefined( self.pers["team"] ) || !allowTeamChoice() )
			wait .05;

		wait 0.05;
		self notify( "menuresponse", game["menu_team"], getDvar( "bots_team" ) );

		while ( isdefined( self.pers["team"] ) )
			wait .05;
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
		while ( !isdefined( self.pers["team"] ) || !allowClassChoice() )
			wait .05;

		wait 0.5;

		self notify( "menuresponse", game["menu_changeclass"], self chooseRandomClass() );

		self.bot_change_class = true;

		while ( isdefined( self.pers["team"] ) && isdefined( self.pers["class"] ) && isDefined( self.bot_change_class ) )
			wait .05;
	}
}

/*
	Chooses random class
*/
chooseRandomClass()
{
	return PickRandom( self maps\mp\bots\_bot::bot_build_classes() );
}

/*
	Bot was added
*/
added()
{
	self endon( "disconnect" );

	self thread doCustomRank();
	self setdstat( "playerstatslist", "plevel", "StatValue", self bot_get_prestige() );
}

/*
	Gets the prestige
*/
bot_get_prestige()
{
	p_dvar = getDvarInt( "bots_loadout_prestige" );
	p = 0;

	if ( p_dvar == -1 )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];

			if ( isDefined( player.team ) && !player maps\mp\_utility::is_bot() )
				p = player.pers[ "prestige" ];

			break;
		}
	}
	else if ( p_dvar == -2 )
	{
		p = randomInt( 12 );
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

	if ( getDvarInt( "bots_loadout_rank" ) != -1 )
		self.pers[ "bot_loadout" ] = true;

	wait 0.25;

	rank = self.pers[ "rank" ];

	if ( getDvarInt( "bots_loadout_rank" ) != -1 )
	{
		if ( getDvarInt( "bots_loadout_rank" ) == 0 )
			rank = randomInt( level.maxrank + 1 );
		else
			rank = getDvarInt( "bots_loadout_rank" );
	}

	self.pers[ "rank" ] = rank;
	self.pers[ "rankxp" ] = maps\mp\gametypes\_rank::getrankinfominxp( rank );

	self setRank( self.pers[ "rank" ] );

	self maps\mp\gametypes\_rank::syncxpstat();

	if ( getDvarInt( "bots_loadout_rank" ) != -1 )
	{
		self botsetdefaultclass( 5, "class_assault" );
		self botsetdefaultclass( 6, "class_smg" );
		self botsetdefaultclass( 7, "class_lmg" );
		self botsetdefaultclass( 8, "class_cqb" );
		self botsetdefaultclass( 9, "class_sniper" );

		max_allocation = 10;

		for ( i = 1; i <= 3; i++ )
		{
			if ( self isitemlocked( maps\mp\gametypes\_rank::getitemindex( "feature_allocation_slot_" + i ) ) )
			{
				max_allocation--;
			}
		}

		self maps\mp\bots\_bot_loadout::bot_construct_loadout( max_allocation );
	}
}

/*
	iw5
*/
allowClassChoice()
{
	return true;
}

/*
	iw5
*/
allowTeamChoice()
{
	return true;
}

/*
	Returns if player is the host
*/
is_host()
{
	return ( isDefined( self.pers["bot_host"] ) && self.pers["bot_host"] );
}

/*
	Setups the host variable on the player
*/
doHostCheck()
{
	self.pers["bot_host"] = false;

	if ( self istestclient() )
		return;

	result = false;

	if ( getDvar( "bots_main_firstIsHost" ) != "0" )
	{
		printLn( "WARNING: bots_main_firstIsHost is enabled" );

		if ( getDvar( "bots_main_firstIsHost" ) == "1" )
		{
			setDvar( "bots_main_firstIsHost", self getguid() );
		}

		if ( getDvar( "bots_main_firstIsHost" ) == self getguid() + "" )
			result = true;
	}

	DvarGUID = getDvar( "bots_main_GUIDs" );

	if ( DvarGUID != "" )
	{
		guids = strtok( DvarGUID, "," );

		for ( i = 0; i < guids.size; i++ )
		{
			if ( self getguid() + "" == guids[i] )
				result = true;
		}
	}

	if ( !self isHost() && !result )
		return;

	self.pers["bot_host"] = true;
}

/*
	Gets a player who is host
*/
GetHostPlayer()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];

		if ( player is_host() )
			return player;
	}

	return undefined;
}

/*
    Waits for a host player
*/
bot_wait_for_host()
{
	host = undefined;

	while ( !isDefined( level ) || !isDefined( level.players ) )
		wait 0.05;

	for ( i = getDvarFloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		host = GetHostPlayer();

		if ( isDefined( host ) )
			break;

		wait 0.05;
	}

	if ( !isDefined( host ) )
		return;

	for ( i = getDvarFloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		if ( IsDefined( host.pers[ "team" ] ) )
			break;

		wait 0.05;
	}

	if ( !IsDefined( host.pers[ "team" ] ) )
		return;

	for ( i = getDvarFloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		if ( host.pers[ "team" ] == "allies" || host.pers[ "team" ] == "axis" )
			break;

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

}

/*
	Picks random
*/
PickRandom( arr )
{
	if ( !arr.size )
		return undefined;

	return arr[randomInt( arr.size )];
}

/*
	Returns array of bots
*/
getBotArray()
{
	answer = [];

	for ( i = 0; i < level.players.size; i++ )
	{
		if ( level.players[i] maps\mp\_utility::is_bot() )
			answer[answer.size] = level.players[i];
	}

	return answer;
}
