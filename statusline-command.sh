#!/usr/bin/env bash
# Claude Code status line script

input=$(cat)

# --- Extract fields ---
model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
version=$(echo "$input" | jq -r '.version // ""')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
RATE_CACHE="/tmp/.claude-rate-limits-cache.json"
has_rate_limits=$(echo "$input" | jq -r 'has("rate_limits")')
if [ "$has_rate_limits" = "true" ]; then
  echo "$input" | jq '{rate_limits}' > "$RATE_CACHE" 2>/dev/null
  five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
  five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  seven_d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
  seven_d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
elif [ -f "$RATE_CACHE" ]; then
  five_h_pct=$(jq -r '.rate_limits.five_hour.used_percentage // empty' "$RATE_CACHE")
  five_h_reset=$(jq -r '.rate_limits.five_hour.resets_at // empty' "$RATE_CACHE")
  seven_d_pct=$(jq -r '.rate_limits.seven_day.used_percentage // empty' "$RATE_CACHE")
  seven_d_reset=$(jq -r '.rate_limits.seven_day.resets_at // empty' "$RATE_CACHE")
else
  five_h_pct=""
  five_h_reset=""
  seven_d_pct=""
  seven_d_reset=""
fi

# --- ANSI colors ---
RESET="\033[0m"
BOLD="\033[1m"

FG_GREEN="\033[32m"
FG_YELLOW="\033[33m"
FG_RED="\033[31m"
FG_CYAN="\033[36m"
FG_BRIGHT_WHITE="\033[97m"
FG_GRAY="\033[90m"
FG_LIGHT_GRAY="\033[38;5;249m"
FG_ORANGE="\033[38;5;208m"

BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_RED="\033[41m"
BG_DARK="\033[100m"

# --- Progress bar ---
BAR_WIDTH=10

if [ -n "$used_pct" ]; then
  pct_int=$(printf "%.0f" "$used_pct")

  if [ "$pct_int" -ge 75 ]; then
    BAR_COLOR="$BG_RED"
    PCT_COLOR="$FG_RED"
  elif [ "$pct_int" -ge 60 ]; then
    BAR_COLOR="$BG_YELLOW"
    PCT_COLOR="$FG_YELLOW"
  else
    BAR_COLOR="$BG_GREEN"
    PCT_COLOR="$FG_GREEN"
  fi

  filled=$(( pct_int * BAR_WIDTH / 100 ))
  [ "$filled" -eq 0 ] && [ "$pct_int" -ge 1 ] && filled=1
  empty=$(( BAR_WIDTH - filled ))

  bar=""
  for i in $(seq 1 $filled 2>/dev/null); do bar="${bar}█"; done
  [ "$filled" -eq 0 ] && bar=""
  filled_str="${PCT_COLOR}${bar}${RESET}"

  bar=""
  for i in $(seq 1 $empty 2>/dev/null); do bar="${bar}░"; done
  [ "$empty" -eq 0 ] && bar=""
  empty_str="${FG_GRAY}${bar}${RESET}"

  progress_bar="${filled_str}${empty_str}"
  pct_label="${PCT_COLOR}${BOLD}${pct_int}%${RESET}"
else
  pct_int=0
  empty_bar=""; for i in $(seq 1 $BAR_WIDTH); do empty_bar="${empty_bar}░"; done
  progress_bar="${FG_GRAY}${empty_bar}${RESET}"
  pct_label="${FG_GRAY}--%${RESET}"
fi

# --- Format token count (e.g. 15k, 235k, 1.2M) ---
fmt_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    echo "$(echo "scale=1; $n / 1000000" | bc)M"
  elif [ "$n" -ge 1000 ]; then
    echo "$(( n / 1000 ))k"
  else
    echo "$n"
  fi
}

# --- Token usage label ---
if [ -n "$used_pct" ] && [ "$pct_int" -gt 0 ]; then
  used_tokens=$(( context_size * pct_int / 100 ))
else
  used_tokens=0
