import os
import sys
from os import path
from pathlib import Path
from typing import Any, Callable


class IO:
    def __init__(self, input_: Callable, output_: Callable):
        self._input = input_
        self._output = output_
        self.indent = 0

    def _indented(self, x: str):
        return self.indent * " " + x

    def increase_indent(self, by: int):
        self.indent += by

    def decrease_indent(self, by: int):
        self.indent -= by

    def read(self, message: str) -> Any:
        return self._input(self._indented(message))

    def tell(self, message: str) -> Any:
        return self._output(self._indented(message))


def terminate():
    print('The setup process is terminated.')
    quit()


def step(name):
    if not hasattr(step, 'io'):
        setattr(step, 'io', IO(input, print))

    def inner(func):
        def body(*args, **kwargs):
            step.io.tell(f'- {name}...')
            step.io.increase_indent(by=4)

            args = list(args)
            args.insert(0, step.io)
            result = func(*args, **kwargs)

            step.io.decrease_indent(by=2)
            step.io.tell('OK')
            step.io.decrease_indent(by=2)

            return result

        return body
    return inner


@step('Backup')
def backup(io: IO, file: str):
    backed = f'{file}.backup'

    if not path.exists(file):
        io.tell('Nothing to backup.')
        return

    if path.exists(backed):
        while True:
            answer = io.read(f"The backup file '{backed}' already exists. Do you want to remove it? (Y/n) ")

            if answer == 'n':
                terminate()
            elif answer in ['y', 'Y', '']:
                os.remove(backed)
                io.tell(f"Successfully removed '{backed}' file.")
                break

    os.rename(file, backed)


@step('Link')
def link(io: IO, file: str, to: str):
    path = Path(to)
    path.parent.mkdir(parents=True, exist_ok=True)

    os.symlink(file, to)

    io.tell(f"Successfully linked '{file}' to '{to}'.")
