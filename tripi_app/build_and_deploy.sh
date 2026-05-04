#!/bin/bash
flutter build web --release --no-wasm-dry-run
firebase deploy --only hosting
