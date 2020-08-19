#!/usr/bin/env elvish

use github.com/dglmoore/elvish-libs/ppd

ppd:pushd data/sims

each [zip]{
	unzip $zip -d extract > /dev/null
	rm -rf extract/__MACOSX
	each [csv]{
		mv $csv (basename $csv)
	} [(find extract -name '*.csv' -type f)]
	rm -rf extract
} [(find zip -name '*.zip' -type f)]

sed -i 's/\([0-9]\)+/\1e+/g' *.csv
sed -i 's/\([0-9]\)-/\1e-/g' *.csv
sed -i 's/Region,/Region/g' *.csv
sed -i '/^,/d' *.csv

ppd:popd
