#!/bin/bash
set -e

# =============================================================================
# Configuration - Edit these to add/remove sources
# =============================================================================

REPOS=(
  "dannysmith/taskdn"
  "dannysmith/astro-editor"
  "dannysmith/obsidian-taskdn"
)

ARTICLES_FEED="https://danny.is/rss/articles.xml"
NOTES_FEED="https://danny.is/rss/notes.xml"

ITEMS_PER_COLUMN=5

# =============================================================================
# Functions
# =============================================================================

fetch_rss_items() {
  local feed_url="$1"
  local count="$2"
  local xml=$(curl -s "$feed_url")

  for i in $(seq 1 "$count"); do
    local title=$(echo "$xml" | xmllint --xpath "//item[$i]/title/text()" - 2>/dev/null) || break
    local link=$(echo "$xml" | xmllint --xpath "//item[$i]/link/text()" - 2>/dev/null)
    local pubdate=$(echo "$xml" | xmllint --xpath "//item[$i]/pubDate/text()" - 2>/dev/null)

    [ -z "$title" ] && break

    # Format date as "Mon DD"
    local formatted_date=""
    if [ -n "$pubdate" ]; then
      formatted_date=$(date -j -f "%a, %d %b %Y %H:%M:%S %Z" "$pubdate" "+%b %d" 2>/dev/null || echo "")
    fi

    echo "- [${title}](${link})$([ -n "$formatted_date" ] && echo " <small>($formatted_date)</small>")"
  done
}

fetch_releases() {
  local temp_file=$(mktemp)

  for repo in "${REPOS[@]}"; do
    gh release list --repo "$repo" --limit 10 --json tagName,publishedAt,name 2>/dev/null | \
      jq -r --arg repo "$repo" '.[] | "\(.publishedAt)\t\($repo)\t\(.tagName)\t\(.name // .tagName)"' >> "$temp_file"
  done

  # Sort by date (newest first), take top N, format as markdown
  sort -t$'\t' -k1 -r "$temp_file" | head -n "$ITEMS_PER_COLUMN" | while IFS=$'\t' read -r date repo tag name; do
    # Extract just repo name from full path
    repo_name="${repo#*/}"
    # Construct release URL
    url="https://github.com/${repo}/releases/tag/${tag}"
    # Format date as "Mon DD"
    formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$date" "+%b %d" 2>/dev/null || echo "")
    echo "- [${repo_name} ${tag}](${url})$([ -n "$formatted_date" ] && echo " <small>($formatted_date)</small>")"
  done

  rm -f "$temp_file"
}

replace_section() {
  local file="$1"
  local marker="$2"
  local content="$3"
  local temp_file=$(mktemp)
  local content_file=$(mktemp)

  # Write content to temp file to avoid awk variable escaping issues
  echo "$content" > "$content_file"

  awk -v marker="$marker" -v cfile="$content_file" '
    BEGIN { in_section = 0 }
    $0 ~ "<!-- " marker " starts -->" {
      print
      while ((getline line < cfile) > 0) print line
      close(cfile)
      in_section = 1
      next
    }
    $0 ~ "<!-- " marker " ends -->" {
      in_section = 0
    }
    !in_section { print }
  ' "$file" > "$temp_file"

  mv "$temp_file" "$file"
  rm -f "$content_file"
}

# =============================================================================
# Main
# =============================================================================

echo "Fetching releases..."
RELEASES=$(fetch_releases)

echo "Fetching articles..."
ARTICLES=$(fetch_rss_items "$ARTICLES_FEED" "$ITEMS_PER_COLUMN")

echo "Fetching notes..."
NOTES=$(fetch_rss_items "$NOTES_FEED" "$ITEMS_PER_COLUMN")

echo "Updating README.md..."

# Replace each section
replace_section "README.md" "releases" "$RELEASES"
replace_section "README.md" "articles" "$ARTICLES"
replace_section "README.md" "notes" "$NOTES"

echo "Done!"
