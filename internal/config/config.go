package config

import (
	"crypto/rand"
	"encoding/hex"
	"os"
)

type Config struct {
	Port       string
	DataDir    string
	BackupDir  string
	WebRoot    string
	DBPath     string
	AdminEmail string
	SecretKey  string
}

func Load() *Config {
	cfg := &Config{
		Port:      getEnv("MICROCP_PORT", "8080"),
		DataDir:   getEnv("MICROCP_DATA", "/var/lib/microcp"),
		BackupDir: getEnv("MICROCP_BACKUP", "/backup"),
		WebRoot:   getEnv("MICROCP_WEBROOT", "/var/www"),
		DBPath:    getEnv("MICROCP_DB", "/var/lib/microcp/microcp.db"),
		SecretKey: getEnv("MICROCP_SECRET", generateSecret()),
	}
	
	// Ensure directories exist
	os.MkdirAll(cfg.DataDir, 0755)
	os.MkdirAll(cfg.BackupDir, 0755)
	os.MkdirAll(cfg.WebRoot, 0755)
	
	return cfg
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func generateSecret() string {
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}
