package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

func getHealth(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "OK")
}

func fileHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	data, err := os.ReadFile("./version.txt")
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading file: %v", err), http.StatusInternalServerError)
		return
	}

	hostname, _ := os.Hostname()

	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprintf(w, "Version: %s\nHostname: %s\nTime: %s\n",
		strings.TrimSpace(string(data)), hostname, time.Now().Format(time.RFC3339))
}

func main() {
	http.HandleFunc("/healthz", getHealth)
	http.HandleFunc("/version", fileHandler)

	log.Println("Server starting on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}