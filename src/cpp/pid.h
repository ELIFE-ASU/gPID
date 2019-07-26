#pragma once

#include "data.h"

#include <inform/pid.h>

auto pid(Data<int> const &data, std::string stimulus_name, int nbin) -> inform_pid_lattice*;

auto source_name(inform_pid_source const *src) -> std::string;

auto const source_label(inform_pid_source const *src) -> std::string;
