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

# isbn хранится в базе в виде i1541-41854-48418i i- это ранкер
//////////////////////////////////////////////////////////////////////////////////////////////////////////
DELIMITER $$

CREATE DEFINER =`idc_bookinist`@`localhost` FUNCTION `jaro_winkler_similarity`(
  in1 VARCHAR(255),
  in2 VARCHAR(255)
)
  RETURNS FLOAT
DETERMINISTIC
  BEGIN
#finestra:= search window, curString:= scanning cursor for the original string, curSub:= scanning cursor for the compared string
    DECLARE finestra, curString, curSub, maxSub, trasposizioni, prefixlen, maxPrefix INT;
    DECLARE char1, char2 CHAR(1);
    DECLARE common1, common2, old1, old2 VARCHAR(255);
    DECLARE trovato BOOLEAN;
    DECLARE returnValue, jaro FLOAT;
    SET maxPrefix = 6;
#from the original jaro - winkler algorithm
    SET common1 = "";
    SET common2 = "";
    SET finestra = (length(in1) + length(in2) - abs(length(in1) - length(in2))) DIV 4
                   + ((length(in1) + length(in2) - abs(length(in1) - length(in2))) / 2) MOD 2;
    SET old1 = in1;
    SET old2 = in2;

#calculating common letters vectors
    SET curString = 1;
    WHILE curString <= length(in1) AND (curString <= (length(in2) + finestra)) DO
      SET curSub = curstring - finestra;
      IF (curSub) < 1
      THEN
        SET curSub = 1;
      END IF;
      SET maxSub = curstring + finestra;
      IF (maxSub) > length(in2)
      THEN
        SET maxSub = length(in2);
      END IF;
      SET trovato = FALSE;
      WHILE curSub <= maxSub AND trovato = FALSE DO
        IF substr(in1, curString, 1) = substr(in2, curSub, 1)
        THEN
          SET common1 = concat(common1, substr(in1, curString, 1));
          SET in2 = concat(substr(in2, 1, curSub - 1), concat("0", substr(in2, curSub + 1, length(in2) - curSub + 1)));
          SET trovato = TRUE;
        END IF;
        SET curSub = curSub + 1;
      END WHILE;
      SET curString = curString + 1;
    END WHILE;
#back to the original string
    SET in2 = old2;
    SET curString = 1;
    WHILE curString <= length(in2) AND (curString <= (length(in1) + finestra)) DO
      SET curSub = curstring - finestra;
      IF (curSub) < 1
      THEN
        SET curSub = 1;
      END IF;
      SET maxSub = curstring + finestra;
      IF (maxSub) > length(in1)
      THEN
        SET maxSub = length(in1);
      END IF;
      SET trovato = FALSE;
      WHILE curSub <= maxSub AND trovato = FALSE DO
        IF substr(in2, curString, 1) = substr(in1, curSub, 1)
        THEN
          SET common2 = concat(common2, substr(in2, curString, 1));
          SET in1 = concat(substr(in1, 1, curSub - 1), concat("0", substr(in1, curSub + 1, length(in1) - curSub + 1)));
          SET trovato = TRUE;
        END IF;
        SET curSub = curSub + 1;
      END WHILE;
      SET curString = curString + 1;
    END WHILE;
#back to the original string
    SET in1 = old1;

#calculating jaro metric
    IF length(common1) <> length(common2)
    THEN SET jaro = 0;
    ELSEIF length(common1) = 0 OR length(common2) = 0
      THEN SET jaro = 0;
    ELSE
#calcolo la distanza di winkler
#passo 1: calcolo le trasposizioni
      SET trasposizioni = 0;
      SET curString = 1;
      WHILE curString <= length(common1) DO
        IF (substr(common1, curString, 1) <> substr(common2, curString, 1))
        THEN
          SET trasposizioni = trasposizioni + 1;
        END IF;
        SET curString = curString + 1;
      END WHILE;
      SET jaro =
      (
        length(common1) / length(in1) +
        length(common2) / length(in2) +
        (length(common1) - trasposizioni / 2) / length(common1)
      ) / 3;

    END IF;
#end if for jaro metric

#calculating common prefix for winkler metric
    SET prefixlen = 0;
    WHILE (substring(in1, prefixlen + 1, 1) = substring(in2, prefixlen + 1, 1)) AND (prefixlen < 6) DO
      SET prefixlen = prefixlen + 1;
    END WHILE;


#calculate jaro-winkler metric
    RETURN jaro + (prefixlen * 0.1 * (1 - jaro));
  END

-- SELECT jaro_winkler_similarity('водка','вотка');
/////////////////////////////////////////////////////////////////////////////////////////////////////


# процедура вычисления диапазона id для индексации

DROP PROCEDURE IF EXISTS  `sp_range_ex`;
# ---------------------------------------------------------------------
DELIMITER $$
CREATE DEFINER=`idc_bookinist`@`%` PROCEDURE `sp_range_ex`(OUT `out_min` INT(10) UNSIGNED, OUT `out_max` INT(10) UNSIGNED, IN `part` TINYINT(1) UNSIGNED, IN `allpart` TINYINT(1) UNSIGNED)  NO SQL
  BEGIN
    DECLARE count_object INT DEFAULT 1;
    DECLARE skip INT DEFAULT 0;
    -- DECLARE max_range INT DEFAULT 0;
    SELECT  COUNT(*) INTO count_object  FROM `idc_bookinist`.`idc_books`;
    SET count_object = count_object/allpart;
    SET skip =  part*count_object-count_object ;
    -- SET max_range = (part*count_object)+0;
    SELECT MIN( d.id ) , MAX( d.id )
    INTO out_min, out_max
    FROM (SELECT book_id FROM idc_books ORDER BY book_id ASC  LIMIT skip,count_object) AS d;
    REPLACE INTO mva_range(id,out_min, out_max) VALUES (part, out_min, out_max);
  END$$
DELIMITER ;


