/*
   To test memory allocation failures, we wrap the allocation functions
   so they fail after a certain number of invocations. The environment
   variable FAIL_AFTER controls the number of allocations before failures
   begin to occur.

   The linker must be given the special option -Wl,--wrap=malloc so that
   the __wrap_malloc() function below will be used instead of the original
   malloc, and __real_malloc will point to the original. Likewise for the
   calloc and realloc cases.
*/
#include <stdlib.h>
#include <errno.h>

void *__real_malloc(size_t);
void *__real_realloc(void *, size_t);
void *__real_calloc(size_t, size_t);
void *__real_strdup(const char *);

static size_t fail_after = -1;
static size_t counter = 0;

__attribute__((constructor))
void
init()
{
    char *env = getenv("FAIL_AFTER");
    if (env) {
        fail_after = atoi(env);
    }
}

__attribute__((destructor))
void
deinit()
{
    /*
     * We assess test coverage using the gcc --coverage flag, which inserts
     * instrumentation code into the binary and has a post-main() hook to
     * dump the coverage stats to a file. However, this hook allocates memory.
     * So here we reset fail_after so that allocations may again succeed once
     * the main() function has returned.
     */
    fail_after = -1;
}

void *
__wrap_malloc(size_t size)
{
    if (++counter > fail_after) {
        errno = ENOMEM;
        return NULL;
    } else {
        return __real_malloc(size);
    }
}

void *
__wrap_calloc(size_t nmemb, size_t size)
{
    if (++counter > fail_after) {
        errno = ENOMEM;
        return NULL;
    } else {
        return __real_calloc(nmemb, size);
    }
}

void *
__wrap_realloc(void* ptr, size_t size)
{
    if (++counter > fail_after) {
        errno = ENOMEM;
        return NULL;
    } else {
        return __real_realloc(ptr, size);
    }
}

void *
__wrap_strdup(const char *s)
{
    if (++counter > fail_after) {
        errno = ENOMEM;
        return NULL;
    } else {
        return __real_strdup(s);
    }
}
