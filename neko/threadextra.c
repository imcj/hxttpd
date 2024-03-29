/* ************************************************************************ */
/*																			*/
/*  Neko Standard Library													*/
/*  Copyright (c)2005-2006 Motion-Twin										*/
/*																			*/
/* This library is free software; you can redistribute it and/or			*/
/* modify it under the terms of the GNU Lesser General Public				*/
/* License as published by the Free Software Foundation; either				*/
/* version 2.1 of the License, or (at your option) any later version.		*/
/*																			*/
/* This library is distributed in the hope that it will be useful,			*/
/* but WITHOUT ANY WARRANTY; without even the implied warranty of			*/
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU		*/
/* Lesser General Public License or the LICENSE file for more details.		*/
/*																			*/
/* ************************************************************************ */
#include <neko.h>
#include <neko_vm.h>
#include <string.h>
#ifdef NEKO_WINDOWS
#	include <windows.h>
#	define WM_TMSG			(WM_USER + 1)

typedef HANDLE vlock;

#else
#	include <pthread.h>
#	include <sys/time.h>

typedef struct _tqueue {
	value msg;
	struct _tqueue *next;
} tqueue;

typedef struct _vlock {
	pthread_mutex_t lock;
	pthread_cond_t cond;
	int counter;
} *vlock;

#endif

/**
	<doc>
	<h1>Thread</h1>
	<p>
	An API to create and manager system threads and locks.
	</p>
	</doc>
**/

#define val_threadextra(t)	((vthread*)val_data(t))
#define val_lockextra(l)		((vlock)val_data(l))

DEFINE_KIND(k_threadextra);
DEFINE_KIND(k_lockextra);

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

#ifndef NEKO_WINDOWS

static pthread_key_t local_thread = (pthread_key_t)-1;

static void free_key( void *r ) {
	free_root((value*)r);
}

static vthread *get_local_thread() {
	value *r;
	if( local_thread == (pthread_key_t)-1 )
		pthread_key_create(&local_thread,free_key);
	r = (value*)pthread_getspecific(local_thread);
	return (vthread*)(r?*r:NULL);
}

static void set_local_thread( vthread *t ) {
	value *r = (value*)pthread_getspecific(local_thread);
	if( r == NULL ) {
		r = alloc_root(1);
		pthread_setspecific(local_thread,r);
	}
	*r = (value)t;
}

static void init_thread_queue( vthread *t ) {
	pthread_mutex_init(&t->lock,NULL);
	pthread_cond_init(&t->cond,NULL);
}

static void free_thread( value v ) {
	vthread *t = val_threadextra(v);
	pthread_mutex_destroy(&t->lock);
	pthread_cond_destroy(&t->cond);
}

#endif

static int thread_loop( void *_t ) {
	vthread *t = (vthread*)_t;
	value exc = NULL;
	neko_vm *vm;
#	ifndef NEKO_WINDOWS
	set_local_thread(t);
#	endif
	// init and run the VM
	vm = neko_vm_alloc(NULL);
	neko_vm_select(vm);
	val_callEx(val_null,t->callb,&t->callparam,1,&exc);
	// cleanup
	vm = NULL;
	return 0;
}

/**
	thread_create : f:function:1 -> p:any -> 'thread
	<doc>Creates a thread that will be running the function [f(p)]</doc>
**/
static value thread_create( value f, value param ) {
	value vt;
	vthread *t;
	val_check_function(f,1);
	t = (vthread*)alloc(sizeof(vthread));
	memset(t,0,sizeof(vthread));
	t->callb = f;
	t->callparam = param;
#	ifdef NEKO_WINDOWS
	if( !neko_thread_create(thread_loop,t,&t->tid) )
		neko_error();
	vt = alloc_abstract(k_threadextra,t);
#	else
	get_local_thread(); // ensure that the key is initialized
	init_thread_queue(t);
	vt = alloc_abstract(k_threadextra,t);
	if( !neko_thread_create(thread_loop,t,&t->phandle) ) {
		free_thread(vt);
		neko_error();
	}
	val_gc(vt,free_thread);
#	endif
	return vt;
}

/**
	thread_current : void -> 'thread
	<doc>Returns the current thread</doc>
**/
static value thread_current() {
#	ifdef NEKO_WINDOWS
	vthread *t = (vthread*)alloc(sizeof(vthread));
	memset(t,0,sizeof(vthread));
	t->tid = GetCurrentThreadId();
#	else
	vthread *t = get_local_thread();
	if( t == NULL ) {
		t = (vthread*)alloc(sizeof(vthread));
		init_thread_queue(t);
		set_local_thread(t);
		t->phandle = pthread_self();
	}
#	endif
	return alloc_abstract(k_threadextra,t);
}

/**
	thread_send : 'thread -> msg:any -> void
	<doc>Send a message into the target thread message queue</doc>
**/
static value thread_send( value vt, value msg ) {
	vthread *t;
	val_check_kind(vt,k_threadextra);
	t = val_threadextra(vt);
#	ifdef NEKO_WINDOWS
	{
		value *r = alloc_root(1);
		*r = msg;
		if( !PostThreadMessage(t->tid,WM_TMSG,0,(LPARAM)r) )
			neko_error();
	}
#	else
	{
		tqueue *q = (tqueue*)alloc(sizeof(tqueue));
		q->msg = msg;
		q->next = NULL;
		pthread_mutex_lock(&t->lock);
		if( t->last == NULL )
			t->first = q;
		else
			t->last->next = q;
		t->last = q;
		pthread_cond_signal(&t->cond);
		pthread_mutex_unlock(&t->lock);
	}
#	endif
	return val_null;
}

