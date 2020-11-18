module pool

import sync

struct Pool {
	size  int
mut:
	queue chan int
	wg    &sync.WaitGroup
}

pub fn new_pool(size int) &Pool {
	mut s := size
	if size <= 0 {
		s = 1
	}
	queue := chan int{cap: s}
	return &Pool{
		size: s
		queue: queue
		wg: sync.new_waitgroup()
	}
}

pub fn (mut p Pool) add(delta int) {
	for i := 0; i < delta; i++ {
		p.queue <- 1
	}
	p.wg.add(delta)
}

pub fn (mut p Pool) done() {
	s := <-p.queue
	if s > 0 {
		// empty block
	}
	p.wg.done()
}

pub fn (mut p Pool) wait() {
	p.wg.wait()
}
