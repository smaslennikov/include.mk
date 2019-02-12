GITROOT=$(shell git rev-parse --show-toplevel)/../

.DEFAULT_GOAL=toc

include $(shell test -d $(GITROOT)/include.mk/ || (git clone git@github.com:sadasystems/include.mk.git && rm -rf include.mk/.git include.mk/LICENSE* include.mk/Makefile include.mk/README.md) && echo $(GITROOT))/include.mk/*.mk

define RECIPIENTS
-r me@smaslennikov.com
endef
