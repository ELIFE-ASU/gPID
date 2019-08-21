#include "graph.h"
#include <algorithm>
#include <graphviz/gvc.h>
#include <sstream>

static auto tohexcolor(double max, double value) -> std::string {
    if (max < 1e-6) {
        return "#ffffff";
    } else if (value < 1e-6) {
        return "#000000";
    }
    auto color = int(0xff * 0.5 * (1 + (value / max)));
    std::stringstream hexstream;
    hexstream << std::setfill('0') << std::setw(2*sizeof(char)) << std::hex << color;
    auto const hex = hexstream.str();
    return "#" + hex + hex + hex;
}

auto agraph(inform_pid_lattice const *lattice) -> Agraph_t* {
    Agraph_t *graph = agopen("g", Agdirected, NULL);

    auto max = 0.0;
    auto const start = lattice->sources, stop = start + lattice->size;
    std::for_each(start, stop, [&max](inform_pid_source const *src) {
        max = std::max(max, src->pi);
    });

    auto index = std::map<std::string, Agnode_t*>{};
    for (size_t i = 0; i < lattice->size; ++i) {
        auto const src = lattice->sources[i];

        auto const node = agnode(graph, NULL, 1);
        auto const name = source_name(src);

        agsafeset(node, "label", (char*)source_label(src).c_str(), "");
        agsafeset(node, "style", "filled", "");
        agsafeset(node, "fillcolor", (char*)tohexcolor(max, src->pi).c_str(), "");

        index[name] = node;
    }

    std::for_each(start, stop, [&graph, &index, &max](inform_pid_source *src) {
        auto const source_node = index.at(source_name(src));
        std::for_each(src->above, src->above + src->n_above, [&graph, &index, &source_node](inform_pid_source *tar) {
            auto const target_node = index.at(source_name(tar));
            agedge(graph, source_node, target_node, NULL, 1);
        });
    });

    return graph;
}

auto write_graph(Agraph_t *graph, std::string filename) -> void {
    auto handle = fopen(filename.c_str(), "w");
    if (!handle) {
        throw std::runtime_error("cannot open file \"" + filename +"\"");
    }

    static GVC_t *gvc;
    if (!gvc) {
        gvc = gvContext();
    }

    if (gvLayout(gvc, graph, "dot")) {
        throw std::runtime_error("cannot layout graph");
    }
    if (gvRender(gvc, graph, "pdf", handle)) {
        throw std::runtime_error("cannot render graph");
    }

    gvFreeLayout(gvc, graph);

    fclose(handle);
}
