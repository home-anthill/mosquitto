package main

import (
	"fmt"
	"os"
	"os/exec"
	"syscall"
	"time"
)

func main() {
	username := os.Getenv("MOSQUITTO_USERNAME")
	password := os.Getenv("MOSQUITTO_PASSWORD")

	if username != "" && password != "" {
		fmt.Println("Configuring authentication")
		passwordFile := "/mosquitto/passwd/password_file"
		cmd := exec.Command("mosquitto_passwd", "-b", "-c", passwordFile, username, password)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to set password: %v\n", err)
			os.Exit(1)
		}
		if err := os.Chmod(passwordFile, 0600); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to chmod password file: %v\n", err)
			os.Exit(1)
		}
	} else {
		fmt.Println("Skipping authentication")
	}

	time.Sleep(10 * time.Second)

	mosquittoPath, err := exec.LookPath("mosquitto")
	if err != nil {
		fmt.Fprintf(os.Stderr, "mosquitto not found: %v\n", err)
		os.Exit(1)
	}

	args := []string{"mosquitto", "-c", "/mosquitto/config/mosquitto.conf"}
	if err := syscall.Exec(mosquittoPath, args, os.Environ()); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to exec mosquitto: %v\n", err)
		os.Exit(1)
	}
}
