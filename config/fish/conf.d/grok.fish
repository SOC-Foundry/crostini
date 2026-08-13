# crostini-grok · CROS-004 / CHG-013
# Grok Build CLI (persistent under ~/.grok — survives reboot on Crostini disk)
if test -d "$HOME/.grok/bin"
    fish_add_path -g "$HOME/.grok/bin"
end
