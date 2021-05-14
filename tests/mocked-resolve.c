#include <stdlib.h>
#include <errno.h>

#define MOCKED_RESOLVE
#include "../resolve.c"

// see mockfail.c
extern size_t fail_after;
extern size_t counter;

int
main(int argc, char **argv)
{
    int ret;

    setlocale(LC_ALL, "");

    if (argc != 2) {
        printf("usage: %s model.yaml\n", argv[0]);
        return -1;
    }

    for (fail_after=0; fail_after<100000; fail_after++) {
        counter = 0;
        if ((ret = resolve(argv[1])) == 0) {
            break;
        }
    }

    counter = 0;
    fail_after = -1;

    if (ret != 0) {
        fprintf(stderr, "mocked-resolve: %s: didn't exhaust all possible failures\n", argv[0]);
        return -1;
    }

    return 0;
}
