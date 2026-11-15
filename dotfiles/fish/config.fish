# CachyOS-only; adjust the path on other distros.
source /usr/share/cachyos-fish-config/cachyos-config.fish

if status is-interactive
    starship init fish | source
end
