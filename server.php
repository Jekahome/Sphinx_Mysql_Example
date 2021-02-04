<?php
//sphinxmysql.com

//index_main хранит все данные и не обновляется а только мержится и помечает удаленые атрибуты
//deltaproduct содержит данные за сегодня он мержится с index_main и содержит килл-лист
//rt_delta содержит актуальные данные реального времени пока deltaproduct не смержился с index_main
//mainproduct обьединяет два локальных индекса    index_main deltaproduct за счет килл-листа deltaproduct только он отдает совпадающие id

// В main данные хранятся всегда а удаляются они при мерже с delta а данные в реальном времени обеспечивает RT
//1. C:/sphinx/bin/indexer deltaproduct  --config  C:/index/etc/sphinxsearch/sphinxmysql.conf --rotate # аганяем по дате добавления или обновления сегодня из mysql в deltaproduct
//2. C:/sphinx/bin/indexer --config C:/index/etc/sphinxsearch/sphinxmysql.conf  --merge index_main deltaproduct   --merge-dst-range deleted 0 0 --rotate # заливаем в index_main новые данные из deltaproduct и удаляем одновременно записи из index_main по атрибуту deleted и обновляем до затирания deltaproduct так как время новых данных должно сравниваться с этим временем обновления
//3. TRUNCATE RTINDEX rt_delta;# чистим RT


//$ARR_ID=unserialize(file_get_contents('list_id.txt'));

    $pdo = new PDO("mysql:host=localhost;port=3306;dbname=sphinxmysql", "root", "");
    $pdo->query("SET NAMES utf8;");

$pdosphinx = new PDO("mysql:host=localhost;port=9306;", "", "");
$pdosphinx->query("SET NAMES utf8;");

$RESULT='';

if(0){
    $prepare= $pdosphinx->prepare("INSERT INTO  rt_delta ( id, product , product_field,category,deleted,fjson, price) VALUES (:id,:name,:name,:category,0,:fjson,:price )  ");
    $prepare->bindValue(':id',1,PDO::PARAM_INT);
    $prepare->bindValue(':name',"test",PDO::PARAM_STR);
    $prepare->bindValue(':category',"category test",PDO::PARAM_INT);
    $prepare->bindValue(':fjson',"{'k':5}",PDO::PARAM_STR);
    $prepare->bindValue(':price',5,PDO::PARAM_INT);
    $prepare->execute();

    print_r(getRT());
    exit;
}


if(isset($_POST['insert'])){
    Insert();
}
elseif(isset($_POST['update'])){
    Update();

}elseif(isset($_POST['delete'])){
    Delete();
}



function Insert(){
    global $pdosphinx;
    global  $pdo;
    if(empty($_POST['category']))return false;
    if(empty($_POST['name']))return false;
    $book=  $_POST['name'];
    $numb=$_POST['price'];
    //Insert Mysql
    $prepare= $pdo->prepare("INSERT INTO  product (  name , price   ) VALUES (:name,:price )  ");
    $prepare->bindValue(':name',$book);
    $prepare->bindValue(':price',$numb);
    $prepare->execute();

    $id_product=$pdo->lastInsertId();
    $id_category=$_POST['category'];
    $prepare= $pdo->prepare("INSERT INTO  product_category ( id_product, id_category)  VALUES (:id_product,:id_category )  ");
    $prepare->bindValue(':id_product',$id_product);
    $prepare->bindValue(':id_category',$id_category);
    $prepare->execute();

    // Insert rt
    $fjson='{}';
    if(!empty($_POST['fjson']))$fjson=$_POST['fjson'];
    $prepare= $pdosphinx->prepare("INSERT INTO  rt_delta ( id, product , product_field,category_field,category,deleted,fjson, price) VALUES (:id,:name,:name,:category,:category,0,:fjson,:price )  ");
    $prepare->bindValue(':id',$id_product,PDO::PARAM_INT);
    $prepare->bindValue(':name',$book,PDO::PARAM_STR);
    $prepare->bindValue(':category',$pdo->query("SELECT  name   FROM  category  WHERE   id=".$id_category)->fetchColumn(),PDO::PARAM_INT);
    $prepare->bindValue(':fjson',$fjson,PDO::PARAM_STR);
    $prepare->bindValue(':price',$numb,PDO::PARAM_INT);
    $prepare->execute();

    header("Location: /");exit;
}

