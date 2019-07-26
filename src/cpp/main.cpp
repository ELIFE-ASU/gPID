#include "graph.h"

#include <string>
#include <regex>

auto normalize(std::string str) -> std::string {
    auto end = std::transform(str.begin(), str.end(), str.begin(), [](char c){ return std::tolower(c); });
    end = std::regex_replace(str.begin(), str.begin(), end, std::regex("\\s+"), "_");
    end = std::regex_replace(str.begin(), str.begin(), end, std::regex("/"), "-");
    end = std::regex_replace(str.begin(), str.begin(), end, std::regex("'"), "");
    return std::string(str.begin(), end);
}

auto main(int argc, char **argv) -> int {
    if (argc < 2 || argc > 4) {
        std::cerr << "usage: " << argv[0] << " <filename> [nbin = 2]" << std::endl;
        return 1;
    }

    auto const filename = std::string(argv[1]);
    auto nbin = (argc == 2) ? 2 : std::atoi(argv[2]);

    auto const coding = bin(read_data(filename), nbin);

    for (auto const entry: coding) {
        auto const &name = std::get<0>(entry);
        auto lattice = pid(coding, name, nbin);

        auto graph = agraph(lattice);
        try {
            write_graph(graph, normalize(name) + ".pdf");
            for (size_t i = 0; i < lattice->size; ++i) {
                if (lattice->sources[i]->pi > 1e-6) {
                    std::cout << std::setw(14) << std::right << source_name(lattice->sources[i]) << ": "
                              << std::setw(14) << std::left << lattice->sources[i]->pi
                              << std::endl;
                }
            }
            std::cout << std::setw(14) << "Total" << ": " << lattice->top->imin << '\n' << std::endl;
        } catch (std::exception &e) {
            agclose(graph);
            inform_pid_lattice_free(lattice);
            throw e;
        }
        agclose(graph);
        inform_pid_lattice_free(lattice);
    }
}
