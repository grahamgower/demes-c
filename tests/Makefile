CFLAGS=-Wall -O0 -g --coverage -fPIC
#CC=gcc -std=c11 -D_POSIX_C_SOURCE=200809L
CC=gcc -std=c11 -D_GNU_SOURCE

test: setup
	bash tests.sh

setup:
	$(MAKE) -C .. clean
	$(MAKE) -C .. CFLAGS="$(CFLAGS)" resolve
	# mocked-resolve is broken on MacOS
	case "$$OSTYPE" in \
		darwin*) ;; \
		*) $(MAKE) mocked-resolve ;; \
	esac

# Ideally, we'd just LD_PRELOAD mockfail.so, but I couldn't get this to work.
# When using a binary built with --coverage, the coverage stats are dumped to
# a file after main() runs. However, this allocates memory, so we need to
# disable the memory allocation failure mocking before that. I was unable to
# get an __attribute__((destructor)) function to run before the gcov bits
# segfaulted.
mocked-resolve: mocked-resolve.c ../libdemes.a mockfail.so
	$(CC) $(CFLAGS) \
		mocked-resolve.c -o $@ ./mockfail.so -L.. -ldemes -lyaml

mockfail.so: mockfail.c
	$(CC) $(CFLAGS) -shared -o $@ mockfail.c -ldl

clean:
	rm -f mocked-resolve mockfail.so
	rm -f *.gcda *.gcno
