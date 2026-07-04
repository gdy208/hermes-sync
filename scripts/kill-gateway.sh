#!/bin/bash
# Tue le process gateway - systemd le relance automatiquement (Restart=always)
pkill -f "hermes_cli.main gateway run" 2>/dev/null || true
