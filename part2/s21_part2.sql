--1) Написать процедуру добавления P2P проверки
--Параметры: ник проверяемого peer1, ник проверяющего peer2, название задания, статус P2P проверки, время. 
--Если задан статус "начало", добавить запись в таблицу Checks (в качестве даты использовать сегодняшнюю). 
--Добавить запись в таблицу P2P. 
--Если задан статус "начало", в качестве проверки указать только что добавленную запись, иначе указать проверку с незавершенным P2P этапом.

drop procedure if exists p2pCheckAndAdd cascade;

create or replace procedure p2pCheckAndAdd (checked_peer varchar, checking_peer varchar, name_of_task text, status_of_P2P check_status, time_of_P2P TIME)  AS $$
    begin
        if (status_of_P2P = 'Start')
		then
            if ((select count(*) from p2p
                join checks 
				on p2p."Check" = checks.id
                where p2p.checkingpeer = checking_peer and checks.peer = checked_peer and checks.task = name_of_task) = 0) 
			then
				insert into p2p values ((select max(id) from p2p) + 1, (select max(id) from checks), checking_peer, status_of_P2P, time_of_P2P);
				insert into checks values ((select max(id) from checks) + 1, checked_peer, name_of_task, NOW());
            else
                raise exception 'Error! Check is not finished yet!';
            end if;	
        else
            insert into p2p values ((select max(id) from p2p) + 1,
                    (select "Check" from p2p
                     join checks 
					 on p2p."Check" = checks.id
                     where p2p.checkingpeer = checking_peer and checks.peer = checked_peer and checks.task = name_of_task),
                    checking_peer, status_of_P2P, time_of_P2P);
        end if;
    end;
 $$ language plpgsql;
 
 call p2pCheckAndAdd('loretath','ghostgar','C2_s21_stringplus', 'Start', '14:30');
 select * from checks;
 select * from p2p;
 call p2pCheckAndAdd('loretath','ghostgar','C2_s21_stringplus', 'Start', '14:30'); -- выйдет ошибка
 call p2pCheckAndAdd('cleverman','perfectgirl','C6_s21_matrix','Start','12:49');
 select * from checks;
 select * from p2p;

 -- 2) Написать процедуру добавления проверки Verter'ом
-- Параметры: ник проверяемого, название задания, статус проверки Verter'ом, время. 
-- Добавить запись в таблицу Verter (в качестве проверки указать проверку соответствующего задания с самым поздним (по времени) успешным P2P этапом)
drop procedure if exists verterChecking cascade;

create or replace procedure verterChecking(checked_peer varchar, name_of_task varchar, status_of_check check_status, time_of_check TIME) as $$
 begin
 if status_of_check = 'Start' then
  if ((select max(p2p.time) from p2p
   join checks on p2p."Check" = checks.id
   where checks.peer = checked_peer and checks.task = name_of_task and p2p.state = 'Success') is not NULL)
  then
  insert into verter values ((select max(id) from verter) + 1, 
        (select distinct checks.id from checks
        join p2p on p2p."Check" = checks.id
        where checks.peer = checked_peer and checks.task = name_of_task and p2p.state = 'Success'),
        status_of_check, time_of_check);
  else
   raise exception 'Error! Peer has not finished checking yet or result is Failure';
  end if;
 else
  insert into verter values ((select max(id) from verter) + 1,
        (select "Check" from verter group by "Check"),
        status_of_check, time_of_check);
  end if;
 end;
$$ language plpgsql;

call verterChecking('loretath','C2_s21_stringplus','Start', '10:30');
select * from verter;

call verterChecking('hzkto','C2_s21_stringplus','Start','10:30'); -- Failure
select * from verter;

call verterChecking('perfectgirl','C3_s21_SimpleBashUtils','Start','20:00'); -- Did not start
select * from verter;

-- 3) Написать триггер: после добавления записи со статутом "начало" в таблицу P2P, изменить соответствующую запись в таблице TransferredPoints
create or replace function fnc_trg_p2p_transferred_points()
returns trigger as $trg_p2p_transferred_points$
    begin
        if NEW.state = 'Start' then
            with updated as (
                select NEW.checkingpeer, checks.peer as checkedpeer from p2p
                join checks on p2p."Check" = checks.id
                where p2p.state = 'Start' and NEW."Check" = checks.id
            )
            update transferredpoints 
            set pointsamount = pointsamount + 1
            from updated
            where transferredpoints.checkingpeer = updated.checkingpeer and transferredpoints.checkedpeer = updated.checkedpeer;
            return NEW;
        end if;
        return null;
    end;
$trg_p2p_transferred_points$
language plpgsql;

create or replace trigger trg_p2p_transferred_points
after insert on p2p
for each row
execute function fnc_trg_p2p_transferred_points();

insert into p2p ("Check",checkingpeer,state,time) values (5,'perfectgirl','Success','16:00');
select * from p2p;
select * from transferredpoints;


-- 4) Написать триггер: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи

create or replace function fnc_trg_xp()
returns trigger as $trg_xp$
    begin
        if (select maxxp from tasks
        join checks on checks.task = tasks.title
        where NEW."Check" = checks.id) >= NEW.xpamount and
        ((select state from verter
        join xp on xp."Check" = verter."Check"
        where (verter.state = 'Success' or verter.state = 'Failure') and NEW."Check" = verter."Check") = 'Success' or
        (select state from p2p
        join xp on xp."Check" = p2p."Check"
        where (p2p.state = 'Success' or p2p.state = 'Failure') and NEW."Check" = p2p."Check") = 'Success')
        then
            raise exception 'Error! XP is greater or project is failed';
        else 
            return (NEW.id, NEW."Check", NEW.xpamount);
        end if;
    end;
    $trg_xp$
    language plpgsql;

create or replace trigger trg_xp
before insert on XP
execute function fnc_trg_xp();

insert into xp ("Check", xpamount) values (1, 1442342); -- xp is greater
select * from xp;