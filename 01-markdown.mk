.PHONY: toc

MARKDOWN_FILE?=README.md

toc:
	markdown-toc --prepend'' --indent "    " -i $(MARKDOWN_FILE)
