.PHONY: build watch open setup

build:
	coffee -c .

watch:
	coffee -cw .

setup:
	cp -r testrepo/.notgit testrepo/.git

open: 
	open /Applications/nwjs.app/ --args `pwd`
