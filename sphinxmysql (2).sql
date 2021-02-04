-- phpMyAdmin SQL Dump
-- version 4.4.15.5
-- http://www.phpmyadmin.net
--
-- Хост: 127.0.0.1:3306
-- Время создания: Апр 17 2016 г., 23:57
-- Версия сервера: 5.5.48
-- Версия PHP: 5.6.19

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `sphinxmysql`
--
CREATE DATABASE IF NOT EXISTS `sphinxmysql` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `sphinxmysql`;

DELIMITER $$
--
-- Процедуры
--
DROP PROCEDURE IF EXISTS `sp_indexer`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_indexer`()
    NO SQL
SELECT p.id,p.name AS 'product',p.name AS 'product_field',c.name AS 'category',0 AS 'deleted', CONCAT("{'tag':[", IFNULL('1,2,3,4,5',""), ']}') AS 'fjson',p.price AS 'price' 
	FROM category c ,product p INNER JOIN product_category pc ON pc.id_product=p.id
	WHERE c.id=pc.id_category  AND    UNIX_TIMESTAMP(p.update_time) < UNIX_TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL "-0 00:00:01"  DAY_SECOND))   ORDER BY p.id ASC$$

DROP PROCEDURE IF EXISTS `sp_indexer_delta`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_indexer_delta`(IN `INTERVAL` VARCHAR(30) CHARSET utf8)
    NO SQL
SELECT p.id,p.name AS 'product',p.name AS 'product_field',c.name AS 'category',0 AS 'deleted',  CONCAT("{'tag':[", IFNULL('1,2,3,4,5',""), ']}') AS 'fjson' ,p.price AS 'price' 
	FROM category c ,product p INNER JOIN product_category pc ON pc.id_product=p.id
	WHERE c.id=pc.id_category
    AND    UNIX_TIMESTAMP(p.update_time) > UNIX_TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL `INTERVAL`  DAY_SECOND))  ORDER BY p.id ASC
 -- "-0 1:15:00" "-0 00:00:01"$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `category`
--

DROP TABLE IF EXISTS `category`;
CREATE TABLE IF NOT EXISTS `category` (
  `id` int(10) unsigned NOT NULL,
  `name` varchar(250) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `category`
--

INSERT INTO `category` (`id`, `name`) VALUES
(1, 'Cheese'),
(2, 'Алкоголь'),
(3, 'Рыба');

-- --------------------------------------------------------

--
-- Структура таблицы `product`
--

DROP TABLE IF EXISTS `product`;
CREATE TABLE IF NOT EXISTS `product` (
  `id` int(10) unsigned NOT NULL,
  `name` varchar(250) NOT NULL,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `price` float unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8 COMMENT='таблица продуктов';

--
-- Дамп данных таблицы `product`
--

INSERT INTO `product` (`id`, `name`, `update_time`, `price`) VALUES
(1, 'Бренди', '2016-03-11 21:57:46', 7.1),
(2, 'Вермут', '2016-03-11 21:57:46', 88.18),
(3, 'Вино', '2016-03-11 22:08:37', 5.6),
(4, 'Виски', '2016-03-11 22:08:37', 4.4),
(5, 'Водка', '2016-03-11 21:57:46', 77),
(6, 'Горбуша', '2016-03-11 21:57:46', 66.14),
(7, 'Кальмар', '2016-03-11 21:57:46', 56),
(8, 'Макрель', '2016-03-11 22:08:37', 7.1),
(9, 'Налим', '2016-03-11 22:00:41', 57.14),
(10, 'Брынза', '2016-03-11 22:00:44', 4),
(11, 'Сулугуни', '2016-03-11 22:00:46', 8.18),
(17, 'rtt', '2016-03-17 21:54:00', 5);

-- --------------------------------------------------------

--
-- Структура таблицы `product_category`
--

DROP TABLE IF EXISTS `product_category`;
CREATE TABLE IF NOT EXISTS `product_category` (
  `id` int(10) unsigned NOT NULL,
  `id_product` int(10) unsigned NOT NULL,
  `id_category` int(10) unsigned NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8 COMMENT='1:1 продукты и категории';

--
-- Дамп данных таблицы `product_category`
--

INSERT INTO `product_category` (`id`, `id_product`, `id_category`) VALUES
(1, 1, 2),
(2, 2, 2),
(3, 3, 2),
(4, 4, 2),
(5, 5, 2),
(6, 6, 3),
(7, 7, 3),
(8, 8, 3),
(9, 9, 3),
(10, 10, 1),
(11, 11, 1),
(29, 17, 1);

--
-- Триггеры `product_category`
--
DROP TRIGGER IF EXISTS `ins_product_category_delete`;
DELIMITER $$
CREATE TRIGGER `ins_product_category_delete` AFTER DELETE ON `product_category`
 FOR EACH ROW UPDATE  `product` SET   `update_time` = CURRENT_TIMESTAMP
    WHERE  `id` =  OLD.`id`
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `ins_product_category_update`;
DELIMITER $$
CREATE TRIGGER `ins_product_category_update` AFTER UPDATE ON `product_category`
 FOR EACH ROW UPDATE  `product` SET   `update_time` = CURRENT_TIMESTAMP
    WHERE  `id` =  NEW.`id`
$$
DELIMITER ;

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `category`
--
ALTER TABLE `category`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `product_category`
--
ALTER TABLE `product_category`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_product` (`id_product`),
  ADD KEY `id_category` (`id_category`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `category`
--
ALTER TABLE `category`
  MODIFY `id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT для таблицы `product`
--
ALTER TABLE `product`
  MODIFY `id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=18;
--
-- AUTO_INCREMENT для таблицы `product_category`
--
ALTER TABLE `product_category`
  MODIFY `id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=30;
--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `product_category`
--
ALTER TABLE `product_category`
  ADD CONSTRAINT `product_category_ibfk_1` FOREIGN KEY (`id_product`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `product_category_ibfk_2` FOREIGN KEY (`id_category`) REFERENCES `category` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
