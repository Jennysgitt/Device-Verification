#!/bin/bash

# Navigate to the ai-backend directory
cd "$(dirname "$0")"

# Activate virtual environment
source venv/bin/activate

# Start the server
echo "🚀 Starting SecureGate AI Backend..."
echo "📍 Server will be available at: http://localhost:8000"
echo "📖 API docs will be available at: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

python3 main.py