# таблица хранения диапазона id для индексации
CREATE TABLE IF NOT EXISTS `mva_range` (
  `id`TINYINT(2) NOT NULL DEFAULT '1' COMMENT 'source part' PRIMARY KEY,
  `out_min` int(10) NOT NULL DEFAULT '0' COMMENT 'min id',
  `out_max` int(10) NOT NULL DEFAULT '0' COMMENT 'max id',
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


# выборки индексации
SELECT idc_books.book_id,idc_books.book,idc_books.isbn,idc_books.protagonist,idc_books.lang_id,idc_books.format_id,0 AS 'is_deleted',
GROUP_CONCAT(DISTINCT idc_authors.author SEPARATOR ',') AS 'author',
GROUP_CONCAT(DISTINCT idc_categories.category SEPARATOR ',') AS 'category'
# ,GROUP_CONCAT(DISTINCT idc_categories.category_id  SEPARATOR ',') AS 'category_id'
FROM idc_books, idc_book_author_hooks,idc_authors,
  idc_book_categories_hooks,idc_categories
WHERE idc_books.book_id = idc_book_author_hooks.book_id AND
      idc_book_author_hooks.author_id = idc_authors.author_id AND
      idc_categories.category_id = idc_book_categories_hooks.category_id AND
      idc_books.book_id =  idc_book_categories_hooks.book_id
GROUP BY 1;

#mva
SELECT idc_books.book_id,idc_book_series.seria_id
FROM   idc_books, idc_book_series,idc_book_series_hooks
WHERE idc_books.book_id = idc_book_series_hooks.book_id AND
      idc_book_series_hooks.seria_id = idc_book_series.seria_id AND idc_book_series.seria_id IN (10)
GROUP BY 1;



SELECT idc_books.book_id,idc_book_publishers.publisher_id
FROM   idc_books, idc_book_publishers,idc_book_publisher_hooks
WHERE idc_books.book_id = idc_book_publisher_hooks.book_id AND
      idc_book_publisher_hooks.publisher_id = idc_book_publishers.publisher_id AND idc_book_publishers.publisher_id IN (1)
GROUP BY 1;


SELECT idc_books.book_id, idc_lists.list_id
FROM   idc_books,  idc_book_list_hooks,idc_lists
WHERE idc_books.book_id = idc_book_list_hooks.book_id AND
      idc_book_list_hooks.list_id = idc_lists.list_id AND idc_lists.list_id IN (9)
GROUP BY 1;


SELECT idc_books.book_id,idc_authors.author_id
FROM   idc_books, idc_book_author_hooks,idc_authors
WHERE idc_books.book_id = idc_book_author_hooks.book_id AND
      idc_book_author_hooks.author_id = idc_authors.author_id AND idc_authors.author_id IN (1)
GROUP BY 1;


SELECT idc_books.book_id,idc_categories.category_id
FROM   idc_books, idc_book_categories_hooks,idc_categories
WHERE idc_books.book_id = idc_book_categories_hooks.book_id AND
      idc_book_categories_hooks.category_id = idc_categories.category_id AND
      idc_books.book_id IN (1)


	  
	  
### EVENT ############################################################
### TRIGGER на UPDATE нужны для строковых полей индекса: ISBN author category 
### TRIGGER на DELETE нужны для id полей индекса :
### idc_book_langs_hooks 
### idc_book_formats_hooks 
### idc_book_series_hooks 
### idc_book_publisher_hooks 
### idc_book_list_hooks 
### idc_book_author_hooks
### idc_book_categories_hooks
### idc_book_types_hooks
### idc_book_prices

 

### idc_book_prices ###
DELIMITER |
DROP TRIGGER IF EXISTS ins_idc_book_prices_update |
CREATE TRIGGER ins_idc_book_prices_update AFTER UPDATE ON idc_book_prices
FOR EACH ROW
BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
 END
|
DELIMITER ; 

DELIMITER |
DROP TRIGGER IF EXISTS ins_idc_book_prices_delete |
CREATE TRIGGER ins_idc_book_prices_delete AFTER DELETE ON idc_book_prices
FOR EACH ROW
BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
 END
|
DELIMITER ; 


### idc_book_types_hooks ###
DELIMITER |
DROP TRIGGER IF EXISTS ins_idc_book_types_hooks_update |
CREATE TRIGGER ins_idc_book_types_hooks_update AFTER UPDATE ON idc_book_types_hooks
FOR EACH ROW
BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
 END
|
DELIMITER ; 
  
DELIMITER |
DROP TRIGGER IF EXISTS ins_idc_book_types_hooks_delete |
CREATE TRIGGER ins_idc_book_types_hooks_delete AFTER DELETE ON idc_book_types_hooks
FOR EACH ROW
BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
 END
|
DELIMITER ;  
  
  
  
  
  
### idc_authors ###
# обработчик события обновления таблици idc_authors
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_authors_update` |
CREATE TRIGGER `ins_idc_authors_update` AFTER UPDATE ON  `idc_authors`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` IN (
      SELECT DISTINCT `idc_book_author_hooks`.`book_id`
      FROM  `idc_book_author_hooks`, `idc_authors`
      WHERE   `idc_book_author_hooks`.`author_id` = `idc_authors`.`author_id`
            AND `idc_authors`.`author_id` =  NEW.`author_id`
    );
    -- NEW это последняя запись
  END
|
DELIMITER ;

DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_authors_delete` |
CREATE TRIGGER `ins_idc_authors_delete` AFTER DELETE ON  `idc_authors`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` IN (
      SELECT DISTINCT `idc_book_author_hooks`.`book_id`
      FROM  `idc_book_author_hooks`, `idc_authors`
      WHERE   `idc_book_author_hooks`.`author_id` = `idc_authors`.`author_id`
            AND `idc_authors`.`author_id` =  OLD.`author_id`
    );
    
  END
|
DELIMITER ;





### idc_book_author_hooks ###
# обработчик события обновления таблици idc_book_author_hooks
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_author_hooks_update` |
CREATE TRIGGER `ins_idc_book_author_hooks_update` AFTER UPDATE ON  `idc_book_author_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
    -- NEW это последняя запись
  END
|
DELIMITER ;


DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_author_hooks_delete` |
CREATE TRIGGER `ins_idc_book_author_hooks_delete` AFTER DELETE ON  `idc_book_author_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
   
  END
|
DELIMITER ;




### idc_categories ###
# обработчик события обновления таблици idc_categories
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_categories_update` |
CREATE TRIGGER `ins_idc_categories_update` AFTER UPDATE ON  `idc_categories`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` IN (
      SELECT DISTINCT `idc_book_categories_hooks`.`book_id`
      FROM   `idc_book_categories_hooks`, `idc_categories`
      WHERE   `idc_book_categories_hooks`.`category_id` = `idc_categories`.`category_id`
            AND `idc_categories`.`category_id` =  NEW.`category_id`
    );
    -- NEW это последняя запись
  END
|
DELIMITER ;


DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_categories_delete` |
CREATE TRIGGER `ins_idc_categories_delete` AFTER DELETE ON  `idc_categories`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` IN (
      SELECT DISTINCT `idc_book_categories_hooks`.`book_id`
      FROM   `idc_book_categories_hooks`, `idc_categories`
      WHERE   `idc_book_categories_hooks`.`category_id` = `idc_categories`.`category_id`
            AND `idc_categories`.`category_id` =  OLD.`category_id`
    );
    
  END
|
DELIMITER ;




### idc_book_categories_hooks ###
# обработчик события обновления таблици idc_book_categories_hooks
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_categories_hooks_update` |
CREATE TRIGGER `ins_idc_book_categories_hooks_update` AFTER UPDATE ON  `idc_book_categories_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
    -- NEW это последняя запись
  END
|
DELIMITER ;

DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_categories_hooks_delete` |
CREATE TRIGGER `ins_idc_book_categories_hooks_delete` AFTER DELETE ON  `idc_book_categories_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
     
  END
|
DELIMITER ;



### idc_book_cover_hooks ###

DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_cover_hooks_update` |
CREATE TRIGGER `ins_idc_book_cover_hooks_update` AFTER UPDATE ON  `idc_book_cover_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
    -- NEW это последняя запись
  END
|
DELIMITER ;


DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_cover_hooks_delete` |
CREATE TRIGGER `ins_idc_book_cover_hooks_delete` AFTER DELETE ON  `idc_book_cover_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
     
  END
|
DELIMITER ;









### idc_lists ###
# обработчик события обновления таблици idc_lists
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_lists_update` |
CREATE TRIGGER `ins_idc_lists_update` AFTER UPDATE ON  `idc_lists`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` IN (
      SELECT DISTINCT `idc_book_list_hooks`.`book_id`
      FROM    `idc_book_list_hooks`, `idc_lists`
      WHERE   `idc_book_list_hooks`.`list_id` = `idc_lists`.`list_id`
            AND `idc_lists`.`list_id` =  NEW.`list_id`
    );
    -- NEW это последняя запись
  END
|
DELIMITER ;


DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_lists_delete` |
CREATE TRIGGER `ins_idc_lists_delete` AFTER DELETE ON  `idc_lists`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` IN (
      SELECT DISTINCT `idc_book_list_hooks`.`book_id`
      FROM    `idc_book_list_hooks`, `idc_lists`
      WHERE   `idc_book_list_hooks`.`list_id` = `idc_lists`.`list_id`
            AND `idc_lists`.`list_id` =  OLD.`list_id`
    );
 
  END
|
DELIMITER ;




### idc_book_list_hooks ###
# обработчик события обновления таблици idc_book_list_hooks
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_list_hooks_update` |
CREATE TRIGGER `ins_idc_book_list_hooks_update` AFTER UPDATE ON  `idc_book_list_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
    -- NEW это последняя запись
  END
|
DELIMITER ;

DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_list_hooks_delete` |
CREATE TRIGGER `ins_idc_book_list_hooks_delete` AFTER DELETE ON  `idc_book_list_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
  
  END
|
DELIMITER ;






### idc_book_publishers ###
# обработчик события обновления таблици idc_book_publishers
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_publishers_update` |
CREATE TRIGGER `ins_idc_book_publishers_update` AFTER UPDATE ON  `idc_book_publishers`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE `idc_books`.`book_id` IN (
      SELECT DISTINCT `idc_book_publisher_hooks`.`book_id`
      FROM    `idc_book_publisher_hooks`, `idc_book_publishers`
      WHERE  `idc_book_publisher_hooks`.`publisher_id` = `idc_book_publishers`.`publisher_id`
            AND `idc_book_publishers`.`publisher_id` =  NEW.`publisher_id`
    );
    -- NEW это последняя запись
  END
|
DELIMITER ;


DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_publishers_delete` |
CREATE TRIGGER `ins_idc_book_publishers_delete` AFTER DELETE ON  `idc_book_publishers`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE `idc_books`.`book_id` IN (
      SELECT DISTINCT `idc_book_publisher_hooks`.`book_id`
      FROM    `idc_book_publisher_hooks`, `idc_book_publishers`
      WHERE  `idc_book_publisher_hooks`.`publisher_id` = `idc_book_publishers`.`publisher_id`
            AND `idc_book_publishers`.`publisher_id` =  OLD.`publisher_id`
    );
   
  END
|
DELIMITER ;




### idc_book_publisher_hooks ###
# обработчик события обновления таблици idc_book_publisher_hooks
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_publisher_hooks_update` |
CREATE TRIGGER `ins_idc_book_publisher_hooks_update` AFTER UPDATE ON  `idc_book_publisher_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET `idc_bookinist`.`idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
    -- NEW это последняя запись
  END
|
DELIMITER ;


DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_publisher_hooks_delete` |
CREATE TRIGGER `ins_idc_book_publisher_hooks_delete` AFTER DELETE ON  `idc_book_publisher_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET `idc_bookinist`.`idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
  END
|
DELIMITER ;






### idc_book_series ###
# обработчик события обновления таблици idc_book_series
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_series_update` |
CREATE TRIGGER `ins_idc_book_series_update` AFTER UPDATE ON  `idc_book_series`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` IN (
      SELECT DISTINCT `idc_book_series_hooks`.`book_id`
      FROM    `idc_book_series_hooks`, `idc_book_series`
      WHERE  `idc_book_series_hooks`.`seria_id` = `idc_book_series`.`seria_id`
            AND `idc_book_series`.`seria_id` =  NEW.`seria_id`
    );
    -- NEW это последняя запись
  END
|
DELIMITER ;


DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_series_delete` |
CREATE TRIGGER `ins_idc_book_series_delete` AFTER DELETE ON  `idc_book_series`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` IN (
      SELECT DISTINCT `idc_book_series_hooks`.`book_id`
      FROM    `idc_book_series_hooks`, `idc_book_series`
      WHERE  `idc_book_series_hooks`.`seria_id` = `idc_book_series`.`seria_id`
            AND `idc_book_series`.`seria_id` =  OLD.`seria_id`
    );
    
  END
|
DELIMITER ;




### idc_book_series_hooks ###
# обработчик события обновления таблици idc_book_series_hooks
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_series_hooks_update` |
CREATE TRIGGER `ins_idc_book_series_hooks_update` AFTER UPDATE ON  `idc_book_series_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
    -- NEW это последняя запись
  END
|
DELIMITER ;


DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_series_hooks_delete` |
CREATE TRIGGER `ins_idc_book_series_hooks_delete` AFTER DELETE ON  `idc_book_series_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
  END
|
DELIMITER ;



### idc_book_states_hooks ###

DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_states_hooks_update` |
CREATE TRIGGER `ins_idc_book_states_hooks_update` AFTER UPDATE ON  `idc_book_states_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
    -- NEW это последняя запись
  END
|
DELIMITER ;


DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_states_hooks_delete` |
CREATE TRIGGER `ins_idc_book_states_hooks_delete` AFTER DELETE ON  `idc_book_states_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
  END
|
DELIMITER ;









### ins_idc_book_binding_hooks_update ###
DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_binding_hooks_update` |
CREATE TRIGGER `ins_idc_book_binding_hooks_update` AFTER UPDATE ON  `idc_book_bindings_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
    -- NEW это последняя запись
  END
|
DELIMITER ;

DELIMITER |
DROP TRIGGER IF EXISTS `ins_idc_book_binding_hooks_delete` |
CREATE TRIGGER `ins_idc_book_binding_hooks_delete` AFTER DELETE ON  `idc_book_bindings_hooks`
FOR EACH ROW
  BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
  END
|
DELIMITER ;





### idc_book_langs ###



### idc_book_langs_hooks ###
DROP TRIGGER IF EXISTS `ins_idc_book_langs_hooks_update`;
DELIMITER //
CREATE TRIGGER `ins_idc_book_langs_hooks_update` AFTER UPDATE ON `idc_book_langs_hooks`
 FOR EACH ROW BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
  END
//
DELIMITER ;


DROP TRIGGER IF EXISTS `ins_idc_book_langs_hooks_delete`;
DELIMITER //
CREATE TRIGGER `ins_idc_book_langs_hooks_delete` AFTER DELETE ON `idc_book_langs_hooks`
 FOR EACH ROW BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
  END
//
DELIMITER ;





### idc_book_formats ###





### idc_book_formats_hooks ###
DROP TRIGGER IF EXISTS `ins_idc_book_formats_hooks_update`;
DELIMITER //
CREATE TRIGGER `ins_idc_book_formats_hooks_update` AFTER UPDATE ON `idc_book_formats_hooks`
 FOR EACH ROW BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
  END
//
DELIMITER ;


DROP TRIGGER IF EXISTS `ins_idc_book_formats_hooks_delete`;
DELIMITER //
CREATE TRIGGER `ins_idc_book_formats_hooks_delete` AFTER DELETE ON `idc_book_formats_hooks`
 FOR EACH ROW BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
  END
//
DELIMITER ;



### idc_book_isbn_hooks ###
DROP TRIGGER IF EXISTS `ins_idc_book_isbn_hooks_update`;
DELIMITER //
CREATE TRIGGER `ins_idc_book_isbn_hooks_update` AFTER UPDATE ON `idc_book_isbn_hooks`
 FOR EACH ROW BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  NEW.`book_id` ;
  END
//
DELIMITER ;

DROP TRIGGER IF EXISTS `ins_idc_book_isbn_hooks_delete`;
DELIMITER //
CREATE TRIGGER `ins_idc_book_isbn_hooks_delete` AFTER DELETE ON `idc_book_isbn_hooks`
 FOR EACH ROW BEGIN
    UPDATE  `idc_books` SET  `idc_books`.`update_time` = CURRENT_TIMESTAMP
    WHERE  `idc_books`.`book_id` =  OLD.`book_id` ;
  END
//
DELIMITER ;






###############

 

DELIMITER |
DROP PROCEDURE IF EXISTS `sp_dump_all2` |
CREATE DEFINER=`idc_bookinist`@`localhost` PROCEDURE `sp_dump_all2`(OUT `res` TINYINT(1))
    NO SQL
BEGIN
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        SET @error = 1;
    -- START TRANSACTION;
				SELECT  HIGH_PRIORITY SQL_BIG_RESULT  b.book_id,
						  b.book AS 'book',
						  b.book AS 'book_field',
						  IFNULL(GROUP_CONCAT(DISTINCT ih.isbn SEPARATOR ' '),'') AS 'isbn',
						  IFNULL(b.protagonist,'') AS 'protagonist',
						  0 AS 'deleted',
						  IFNULL(b.status,0) AS 'status',
					   GROUP_CONCAT(DISTINCT a.author SEPARATOR ' ') AS 'author',
					   GROUP_CONCAT(DISTINCT c.category SEPARATOR ',') AS 'category',
					   IFNULL(b.trigrams,0),IFNULL(b.len,0),IFNULL(b.count_tr,0) ,IFNULL(b.count_word,0),
					   CONCAT( 
						 IFNULL(  GROUP_CONCAT(DISTINCT ' la',ch.category_id,'_',la.lang_id,'e'  SEPARATOR ' ')   ,'')   ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' bh',ch.category_id,'_',bh.binding_id,'e'  SEPARATOR ' ')   ,'')  ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' st',ch.category_id,'_',st.state_id,'e'  SEPARATOR ' ')   ,'')   ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' fh',ch.category_id,'_',fh.format_id,'e'  SEPARATOR ' ')   ,'')  ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' th',ch.category_id,'_',th.type_id,'e'  SEPARATOR ' ')   ,'') ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' sh',ch.category_id,'_',sh.seria_id,'e'  SEPARATOR ' ')   ,'')  ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' ph',ch.category_id,'_',ph.publisher_id,'e'  SEPARATOR ' ')   ,'')  ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' lh',ch.category_id,'_',lh.list_id,'e'  SEPARATOR ' ')   ,'')   ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' lh',ch.category_id,'_',coh.cover_id,'e'  SEPARATOR ' ')   ,'')
						 ) AS 'filter',IFNULL(TRUNCATE(MIN(bp.price_float),3),0) AS 'minprice', IFNULL(TRUNCATE(MAX(bp.price_float),3),0) AS 'maxprice'
					 INTO OUTFILE 'D:/source_main.csv' FIELDS TERMINATED BY '~' OPTIONALLY ENCLOSED BY '"'  LINES TERMINATED BY '\n'
					 FROM  idc_authors a,idc_categories c,idc_books b
					 LEFT JOIN idc_book_author_hooks ah     ON b.book_id = ah.book_id
					 LEFT JOIN idc_book_categories_hooks ch ON b.book_id = ch.book_id
					 LEFT JOIN idc_book_prices bp           ON bp.book_id=b.book_id
					 LEFT JOIN idc_book_series_hooks sh     ON b.book_id = sh.book_id
					 LEFT JOIN idc_book_publisher_hooks ph  ON b.book_id = ph.book_id
					 LEFT JOIN idc_book_list_hooks  lh      ON b.book_id = lh.book_id
					 LEFT JOIN  idc_book_langs_hooks  la    ON b.book_id = la.book_id
					 LEFT JOIN idc_book_bindings_hooks bh   ON bh.book_id=b.book_id
					 LEFT JOIN idc_book_states_hooks st     ON st.book_id=b.book_id
					 LEFT JOIN  idc_book_formats_hooks fh   ON b.book_id = fh.book_id
					 LEFT JOIN idc_book_isbn_hooks  ih      ON b.book_id = ih.book_id
					 LEFT JOIN idc_book_types_hooks th      ON th.book_id=b.book_id
					 LEFT JOIN idc_book_cover_hooks coh     ON coh.book_id=b.book_id
					 WHERE ah.author_id = a.author_id AND c.category_id = ch.category_id  
					 GROUP BY b.book_id;     
     -- '/tmp/dbcsv/source_main.csv'
