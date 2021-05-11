CFLAGS=-Wall -O2 -g
# We use two posix extensions, strdup() and newlocale()/uselocale().
CC=gcc -std=c11 -D_POSIX_C_SOURCE=200809L

resolve: resolve.c demes.c demes.h
	$(CC) $(CFLAGS) $^ -o $@ -lyaml

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
	rm -f resolve
