/* ******************************************************************** */
/*									*/
/*  Neko Standard Library Thread extennsion				*/
/*  Copyright (c)2005-2006 Motion-Twin, Russell Weir			*/
/*									*/
/* This library is free software; you can redistribute it and/or	*/
/* modify it under the terms of the GNU Lesser General Public		*/
/* License as published by the Free Software Foundation; either		*/
/* version 2.1 of the License, or (at your option) any later version.	*/
/*									*/
/* This library is distributed in the hope that it will be useful,	*/
/* but WITHOUT ANY WARRANTY; without even the implied warranty of	*/
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU	*/
/* Lesser General Public License or the LICENSE file for more details.	*/
/*									*/
/* ******************************************************************** */
#include <neko.h>
#ifdef NEKO_WINDOWS
#include <windows.h>
#else
#include <pthread.h>
#endif

/**
	<doc>
	<h1>Thread Extra</h1>
	<p>
	Thread equality, and forced exits 
	</p>
	</doc>
**/

#define val_thread(t)	((vthread*)val_data(t))

// from neko thread
typedef struct _tqueue {
        value msg;
        struct _tqueue *next;
} tqueue;

typedef struct {
#	ifdef NEKO_WINDOWS
	DWORD tid;
#	else
	pthread_t phandle;
	tqueue *first;
	tqueue *last;
	pthread_mutex_t lock;
	pthread_cond_t cond;
#	endif
	value callb;
	value callparam;
} vthread;



static value thread_equal(value t1, value t2) {
	vthread *thread1, *thread2;
	vkind k_thread = kind_import("thread");
	value rv;

	val_check_kind(t1,k_thread);
	val_check_kind(t2,k_thread);
	thread1 = val_thread(t1);
	thread2 = val_thread(t2);

	rv = val_false;
#ifdef NEKO_WINDOWS
	if(thread1->tid == thread2->tid)
#else
	if(thread1->phandle == thread2->phandle)
#endif
		rv = val_true;
	return rv;
}



static void thread_exit() {
#ifdef NEKO_WINDOWS
	ThreadExit();
#else
        pthread_exit(NULL);
#endif
}

DEFINE_PRIM(thread_exit,0);
DEFINE_PRIM(thread_equal,2);