function Update( ){
    global $pdosphinx;
    global  $pdo;

    $id=  $_POST['id'];
    if(empty($_POST['id']) || !is_numeric($_POST['id']))return false;
          $SET=[];
          if(!empty($_POST['name']))$SET[]=  ' name='.$pdo->quote($_POST['name']) ;
          if(!empty($_POST['price'])) $SET[]= " price=".$_POST['price'] ;
          if(!empty($_POST['fjson'])) $SET[]=' fjson='.$_POST['fjson'] ;
          $SET=" SET ".implode(',',$SET);

    // Обновим Mysql
    if( $pdo->exec("UPDATE  product {$SET}  WHERE id=".$_POST['id']) > 0){
        if($category_id = $_POST['category'] ){
            $prepare=  $pdo->prepare( "SELECT id,name   FROM  category  WHERE id=:id LIMIT 1");
            $prepare->bindValue(':id',$category_id,PDO::PARAM_INT);
            $prepare->execute();
            $category= $prepare->fetchAll();
            $category_id=$category[0]['id'];
            $name_category=$category[0]['name'];
            if($category_id){
                $prepare= $pdo->prepare("DELETE FROM  product_category  WHERE id_product=:id_product AND id_category=:id_category LIMIT 1");
                $prepare->bindValue(':id_product',$id,PDO::PARAM_INT);
                $prepare->bindValue(':id_category',$category_id,PDO::PARAM_INT);
                $prepare->execute();

                $prepare= $pdo->prepare("INSERT INTO product_category  (id_product,id_category) VALUES(:id_product,:id_category)");
                $prepare->bindValue(':id_product',$id,PDO::PARAM_INT);
                $prepare->bindValue(':id_category',$category_id,PDO::PARAM_INT);
                $prepare->execute();
            }
        }
        // Обновим RT и удалим из index_main через обновление поля deleted
        $pdosphinx->exec("UPDATE index_main SET deleted=1 WHERE id=".$_POST['id']);
        $SET=[];
        if(!empty($_POST['name']))$SET[]=  " name=".$_POST['name'] ;
        if(!empty($_POST['price'])) $SET[]= " price=".$_POST['price'] ;
        if(!empty($_POST['fjson']))$SET[]=" fjson=".$_POST['fjson'] ;
        $SET[]= !empty($name_category)? " category=".$name_category:'';
        $SET=" SET ".implode(',',$SET);
        $pdosphinx->exec("UPDATE rt_delta {$SET} WHERE id=".$_POST['id']);
    }else{
        throw new Exception("Not Update!");
    }
    header("Location: /");exit;
}

function Delete( ){
    global $pdosphinx;
    global  $pdo;
    // Delete Mysql
    if($pdo->exec("DELETE FROM  product  WHERE id=".$_POST['id'])>0){
        $pdo->exec(" ALTER TABLE product AUTO_INCREMENT = 1;");
        // Delete RT
        $pdosphinx->exec("DELETE FROM  rt_delta  WHERE id=".$_POST['id']);
        // Update  index_main
        $pdosphinx->exec("UPDATE index_main SET deleted=1 WHERE id=".$_POST['id']);
    }
    header("Location: /");exit;
}


