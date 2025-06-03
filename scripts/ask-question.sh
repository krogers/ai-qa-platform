#!/bin/bash

# AI Q&A Platform - Interactive Question Client
# Usage: ./ask-question.sh

# Configuration
API_URL="https://oottikhn07.execute-api.us-east-1.amazonaws.com/dev/graphql"
USER_ID="550e8400-e29b-41d4-a716-446655440000"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display header
show_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    AI Q&A Platform                          ║${NC}"
    echo -e "${BLUE}║                Ask questions about Kevin Rogers              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to ask a question
ask_question() {
    local question="$1"
    
    # Escape quotes for JSON
    question=$(echo "$question" | sed 's/"/\\"/g')
    
    # Build GraphQL query
    local query="{\"query\":\"mutation { askQuestion(input: { text: \\\"$question\\\", userId: \\\"$USER_ID\\\" }) { id questionId text timestamp } }\"}"
    
    echo -e "${YELLOW}🤔 Thinking...${NC}"
    echo ""
    
    # Make API call
    response=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "$query")
    
    # Check if response contains errors
    if echo "$response" | grep -q '"errors"'; then
        echo -e "${RED}❌ Error occurred:${NC}"
        echo "$response" | jq -r '.errors[0].message' 2>/dev/null || echo "$response"
        return 1
    fi
    
    # Extract and display only the answer
    local answer=$(echo "$response" | jq -r '.data.askQuestion.text' 2>/dev/null)
    
    if [ "$answer" != "null" ] && [ -n "$answer" ]; then
        echo -e "${GREEN}💬 Answer:${NC}"
        echo "$answer"
    else
        echo -e "${RED}❌ Failed to get a valid response${NC}"
        echo "Raw response: $response"
        return 1
    fi
}

# Function for interactive mode
interactive_mode() {
    show_header
    echo -e "${GREEN}Interactive mode - Type your questions (or 'quit' to exit)${NC}"
    echo ""
    
    while true; do
        echo -e "${YELLOW}❓ Your question:${NC}"
        read -r question
        
        # Check for exit commands
        if [[ "$question" =~ ^(quit|exit|q)$ ]]; then
            echo -e "${BLUE}👋 Goodbye!${NC}"
            break
        fi
        
        # Skip empty questions
        if [ -z "$question" ]; then
            continue
        fi
        
        echo ""
        ask_question "$question"
        echo ""
        echo "────────────────────────────────────────────────────────────────"
        echo ""
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [question]"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive mode"
    echo "  $0 \"Who is Kevin Rogers?\"             # Single question"
    echo "  $0 \"What is Kevin's background?\"     # Another question"
    echo ""
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ Error: 'jq' is required but not installed.${NC}"
    echo "Please install jq: brew install jq"
    exit 1
fi

# Main script logic
if [ $# -eq 0 ]; then
    # No arguments - run interactive mode
    interactive_mode
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    # Show help
    show_usage
else
    # Single question mode
    show_header
    echo -e "${YELLOW}❓ Question: $1${NC}"
    echo ""
    ask_question "$1"
fi