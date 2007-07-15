#include <neko.h>
#include <stdio.h>
#ifdef NEKO_WINDOWS
#include <windows.h>
#endif

/**
	<doc>
	<h1>hive</h1>
	<p>
	Hive helper functions.
	</p>
	</doc>
**/


/**
        send_message : message dynamic
        <doc>Actually only a placeholder for haxe toooo override</doc>
**/
static void send_message( value o ) {
	return;
}


DEFINE_PRIM(send_message,1);


