#!/usr/bin/env bash
set -a; source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.env"; set +a
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV=$ROOT_DIR/config/.env
echo "$ENV"

options=("Config" "Show" "Environment" "Deployment" "Update" "Docker" "Quit")
sel=0; n=${#options[@]}
menu_lines=$((n + 2)) # Total lines drawn by draw()

# Ensure cursor is restored on exit or interruption
cleanup() {
    tput cnorm
    echo
}
trap cleanup EXIT INT TERM

run_script() {
    clear; tput cnorm
    if [ -e "$ENV" ]; then
      (source $ENV && cd "$ROOT_DIR/$1" && ./go.sh)
    else
      (cd "$ROOT_DIR/config" && ./go.sh)
    fi
    echo; read -rp "Press Enter to return to the menu..."
    clear; tput civis
}

config()      { run_script config; }
show()        { run_script show; }
docker()      { run_script docker-optional; }
environment() { run_script environment; }
deployment()    { run_script endpoint; }
update()      { run_script update; }
quit()        { clear; tput cnorm; echo "Bye!"; exit 0; }

[ -e $ENV ] || run_script config

draw() {
    # Print header and clear lines in place (\033[K)
    printf "\033[KUse ↑ ↓ and Enter\n\033[K\n"
    for i in "${!options[@]}"; do
        if [[ $i -eq $sel ]]; then
            printf "\033[K\e[1;34m> %s\e[0m\n" "${options[$i]}"
        else
            printf "\033[K  %s\n" "${options[$i]}"
        fi
    done
}

# Initial clear and hide cursor
clear; tput civis

while true; do
    draw
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key
        [[ $key == "[A" ]] && ((sel = (sel - 1 + n) % n))
        [[ $key == "[B" ]] && ((sel = (sel + 1) % n))
    elif [[ $key =~ ^[qQ]$ ]]; then
        quit
    elif [[ -z $key ]]; then
        "${options[$sel],,}"
    fi
    
    # Move cursor back up to the menu start position (avoids clearing screen)
    printf "\033[%dA" "$menu_lines"
done

