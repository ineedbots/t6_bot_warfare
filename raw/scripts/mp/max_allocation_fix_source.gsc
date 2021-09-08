init()
{
	level thread on_player_connect();
}

on_player_connect()
{
	while ( true )
	{
		level waittill( "connected", player );

		if ( !player istestclient() )
			player thread check_player_classes();
	}
}

check_player_classes()
{
	self endon( "disconnect" );

	for ( class_num = 0; class_num < 10; class_num++ )
	{
		allocationSpent = self GetLoadoutAllocation( class_num );
		logline1 = self.name + " XUID: " + self getXUID() + " maxAllowed: " + level.maxAllocation + " current: " + allocationSpent;
		print( logline1 );

		if ( allocationSpent > level.maxAllocation )
		{
			logline1 = "Player: " + self.name + " XUID: " + self getXUID() + " had too many items in their class.";
			print( logline1 );
			kick( self getEntityNumber() );
			return;
		}
	}
}