IF @error != 0 THEN 
      SELECT 0 INTO res;
     -- ROLLBACK ;
ELSE SELECT 1 INTO res;
    END IF;
END 
|
DELIMITER ;


DROP PROCEDURE IF EXISTS `sp_dump_delta`$$
CREATE DEFINER=`idc_bookinist`@`localhost` PROCEDURE `sp_dump_delta`(IN `INTERVAL` VARCHAR(30) CHARSET utf8, OUT `res` TINYINT(1))
    NO SQL
BEGIN
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        SET @error = 1;
SELECT 1 INTO res;
 SELECT  HIGH_PRIORITY SQL_BIG_RESULT  b.book_id,
						  b.book,
						  b.book AS 'book_field',
						  IFNULL(GROUP_CONCAT(DISTINCT ih.isbn SEPARATOR ' '),'') AS 'isbn',
						  IFNULL(b.protagonist,'') AS 'protagonist',
						  0 AS 'deleted',
						  IFNULL(b.status,0) AS 'status',
					   GROUP_CONCAT(DISTINCT a.author SEPARATOR ' ') AS 'author',
					   GROUP_CONCAT(DISTINCT c.category SEPARATOR ',') AS 'category',
					   IFNULL(b.trigrams,0),IFNULL(b.len,0),IFNULL(b.count_tr,0) ,IFNULL(b.count_word,0),
					   CONCAT( 
						 IFNULL(  GROUP_CONCAT(DISTINCT ' bp',ch.category_id,'_',bp.price,'e'  SEPARATOR ' ')   ,'')   ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' la',ch.category_id,'_',la.lang_id,'e'  SEPARATOR ' ')   ,'')   ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' bh',ch.category_id,'_',bh.binding_id,'e'  SEPARATOR ' ')   ,'')  ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' st',ch.category_id,'_',st.state_id,'e'  SEPARATOR ' ')   ,'')   ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' fh',ch.category_id,'_',fh.format_id,'e'  SEPARATOR ' ')   ,'')  ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' th',ch.category_id,'_',th.type_id,'e'  SEPARATOR ' ')   ,'') ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' sh',ch.category_id,'_',sh.seria_id,'e'  SEPARATOR ' ')   ,'')  ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' ph',ch.category_id,'_',ph.publisher_id,'e'  SEPARATOR ' ')   ,'')  ,
						 IFNULL(  GROUP_CONCAT(DISTINCT ' lh',ch.category_id,'_',lh.list_id,'e'  SEPARATOR ' ')   ,'') ,
                         IFNULL(  GROUP_CONCAT(DISTINCT ' lh',ch.category_id,'_',coh.cover_id,'e'  SEPARATOR ' ')   ,'')						 
						 ) AS 'filter'
					 INTO OUTFILE '/tmp/dbcsv/source_item_delta.csv' FIELDS TERMINATED BY '~' OPTIONALLY ENCLOSED BY '"'  LINES TERMINATED BY '
