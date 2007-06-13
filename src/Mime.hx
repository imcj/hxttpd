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

class Mime {
	static public var extmap 	: Hash<String>;

	static function populateExtmap() {
		extmap = new Hash<String>();
		extmap.set("gif", "image/gif");
		extmap.set("jpeg", "image/jpeg");
		extmap.set("jpg", "image/jpeg");
		extmap.set("png", "image/png");
		extmap.set("css", "text/css");
		extmap.set("html", "text/html");
		extmap.set("htm", "text/html");
		extmap.set("txt", "text/plain");
		extmap.set("js", "application/javascript");
		extmap.set("pdf", "application/pdf");
		extmap.set("xml", "text/xml");
		extmap.set("wav", "audio/x-wav");
		//extmap.set("", "");
	}
	static public function extensionToMime(ext : String) : String {
		if(extmap == null)
                        populateExtmap();
		if(extmap.exists(ext))
			return extmap.get(ext);
		return "unknown/unknown";
	}
}
