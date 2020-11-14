#!/usr/bin/env bash

v -prod -os windows -o prune_win build main.v
v -prod -os macos -o prune_osx build main.v
v -prod -os linux -o prune_linux build main.v