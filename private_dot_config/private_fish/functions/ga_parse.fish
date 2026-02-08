# Analytics パラメータ パース
# ga_parse https://analytics.google.com/g/collect?key=val
function ga_parse
    set -l url $argv[1]
    python -c "import sys, urllib.parse as p; q=p.parse_qs(p.urlparse(sys.argv[1]).query); [print(f'{k:20}: {v[0]}') for k, v in q.items()]" $url
end
