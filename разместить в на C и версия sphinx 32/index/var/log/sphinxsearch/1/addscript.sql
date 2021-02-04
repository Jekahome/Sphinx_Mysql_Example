# sql_field_string = book
# sql_field_string = protagonist
# sql_field_string = author
# sql_field_string = category
# sql_field_string = category_id
# sql_field_string = isbn
# sql_attr_uint    = lang_id
# sql_attr_bool    = is_deleted
#
# sql_attr_multi = author_id
# sql_attr_multi = list_id
# sql_attr_multi = publisher_id
# sql_attr_multi = series_id
 



 


		  SELECT HIGH_PRIORITY SQL_BIG_RESULT  idc_books.book_id,idc_books.book,IFNULL(idc_books.isbn,''),IFNULL(idc_books.protagonist,''),IFNULL(idc_books.lang_id,''),IFNULL(idc_books.format_id,''),"0" AS 'is_deleted',IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),"{'seria_id':[]}")  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),"{'publisher_id':[]}")  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),"{'list_id':[]}")  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),"{'author_id':[]}")  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),"{'category_id':[]}")  AS 'category_id'
 INTO OUTFILE 'C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data/source_item_index11.csv'
 CHARACTER SET UTF8
 FIELDS TERMINATED BY '~'
 OPTIONALLY ENCLOSED BY '"'
 ESCAPED BY '\\'
 LINES TERMINATED BY '\r\n'
		 FROM  idc_authors,idc_categories,idc_books
		 LEFT JOIN idc_book_author_hooks     ON idc_books.book_id = idc_book_author_hooks.book_id
		 LEFT JOIN idc_book_categories_hooks ON idc_books.book_id = idc_book_categories_hooks.book_id
		 LEFT JOIN idc_book_series_hooks     ON idc_books.book_id = idc_book_series_hooks.book_id
		 LEFT JOIN idc_book_publisher_hooks  ON idc_books.book_id = idc_book_publisher_hooks.book_id
		 LEFT JOIN idc_book_list_hooks       ON idc_books.book_id = idc_book_list_hooks.book_id
		 WHERE idc_book_author_hooks.author_id = idc_authors.author_id AND
		 idc_categories.category_id = idc_book_categories_hooks.category_id  AND
		  idc_books.book_id >= 1
		 GROUP BY idc_books.book_id;








 





 