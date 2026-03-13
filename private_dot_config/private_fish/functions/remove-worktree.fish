function remove-worktree
    set current (pwd)

    set targets (git worktree list --porcelain | string match -r '^worktree (.+)' --groups-only | string match -v $current)

    if test (count $targets) -eq 0
        echo "No other worktrees to remove."
        return 0
    end

    echo "The following worktrees will be removed:"
    for path in $targets
        echo "  $path"
    end

    read --prompt-str "Proceed? [y/N] " confirm
    if test "$confirm" != y
        echo "Aborted."
        return 1
    end

    for path in $targets
        git worktree remove $path
        and echo "Removed: $path"
        or echo "Failed (dirty?): $path  →  use: git worktree remove --force $path"
    end
end
