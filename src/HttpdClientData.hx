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
	public var keepalive		: Bool;

	public function new(s:Socket) {
		sock = s;
		state = STATE_WAITING;
		//req = new HttpdRequest();
		req = null;
		num_requests = 0;
		timer = 0;
		keepalive = false; // wait for header in request
	}


	public function startNewRequest() : Void {
		closeFile(); // close last req file, in case.
		state = STATE_PROCESSING;
		req = new HttpdRequest();
		//headers_out = new Hash<String>();
		//return_code = 200;
		num_requests ++;
		timer = 0;
		keepalive = false;
	}

	public function endRequest() : Void {
		closeFile();
		req = null;
		if(keepalive) {
			trace(here.methodName + " keeping alive");
			state = STATE_KEEPALIVE;
		}
		else {
			trace(here.methodName + " closing");
			state = STATE_CLOSING;
		}
		timer = 0;
	}

	//public function addResponseHeader(key : String, value : String) : Void
	//{
	//	headers_out.set(key, value);
	//}

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