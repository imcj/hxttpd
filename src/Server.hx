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

class Server {
	public static var HOST = "localhost";
	public static var PORT = 2000;
	static function main() {
		var s = new HxTTPDTinyServer();
		s.keepalive_enabled = true;
		s.run(new neko.net.Host(HOST), PORT);
		trace("Server did not run");
	}
}
