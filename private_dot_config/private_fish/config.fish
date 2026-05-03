# homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"

if not functions -q fisher
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
    fish -c fisher
end

#libpq
# If you need to have libpq first in your PATH, run:
fish_add_path /usr/local/opt/libpq/bin
# For compilers to find libpq you may need to set:
set -gx LDFLAGS "-L/opt/homebrew/opt/readline/lib"
set -gx CPPFLAGS "-I/opt/homebrew/opt/readline/include"
# For pkg-config to find libpq you may need to set:
set -gx PKG_CONFIG_PATH "/opt/homebrew/opt/libffi/lib/pkgconfig"
# set -gx RUBY_CONFIGURE_OPTS "--with-openssl-dir=(brew --prefix openssl@3)"

if type -q rbenv
# Added by `rbenv init` on Tue Apr  8 16:19:31 JST 2025
status --is-interactive; and rbenv init - --no-rehash fish | source
end

# claude-code Bedrockの有効化
# see: https://code.claude.com/docs/ja/amazon-bedrock
if [ -f ~/.claudecode.fish ]; . ~/.claudecode.fish; end

# The next line updates PATH for the Google Cloud SDK.
if [ -f ~/google-cloud-sdk/path.fish.inc ]; . ~/google-cloud-sdk/path.fish.inc; end

# envrionment variables and paths...
set -x PATH $PATH $HOME/bin
## psql locale
set -gx LC_MESSAGES en_US.UTF-8
## nodejs signature
set --export NODEJS_CHECK_SIGNATURES no
## ruby
set -g theme_display_ruby no
## git global
set -gx REPOS '~/project/github.com/'
## composer installer
set -gx PATH $HOME/.composer/vendor/bin $PATH
## bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
## Go
set -x GOPATH $HOME/go
set -x PATH $PATH $GOPATH/bin
## angular-cli
set -gx NG_CLI_ANALYTICS "false"

# set abbr
abbr --add dc "docker compose"
abbr --add python "python3"
abbr --add pip "pip3"
abbr --add ngtest "npx ng test --watch=false --main src/test.ts --include"

# LESS
set -x LESS -R
set -x LESSCHARSET utf-8
set -x LC_ALL en_US.UTF-8

# bobthefish not use Powerline fonts
set -g theme_powerline_fonts no
