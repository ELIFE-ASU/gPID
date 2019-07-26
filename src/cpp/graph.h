#pragma once

#include "pid.h"
#include <graphviz/cgraph.h>

auto agraph(inform_pid_lattice const *lattice) -> Agraph_t*;
auto write_graph(Agraph_t *graph, std::string filename) -> void;
