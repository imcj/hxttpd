#include <stdio.h>
#include <neko.h>
#include "plugin.h"

//DEFINE_KIND(k_mykind);

value on_interval( value server ) {

	switch( val_type(server) ) {
	case VAL_OBJECT:
		printf("object\n");
		break;
	default:
		printf("?????");
		break;
	}
	return val_null;

}

DEFINE_PRIM(on_interval,1);
