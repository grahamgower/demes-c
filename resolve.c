#include <stdio.h>
#include <locale.h>

#include <yaml.h>
#include "demes.h"

int
resolve(char *filename)
{
    struct demes_graph *graph;
    int ret;
    if ((ret = demes_graph_load(filename, &graph))) {
        fprintf(stderr, "failed while loading %s\n", filename);
    }
    if (ret == 0) {
        if ((ret = demes_graph_dump(graph, stdout))) {
            fprintf(stderr, "failed while dumping graph\n");
        }
    }
    demes_graph_free(graph);
    return ret;
}

#ifndef MOCKED_RESOLVE
int
main(int argc, char **argv)
{
    // Setting a locale is optional. libdemes works with any locale set.
    setlocale(LC_ALL, "");

    if (argc != 2) {
        printf("usage: %s model.yaml\n", argv[0]);
        return 1;
    }

    return resolve(argv[1]);
}
#endif
