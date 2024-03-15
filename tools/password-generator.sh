#!/bin/sh
password=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 16)
echo "pass: $password"
echo "base64: "$(echo -n $password|base64)