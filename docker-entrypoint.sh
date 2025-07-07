#!/bin/sh
set -e

# If the command is keydb-server, drop privileges to keydb user
if [ "$1" = 'keydb-server' ]; then
    # Check if we have a config file as second argument
    if [ $# -eq 2 ] && [ -f "$2" ]; then
        # Traditional config file mode
        echo "Starting KeyDB with config file: $2"
        exec su-exec keydb "$@"
    else
        # Command-line arguments mode (production style)
        echo "Starting KeyDB with command-line arguments"
        exec su-exec keydb "$@"
    fi
fi

# Otherwise, run whatever was passed
exec "$@"

