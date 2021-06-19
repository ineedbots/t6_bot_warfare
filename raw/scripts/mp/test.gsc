init()
{
	for ( ;; )
	{
		level waittill ( "connected", player );

		player thread test();
	}
}

test()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		wait 0.05;
	}
}
