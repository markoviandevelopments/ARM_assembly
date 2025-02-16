#!/bin/bash
as -o assembly.o assembly.s
ld -o assembly assembly.o
./assembly
