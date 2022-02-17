CFLAGS=-Wall -O2 -g -fPIC
# We use two posix extensions, strdup() and newlocale()/uselocale().
CC=gcc -std=c11 -D_POSIX_C_SOURCE=200809L

resolve: resolve.c libdemes.a
	$(CC) $(CFLAGS) resolve.c -o $@ -L. -ldemes -lyaml

libdemes.a: demes.o unicodectype.o
	$(AR) r $@ $^

demes.o: demes.c demes.h
unicodectype.o: unicodectype.c unicodetype_db.h

alltests: test memcheck pytest

test:
	$(MAKE) -C tests
	gcov *.c

# Resolve the test models under valgrind to check for memory errors.
memcheck: resolve
	cd tests && bash memcheck.sh

# Compare resolution of graphs to the demes-python resolver.
pytest: resolve
	pytest -n auto tests/compare-reference-implementation.py

clean:
	rm -f resolve libdemes.a *.o
	rm -f *.gcda *.gcno *.gcov
	$(MAKE) -C tests clean
