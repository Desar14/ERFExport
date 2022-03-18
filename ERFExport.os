#Использовать v8runner
#Использовать gitrunner
#Использовать logos
#Использовать cmdline

#Использовать "Модули"

Перем Лог;
Перем РепозиторийGit;

Функция ПроверитьПараметрыКоманды(КаталогРепозитория, Лог)
	
	ФайлКаталогРепозитория = Новый Файл(КаталогРепозитория);
	
	Если НЕ ФайлКаталогРепозитория.Существует() ИЛИ ФайлКаталогРепозитория.ЭтоФайл() Тогда
		
		Лог.Ошибка("Каталог репозитория '%1' не существует или это файл", КаталогРепозитория);
		Возврат Ложь;
		
	КонецЕсли;
	
	Лог.Вывести("Тестовый лог", УровниЛога.Информация);
	
	КаталогРепозитория = ФайлКаталогРепозитория.ПолноеИмя;
	
	РепозиторийGit = Новый ГитРепозиторий();
	РепозиторийGit.УстановитьРабочийКаталог(КаталогРепозитория);
	
	Если НЕ РепозиторийGit.ЭтоРепозиторий() Тогда
		
		Лог.Ошибка("Каталог '%1' не является репозиторием git", КаталогРепозитория);
		Возврат Ложь;
		
	КонецЕсли;
	
	Возврат Истина;
	
КонецФункции

Процедура НастроитьКоманду(Знач Команда, Знач Парсер) Экспорт
	
	// Добавление параметров команды
	Парсер.ДобавитьПозиционныйПараметрКоманды(Команда, "КаталогРепозитория", "Каталог анализируемого репозитория");
	Парсер.ДобавитьИменованныйПараметрКоманды(Команда, "-source-dir",
		"Каталог расположения исходных файлов относительно корня репозитория. По умолчанию <src>");
	
КонецПроцедуры // НастроитьКоманду

Функция ЗапускПриложения()
	
	ПарсерКоманд = Новый ПарсерАргументовКоманднойСтроки();
	
	ПарсерКоманд.ДобавитьИменованныйПараметр("-temp");
	ПарсерКоманд.ДобавитьИменованныйПараметр("-repo");
	ПарсерКоманд.ДобавитьИменованныйПараметр("-filesForProcess");
	
	ПараметрыЗапуска = ПарсерКоманд.Разобрать(АргументыКоманднойСтроки);
	
	Если ПараметрыЗапуска = Неопределено ИЛИ ПараметрыЗапуска.Количество() = 0 Тогда
		
		Возврат РезультатыКоманд().НеверныеПараметры;
		
	ИначеЕсли ТипЗнч(ПараметрыЗапуска) = Тип("Структура") Тогда
		
		// это команда
		Команда = ПараметрыЗапуска.Команда;
		ЗначенияПараметров = ПараметрыЗапуска.ЗначенияПараметров;
		Лог.Отладка("Выполняю команду продукта %1", Команда);
		
	КонецЕсли;
	
	КаталогРепозитория = ПараметрыЗапуска["-repo"]; //"E:\1C\21vek\выгрузка обработок\репозиторий";
	
	ТекущийКаталогИсходныхФайлов = ПараметрыЗапуска["-temp"]; //"E:\1C\21vek\выгрузка обработок\temp"; //ОбъединитьПути(КаталогРепозитория, "src");
	
	// Логирование
	Лог = Логирование.ПолучитьЛог("oscript.app.erfexport");
	//Лог.УстановитьРаскладку(ОбъектНастроек);
	
	ПроверитьПараметрыКоманды(КаталогРепозитория, Лог);
	
	ДобавитьФайлыВРепозиторий(ПараметрыЗапуска["-filesForProcess"], КаталогРепозитория);

	ЖурналИзменений = ПолучитьЖурналИзменений();
	
	ФайлыКОбработке = Новый ТаблицаЗначений();
	ФайлыКОбработке.Колонки.Добавить("Файл");
	ФайлыКОбработке.Колонки.Добавить("ТипИзменения");
	
	ПараметрыОбработки = ПолучитьСтандартныеПараметрыОбработки();
	ПараметрыОбработки.Лог = Лог;
	ПараметрыОбработки.КаталогРепозитория = КаталогРепозитория;
	ПараметрыОбработки.ТекущийКаталогИсходныхФайлов = ТекущийКаталогИсходныхФайлов;
	
	Для каждого Изменение Из ЖурналИзменений Цикл
		ДобавитьКОбработке(ФайлыКОбработке, Новый Файл(ОбъединитьПути(КаталогРепозитория, Изменение.ИмяФайла)),
			Изменение.ТипИзменения);
	КонецЦикла;
	
	ВыполнитьОбработкуФайлов(ФайлыКОбработке, ПараметрыОбработки);
	
	Комментарий = "тест коммент коммита";
	АвторДляГит = "тестовый автор <test@test.com>";
	ДатаДляГит = ДатаPOSIX(ТекущаяУниверсальнаяДата());
	
	ИмяФайлаКомментария = ПодготовитьФайлКоммита(Комментарий);
	РепозиторийGit.ВыполнитьКоманду(СтрРазделить("add -A .", " "));
	РепозиторийGit.Закоммитить(Комментарий,
		Истина,
		ИмяФайлаКомментария,
		АвторДляГит,
		ДатаДляГит,
		АвторДляГит,
		ДатаДляГит);
	Лог.Отладка("Вывод команды Commit: %1", СокрЛП(РепозиторийGit.ПолучитьВыводКоманды()));
	
	ЗавершитьРаботу(0);
	
