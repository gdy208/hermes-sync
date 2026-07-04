#!/bin/bash
# Bascule vers le profil english et redémarre le gateway
# Exécuté par cron (processus indépendant du gateway)
hermes profile use english
sleep 2
systemctl --user restart hermes-gateway
