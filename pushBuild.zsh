#!/bin/zsh
# This script pushes the updated source to liubrandon/instacritic,
# builds a release version for web, then pushes it to the Github page.

# First save build time and push source code
BUILD_TIME=$( date '+%Y%m%d.%H%M' )
git add .
git commit -m $1
git push

# Then build the app for my site and push it
sed -i '' 's#"/"#"/instacritic/"#' web/index.html # Set relative path href base
flutter build web --dart-define=APP_VERSION=$BUILD_TIME --release
pushd build/web
git init
git remote add unagibrandon git@github.com:liubrandon/instacritic.git
git checkout -b gh-pages
git add .
git commit -m $1 --quiet
git push -f unagibrandon gh-pages
popd
sed -i '' 's#"/instacritic/"#"/"#' web/index.html # Undo relative path href base

# Then build the app for Meghna's site and push it
sed -i '' 's#"/"#"/asiayum/"#' web/index.html # Set relative path href base
flutter build web --dart-define=APP_VERSION=$BUILD_TIME --dart-define=USERNAME='asia.yum' --release
pushd build/web
git init
git remote add asiayum git@github.com:instacritic/asiayum.git
git checkout -b gh-pages
git add .
git commit -m $1 --quiet
git push -f asiayum gh-pages
popd
sed -i '' 's#"/asiayum/"#"/"#' web/index.html # Undo relative path href base
printf "Build $BUILD_TIME\n"