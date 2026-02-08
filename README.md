# Install

```bash
pnpm i
```
```
pnpm lefthook install
```

# Setup

```bash
chezmoi init https://github.com/tkdn/dotfiles.git
```
```bash
chezmoi apply
```

# Config example

```toml:~/.config/chezmoi/config.toml
[data.claude]
aws_profile = "YOUR_AWS_PROFILE_USE_BEDROCK"
```
