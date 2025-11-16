package config

import (
	"fmt"
	"os"

	"github.com/gocql/gocql"
)

// ConnectAstraDB establishes connection to AstraDB using token and endpoint
func ConnectAstraDB() (*gocql.Session, error) {
	// Get environment variables
	token := os.Getenv("ASTRA_DB_TOKEN")
	endpoint := os.Getenv("ASTRA_DB_ENDPOINT")

	if token == "" || endpoint == "" {
		return nil, fmt.Errorf("missing required environment variables: ASTRA_DB_TOKEN or ASTRA_DB_ENDPOINT")
	}

	// Create cluster configuration for AstraDB
	cluster := gocql.NewCluster(endpoint)
	cluster.Authenticator = gocql.PasswordAuthenticator{
		Username: "token",
		Password: token,
	}
	cluster.Consistency = gocql.LocalQuorum

	// Create session
	session, err := cluster.CreateSession()
	if err != nil {
		return nil, fmt.Errorf("failed to create session: %v", err)
	}

	return session, nil
}
