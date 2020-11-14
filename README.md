# prune

![ci](https://github.com/axetroy/prune/workflows/ci/badge.svg)
![Latest Version](https://img.shields.io/github/v/release/axetroy/prune.svg)
![License](https://img.shields.io/github/license/axetroy/prune.svg)
![Repo Size](https://img.shields.io/github/repo-size/axetroy/prune.svg)

A tool to prune your file-system written in [vlang](https://github.com/vlang/v)

The tool will traverse the target directory, look for files/directories that can be deleted (eg. `node_modules`/`bower_components`/`.temp`/`.dist`) and delete them to free up your hard disk space.

## Installation

Download [the release file](https://github.com/axetroy/prune/releases) for your platform and put it to `$PATH` folder.

## Usage

```sh
prune ./src
```

## Build from source

```sh
sh ./build.sh
```

## LICENSE

The [MIT License](LICENSE)