'
					 FROM  idc_authors a,idc_categories c,idc_books b
					 LEFT JOIN idc_book_author_hooks ah     ON b.book_id = ah.book_id
					 LEFT JOIN idc_book_categories_hooks ch ON b.book_id = ch.book_id
					 LEFT JOIN idc_book_prices bp           ON bp.book_id=b.book_id
					 LEFT JOIN idc_book_series_hooks sh     ON b.book_id = sh.book_id
					 LEFT JOIN idc_book_publisher_hooks ph  ON b.book_id = ph.book_id
					 LEFT JOIN idc_book_list_hooks  lh      ON b.book_id = lh.book_id
					 LEFT JOIN  idc_book_langs_hooks  la    ON b.book_id = la.book_id
					 LEFT JOIN idc_book_bindings_hooks bh   ON bh.book_id=b.book_id
					 LEFT JOIN idc_book_states_hooks st     ON st.book_id=b.book_id
					 LEFT JOIN  idc_book_formats_hooks fh   ON b.book_id = fh.book_id
					 LEFT JOIN idc_book_isbn_hooks  ih      ON b.book_id = ih.book_id
					 LEFT JOIN idc_book_types_hooks th      ON th.book_id=b.book_id
					 LEFT JOIN idc_book_cover_hooks coh     ON coh.book_id=b.book_id
					 WHERE ah.author_id = a.author_id AND c.category_id = ch.category_id  
					  AND UNIX_TIMESTAMP(b.update_time) > UNIX_TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL `INTERVAL`  DAY_SECOND))
					 GROUP BY b.book_id;  	 
 -- "-0 1:15:00" "-0 00:00:01"
