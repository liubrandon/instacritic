#!/bin/zsh
# This script pushes the updated source to liubrandon/instacritic,
# builds a release version for web, then pushes it to the Github page.

# First save build time and push source code
BUILD_TIME=$( date '+%F_%H:%M' )
git add .
git commit -m $1
git push

# Backup .git in build/web
cp -r build/web/.git ./temp/.git

# Then build the app for my site and push it
sed -i '' 's#"/"#"/instacritic/"#' web/index.html # Set relative path href base
flutter build web --dart-define=APP_VERSION=$BUILD_TIME --release
cp -r ./temp/.git build/web/.git
pushd build/web
git add .
git commit -m $1
git push origin gh-pages
popd
sed -i '' 's#"/instacritic/"#"/"#' web/index.html # Undo relative path href base

# Then build the app for Meghna's site and push it
sed -i '' 's#"/"#"/asiayum/"#' web/index.html # Set relative path href base
flutter build web --dart-define=APP_VERSION=$BUILD_TIME --dart-define=USERNAME='asia.yum' --release
cp -r ./temp/.git build/web/.git
pushd build/web
git add .
git commit -m $1
git push instacritic-asiayum gh-pages
popd
sed -i '' 's#"/asiayum/"#"/"#' web/index.html # Undo relative path href base
printf "Build $BUILD_TIME\n"

rm -rf ./temp