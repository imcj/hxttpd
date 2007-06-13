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

class HttpdPathTools {

/*
	static public function checkPath(
	enum {
		s_normal,
		s_slash,
		s_slashdot,
		s_slashdotdot,
		s_forbidden
	} s;

	p = r->path;
	s = s_normal;
	do {
		c = *p++;
		switch (s) {
		case s_normal:
			if (c == '/')
				s = s_slash;
			break;
		case s_slash:
			if (c == '/')
				s = s_forbidden;
			else if (c == '.')
				s = r->c->allow_dotfiles ? s_slashdot : s_forbidden;
			else
				s = s_normal;
			break;
		case s_slashdot:
			if (c == 0 || c == '/')
				s = s_forbidden;
			else if (c == '.')
				s = s_slashdotdot;
			else
				s = s_normal;
			break;
		case s_slashdotdot:
			if (c == 0 || c == '/')
				s = s_forbidden;
			else
				s = s_normal;
			break;
		case s_forbidden:
			c = 0;
			break;
		}
	} while (c);
	return s == s_forbidden ? -1 : 0;

*/
}
