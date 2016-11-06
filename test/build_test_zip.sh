#!/usr/bin/env bash

# Usage: ./build_test_zip

# Make a test directory
mkdir test

# Copy in .js, .json files and node_modules folder
cp *.js test
cp *.json test
cp -r node_modules test

# Zip it
zip test.zip test/*

# Delete the test directory
rm -rf test