package db

import (
	"database/sql"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func Init(dsn string) error {
	var err error
	DB, err = sql.Open("sqlite", dsn)
	if err != nil {
		return err
	}

	schema := `
	CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
	CREATE TABLE IF NOT EXISTS websites (id INTEGER PRIMARY KEY AUTOINCREMENT, domain TEXT UNIQUE NOT NULL, php_version TEXT NOT NULL DEFAULT '8.2', document_root TEXT NOT NULL, ssl_enabled INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'active', created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
	CREATE TABLE IF NOT EXISTS databases (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE NOT NULL, db_user TEXT NOT NULL, website_id INTEGER, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
	CREATE TABLE IF NOT EXISTS ssl_certs (id INTEGER PRIMARY KEY AUTOINCREMENT, domain TEXT UNIQUE NOT NULL, issued_at DATETIME, expires_at DATETIME, auto_renew INTEGER DEFAULT 1);
	CREATE TABLE IF NOT EXISTS backups (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL, size_bytes INTEGER, path TEXT NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
	CREATE TABLE IF NOT EXISTS cron_jobs (id INTEGER PRIMARY KEY AUTOINCREMENT, schedule TEXT NOT NULL, command TEXT NOT NULL, enabled INTEGER DEFAULT 1, last_run DATETIME, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
	`
	_, err = DB.Exec(schema)
	return err
}
