init()
{
	if ( getDvar( "g_inactivitySpectator" ) == "" )
		setDvar( "g_inactivitySpectator", 0.0 );

	level.inactivitySpectator = getDvarFloat( "g_inactivitySpectator" ) * 1000;

	if ( level.inactivitySpectator <= 0 )
		return;

	thread watchPlayers();
}

watchPlayers()
{
	for ( ;; )
	{
		wait 1.5;

		theTime = getTime();

		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];

			if ( isDefined( player ) && !player.hasSpawned )
			{
				if ( !isDefined( player.specTime ) )
					player.specTime = theTime;
				else if ( ( theTime - player.specTime ) >= level.inactivitySpectator )
					kick( player getEntityNumber() );
			}
		}
	}
}
