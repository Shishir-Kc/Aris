#!/bin/bash
# Display custom Fastfetch logo at login
if command -v fastfetch &> /dev/null; then
    fastfetch --config /usr/share/aris/aris.txt
fi

