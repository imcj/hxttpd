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

import neko.net.ServerLoop;
import neko.net.Socket;
import neko.net.Host;

import HttpdRequest.HttpMethod;

enum ConnectionState {
	/** during connection before the server has received a complete header */
        STATE_WAITING;

	/** While waiting for complete application/x-www-form-urlencoded content */
	STATE_DATA;

	/** Input data complete. Process on next interval */
	STATE_READY;

	/** during response */
        STATE_PROCESSING;

	/** After initial response completed */
        STATE_KEEPALIVE;

	/** No keepalive, we're closing */
	STATE_CLOSING;
}


class HttpdClientData {
	public var sock(default,null)	: Socket;
	public var remote_host		: Host;
	public var remote_port		: Int;
	public var state 		: ConnectionState;
	public var req 			: HttpdRequest;
	private var num_requests	: Int;
	public var timer		: Int;

	public function new(s:Socket) {
		sock = s;
		state = STATE_WAITING;
		req = null;
		num_requests = 0;
		timer = 0;
	}


	public function startNewRequest() : Void {
		closeFile(); // close last req file, in case.
		req = new HttpdRequest(this);
		num_requests ++;
		timer = 0;
	}

	public function markReady() : Void {
		state = STATE_READY;
	}

	public function startResponse() : Void {
		state = STATE_PROCESSING;
		timer = 0;
	}

	public function endRequest() : Void {
		closeFile();
		if(req.keepalive) {
			state = STATE_KEEPALIVE;
		}
		else {
			state = STATE_CLOSING;
		}
		req = null;
		timer = 0;
	}

	/** Set response code for current request */
	public function setResponse(val : Int) : Void {
		if(req != null) {
			req.return_code = val;
		}
		else {
			throw( new String("req not initialized"));
		}
	}

	/** Get current response code */
	public function getResponse() : Int {
		if(req == null) {
			throw( new String("req not initialized"));
		}
		return req.return_code;
	}

	/** Close current file associated with request */
	public function closeFile() : Void {
		if(req != null && req.file != null) {
			req.file.close();
		}
	}
}
