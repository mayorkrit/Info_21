-- 1) Написать функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде
-- Ник пира 1, ник пира 2, количество переданных пир поинтов. 
-- Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.
create or replace function fnc_transferred_point_readable()
	returns table(Peer1 varchar, Peer2 varchar, Points numeric) as $$
	begin
		return query(
            with first as (
                select checkingpeer, checkedpeer, pointsamount
                from transferredpoints where checkedpeer < checkingpeer
            ),
            second as (
                select checkingpeer, checkedpeer, -pointsamount  --смотря у какого пира больше поинтов, pointsamount - >0/<0
                from transferredpoints where checkedpeer > checkingpeer
            ),
            summ as (
                select * from first 
                union 
                select *from second
            )

            select checkingpeer, checkedpeer, sum(pointsamount) from summ
            group by (checkingpeer, checkedpeer)
            order by 1
        );
	end;
$$ language plpgsql;
select * from fnc_transferred_point_readable();


-- 2) Написать функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP
-- В таблицу включать только задания, успешно прошедшие проверку (определять по таблице Checks). 
-- Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.
create or replace function fnc_success_tasks()
returns table(Peer varchar, Task varchar, XP bigint) as $$
	begin
	return query(
		select checks.peer, checks.task, xp.xpamount as XP from checks
		join p2p on p2p."Check" = checks.id
		join xp on xp."Check" = checks.id
		where p2p.state = 'Success'
		order by 1
	);
	end;
$$ language plpgsql;

select * from fnc_success_tasks();


-- 3) Написать функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня
-- Параметры функции: день, например 12.05.2022. 
-- Функция возвращает только список пиров.
create or replace function fnc_peers_not_left(pdate date)
returns table(Peer varchar) as $$
	begin
		return query(
			select timetracking.peer from timetracking
			where timetracking.date = pdate
			group by timetracking.peer, date
			having count(state) < 3
		);
	end;
$$ language plpgsql;

select * from fnc_peers_not_left('2023-04-05');


-- 4) Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints
-- Результат вывести отсортированным по изменению числа поинтов. 
-- Формат вывода: ник пира, изменение в количество пир поинтов
create or replace procedure proc_diff_transferred_points(in refc refcursor) as $$
begin
	open refc for
	with first as (
		select checkingpeer, sum(pointsamount) as PointsChange
		from transferredpoints
		group by transferredpoints.checkingpeer
	),
	second as (
		select checkedpeer, -sum(pointsamount) as PointsChange
		from transferredpoints
		group by transferredpoints.checkedpeer
	),
	summ as (
		select * from first
		union
		select * from second
	)
	
	select checkingpeer as Peer, sum(PointsChange) as PointsChange from summ
	group by summ.checkingpeer
	order by 1;
end;
$$ language plpgsql;
	
call proc_diff_transferred_points('2');
fetch all in "2";


-- 5) Посчитать изменение в количестве пир поинтов каждого пира по таблице, возвращаемой первой функцией из Part 3
-- Результат вывести отсортированным по изменению числа поинтов. 
-- Формат вывода: ник пира, изменение в количество пир поинтов
create or replace procedure proc_diff_transferred_points_from_fnc(in refc refcursor) as $$
begin
	open refc for
	with first as (
		select Peer1, sum(Points) as PointsChange
		from fnc_transferred_point_readable()
		group by Peer1
	),
	second as (
		select Peer2, -sum(Points) as PointsChange
		from fnc_transferred_point_readable()
		group by Peer2
	),
	summ as (
		select * from first
		union
		select * from second
	)
	
	select Peer1 as Peer, sum(PointsChange) as PointsChange from summ
	group by Peer1
	order by 1;
end;
$$ language plpgsql;
	
call proc_diff_transferred_points_from_fnc('2');
fetch all in "2";



-- 06


CREATE OR REPLACE PROCEDURE find_most_checked_task()
AS
$$
DECLARE
  check_row RECORD;
  date_val DATE;
  date_list DATE[];
  task_list VARCHAR[];
  max_check_count INTEGER;
BEGIN
  -- Get the distinct list of dates
  SELECT ARRAY(SELECT DISTINCT date FROM checks) INTO date_list;

  -- Iterate over each date
  FOREACH date_val IN ARRAY date_list
  LOOP
    max_check_count := 0;
    task_list := '{}';

    -- Find the maximum check count for the current date
    FOR check_row IN (
      SELECT task, COUNT(*) AS check_count
      FROM checks
      WHERE date = date_val
      GROUP BY task
    )
    LOOP
      -- If the current task has a higher check count, update the max_check_count and task_list
      IF check_row.check_count > max_check_count THEN
        max_check_count := check_row.check_count;
        task_list := ARRAY[check_row.task];
      -- If the current task has the same check count, add it to the task_list
      ELSIF check_row.check_count = max_check_count THEN
        task_list := task_list || check_row.task;
      END IF;
    END LOOP;

    -- Print the results for the current date
    RAISE NOTICE 'Day: %, Task(s): %', date_val, task_list;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

