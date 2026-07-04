#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/0
systemctl --user restart hermes-gateway
sleep 2
systemctl --user is-active hermes-gateway
