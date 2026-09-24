#!/bin/bash
# Terminal content for the hero screenshot. bat's "ansi" theme colors through the
# terminal palette; the Xcode System bat theme maps scopes to the palette slots.
cd "$(dirname "$0")/../../sample/Landmarks"
clear
printf '\e[1m$\e[0m swift build\n'; swift build 2>&1 | tail -1
printf '\n\e[1m$\e[0m bat -r 7:24 Sources/Landmarks/Landmark.swift\n'
bat --theme="Xcode System" --style=numbers --color=always --paging=never -r 7:24 Sources/Landmarks/Landmark.swift
printf '\n'
for i in 0 1 2 3 4 5 6 7; do printf '\e[48;5;%dm    \e[0m' $i; done; printf '\n'
for i in 8 9 10 11 12 13 14 15; do printf '\e[48;5;%dm    \e[0m' $i; done; printf '\n\n'
printf '\e[1m$\e[0m '
