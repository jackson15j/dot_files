
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH=/opt/homebrew/opt/python@3.12/libexec/bin:$PATH
export PATH=/opt/homebrew/opt/python@3.12/libexec/bin:/opt/homebrew/opt/python@3.12/libexec/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/Library/Taps/homebrew/homebrew-bundle/cmd:/opt/homebrew/Library/Taps/homebrew/homebrew-services/cmd
export PATH=/opt/homebrew/opt/python@3.12/libexec/bin:/opt/homebrew/opt/python@3.12/libexec/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/Library/Taps/homebrew/homebrew-bundle/cmd:/opt/homebrew/Library/Taps/homebrew/homebrew-services/cmd
export PATH=/opt/homebrew/opt/python@3.12/libexec/bin:/opt/homebrew/opt/python@3.12/libexec/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/Library/Taps/homebrew/homebrew-bundle/cmd:/opt/homebrew/Library/Taps/homebrew/homebrew-services/cmd

alias whipper="docker run -ti --rm --device=/dev/cdrom \
    --mount type=bind,source=${HOME}/.config/whipper,target=/home/worker/.config/whipper \
    --mount type=bind,source=${HOME}/Music/output,target=/output \
    whipperteam/whipper"

# Change `ls` output of: `<MMM dd>` to include year.
# https://stackoverflow.com/questions/41994368/how-to-get-the-modified-date-and-year-of-file-in-unix
# Mac doesn't have: `--time-style=<full-iso|+%Y-%m-%d>`.
alias ls="ls -D %Y-%m-%d"
