#!/bin/bash

# Script for simultaneous development of Rails API and React Frontend
# Ballast Lane Technical Review

echo "🚀 Starting Ballast Lane Technical Review development..."

# Function to clean up processes on exit
cleanup() {
    echo "🛑 Stopping servers..."
    kill $RAILS_PID $REACT_PID 2>/dev/null
    exit 0
}

# Capture Ctrl+C
trap cleanup SIGINT

# Check that we are in the correct directory
if [ ! -f "Gemfile" ]; then
    echo "❌ Error: Gemfile not found. Make sure you are in the project root directory."
    exit 1
fi

# Check that PostgreSQL is running
if ! pg_isready -q; then
    echo "❌ Error: PostgreSQL is not running. Please start PostgreSQL first."
    exit 1
fi

# Check that the database exists
if ! rails db:version >/dev/null 2>&1; then
    echo "📦 Setting up database..."
    rails db:create
    rails db:migrate
fi

# Start Rails server in background
echo "🔧 Starting Rails API server at http://localhost:3001..."
rails server -p 3001 &
RAILS_PID=$!

# Wait a moment for Rails to start
sleep 3

# Check that Rails is running
if ! curl -s http://localhost:3001/api/health/index >/dev/null; then
    echo "❌ Error: Could not connect to Rails server. Check the logs."
    exit 1
fi

echo "✅ Rails API server started successfully!"

# Start React server in background
echo "⚛️  Starting React server at http://localhost:5173..."
cd frontend
npm run dev &
REACT_PID=$!
cd ..

# Wait a moment for React to start
sleep 5

echo ""
echo "🎉 Development started successfully!"
echo ""
echo "📱 Frontend React: http://localhost:5173"
echo "🔧 Backend Rails API: http://localhost:3001"
echo "🏥 Health Check: http://localhost:3001/api/health/index"
echo ""
echo "Press Ctrl+C to stop both servers"
echo ""

# Keep the script running
wait 