function git-clean-branches
    if test "$argv[1]" = --merged
        set targets (git for-each-ref --format="%(refname:short) %(upstream:track)" refs/heads \
        | string match -r '^\S+(?= \[gone\]$)')

        if test -z "$targets"
            echo "No merged branches to delete"
            return
        end

        printf "%s\n" $targets
        read -l -P "Delete these branches? [y/N] " answer
        if string match -qi y -- $answer
            git branch -d $targets
        end
        return
    end

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
