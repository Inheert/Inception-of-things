#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
#  Usage:  ./display.sh [scriptfile.sh]
#  All settings can also be overridden via env vars:
#    BOX_X=10 BOX_Y=5 ./display.sh myscript.sh
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ASCII_FILE="${1:-${ASCII_FILE:-$SCRIPT_DIR/asciiart.txt}}"
PRODUCER="${2:-${PRODUCER:-$SCRIPT_DIR/producer.sh}}"
PRODUCER_ARGS=("${@:3}")    # all arguments after $2 are forwarded to the producer

# Box position (1-indexed terminal rows/columns)
BOX_X="${BOX_X:-1}"
BOX_Y="${BOX_Y:-9}"

# Box dimensions (inner area — does not include the border)
BOX_W="${BOX_W:-75}"       # inner width  (characters per line)
BOX_H="${BOX_H:-20}"       # inner height (number of content lines)

# Title shown centered in the top border (set to "" to disable)
BOX_TITLE="${BOX_TITLE:- Status }"

# Log file (set to "" to disable)
LOG_FILE="${LOG_FILE:-$SCRIPT_DIR/../logs/display.log}"

# Colors (ANSI escape codes — set any to "" to disable)
C_BORDER="\033[1;36m"      # box border:  bold cyan
C_TITLE="\033[1;33m"       # box title:   bold yellow
C_TEXT="\033[0;97m"        # content text: bright white
C_RESET="\033[0m"

# Box drawing characters (swap for ASCII if UTF-8 isn't supported)
TL="┌" TR="┐" BL="└" BR="┘" H="─" V="│"

# ═══════════════════════════════════════════════════════════════════
#  Helpers
# ═══════════════════════════════════════════════════════════════════

move()       { printf "\033[%d;%dH" "$1" "$2"; }
strip_ansi() { printf '%s' "$1" | sed 's/\x1b\[[0-9;]*[mKHJA-Z]//g'; }
hline()      { printf '%0.s'"$H" $(seq 1 "$BOX_W"); }

# ═══════════════════════════════════════════════════════════════════
#  Border — drawn once; stream_to_box only touches the inner cells
# ═══════════════════════════════════════════════════════════════════

draw_border() {
    # Top border with optional centered title
    move "$BOX_Y" "$BOX_X"
    printf "${C_BORDER}${TL}"
    if [[ -n "$BOX_TITLE" ]]; then
        local tlen=${#BOX_TITLE}
        local left=$(( (BOX_W - tlen) / 2 ))
        local right=$(( BOX_W - tlen - left ))
        printf '%0.s'"$H" $(seq 1 $left)
        printf "${C_TITLE}%s${C_BORDER}" "$BOX_TITLE"
        printf '%0.s'"$H" $(seq 1 $right)
    else
        hline
    fi
    printf "${TR}${C_RESET}"

    # Side borders + clear inner area
    local i
    for (( i = 0; i < BOX_H; i++ )); do
        move $(( BOX_Y + 1 + i )) "$BOX_X"
        printf "${C_BORDER}${V}${C_RESET}"
        printf "%${BOX_W}s" ""
        printf "${C_BORDER}${V}${C_RESET}"
    done

    # Bottom border
    move $(( BOX_Y + 1 + BOX_H )) "$BOX_X"
    printf "${C_BORDER}${BL}"
    hline
    printf "${BR}${C_RESET}"
}

# ═══════════════════════════════════════════════════════════════════
#  Render one row of content inside the box (does not touch borders)
# ═══════════════════════════════════════════════════════════════════

render_row() {
    local row="$1" text="$2"
    local plain
    plain=$(strip_ansi "$text")

    # Truncate to inner width
    if (( ${#plain} > BOX_W )); then
        text="${plain:0:$BOX_W}"
        plain="$text"
    fi

    local pad=$(( BOX_W - ${#plain} ))
    move $(( BOX_Y + 1 + row )) $(( BOX_X + 1 ))
    printf "${C_TEXT}%s%${pad}s${C_RESET}" "$text" ""
}

# ═══════════════════════════════════════════════════════════════════
#  Stream producer output into the box live, char by char.
#  \n  → commit line, advance to next row (scroll when full)
#  \r  → overwrite current row in place (Docker-style progress)
# ═══════════════════════════════════════════════════════════════════

stream_to_box() {
    local -a buf
    local cur_row=0 cur_text="" char

    # Pre-fill buffer with empty strings
    for (( i = 0; i < BOX_H; i++ )); do buf[$i]=""; done

    while IFS= read -r -d '' -n1 char 2>/dev/null; do
        case "$char" in
            $'\n')
                buf[$cur_row]="$cur_text"
                render_row "$cur_row" "$cur_text"
                [[ -n "$LOG_FILE" ]] && printf '%s\n' "$(strip_ansi "$cur_text")" >> "$LOG_FILE"
                cur_text=""
                cur_row=$(( cur_row + 1 ))

                # Scroll: shift buffer up when box is full
                if (( cur_row >= BOX_H )); then
                    buf=("${buf[@]:1}" "")
                    cur_row=$(( BOX_H - 1 ))
                    for (( i = 0; i < BOX_H; i++ )); do
                        render_row "$i" "${buf[$i]}"
                    done
                fi
                ;;
            $'\r')
                # Overwrite current row without advancing
                buf[$cur_row]="$cur_text"
                render_row "$cur_row" "$cur_text"
                cur_text=""
                ;;
            *)
                cur_text+="$char"
                ;;
        esac
    done < <(bash "$PRODUCER" "${PRODUCER_ARGS[@]}" 2>&1)

    # Flush any trailing text without a final newline
    if [[ -n "$cur_text" ]]; then
        render_row "$cur_row" "$cur_text"
    fi
}

# ═══════════════════════════════════════════════════════════════════
#  Main
# ═══════════════════════════════════════════════════════════════════

main() {
    clear
    tput civis 2>/dev/null

    if [[ -n "$LOG_FILE" ]]; then
        mkdir -p "$(dirname "$LOG_FILE")"
        printf '=== %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    fi

    [[ -f "$ASCII_FILE" ]] && cat "$ASCII_FILE"

    draw_border
    stream_to_box

    move $(( BOX_Y + BOX_H + 3 )) 1
    tput cnorm 2>/dev/null
    echo
}

main