CALL find_most_checked_task();
-- 07

-- part3.sql

-- Процедура для поиска всех пиров, выполнивших весь заданный блок задач
CREATE OR REPLACE PROCEDURE find_completed_block_peers(block_title VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
  last_task_date DATE;
  peer_row RECORD;
BEGIN
  -- Получаем дату завершения последнего задания в блоке
  SELECT MAX(c.date) INTO last_task_date
  FROM tasks t
  JOIN checks c ON t.title = c.task
  WHERE t.title LIKE block_title || '%';

  -- Выводим результаты
  FOR peer_row IN (
    SELECT p.nickname, last_task_date
    FROM peers p
    JOIN checks c ON p.nickname = c.peer
    JOIN tasks t ON c.task = t.title
    WHERE t.title LIKE block_title || '%'
    GROUP BY p.nickname
    HAVING MAX(c.date) = last_task_date
    ORDER BY last_task_date
  )
  LOOP
    RAISE NOTICE 'Peer: %, Day: %', peer_row.nickname, peer_row.last_task_date;
  END LOOP;
END;
$$;

CALL find_completed_block_peers('CPP');

-- 08

-- part3.sql

-- Процедура для определения рекомендуемого пира для каждого обучающегося
CREATE OR REPLACE PROCEDURE find_peer_recommendations()
LANGUAGE plpgsql
AS $$
DECLARE
  peer_row RECORD;
BEGIN
  -- Выводим результаты
  FOR peer_row IN (
    SELECT f.peer1 AS peer, r.recommendedpeer
    FROM friends f
    JOIN recommendations r ON f.peer1 = r.peer
    GROUP BY f.peer1, r.recommendedpeer
    ORDER BY COUNT(*) DESC
  )
  LOOP
    RAISE NOTICE 'Peer: %, RecommendedPeer: %', peer_row.peer, peer_row.recommendedpeer;
  END LOOP;
END;
$$;

CALL find_peer_recommendations();

-- 09

-- part3.sql

-- Процедура для определения процента пиров в различных категориях
CREATE OR REPLACE PROCEDURE calculate_peer_percentages(block1_title VARCHAR, block2_title VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
  total_peers INTEGER;
  started_block1 INTEGER;
  started_block2 INTEGER;
  started_both_blocks INTEGER;
  didnt_start_any_block INTEGER;
  percent_started_block1 FLOAT;
  percent_started_block2 FLOAT;
  percent_started_both_blocks FLOAT;
  percent_didnt_start_any_block FLOAT;
BEGIN
  -- Получаем общее число пиров
  SELECT COUNT(*) INTO total_peers FROM peers;

  -- Получаем число пиров, приступивших к первому блоку
  SELECT COUNT(DISTINCT peer) INTO started_block1
  FROM checks
  WHERE task LIKE block1_title || '%';

  -- Получаем число пиров, приступивших ко второму блоку
  SELECT COUNT(DISTINCT peer) INTO started_block2
  FROM checks
  WHERE task LIKE block2_title || '%';

  -- Получаем число пиров, приступивших к обоим блокам
  SELECT COUNT(DISTINCT peer) INTO started_both_blocks
  FROM checks
  WHERE task LIKE block1_title || '%' AND peer IN (
    SELECT peer
    FROM checks
    WHERE task LIKE block2_title || '%'
  );

  -- Рассчитываем число пиров, не приступивших ни к одному блоку
  didnt_start_any_block := total_peers - (started_block1 + started_block2 - started_both_blocks);

  -- Рассчитываем проценты для каждой категории
  percent_started_block1 := (started_block1 * 100.0) / total_peers;
  percent_started_block2 := (started_block2 * 100.0) / total_peers;
  percent_started_both_blocks := (started_both_blocks * 100.0) / total_peers;
  percent_didnt_start_any_block := (didnt_start_any_block * 100.0) / total_peers;

  -- Выводим результаты
  RAISE NOTICE 'StartedBlock1: %.2f', percent_started_block1;
  RAISE NOTICE 'StartedBlock2: %.2f', percent_started_block2;
  RAISE NOTICE 'StartedBothBlocks: %.2f', percent_started_both_blocks;
  RAISE NOTICE 'DidntStartAnyBlock: %.2f', percent_didnt_start_any_block;
END;
$$;

CALL calculate_peer_percentages('SQL', 'A');

-- 10

drop procedure if exists proc_success_on_bday(refc refcursor);
CREATE OR REPLACE PROCEDURE proc_success_on_bday(IN refc refcursor) AS $$
    BEGIN
        OPEN refc for
        WITH birthday_checks AS (
			SELECT peers.nickname, peers.birthday, checks.id, (to_char(peers.birthday, 'mon DD')) day_of_birth,
            (to_char(checks.date, 'mon DD')) day_of_check
        	FROM peers, checks WHERE peers.nickname = checks.peer
		),
        successfull_checks AS (
			SELECT nickname FROM birthday_checks, p2p
            WHERE day_of_birth = day_of_check AND p2p."Check" = birthday_checks.id AND p2p.state = 'Success'
		),
        fail_checks AS (
			SELECT nickname FROM birthday_checks, p2p WHERE day_of_birth = day_of_check
             AND p2p."Check" = birthday_checks.id AND p2p.state = 'Failure'
		),
        amount_of_peers AS (
			SELECT (SELECT COUNT(*) FROM successfull_checks s) + (SELECT COUNT(*) FROM fail_checks f) AS n
		),
        s_amount AS (
			SELECT (CASE WHEN amount_of_peers.n = 0 THEN 0
            ELSE ((SELECT COUNT(*) FROM successfull_checks)) / (SELECT a.n FROM amount_of_peers a) * 100 END) AS percent
        	FROM amount_of_peers, successfull_checks
		),
        f_amount AS (
			SELECT (CASE WHEN amount_of_peers.n = 0 THEN 0
            ELSE ((SELECT COUNT(*) FROM fail_checks) / (SELECT a.n FROM amount_of_peers a) * 100) END) AS percent
        	FROM amount_of_peers, fail_checks
		)
        SELECT COALESCE(s_amount.percent, '0') "SuccessfulChecks", COALESCE(f_amount.percent, '0') "UnsuccessfulChecks"
        FROM f_amount
        FULL JOIN s_amount ON true AND false;
    end;
$$ LANGUAGE plpgsql;

call proc_success_on_bday('1');
fetch all in "1";

-- 11

-- Процедура для определения пиров, сдавших задания 1 и 2, но не сдавших задание 3
CREATE OR REPLACE PROCEDURE find_peers_with_specific_tasks()
LANGUAGE plpgsql
AS $$
DECLARE
  peer_row RECORD;
  task1 VARCHAR := 'C2_s21_stringplus';
  task2 VARCHAR := 'C3_s21_SimpleBashUtils';
  task3 VARCHAR := 'C4_s21_math';
BEGIN
  -- Находим пиров, сдавших задания 1 и 2, но не сдавших задание 3
  FOR peer_row IN
    SELECT DISTINCT c.peer
    FROM checks c
    WHERE (c.task = task1 OR c.task = task2)
    EXCEPT
    SELECT DISTINCT c.peer
    FROM checks c
    WHERE c.task = task3
  LOOP
    -- Выводим результат
    RAISE NOTICE 'Peer: %', peer_row.peer;
  END LOOP;
END;
$$;

CALL find_peers_with_specific_tasks();

-- 12
DROP PROCEDURE IF EXISTS task_road(ref refcursor);

CREATE OR REPLACE PROCEDURE task_road(IN ref refcursor)
AS $$
BEGIN
    OPEN ref FOR
    WITH RECURSIVE task_hierarchy AS (
    SELECT th.title AS task, 0 AS prev_count
    FROM tasks th
    WHERE parenttask IS NULL
      
    UNION ALL
      
    SELECT t.title, th.prev_count + 1
    FROM tasks t
    INNER JOIN task_recursive th ON t.parenttask = th.task
    )
SELECT task, prev_count FROM task_recursive;END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL task_road('ref');
fetch ALL in "ref";
end;

-- 13
-- part3.sql

-- Procedure to find "successful" days with a specified number of consecutive successful checks
CREATE OR REPLACE PROCEDURE find_successful_days(N INTEGER)
AS $$
DECLARE
  successful_days DATE[] := '{}';
  current_streak INTEGER := 0;
  previous_check_time TIME := NULL;
  previous_check_xp BIGINT := NULL;
  p2p_row RECORD;
  p2p_cursor CURSOR FOR
    SELECT p."Check", p.state, p.time, xp.xpamount, t.maxxp
    FROM p2p p
    JOIN xp ON xp."Check" = p."Check"
    JOIN tasks t ON t.title = (SELECT task FROM checks WHERE id = p."Check")
    ORDER BY p."Check", p.time;
BEGIN
  OPEN p2p_cursor;
  LOOP
    FETCH p2p_cursor INTO p2p_row;
    EXIT WHEN NOT FOUND;

    IF p2p_row.state = 'Success' THEN
      IF previous_check_time IS NOT NULL AND previous_check_xp IS NOT NULL AND
         p2p_row.time > previous_check_time AND
         p2p_row.xpamount >= 0.8 * previous_check_xp AND
         p2p_row.xpamount >= 0.8 * p2p_row.maxxp THEN
        current_streak := current_streak + 1;
      ELSE
        current_streak := 1;
      END IF;

      previous_check_time := p2p_row.time;
      previous_check_xp := p2p_row.xpamount;

      IF current_streak >= N THEN
        successful_days := array_append(successful_days, (SELECT date FROM checks WHERE id = p2p_row."Check"));
      END IF;
    ELSE
      current_streak := 0;
      previous_check_time := NULL;
      previous_check_xp := NULL;
    END IF;
  END LOOP;

  CLOSE p2p_cursor;

  RAISE NOTICE 'Successful Days: %', successful_days;
END;
$$ LANGUAGE plpgsql;

CALL find_successful_days(3);

-- 14
create or replace procedure pr_max_xp (ref refcursor) 
as $$ 
begin open ref for
select Peer as "Peer", sum(XPAmount) as "XP"
from xp inner join checks on xp._check=checks.id group by Peer
order by 2 desc
limit 1;
end;
$$ language plpgsql;

call pr_max_xp('ref');
fetch all in "ref";


-- 15

create or replace function fn_early_entire (choose_time time, N bigint)
returns table (Nickname varchar)
as $$
begin return query
select peer from timetracking 
where State=1 and timetracking.time < choose_time
group by peer
having count (peer) >= N;
end;
$$ language plpgsql;

select * from fn_early_entire ('200000', 2);

-- 16

create or replace function fn_entire_Ndays_Mtimes (N bigint, M bigint)
returns table (Nickname varchar)
as $$
begin return query
select peer from timetracking 
where State=2 and date >= (SELECT MAX(date) - INTERVAL '1 day' * N FROM timetracking)
group by peer
having count (peer) >= M;
end;
$$ language plpgsql;

SELECT * FROM fn_entire_Ndays_Mtimes(5, 1);

-- 17
CREATE OR REPLACE FUNCTION fnc_early_entries_percent()
RETURNS table (Month varchar, EarlyEntries numeric(5, 1)) AS $$
    BEGIN
        return query
        WITH entries AS (
            SELECT timetracking.peer, timetracking.time, (to_char(timetracking.date, 'month')) AS entrance_date,
                   (to_char(peers.birthday, 'month')) AS birthday FROM timetracking
            JOIN peers on peers.nickname = timetracking.peer
            WHERE timetracking.state = 1
            ),
         number_of_entries AS (
             SELECT entries.peer, entries.time, entries.entrance_date FROM entries
             WHERE entries.entrance_date = entries.birthday
             ),
         total_number_of_entries AS (
             SELECT DISTINCT entries.peer, entries.entrance_date, COUNT(entries.entrance_date) entries FROM entries
             WHERE entries.entrance_date = entries.birthday GROUP BY entries.peer, entries.entrance_date
             ),
         number_of_early_entries AS (
			 SELECT total_number_of_entries.entries, substring(total_number_of_entries.entrance_date from '\D*') AS month
             FROM total_number_of_entries, number_of_entries
             WHERE number_of_entries.time < '12:00:00' AND number_of_entries.entrance_date = total_number_of_entries.entrance_date AND number_of_entries.peer = total_number_of_entries.peer 
			 GROUP BY total_number_of_entries.entrance_date, total_number_of_entries.entries
		 ),
         months AS (
			 SELECT TRIM(to_char(generate_series('2023-01-01'::date, '2023-12-01'::date, '1 month'), 'month')) AS month, 0 AS entries
		 ),
        result AS (
            SELECT TRIM(t.month::varchar) AS month,
            (t.entries::numeric / (SELECT SUM(t.entries) FROM total_number_of_entries t) * 100) AS entries
            FROM number_of_early_entries t
            GROUP BY t.entries, t.month
            UNION ALL
            SELECT m.month::varchar, 0 FROM months m, number_of_early_entries n)
        SELECT r.month::varchar, (SUM(r.entries))::numeric(5,1) FROM result r GROUP BY r.month
            ORDER BY concat('2023-'::varchar, r.month::varchar,'-01'::varchar)::date;
    end;
$$ LANGUAGE plpgsql;

select * from fnc_early_entries_percent();