<?php


/*
<url>http://www.bookclub.ua/catalog/books/pop/product.html?id=35278</url>
	<title>Чорне сонце</title>
	<ISBN>978-966-14-9633-9</ISBN>
	<category>Книги</category>
    <category>Современные авторы</category>
	<author>http://www.bookclub.ua/authorbooks/?aid=14</author>
	<publisher>«Книжный Клуб «Клуб Семейного Досуга»</publisher>
	<seria></seria>
	<description>
Новинка від популярного автора!
Трагічні події на Донбасі очима бійців полку «Азов».
Головний герой, двадцятивосьмирічний юнак, який щиро любить свою країну,
		  прагне нової долі для неї і намагається робити все для цього, навіть ризикуючи власним життям...
	</description>
	<content></content>
	<format>135х205</format>
	<picture>http://www.bookclub.ua/images/db/goods/35278_52619.jpg</picture>
	<authorname>

url
title
ISBN
category
publisher
seria
description
content
format
picture
author
authorname
*/
/*
$file = file_get_contents('http://www.bookclub.ua/images/db/goods/35278_52619.jpg');
file_put_contents("C:/OpenServer/domains/Platforma/basic/views/site/xml/newimage.jpg", $file);
exit;
*/
libxml_use_internal_errors(true);
$movies = file_get_contents('C:\OpenServer\domains\Platforma\basic\views\site\xml\xml.xml');// article_all_1

try
{

	/*
		$movies = new DOMDocument;
		if (!$movies->load('C:\OpenServer\domains\Platforma\basic\views\site\xml\xml.xml')) {
			foreach (libxml_get_errors() as $error) {
				// handle errors here
				echo $error;
			}

			libxml_clear_errors();
		}
	*/


	$movies = new SimpleXMLElement($movies);
	echo "<pre>";
	//print_r($movies);exit;
	$book=$movies->books;
	//$cursor = iterator_to_array($movies->book);
	print_r($book);exit;
	//print_r($book);
	for($i=0;$i<count($book);$i++){
		foreach($book[$i] as $k=>$v){
			if($k=='category'){
				echo "<b>",$k,"</b> => ";
				echo "<b>",$v,"</b><br/>";
			}

		}
	}


	//echo $movies->movie[0]->plot;

}catch (\Exception $e){
	echo $e->getMessage();
}





if(0){

	if(0){
		function startElement($parser, $name, $attrs)
		{
			global $depth;
			echo str_repeat(" ", $depth * 3);
			// отступы     echo "Element: $name";

			// имя элемента
			$depth++; // увеличиваем глубину, чтобы браузер показал отступы
			foreach ($attrs as $attr => $value) {
				echo str_repeat(" ", $depth * 3); // отступы
				// выводим имя атрибута и его значение
				echo 'Attribute: '.$attr.' = '.$value.'';
			}
		}
		function endElement($parser, $name) {
			global $depth;
			$depth--; // уменьшаем глубину
		}

		$depth = 0;
		$file  = "data.xml";
		$xml_parser = xml_parser_create(); xml_set_element_handler($xml_parser, "startElement", "endElement");
		if (!($fp = fopen('C:\OpenServer\domains\Platforma\basic\views\site\xml\xml.xml', "r"))) {
			die("could not open XML input");
		}

		while ($data = fgets($fp)) {
			if (!xml_parse($xml_parser, $data, feof($fp))) {
				echo "XML Error: ";
				echo xml_error_string(xml_get_error_code($xml_parser));
				echo " at line ".xml_get_current_line_number($xml_parser);         break;
			}
		}
		xml_parser_set_option($xml_parser, XML_OPTION_CASE_FOLDING, 0);
		xml_parser_free($xml_parser);

	}












}

if(0){

	$p = xml_parser_create();
	xml_parse_into_struct($p, $article_all_1, $vals, $index);
	xml_parser_free($p);
	echo "<pre>";
	//echo "Index array\n";
	//print_r($index);
	echo "\nМассив Vals\n";
	print_r($vals);

	/*<book>
		<url>http://www.bookvoed.ru/book?id=3612728</url>
		<title>Ночной мост: Календарь 2005</title>
		<ISBN>0-00-165862-0</ISBN>
		<category>Изопродукция</category>
		<category>Календари</category>
		<category>Квартальные</category>

		<publisher></publisher>
		<seria></seria>
		<description></description>
		<content></content>
		<format></format>
		<picture></picture>

		<editor></editor>
		<editorname></editorname>
</book>*/



}

if(0){
	$dom = new DOMDocument();
	$dom->load('quotes.xml');
	echo '<ul>';
	foreach($dom->getElementsByTagname('quote') as $element){
		$year = $element->getAttribute('year');
		foreach(($element->childNodes) as $e){
			if(is_a($e, 'DOMElement')){
				if($e->tagName=='phrase'){
					$phrase = htmlspecialchars($e->textContent);
				}elseif($e->tagName=='author'){
					$author = htmlspecialchars($e->textContent);
				}
			}
		}
		echo "<li>$author: \"$phrase\" ($year)</li>";
	}
	echo '</ul>';
}
 