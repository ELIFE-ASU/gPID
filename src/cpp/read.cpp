#include "data.h"

#include <csv.h>
#include <cstdio>

struct Accumulator {
    size_t field = 0;
    size_t rows = 0;
    std::vector<std::string> names;
    Data<double> data;

    Accumulator(size_t field, size_t rows): field{field}, rows{rows} {}
};

static auto field(void *s, size_t len, void *data) -> void{
    if (s) {
        auto *acc = static_cast<Accumulator*>(data);
        if (acc->rows == 0) {
            auto const name = std::string((char*)s, len);
            acc->names.push_back(name);
            acc->data[name] = Vec<double>{};
        } else if (acc->names.size() && acc->field >= acc->names.size()) {
            auto const nfields = acc->names.size();
            auto const field = acc->field;
            auto const rows = acc->rows;
            std::cerr << "expected " << nfields << " fields got " << field << " on line " << rows << std::endl;
            exit(EXIT_FAILURE);
        } else {
            auto const name = acc->names.at(acc->field);
            auto const value = std::atof(static_cast<char*>(s));
            acc->data[name].push_back(value);
        }
        acc->field++;
    }
}

static auto row(int c, void *data) -> void {
    auto *acc = static_cast<Accumulator*>(data);
    acc->rows++;
    if (acc->names.size() && acc->field < acc->names.size()) {
        auto const nfields = acc->names.size();
        auto const field = acc->field;
        auto const rows = acc->rows;
        std::cerr << "expected " << nfields << " fields got " <<field << " on line " << rows << std::endl;
        exit(EXIT_FAILURE);
    }
    acc->field = 0;
}

auto read_data(std::string filename) -> Data<double> {
    csv_parser p;
    char buffer[1024];
    size_t bytes_read = 0;

    auto acc = Accumulator{0, 0};

    if (csv_init(&p, 0) != 0) {
        exit(EXIT_FAILURE);
    }

    auto fp = fopen(filename.c_str(), "rb");
    if (!fp) {
        exit(EXIT_FAILURE);
    }

    while ((bytes_read = fread(buffer, 1, 1024, fp)) > 0) {
        if (csv_parse(&p, buffer, bytes_read, field, row, &acc) != bytes_read) {
            fprintf(stderr, "Error while parsing file: %s\n",
                csv_strerror(csv_error(&p)));
            exit(EXIT_FAILURE);
        }
    }

    csv_fini(&p, field, row, &acc);

    fclose(fp);

    csv_free(&p);

    return acc.data;
}
