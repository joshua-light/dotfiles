#!/bin/bash
echo -e "Top RAM-hungry processes:\n"
ps -eo pid,comm,%mem --sort=-%mem | head -n 6

