function claude-review
    if test (count $argv) -eq 0
        echo "Usage: claude-review <branch>"
        return 1
    end

    set branch $argv[1]
    set repo_root (git rev-parse --show-toplevel)

    git worktree add $repo_root/../$branch $branch
    cd $repo_root/../$branch
    claude /pr-review
end
