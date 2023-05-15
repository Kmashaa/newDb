--task 1
alter session set "_ORACLE_SCRIPT"=true;

CREATE TABLE PASSPORT(
PASSPORT_ID NUMBER PRIMARY KEY,
SERIES VARCHAR2(5) NOT NULL,
NUM VARCHAR2(20) NOT NULL,
ISSUE_DATA DATE NOT NULL
);

CREATE TABLE GROUPS(
GROUP_ID NUMBER,
NAME VARCHAR2(50),
C_VAL NUMBER,
CONSTRAINT GROUPS_PK PRIMARY KEY(GROUP_ID)
);

CREATE TABLE STUDENTS(
STUDENT_ID NUMBER,
NAME VARCHAR2(50),
GROUP_ID NUMBER,
PASSPORT_ID NUMBER,
CONSTRAINT STUDENTS_PK PRIMARY KEY (STUDENT_ID),
CONSTRAINT FK_STUDENTS_GROUPS FOREIGN KEY(GROUP_ID)
REFERENCES GROUPS(GROUP_ID),
CONSTRAINT FK_STUDENTS_PASSPORT FOREIGN KEY(PASSPORT_ID)
REFERENCES PASSPORT(PASSPORT_ID)
);

--task 2
CREATE TABLE HISTORY(
HISTORY_ID NUMBER GENERATED ALWAYS AS IDENTITY,
NEW_PASSPORT_ID NUMBER,
OLD_PASSPORT_ID NUMBER,
SERIES VARCHAR2(5),
NUM VARCHAR2(20),
ISSUE_DATA DATE,
NEW_GROUP_ID NUMBER,
OLD_GROUP_ID NUMBER,
NAME VARCHAR2(50),
C_VAL NUMBER,
NEW_STUDENT_ID NUMBER,
OLD_STUDENT_ID NUMBER,
STUDENT_GROUP_ID NUMBER,
STUDENT_PASSPORT_ID NUMBER,
OPERATION VARCHAR2(6) NOT NULL CHECK(OPERATION IN ('insert', 'update', 'delete')),
OP_DATE DATE NOT NULL,
CONSTRAINT HISTORY_PK PRIMARY KEY(HISTORY_ID)
);

CREATE OR REPLACE TRIGGER save_passport_history_trigger
AFTER INSERT OR UPDATE OR delete
ON PASSPORT
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO HISTORY(NEW_PASSPORT_ID, SERIES, NUM, ISSUE_DATA, OPERATION, OP_DATE)
        VALUES(:NEW.PASSPORT_ID, :NEW.SERIES, :NEW.NUM, :NEW.ISSUE_DATA, 'insert', SYSDATE);
    ELSIF UPDATING THEN
        INSERT INTO HISTORY(OLD_PASSPORT_ID, NEW_PASSPORT_ID, SERIES, NUM, ISSUE_DATA, OPERATION, OP_DATE)
        VALUES(:OLD.PASSPORT_ID, :NEW.PASSPORT_ID, :OLD.SERIES, :OLD.NUM, :OLD.ISSUE_DATA, 'update', SYSDATE);
    ELSIF DELETING THEN
        INSERT INTO HISTORY(OLD_PASSPORT_ID, SERIES, NUM, ISSUE_DATA, OPERATION, OP_DATE)
        VALUES(:OLD.PASSPORT_ID, :OLD.SERIES, :OLD.NUM, :OLD.ISSUE_DATA, 'delete', SYSDATE);
    END IF;
END save_passport_history_trigger;

CREATE OR REPLACE TRIGGER save_groups_history_trigger
AFTER INSERT OR UPDATE OR delete
ON GROUPS
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO HISTORY(NEW_GROUP_ID, NAME, C_VAL, OPERATION, OP_DATE)
        VALUES(:NEW.GROUP_ID, :NEW.NAME, :NEW.C_VAL, 'insert', SYSDATE);
    ELSIF UPDATING THEN
        INSERT INTO HISTORY(OLD_GROUP_ID, NEW_GROUP_ID, NAME, C_VAL, OPERATION, OP_DATE)
        VALUES(:OLD.GROUP_ID, :NEW.GROUP_ID, :OLD.NAME, :OLD.C_VAL, 'update', SYSDATE);
    ELSIF DELETING THEN
        INSERT INTO HISTORY(OLD_GROUP_ID, NAME, C_VAL, OPERATION, OP_DATE)
        VALUES(:OLD.GROUP_ID, :OLD.NAME, :OLD.C_VAL, 'delete', SYSDATE);
    END IF;
END save_groups_history_trigger;