/**
	thread_read_message : block:bool -> any
	<doc>
	Reads a message from the message queue. If [block] is true, the
	function only returns when a message is available. If [block] is
	false and no message is available in the queue, the function will
	return immediatly [null].
	</doc>
**/
static value thread_read_message( value block ) {
#	ifdef NEKO_WINDOWS
	value *r, v = val_null;
	MSG msg;
	val_check(block,bool);
	if( !val_bool(block) ) {
		if( !PeekMessage(&msg,NULL,0,0,PM_REMOVE) )
			return val_null;
	} else if( !GetMessage(&msg,NULL,0,0) )
		neko_error();
	switch( msg.message ) {
	case WM_TMSG:
		r = (value*)msg.lParam;
		v = *r;
		free_root(r);
		break;
	default:
		neko_error();
		break;
	}
	return v;
#	else
	vthread *t = val_threadextra(thread_current());
	value msg;
	val_check(block,bool);
	pthread_mutex_lock(&t->lock);
	while( t->first == NULL )
		if( val_bool(block) )
			pthread_cond_wait(&t->cond,&t->lock);
		else {
			pthread_mutex_unlock(&t->lock);
			return val_null;
		}
	msg = t->first->msg;
	t->first = t->first->next;
	if( t->first == NULL )
		t->last = NULL;
	else
		pthread_cond_signal(&t->cond);
	pthread_mutex_unlock(&t->lock);
	return msg;
#	endif
}

static value thread_equal(value t1, value t2) {
	vthread *thread1, *thread2;
	value rv;

	val_check_kind(t1,k_threadextra);
	val_check_kind(t2,k_threadextra);
	thread1 = val_threadextra(t1);
	thread2 = val_threadextra(t2);

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
	ExitThread(0);
#else
        pthread_exit(NULL);
#endif
}

static void free_lock( value l ) {
#	ifdef NEKO_WINDOWS
	CloseHandle( val_lockextra(l) );
#	else
	pthread_cond_destroy( &val_lockextra(l)->cond );
	pthread_mutex_destroy( &val_lockextra(l)->lock );
#	endif
}

/**
	lock_create : void -> 'lock
	<doc>Creates a lock which is initially locked</doc>
**/
static value lock_create() {
	value vl;
	vlock l;
#	ifdef NEKO_WINDOWS
	l = CreateSemaphore(NULL,0,(1 << 10),NULL);
	if( l == NULL )
		neko_error();
#	else
	l = (vlock)alloc_private(sizeof(struct _vlock));
	l->counter = 0;
	if( pthread_mutex_init(&l->lock,NULL) != 0 || pthread_cond_init(&l->cond,NULL) != 0 )
		neko_error();
#	endif
	vl = alloc_abstract(k_lockextra,l);
	val_gc(vl,free_lock);
	return vl;
}

/**
	lock_release : 'lock -> void
	<doc>
	Release a lock. The thread does not need to own the lock to be
	able to release it. If a lock is released several times, it can be
	acquired as many times
	</doc>
**/
static value lock_release( value lock ) {
	vlock l;
	val_check_kind(lock,k_lockextra);
	l = val_lockextra(lock);
#	ifdef NEKO_WINDOWS
	if( !ReleaseSemaphore(l,1,NULL) )
		neko_error();
#	else
	pthread_mutex_lock(&l->lock);
	l->counter++;
	pthread_cond_signal(&l->cond);
	pthread_mutex_unlock(&l->lock);
#	endif
	return val_true;
}

/**
	lock_wait : 'lock -> timeout:number? -> bool
	<doc>
	Waits for a lock to be released and acquire it.
	If [timeout] (in seconds) is not null and expires then
	the returned value is false
	</doc>
**/
static value lock_wait( value lock, value timeout ) {
	int has_timeout = !val_is_null(timeout);
	val_check_kind(lock,k_lockextra);
	if( has_timeout )
		val_check(timeout,number);
#	ifdef NEKO_WINDOWS
	switch( WaitForSingleObject(val_lockextra(lock),has_timeout?(DWORD)(val_number(timeout) * 1000.0):INFINITE) ) {
	case WAIT_ABANDONED:
	case WAIT_OBJECT_0:
		return val_true;
	case WAIT_TIMEOUT:
		return val_false;
	default:
		neko_error();
	}
#	else
	{
		vlock l = val_lockextra(lock);
		pthread_mutex_lock(&l->lock);
		while( l->counter == 0 ) {
			if( has_timeout ) {
				struct timeval tv;
				struct timespec t;
				double delta = val_number(timeout);
				int idelta = (int)delta, idelta2;
				delta -= idelta;
				delta *= 1.0e9;
				gettimeofday(&tv,NULL);
				delta += tv.tv_usec * 1000.0;
				idelta2 = (int)(delta / 1e9);
				delta -= idelta2 * 1e9;
				t.tv_sec = tv.tv_sec + idelta + idelta2;
				t.tv_nsec = (long)delta;
				if( pthread_cond_timedwait(&l->cond,&l->lock,&t) != 0 ) {
					pthread_mutex_unlock(&l->lock);
					return val_false;
				}
			} else
				pthread_cond_wait(&l->cond,&l->lock);
		}
		l->counter--;
		if( l->counter > 0 )
			pthread_cond_signal(&l->cond);
		pthread_mutex_unlock(&l->lock);
		return val_true;
	}
#	endif
}

DEFINE_PRIM(thread_create,2);
DEFINE_PRIM(thread_current,0);
DEFINE_PRIM(thread_send,2);
DEFINE_PRIM(thread_read_message,1);
DEFINE_PRIM(thread_exit,0);
DEFINE_PRIM(thread_equal,2);

DEFINE_PRIM(lock_create,0);
DEFINE_PRIM(lock_wait,2);
DEFINE_PRIM(lock_release,1);
