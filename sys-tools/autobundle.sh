#!/bin/sh

# create a CPAN autobundle and then push all of the snapshot bundles to
# a backup folder

cpan -a
cp  /root/.cpan/Bundle/Snapshot* output/cpan_bundles/
