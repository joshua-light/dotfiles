# dotfiles
_My dotfiles for different applications._

## Fonts
- `JetBrainsMono Nerd Font` ([Arch](https://aur.archlinux.org/packages/nerd-fonts-jetbrains-mono/))
- `Iosevka Nerd Font` ([Arch](https://aur.archlinux.org/packages/nerd-fonts-iosevka/))

## i3
- `ln -s $DOTFILES$/i3/config ~/.config/i3/config`

## fish
- `ln -s $DOTFILES$/config.fish ~/.config/fish/config.fish`

## Rofi
- _Nothing special_

## Polybar
- Install [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) icon theme
- Install [polybar-themes](https://github.com/adi1090x/polybar-themes)
- `ln -s $DOTFILES$/polybar/forest ~/.config/polybar/forest`

## Alacritty
- `ln -s $DOTFILES$/alacritty.yml ~/.alacritty.yml`

## Vim
- `ln -s $DOTFILES$/.vimrc ~/.config/nvim/init.vim` (NeoVim)
- `ln -s $DOTFILES$/coc-settings.json ~/.config/nvim/coc-settings.json` (NeoVim)
- `mkdir ~/.vim/swap`
- `mkdir ~/.vim/backup`
- `mkdir ~/.vim/undo`
- `pip3 install pynvim`
- `pip3 install isort`

_Note that Python packages should also be installed inside a `virtualenv`._
