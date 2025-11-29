#!/bin/bash
# Kali Linux Docker - GUI Application Launcher
# Launches GUI applications from the Kali container on the host display
#
# Usage:
#   ./kali-gui.sh ghidra        # Launch Ghidra
#   ./kali-gui.sh burpsuite     # Launch Burp Suite
#   ./kali-gui.sh wireshark     # Launch Wireshark
#   ./kali-gui.sh xterm         # Launch xterm

set -e

# Container name
CONTAINER="kali-pentesting"

# Check if container is running
if ! docker ps | grep -q "$CONTAINER"; then
  echo "Error: Container '$CONTAINER' is not running"
  echo "Start it with: docker compose up -d"
  exit 1
fi

# Ensure xauth file exists
if [ ! -f /tmp/kali-xauth ]; then
  echo "Generating xauth credentials..."

  # Get the X11 magic cookie
  COOKIE=$(xauth list | grep ":0" | awk '{print $3}' | head -1)

  if [ -z "$COOKIE" ]; then
    echo "Error: Could not extract X11 magic cookie"
    echo "Make sure X11 is running: DISPLAY=$DISPLAY"
    exit 1
  fi

  # Create xauth file with multiple entries for compatibility
  xauth -f /tmp/kali-xauth add "localhost:0" MIT-MAGIC-COOKIE-1 "$COOKIE"
  xauth -f /tmp/kali-xauth add "localhost/unix:0" MIT-MAGIC-COOKIE-1 "$COOKIE"
  xauth -f /tmp/kali-xauth add "unix:0" MIT-MAGIC-COOKIE-1 "$COOKIE"
  xauth -f /tmp/kali-xauth add ":0" MIT-MAGIC-COOKIE-1 "$COOKIE"

  chmod 644 /tmp/kali-xauth
  echo "✓ Generated xauth file at /tmp/kali-xauth"
fi

# Get the application to launch
APP="${1:-ghidra}"

# Launch the application
echo "Launching $APP..."
docker exec -d "$CONTAINER" bash -c "
  export DISPLAY=:0
  export XAUTHORITY=/root/.Xauthority
  $APP &
" 2>&1

echo "✓ $APP launched"
echo ""
echo "Application should appear on host display (DISPLAY=$DISPLAY)"
echo "If it doesn't appear, check container logs:"
echo "  docker logs -f $CONTAINER"
