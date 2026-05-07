#!/bin/bash
cd /Users/amitay/tripi/tripi_app
flutter build web --release --no-wasm-dry-run
firebase deploy --only hosting
