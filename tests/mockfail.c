/*
   To test memory allocation failures, we wrap the allocation functions
   so they fail after a certain number of invocations.
*/
/*#define _GNU_SOURCE*/
#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <locale.h>
#include <errno.h>
#ifdef __APPLE__
#include <xlocale.h>
#endif

#include "yaml.h"

// libc
static void *(*__real_malloc)(size_t) = NULL;
static void *(*__real_realloc)(void *, size_t) = NULL;
static void *(*__real_calloc)(size_t, size_t) = NULL;
static locale_t (*__real_newlocale)(int, const char *, locale_t) = NULL;
static locale_t (*__real_uselocale)(locale_t) = NULL;
// libyaml
static int (*__real_yaml_document_append_mapping_pair)(
        yaml_document_t *, int, int, int) = NULL;
static int (*__real_yaml_document_append_sequence_item)(
        yaml_document_t *, int, int) = NULL;
static int (*__real_yaml_emitter_open)(yaml_emitter_t *) = NULL;
static int (*__real_yaml_emitter_close)(yaml_emitter_t *) = NULL;

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
    if (!(__real_newlocale = dlsym(RTLD_NEXT, "newlocale"))) {
        fprintf(stderr, "mockfail: dlsym: newlocale: %s\n", dlerror());
        abort();
    }
    if (!(__real_uselocale = dlsym(RTLD_NEXT, "uselocale"))) {
        fprintf(stderr, "mockfail: dlsym: uselocale: %s\n", dlerror());
        abort();
    }
    if (!(__real_yaml_document_append_mapping_pair = dlsym(
                    RTLD_NEXT, "yaml_document_append_mapping_pair"))) {
        fprintf(stderr, "mockfail: dlsym: yaml_document_append_mapping_pair: %s\n",
                dlerror());
        abort();
    }
    if (!(__real_yaml_document_append_sequence_item = dlsym(
                    RTLD_NEXT, "yaml_document_append_sequence_item"))) {
        fprintf(stderr, "mockfail: dlsym: yaml_document_append_sequence_item: %s\n",
                dlerror());
        abort();
    }
    if (!(__real_yaml_emitter_open = dlsym(RTLD_NEXT, "yaml_emitter_open"))) {
        fprintf(stderr, "mockfail: dlsym: yaml_emitter_open: %s\n", dlerror());
        abort();
    }
    if (!(__real_yaml_emitter_close = dlsym(RTLD_NEXT, "yaml_emitter_close"))) {
        fprintf(stderr, "mockfail: dlsym: yaml_emitter_close: %s\n", dlerror());
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

locale_t
newlocale(int category_mask, const char *locale, locale_t base)
{
    if (++counter > fail_after) {
        errno = ENOMEM;
        return (locale_t)0;
    } else {
        return __real_newlocale(category_mask, locale, base);
    }
}

locale_t
uselocale(locale_t newloc)
{
    if (++counter > fail_after) {
        errno = EINVAL;
        return (locale_t)0;
    } else {
        return __real_uselocale(newloc);
    }
}

int
yaml_document_append_mapping_pair(
        yaml_document_t *document,
        int mapping, int key, int value)
{
    if (++counter > fail_after) {
        errno = ENOMEM;
        return 0;
    } else {
        return __real_yaml_document_append_mapping_pair(
                document, mapping, key, value);
    }
}

int
yaml_document_append_sequence_item(
        yaml_document_t *document,
        int sequence, int item)
{
    if (++counter > fail_after) {
        errno = ENOMEM;
        return 0;
    } else {
        return __real_yaml_document_append_sequence_item(document, sequence, item);
    }
}

int
yaml_emitter_open(yaml_emitter_t *emitter)
{
    if (++counter > fail_after) {
        return 0;
    } else {
        return __real_yaml_emitter_open(emitter);
    }
}

int
yaml_emitter_close(yaml_emitter_t *emitter)
{
    if (++counter > fail_after) {
        return 0;
    } else {
        return __real_yaml_emitter_close(emitter);
    }
}
