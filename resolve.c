#include <stdio.h>
#include <locale.h>

#include <yaml.h>
#include "demes.h"

int
main(int argc, char **argv)
{
    struct demes_graph *graph;
    int ret;

    setlocale(LC_ALL, "");

    if (argc != 2) {
        printf("usage: %s model.yaml\n", argv[0]);
        return 1;
    }
    if ((ret = demes_graph_load(argv[1], &graph))) {
        fprintf(stderr, "failed while loading %s\n", argv[1]);
    }
    if (ret == 0) {
        if ((ret = demes_graph_dump(graph, stdout))) {
            fprintf(stderr, "failed while dumping graph\n");
        }
    }
    demes_graph_free(graph);
    return ret;
}
