module main

import os { ls, join_path, getwd, is_dir, is_file, is_link, rmdir, rm, file_size }
import sync { RwMutex }
import flag
import time { now }
import pool { new_pool }

const (
	version    = 'v0.2.5'
	dir_ignore = ['.git', '.github', '.idea', '.vscode']
	dir_prune  = ['node_modules', 'bower_components', '.temp', '.dist']
	file_prune = [
		/* macos */
		'.DS_Store',
		'.AppleDouble',
		'.LSOverride',
		/* windows */
		'Thumbs.db',
		'Thumbs.db:encryptable',
		'ehthumbs.db',
		'ehthumbs_vista.db',
	]
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
	folder     int // folder count
	file       int // file count
	size       int // the prune size
	mtx        &sync.RwMutex // r/w lock
}

fn (mut r Result) increase_size(i int) {
	r.mtx.w_lock()
	defer {
		r.mtx.w_unlock()
	}
	r.size += i
}

fn (mut r Result) increase_folder(i int) {
	r.mtx.w_lock()
	defer {
		r.mtx.w_unlock()
	}
	r.folder += i
}

fn (mut r Result) increase_file(i int) {
	r.mtx.w_lock()
	defer {
		r.mtx.w_unlock()
	}
	r.file += i
}

fn calc_size(filepath string, mut result Result) int {
	if is_dir(filepath) {
		files := ls(filepath) or {
			panic(err)
		}
		result.increase_folder(1)
		mut size := 0
		for file in files {
			target := join_path(filepath, file)
			if is_dir(target) {
				size += calc_size(target, mut result)
			} else if is_link(target) {
				result.increase_file(1)
				size += file_size(target)
			} else if is_file(target) {
				result.increase_file(1)
				size += file_size(target)
			}
		}
		return size
	} else {
		result.increase_file(1)
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
	mut pool := new_pool(10)
	start := now().unix_time_milli()
	mut result := Result{
		check_mode: is_check_only
		size: 0
		folder: 0
		file: 0
		mtx: sync.new_rwmutex()
	}
	for _, target in targets {
		pool.add(1)
		go walk(target, mut pool, mut &result)
	}
	pool.wait()
	end := now().unix_time_milli()
	diff_time := end - start
	println('prune $result.folder folder & $result.file file & $result.size Bytes')
	println('finish in $diff_time ms')
}

fn remove_dir(dir string, mut pool pool.Pool, mut result Result) {
	defer {
		pool.done()
	}
	size := calc_size(dir, mut result)
	if result.check_mode == false {
		rmdir(dir) or {
			panic(err)
		}
	}
	println(dir)
	result.increase_folder(1)
	result.increase_size(size)
}

fn remove_file(file string, mut pool pool.Pool, mut result Result) {
	defer {
		pool.done()
	}
	size := calc_size(file, mut result)
	if result.check_mode == false {
		rm(file) or {
			panic(err)
		}
	}
	println(file)
	result.increase_file(1)
	result.increase_size(size)
}

fn walk(dir string, mut pool pool.Pool, mut result Result) {
	mut is_done := false
	files := ls(dir) or {
		panic(err)
	}
	defer {
		if is_done == false {
			pool.done()
		}
	}
	for file in files {
		filepath := join_path(dir, file)
		if is_dir(filepath) {
			if file in dir_prune {
				if is_done == false {
					pool.done()
				}
				is_done = true
				pool.add(1)
				go remove_dir(filepath, mut pool, mut result)
			} else if file in dir_ignore {
				continue
			} else {
				if is_done == false {
					pool.done()
				}
				is_done = true
				pool.add(1)
				go walk(filepath, mut pool, mut result)
			}
		} else if is_file(filepath) {
			if file in file_prune {
				if is_done == false {
					pool.done()
				}
				is_done = true
				pool.add(1)
				go remove_file(filepath, mut pool, mut result)
			}
		}
	}
}
