default:
	@make windows
	@make macos
	@make linux

format:
	@v fmt -w *.v **/*.v

format-check:
	@v fmt -c *.v **/*.v

windows:
	@v -prod -os windows -m64 -o ./bin/prune_win main.v

macos:
	@v -prod -os macos -m64 -o ./bin/prune_osx main.v

linux:
	@v -prod -os linux -m64 -o ./bin/prune_linux main.v