IF @error != 0 THEN
      SELECT 0 INTO res;
ELSE SELECT 1 INTO res;
    END IF;
END$$

 
bp1_8e idc_book_prices
la1_8e idc_book_langs_hooks
bh1_8e idc_book_bindings_hooks
st1_8e idc_book_states_hooks
fh1_8e idc_book_formats_hooks
th1_8e idc_book_types_hooks
sh1_8e idc_book_series_hooks
ph1_8e idc_book_publisher_hooks
lh1_8e idc_book_list_hooks


#####################

mysqldump -u [USER_NAME] -p "--where=[WHERE]" "--fields-terminated-by=," "--tab=./" [DB_NAME] [TABLE] > [TABLE].txt

  "C:/OpenServer/modules/database/MySQL-5.5/bin/mysqldump.exe" -u idc_bookinist -pparol  --single-transaction --hex-blob --no-create-info  --fields-terminated-by=, --where="idc_authors.author_id = 5"  --tab="C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data"  idc_bookinist idc_authors > idc_authors.txt

C:/OpenServer/modules/database/MySQL-5.5/bin/mysql -u idc_bookinist -pparol -e "SELECT * from idc_authors" dbname | sed 's/\t/","/g;s/^/"/;s/$/"/' > "C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data/idc_authors.txt"

