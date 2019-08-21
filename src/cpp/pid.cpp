#include "pid.h"

#include <algorithm>
#include <iomanip>
#include <iterator>
#include <sstream>
#include <stdexcept>

auto pid(Data<int> const &data, std::string stimulus_name, int nbin) -> inform_pid_lattice* {
    auto stimulus = data.at(stimulus_name);

    std::cout << std::setw(6) << std::left << stimulus_name << ": ";
    auto responses = Vec<int>{};
    for (auto const entry: data) {
        if (std::get<0>(entry) != stimulus_name) {
            std::cout << std::setw(7) << std::get<0>(entry);
            auto const &col = std::get<1>(entry);
            std::copy(std::begin(col), std::end(col), std::back_inserter(responses));
        }
    }
    std::cout << std::endl;

    auto const l = data.size() - 1;
    auto const n = stimulus.size();
    if (responses.size() != l * n) {
        throw std::runtime_error("you done goofed");
    }

    auto br = Vec<int>(data.size() - 1);
    std::fill(std::begin(br), std::end(br), nbin);

    inform_error err = INFORM_SUCCESS;
    auto pid = inform_pid(stimulus.data(), responses.data(), l, n, nbin, br.data(), &err);
    if (err) {
        throw std::runtime_error(inform_strerror(&err));
    }

    return pid;
}

auto source_name(inform_pid_source const *src) -> std::string {
    std::stringstream namestream;
    std::copy(src->name, src->name + src->size, std::ostream_iterator<int>(namestream, " "));
    auto const name = namestream.str();
    return name.substr(0, name.size()-1);
}

auto source_label(inform_pid_source const *src) -> std::string {
    std::stringstream labelstream;
    labelstream << '(' << source_name(src) << " | "
                << ((src->imin < 1e-6) ? 0 : src->imin) << ", "
                << ((src->pi < 1e-6) ? 0 : src->pi) << ')';
    return labelstream.str();
}
