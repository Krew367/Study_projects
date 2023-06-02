/* 1. Посчитайте, сколько компаний закрылось. */

SELECT COUNT(status)
FROM company
WHERE status = 'closed'

/* 2. Отобразите количество привлечённых средств для 
новостных компаний США. Используйте данные из таблицы company. 
Отсортируйте таблицу по убыванию значений в поле funding_total. */

SELECT funding_total
FROM company
WHERE country_code = 'USA'
      AND category_code = 'news'
ORDER BY funding_total DESC

/* 3. Найдите общую сумму сделок по покупке одних компаний другими 
в долларах. Отберите сделки, которые осуществлялись только за наличные 
с 2011 по 2013 год включительно. */

SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash'
      AND EXTRACT(YEAR FROM CAST(acquired_at AS timestamp)) IN (2011, 2012, 2013)
      
/* 4. Отобразите имя, фамилию и названия аккаунтов людей в твиттере, 
 у которых названия аккаунтов начинаются на 'Silver'. */
      
SELECT first_name,
       last_name,
       twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%'

/* 5. Выведите на экран всю информацию о людях, у которых названия аккаунтов 
в твиттере содержат подстроку 'money', а фамилия начинается на 'K'. */

SELECT *
FROM people
WHERE twitter_username LIKE '%money%'
      AND last_name LIKE 'K%'
      
 /* 6. Для каждой страны отобразите общую сумму привлечённых инвестиций, 
 которые получили компании, зарегистрированные в этой стране. Страну, 
 в которой зарегистрирована компания, можно определить по коду страны. 
 Отсортируйте данные по убыванию суммы. */
      
 SELECT country_code,
       SUM(funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC

/* 7. Составьте таблицу, в которую войдёт дата проведения раунда, 
а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы 
инвестиций не равно нулю и не равно максимальному значению. */

SELECT CAST(funded_at AS date),
       min(raised_amount),
       max(raised_amount)
FROM funding_round
GROUP BY CAST(funded_at AS date)
HAVING min(raised_amount) != max(raised_amount)
       AND min(raised_amount) != 0
       
/* 8. Создайте поле с категориями:
Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
Отобразите все поля таблицы fund и новое поле с категориями. */
       
SELECT *,
       CASE
    WHEN invested_companies >= 100 THEN 'high_activity'
    WHEN invested_companies >= 20 AND invested_companies <100 THEN 'middle_activity'
    WHEN invested_companies < 20 THEN 'low_activity'
    END
FROM fund

/* 9. Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое 
 до ближайшего целого числа среднее количество инвестиционных раундов, в которых фонд принимал участие. 
 Выведите на экран категории и среднее число инвестиционных раундов. Отсортируйте таблицу по возрастанию среднего. */

SELECT ROUND(AVG(investment_rounds)),
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity
FROM fund
GROUP BY activity
ORDER BY ROUND(AVG(investment_rounds))

/* 10. Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали фонды этой страны, 
основанные с 2010 по 2012 год включительно. Исключите страны с фондами, у которых минимальное число компаний, 
получивших инвестиции, равно нулю. */

SELECT country_code,
       MIN(invested_companies) AS min_companies,
       MAX(invested_companies) AS max_companies,
       AVG(invested_companies) AS avg_companies
FROM fund
WHERE CAST(founded_at AS date) BETWEEN '2010-01-01' AND '2012-12-31'  
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY  avg_companies DESC, country_code 
LIMIT 10;

/* 11. Отобразите имя и фамилию всех сотрудников стартапов. Добавьте поле с названием учебного заведения, 
которое окончил сотрудник, если эта информация известна.  */

SELECT p.first_name,
       p.last_name,
       e.instituition
FROM people AS p LEFT JOIN education AS e ON p.id = e.person_id

/* 12. Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. 
Выведите название компании и число уникальных названий учебных заведений. Составьте топ-5 компаний по количеству университетов.
Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу по среднему количеству компаний от большего к меньшему. 
Затем добавьте сортировку по коду страны в лексикографическом порядке. */

SELECT c.name,
       COUNT(DISTINCT e.instituition)
FROM company AS c JOIN people AS p ON c.id = p.company_id
     JOIN education AS e ON p.id = e.person_id
GROUP BY c.name
ORDER BY COUNT(DISTINCT e.instituition) DESC
LIMIT 5
     
/* 13. Составьте список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним. */

WITH
fr AS (SELECT *
      FROM funding_round
      WHERE is_first_round = 1
      AND is_last_round = 1) 

SELECT DISTINCT c.name
FROM fr LEFT JOIN company AS c ON fr.company_id = c.id
WHERE status = 'closed'

/* 14. Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании. */

WITH
fr AS (SELECT *
      FROM funding_round
      WHERE is_first_round = 1
      AND is_last_round = 1),
      
c AS (SELECT *
     FROM company
     WHERE status = 'closed')

SELECT DISTINCT p.id
FROM fr JOIN c ON c.id = fr.company_id
        JOIN people AS p ON c.id = p.company_id

/* 15. Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи 
и учебным заведением, которое окончил сотрудник. */
        
 WITH
fr AS (SELECT company_id
      FROM funding_round
      WHERE is_first_round = 1
      AND is_last_round = 1),
      
c AS (SELECT id
     FROM company
     WHERE status = 'closed')

SELECT DISTINCT p.id,
       e.instituition
FROM fr JOIN c ON c.id = fr.company_id
        JOIN people AS p ON c.id = p.company_id
        JOIN education AS e ON p.id = e.person_id
        
 /* 16. Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. 
При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды. */
        
SELECT p.id, 
  COUNT(e.instituition) 
FROM people AS p 
JOIN education AS e ON e.person_id = p.id 
WHERE p.company_id in (
    SELECT c.id 
    FROM company c 
    JOIN funding_round AS f ON c.id = f.company_id 
      AND f.is_first_round = 1 
      AND f.is_last_round = 1 
      AND c.status = 'closed'
  ) 
GROUP BY p.id

/* 17. Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), 
которые окончили сотрудники разных компаний. Нужно вывести только одну запись, группировка здесь не понадобится. */

SELECT AVG(uni)
FROM
(SELECT
  COUNT(e.instituition) AS uni
FROM people AS p 
JOIN education AS e ON e.person_id = p.id 
WHERE p.company_id in (
    SELECT c.id 
    FROM company c 
    JOIN funding_round AS f ON c.id = f.company_id 
      AND f.is_first_round = 1 
      AND f.is_last_round = 1 
      AND c.status = 'closed'
  ) 
GROUP BY p.id) AS i

/* 18. Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), 
которые окончили сотрудники Facebook */

SELECT AVG(uni)
FROM
(SELECT
  COUNT(e.instituition) AS uni
FROM people AS p 
JOIN education AS e ON e.person_id = p.id 
WHERE p.company_id in (
    SELECT c.id 
    FROM company c 
    JOIN funding_round AS f ON c.id = f.company_id 
      AND c.name = 'Facebook'
  ) 
GROUP BY p.id) AS i

/* 19. 
Составьте таблицу из полей:
name_of_fund — название фонда;
name_of_company — название компании;
amount — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, 
а раунды финансирования проходили с 2012 по 2013 год включительно. */

WITH 
itog AS (SELECT f.name AS name_of_fund,
                c.name AS name_of_company,
                fr.raised_amount AS amount,
                c.milestones,
                fr.funded_at
        FROM investment AS i LEFT JOIN company AS c ON i.company_id = c.id
        LEFT JOIN fund AS f ON i.fund_id = f.id
        LEFT JOIN funding_round AS fr ON i.funding_round_id = fr.id)
        
SELECT name_of_fund,
       name_of_company,
       amount
FROM itog
WHERE milestones > 6 
      AND EXTRACT(YEAR FROM CAST(funded_at AS date)) IN (2012, 2013)
      
/* 20. Выгрузите таблицу, в которой будут такие поля:
название компании-покупателя;
сумма сделки;
название компании, которую купили;
сумма инвестиций, вложенных в купленную компанию;
доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.

Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. 
Ограничьте таблицу первыми десятью записями. */
      
SELECT
c.name AS acquiring_name,
c2.name AS acquired_name,
a.price_amount,
c2.funding_total,
ROUND(a.price_amount/c2.funding_total) AS ratio
FROM acquisition AS a
LEFT JOIN company AS c ON a.acquiring_company_id=c.id
LEFT JOIN company AS c2 ON a.acquired_company_id=c2.id
WHERE a.price_amount!=0 AND c2.funding_total!=0
ORDER BY a.price_amount DESC, acquired_name
LIMIT 10

/* 21. Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование с 2010 по 2013 год включительно. 
Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, в котором проходил раунд финансирования. */

SELECT c.name,
       EXTRACT(MONTH FROM CAST(fr.funded_at AS date))
FROM company AS c JOIN funding_round AS fr ON c.id = fr.company_id 
WHERE (EXTRACT(YEAR FROM CAST(funded_at AS date)) IN (2010, 2011, 2012, 2013)
      AND fr.raised_amount > 0
      AND c.category_code = 'social')

/* 22. 
Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
номер месяца, в котором проходили раунды;
количество уникальных названий фондов из США, которые инвестировали в этом месяце;
количество компаний, купленных за этот месяц;
общая сумма сделок по покупкам в этом месяце. */
      
WITH fundings AS
(SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS DATE)) AS funding_month,
COUNT(DISTINCT f.id) AS us_funds
FROM fund AS f
LEFT JOIN investment AS i ON f.id = i.fund_id
LEFT JOIN funding_round AS fr ON i.funding_round_id = fr.id
WHERE f.country_code = 'USA'
AND EXTRACT(YEAR FROM CAST(fr.funded_at AS DATE)) BETWEEN 2010 AND 2013
GROUP BY funding_month),
acquisitions AS
(SELECT EXTRACT(MONTH FROM CAST(acquired_at AS DATE)) AS funding_month,
COUNT(acquired_company_id) AS bought_co,
SUM(price_amount) AS sum_total
FROM acquisition
WHERE EXTRACT(YEAR FROM CAST(acquired_at AS DATE)) BETWEEN 2010 AND 2013
GROUP BY funding_month)
SELECT fnd.funding_month, fnd.us_funds, acq.bought_co, acq.sum_total
FROM fundings AS fnd
LEFT JOIN acquisitions AS acq ON fnd.funding_month = acq.funding_month;

