
  SELECT HIGH_PRIORITY SQL_BIG_RESULT  idc_books.book_id,
              idc_books.book,
              idc_books.book AS 'book_field',
              idc_books.book AS 'book_string',
              IFNULL(idc_books.isbn,''),
              IFNULL(idc_books.protagonist,''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_langs_hooks.lang_id),''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_formats_hooks.format_id),''),
              '0' AS 'is_deleted',
              IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_field',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_string',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),'')  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),'')  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),'')  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),'')  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),'')  AS 'category_id'
		   , IFNULL(idc_books.trigrams,''),IFNULL(idc_books.len,''),IFNULL(idc_books.count_tr,'') ,IFNULL(idc_books.count_word,'0')
 INTO OUTFILE 'C:/index/source_item_index1.csv'
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
		 LEFT JOIN  idc_book_langs_hooks     ON idc_books.book_id = idc_book_langs_hooks.book_id
		 LEFT JOIN  idc_book_formats_hooks   ON idc_books.book_id = idc_book_formats_hooks.book_id
		 WHERE idc_book_author_hooks.author_id = idc_authors.author_id AND
		 idc_categories.category_id = idc_book_categories_hooks.category_id  AND
		  idc_books.book_id <= 25000
		 GROUP BY idc_books.book_id;





  SELECT HIGH_PRIORITY SQL_BIG_RESULT  idc_books.book_id,
              idc_books.book,
              idc_books.book AS 'book_field',
              idc_books.book AS 'book_string',
              IFNULL(idc_books.isbn,''),
              IFNULL(idc_books.protagonist,''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_langs_hooks.lang_id),''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_formats_hooks.format_id),''),
              '0' AS 'is_deleted',
              IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_field',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_string',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),'')  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),'')  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),'')  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),'')  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),'')  AS 'category_id'
		   ,IFNULL(idc_books.trigrams,''),IFNULL(idc_books.len,''),IFNULL(idc_books.count_tr,'') ,IFNULL(idc_books.count_word,'0')
 INTO OUTFILE 'C:/index/source_item_index2.csv'
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
		 LEFT JOIN  idc_book_langs_hooks     ON idc_books.book_id = idc_book_langs_hooks.book_id
		 LEFT JOIN  idc_book_formats_hooks   ON idc_books.book_id = idc_book_formats_hooks.book_id
		 WHERE idc_book_author_hooks.author_id = idc_authors.author_id AND
		 idc_categories.category_id = idc_book_categories_hooks.category_id  AND
		  idc_books.book_id > 25000 AND idc_books.book_id <= 50000
		 GROUP BY idc_books.book_id;






   SELECT HIGH_PRIORITY SQL_BIG_RESULT  idc_books.book_id,
              idc_books.book,
              idc_books.book AS 'book_field',
              idc_books.book AS 'book_string',
              IFNULL(idc_books.isbn,''),
              IFNULL(idc_books.protagonist,''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_langs_hooks.lang_id),''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_formats_hooks.format_id),''),
              '0' AS 'is_deleted',
              IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_field',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_string',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),'')  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),'')  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),'')  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),'')  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),'')  AS 'category_id'
		   ,IFNULL(idc_books.trigrams,''),IFNULL(idc_books.len,''),IFNULL(idc_books.count_tr,'') ,IFNULL(idc_books.count_word,'0')
 INTO OUTFILE 'C:/index/source_item_index3.csv'
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
		 LEFT JOIN  idc_book_langs_hooks     ON idc_books.book_id = idc_book_langs_hooks.book_id
		 LEFT JOIN  idc_book_formats_hooks   ON idc_books.book_id = idc_book_formats_hooks.book_id
		 WHERE idc_book_author_hooks.author_id = idc_authors.author_id AND
		 idc_categories.category_id = idc_book_categories_hooks.category_id  AND
		  idc_books.book_id > 50000 AND idc_books.book_id <= 75000
		 GROUP BY idc_books.book_id;





  SELECT HIGH_PRIORITY SQL_BIG_RESULT  idc_books.book_id,
              idc_books.book,
              idc_books.book AS 'book_field',
              idc_books.book AS 'book_string',
              IFNULL(idc_books.isbn,''),
              IFNULL(idc_books.protagonist,''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_langs_hooks.lang_id),''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_formats_hooks.format_id),''),
              '0' AS 'is_deleted',
              IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_field',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_string',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),'')  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),'')  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),'')  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),'')  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),'')  AS 'category_id'
		   ,IFNULL(idc_books.trigrams,''),IFNULL(idc_books.len,''),IFNULL(idc_books.count_tr,'') ,IFNULL(idc_books.count_word,'0')
 INTO OUTFILE 'C:/index/source_item_index4.csv'
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
		 LEFT JOIN  idc_book_langs_hooks     ON idc_books.book_id = idc_book_langs_hooks.book_id
		 LEFT JOIN  idc_book_formats_hooks   ON idc_books.book_id = idc_book_formats_hooks.book_id
		 WHERE idc_book_author_hooks.author_id = idc_authors.author_id AND
		 idc_categories.category_id = idc_book_categories_hooks.category_id  AND
		  idc_books.book_id > 75000
		 GROUP BY idc_books.book_id;

