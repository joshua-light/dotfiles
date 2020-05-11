# vimrc
My NeoVim configuration file.

## Install (Linux)
**Requirements:** Python `3.6` or greater ([Download](https://www.python.org/downloads/)).

### Plugin Manager
Install [`vim-plug`](https://github.com/junegunn/vim-plug) manually or by using:
```shell
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```
### Auto
To install, you only need to clone the repository, and run the `setup-unix.py` script.
To do that, execute a following list of commands.

```shell
$ git clone https://github.com/JoshuaLight/vimrc.git
$ cd vimrc
$ cdhmod +x setup-unix.py
$ ./setup-unix.py
```

Follow the instruction and backup data if suggested.
