#!/usr/bin/env elvish

use github.com/dglmoore/elvish-libs/ppd

ppd:pushd data/sims

each [zip]{
	unzip $zip -d extract > /dev/null
	rm -rf extract/__MACOSX
	each [csv]{
		mv $csv (basename $csv | sed -E 's/date=([0-9]{2})([0-9]{2})_/date=2020-\1-\2_/')
	} [(find extract -name '*.csv' -type f)]
	rm -rf extract
} [(find zip -name '*.zip' -type f)]

sed -i 's/\([0-9]\)+/\1e+/g' *.csv
sed -i 's/\([0-9]\)-/\1e-/g' *.csv
sed -i 's/Region,/Region/g' *.csv
sed -i '/^,/d' *.csv

find . -name '*=NULL*.csv' -delete

ppd:popd
