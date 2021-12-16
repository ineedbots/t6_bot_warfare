#include maps/mp/gametypes/_spectating;
#include maps/mp/gametypes/_globallogic_ui;
#include maps/mp/gametypes/_persistence;
#include maps/mp/_utility;

init()
{
	precacheshader( "mpflag_spectator" );
	game["strings"]["autobalance"] = &"MP_AUTOBALANCE_NOW";
	precachestring( &"MP_AUTOBALANCE_NOW" );

	if ( GetDvar( "scr_teambalance" ) == "" )
	{
		setdvar( "scr_teambalance", "0" );
	}

	level.teambalance = GetDvarInt( "scr_teambalance" );
	level.teambalancetimer = 0;

	if ( GetDvar( "scr_timeplayedcap" ) == "" )
	{
		setdvar( "scr_timeplayedcap", "1800" );
	}

	level.timeplayedcap = int( GetDvarInt( "scr_timeplayedcap" ) );
	level.freeplayers = [];

	if ( level.teambased )
	{
		level.alliesplayers = [];
		level.axisplayers = [];
		level thread onplayerconnect();
		level thread updateTeamBalance();
		wait( 0.15 );
		level thread updateplayertimes();
	}
	else
	{
		level thread onfreeplayerconnect();
		wait( 0.15 );
		level thread updateplayertimes();
	}
}


onplayerconnect()
{
	for ( ;; )
	{
		level waittill( "connecting", player );
		player thread onjoinedteam();
		player thread onjoinedspectators();
		player thread trackplayedtime();
	}
}


onfreeplayerconnect()
{
	for ( ;; )
	{
		level waittill( "connecting", player );
		player thread trackfreeplayedtime();
	}
}


onjoinedteam()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "joined_team" );
		self logstring( "joined team: " + self.pers["team"] );
		self updateteamtime();
	}
}


onjoinedspectators()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "joined_spectators" );
		self.pers["teamTime"] = undefined;
	}
}

trackplayedtime()
{
	self endon( "disconnect" );

	foreach ( team in level.teams )
	{
		self.timePlayed[team] = 0;
	}

	self.timePlayed["free"] = 0;
	self.timePlayed["other"] = 0;
	self.timePlayed["alive"] = 0;


	if ( !isdefined( self.timePlayed["total"] ) )
		self.timePlayed["total"] = 0;
	else if ( ( level.gameType == "twar" ) && ( 0 < game["roundsplayed"] ) && ( 0 < self.timeplayed["total"] ) )
		self.timePlayed["total"] = 0;

	while ( level.inprematchperiod )
	{
		wait( 0.05 );
	}

	for ( ;; )
	{
		if ( game["state"] == "playing" )
		{
			if ( isdefined( level.teams[self.sessionteam] ) )
			{
				self.timeplayed[self.sessionteam]++;
				self.timeplayed["total"]++;

				if ( isalive( self ) )
				{
					self.timeplayed["alive"]++;
				}
			}
			else if ( self.sessionteam == "spectator" )
			{
				self.timeplayed["other"]++;
			}
		}

		wait ( 1.0 );
	}

}

updateplayertimes()
{
	nexttoupdate = 0;

	for ( ;; )
	{
		nexttoupdate++;

		if ( nexttoupdate >= level.players.size )
		{
			nexttoupdate = 0;
		}

		if ( isdefined( level.players[nexttoupdate] ) )
		{
			level.players[nexttoupdate] updateplayedtime();
			level.players[nexttoupdate] maps\mp\gametypes\_persistence::checkcontractexpirations();
		}

		wait( 1 );
	}
}

updateplayedtime()
{
	pixbeginevent( "updatePlayedTime" );

	foreach ( team in level.teams )
	{
		if ( self.timeplayed[team] )
		{
			self addplayerstat( "time_played_" + team, int( min( self.timeplayed[team], level.timeplayedcap ) ) );
			self addplayerstatwithgametype( "time_played_total", int( min( self.timeplayed[team], level.timeplayedcap ) ) );
		}
	}

	if ( self.timeplayed["other"] )
	{
		self addplayerstat( "time_played_other", int( min( self.timeplayed["other"], level.timeplayedcap ) ) );
		self addplayerstatwithgametype( "time_played_total", int( min( self.timeplayed["other"], level.timeplayedcap ) ) );
	}

	if ( self.timeplayed["alive"] )
	{
		timealive = int( min( self.timeplayed["alive"], level.timeplayedcap ) );
		self maps\mp\gametypes\_persistence::incrementcontracttimes( timealive );
		self addplayerstat( "time_played_alive", timealive );
	}

	pixendevent();

	if ( game["state"] == "postgame" )
	{
		return;
	}

	foreach ( team in level.teams )
	{
		self.timeplayed[team] = 0;
	}

	self.timeplayed["other"] = 0;
	self.timeplayed["alive"] = 0;
}

