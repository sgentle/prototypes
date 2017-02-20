/*
 * Copyright (c) 2015, Majenko Technologies
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright notice, this
 *   list of conditions and the following disclaimer in the documentation and/or
 *   other materials provided with the distribution.
 *
 * * Neither the name of Majenko Technologies nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <ESP8266mDNS.h>

const char *ssid = "";
const char *password = "";

ESP8266WebServer server(80);

const int relay1 = 12;
const int relay2 = 13;

void handleRoot() {
  for(uint8_t i = 0; i < server.args(); i++) {
    if (server.method() == HTTP_POST && server.argName(i).equals("state")) {
      if (server.arg(i).equals("on")) {
        digitalWrite(relay1, HIGH);
        digitalWrite(relay2, HIGH);
      }
      else {
        digitalWrite(relay1, LOW);
        digitalWrite(relay2, LOW);
      }
    }
  }

	server.send(200, "text/html", "OK");
}

void handleNotFound() {
	server.send(404, "text/plain", "Not Found");
}

void setup(void) {
	pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
	digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);
	Serial.begin(115200);
	WiFi.begin(ssid, password);
	Serial.println("");

	// Wait for connection
	while(WiFi.status() != WL_CONNECTED) {
		delay(500);
		Serial.print(".");
	}

	Serial.println("");
	Serial.print("Connected to ");
	Serial.println(ssid);
	Serial.print("IP address: ");
	Serial.println(WiFi.localIP());

	if(MDNS.begin("esprelay") ) {
		Serial.println("MDNS responder started");
	}

	server.on("/", handleRoot);
	server.onNotFound(handleNotFound);
	server.begin();
	Serial.println("HTTP server started");
}

void loop(void) {
	server.handleClient();
}

