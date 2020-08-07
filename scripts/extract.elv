#!/usr/bin/env elvish

use github.com/dglmoore/elvish-libs/ppd

ppd:pushd data/sims

each [dir]{
    each [zip]{ unzip $zip -d $dir > /dev/null } [(find $dir -name '*.zip' -type f)]

    rm -r $dir"/__MACOSX"

    each [csv]{
       filename = 'date='(basename $dir)'_'(basename $csv)
       mv $csv $filename
    } [(find $dir -name '*.csv' -type f)]
} [(find . -name '2020*' -type d)]

sed -i 's/\([0-9]\)+/\1e+/g' *.csv
sed -i 's/\([0-9]\)-/\1e-/g' *.csv
sed -i 's/Region,/Region/g' *.csv
sed -i '/^,/d' *.csv

find . -name 'ps-recom*' -type d -delete
find . -name '*minusFu*' -type f -delete

ppd:popd
