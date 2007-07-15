package neko.io;
import neko.io.File;

class TmpFile {
	private var fi : FileInput;
	private var fo : FileOutput;
	private var __f : FileHandle;

	public function new() : Void {
		__f = untyped tmpfile_open();
		fi = new FileInput(__f);
		fo = new FileOutput(__f);
	}

	public function close() : Void {
		untyped tmpfile_close(__f);
	}

	public function getInput() : FileInput {
		return fi;
	}

	public function getOutput() : FileOutput {
		return fo;
	}

	private static var tmpfile_open = neko.Lib.load("tmpfile","tmpfile_open",0);
	private static var tmpfile_close = neko.Lib.load("tmpfile", "tmpfile_close", 1);
}
