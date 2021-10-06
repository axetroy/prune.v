default:
	@make windows
	@make macos
	@make linux

format:
	@v fmt -w *.v **/*.v

format-check:
	@v fmt -c *.v **/*.v

windows:
	@v -prod -os windows -m64 -o ./bin/prune.exe main.v

macos:
	@v -prod -os macos -m64 -o ./bin/prune main.v

linux:
	@v -prod -os linux -m64 -o ./bin/prune main.v