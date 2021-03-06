.PHONY: all

all: dmd
dmd: dmdserver dmdclient
debug: dmdclient debugserver
gdc: gdcserver gdcclient
ldc: ldcserver ldcclient

DMD := dmd
GDC := gdc
LDC := ldc2

DPARSE_DIR := libdparse
DSYMBOL_DIR := dsymbol
STDXALLOC_DIR := stdx-allocator

SHELL:=/bin/bash

githash:
	@mkdir -p bin
	git describe --tags > bin/githash.txt

report:
	dscanner --report src > dscanner-report.json
	sonar-runner

clean:
	rm -rf bin
	rm -f dscanner-report.json
	rm -f githash.txt
	rm -f *.o

CLIENT_SRC := \
	$(shell find src/dcd/common -name "*.d")\
	$(shell find src/dcd/client -name "*.d")\
	$(shell find msgpack-d/src/ -name "*.d")

DMD_CLIENT_FLAGS := -Imsgpack-d/src\
	-Imsgpack-d/src\
	-Jbin\
	-inline\
	-O\
	-wi\
	-ofbin/dcd-client

GDC_CLIENT_FLAGS := -Imsgpack-d/src\
	-Jbin\
	-O3\
	-frelease\
	-obin/dcd-client

LDC_CLIENT_FLAGS := -Imsgpack-d/src\
	-Imsgpack-d/src\
	-J=bin\
	-release\
	-O5\
	-oq\
	-of=bin/dcd-client

override DMD_CLIENT_FLAGS += $(DFLAGS)
override LDC_CLIENT_FLAGS += $(DFLAGS)
override GDC_CLIENT_FLAGS += $(DFLAGS)

SERVER_SRC := \
	$(shell find src/dcd/common -name "*.d")\
	$(shell find src/dcd/server -name "*.d")\
	$(shell find ${DSYMBOL_DIR}/src -name "*.d")\
	$(shell find ${STDXALLOC_DIR}/source -name "*.d")\
	${DPARSE_DIR}/src/dparse/ast.d\
	${DPARSE_DIR}/src/dparse/entities.d\
	${DPARSE_DIR}/src/dparse/lexer.d\
	${DPARSE_DIR}/src/dparse/parser.d\
	${DPARSE_DIR}/src/dparse/formatter.d\
	${DPARSE_DIR}/src/dparse/rollback_allocator.d\
	${DPARSE_DIR}/src/dparse/stack_buffer.d\
	${DPARSE_DIR}/src/std/experimental/lexer.d\
	containers/src/containers/dynamicarray.d\
	containers/src/containers/ttree.d\
	containers/src/containers/unrolledlist.d\
	containers/src/containers/openhashset.d\
	containers/src/containers/hashset.d\
	containers/src/containers/internal/hash.d\
	containers/src/containers/internal/node.d\
	containers/src/containers/internal/storage_type.d\
	containers/src/containers/internal/element_type.d\
	containers/src/containers/internal/backwards.d\
	containers/src/containers/slist.d\
	$(shell find msgpack-d/src/ -name "*.d")

DMD_SERVER_FLAGS := -Icontainers/src\
	-Imsgpack-d/src\
	-I${DPARSE_DIR}/src\
	-I${DSYMBOL_DIR}/src\
	-I${STDXALLOC_DIR}/source\
	-Jbin\
	-wi\
	-O\
	-release\
	-inline\
	-ofbin/dcd-server

DEBUG_SERVER_FLAGS := -Icontainers/src\
	-Imsgpack-d/src\
	-I${DPARSE_DIR}/src\
	-I${DSYMBOL_DIR}/src\
	-wi\
	-g\
	-ofbin/dcd-server\
	-Jbin

GDC_SERVER_FLAGS := -Icontainers/src\
	-Imsgpack-d/src\
	-I${DPARSE_DIR}/src\
	-I${DSYMBOL_DIR}/src\
	-Jbin\
	-O3\
	-frelease\
	-obin/dcd-server

LDC_SERVER_FLAGS := -Icontainers/src\
	-Imsgpack-d/src\
	-I${DPARSE_DIR}/src\
	-I${DSYMBOL_DIR}/src\
	-Isrc\
	-J=bin\
	-O5\
	-release

override DMD_SERVER_FLAGS += $(DFLAGS)
override LDC_SERVER_FLAGS += $(DFLAGS)
override GDC_SERVER_FLAGS += $(DFLAGS)

dmdclient: githash
	mkdir -p bin
	${DMD} ${CLIENT_SRC} ${DMD_CLIENT_FLAGS}

dmdserver: githash
	mkdir -p bin
	${DMD} ${SERVER_SRC} ${DMD_SERVER_FLAGS}

debugserver: githash
	mkdir -p bin
	${DMD} ${SERVER_SRC} ${DEBUG_SERVER_FLAGS}

gdcclient: githash
	mkdir -p bin
	${GDC} ${CLIENT_SRC} ${GDC_CLIENT_FLAGS}

gdcserver: githash
	mkdir -p bin
	${GDC} ${SERVER_SRC} ${GDC_SERVER_FLAGS}

ldcclient: githash
	${LDC} ${CLIENT_SRC} ${LDC_CLIENT_FLAGS} -oq -of=bin/dcd-client

ldcserver: githash
	${LDC} $(LDC_SERVER_FLAGS) ${SERVER_SRC} -oq -of=bin/dcd-server

test: debugserver dmdclient
	cd tests && ./run_tests.sh

release:
	./release.sh
