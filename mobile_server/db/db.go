package db

import (
	"database/sql"
	"log"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

func Connect() {
	dsn := os.Getenv("DB_DSN")
	if dsn == "" {
		// Unix socket orqali ulanish (MariaDB local)
		dsn = "wikki@unix(/tmp/mysql.sock)/calculator?parseTime=true"
	}

	var err error
	DB, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatalf("❌ DB ochib bo'lmadi: %v", err)
	}

	if err = DB.Ping(); err != nil {
		log.Fatalf("❌ DB ga ulanib bo'lmadi: %v", err)
	}

	// Make sure tables exist
	_, err = DB.Exec(`
		CREATE TABLE IF NOT EXISTS products (
			id INT AUTO_INCREMENT PRIMARY KEY,
			name VARCHAR(255) NOT NULL,
			price DECIMAL(10, 2) NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		log.Fatalf("❌ Products jadvalini yaratib bo'lmadi: %v", err)
	}

	_, err = DB.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id INT AUTO_INCREMENT PRIMARY KEY,
			first_name VARCHAR(255) NOT NULL,
			last_name VARCHAR(255) NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		log.Fatalf("❌ Users jadvalini yaratib bo'lmadi: %v", err)
	}

	_, err = DB.Exec(`
		CREATE TABLE IF NOT EXISTS records (
			id INT AUTO_INCREMENT PRIMARY KEY,
			user_id INT NOT NULL,
			product_id INT NOT NULL,
			quantity DECIMAL(10,2) NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
			FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
		)
	`)
	if err != nil {
		log.Fatalf("❌ Records jadvalini yaratib bo'lmadi: %v", err)
	}

	log.Println("✅ MySQL ga muvaffaqiyatli ulandi!")
}
