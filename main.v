module main

import os { ls, join_path, getwd, is_dir, is_file, rmdir, rm }
import sync

const (
	dir_prune = ["node_modules"]
	file_prune = [".DS_Store"]
)

fn main() {
	mut targets := []string{}

	cwd := getwd()

	for index, dir in os.args{
		if index != 0{
			if is_abs_path(dir) {
				targets << dir
			} else {
				targets << join_path(cwd, dir)
			}
		}
	}

	if targets.len<1 {
		panic(error('target dir required'))
	}

	mut wg := sync.new_waitgroup()

	wg.add(targets.len)

	for _, target in targets {
		go walk(target, mut wg)
	}

	wg.wait()
}

fn remove_dir(dir string, mut group &sync.WaitGroup){
	rmdir(dir) or {
		panic(err)
	}
	println(dir)
	group.done()
}

fn remove_file(file string, mut group &sync.WaitGroup){
	rm(file) or {
		panic(err)
	}
	println(file)
	group.done()
}

fn walk(dir string, mut group &sync.WaitGroup) {
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
		} else if is_file(filepath){
			if file in file_prune {
				group.add(1)
				go remove_file(filepath, mut group)
			}
		}
	}

	group.done()
}