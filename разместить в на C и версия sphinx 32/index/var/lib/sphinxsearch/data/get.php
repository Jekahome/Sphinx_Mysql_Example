<?php
//ini_set("auto_detect_line_endings", true);
//echo "1~'ffffffffffffffff'\n";
//return "1~'ffffffffffffffff'\n";

//popen()

/*
popen("source_item_no.txt", "r");


/* Добавляем перенаправление, чтобы прочитать stderr. * /
//$handle = popen('source_item_no.txt 2>&1', 'r');
$handle = popen('C:\OpenServer\domains\JediAssistant\common\components\var\lib\sphinxsearch\data\source_item_all.txt', 'r');
//echo "'$handle'; " . gettype($handle) . "\n";
ob_start();
echo fread($handle, 90096);
ob_get_flush();ob_clean();
pclose($handle);
*/



 //echo stream_get_contents(fwrite( tmpfile(), file_get_contents('C:\OpenServer\domains\JediAssistant\common\components\var\lib\sphinxsearch\data\source_item_all.txt')));
//echo file_get_contents('C:\OpenServer\domains\JediAssistant\common\components\var\lib\sphinxsearch\data\source_item_all.txt');



/*
$temp = tmpfile();
fwrite($temp, file_get_contents('C:\OpenServer\domains\JediAssistant\common\components\var\lib\sphinxsearch\data\source_item_all.txt'));
fseek($temp, 0);
ob_start();
echo fread($temp,1000000000);
ob_get_flush();
fclose($temp);

*/



/*
$temp = tmpfile();
//var_dump($temp);exit;
fwrite($temp, file_get_contents('C:\OpenServer\domains\JediAssistant\common\components\var\lib\sphinxsearch\data\source_item_all.txt'));


fseek($temp, 0);
ob_start();
while (!feof($temp)) {
	echo fgets($temp );
}
ob_get_flush();
//ob_end_flush();
ob_clean();
//fclose($temp); // происходит удаление файла
*/


/*
\Yii::$app->redis->set('d', '2');
$temp = tmpfile();
fwrite($temp, file_get_contents('C:\OpenServer\domains\JediAssistant\common\components\var\lib\sphinxsearch\data\source_item_all.txt'));
while (!feof($temp)) {
	echo fgets($temp );
	//echo fgetcsv($handle);
}*/





//$redis = \Yii::$app->redis;
/*
$temp = tmpfile();
fwrite($temp, file_get_contents('C:\OpenServer\domains\JediAssistant\common\components\var\lib\sphinxsearch\data\source_item_all.txt'));
fseek($temp, 0);
while (!feof($temp)) {
	//echo fgets($temp );
	//echo fgetcsv($handle);
	\Yii::$app->redis->set('testcsv',fgets($temp ));
	break;
}
fclose($temp);

$str ='1~"hello"';
*/
/*
 $redis->set('testcsv',$str);
//ob_start();
echo  str_getcsv($redis->get('testcsv'),'~');
//ob_get_flush();
*/
ob_start();
fwrite(fopen('C:\OpenServer\domains\JediAssistant\backend\web\testcsv.txt','a+b'), Yii::$app->redis->get('testcsv'));
echo  str_replace('\\','',Yii::$app->redis->get('testcsv'));
ob_get_flush();




/*

$temp = tmpfile();
fwrite($temp, file_get_contents('C:\OpenServer\domains\testvariablesphinx\basic\views\page\source_item_no.txt'));
$c=3;
fseek($temp, 0);
$i=0;
/** @var  $redis yii\redis\Connection * /
$redis = \Yii::$app->redis;
while (!feof($temp)  ){

	//$i++;

	$redis->lpush("tutorial", fgets($temp));

}
fclose($temp);
*/
//$redis->lrange("tutorial-list", 0 ,5);
