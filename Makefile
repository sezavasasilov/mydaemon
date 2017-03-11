TMP = ./tmp
OUT = ./out
SRC = ./src
FLAGS = -FE$(OUT) -FU$(TMP)
BIN = /etc/init.d
LOG = /var/log
PID = /var/run
TARGET = mydaemon
AUTOSTART = /etc/rc2.d/S[0-9][0-9]$(TARGET)

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
	install $(OUT)/mydaemon $(BIN)/$(TARGET)
	update-rc.d $(TARGET) defaults

uninstall:
	rm -rf $(BIN)/$(TARGET)
	rm -rf $(LOG)/mydaemon.log
	rm -rf $(PID)/mydaemon.pid
	update-rc.d $(TARGET) remove