"C:/OpenServer/modules/database/MySQL-5.5/bin/mysql" -u idc_bookinist -pparol -e "SELECT * from idc_authors" idc_bookinist | sed 's/\t/,/g' > "C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data/idc_authors.txt"
"C:/OpenServer/modules/database/MySQL-5.5/bin/mysql" -u idc_bookinist -pparol -e "SELECT * from idc_authors" idc_bookinist | sed 's/\t/|/g;s/^/"/;s/$/"/' > "C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data/idc_authors.txt"



------------------------------
https://ru.wikipedia.org/wiki/Sed
Здесь s — замена; g — глобально, что означает «все вхождения искомого значения». После первого (/,#,$,%)  расположено регулярное выражение для поиска, после второго (/,#,$,%)  — выражение для замены. 's/1/5/g'
sed 's/\x22hello\x22\x2C/\x22hello world\x22\x2C/g'

"C:/OpenServer/modules/database/MySQL-5.5/bin/mysql" -u idc_bookinist -pparol -e "SELECT * from idc_authors" idc_bookinist | sed 's#\t#_#g' > "C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data/idc_authors.txt"
"C:/OpenServer/modules/database/MySQL-5.5/bin/mysql" -u idc_bookinist -pparol -e "SELECT * from idc_authors" idc_bookinist | sed 's/\t/|/g;s/^/"/;s/$/"/' > "C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data/idc_authors.txt"


"C:/OpenServer/modules/database/MySQL-5.5/bin/mysql" -u idc_bookinist -pparol -e "SELECT * from idc_authors limit 12" idc_bookinist


"C:/OpenServer/modules/database/MySQL-5.5/bin/mysqldump.exe"
  -u idc_bookinist
  -p
  --single-transaction
  --hex-blob
  --no-create-info
  --fields-terminated-by=,
  --where="idc_authors.author_id = 5"
  --tab="C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data"  idc_bookinist idc_authors > idc_authors.txt

Вы можете начать транзакцию, скопировать группу взаимосвязанных
таблиц и потом зафиксировать транзакцию.
Если установлен уровень
изоляции REPEATABLE READ, то этот метод позволит получить идеально со-
гласованный по времени снимок данных, не блокируя при этом работу
сервера на время снятия копии.





SELECT author_id,author
INTO OUTFILE 'C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data/idc_authors.csv'
 FIELDS TERMINATED BY '_'
 ENCLOSED BY '"'
 ESCAPED BY '\\'
 LINES TERMINATED BY '\r\n'
 FROM idc_authors








LOAD DATA [LOW_PRIORITY | CONCURRENT] [LOCAL] INFILE 'file_name.txt'
    [REPLACE | IGNORE]
    INTO TABLE tbl_name
    [FIELDS
        [TERMINATED BY '\t']
        [[OPTIONALLY] ENCLOSED BY '']
        [ESCAPED BY '\\' ]
    ]
    [LINES TERMINATED BY '\n']
    [IGNORE number LINES]
    [(col_name,...)]


\N
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n';

book_id
book
isbn
protagonist
lang_id
format_id
is_deleted
status
author
category
seria_id
publisher_id
list_id
author_id
category_id



SQL_BUFFER_RESULT

GRANT FILE ON * . * TO 'username'@'localhost' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;

http://dev.mysql.com/doc/refman/5.7/en/select-into.html


'C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data/source_item_1.csv'
/var/lib/sphinxsearch/data/source_item_index1.csv

 SELECT HIGH_PRIORITY SQL_BIG_RESULT  idc_books.book_id,idc_books.book,IFNULL(idc_books.isbn,''),IFNULL(idc_books.protagonist,''),IFNULL(idc_books.lang_id,''),IFNULL(idc_books.format_id,''),0 AS 'is_deleted',IFNULL(idc_books.status,''),
		   GROUP_CONCAT(  idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT(  idc_categories.category SEPARATOR ',') AS 'category' ,
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT(idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),"{'seria_id':[]}")  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT(idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),"{'publisher_id':[]}")  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT(idc_book_list_hooks.list_id   SEPARATOR ','),']}'),"{'list_id':[]}")  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT(idc_book_author_hooks.author_id  SEPARATOR ','),']}'),"{'author_id':[]}")  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT(idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),"{'category_id':[]}")  AS 'category_id'
 INTO OUTFILE '/var/lib/sphinxsearch/data/source_item_index1.csv'
 CHARACTER SET UTF8
 FIELDS TERMINATED BY '|'
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
		 idc_books.book_id >=1 AND idc_books.book_id <= 100000
		 GROUP BY idc_books.book_id;









