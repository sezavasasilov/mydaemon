TMP=./tmp
OUT=./out
SRC=./src
FLAGS=-FE$(OUT) -FU$(TMP)

all: mydaemon

mydaemon:
	mkdir $(TMP)
	mkdir $(OUT)
	fpc $(FLAGS) $(SRC)/mydaemon.lpr

clean:
	rm -rf $(OUT)
	rm -rf $(TMP)
