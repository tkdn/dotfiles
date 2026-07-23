function mypr1week
  set -l days 7
  set -l user tkdn

  for arg in $argv
    switch $arg
      case '-d=*'
        set days (string match -r -- '-d=(\d+)' $arg)[2]
      case '-u=*'
        set user (string match -r -- '-u=(.+)' $arg)[2]
    end
  end

  set -l since (date -v -{$days}d +%Y-%m-%d)
  set -l jq_filter '.[] | [
      .repository.nameWithOwner,
      .number,
      (.closedAt | sub("Z$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime | . + (9*3600) | strftime("%Y-%m-%d %H:%M:%S")),
      .title,
      .url
    ] | @tsv'

  echo "=== authored ==="
  gh search prs --author $user --closed ">$since" \
    --json repository,number,title,closedAt,url \
    --jq $jq_filter

  echo "=== reviewed ==="
  gh search prs --reviewed-by $user --closed ">$since" \
    --json repository,number,title,closedAt,url \
    --jq $jq_filter
end
