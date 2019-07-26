#pragma once

#include <iomanip>
#include <iostream>
#include <map>
#include <string>
#include <vector>

template <typename T>
using Vec = std::vector<T>;

template <typename T>
using Data = std::map<std::string, Vec<T>>;

template <typename T>
auto operator<<(std::ostream &out, Data<T> const& data) -> std::ostream& {
    for (auto const entry: data) {
        out << std::setw(10) << std::left << (std::get<0>(entry) + ": ");
        for (auto const &datum: std::get<1>(entry)) {
            out << std::setw(6) << std::left << std::setprecision(3) << datum;
        }
        out << '\n';
    }
    return out;
}

auto bin(Data<double> const& data, int nbin) -> Data<int32_t>;

auto read_data(std::string filename) -> Data<double>;
