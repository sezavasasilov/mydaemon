TMP = ./tmp
OUT = ./out
SRC = ./src
FLAGS = -FE$(OUT) -FU$(TMP)
BIN = /usr/local/bin
LOG = /var/log
PID = /run

.PHONY: all clean install uninstall

all: mydaemon

mydaemon:
	mkdir $(TMP)
	mkdir $(OUT)
	fpc $(FLAGS) $(SRC)/mydaemon.lpr

clean:
	rm -rf $(OUT)
	rm -rf $(TMP)

install:
	install $(OUT)/mydaemon $(PREFIX)/mydaemon

uninstall:
	rm -rf $(PREFIX)/mydaemon
	rm -rf $(LOG)/mydaemon.log
	rm -rf $(PID)/mydaemon
