package config

import (
	"fmt"
	"os"

	"github.com/gocql/gocql"
)

// ConnectAstraDB establishes connection to AstraDB
func ConnectAstraDB() (*gocql.Session, error) {
	// Get environment variables
	bundlePath := os.Getenv("ASTRA_DB_SECURE_BUNDLE_PATH")
	username := os.Getenv("ASTRA_DB_USERNAME")
	password := os.Getenv("ASTRA_DB_PASSWORD")
	keyspace := os.Getenv("ASTRA_DB_KEYSPACE")

	if bundlePath == "" || username == "" || password == "" || keyspace == "" {
		return nil, fmt.Errorf("missing required environment variables for AstraDB connection")
	}

	// Create cluster configuration
	cluster := gocql.NewCluster()
	cluster.Hosts = []string{} // Not needed for AstraDB with secure bundle
	cluster.Authenticator = gocql.PasswordAuthenticator{
		Username: username,
		Password: password,
	}
	cluster.SslOpts = &gocql.SslOptions{
		CaPath:                 bundlePath,
		EnableHostVerification: false,
	}
	cluster.Keyspace = keyspace
	cluster.Consistency = gocql.LocalQuorum

	// Create session
	session, err := cluster.CreateSession()
	if err != nil {
		return nil, fmt.Errorf("failed to create session: %v", err)
	}

	return session, nil
}