---------------------------------------------------------------






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










SELECT book_id ,"Записки о Галльской войне","151-6841-62","Евгений Витальевич","13","1","0","2","И. А. Ягодкина,И. А. Ягодкина","Банковское дело,Бухучет налогообложение аудит","{'seria_id':[1]}","{'publisher_id':[1,1]}","{'list_id':[1,2]}","{'author_id':[9,9]}","{'category_id':[2,3]}"
INTO OUTFILE 'D:/bigdata/source_item_data4.csv'
 CHARACTER SET UTF8
 FIELDS TERMINATED BY '~'
 OPTIONALLY ENCLOSED BY '"'
 ESCAPED BY '\\'
 LINES TERMINATED BY '\r\n'
FROM idc_books WHERE  idc_books.book_id >= 7500000


10 044 982

2509511
5019023
7528535

		 1-25000: 12250
		 25000-50000
		 50000-75000
		 75000

		 idc_books.book_id < 12250                              source_item_11 +
        idc_books.book_id >=12250 AND idc_books.book_id < 25000 source_item_12 +



        idc_books.book_id >=25000 AND idc_books.book_id < 37250 source_item_21 +
        idc_books.book_id >=37250 AND idc_books.book_id < 50000 source_item_22 +

         idc_books.book_id >=50000 AND idc_books.book_id < 52250 source_item_31 +
        idc_books.book_id >=52250 AND idc_books.book_id < 75000 source_item_32 +


        idc_books.book_id >=75000 AND idc_books.book_id < 82250 source_item_41 +
        idc_books.book_id >=82250                               source_item_42 +











  SELECT HIGH_PRIORITY SQL_BIG_RESULT  idc_books.book_id,
              idc_books.book,
              IFNULL(idc_books.isbn,''),
              IFNULL(idc_books.protagonist,''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_langs_hooks.lang_id),''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_formats_hooks.format_id),''),
              "0" AS 'is_deleted',
              IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),"{'seria_id':[]}")  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),"{'publisher_id':[]}")  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),"{'list_id':[]}")  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),"{'author_id':[]}")  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),"{'category_id':[]}")  AS 'category_id'
 INTO OUTFILE 'C:/OpenServer/domains/JediAssistant/common/components/var/lib/sphinxsearch/data/source_item_indexTEST.csv'
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
		  idc_books.book_id >= 100000
		 GROUP BY idc_books.book_id;









 SELECT
 idc_books.book_id,
 idc_books.book,
 idc_books.isbn,
 IFNULL( idc_books.protagonist,'-') AS 'protagonist',
 GROUP_CONCAT( DISTINCT    idc_book_langs_hooks.lang_id   ) AS 'lang_id',
 GROUP_CONCAT( DISTINCT    idc_book_formats_hooks.format_id  ) AS 'format_id',
 idc_books.status ,
    GROUP_CONCAT(DISTINCT  idc_authors.author_id,'_' ,idc_authors.author SEPARATOR ',') AS 'author',
    GROUP_CONCAT(DISTINCT  idc_categories.category_id,'_',idc_categories.category SEPARATOR ',') AS 'category' ,
    IFNULL( GROUP_CONCAT(DISTINCT  idc_book_series_hooks.seria_id  SEPARATOR ','),'-')  AS 'seria_id',
    IFNULL( GROUP_CONCAT(DISTINCT  idc_book_publisher_hooks.publisher_id  SEPARATOR ','),'-')   AS 'publisher_id',
    IFNULL( GROUP_CONCAT(DISTINCT  idc_book_list_hooks.list_id  SEPARATOR ',') ,'-')  AS 'list_id'
		 FROM   idc_book_formats,idc_langs,idc_authors,idc_categories,idc_books
		 LEFT JOIN idc_book_author_hooks     ON idc_books.book_id = idc_book_author_hooks.book_id
		 LEFT JOIN idc_book_categories_hooks ON idc_books.book_id = idc_book_categories_hooks.book_id
		 LEFT JOIN idc_book_series_hooks     ON idc_books.book_id = idc_book_series_hooks.book_id
		 LEFT JOIN idc_book_publisher_hooks  ON idc_books.book_id = idc_book_publisher_hooks.book_id
		 LEFT JOIN idc_book_list_hooks       ON idc_books.book_id = idc_book_list_hooks.book_id
         LEFT JOIN  idc_book_langs_hooks     ON idc_books.book_id = idc_book_langs_hooks.book_id
		 LEFT JOIN  idc_book_formats_hooks   ON idc_books.book_id = idc_book_formats_hooks.book_id
		 WHERE idc_book_author_hooks.author_id = idc_authors.author_id AND
		  idc_categories.category_id = idc_book_categories_hooks.category_id  AND
		  idc_books.book_id > 14 AND idc_books.book_id < 20
		 GROUP BY idc_books.book_id;



idc_lists.list_id = idc_book_list_hooks.list_id AND






