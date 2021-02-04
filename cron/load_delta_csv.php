<?php

// Переброс с RT индекса в plain index delta
//C:/sphinx/bin/indexer --config C:/index/etc/sphinxsearch/sphinxmysql.conf  --merge index_main deltaproductcsv --rotate  --merge-dst-range deleted 0 0
try{
    $pdosphinx = new PDO("mysql:host=localhost;port=9306;", "", "" );
    if($pdosphinx){
        $pdosphinx->query("SET NAMES utf8;");
        $res=$pdosphinx->query("SELECT id,product,category,fjson,price FROM rt_delta")->fetchAll(PDO::FETCH_ASSOC);
        echo '12~0~"new"~"new"~"Cheese"'."\n";
        $delim='~';
        foreach($res as $product){
            // индексация через отдачу вывода
          //  echo $product['id'].$delim. '"'. $product['product'].'"'.$delim. '"'.$product['product'].'"'.$delim. '"'.$product['category'].'"'.$delim. '"0"'.$delim. '"{}"'.$delim."'". $product["price"]."'". "\n";
        }
    }
    // Очистить RT
   // $pdosphinx->exec("TRUNCATE RTINDEX rt_delta;");
    // $pdosphinx->exec("DELETE FROM rt_delta;");


}catch (Exception $e){
//echo $e->getMessage();
}





if(0){

    ini_set('max_execution_time ',25800);
    ini_set('file_uploads ',1);
    ini_set('upload_max_filesize','1000M');
    ini_set('post_max_size','2000M');
    ini_set('max_file_uploads',4);
    $delim='~';
    if(file_exists('C:/index/source_item_delta.csv')){
        unlink('C:/index/source_item_delta.csv');
    }
    try{

        $pdosphinx = new PDO("mysql:host=localhost;port=9306;", "", "" );
        if($pdosphinx){

            $pdosphinx->query("SET NAMES utf8;");
            $res=$pdosphinx->query("SELECT id,product,category,fjson,price FROM rt_delta")->fetchAll(PDO::FETCH_ASSOC);
            $csv=fopen('C:/index/source_item_delta.csv','w+b');
            chmod('C:/index/source_item_delta.csv',0777);
            //echo '12~"new"~"new"~"Cheese"~0~"{}"~0'."\r\n";
            foreach($res as $product){

                // через сброс в файл с последующей командой индексации
               fwrite($csv,
                    $product['id'].$delim.
                    '"'. $product['product'].'"'.$delim.
                    '"'.$product['product'].'"'.$delim.
                    '"'.$product['category'].'"'.$delim.
                    "0".$delim.
                    '"'.$product['fjson'].'"'.$delim.
                    $product['price'].
                    "\r\n");
            }
            fclose($csv);


            //shell_exec("C:/sphinx/bin/indexer deltaproduct --config C:/index/etc/sphinxsearch/sphinxmysql.conf --rotate");
//shell_exec(" C:/sphinx/bin/indexer --config C:/index/etc/sphinxsearch/sphinxmysql.conf  --merge index_main deltaproduct --rotate  --merge-dst-range deleted 0 0");
            /*rt_field = product_field
            rt_field  = category_field
            rt_attr_string = product
            rt_attr_string = category
            rt_attr_uint    = deleted
            rt_attr_json    = fjson
            rt_attr_uint    = price


            csvpipe_field_string = product
            csvpipe_field = product_field
            csvpipe_field = category
            csvpipe_attr_uint = deleted
            csvpipe_attr_json = fjson
            csvpipe_attr_uint = price*/

        }


    }catch (Exception $e){
//echo $e->getMessage();
    }

}
