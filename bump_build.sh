#!/bin/bash

# 현재 build number 읽기
version_line=$(grep '^version:' pubspec.yaml)
current_build=$(echo $version_line | cut -d'+' -f2)
new_build=$((current_build + 1))

# 새 버전으로 대체
new_version_line=$(echo $version_line | sed "s/+${current_build}/+${new_build}/")
sed -i '' "s/^version:.*/${new_version_line}/" pubspec.yaml

echo "Updated build number: $current_build → $new_build"
