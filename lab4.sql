alter session set "_ORACLE_SCRIPT"=true;

CREATE OR REPLACE DIRECTORY TASK_DIR AS 'D:\DB\newDb\DBMS_JSON_FILES';


CREATE OR REPLACE PACKAGE json_parser AS
    FUNCTION parse_all_or_distinct(json_select IN JSON_OBJECT_T) RETURN VARCHAR2;
    FUNCTION parse_select(json_select IN JSON_OBJECT_T) RETURN VARCHAR2;
    FUNCTION parse_json(json_str IN VARCHAR2) RETURN VARCHAR2;
        FUNCTION parse_cols(json_cols IN JSON_ARRAY_T, tab_name IN VARCHAR2) RETURN VARCHAR2;
        FUNCTION parse_tables(json_tables IN JSON_ARRAY_T) RETURN VARCHAR2;
    FUNCTION read(dir VARCHAR2, fname VARCHAR2) RETURN VARCHAR2;
END json_parser;

CREATE OR REPLACE PACKAGE BODY json_parser AS


    FUNCTION parse_select(json_select IN JSON_OBJECT_T) RETURN VARCHAR2
    IS
        buff VARCHAR2(10000);
    BEGIN
        buff := 'SELECT ';
        IF json_select.has('all_or_distinct') THEN
            buff := buff || parse_all_or_distinct(json_select);
        END IF;

        IF NOT json_select.has('tables') THEN
            RAISE_APPLICATION_ERROR(-20003, 'Error in parse_select(). There is not "tables" section');
        END IF;

        buff := buff || ' ' || parse_tables(json_select.get_array('tables'));
        RETURN buff;
    END parse_select;

    FUNCTION parse_all_or_distinct(json_select IN JSON_OBJECT_T) RETURN VARCHAR2
    IS
    BEGIN
        IF UPPER(json_select.get_string('all_or_distinct')) = 'DISTINCT' THEN
            RETURN 'DISTINCT';
        END IF;
        RETURN NULL;
    END parse_all_or_distinct;

    FUNCTION parse_cols(json_cols IN JSON_ARRAY_T, tab_name IN VARCHAR2) RETURN VARCHAR2
    IS
        buff VARCHAR2(10000);
        col_obj JSON_OBJECT_T;
    BEGIN
        FOR i in 0..json_cols.get_size - 1 LOOP
            col_obj := TREAT(json_cols.get(i) AS JSON_OBJECT_T);
            IF NOT col_obj.has('col_name') THEN
                RAISE_APPLICATION_ERROR(-20005, 'Error in parse_cols(). There is not "col_name"');
            END IF;
            IF tab_name IS NOT NULL THEN
                buff := buff || tab_name || '.' || col_obj.get_string('col_name');
            ELSE
                buff := buff ||  col_obj.get_string('col_name');
            END IF;

            IF col_obj.has('as') THEN
                buff := buff || ' ' || col_obj.get_string('as');
            END IF;
            buff := buff || ', ';
        END LOOP;
        RETURN RTRIM(buff, ', ');
    END parse_cols;

    FUNCTION parse_tables(json_tables IN JSON_ARRAY_T) RETURN VARCHAR2
    IS
        buff VARCHAR2(10000);
        table_obj JSON_OBJECT_T;
        table_name VARCHAR2(100);
    BEGIN
        FOR i IN 0..json_tables.get_size - 1 LOOP
            buff := buff || CHR(10);
            table_obj := TREAT(json_tables.get(i) AS JSON_OBJECT_T);
            table_name := table_obj.get_string('table_name');
            buff := buff || parse_cols(table_obj.get_array('cols'), table_name) || ', ';
        END LOOP;
        RETURN RTRIM(buff, ', ');
    END parse_tables;



    FUNCTION read(dir VARCHAR2, fname VARCHAR2) RETURN VARCHAR2
    IS
        file UTL_FILE.FILE_TYPE;
        buff VARCHAR2(10000);
        str VARCHAR2(500);
    BEGIN
        file := UTL_FILE.FOPEN(dir, fname, 'R', 32767);
        IF NOT UTL_FILE.IS_OPEN(file) THEN
            DBMS_OUTPUT.PUT_LINE('File ' || fname || ' does not open!');
            RETURN NULL;
        END IF;

        LOOP
            BEGIN
                UTL_FILE.GET_LINE(file, str);
                buff := buff || str;

                EXCEPTION
                    WHEN OTHERS THEN EXIT;
            END;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(buff);
        UTL_FILE.FCLOSE(file);
        RETURN buff;
    END read;

        FUNCTION parse_json(json_str IN VARCHAR2) RETURN VARCHAR2
    IS
        json_obj JSON_OBJECT_T;
    BEGIN
        json_obj := JSON_OBJECT_T(json_str);
        IF json_obj IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Error in parse_json(). json_obj = NULL');
        ELSIF json_obj.has('select') THEN
            RETURN parse_select(json_obj.get_object('select')) || ';';
        END IF;

    END parse_json;
END json_parser;



SELECT json_parser.parse_json(json_parser.read('TASK_DIR', 'SelectJSON.json')) FROM dual;

SELECT json_parser.read('TASK_DIR', 'SelectJSON.json') FROM dual;

select * from session_privs;