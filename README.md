# prune

![ci](https://github.com/axetroy/prune/workflows/ci/badge.svg)
![Latest Version](https://img.shields.io/github/v/release/axetroy/prune.svg)
![License](https://img.shields.io/github/license/axetroy/prune.svg)
![Repo Size](https://img.shields.io/github/repo-size/axetroy/prune.svg)

An extremely fast tool for prune your file-system written in [V](https://github.com/vlang/v)

The tool will traverse the target directory, look for files/directories that can be deleted (eg. `node_modules`/`bower_components`/`.temp`/`.dist`) and delete them to free up your hard disk space.

## Feature

- [x] Remove extra stuff to make room for your hard drive
- [x] Written in [V](https://github.com/vlang/v)
- [x] Coroutine support, make full use of CPU. It's fast

### Install

1. Shell (Mac/Linux)

```bash
curl -fsSL https://github.com/release-lab/install/raw/v1/install.sh | bash -s -- -r=axetroy/prune
```

2. PowerShell (Windows):

```powershell
$r="axetroy/prune";iwr https://github.com/release-lab/install/raw/v1/install.ps1 -useb | iex
```

3. [Github release page](https://github.com/axetroy/prune/releases) (All platforms)

download the executable file and put the executable file to `$PATH`

## Usage

```sh
$ prune --help
prune - A tool for prune your file-system

USAGE:
  prune [OPTIONS] <dirs>

OPTIONS:
  --help        print help information
  --version     print version information
  --check-only  where check prune only without any file remove

EXAMPLE:
  prune ./dir1 ./dir2 ./dir3

SOURCE CODE:
  https://github.com/axetroy/prune
$ prune ./src
```

## Build from source

```sh
$ make
```

## LICENSE

The [MIT License](LICENSE)