updateteamtime()
{
	if ( game["state"] != "playing" )
	{
		return;
	}

	self.pers["teamTime"] = GetTime();
}

updateteambalancedvar()
{
	for ( ;; )
	{
		teambalance = GetDvarInt( "scr_teambalance" );

		if ( level.teambalance != teambalance )
		{
			level.teambalance = GetDvarInt( "scr_teambalance" );
		}

		timeplayedcap = GetDvarInt( "scr_timeplayedcap" );

		if ( level.timeplayedcap != timeplayedcap )
		{
			level.timeplayedcap = int( GetDvarInt( "scr_timeplayedcap" ) );
		}

		wait( 1 );
	}
}

updateTeamBalance()
{
	level thread updateTeamBalanceDvar();

	wait .15;

	if ( level.teamBalance && isRoundBased() && level.numlives )
	{
		if ( isDefined( game["BalanceTeamsNextRound"] ) )
			iPrintLnbold( &"MP_AUTOBALANCE_NEXT_ROUND" );

		level waittill( "game_ended" );
		wait 1;

		if ( isDefined( game["BalanceTeamsNextRound"] ) )
		{
			level balanceTeams();
			game["BalanceTeamsNextRound"] = undefined;
		}
		else if ( !getTeamBalance() )
		{
			game["BalanceTeamsNextRound"] = true;
		}
	}
	else
	{
		level endon ( "game_ended" );

		for ( ;; )
		{
			if ( level.teamBalance )
			{
				if ( !getTeamBalance() )
				{
					iPrintLnBold( &"MP_AUTOBALANCE_SECONDS", 15 );
					wait 15.0;

					if ( !getTeamBalance() )
						level balanceTeams();
				}

				wait 59.0;
			}

			wait 1.0;
		}
	}

}

getTeamBalance()
{
	level.team["allies"] = 0;
	level.team["axis"] = 0;

	players = level.players;

	for ( i = 0; i < players.size; i++ )
	{
		if ( ( isdefined( players[i].pers["team"] ) ) && ( players[i].pers["team"] == "allies" ) )
			level.team["allies"]++;
		else if ( ( isdefined( players[i].pers["team"] ) ) && ( players[i].pers["team"] == "axis" ) )
			level.team["axis"]++;
	}

	if ( ( level.team["allies"] > ( level.team["axis"] + level.teamBalance ) ) || ( level.team["axis"] > ( level.team["allies"] + level.teamBalance ) ) )
		return false;
	else
		return true;
}

balanceTeams()
{
	iPrintLnBold( game["strings"]["autobalance"] );
	//Create/Clear the team arrays
	AlliedPlayers = [];
	AxisPlayers = [];

	// Populate the team arrays
	players = level.players;

	for ( i = 0; i < players.size; i++ )
	{
		if ( !isdefined( players[i].pers["teamTime"] ) )
			continue;

		if ( ( isdefined( players[i].pers["team"] ) ) && ( players[i].pers["team"] == "allies" ) )
			AlliedPlayers[AlliedPlayers.size] = players[i];
		else if ( ( isdefined( players[i].pers["team"] ) ) && ( players[i].pers["team"] == "axis" ) )
			AxisPlayers[AxisPlayers.size] = players[i];
	}

	MostRecent = undefined;

	while ( ( AlliedPlayers.size > ( AxisPlayers.size + 1 ) ) || ( AxisPlayers.size > ( AlliedPlayers.size + 1 ) ) )
	{
		if ( AlliedPlayers.size > ( AxisPlayers.size + 1 ) )
		{
			// Move the player that's been on the team the shortest ammount of time (highest teamTime value)
			// Ignore players capturing or carrying objects
			for ( j = 0; j < AlliedPlayers.size; j++ )
			{

				if ( !isdefined( MostRecent ) )
					MostRecent = AlliedPlayers[j];
				else if ( AlliedPlayers[j].pers["teamTime"] > MostRecent.pers["teamTime"] )
					MostRecent = AlliedPlayers[j];
			}

			if ( isdefined( MostRecent ) )
				MostRecent changeTeam( "axis" );
			else
			{
				// Move the player that's been on the team the shortest ammount of time
				for ( j = 0; j < AlliedPlayers.size; j++ )
				{
					if ( !isdefined( MostRecent ) )
						MostRecent = AlliedPlayers[j];
					else if ( AlliedPlayers[j].pers["teamTime"] > MostRecent.pers["teamTime"] )
						MostRecent = AlliedPlayers[j];
				}

				MostRecent changeTeam( "axis" );
			}
		}
		else if ( AxisPlayers.size > ( AlliedPlayers.size + 1 ) )
		{
			// Move the player that's been on the team the shortest ammount of time (highest teamTime value)
			// Ignore players capturing or carrying objects
			for ( j = 0; j < AxisPlayers.size; j++ )
			{

				if ( !isdefined( MostRecent ) )
					MostRecent = AxisPlayers[j];
				else if ( AxisPlayers[j].pers["teamTime"] > MostRecent.pers["teamTime"] )
					MostRecent = AxisPlayers[j];
			}

			if ( isdefined( MostRecent ) )
				MostRecent changeTeam( "allies" );
			else
			{
				// Move the player that's been on the team the shortest ammount of time
				for ( j = 0; j < AxisPlayers.size; j++ )
				{
					if ( !isdefined( MostRecent ) )
						MostRecent = AxisPlayers[j];
					else if ( AxisPlayers[j].pers["teamTime"] > MostRecent.pers["teamTime"] )
						MostRecent = AxisPlayers[j];
				}

				MostRecent changeTeam( "allies" );
			}
		}

		MostRecent = undefined;
		AlliedPlayers = [];
		AxisPlayers = [];

		players = level.players;

		for ( i = 0; i < players.size; i++ )
		{
			if ( ( isdefined( players[i].pers["team"] ) ) && ( players[i].pers["team"] == "allies" ) )
				AlliedPlayers[AlliedPlayers.size] = players[i];
			else if ( ( isdefined( players[i].pers["team"] ) ) && ( players[i].pers["team"] == "axis" ) )
				AxisPlayers[AxisPlayers.size] = players[i];
		}
	}
}

