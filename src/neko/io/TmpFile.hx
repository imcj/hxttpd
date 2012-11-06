// Copyright 2007, Russell Weir
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package neko.io;

class TmpFile {
	private var fi : FileInput;
	private var fo : FileOutput;
	private var __f : Dynamic;

	public function new() : Void {
		__f = untyped tmpfile_open();
		fi = untyped new FileInput(__f);
		fo = untyped new FileOutput(__f);
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