КонецФункции

Функция ДатаPOSIX(Знач Дата)
	
	Возврат "" + Год(Дата) + "-" + ФорматДвузначноеЧисло(Месяц(Дата)) + "-" + ФорматДвузначноеЧисло(День(Дата)) + " "
	+ ФорматДвузначноеЧисло(Час(Дата)) + ":" + ФорматДвузначноеЧисло(Минута(Дата))
	+ ":" + ФорматДвузначноеЧисло(Секунда(Дата));
	
КонецФункции

Функция ФорматДвузначноеЧисло(ЗначениеЧисло)
	ЧислоСтрокой = Строка(ЗначениеЧисло);
	Если СтрДлина(ЧислоСтрокой) < 2 Тогда
		ЧислоСтрокой = "0" + ЧислоСтрокой;
	КонецЕсли;
	
	Возврат ЧислоСтрокой;
КонецФункции

Функция ПодготовитьФайлКоммита(Знач Комментарий)
	
	ИмяФайлаКомментария = ВременныеФайлы.СоздатьФайл("txt");
	ФайлКомментария = Новый ЗаписьТекста(ИмяФайлаКомментария, КодировкаТекста.UTF8NoBOM);
	ФайлКомментария.Записать(?(ПустаяСтрока(Комментарий), ".", Комментарий));
	ФайлКомментария.Закрыть();
	Лог.Отладка(СтрШаблон("Текст коммита: %1", Комментарий));
	
	Возврат ИмяФайлаКомментария;
	
КонецФункции

Процедура ВыполнитьОбработкуФайлов(Файлы, ПараметрыОбработки)
	
	КаталогРепозитория = ПараметрыОбработки.КаталогРепозитория;
	Ит = 0;
	Пока Ит < Файлы.Количество() Цикл
		
		АнализируемыйФайл = Файлы[Ит].Файл;
		Лог.Отладка("Анализируется файл <%1>", АнализируемыйФайл.Имя);
		
		ИмяФайла = ФайловыеОперации.ПолучитьНормализованныйОтносительныйПуть(КаталогРепозитория,
				СтрЗаменить(АнализируемыйФайл.ПолноеИмя, КаталогРепозитория, ""));
		
		ПараметрыОбработки.ТипИзменения = Файлы[Ит].ТипИзменения;
		
		ФайлОбработан = РазборОтчетовОбработокРасширений.ОбработатьФайл(АнализируемыйФайл,
				ПараметрыОбработки.ТекущийКаталогИсходныхФайлов,
				ПараметрыОбработки);
		
		Если НЕ ФайлОбработан Тогда
			Продолжить;
		КонецЕсли;
		
		Для Каждого ФайлДляДопОбработки Из ПараметрыОбработки.ФайлыДляПостОбработки Цикл
			
			ДобавитьКОбработке(Файлы, ФайловыеОперации.НовыйФайл(ФайлДляДопОбработки), "Изменен");
			
		КонецЦикла;
		
		ПараметрыОбработки.ФайлыДляПостОбработки.Очистить();
		
		Ит = Ит + 1;
		
	КонецЦикла;
	
КонецПроцедуры

Процедура ЗавершитьРаботуПриложения(Знач КодВозврата = Неопределено) Экспорт
	
	Если КодВозврата = Неопределено Тогда
		КодВозврата = РезультатыКоманд().Успех;
	КонецЕсли;
	
	ЗавершитьРаботу(КодВозврата);
	
КонецПроцедуры

