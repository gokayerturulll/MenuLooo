#!/bin/sh
set -e

node migrations/run.js
exec node server.js
