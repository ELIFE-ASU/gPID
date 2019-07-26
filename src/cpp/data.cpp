#include "data.h"
#include <inform/utilities/binning.h>

auto bin(Data<double> const& data, int nbin) -> Data<int32_t> {
    auto binned = Data<int32_t>{};
    for (auto const entry: data) {
        auto const& raw_col = std::get<1>(entry);
        auto col = Vec<int>(raw_col.size());
        inform_error err = INFORM_SUCCESS;
        inform_bin(raw_col.data(), raw_col.size(), nbin, col.data(), &err);
        if (err) {
            throw std::runtime_error(inform_strerror(&err));
        }
        binned[std::get<0>(entry)] = col;
    }
    return binned;
}