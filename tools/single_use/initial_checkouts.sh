#!/bin/sh

# run this script from the top directory.  use it to set up initial framework SVN checkouts

svn co https://ww1.wundercounter.com/open_source/wunder-tools/trunk/lib/Wunder/Framework lib/Wunder/Framework
svn co https://ww1.wundercounter.com/open_source/wunder-tools/trunk/tools wunder-tools
svn co https://ww1.wundercounter.com/open_source/wunder-tools/trunk/t/framework t/framework
svn co https://ww1.wundercounter.com/open_source/wunder-tools/trunk/templates templates/framework

