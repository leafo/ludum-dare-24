.PHONY: build run run43 watch lint tags deploy clean

LOVE_VERSION = 11.5
LOVE_FILE = exoslime-love$(LOVE_VERSION).love
ITCH_TARGET = leafo/exoslime:love-$(LOVE_VERSION)
USER_VERSION = love$(LOVE_VERSION)-$(shell git rev-parse --short HEAD)

build:
	moonc *.moon levels/*.moon

run: build
	love .

# 4:3 handheld resolution (RG35XXH)
run43: build
	love . --window 640x480

watch:
	moonc -w *.moon levels/*.moon

lint:
	moonc -l *.moon levels/*.moon

$(LOVE_FILE): build
	rm -f $(LOVE_FILE)
	zip -9 -r $(LOVE_FILE) *.lua img audio levels/*.lua lovekit/*.lua -x '*.xrns' '*.xcf'

deploy: $(LOVE_FILE)
	butler push $(LOVE_FILE) $(ITCH_TARGET) --userversion $(USER_VERSION)

clean:
	rm -f $(LOVE_FILE)

tags:
	moon-tags $$(find -L . -path ./lib -prune -o -type f -name "*.moon" -print) > $@
