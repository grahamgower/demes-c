/*
   To test memory allocation failures, we wrap the allocation functions
   so they fail after a certain number of invocations.
*/
#define _GNU_SOURCE
#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <errno.h>

static void *(*__real_malloc)(size_t) = NULL;
static void *(*__real_realloc)(void *, size_t) = NULL;
static void *(*__real_calloc)(size_t, size_t) = NULL;

size_t fail_after = -1;
size_t counter = 0;

__attribute__((constructor))
static void
mockinit()
{
    if (!(__real_malloc = dlsym(RTLD_NEXT, "malloc"))) {
        fprintf(stderr, "mockfail: dlsym: malloc: %s\n", dlerror());
        abort();
    }
    if (!(__real_realloc = dlsym(RTLD_NEXT, "realloc"))) {
        fprintf(stderr, "mockfail: dlsym: realloc: %s\n", dlerror());
        abort();
    }
    if (!(__real_calloc = dlsym(RTLD_NEXT, "calloc"))) {
        fprintf(stderr, "mockfail: dlsym: calloc: %s\n", dlerror());
        abort();
    }
}

void *
malloc(size_t size)
{
    if (++counter > fail_after) {
        errno = ENOMEM;
        return NULL;
    } else {
        return __real_malloc(size);
    }
}

void *
calloc(size_t nmemb, size_t size)
{
    if (++counter > fail_after) {
        errno = ENOMEM;
        return NULL;
    } else {
        return __real_calloc(nmemb, size);
    }
}

void *
realloc(void* ptr, size_t size)
{
    if (++counter > fail_after) {
        errno = ENOMEM;
        return NULL;
    } else {
        return __real_realloc(ptr, size);
    }
}

