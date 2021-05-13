CFLAGS=-Wall -O2 -g
# We use two posix extensions, strdup() and newlocale()/uselocale().
CC=gcc -std=c11 -D_POSIX_C_SOURCE=200809L

resolve: resolve.c libdemes.a
	$(CC) $(CFLAGS) resolve.c -o $@ -L. -ldemes -lyaml

libdemes.a: demes.o unicodectype.o
	$(AR) r $@ $^

demes.o: demes.c demes.h

unicodectype.o: unicodectype.c unicodetype_db.h

test: memcheck-valid memcheck-invalid pytest

# Resolve the valid example models under valgrind to check for memory errors.
memcheck-valid: resolve
	for yaml in examples/*.yaml examples/tutorial/*.yaml ; do \
		valgrind -q --leak-check=full --error-exitcode=255 \
			./resolve $$yaml >/dev/null ; \
		ret=$$? ; \
		if [ $$ret -ge "128" ]; then \
			echo "$$yaml: memory error" ; \
			exit 1 ; \
		elif [ "$$ret" != "0" ]; then \
			echo "$$yaml: failed to resolve valid model" ; \
			exit 2 ; \
		fi \
	done

# Check that the resolver raises errors for invalid models,
# and that there are no memory leaks.
memcheck-invalid: resolve
	for yaml in \
		examples/bad-models/*.yaml; \
	do \
		valgrind -q --leak-check=full --error-exitcode=255 \
			./resolve $$yaml >/dev/null ; \
		ret=$$? ; \
		if [ $$ret -ge "128" ]; then \
			echo "$$yaml: memory error" ; \
			exit 1 ; \
		elif [ $$ret = "0" ]; then \
			echo "$$yaml: failed to reject invalid model" ; \
			exit 2 ; \
		fi \
	done

# Compare resolution of graphs to the demes-python resolver.
pytest: resolve
	pytest -n auto --hypothesis-show-statistics test.py

coverage:
	$(MAKE) clean
	$(MAKE) CFLAGS="-Wall -O0 -g --coverage"
	find examples -name "*.yaml" -exec ./resolve {} \; > /dev/null 2>&1
	gcov -p *.c

clean:
	rm -f resolve libdemes.a *.o
	rm -f *.gcda *.gcno *.gcov
