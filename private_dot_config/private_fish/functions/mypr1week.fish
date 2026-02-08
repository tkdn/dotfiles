function mypr1week
  gh search prs \
    --author tkdn --closed '>'(date -v -7d +%Y-%m-%d) \
    --json repository,number,title,closedAt,url \
    --jq '.[] | [
      .repository.nameWithOwner,
      .number,
      (.closedAt | sub("Z$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime | . + (9*3600) | strftime("%Y-%m-%d %H:%M:%S")),
      .title,
      .url
    ] | @tsv'
end
