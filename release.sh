#/bin/bash
set -e

test -d release/metaparser || mkdir -p release/metaparser
for d in parser morph theme modules games main3.lua theme.ini README ChangeLog COPYING; do 
	cp -r $d release/metaparser
done

cd doc && make && cd ..

mkdir -p release/metaparser/doc

cp doc/*.pdf doc/*.md release/metaparser/doc
