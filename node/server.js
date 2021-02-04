

const http = require('http');

const hostname = '127.0.0.1';
const port = 1337;
// http://127.0.0.1:1337       http://node:1337
http.createServer(function(req, res){

    res.writeHead(200, { 'Content-Type': 'text/plain' });

    for(var index in req ){
        // res.end(req[index]+"<br>");
    }
    res.end('Hello World all<br>');



  var intervalID=  setInterval( show  , 2000);
  //clearInterval(intervalID)


}).listen(port, hostname );





function show(){


    if(1){
        var mysql      = require('mysql');
        var connection = mysql.createConnection({
            host     : 'localhost',
            user     : 'user',
            password : '1234',
            database : 'sphinxmysql'
        });

        connection.connect();

        connection.query('SELECT * from product', function(err, rows, fields) {
            if (!err){
               // console.log('The solution is: ', rows);


                var request = require('request');

                request.post({url:'http://sphinxmysql.com', form: {'c1':'1'}}, function(err,httpResponse,body){

                    process.stdout.write("fff");

                     for(var indx in httpResponse){
                    // write(rows /*httpResponse[indx]*/);
                    }

                });





            }

            else
                console.log('Error while performing Query.');
        });




        connection.end();
    }

   // Asynch_showDemoSample();



}
/*
function getXmlHttpRequest()
{
    if (window.XMLHttpRequest)
    {
        try
        {
            return new XMLHttpRequest();
        }
        catch (e){}
    }
    else if (window.ActiveXObject)
    {
        try
        {
            return new ActiveXObject('Msxml2.XMLHTTP');
        } catch (e){}
        try
        {
            return new ActiveXObject('Microsoft.XMLHTTP');
        }
        catch (e){}
    }
    return null;
}

//В глобальную область видимости поместим объект взаимодействия с сервером
var request_Asynch = getXmlHttpRequest();

// Моя ф-ция обработчик
function myEventHandler(){

    if(request_Asynch.readyState == 4){

        if(request_Asynch.status != 200){

            // Если какая либо ошибка нет страницы 404 и т.д.
            alert("Статус: "+request_Asynch.status+" "+request_Asynch.statusText);
            alert(request_Asynch.getResponseHeader('Status'));// или так // Content-Length заголовок размер данных в байтах
            // alert(request_Asynch.gatAllResponseHeaders());// все заголовки
        }
        else
        {
            // alert(request_Asynch.responseText);

            //Можэм создать элемент и запихнуть внего данные полученные от сервера
            var result=document.getElementById('myDiv');
            result.innerHTML=request_Asynch.responseText;

            //Можно так загнать в массив все данные полученные от сервера с помощью JavaScript
            var responseText = new String(req.responseText);
            var books = responseText.split('\n');
            clearList();
            for (var i = 0; i < books.length; i++)
                addListItem(books[i]);




            //Если на сервере данные передали придуманным заголовком
            // result.innerHTML=request_Asynch.getResponseHeader('MyData-value')

        }

    }

}

//Реакция на кнопку для асинхронного запроса
function Asynch_showDemoSample()
{


    //Асинхронный  Запрос на сервер
    //Предполагает отслеживание состояния readyState через событие onreadystatechange
    request_Asynch.onreadystatechange = myEventHandler;// моя ф-ция обработчик

    //--------------- GET---------------------------
    // Адрес текущей страницы
    //var url = location.href+"?data2=33333333333";
    //var url = "server.php?data=33333333333";



    //request_Asynch.open("GET", url, true);//  HEAD
    //request_Asynch.send(null);// null в GET нет тела



    //--------------- POST---------------------------
    // Адрес текущей страницы
    //var url = location.href+"?data2=33333333333";
    var url = "server.php";// или адрес с данными на нашем жэ сервере(на другом не даст безопасность AJAX)


    request_Asynch.open("POST", url, true);
    // Установка заголовков
    request_Asynch.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");// имитируем форму


    //data="arg1=333&arg2=444";
    //request_Asynch.send(data);

    // или данные из формы !!!
    var arg1_value = document.getElementById("id1").value;
    var arg2_value = document.getElementById("id2").value;
    // Формирование строки поиска
    //var data = "arg1=" + arg1_value + "&" + "arg2=" + arg2_value;// при кириллице будет не верный размер строки нобраузер можэт простить
    var data = "arg1=" + encodeURIComponent(arg1_value) + "&" + "arg2=" + encodeURIComponent(arg2_value);

    request_Asynch.setRequestHeader("Content-Length", data.length);//Надо кодировть в utf8 // data.length это длина строки ,а нам надо размер в байтах ведь в кириллице 1 символ два байта(да = 4 байта != да.length=2)     )
    request_Asynch.send(data);

    //Асинхронный запрос Для данных которые нам в данный момент не обязательны( но нужны)

    //Можно безимянную ф-цию назначить обработчику события
   //  request_Asynch.onreadystatechange = function(){
    // if(request_Asynch.readyState==4){ alert(request_Asynch.responseText); }
   //  }


}*/

/*
//Реакция на кнопку для синхронного запроса
function Synch_showDemoSample()
{
    // Адрес текущей страницы
    var url = location.href;
    // Объект XMLHttpRequest
    var request = getXmlHttpRequest();
    // var request = < ?php new XMLHttpRequest();?>

    //Синхронный  Запрос на сервер
    //готовым объект
    request.open("GET", url, false);  // дай мне текущую страницу
    request.send(null);
    // Чтение ответа
    alert(request.responseText);
    //Для загрузки файлов и проверки их т.е. те данные которые нм нужны в данный момент и не можэм их ждать
}*/