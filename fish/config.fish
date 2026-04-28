if status is-interactive
    set -g fish_greeting ""
    alias ls='lsd'
    zoxide init fish | source
end
# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