/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////// 4 in 1 //////////////////////////////////////////////////////
        csvpipe_field_string = book*
    	csvpipe_field       = book_field*
    	csvpipe_attr_string = book_string*
    	csvpipe_field_string = isbn*
    	csvpipe_field_string = protagonist*
    	csvpipe_attr_uint    = lang_id*
    	csvpipe_attr_uint    = format_id*
    	csvpipe_attr_bool    = is_deleted*
    	csvpipe_attr_uint    = status:3*
    	csvpipe_field_string = author*
    	csvpipe_field_string = category*
    	csvpipe_field = category_field*
    	csvpipe_attr_string = category_string*
    	csvpipe_attr_json    = seria_id*
    	csvpipe_attr_json    = publisher_id*
        csvpipe_attr_json    = list_id*
    	csvpipe_attr_json    = author_id*
        csvpipe_attr_json    = category_id*
        csvpipe_field        = trigrams
        csvpipe_attr_uint    = len
        csvpipe_attr_uint    = count_tr



 SELECT id,
 keyword,
 trigrams,
 freq, частота в индексе
 CHAR_LENGTH(keyword) AS len , длина текста для триграммы( все слова больше 2 букв)
 ((CHAR_LENGTH( REPLACE(  trigrams,  ' ',  '  ' ) ) - CHAR_LENGTH(trigrams)) +1 ) AS count_tr  количество триграмм


  SELECT HIGH_PRIORITY SQL_BIG_RESULT  idc_books.book_id,
              idc_books.book,
              idc_books.book AS 'book_field',
              idc_books.book AS 'book_string',
              IFNULL(idc_books.isbn,''),
              IFNULL(idc_books.protagonist,''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_langs_hooks.lang_id),''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_formats_hooks.format_id),''),
              "0" AS 'is_deleted',
              IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_field',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_string',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),"{'seria_id':[]}")  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),"{'publisher_id':[]}")  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),"{'list_id':[]}")  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),"{'author_id':[]}")  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),"{'category_id':[]}")  AS 'category_id'
		   , IFNULL(idc_books.trigrams,''),IFNULL(idc_books.len,''),IFNULL(idc_books.count_tr,'') 
 INTO OUTFILE 'D:/index/source_item_index1.csv'
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
              "0" AS 'is_deleted',
              IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_field',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_string',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),"{'seria_id':[]}")  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),"{'publisher_id':[]}")  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),"{'list_id':[]}")  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),"{'author_id':[]}")  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),"{'category_id':[]}")  AS 'category_id'
		   ,IFNULL(idc_books.trigrams,''),IFNULL(idc_books.len,''),IFNULL(idc_books.count_tr,'') 
 INTO OUTFILE 'D:/index/source_item_index2.csv'
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
              "0" AS 'is_deleted',
              IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_field',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_string',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),"{'seria_id':[]}")  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),"{'publisher_id':[]}")  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),"{'list_id':[]}")  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),"{'author_id':[]}")  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),"{'category_id':[]}")  AS 'category_id'
		   ,IFNULL(idc_books.trigrams,''),IFNULL(idc_books.len,''),IFNULL(idc_books.count_tr,'') 
 INTO OUTFILE 'D:/index/source_item_index3.csv'
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
              "0" AS 'is_deleted',
              IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_field',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_string',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),"{'seria_id':[]}")  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),"{'publisher_id':[]}")  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),"{'list_id':[]}")  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),"{'author_id':[]}")  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),"{'category_id':[]}")  AS 'category_id'
		   ,IFNULL(idc_books.trigrams,''),IFNULL(idc_books.len,''),IFNULL(idc_books.count_tr,'') 
 INTO OUTFILE 'D:/index/source_item_index4.csv'
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




		 id
		csvpipe_field_string = book
    	csvpipe_field_string = isbn
    	csvpipe_field_string = protagonist
    	csvpipe_attr_uint    = lang_id
    	csvpipe_attr_uint    = format_id
    	csvpipe_attr_bool    = is_deleted
    	csvpipe_attr_uint    = status:3
    	csvpipe_field_string = author
    	csvpipe_field_string = category
    	csvpipe_attr_json    = seria_id
    	csvpipe_attr_json    = publisher_id
        csvpipe_attr_json    = list_id
    	csvpipe_attr_json    = author_id
        csvpipe_attr_json    = category_id

		101001~
		"Ночь накануне юбилея Санкт-Петербурга"~
		"51-15141-15-51-851"~
		"Валентин"~
		"13"~
		"2"~
		"0"~
		"2"~
		"Виктор Точинов"~
		"Ужасы и Мистика"~
		"{'seria_id':[]}"~
		"{'publisher_id':[]}"~
		"{'list_id':[]}"~
		"{'author_id':[1515]}"~
		"{'category_id':[211]}"










  SELECT HIGH_PRIORITY SQL_BIG_RESULT  idc_books.book_id,
              idc_books.book,
              idc_books.book AS 'book_field',
              idc_books.book AS 'book_string',
              IFNULL(idc_books.isbn,''),
              IFNULL(idc_books.protagonist,''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_langs_hooks.lang_id),''),
              IFNULL(GROUP_CONCAT(DISTINCT idc_book_formats_hooks.format_id),''),
              "0" AS 'is_deleted',
              IFNULL(idc_books.status,''),
		   GROUP_CONCAT( DISTINCT   idc_authors.author SEPARATOR ',') AS 'author',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_field',
		   GROUP_CONCAT( DISTINCT   idc_categories.category SEPARATOR ',') AS 'category_string',
		   IFNULL(CONCAT("{'seria_id':[",     GROUP_CONCAT( DISTINCT idc_book_series_hooks.seria_id  SEPARATOR ','),']}'),"{'seria_id':[]}")  AS 'seria_id',
		   IFNULL(CONCAT("{'publisher_id':[", GROUP_CONCAT( DISTINCT idc_book_publisher_hooks.publisher_id  SEPARATOR ','),']}'),"{'publisher_id':[]}")  AS 'publisher_id',
		   IFNULL(CONCAT("{'list_id':[",      GROUP_CONCAT( DISTINCT idc_book_list_hooks.list_id   SEPARATOR ','),']}'),"{'list_id':[]}")  AS 'list_id',
		   IFNULL(CONCAT("{'author_id':[",    GROUP_CONCAT( DISTINCT idc_book_author_hooks.author_id  SEPARATOR ','),']}'),"{'author_id':[]}")  AS 'author_id',
		   IFNULL(CONCAT("{'category_id':[",  GROUP_CONCAT( DISTINCT idc_book_categories_hooks.category_id  SEPARATOR ','),']}'),"{'category_id':[]}")  AS 'category_id'
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
		  idc_books.book_id <= 15
		 GROUP BY idc_books.book_id;














