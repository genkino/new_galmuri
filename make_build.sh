#!/bin/bash
./bump_build.sh
flutter build ipa
flutter build appbundle

git add .
git commit -m 'make binary'
git push