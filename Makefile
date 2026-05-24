.POSIX:

CFLAGS ?= -std=c99
CFLAGS += -O2

CFLAGS += -Wall -Wextra -Wpedantic
CFLAGS += -Werror=write-strings -Werror=return-type
CFLAGS += -Wcast-align -Wcast-qual

fhp: fast-hydra-parser.c
	$(LINK.c) -o $@ $(LDFLAGS) $(LDLIBS) $^

.PHONY: clean
clean:
	$(RM) fhp


PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin

.PHONY: install
install: fhp
	install -Dm577 fhp -t $(BINDIR)
