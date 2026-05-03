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
	users := os.Getenv("MOSQUITTO_USERS")

	// Clear sensitive env vars as early as possible
	os.Unsetenv("MOSQUITTO_USERNAME")
	os.Unsetenv("MOSQUITTO_PASSWORD")
	os.Unsetenv("MOSQUITTO_USERS")

	switch {
	case users != "":
		if username != "" || password != "" {
			log.Fatal("MOSQUITTO_USERS cannot be combined with MOSQUITTO_USERNAME/MOSQUITTO_PASSWORD")
		}
		log.Println("Configuring authentication for multiple users")
		if err := createPasswordFile(parseUsers(users)); err != nil {
			log.Fatal(err)
		}
	case username != "" && password != "":
		log.Println("Configuring authentication")
		if err := createPasswordFile([]mqttUser{{username: username, password: password}}); err != nil {
			log.Fatal(err)
		}
	case username != "" || password != "":
		log.Fatal("Both MOSQUITTO_USERNAME and MOSQUITTO_PASSWORD must be set, got only one")
	default:
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

type mqttUser struct {
	username string
	password string
}

func parseUsers(raw string) []mqttUser {
	entries := strings.Split(raw, ",")
	users := make([]mqttUser, 0, len(entries))
	for _, entry := range entries {
		entry = strings.TrimSpace(entry)
		if entry == "" {
			continue
		}
		username, password, found := strings.Cut(entry, ":")
		if !found {
			log.Fatal("MOSQUITTO_USERS entries must use username:password format")
		}
		users = append(users, mqttUser{username: username, password: password})
	}
	if len(users) == 0 {
		log.Fatal("MOSQUITTO_USERS must contain at least one username:password entry")
	}
	return users
}

func createPasswordFile(users []mqttUser) error {
	passwordFile := "/mosquitto/passwd/password_file"

	if err := os.MkdirAll("/mosquitto/passwd", 0700); err != nil {
		return fmt.Errorf("failed to create password directory: %w", err)
	}
	if err := os.Remove(passwordFile); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to remove existing password file: %w", err)
	}

	for i, user := range users {
		if !validUsername(user.username) {
			return fmt.Errorf("MOSQUITTO username %q contains invalid characters", user.username)
		}
		if !validPassword(user.password) {
			return fmt.Errorf("MOSQUITTO password for username %q contains invalid control characters", user.username)
		}

		args := []string{passwordFile, user.username}
		if i == 0 {
			args = append([]string{"-c"}, args...)
		}

		// Use stdin to pass password, avoiding exposure in process listing
		cmd := exec.Command("mosquitto_passwd", args...)
		cmd.Stdin = strings.NewReader(fmt.Sprintf("%s\n%s\n", user.password, user.password))
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to set password for username %q: %w", user.username, err)
		}
	}

	if err := os.Chmod(passwordFile, 0600); err != nil {
		return fmt.Errorf("failed to chmod password file: %w", err)
	}
	return nil
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