fi
tokens_label="${FG_LIGHT_GRAY}$(fmt_tokens $used_tokens)/$(fmt_tokens $context_size)${RESET}"

# --- Cost label ---
cost_label="${FG_CYAN}\$${RESET}${FG_BRIGHT_WHITE}${BOLD}$(printf '%.2f' "$cost")${RESET}"

# --- Version label ---
version_label="${FG_LIGHT_GRAY}v${version}${RESET}"

# --- Git branch ---
git_branch=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    git_branch=" ${FG_LIGHT_GRAY}on${RESET} ${FG_BRIGHT_WHITE}${BOLD}${branch}${RESET}"
  fi
fi

# --- Working directory ---
home="$HOME"
display_cwd="${cwd/#$home/~}"
cwd_label="${FG_BRIGHT_WHITE}${display_cwd}${RESET}${git_branch}"

# --- Model label ---
model_label="${FG_CYAN}${BOLD}${model}${RESET}"

# --- Separator ---
SEP="${FG_GRAY} | ${RESET}"

# --- Lines added/removed ---
lines_added_label="${FG_GREEN}+${lines_added}${RESET}"
lines_removed_label="${FG_RED}-${lines_removed}${RESET}"

# --- Cumulative tokens ---
input_tokens_label="${FG_YELLOW}input tokens:${RESET}${FG_YELLOW}${BOLD}$(fmt_tokens $total_input)${RESET}"
output_tokens_label="${FG_ORANGE}output tokens:${RESET}${FG_ORANGE}${BOLD}$(fmt_tokens $total_output)${RESET}"

# --- Format epoch to human-readable time remaining ---
# Usage: fmt_reset <epoch> [use_days]
fmt_reset() {
  local epoch=$1
  local use_days=${2:-false}
  if [ -z "$epoch" ]; then echo ""; return; fi
  local now=$(date +%s)
  local diff=$(( epoch - now ))
  if [ "$diff" -le 0 ]; then echo "now"; return; fi
  local days=$(( diff / 86400 ))
  local hours=$(( (diff % 86400) / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))
  if [ "$use_days" = "true" ] && [ "$days" -gt 0 ]; then
    echo "${days}d ${hours}h ${mins}m"
  elif [ "$(( diff / 3600 ))" -gt 0 ]; then
    echo "$(( diff / 3600 ))h ${mins}m"
  else
    echo "${mins}m"
  fi
}

# --- Rate limits (5h / 7d windows) ---
RATE_BAR_WIDTH=10
rate_label=""
if [ -n "$five_h_pct" ]; then
  fh_int=$(printf "%.0f" "$five_h_pct")
  if [ "$fh_int" -ge 75 ]; then FH_COLOR="$FG_RED"
  elif [ "$fh_int" -ge 50 ]; then FH_COLOR="$FG_YELLOW"
  else FH_COLOR="$FG_GREEN"; fi
  # 5h progress bar
  fh_filled=$(( fh_int * RATE_BAR_WIDTH / 100 ))
  [ "$fh_filled" -eq 0 ] && [ "$fh_int" -ge 1 ] && fh_filled=1
  fh_empty=$(( RATE_BAR_WIDTH - fh_filled ))
  fh_bar=""; for i in $(seq 1 $fh_filled 2>/dev/null); do fh_bar="${fh_bar}█"; done
  fh_ebar=""; for i in $(seq 1 $fh_empty 2>/dev/null); do fh_ebar="${fh_ebar}░"; done
  [ "$fh_filled" -eq 0 ] && fh_bar=""
  [ "$fh_empty" -eq 0 ] && fh_ebar=""
  fh_bar_str="${FH_COLOR}${fh_bar}${RESET}${FG_GRAY}${fh_ebar}${RESET}"
  fh_reset_str=""
  if [ -n "$five_h_reset" ]; then
    fh_reset_str="${FG_LIGHT_GRAY}($(fmt_reset "$five_h_reset"))${RESET}"
  fi
  rate_label="${fh_bar_str} ${FH_COLOR}5h:${fh_int}%${RESET}${fh_reset_str}"
