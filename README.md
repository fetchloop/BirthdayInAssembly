# BirthdayInAssembly

A console-based birthday manager written in x86-64 NASM assembly for Windows.

## Features

- View all upcoming birthdays, sorted by how soon they occur
- Add new birthdays (name + date)
- Edit or remove existing entries
- Persists to `birthdays.ini` between sessions

## Requirements

- [MSYS2](https://www.msys2.org/) (provides GCC and the C runtime)
- [NASM](https://www.nasm.us/)

## Building

The project includes a VS Code `tasks.json` that runs the build automatically. To build manually:

```
nasm -f win64 soft.asm -o soft.o
gcc main.o -o soft.exe
```

## Running

```
./soft.exe
```

Birthdays are saved to `birthdays.ini` in the same directory and loaded automatically on startup.

## Notes

This is a learning project. The program links against libc (`printf`, `scanf`, etc.) rather than calling the Windows API directly.
