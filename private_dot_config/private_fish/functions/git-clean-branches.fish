function git-clean-branches
    set current (git branch --show-current)

    set branches (git branch --format="%(refname:short)" \
    | grep -v "^main\$" \
    | grep -v "^$current\$")

    if test -z "$branches"
        echo "No branches to delete"
        return
    end

    set selected (printf "%s\n" $branches | fzf -m --prompt="Delete branches> ")

    if test -z "$selected"
        echo "No selection"
        return
    end

    for b in $selected
        git branch -D $b
    end
end