fi
if [ -n "$seven_d_pct" ]; then
  sd_int=$(printf "%.0f" "$seven_d_pct")
  if [ "$sd_int" -ge 75 ]; then SD_COLOR="$FG_RED"
  elif [ "$sd_int" -ge 50 ]; then SD_COLOR="$FG_YELLOW"
  else SD_COLOR="$FG_GREEN"; fi
  sd_reset_str=""
  if [ -n "$seven_d_reset" ]; then
    sd_reset_str="${FG_LIGHT_GRAY}($(fmt_reset "$seven_d_reset" true))${RESET}"
  fi
  rate_label="${rate_label:+${rate_label} }${SD_COLOR}7d:${sd_int}%${RESET}${sd_reset_str}"
fi
if [ -n "$rate_label" ]; then
  rate_section="${SEP}${rate_label}"
else
  rate_section=""
fi

# --- Session ID ---
session_id=$(echo "$input" | jq -r '.session_id // ""')
session_name=$(echo "$input" | jq -r '.session_name // ""')
if [ -n "$session_id" ]; then
  if [ -n "$session_name" ]; then
    session_label="${FG_BRIGHT_WHITE}session:${RESET} ${FG_BRIGHT_WHITE}${session_id}${RESET}${FG_GRAY} (${session_name})${RESET}"
  else
    session_label="${FG_BRIGHT_WHITE}session:${RESET} ${FG_BRIGHT_WHITE}${session_id}${RESET}"
  fi
else
  session_label="${FG_GRAY}session: —${RESET}"
fi

# --- Format elapsed seconds as "Xd Xh Xm" / "Xh Xm" / "Xm" ---
fmt_elapsed() {
  local secs=$1
  [ "$secs" -lt 0 ] && secs=0
  local d=$(( secs / 86400 ))
  local h=$(( (secs % 86400) / 3600 ))
  local m=$(( (secs % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    echo "${d}d ${h}h ${m}m"
  elif [ "$h" -gt 0 ]; then
    echo "${h}h ${m}m"
  else
    echo "${m}m"
  fi
}

# --- Session created time (from transcript file birth time) ---
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')
session_start_label=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  now_epoch=$(date +%s)
  start_epoch=$(stat -f "%B" "$transcript_path" 2>/dev/null)
  if [ -n "$start_epoch" ] && [ "$start_epoch" -gt 0 ]; then
    start_time=$(date -r "$start_epoch" +"%H:%M")
    start_elapsed_str=$(fmt_elapsed $(( now_epoch - start_epoch )))
    session_start_label="${FG_LIGHT_GRAY} | created ${start_time} (${start_elapsed_str} ago)${RESET}"
  fi

  # --- Last user prompt (parse transcript for last type=user with string content) ---
  last_prompt_ts=$(grep '"type":"user"' "$transcript_path" 2>/dev/null | \
    jq -r 'select((.message.content | type) == "string") | .timestamp // empty' 2>/dev/null | \
    tail -1)
  if [ -n "$last_prompt_ts" ]; then
    clean_ts=${last_prompt_ts%.*}
    clean_ts=${clean_ts%Z}
    last_prompt_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$clean_ts" +%s 2>/dev/null)
    if [ -n "$last_prompt_epoch" ]; then
      last_prompt_time=$(date -r "$last_prompt_epoch" +"%H:%M")
      last_prompt_elapsed_str=$(fmt_elapsed $(( now_epoch - last_prompt_epoch )))
      session_start_label="${session_start_label}${FG_LIGHT_GRAY} | last prompt ${last_prompt_time} (${last_prompt_elapsed_str} ago)${RESET}"
    fi
  fi
fi

# --- Assemble ---
echo -e "${model_label}${SEP}${progress_bar} ${pct_label} ${tokens_label}${rate_section}${SEP}${cost_label}"
echo -e "${lines_added_label} ${lines_removed_label}${SEP}${input_tokens_label} ${output_tokens_label}${SEP}${version_label}${SEP}${cwd_label}"
echo -e "${session_label}${session_start_label}"
