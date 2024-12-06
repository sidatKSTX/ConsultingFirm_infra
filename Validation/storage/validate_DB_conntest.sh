#!/bin/bash

# Source variables
source rds_variables.env

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Testing Database Connectivity..."
echo "-------------------------------"

# Function to test PostgreSQL connection
test_db_connection() {
    echo -e "${YELLOW}Testing PostgreSQL connection...${NC}"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_ENDPOINT \
                                -p $DB_PORT \
                                -U $DB_USER \
                                -d $DB_NAME \
                                -c "SELECT 1" > /dev/null 2>&1
    
    PSQL_RESULT=$?

    if [ $PSQL_RESULT -eq 0 ]; then
        echo -e "${GREEN}✓ PostgreSQL connection successful${NC}"
        
        # Get connection details
        echo -e "\n${YELLOW}Connection Details:${NC}"
        PGPASSWORD=$DB_PASSWORD psql -h $DB_ENDPOINT \
                                    -p $DB_PORT \
                                    -U $DB_USER \
                                    -d $DB_NAME \
                                    -c "\conninfo"
        
        # Test database version
        echo -e "\n${YELLOW}Database Version:${NC}"
        PGPASSWORD=$DB_PASSWORD psql -h $DB_ENDPOINT \
                                    -p $DB_PORT \
                                    -U $DB_USER \
                                    -d $DB_NAME \
                                    -c "SELECT version();"
    else
        echo -e "${RED}✗ PostgreSQL connection failed${NC}"
        return 1
    fi
}

# Function to validate connection parameters
validate_connection_params() {
    local errors=0

    echo "Validating connection parameters..."
    
    # Validate endpoint format
    if [[ ! $DB_ENDPOINT =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+$ ]]; then
        echo -e "${RED}✗ Invalid endpoint format${NC}"
        errors=$((errors+1))
    else
        echo -e "${GREEN}✓ Endpoint format valid${NC}"
    fi

    # Validate port
    if ! [[ $DB_PORT =~ ^[0-9]+$ ]] || [ $DB_PORT -lt 1 ] || [ $DB_PORT -gt 65535 ]; then
        echo -e "${RED}✗ Invalid port number${NC}"
        errors=$((errors+1))
    else
        echo -e "${GREEN}✓ Port number valid${NC}"
    fi

    # Validate database name
    if [ -z "$DB_NAME" ]; then
        echo -e "${RED}✗ Database name is empty${NC}"
        errors=$((errors+1))
    else
        echo -e "${GREEN}✓ Database name provided${NC}"
    fi

    # Validate username
    if [ -z "$DB_USER" ]; then
        echo -e "${RED}✗ Username is empty${NC}"
        errors=$((errors+1))
    else
        echo -e "${GREEN}✓ Username provided${NC}"
    fi

    return $errors
}

# Main execution
echo -e "${YELLOW}Step 1: Validating Parameters${NC}"
validate_connection_params
VALIDATION_RESULT=$?

if [ $VALIDATION_RESULT -eq 0 ]; then
    echo -e "\n${YELLOW}Step 2: Testing Connection${NC}"
    test_db_connection
    CONNECTION_RESULT=$?
    
    if [ $CONNECTION_RESULT -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed successfully!${NC}"
        exit 0
    else
        echo -e "\n${RED}Connection test failed!${NC}"
        exit 1
    fi
else
    echo -e "\n${RED}Parameter validation failed! Please check your configuration.${NC}"
    exit 1
fi
