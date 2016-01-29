#! /bin/bash

mkdir csv;

for f in *.wsp; 
do
	whisper-dump.py $f > csv/$f.tmp; 
done

for f in csv/*.tmp;
do 
	~/wsp_formater.rb $f
	rm $f
done