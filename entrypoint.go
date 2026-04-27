package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"syscall"
	"unicode"
)

func main() {
	username := os.Getenv("MOSQUITTO_USERNAME")
	password := os.Getenv("MOSQUITTO_PASSWORD")

	// Clear sensitive env vars as early as possible
	os.Unsetenv("MOSQUITTO_USERNAME")
	os.Unsetenv("MOSQUITTO_PASSWORD")

	if username != "" && password != "" {
		if !validUsername(username) {
			log.Fatal("MOSQUITTO_USERNAME contains invalid characters")
		}
		if !validPassword(password) {
			log.Fatal("MOSQUITTO_PASSWORD contains invalid control characters")
		}

		log.Println("Configuring authentication")
		passwordFile := "/mosquitto/passwd/password_file"

		if err := os.MkdirAll("/mosquitto/passwd", 0700); err != nil {
			log.Fatalf("Failed to create password directory: %v", err)
		}

		// Use stdin to pass password, avoiding exposure in process listing
		cmd := exec.Command("mosquitto_passwd", "-c", passwordFile, username)
		cmd.Stdin = strings.NewReader(fmt.Sprintf("%s\n%s\n", password, password))
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			log.Fatalf("Failed to set password: %v", err)
		}
		if err := os.Chmod(passwordFile, 0600); err != nil {
			log.Fatalf("Failed to chmod password file: %v", err)
		}
	} else if username != "" || password != "" {
		log.Fatal("Both MOSQUITTO_USERNAME and MOSQUITTO_PASSWORD must be set, got only one")
	} else {
		log.Println("Skipping authentication")
	}

	mosquittoPath, err := exec.LookPath("mosquitto")
	if err != nil {
		log.Fatalf("mosquitto not found: %v", err)
	}

	args := []string{"mosquitto", "-c", "/mosquitto/config/mosquitto.conf"}
	if err := syscall.Exec(mosquittoPath, args, os.Environ()); err != nil {
		log.Fatalf("Failed to exec mosquitto: %v", err)
	}
}

func validUsername(username string) bool {
	if strings.HasPrefix(username, "-") || strings.ContainsAny(username, "/\\:") {
		return false
	}
	for _, r := range username {
		if unicode.IsControl(r) || unicode.IsSpace(r) {
			return false
		}
	}
	return true
}

func validPassword(password string) bool {
	for _, r := range password {
		if unicode.IsControl(r) {
			return false
		}
	}
	return true
}
