package main

import "testing"

func TestParseUsers(t *testing.T) {
	users := parseUsers("device_pubsub:device-pass,producer_sub:producer-pass")
	if len(users) != 2 {
		t.Fatalf("len(parseUsers) = %d, want 2", len(users))
	}
	if users[0].username != "device_pubsub" || users[0].password != "device-pass" {
		t.Fatalf("users[0] = %#v, want device_pubsub/device-pass", users[0])
	}
	if users[1].username != "producer_sub" || users[1].password != "producer-pass" {
		t.Fatalf("users[1] = %#v, want producer_sub/producer-pass", users[1])
	}
}

func TestValidUsername(t *testing.T) {
	tests := []struct {
		name     string
		username string
		want     bool
	}{
		{name: "plain", username: "mosquser", want: true},
		{name: "dash inside", username: "mosq-user", want: true},
		{name: "leading dash", username: "-D", want: false},
		{name: "slash", username: "mosq/user", want: false},
		{name: "backslash", username: `mosq\user`, want: false},
		{name: "colon", username: "mosq:user", want: false},
		{name: "space", username: "mosq user", want: false},
		{name: "tab", username: "mosq\tuser", want: false},
		{name: "newline", username: "mosq\nuser", want: false},
		{name: "carriage return", username: "mosq\ruser", want: false},
		{name: "null byte", username: "mosq\x00user", want: false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := validUsername(tt.username); got != tt.want {
				t.Fatalf("validUsername(%q) = %v, want %v", tt.username, got, tt.want)
			}
		})
	}
}

func TestValidPassword(t *testing.T) {
	tests := []struct {
		name     string
		password string
		want     bool
	}{
		{name: "symbols", password: "Password1!", want: true},
		{name: "spaces allowed", password: "correct horse battery staple", want: true},
		{name: "newline", password: "foo\nbar", want: false},
		{name: "carriage return", password: "foo\rbar", want: false},
		{name: "tab", password: "foo\tbar", want: false},
		{name: "null byte", password: "foo\x00bar", want: false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := validPassword(tt.password); got != tt.want {
				t.Fatalf("validPassword(%q) = %v, want %v", tt.password, got, tt.want)
			}
		})
	}
}
