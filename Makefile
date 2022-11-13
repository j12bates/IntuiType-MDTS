ifeq ($(PREFIX),)
	PREFIX := /usr/local
endif

.PHONY: install

install:
	install -d $(PREFIX)/lib/intuitype $(PREFIX)/bin
	cp -r src/* $(PREFIX)/lib/intuitype/
	cp intuitype $(PREFIX)/bin/intuitype
	chmod +x $(PREFIX)/bin/intuitype
