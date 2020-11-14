module main

import os { ls, join_path, getwd, is_dir, is_file, is_link, rmdir, rm, file_size }
import sync { RwMutex }
import flag

const (
	version    = 'v0.2.2'
	dir_prune  = ['node_modules', 'bower_components', '.temp', '.dist']
	file_prune = ['.DS_Store']
)

fn print_help() {
	print('prune - A tool for prune your file-system

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
')
}

struct Result {
	check_mode bool
mut:
	size       int // the prune size
	mtx        &sync.RwMutex // r/w lock
}

fn (mut r Result) add(i int) {
	r.mtx.w_lock()
	r.size += i
	r.mtx.w_unlock()
}

fn calc_size(filepath string) int {
	if is_dir(filepath) {
		files := ls(filepath) or {
			panic(err)
		}
		mut size := 0
		for file in files {
			target := join_path(filepath, file)
			if is_dir(target) {
				size += calc_size(target)
			} else if is_link(target) {
				size += file_size(target)
			} else if is_file(target) {
				size += file_size(target)
			}
		}
		return size
	} else {
		return file_size(filepath)
	}
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.skip_executable()
	is_help := fp.bool('help', 0, false, 'prine help information')
	is_version := fp.bool('version', 0, false, 'prine version information')
	is_check_only := fp.bool('check-only', 0, false, 'where check prune only without any file remove')
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
	for _, dir in additional_args {
		if is_abs_path(dir) {
			targets << dir
		} else {
			targets << join_path(cwd, dir)
		}
	}
	if targets.len < 1 {
		print_help()
		return
	}
	mut result := Result{
		check_mode: is_check_only
		size: 0
		mtx: sync.new_rwmutex()
	}
	mut wg := sync.new_waitgroup()
	wg.add(targets.len)
	for _, target in targets {
		go walk(target, mut wg, mut &result)
	}
	wg.wait()
	print('prune size: $result.size Bytes')
}

fn remove_dir(dir string, mut group sync.WaitGroup, mut result Result) {
	size := calc_size(dir)
	if result.check_mode == false {
		rmdir(dir) or {
			panic(err)
		}
	}
	println(dir)
	result.add(size)
	group.done()
}

fn remove_file(file string, mut group sync.WaitGroup, mut result Result) {
	size := calc_size(file)
	if result.check_mode == false {
		rm(file) or {
			panic(err)
		}
	}
	println(file)
	result.add(size)
	group.done()
}

fn walk(dir string, mut group sync.WaitGroup, mut result Result) {
	files := ls(dir) or {
		panic(err)
	}
	for file in files {
		filepath := join_path(dir, file)
		if is_dir(filepath) {
			group.add(1)
			if file in dir_prune {
				go remove_dir(filepath, mut group, mut result)
			} else {
				go walk(filepath, mut group, mut result)
			}
		} else if is_file(filepath) {
			if file in file_prune {
				group.add(1)
				go remove_file(filepath, mut group, mut result)
			}
		}
	}
	group.done()
}
