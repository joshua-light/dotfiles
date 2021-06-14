#!/bin/bash 

echo "Setting default sink to: $1";
pactl set-default-sink $1
pactl list sink-inputs | grep index | while read line
do
    echo "Moving input: ";
    echo $line | cut -f2 -d' ';
    echo "to sink: $1";
    pactl move-sink-input `echo $line | cut -f2 -d' '` $1
done
