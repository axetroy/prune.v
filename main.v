module main

import os
import flag
import time
// import runtime
// import pool { new_pool }

const (
	version = 'v0.2.13'
	rules   = $embed_file('rules.txt')
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

struct Rule {
pub mut:
	dir_ignore []string
	dir_prune  []string
	file_prune []string
}

struct Result {
	check_mode bool
pub:
	rule Rule
mut:
	folder int // folder count
	file   int // file count
	size   u64 // the prune size
}

fn (mut r Result) increase_size(i u64) {
	r.size += i
}

fn (mut r Result) increase_folder(i int) {
	r.folder += i
}

fn (mut r Result) increase_file(i int) {
	r.file += i
}

fn calc_size(filepath string, mut result Result) ?u64 {
	if os.is_dir(filepath) {
		files := os.ls(filepath) ?
		mut size := u64(0)
		for file in files {
			target := os.join_path(filepath, file)
			size += calc_size(target, mut result) ?
		}
		return size
	} else if os.is_file(filepath) {
		return os.file_size(filepath)
	} else {
		return u64(0)
	}
}

fn remove_dir(dir string, mut result Result) ? {
	size := calc_size(dir, mut result) ?
	if result.check_mode == false {
		os.rmdir_all(dir) ?
	}
	println(dir)
	result.increase_folder(1)
	result.increase_size(size)
}

fn remove_file(file string, mut result Result) ? {
	size := calc_size(file, mut result) ?
	if result.check_mode == false {
		os.rm(file) ?
	}
	println(file)
	result.increase_file(1)
	result.increase_size(size)
}

fn walk(dir string, mut result Result) ? {
	files := os.ls(dir) ?
	for file in files {
		filepath := os.join_path(dir, file)
		if os.is_dir(filepath) {
			if file in result.rule.dir_prune {
				remove_dir(filepath, mut result) ?
			} else if file in result.rule.dir_ignore {
				continue
			} else {
				walk(filepath, mut result) ?
			}
		} else if os.is_file(filepath) {
			if file in result.rule.file_prune {
				remove_file(filepath, mut result) ?
			}
		}
	}
}

fn parse_rules(r string) Rule {
	mut rule := Rule{
		dir_ignore: []string{}
		dir_prune: []string{}
		file_prune: []string{}
	}

	lines := r.split_into_lines()

	for l in lines {
		line := l.trim_space()

		// empty line
		if line == '' {
			continue
		}

		// comment line
		if line.starts_with('#') {
			continue
		}

		if line.starts_with('I ') {
			rule.dir_ignore << line.trim_left('I ').trim_space()
		}

		if line.starts_with('D ') {
			rule.dir_prune << line.trim_left('D ').trim_space()
		}

		if line.starts_with('F ') {
			rule.file_prune << line.trim_left('F ').trim_space()
		}
	}

	return rule
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
	cwd := os.getwd()
	for _, dir in additional_args {
		if os.is_abs_path(dir) {
			targets << dir
		} else {
			targets << os.join_path(cwd, dir)
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
	start := time.now().unix_time_milli()
	mut result := Result{
		check_mode: is_check_only
		size: 0
		folder: 0
		file: 0
		rule: parse_rules(rules.to_string())
	}

	for _, target in targets {
		walk(target, mut result) or { panic(err) }
	}
	end := time.now().unix_time_milli()
	diff_time := end - start
	println('prune $result.folder folder and $result.file file, total size: $result.size Bytes')
	println('finish in $diff_time ms')
}