CREATE OR REPLACE TRIGGER save_students_history_trigger
AFTER INSERT OR UPDATE OR delete
ON STUDENTS
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO HISTORY(NEW_STUDENT_ID, NAME, STUDENT_GROUP_ID, STUDENT_PASSPORT_ID, OPERATION, OP_DATE)
        VALUES(:NEW.STUDENT_ID, :NEW.NAME, :NEW.GROUP_ID, :NEW.PASSPORT_ID, 'insert', SYSDATE);
    ELSIF UPDATING THEN
        INSERT INTO HISTORY(OLD_STUDENT_ID, NEW_STUDENT_ID, NAME, STUDENT_GROUP_ID, STUDENT_PASSPORT_ID, OPERATION, OP_DATE)
        VALUES(:OLD.STUDENT_ID, :NEW.STUDENT_ID, :OLD.NAME, :OLD.GROUP_ID, :OLD.PASSPORT_ID, 'update', SYSDATE);
    ELSIF DELETING THEN
        INSERT INTO HISTORY(OLD_STUDENT_ID, NAME, STUDENT_GROUP_ID, STUDENT_PASSPORT_ID, OPERATION, OP_DATE)
        VALUES(:OLD.STUDENT_ID, :OLD.NAME, :OLD.GROUP_ID, :OLD.PASSPORT_ID, 'delete', SYSDATE);
    END IF;
END save_students_history_trigger;

--task 3

-- Отключаем нужные триггеры.
ALTER TRIGGER save_passport_history_trigger DISABLE;
ALTER TRIGGER save_groups_history_trigger DISABLE;
ALTER TRIGGER save_students_history_trigger DISABLE;


-- Включаем нужные триггеры.
ALTER TRIGGER save_passport_history_trigger ENABLE;
ALTER TRIGGER save_groups_history_trigger ENABLE;
ALTER TRIGGER save_students_history_trigger ENABLE;

CREATE OR REPLACE PACKAGE restore_by_history AS
PROCEDURE restore(desired_date IN DATE);
PROCEDURE restore(desired_period NUMBER);
END restore_by_history;

CREATE OR REPLACE PACKAGE BODY restore_by_history AS
    PROCEDURE restore_passport(rec IN HISTORY%ROWTYPE)
    IS
    BEGIN
        IF rec.OPERATION = 'insert' THEN
            DELETE FROM PASSPORT WHERE PASSPORT_ID = rec.NEW_PASSPORT_ID;
        ELSIF rec.OPERATION = 'update' THEN
            UPDATE PASSPORT SET PASSPORT_ID = rec.OLD_PASSPORT_ID, SERIES = rec.SERIES, NUM = rec.NUM, ISSUE_DATA = rec.ISSUE_DATA
            WHERE PASSPORT_ID = rec.NEW_PASSPORT_ID;
        ELSIF rec.OPERATION = 'delete' THEN
            INSERT INTO PASSPORT(PASSPORT_ID, SERIES, NUM, ISSUE_DATA)
            VALUES (rec.OLD_PASSPORT_ID, rec.SERIES, rec.NUM, rec.ISSUE_DATA);
        END IF;
    END restore_passport;


    PROCEDURE restore_groups(rec IN HISTORY%ROWTYPE)
    IS
    BEGIN
        IF rec.OPERATION = 'insert' THEN
            DELETE FROM GROUPS WHERE GROUP_ID = rec.NEW_GROUP_ID;
        ELSIF rec.OPERATION = 'update' THEN
            UPDATE GROUPS SET GROUP_ID = rec.OLD_GROUP_ID, NAME = rec.NAME, C_VAL = rec.C_VAL
            WHERE GROUP_ID = rec.NEW_GROUP_ID;
        ELSIF rec.OPERATION = 'delete' THEN
            INSERT INTO GROUPS(GROUP_ID, NAME, C_VAL)
            VALUES (rec.OLD_GROUP_ID, rec.NAME, rec.C_VAL);
        END IF;
    END restore_groups;


    PROCEDURE restore_students(rec IN HISTORY%ROWTYPE)
    IS
    BEGIN
        IF rec.OPERATION = 'insert' THEN
            DELETE FROM STUDENTS WHERE STUDENT_ID = rec.NEW_STUDENT_ID;
        ELSIF rec.OPERATION = 'update' THEN
            UPDATE STUDENTS SET STUDENT_ID = rec.OLD_STUDENT_ID, NAME = rec.NAME, GROUP_ID = rec.STUDENT_GROUP_ID, PASSPORT_ID = rec.STUDENT_PASSPORT_ID
            WHERE STUDENT_ID = rec.NEW_STUDENT_ID;
        ELSIF rec.OPERATION = 'delete' THEN
            INSERT INTO STUDENTS(STUDENT_ID, NAME, GROUP_ID, PASSPORT_ID)
            VALUES (rec.OLD_STUDENT_ID, rec.NAME, rec.STUDENT_GROUP_ID, rec.STUDENT_PASSPORT_ID);
        END IF;
    END restore_students;


    PROCEDURE restore(desired_date IN DATE)
    IS
        CURSOR get_history(hist_date HISTORY.OP_DATE%TYPE) IS
            SELECT * FROM HISTORY
            WHERE op_date >= hist_date
            ORDER BY history_id DESC;
    BEGIN
        FOR rec IN get_history(desired_date) LOOP
            IF rec.NEW_PASSPORT_ID IS NOT NULL OR rec.OLD_PASSPORT_ID IS NOT NULL THEN
                restore_passport(rec);
            ELSIF rec.NEW_GROUP_ID IS NOT NULL OR rec.OLD_GROUP_ID IS NOT NULL THEN
                restore_groups(rec);
            ELSIF rec.NEW_STUDENT_ID IS NOT NULL OR rec.OLD_STUDENT_ID IS NOT NULL THEN
                restore_students(rec);
            END IF;
        END LOOP;

        DELETE FROM HISTORY WHERE OP_DATE >= desired_date;
    END restore;

    PROCEDURE restore(desired_period NUMBER)
    IS
    BEGIN
        restore(SYSDATE - NUMTODSINTERVAL(desired_period / 1000, 'SECOND'));
    END restore;