changeTeam( team )
{
	teams[0] = "allies";
	teams[1] = "axis";
	assignment = team;

	if ( assignment != self.pers["team"] )
	{
		if ( self.sessionstate == "playing" || self.sessionstate == "dead" )
		{
			self.switching_teams = true;
			self.joining_team = assignment;
			self.leaving_team = self.pers["team"];
			self suicide();
		}
	}

	self.pers["team"] = assignment;
	self.team = assignment;
	self.pers["class"] = undefined;
	self.class = undefined;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;

	self maps\mp\gametypes\_globallogic_ui::updateObjectiveText();
	self maps\mp\gametypes\_spectating::setspectatepermissions();

	if ( level.teamBased )
		self.sessionteam = assignment;
	else
	{
		self.sessionteam = "none";
		self.ffateam = assignment;
	}

	if ( !isAlive( self ) )
		self.statusicon = "hud_status_dead";


	self notify( "joined_team" );
	level notify( "joined_team" );
	self setclientscriptmainmenu( game["menu_class"] );
	self openmenu( game["menu_class"] );
	self notify( "end_respawn" );
}

countplayers()
{
	players = level.players;
	playercounts = [];

	foreach ( team in level.teams )
	{
		playercounts[team] = 0;
	}

	foreach ( player in level.players )
	{
		if ( player == self )
		{
			continue;
		}

		team = player.pers["team"];

		if ( isdefined( team ) && isdefined( level.teams[team] ) )
		{
			playercounts[team]++;
		}
	}

	return playercounts;
}

trackfreeplayedtime()
{
	self endon( "disconnect" );

	foreach ( team in level.teams )
	{
		self.timeplayed[team] = 0;
	}

	self.timeplayed["other"] = 0;
	self.timeplayed["total"] = 0;
	self.timeplayed["alive"] = 0;

	while ( game["state"] == "playing" )
	{
		team = self.pers["team"];

		if ( isdefined( team ) && isdefined( level.teams[team] ) && self.sessionteam != "spectator" )
		{
			self.timeplayed[team]++;
			self.timeplayed["total"]++;

			if ( isalive( self ) )
			{
				self.timeplayed["alive"]++;
			}
		}
		else
		{
			self.timeplayed["other"]++;
		}

		wait( 1 );
	}
}

set_player_model( team, weapon )
{
	weaponclass = getweaponclass( weapon );
	bodytype = "default";

	switch ( weaponclass )
	{
		case "weapon_sniper":
			bodytype = "rifle";
			break;

		case "weapon_cqb":
			bodytype = "spread";
			break;

		case "weapon_lmg":
			bodytype = "mg";
			break;

		case "weapon_smg":
			bodytype = "smg";
			break;
	}

	self detachall();
	self setmovespeedscale( 1 );
	self setsprintduration( 4 );
	self setsprintcooldown( 0 );

	if ( level.multiteam )
	{
		bodytype = "default";

		switch ( team )
		{
			case "team7":
			case "team8":
				team = "allies";
				break;
		}
	}

	self [[ game[ "set_player_model" ][ team ][ bodytype ] ]]();
}

getteamflagmodel( teamref )
{
	return game["flagmodels"][teamref];
}

getteamflagcarrymodel( teamref )
{
	return game["carry_flagmodels"][teamref];
}

getteamflagicon( teamref )
{
	return game["carry_icon"][teamref];
}
