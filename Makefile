CC = clang
CFLAGS = -O2
CFLAGS_DEBUG = -gdwarf -DDEBUG=1 -Og
LDFLAGS = -framework Foundation -framework CFNetwork -framework ApplicationServices

.PHONY: release debug clean

release: bin/pidfocus

debug: dbg/pidfocus

bin/pidfocus: src/main.m src/util.m
	mkdir -p bin
	$(CC) $(CFLAGS) $(LDFLAGS) -o bin/pidfocus src/main.m src/util.m

dbg/pidfocus: src/main.m src/util.m
	mkdir -p dbg
	$(CC) $(CFLAGS_DEBUG) $(LDFLAGS) -o dbg/pidfocus src/main.m src/util.m

clean:
	rm -rf bin dbg
	mkdir -p bin dbg
