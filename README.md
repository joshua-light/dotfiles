# vimrc
My NeoVim configuration file.

## Install (Linux)
### Auto
**Requirements:** Python `3.6` or greater ([Download](https://www.python.org/downloads/)).

To install, you only need to clone the repository, and run the `setup-unix.py` script.
To do that, execute a following list of commands.

```shell
$ git clone https://github.com/JoshuaLight/vimrc.git
$ cd vimrc
$ cdhmod +x setup-unix.py
$ ./setup-unix.py
```

### Manual
Just link the `.vimrc` file to `~/.config/nvim/init.vim`.

```shell
$ git clone https://github.com/JoshuaLight/vimrc.git
$ cd vimrc
$ ln -s .vimrc ~/.config/nvim/init.vim
```
