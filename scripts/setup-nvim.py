#! /usr/bin/env python3

import sys
from os import path
from pathlib import Path

from core import backup, link

if __name__ == '__main__':
    _, neo, *rest = sys.argv

    print('Setting up your vimrc environment...')

    home_dir = str(Path.home())
    home_vimrc = path.join(home_dir, '.config', 'nvim', 'init.vim') if neo == '--neo' else \
                 path.join(home_dir, '.vimrc')
    script_dir = Path(__file__).parent.absolute()
    script_vimrc = path.join(script_dir, '.vimrc')

    backup(home_vimrc)
    link(script_vimrc, to=home_vimrc)