END restore_by_history;

    SELECT HISTORY_ID, OPERATION, TO_CHAR(OP_DATE, 'YYYY-MM-DD HH24:MI:SS') oper_date FROM HISTORY;

call restore_by_history.restore(TO_DATE('2023-05-05 14:12:56', 'YYYY-MM-DD HH24:MI:SS'));



--task 4

CREATE OR REPLACE DIRECTORY REPORT_DIR AS 'D:\DB\newDb\report';

call generate_report(TO_DATE('2023-04-25 22:17:12', 'YYYY-MM-DD HH24:MI:SS'));

CREATE OR REPLACE PROCEDURE generate_report(desired_date DATE)
IS
    file UTL_FILE.file_type;
    buff VARCHAR(1000);
    num_passport_insert NUMBER;
    num_passport_update NUMBER;
    num_passport_delete NUMBER;

    num_groups_insert NUMBER;
    num_groups_update NUMBER;
    num_groups_delete NUMBER;

    num_students_insert NUMBER;
    num_students_update NUMBER;
    num_students_delete NUMBER;
BEGIN
    file := UTL_FILE.fopen('REPORT_DIR', 'report.html', 'W');
    IF NOT UTL_FILE.IS_OPEN(file) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error in generate_report(). File ' || 'report.html' || ' does not open!');
    END IF;

    buff := HTF.HTMLOPEN || CHR(10) || HTF.headopen || CHR(10) || HTF.title('Report')
            || CHR(10) || HTF.headclose || CHR(10) ||HTF.bodyopen || CHR(10);

    SELECT COUNT(*) INTO num_passport_insert FROM HISTORY
    WHERE (NEW_PASSPORT_ID IS NOT NULL OR OLD_PASSPORT_ID IS NOT NULL) AND OPERATION = 'insert' AND OP_DATE >= desired_date;

    SELECT COUNT(*) INTO num_passport_update FROM HISTORY
    WHERE (NEW_PASSPORT_ID IS NOT NULL OR OLD_PASSPORT_ID IS NOT NULL) AND OPERATION = 'update' AND OP_DATE >= desired_date;

    SELECT COUNT(*) INTO num_passport_delete FROM HISTORY
    WHERE (NEW_PASSPORT_ID IS NOT NULL OR OLD_PASSPORT_ID IS NOT NULL) AND OPERATION = 'delete' AND OP_DATE >= desired_date;


    SELECT COUNT(*) INTO num_groups_insert FROM HISTORY
    WHERE (NEW_GROUP_ID IS NOT NULL OR OLD_GROUP_ID IS NOT NULL) AND OPERATION = 'insert' AND OP_DATE >= desired_date;

    SELECT COUNT(*) INTO num_groups_update FROM HISTORY
    WHERE (NEW_GROUP_ID IS NOT NULL OR OLD_GROUP_ID IS NOT NULL) AND OPERATION = 'update' AND OP_DATE >= desired_date;

    SELECT COUNT(*) INTO num_groups_delete FROM HISTORY
    WHERE (NEW_GROUP_ID IS NOT NULL OR OLD_GROUP_ID IS NOT NULL) AND OPERATION = 'delete' AND OP_DATE >= desired_date;


    SELECT COUNT(*) INTO num_students_insert FROM HISTORY
    WHERE (NEW_STUDENT_ID IS NOT NULL OR OLD_STUDENT_ID IS NOT NULL) AND OPERATION = 'insert' AND OP_DATE >= desired_date;

    SELECT COUNT(*) INTO num_students_update FROM HISTORY
    WHERE (NEW_STUDENT_ID IS NOT NULL OR OLD_STUDENT_ID IS NOT NULL) AND OPERATION = 'update' AND OP_DATE >= desired_date;

    SELECT COUNT(*) INTO num_students_delete FROM HISTORY
    WHERE (NEW_STUDENT_ID IS NOT NULL OR OLD_STUDENT_ID IS NOT NULL) AND OPERATION = 'delete' AND OP_DATE >= desired_date;


    buff := buff || HTF.TABLEOPEN || CHR(10) || HTF.TABLEROWOPEN || CHR(10) || HTF.TABLEHEADER('') || CHR(10) || HTF.TABLEHEADER('Passport') || CHR(10) ||
    HTF.TABLEHEADER('Groups') || CHR(10) || HTF.TABLEHEADER('Students') || CHR(10) || HTF.TABLEROWCLOSE || CHR(10);

    buff := buff || HTF.TABLEROWOPEN || CHR(10) || HTF.TABLEHEADER('insert') || CHR(10) || HTF.TABLEDATA(num_passport_insert) || CHR(10) ||
    HTF.TABLEDATA(num_groups_insert) || CHR(10) || HTF.TABLEDATA(num_students_insert) || CHR(10) || HTF.TABLEROWCLOSE || CHR(10);

    buff := buff || HTF.TABLEROWOPEN || CHR(10) || HTF.TABLEHEADER('update') || CHR(10) || HTF.TABLEDATA(num_passport_update) || CHR(10) ||
    HTF.TABLEDATA(num_groups_update) || CHR(10) || HTF.TABLEDATA(num_students_update) || CHR(10) || HTF.TABLEROWCLOSE || CHR(10);

    buff := buff || HTF.TABLEROWOPEN || CHR(10) || HTF.TABLEHEADER('delete') || CHR(10) || HTF.TABLEDATA(num_passport_delete) || CHR(10) ||
    HTF.TABLEDATA(num_groups_delete) || CHR(10) || HTF.TABLEDATA(num_students_delete) || CHR(10) || HTF.TABLEROWCLOSE || CHR(10);

    buff := buff || HTF.TABLECLOSE || CHR(10) || HTF.bodyclose || CHR(10) || HTF.htmlclose;

    UTL_FILE.put_line (file, buff);
    UTL_FILE.fclose(file);
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error in generate_report(). NO_DATA_FOUND');
END generate_report;