/* 23. Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. 
Данные за каждый год должны быть в отдельном поле. Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему. */

WITH y_11 AS
(SELECT country_code AS country,
AVG(funding_total) AS y_2011
FROM company
WHERE EXTRACT(YEAR FROM founded_at::DATE) IN(2011, 2012, 2013)
GROUP BY country, EXTRACT(YEAR FROM founded_at)
HAVING EXTRACT(YEAR FROM founded_at) = '2011'),
y_12 AS
(SELECT country_code AS country,
AVG(funding_total) AS y_2012
FROM company
WHERE EXTRACT(YEAR FROM founded_at::DATE) IN(2011, 2012, 2013)
GROUP BY country, EXTRACT(YEAR FROM founded_at)
HAVING EXTRACT(YEAR FROM founded_at) = '2012'),
y_13 AS
(SELECT country_code AS country,
AVG(funding_total) AS y_2013
FROM company
WHERE EXTRACT(YEAR FROM founded_at::DATE) IN(2011, 2012, 2013)
GROUP BY country, EXTRACT(YEAR FROM founded_at)
HAVING EXTRACT(YEAR FROM founded_at) = '2013')
SELECT y_11.country, y_2011, y_2012, y_2013
FROM y_11
JOIN y_12 ON y_11.country = y_12.country
JOIN y_13 ON y_12.country = y_13.country
ORDER BY y_2011 DESC;