Функция ПолучитьСтандартныеПараметрыОбработки() Экспорт
	
	ПараметрыОбработки = Новый Структура();
	ПараметрыОбработки.Вставить("ФайлыДляПостОбработки", Новый Массив);
	ПараметрыОбработки.Вставить("ИзмененныеКаталоги", Новый Массив);
	ПараметрыОбработки.Вставить("Лог", Лог);
	ПараметрыОбработки.Вставить("КаталогРепозитория", Неопределено);
	ПараметрыОбработки.Вставить("ТекущийКаталогИсходныхФайлов", Неопределено);
	ПараметрыОбработки.Вставить("Настройки", Неопределено);
	ПараметрыОбработки.Вставить("ТипИзменения", "Изменен");
	ПараметрыОбработки.Вставить("ЗатребованныеСценарии", Новый Массив);
	
	Возврат ПараметрыОбработки;
	
КонецФункции

Функция РезультатыКоманд() Экспорт
	
	РезультатыКоманд = Новый Структура;
	РезультатыКоманд.Вставить("Успех", 0);
	РезультатыКоманд.Вставить("НеверныеПараметры", 5);
	РезультатыКоманд.Вставить("ОшибкаВремениВыполнения", 1);
	
	Возврат РезультатыКоманд;
	
КонецФункции // РезультатыКоманд

Функция ПолучитьЖурналИзменений()
	
	//ПараметрыКомандыGit = Новый Массив;
	//ПараметрыКомандыGit.Добавить("add *.*");
	//РепозиторийGit.ВыполнитьКоманду(ПараметрыКомандыGit);
	
	ПараметрыКомандыGit = Новый Массив;
	//ПараметрыКомандыGit.Добавить("diff --name-status --staged --no-renames");
	ПараметрыКомандыGit.Добавить("status --short --no-renames");
	РепозиторийGit.ВыполнитьКоманду(ПараметрыКомандыGit);
	РезультатВывода = РепозиторийGit.ПолучитьВыводКоманды();
	СтрокиВывода = СтрРазделить(РезультатВывода, Символы.ПС);
	ЖурналИзменений = Новый Массив;
	
	Для Каждого СтрокаВывода Из СтрокиВывода Цикл
		
		Лог.Отладка("	<%1>", СтрокаВывода);
		
		СтрокаВывода = СокрЛП(СтрокаВывода);
		ПозицияПробела = СтрНайти(СтрокаВывода, Символы.Таб);
		
		Если ПозицияПробела = 0 Тогда
			ПозицияПробела = СтрНайти(СтрокаВывода, " ");
		КонецЕсли;
		
		СимволИзменения = Лев(СтрокаВывода, ПозицияПробела - 1);
		
		ТипИзменения = ВариантИзмененийФайловGit.ОпределитьВариантИзменения(СимволИзменения);
		ИмяФайла = СокрЛП(СтрЗаменить(Сред(СтрокаВывода, ПозицияПробела + 1), """", ""));
		ЖурналИзменений.Добавить(Новый Структура("ИмяФайла, ТипИзменения", ИмяФайла, ТипИзменения));
		
		Лог.Отладка("		В журнале git %2 файл <%1>", ИмяФайла, ТипИзменения);
		
	КонецЦикла;
	
	Возврат ЖурналИзменений;
	
КонецФункции

Процедура ДобавитьКОбработке(СпиоскФ, ДобавляемыйФ, ТипИзменения)
	Строка = СпиоскФ.Добавить();
	Строка.Файл = ДобавляемыйФ;
	Строка.ТипИзменения = ТипИзменения;
КонецПроцедуры

Процедура ДобавитьФайлыВРепозиторий(ПапкаСФайлами, ПапкаРепозитория)
	
	СписокФайлов = НайтиФайлы(ПапкаСФайлами, ".", Истина);
	
	Для каждого ФайлОтчетаОбработки Из СписокФайлов Цикл
		
		//ЧастичныйПуть = СтрЗаменить(ФайлОтчетаОбработки.ИмяФайла, ПутьПроект + "\", "");
		
		НовыйПуть = ОбъединитьПути(ПапкаРепозитория, ФайлОтчетаОбработки.Имя);
		
		Если ФайлОтчетаОбработки.ЭтоКаталог() Тогда			
			Продолжить;
		КонецЕсли;
		
		Попытка
			КопироватьФайл(ФайлОтчетаОбработки.ПолноеИмя, НовыйПуть);
		Исключение
			Лог.Ошибка(ОписаниеОшибки());
		КонецПопытки;
		
	КонецЦикла;
	
КонецПроцедуры

ЗапускПриложения();