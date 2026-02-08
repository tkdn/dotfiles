# fish shell

## init
```bash
sudo vi /etc/shells
chsh -s (which fish)
```

## quick setup
```bash
. ~/.config/fish/fish_setup
```

## manual install

### fisher install
```bash
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

#### plugin install
```bash
fisher install decors/fish-ghq jethrokuan/fzf
```

### oh-my-fish install
```bash
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
```

#### theme
```bash
omf install bobthefish
```

without power font:

```bash
echo "set -g theme_powerline_fonts no" >> ~/.config/fish/config.fish
```

# other
## add path
```bash
# e.g. from wsl to host vscode
fish_add_path /mnt/c/Users/tkdn/AppData/Local/Programs/Microsoft\ VS\ Code/bin/
```

