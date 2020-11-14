module main

import os { ls, join_path, getwd, is_dir, is_file, rmdir, rm }
import sync
import flag

const (
	version    = 'v0.1.1'
	dir_prune  = ['node_modules', 'bower_components', '.temp', '.dist']
	file_prune = ['.DS_Store']
)

fn print_help() {
	print('prune - A tool for prune your file-system

USAGE:
  prune [OPTIONS] <dirs>

OPTIONS:
  --help      print help information
  --version   print version information

EXAMPLE:
  prune ./dir1 ./dir2 ./dir3

SOURCE CODE:
	https://github.com/axetroy/prune
')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.skip_executable()
	is_help := fp.bool('help', 0, false, 'prine help information')
	is_version := fp.bool('version', 0, false, 'prine version information')
	additional_args := fp.finalize() or {
		eprintln(err)
		print_help()
		return
	}
	if is_help {
		print_help()
		return
	}
	if is_version {
		println(version)
		return
	}
	mut targets := []string{}
	cwd := getwd()
	for index, dir in additional_args {
		if index != 0 {
			if is_abs_path(dir) {
				targets << dir
			} else {
				targets << join_path(cwd, dir)
			}
		}
	}
	if targets.len < 1 {
		panic('target dir required')
	}
	mut wg := sync.new_waitgroup()
	wg.add(targets.len)
	for _, target in targets {
		go walk(target, mut wg)
	}
	wg.wait()
}

fn remove_dir(dir string, mut group sync.WaitGroup) {
	rmdir(dir) or {
		panic(err)
	}
	println(dir)
	group.done()
}

fn remove_file(file string, mut group sync.WaitGroup) {
	rm(file) or {
		panic(err)
	}
	println(file)
	group.done()
}

fn walk(dir string, mut group sync.WaitGroup) {
	files := ls(dir) or {
		panic(err)
	}
	for file in files {
		filepath := join_path(dir, file)
		if is_dir(filepath) {
			group.add(1)
			if file in dir_prune {
				go remove_dir(filepath, mut group)
			} else {
				go walk(filepath, mut group)
			}
		} else if is_file(filepath) {
			if file in file_prune {
				group.add(1)
				go remove_file(filepath, mut group)
			}
		}
	}
	group.done()
}
