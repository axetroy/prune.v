module main

import os { file_size, getwd, is_dir, is_file, join_path, ls, rm, rmdir }
import flag
import time { now }
// import runtime
// import pool { new_pool }

const (
	version    = 'v0.2.9'
	dir_ignore = ['.git', '.github', '.idea', '.vscode']
	dir_prune  = ['node_modules', 'bower_components', '.temp', '.dist']
	file_prune = [
		// macos
		'.DS_Store',
		'.AppleDouble',
		'.LSOverride',
		// windows
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
	folder int // folder count
	file   int // file count
	size   u64 // the prune size
}

fn (shared r Result) increase_size(i u64) {
	lock r {
		r.size += i
	}
}

fn (shared r Result) increase_folder(i int) {
	lock r {
		r.folder += i
	}
}

fn (shared r Result) increase_file(i int) {
	lock r {
		r.file += i
	}
}

fn calc_size(filepath string, shared result Result) u64 {
	if is_dir(filepath) {
		files := ls(filepath) or { panic(err) }
		result.increase_folder(1)
		mut size := u64(0)
		for file in files {
			target := join_path(filepath, file)
			if is_dir(target) {
				size += calc_size(target, shared result)
			} else {
				result.increase_file(1)
				size += u64(file_size(target))
			}
		}
		return size
	} else {
		result.increase_file(1)
		return u64(file_size(filepath))
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
	// cpus_num := nr_cpus()
	// this is a bug and it should be fix in V upstream
	// ref: https://github.com/vlang/v/issues/6870
	// mut pool := new_pool(cpus_num)
	start := now().unix_time_milli()
	shared result := Result{
		check_mode: is_check_only
		size: 0
		folder: 0
		file: 0
	}
	for _, target in targets {
		walk(target, shared result)
	}
	end := now().unix_time_milli()
	diff_time := end - start
	rlock result{
		println('prune $result.folder folder & $result.file file & $result.size Bytes')
		println('finish in $diff_time ms')
	}
}

fn remove_dir(dir string, shared result Result) {
	size := calc_size(dir, shared result)
	if result.check_mode == false {
		rmdir(dir) or { panic(err) }
	}
	println(dir)
	result.increase_folder(1)
	result.increase_size(size)
}

fn remove_file(file string, shared result Result) {
	size := calc_size(file, shared result)
	if result.check_mode == false {
		rm(file) or { panic(err) }
	}
	println(file)
	result.increase_file(1)
	result.increase_size(size)
}

fn walk(dir string, shared result Result) {
	files := ls(dir) or { panic(err) }
	for file in files {
		filepath := join_path(dir, file)
		if is_dir(filepath) {
			if file in dir_prune {
				remove_dir(filepath, shared result)
			} else if file in dir_ignore {
				continue
			} else {
				walk(filepath, shared result)
			}
		} else if is_file(filepath) {
			if file in file_prune {
				remove_file(filepath, shared result)
			}
		}
	}
}