INSERT INTO PASSPORT(PASSPORT_ID, SERIES, NUM, ISSUE_DATA)
VALUES(0, 'HB', '1111111', sysdate);
;

UPDATE PASSPORT SET ISSUE_DATA = systimestamp WHERE PASSPORT_ID = 1;

DELETE FROM PASSPORT WHERE PASSPORT_ID = 0;


INSERT INTO GROUPS(GROUP_ID, NAME, C_VAL)
VALUES(0, '053502', 1);

UPDATE GROUPS SET C_VAL = 5 WHERE GROUP_ID = 0;

DELETE FROM GROUPS WHERE GROUP_ID = 0;


INSERT INTO STUDENTS(STUDENT_ID, NAME, GROUP_ID, PASSPORT_ID)
VALUES(1, 'Masha', 1, 1);

UPDATE STUDENTS SET NAME = 'Liza' WHERE STUDENT_ID = 1;

DELETE FROM STUDENTS WHERE STUDENT_ID = 1;

-- Выкл триггеры.
ALTER TRIGGER save_passport_history_trigger DISABLE;
ALTER TRIGGER save_groups_history_trigger DISABLE;
ALTER TRIGGER save_students_history_trigger DISABLE;


-- Вкл триггеры.
ALTER TRIGGER save_passport_history_trigger ENABLE;
ALTER TRIGGER save_groups_history_trigger ENABLE;
ALTER TRIGGER save_students_history_trigger ENABLE;

call restore_by_history.restore(TO_DATE('2023-05-05 15:00:12', 'YYYY-MM-DD HH24:MI:SS'));
call restore_by_history.restore(42000);
call generate_report(TO_DATE('2023-05-05 15:18:00', 'YYYY-MM-DD HH24:MI:SS'));
