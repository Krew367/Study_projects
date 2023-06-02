/* 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки». */

SELECT count(p.id)
FROM stackoverflow.posts p
join stackoverflow.post_types pt on p.post_type_id = pt.id
where pt.type = 'Question' AND (p.score > 300 or p.favorites_count >= 100)

/* 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа. */

SELECT ROUND(AVG(q.count), 0)
FROM (
      SELECT COUNT(id),
             creation_date::date
      FROM stackoverflow.posts
      WHERE post_type_id = 1
      GROUP BY creation_date::date
      HAVING creation_date::date BETWEEN '2008-11-01' AND '2008-11-18') AS q;
      
/* 3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей. */
     
 SELECT COUNT(DISTINCT b.user_id)
FROM stackoverflow.badges AS b
JOIN stackoverflow.users AS u ON u.id=b.user_id
WHERE u.creation_date::date = b.creation_date::date

/* 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос? */

SELECT COUNT(cv.id)
FROM (SELECT ps.id
      FROM stackoverflow.posts AS ps
      JOIN stackoverflow.votes AS v ON ps.id=v.post_id
      JOIN stackoverflow.users AS u ON ps.user_id=u.id
      WHERE u.display_name LIKE 'Joel Coehoorn' AND v.id > 0
      GROUP BY ps.id) AS cv;
      
/* 5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. 
Таблица должна быть отсортирована по полю id. */
     
SELECT *,
       ROW_NUMBER() OVER(ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id;

/* 6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: 
идентификатором пользователя и количеством голосов. Отсортируйте данные сначала по убыванию количества голосов, 
потом по убыванию значения идентификатора пользователя. */

SELECT *
FROM (SELECT v.user_id,
             COUNT(vt.id) AS v_cnt
      FROM stackoverflow.votes AS v
      JOIN stackoverflow.vote_types AS vt ON vt.id=v.vote_type_id
      WHERE vt.name LIKE 'Close'
      GROUP BY v.user_id
      ORDER BY v_cnt DESC
      LIMIT 10) AS au
ORDER BY au.v_cnt DESC, au.user_id DESC;

/* 7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.

Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя. */

SELECT *,
      DENSE_RANK() OVER (ORDER BY b.b_cnt DESC) AS rating
FROM (SELECT user_id,
             COUNT(id) AS b_cnt
      FROM stackoverflow.badges
      WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15' 
      GROUP BY user_id
      ORDER BY b_cnt DESC, user_id LIMIT 10) as b;
      
/* 8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.

Не учитывайте посты без заголовка, а также те, что набрали ноль очков. */
     
WITH sc AS (
SELECT ROUND(AVG(score)) AS avg_score,
       user_id
FROM stackoverflow.posts
WHERE title IS NOT NULL AND score <> 0
GROUP BY user_id)

SELECT p.title,
       sc.user_id,
       p.score,
       sc.avg_score
FROM sc
JOIN stackoverflow.posts AS p ON sc.user_id=p.user_id
WHERE p.title IS NOT NULL AND p.score <> 0;

/* 9. Отобразите заголовки постов, которые были написаны пользователями, 
получившими более 1000 значков. Посты без заголовков не должны попасть в список. */

SELECT title
FROM stackoverflow.posts
WHERE user_id IN (SELECT user_id
                  FROM stackoverflow.badges
                  GROUP BY user_id
                  HAVING COUNT(id) >1000)
              AND title IS NOT NULL;
              
/* 10. Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). 
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.

Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу. */
             
SELECT id,
       views,
       CASE
          WHEN views >= 350 THEN 1
          WHEN views < 100 THEN 3
          ELSE 2
       END AS group
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND views > 0;

/* 11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, 
которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора. */

WITH grp AS (SELECT g.id,
                    g.views,
                    g.group,
                    MAX(g.views) OVER (PARTITION BY g.group) AS max     
             FROM (SELECT id,
                          views,
                          CASE
                             WHEN views >= 350 THEN 1
                             WHEN views < 100 THEN 3
                             ELSE 2
                          END AS group
                   FROM stackoverflow.users
                   WHERE location LIKE '%Canada%' AND views > 0) as g
              )
  
SELECT grp.id, 
       grp.views,  
       grp.group
FROM grp
WHERE grp.views = grp.max
ORDER BY grp.views DESC, grp.id;

/* 12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением. */

SELECT *,
       SUM(uc.cnt_reg) OVER (ORDER BY uc.days) as cnt_users
FROM (SELECT EXTRACT(DAY FROM creation_date::date) AS days,
             COUNT(id) AS cnt_reg
      FROM stackoverflow.users
      WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
      GROUP BY EXTRACT(DAY FROM creation_date::date)
      ) as uc;

/* 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. 
Отобразите:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом. */
     
 WITH dt AS (SELECT DISTINCT user_id,
                            MIN(creation_date) OVER (PARTITION BY user_id) AS min_dt      
            FROM stackoverflow.posts)

SELECT dt.user_id,
       (dt.min_dt - u.creation_date) AS diff
FROM stackoverflow.users AS u 
JOIN dt ON  u.id = dt.user_id;