function getAllMysql(){

    global  $pdo;
//SELECT p.id,p.name AS 'product',p.name AS 'product_field',c.name AS 'category',0 AS 'deleted',  CONCAT(\"{'tag':[\", IFNULL('1,2,3,4,5',\"\"), ']}') AS 'fjson'
    $PDOstatement= $pdo->query("SELECT p.id,p.name AS 'product',p.price ,p.update_time ,c.name AS 'category'
	FROM category c ,product p INNER JOIN product_category pc ON pc.id_product=p.id
	WHERE c.id=pc.id_category
    ORDER BY p.id ASC");
if($PDOstatement) {
    return $PDOstatement->fetchAll(PDO::FETCH_ASSOC);
}
   // return json_encode($RESULT);
//fwrite(fopen('file.txt','a+'),implode(',',$_POST) );
}


//http://sphinxsearch.com/docs/current.html#sphinxql-reference
function getAllSphinxQL( ){
try{
    if(!empty($_POST['index'])){
        global  $pdosphinx;
        $index=$_POST['index'];
        // При поиске mainproduct,rt_delta атрибуты должны совпадать
        //sql_field_string = rt_attr_string для SELECT
        //sql_field_string = rt_field для MATCH
        $PDOstatement= $pdosphinx->query("SELECT id,product,category,deleted,price,fjson FROM {$index} WHERE id>0  ORDER BY id ASC LIMIT 100");
        // $PDOstatement= $pdosphinx->query("SELECT id,product,deleted,price,fjson FROM  mainproduct,rt_delta WHERE id>0  ORDER BY id ASC LIMIT 100");
        if($PDOstatement){

            return ['res'=>$PDOstatement->fetchAll(PDO::FETCH_ASSOC),'ind'=>$index];
        }else{
            return ['res'=>0,'ind'=>$index];;
        }
    }
}catch (Exception $e){
    echo $e->getMessage();
}
}


function getRT(){
    try{
        global  $pdosphinx;

        $PDOstatement= $pdosphinx->query("SELECT id,product,price,deleted,fjson FROM rt_delta");
        if($PDOstatement){

            return  $PDOstatement->fetchAll(PDO::FETCH_ASSOC) ;
        }
    }catch (Exception $e){
        echo $e->getMessage();
    }

}




function search( ){

    global  $pdosphinx;
    //index_main mainproduct distributed deltaproduct rt_delta
    $word= $_POST['search'];
    $index=[];
    if(isset($_POST['index_main']))$index[]='index_main';
    if(isset($_POST['mainproduct']))$index[]='mainproduct';
    if(isset($_POST['distributed']))$index[]='distributed';
    if(isset($_POST['deltaproduct']))$index[]='deltaproduct';
    if(isset($_POST['rt_delta']))$index[]='rt_delta';
    if(empty($index))return;
    $index=implode(',',$index);
    $query="SELECT *
            FROM  {$index}
            WHERE MATCH('@product_field \"{$word}\" ')
            ORDER BY id ASC LIMIT 100";

    $PDOstatement= $pdosphinx->query($query);
    if($PDOstatement){
        return ['res'=>$PDOstatement->fetchAll(PDO::FETCH_ASSOC),'ind'=>$index];
    }

}


function getCategory(){
    global  $pdo;
   return $pdo->query("SELECT id, name FROM category")->fetchAll(PDO::FETCH_ASSOC);

}

?>

<html>
<header>
    <meta charset="UTF-8">
</header>
<body>

<div >



<div style="border: 15px solid black;width: 380px;height: 750px;display: inline-block;position: absolute;top:0;left:0px">

   <!--  SEARCH  -->
    <form action="." method="post" style="border:3px solid  green">


         <input id="s1" type="checkbox" name="mainproduct" value="mainproduct"  ><label  for="s1">mainproduct(index_main)</label><br>
         <input id="s2" type="checkbox" name="deltaproduct" value="deltaproduct"  > <label  for="s2">deltaproduct</label><br>
         <input id="s3" type="checkbox" name="rt_delta" value="rt_delta"  ><label  for="s3">rt_delta</label><br>

        <input id="search" type="text" name="search" style="background: mediumpurple" placeholder="<?=$_POST['search']?>"/>
        <label for="search">search</label><br>
        <input name="submit" type="submit" style="color: #0055aa" >
    </form>



    <!-- MYSQL -->
    <form action="." method="post" style="border:3px solid  green">
        <button name="c1" type="submit" value="1" style="color: #0055aa">SHOW MySQL ALL</button>
    </form>



    <!-- SPHINXQL -->
    <form action="." method="post" style="border:3px solid  green">


        <select id="search" name="index">
            <option value="mainproduct">mainproduct(index_main)</option>
            <option value="rt_delta,mainproduct">rt_delta,mainproduct(rt_delta,index_main)</option>
            <option value="deltaproduct">deltaproduct</option>
            <option value="rt_delta">rt_delta</option>
        </select>

        <button name="submit" type="submit" style="color: #0055aa">SHOW SPHINXQL ALL</button>
    </form>



    <!-- INSERT -->
    <form action="." method="post" style="border: 3px solid green">
        <h4>Insert</h4>
        <input  type="text" name="name"  required placeholder="name:" autocomplete="off" style="background: yellowgreen" /><br>
        <input  type="number" name="price"   placeholder="price:" autocomplete="off"  style="background: yellowgreen"/><br>
        <input  type="text" name="fjson"   placeholder='{"key":value}' autocomplete="off"  style="background: yellowgreen"/><br>
        <select id="category" name="category" required>
        <?php
        $categories=getCategory();
        foreach($categories as $category){
            echo ' <option value="'.$category['id'].'">'.$category['name'].'</option>';
        }
        ?>
        </select>
        <label  >Категория</label><br>
        <input name="insert" type="submit" style="color: #0055aa">
    </form>


    <!-- UPDATE -->
    <form action="." method="post" style="border:3px solid  green">
        <h4>Update</h4>
        <input  type="text" name="id"  required placeholder="id:" autocomplete="off"   style="background: yellowgreen" /><br>
        <input  type="text" name="name"    placeholder="name:" autocomplete="off"  style="background: yellowgreen" /><br>
        <input   type="number" name="price"   placeholder="price:" autocomplete="off" style="background: yellowgreen"/><br>
        <input   type="text" name="fjson"    placeholder='{"key":value}' autocomplete="off"  style="background: yellowgreen"/><br>
        <select id="category" name="category"  >
            <option value="" selected> </option>
            <?php
            $categories=getCategory();
            foreach($categories as $category){
                echo ' <option value="'.$category['id'].'">'.$category['name'].'</option>';
            }
            ?>
        </select>
        <label  >Категория</label><br>
        <input name="update" type="submit" style="color: #0055aa">
    </form>



    <!-- DELETE -->
    <form action="." method="post" style="border:3px solid green">
        <h4>Delete</h4>
        <input  type="text" name="id"  required placeholder="id:" autocomplete="off"  style="background: yellowgreen" /><br>
        <input name="delete" type="submit" style="color: #0055aa">
    </form>


</div>
<div  style="border: 15px solid black;width: 360px;height 700px;display: inline-block;position: absolute;top:0;left:400px">
    <?php
     echo "<h3 style='margin-left: 50px'>Search <sub>mainproduct + rt_delta SPHINX</sub></h3> ";
    if($_POST['search']   ){
        $RESULT=  search();
        echo @$RESULT['ind'];

        foreach($RESULT['res'] as $obj){
            echo "<ul>";
            foreach($obj as $key=>$value){
                echo "<li>";
                echo $key,"=>",$value;
                echo "</li>";
            }
            echo "</ul>";
        }

    }




    ?>
</div>
    <div style="border: 15px solid black;width: 360px; height 700px;display: inline-block;position: absolute;top:0;left:780px" >
        <?php
        echo "<h3 style='margin-left: 50px'>SHOW SPHINXQL ALL</h3>";

        $RESULT_=getAllSphinxQL();
        if(is_array($RESULT_)){
            echo @$RESULT_['ind'];
            if(is_array($RESULT_['res'])){
                foreach($RESULT_['res'] as $obj){
                    echo "<ul>";
                    foreach($obj as $key=>$value){
                        echo "<li>";
                        echo $key,"=>",$value;
                        echo "</li>";
                    }
                    echo "</ul>";
                }
            }

        }

        ?>

    </div>
    <div  style="border: 15px solid black;width: 360px; height 700px;display: inline-block;position: absolute;top:0;left:1165px">

             <?php
            echo "<h3 style='margin-left: 50px'>SHOW MYSQL ALL</h3>";
            $RESULT=getAllMysql();
             foreach($RESULT as $obj){
                 echo "<ul>";
                 foreach($obj as $key=>$value){
                     echo "<li>";
                     echo $key,"=>",$value;
                     echo "</li>";
                 }
                 echo "</ul>";
             }
             ?>


    </div>
    <div  style="border: 15px solid black;width: 330px; height 700px;display: inline-block;position: absolute;top:0;left:1550px">
        <?php
        echo "<h3 style='margin-left: 50px'>rt_delta</h3>";

        $RESULT_=getRT();

        foreach($RESULT_  as $obj){
            echo "<ul>";
            foreach($obj as $key=>$value){
                echo "<li>";
                echo $key,"=>",$value;
                echo "</li>";
            }
            echo "</ul>";
        }
        ?>


    </div>

</div>

</body>

</html>








