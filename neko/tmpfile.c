#include <neko.h>
#include <stdio.h>
#ifdef NEKO_WINDOWS
#include <windows.h>
#endif

// forward decl
static value tmpfile_close( value o );
static void cleanup( value o );

/**
	<doc>
	<h1>TempFile</h1>
	<p>
	Create and use temporary files.
	</p>
	</doc>
**/

typedef struct {
        value name;
        FILE *io;
} fio;

#define val_file(o)	((fio*)val_data(o))

static void tmpfile_error( const char *msg ) {
	value a = alloc_string(msg);
	val_throw(a);
}

/**
        tmpfile_open :
        <doc>
        Calls tmpfile to create a temporary file
        </doc>
**/
static value tmpfile_open() {
        fio * f;
	vkind k_file;
        kind_share(k_file, "file");

	if(k_file == NULL)
		tmpfile_error("tmpfile_open k_file");

        f = (fio*)alloc(sizeof(fio));
	f->name = alloc_string("tmpfile");
	f->io = tmpfile();
	//f->io = fopen("/tmp/myfile","w+");
	if( f->io == NULL )
		tmpfile_error("tmpfile_open");

	value v = alloc_abstract(k_file,f);
	val_gc(v, cleanup);
	return v;
}

/**
        file_close : 'file -> void
        <doc>Close an file. Any other operations on this file will fail</doc>
**/
static value tmpfile_close( value o ) {
        fio *f;
	vkind k_file;
        kind_share(k_file, "file");
        val_check_kind(o,k_file);
        f = val_file(o);
        fclose(f->io);

	// no longer needs garbage collection
	val_gc(o,NULL);
        val_kind(o) = NULL;
	return val_true;
}

static void cleanup( value o ) {
        fio *f = val_file(o);
        fclose(f->io);
}

DEFINE_PRIM(tmpfile_open,0);
DEFINE_PRIM(tmpfile_close,1);


