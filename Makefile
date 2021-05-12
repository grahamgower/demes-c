CFLAGS=-Wall -O2 -g
# We use two posix extensions, strdup() and newlocale()/uselocale().
CC=gcc -std=c11 -D_POSIX_C_SOURCE=200809L

resolve: resolve.c libdemes.a
	$(CC) $(CFLAGS) resolve.c -o $@ -lyaml -L. -ldemes

libdemes.a: demes.o unicodectype.o
	$(AR) r $@ $^

demes.o: demes.c demes.h

unicodectype.o: unicodectype.c unicodetype_db.h

test: memcheck pytest

# Resolve all the example files under valgrind to check for memory errors.
memcheck: resolve 
	for yaml in examples/*.yaml examples/tutorial/*.yaml; do \
		valgrind -q --leak-check=full ./resolve $$yaml >/dev/null ; \
		if [ $$? != "0" ]; then \
			echo "$$yaml: failed" ; \
			exit 1 ; \
		fi \
	done

# Compare resolution of graphs to the demes-python resolver.
pytest: resolve
	pytest -n auto --hypothesis-show-statistics test.py

clean:
	rm -f resolve libdemes.a *.o
