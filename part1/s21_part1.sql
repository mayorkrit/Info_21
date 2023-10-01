-- TABLES CREATION
CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');

CREATE TABLE Peers
(
  Nickname varchar NOT NULL PRIMARY KEY,
  Birthday date NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE Tasks
(
  Title varchar NOT NULL PRIMARY key,
  ParentTask varchar DEFAULT NULL REFERENCES Tasks(Title),
  MaxXP bigint NOT NULL DEFAULT 0,
  CONSTRAINT chk_parenttask CHECK (parenttask IS NULL OR parenttask <> title)
);

CREATE OR REPLACE FUNCTION check_entry_condition() RETURNS TRIGGER AS $$
DECLARE
  null_count INTEGER;
BEGIN
  IF NEW.ParentTask IS NULL THEN
    SELECT COUNT(*) FROM Tasks WHERE parenttask IS NULL INTO null_count;
    IF null_count > 0 THEN
      RAISE EXCEPTION 'Only one task can have the entry condition set to null';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER entry_condition_trigger
BEFORE INSERT OR UPDATE ON Tasks
FOR EACH ROW
EXECUTE FUNCTION check_entry_condition();

CREATE TABLE Checks
(
  ID serial not NULL PRIMARY Key,
  Peer varchar NOT NULL,
  Task varchar NOT NULL,
  Date date NOT NULL DEFAULT CURRENT_DATE,
  constraint fk_check_peer_nickname foreign key (Peer) references Peers(Nickname),
  constraint fk_check_task foreign key (Task) references Tasks(Title)
);

CREATE TABLE P2P
(
  id serial PRIMARY KEY,
  "Check" bigint NOT NULL,
  CheckingPeer varchar NOT NULL,
  State check_status NOT NULL,
  Time TIME (0) DEFAULT CURRENT_TIME,
  constraint fk_p2p_check foreign key ("Check") references Checks(ID),
  constraint fk_p2p_peer_nickname foreign key (CheckingPeer) references Peers(Nickname)
);

CREATE TABLE Verter
(
  ID serial PRIMARY KEY,
  "Check" bigint NOT NULL,
  STATE check_status NOT NULL,
  Time TIME (0) DEFAULT CURRENT_TIME,
  constraint fk_Verter_checks foreign key ("Check") references Checks(ID)
);

CREATE TABLE XP
(
  ID serial PRIMARY KEY,
  "Check" bigint NOT NULL,
  XPAmount bigint NOT NULL,
  constraint fk_Verter_checks foreign key ("Check") references Checks(ID)
);

CREATE TABLE TransferredPoints
(
  ID serial PRIMARY KEY,
  CheckingPeer varchar NOT NULL,
  CheckedPeer varchar NOT NULL,
  PointsAmount BIGINT NOT NULL,
  constraint fk_points_checkingpeer foreign key (checkingpeer) references peers(nickname),
  constraint fk_points_checkedpeer foreign key (CheckedPeer) references peers(nickname)
);

CREATE TABLE Friends
(
  ID serial PRIMARY KEY,
  Peer1 varchar NOT NULL,
  Peer2 varchar NOT NULL,
  constraint fk_friends_peer1 foreign key (Peer1) references peers(nickname),
  constraint fk_friends_peer2 foreign key (Peer2) references peers(nickname)
);

CREATE TABLE Recommendations
(
  ID serial PRIMARY KEY,
  Peer varchar NOT NULL,
  RecommendedPeer varchar NOT NULL,
  constraint fk_friends_peer1 foreign key (Peer) references peers(nickname),
  constraint fk_friends_peer2 foreign key (RecommendedPeer) references peers(nickname)
);

CREATE TABLE TimeTracking
(
  ID serial PRIMARY KEY,
  Peer varchar NOT NULL,
  Date date NOT NULL DEFAULT CURRENT_DATE,
  Time TIME (0) DEFAULT CURRENT_TIME,
  State int,
  constraint fk_time_peer1 foreign key (Peer) references peers(nickname),
  constraint state_1 check (state between 1 and 2)
);

-- END OF TABLES CREATION

-- BEGINING OF INSERTS
-- PEERS TABLE 
INSERT INTO peers VALUES ('ghostgar', '2001-11-29');
INSERT INTO peers VALUES ('loretath', '2001-05-07');
INSERT INTO peers VALUES ('cleverman','1987-01-27');
INSERT INTO peers VALUES ('perfectgirl','2003-03-03');
INSERT INTO peers VALUES ('hzkto','1990-08-15');

-- TASKS TABLE
INSERT INTO tasks VALUES ('C2_s21_stringplus', null, 100);
INSERT INTO tasks VALUES ('C3_s21_SimpleBashUtils', 'C2_s21_stringplus', 150);
INSERT INTO tasks VALUES ('C4_s21_math', 'C3_s21_SimpleBashUtils', 400);
INSERT INTO tasks VALUES ('C5_s21_decimal', 'C3_s21_SimpleBashUtils', 200);
INSERT INTO tasks VALUES ('C6_s21_matrix', 'C4_s21_math', 800);

-- TIME TRACKING TABLE
INSERT INTO timetracking(peer,date,time,state) VALUES ('ghostgar', '2023-04-05', '13:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('ghostgar', '2023-04-05', '17:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('ghostgar', '2023-04-05', '17:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('ghostgar', '2023-04-05', '20:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('ghostgar', '2023-07-13', '13:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('ghostgar', '2023-07-13', '17:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('ghostgar', '2023-07-14', '17:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('ghostgar', '2023-07-14', '20:30', '2');

INSERT INTO timetracking(peer,date,time,state) VALUES ('loretath', '2023-05-21', '10:00', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('loretath', '2023-05-21', '14:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('loretath', '2023-05-21', '14:57', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('loretath', '2023-05-21', '18:27', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('loretath', '2023-06-15', '11:00', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('loretath', '2023-06-15', '16:25', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('loretath', '2023-06-15', '18:57', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('loretath', '2023-06-15', '22:20', '2');

INSERT INTO timetracking(peer,date,time,state) VALUES ('cleverman', '2023-01-05', '13:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('cleverman', '2023-01-05', '17:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('cleverman', '2023-02-05', '17:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('cleverman', '2023-02-05', '20:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('cleverman', '2023-03-13', '13:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('cleverman', '2023-03-13', '17:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('cleverman', '2023-08-14', '17:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('cleverman', '2023-08-14', '20:30', '2');

INSERT INTO timetracking(peer,date,time,state) VALUES ('perfectgirl', '2023-09-05', '13:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('perfectgirl', '2023-09-05', '17:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('perfectgirl', '2023-10-05', '17:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('perfectgirl', '2023-10-05', '20:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('perfectgirl', '2023-11-13', '13:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('perfectgirl', '2023-11-13', '17:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('perfectgirl', '2023-11-14', '17:45', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('perfectgirl', '2023-11-14', '20:30', '2');

INSERT INTO timetracking(peer,date,time,state) VALUES ('hzkto', '2022-12-21', '10:00', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('hzkto', '2022-12-21', '14:30', '2');
INSERT INTO timetracking(peer,date,time,state) VALUES ('hzkto', '2022-12-21', '14:57', '1');
INSERT INTO timetracking(peer,date,time,state) VALUES ('hzkto', '2022-12-21', '18:27', '2');

-- RECOMMENDATIONS TABLE
INSERT INTO recommendations(peer, recommendedpeer) VALUES ('ghostgar', 'loretath');
INSERT INTO recommendations(peer, recommendedpeer) VALUES ('hzkto', 'cleverman');
INSERT INTO recommendations(peer, recommendedpeer) VALUES ('cleverman', 'perfectgirl');
INSERT INTO recommendations(peer, recommendedpeer) VALUES ('loretath', 'hzkto');
INSERT INTO recommendations(peer, recommendedpeer) VALUES ('perfectgirl', 'ghostgar');

-- FRIENDS TABLE
INSERT INTO friends(peer1, peer2) VALUES ('ghostgar', 'loretath');
INSERT INTO friends(peer1, peer2) VALUES ('hzkto', 'cleverman');
INSERT INTO friends(peer1, peer2) VALUES ('perfectgirl', 'ghostgar');
INSERT INTO friends(peer1, peer2) VALUES ('loretath', 'perfectgirl');
INSERT INTO friends(peer1, peer2) VALUES ('cleverman', 'loretath');

-- CHECKS TABLE
INSERT INTO checks(peer, task, date) VALUES ('loretath', 'C2_s21_stringplus', '2023-05-21');
INSERT INTO checks(peer, task, date) VALUES ('ghostgar', 'C2_s21_stringplus', '2023-04-05');
INSERT INTO checks(peer, task, date) VALUES ('cleverman', 'C2_s21_stringplus', '2023-01-05');
INSERT INTO checks(peer, task, date) VALUES ('cleverman', 'C3_s21_SimpleBashUtils', '2023-02-05');
INSERT INTO checks(peer, task, date) VALUES ('perfectgirl', 'C2_s21_stringplus', '2023-09-05');
INSERT INTO checks(peer, task, date) VALUES ('cleverman', 'C4_s21_math', '2023-03-13');
INSERT INTO checks(peer, task, date) VALUES ('hzkto', 'C2_s21_stringplus', '2022-12-21');
INSERT INTO checks(peer, task, date) VALUES ('loretath', 'C3_s21_SimpleBashUtils', '2023-06-15');
INSERT INTO checks(peer, task, date) VALUES ('loretath', 'C4_s21_math', '2023-06-18');
INSERT INTO checks(peer, task, date) VALUES ('ghostgar', 'C3_s21_SimpleBashUtils', '2023-05-10');
INSERT INTO checks(peer, task, date) VALUES ('ghostgar', 'C4_s21_math', '2023-07-13');
INSERT INTO checks(peer, task, date) VALUES ('cleverman', 'C6_s21_matrix', '2023-08-20');
INSERT INTO checks(peer, task, date) VALUES ('perfectgirl', 'C3_s21_SimpleBashUtils', '2023-10-10');

-- P2P TABLE
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (1, 'loretath', 'Start', '10:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (1, 'loretath', 'Success', '11:00');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (2, 'ghostgar', 'Start', '13:50');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (2, 'ghostgar', 'Failure', '14:20');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (2, 'ghostgar', 'Start', '14:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (2, 'ghostgar', 'Success', '15:00');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (3, 'cleverman', 'Start', '14:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (3, 'cleverman', 'Success', '15:00');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (4, 'cleverman', 'Start', '18:00');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (4, 'cleverman', 'Success', '18:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (5, 'perfectgirl', 'Start', '15:50');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (5, 'perfectgirl', 'Success', '16:20');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (5, 'perfectgirl', 'Start', '16:50');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (5, 'perfectgirl', 'Success', '17:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (6, 'cleverman', 'Start', '15:25');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (6, 'cleverman', 'Failure', '16:25');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (6, 'cleverman', 'Start', '16:45');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (6, 'cleverman', 'Success', '17:45');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (6, 'cleverman', 'Start', '18:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (6, 'cleverman', 'Success', '19:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (7, 'hzkto', 'Start', '10:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (7, 'hzkto', 'Failure', '11:00');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (8, 'loretath', 'Start', '14:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (8, 'loretath', 'Success', '15:00');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (9, 'loretath', 'Start', '11:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (9, 'loretath', 'Success', '12:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (9, 'loretath', 'Start', '14:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (9, 'loretath', 'Success', '15:30');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (10, 'ghostgar', 'Start', '16:23');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (10, 'ghostgar', 'Success', '17:00');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (11, 'ghostgar', 'Start', '13:19');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (11, 'ghostgar', 'Failure', '14:00');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (12, 'cleverman', 'Start', '12:45');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (12, 'cleverman', 'Success', '13:45');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (12, 'cleverman', 'Start', '16:45');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (12, 'cleverman', 'Success', '17:45');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (13, 'perfectgirl', 'Start', '20:10');
INSERT INTO P2P("Check", checkingpeer, state, time) VALUES (13, 'perfectgirl', 'Failure', '20:55');

-- VERTER TABLE
INSERT INTO verter("Check", state, time) VALUES (1, 'Start', '11:10');
INSERT INTO verter("Check", state, time) VALUES (1, 'Success', '11:15');
INSERT INTO verter("Check", state, time) VALUES (2, 'Start', '15:10');
INSERT INTO verter("Check", state, time) VALUES (2, 'Success', '15:15');
INSERT INTO verter("Check", state, time) VALUES (3, 'Start', '15:20');
INSERT INTO verter("Check", state, time) VALUES (3, 'Success', '15:30');
INSERT INTO verter("Check", state, time) VALUES (4, 'Start', '15:20');
INSERT INTO verter("Check", state, time) VALUES (4, 'Success', '15:30');
INSERT INTO verter("Check", state, time) VALUES (5, 'Start', '16:30');
INSERT INTO verter("Check", state, time) VALUES (5, 'Failure', '16:40');
INSERT INTO verter("Check", state, time) VALUES (5, 'Start', '17:35');
INSERT INTO verter("Check", state, time) VALUES (5, 'Success', '17:45');
INSERT INTO verter("Check", state, time) VALUES (6, 'Start', '17:50');
INSERT INTO verter("Check", state, time) VALUES (6, 'Failure', '18:00');
INSERT INTO verter("Check", state, time) VALUES (6, 'Start', '19:35');
INSERT INTO verter("Check", state, time) VALUES (6, 'Success', '19:45');
INSERT INTO verter("Check", state, time) VALUES (8, 'Start', '15:10');
INSERT INTO verter("Check", state, time) VALUES (8, 'Success', '15:15');
INSERT INTO verter("Check", state, time) VALUES (9, 'Start', '12:35');
INSERT INTO verter("Check", state, time) VALUES (9, 'Failure', '13:00');
INSERT INTO verter("Check", state, time) VALUES (9, 'Start', '15:35');
INSERT INTO verter("Check", state, time) VALUES (9, 'Success', '15:55');
INSERT INTO verter("Check", state, time) VALUES (10, 'Start', '17:05');
INSERT INTO verter("Check", state, time) VALUES (10, 'Success', '17:15');
INSERT INTO verter("Check", state, time) VALUES (12, 'Start', '14:05');
INSERT INTO verter("Check", state, time) VALUES (12, 'Failure', '14:25');
INSERT INTO verter("Check", state, time) VALUES (12, 'Start', '17:55');
INSERT INTO verter("Check", state, time) VALUES (12, 'Success', '18:15');

-- XP TABLE
INSERT INTO xp("Check", xpamount) VALUES (1, 500);
INSERT INTO xp("Check", xpamount) VALUES (2, 500);
INSERT INTO xp("Check", xpamount) VALUES (3, 500);
INSERT INTO xp("Check", xpamount) VALUES (4, 250);
INSERT INTO xp("Check", xpamount) VALUES (5, 500);
INSERT INTO xp("Check", xpamount) VALUES (6, 300);
INSERT INTO xp("Check", xpamount) VALUES (8, 250);
INSERT INTO xp("Check", xpamount) VALUES (9, 300);
INSERT INTO xp("Check", xpamount) VALUES (10, 250);
INSERT INTO xp("Check", xpamount) VALUES (12, 200);

-- TRANSFEREDPOINTS TABLE
INSERT INTO transferredpoints(checkingpeer, checkedpeer, pointsamount) VALUES ('ghostgar', 'loretath', 5);
INSERT INTO transferredpoints(checkingpeer, checkedpeer, pointsamount) VALUES ('loretath', 'ghostgar', 4);
INSERT INTO transferredpoints(checkingpeer, checkedpeer, pointsamount) VALUES ('cleverman', 'perfectgirl', 3);
INSERT INTO transferredpoints(checkingpeer, checkedpeer, pointsamount) VALUES ('perfectgirl', 'cleverman', 2);
INSERT INTO transferredpoints(checkingpeer, checkedpeer, pointsamount) VALUES ('hzkto', 'cleverman', 1);
INSERT INTO transferredpoints(checkingpeer, checkedpeer, pointsamount) VALUES ('cleverman', 'loretath', 6);
INSERT INTO transferredpoints(checkingpeer, checkedpeer, pointsamount) VALUES ('ghostgar', 'cleverman', 3);
INSERT INTO transferredpoints(checkingpeer, checkedpeer, pointsamount) VALUES ('perfectgirl', 'loretath', 4);
INSERT INTO transferredpoints(checkingpeer, checkedpeer, pointsamount) VALUES ('loretath', 'cleverman', 4);

-- END OF INSERTS

-- CSV EXPORT 
DROP PROCEDURE IF EXISTS export() CASCADE;

CREATE OR REPLACE PROCEDURE export(IN tablename varchar, IN path text, IN separator char) AS $$
    BEGIN
        EXECUTE format('COPY %s TO ''%s'' DELIMITER ''%s'' CSV HEADER;',
            tablename, path, separator);
    END;
$$ LANGUAGE plpgsql;

CALL export('peers', '/Users/ghostgar/goinfre/peers.csv', ',');
CALL export('tasks', '/Users/ghostgar/goinfre/tasks.csv', ',');
CALL export('checks', '/Users/ghostgar/goinfre/checks.csv', ',');
CALL export('p2p', '/Users/ghostgar/goinfre/p2p.csv', ',');
CALL export('verter', '/Users/ghostgar/goinfre/verter.csv', ',');
CALL export('transfered_points', '/Users/ghostgar/goinfre/transferred_points.csv', ',');
CALL export('friends', '/Users/ghostgar/goinfre/friends.csv', ',');
CALL export('recommendations', '/Users/ghostgar/goinfre/recommendations.csv', ',');
CALL export('xp', '/Users/ghostgar/goinfre/xp.csv', ',');
CALL export('time_tracking', '/Users/ghostgar/goinfre/time_tracking.csv', ',');

TRUNCATE TABLE peers CASCADE;
TRUNCATE TABLE tasks CASCADE;
TRUNCATE TABLE checks CASCADE;
TRUNCATE TABLE p2p CASCADE;
TRUNCATE TABLE verter CASCADE;
TRUNCATE TABLE transferred_points CASCADE;
TRUNCATE TABLE friends CASCADE;
TRUNCATE TABLE recommendations CASCADE;
TRUNCATE TABLE xp CASCADE;
TRUNCATE TABLE time_tracking CASCADE;

-- CSV IMPORT
DROP PROCEDURE IF EXISTS import() CASCADE;

CREATE OR REPLACE PROCEDURE import(IN tablename varchar, IN path text, IN separator char) AS $$
    BEGIN
        EXECUTE format('COPY %s FROM ''%s'' DELIMITER ''%s'' CSV HEADER;',
            tablename, path, separator);
    END;
$$ LANGUAGE plpgsql;

CALL import('peers', '/Users/ghostgar/goinfre/peers.csv', ',');
CALL import('tasks', '/Users/ghostgar/goinfre/tasks.csv', ',');
CALL import('checks', '/Users/ghostgar/goinfre/checks.csv', ',');
CALL import('p2p', '/Users/ghostgar/goinfre/p2p.csv', ',');
CALL import('verter', '/Users/ghostgar/goinfre/verter.csv', ',');
CALL import('transfered_points', '/Users/ghostgar/goinfre/transferred_points.csv', ',');
CALL import('friends', '/Users/ghostgar/goinfre/friends.csv', ',');
CALL import('recommendations', '/Users/ghostgar/goinfre/recommendations.csv', ',');
CALL import('xp', '/Users/ghostgar/goinfre/xp.csv', ',');
CALL import('time_tracking', '/Users/ghostgar/goinfre/time_tracking.csv', ',');