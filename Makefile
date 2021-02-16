default:
	make windows
	make macos
	make linux

format:
	v fmt -w **/*.v

format-check:
	v fmt -c **/*.v

windows:
	v -prod -os windows -o ./bin/prune_win main.v

macos:
	v -prod -os macos -o ./bin/prune_osx main.v

linux:
	v -prod -os linux -o ./bin/prune_linux main.v