#!/usr/bin/env bash
# Attach ble.sh after all integrations and key bindings have been configured.

if [[ ${BLE_VERSION-} ]]; then
  ble-attach
fi
