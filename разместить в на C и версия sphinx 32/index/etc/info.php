<?php

?>

КОМАНДЫ
 sudo /usr/bin/indexer --all  --print-queries --config  /etc/sphinxsearch/sphinxbook.conf
 sudo /usr/bin/indexer --rotate  --all --config /etc/sphinxsearch/sphinxbook.conf
 sudo /usr/bin/searchd --config /etc/sphinxsearch/sphinxbook.conf --console --iostats --logdebugv
 sudo /usr/bin/searchd --stop --config /etc/sphinxsearch/sphinxbook.conf

 команда на запуск
 sudo start-stop-daemon -Sbvmp /var/lib/sphinxsearch/booksearchd.pid -x  /usr/bin/searchd -- --config /etc/sphinxsearch/sphinxbook.conf
 команда на остановку
 sudo start-stop-daemon -Kbvmp /var/lib/sphinxsearch/booksearchd.pid -x  /usr/bin/searchd -- --config /etc/sphinxsearch/sphinxbook.conf




