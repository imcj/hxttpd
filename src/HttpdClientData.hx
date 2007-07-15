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


class HttpdClientData {
	/** during connection before the server has received a complete header */
	public static var STATE_WAITING 	: Int = 0;
	/** While waiting for complete application/x-www-form-urlencoded content */
	public static var STATE_DATA		: Int = 1;
	/** Input data complete. Process on next interval */
	public static var STATE_READY		: Int = 2;
	/** during response */
	public static var STATE_PROCESSING 	: Int = 3;
	/** After initial response completed */
	public static var STATE_KEEPALIVE 	: Int = 4;
	/** No keepalive, we're closing */
	public static var STATE_CLOSING		: Int = 5;
	public static var STATE_MAX		: Int = 5;

	//public var server		: ThreadServer<Connection,String>;
	public var server(default,null) : HxTTPDTinyServer;
	public var sock			: Socket;
	public var remote_host		: Host;
	public var remote_port		: Int;
	public var state 		: Int;
	public var req 			: HttpdRequest;
	public var response		: HttpdResponse;
	private var num_requests	: Int;
	public var timer		: Int;

	public function new(server, s:Socket) {
		this.server = server;
		sock = s;
		state = STATE_WAITING;
		req = null;
		response = null;
		num_requests = 0;
		timer = 0;
	}


	public function startNewRequest() : Void {
		closeFile(); // close last req file, in case.
		req = new HttpdRequest(this,server.getRequestSerial());
		response = new HttpdResponse(this);
		num_requests ++;
		timer = 0;
	}

	public function awaitPost() : Bool {
		// TODO: Check states, and make .state(get,null)
		state = STATE_DATA;
		if(!req.startPost()) {
			return false;
		}
		return true;
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
		if(response.keepalive) {
			state = STATE_KEEPALIVE;
		}
		else {
			state = STATE_CLOSING;
		}
		req = null;
		response = null;
		timer = 0;
	}

	public function setState(s:Int) : Void {
		if(s < 0 || s > STATE_MAX)
			throw("Invalid state set for client");
		state = s;
	}

	/** Set response code for current request */
	public function setResponse(val : Int) : Void {
		if(req != null && response != null) {
			response.setStatus(val);
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
		return response.getStatus();
		//return response.status;
	}

	/** Close current file associated with request */
	public function closeFile() : Void {
		if(response != null && response.file != null) {
			response.file.close();
		}
	}
}
