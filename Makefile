default:
	make windows
	make macos
	make linux

format:
	v fmt -w main.v

windows:
	v -prod -os windows -o ./bin/prune_win build main.v

macos:
	v -prod -os macos -o ./bin/prune_osx build main.v

linux:
	v -prod -os linux -o ./bin/prune_linux build main.v