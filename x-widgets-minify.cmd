@echo off

du -shc x-*.js divs.js glue.js
echo.

cat x-*.js divs.js glue.js | gzip - > x-widgets.js.gz
du -sh x-widgets.js.gz
echo.

cat x-*.js divs.js glue.js | jsmin | gzip - > x-widgets.min.js.gz
du -sh x-widgets.min.js.gz
echo.

wc -l x-*.js divs.js glue.js
echo.

rm x-widgets.js.gz
rm x-widgets.min.js.gz
