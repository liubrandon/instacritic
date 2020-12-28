#!/bin/zsh
# This script pushes the updated source to liubrandon/instacritic,
# builds a release version for web, then pushes it to the Github page.
BUILD_TIME=$( date '+%F_%H:%M:%S' )
git add .
git commit -m $1
git push
sed -i '' 's#"/"#"/instacritic/"#' web/index.html # Set relative path href base
flutter build web --dart-define=APP_VERSION=$BUILD_TIME --release
pushd build/web
git add .
git commit -m $1
git push
popd
sed -i '' 's#"/instacritic/"#"/"#' web/index.html # Undo relative path href base
printf "Build $BUILD_TIME\n"