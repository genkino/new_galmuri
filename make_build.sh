#!/bin/bash
./bump_build.sh
flutter build ipa
flutter build apk

git add .
git commit -m 'make binary'
git push