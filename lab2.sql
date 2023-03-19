insert into STUDENTS (name,group_id) values ('masha',102);
delete from students;
delete from groups;
delete from loggs;
drop table STUDENTS;
drop table groups;
drop table loggs;
delete from groups where id = 102;
delete from students where id=189;
insert into students (id,name, group_id) VALUES (72,'dasha',1);
alter table students disable all triggers;
alter table students enable all triggers;
alter session set ddl_lock_timeout = 600;

insert into groups (name, c_val) VALUES ('c',0);
insert into groups (id,name, c_val) VALUES (10,'ssss',1);
truncate table students;





--1
create table STUDENTS
(
    id number,
    name varchar2(50),
    group_id number
);

create table GROUPS
(
    id number,
    name varchar2(50),
    c_val number
);
drop table groups;
drop table students;


--2
create sequence students_seq
start with 1
increment by 1
nomaxvalue;

create or replace trigger stuents_id_trg
before insert on students
for each row
begin
  if :new.id is null then
    select students_seq.nextval into :new.id from dual;
  end if;
end;

drop trigger stuents_id_trg;



create sequence groups_seq
start with 1
increment by 1
nomaxvalue;

create or replace trigger groups_id_trg
before insert on groups
for each row
begin
  if :new.id is null then
    select groups_seq.nextval into :new.id from dual;
  end if;
end;

drop trigger groups_id_trg;



drop trigger unique_id_stud_trg;

create or replace trigger unique_id_stud_trg
before insert
on students
for each row
declare
    idx number;
    ex exception ;
begin
        select id into idx from students where :new.id=id-- and rownum <=1;
        offset 0 rows fetch next 1 rows only;
        if(idx is not null) then
            raise_application_error(-20001, 'error: not unique id');
        end if;

        exception
        when no_data_found then
        idx := null;
end;


create or replace trigger unique_id_group_trg
before insert
on groups
for each row
declare
    idx number;
    idxx number;
begin

        select id into idxx from groups where :new.id=id and rownum <=1;
        if(idxx is not null) then
            raise_application_error(-20001, 'error: not unique id');
        end if;

        exception
        when no_data_found then
        idx := null;
end;



drop trigger unique_name_group_trg;

create or replace trigger unique_name_group_trg
before insert
on groups
for each row
declare
    idx number;
begin
        select id into idx from groups where :new.name=name and rownum <=1;
        if(idx is not null) then
            raise_application_error(-20001, 'error: not unique name');
        end if;

        exception
        when no_data_found then
        idx := null;

end;



--3
create or replace trigger groups_cascade_delete
before delete
on groups
for each row
begin
    delete from students where group_id = :old.id;
end groups_cascade_delete;

delete from groups where id=1;






--4
create table loggs(
    logg_id number generated by default as identity,
    student_id number,
    student_name varchar2(50),
    student_group_id number,
    operation varchar2(6) not null,
    date_of_action date not null,
    constraint loggs_pk primary key(logg_id)
);

drop table loggs;

drop trigger loggs_trg;

create or replace trigger loggs_trg
after insert or update or delete
on students
for each row
begin
    if inserting then
        insert into loggs(student_id, student_name, student_group_id, operation, date_of_action)
        values(:new.id, :new.name, :new.group_id, 'insert', sysdate);
    elsif updating then
        insert into loggs(student_id, student_name, student_group_id, operation, date_of_action)
        values(:old.id, :old.name, :old.group_id, 'update', sysdate);
    elsif deleting then
        insert into loggs(student_id, student_name, student_group_id, operation, date_of_action)
        values(:old.id, :old.name, :old.group_id, 'delete', sysdate);
    end if;

end loggs_trg;




delete from loggs;
delete from students;
delete from groups;
--5
alter table students disable all triggers;
alter table students enable all triggers;

delete from groups where id = 101;
alter table students disable all triggers;
call restore_table_students(to_date('2023-03-10 21:28:40', 'yyyy-mm-dd hh24:mi:ss'));
alter table students enable all triggers;


call restore_table_students_period(interval '0 0:2:2' day to second);

create or replace procedure restore_table_students(desired_date in date)
is
cursor get_history(hist_date loggs.date_of_action%type) is
select * from loggs
where date_of_action <= hist_date
order by logg_id asc;
begin
            DBMS_OUTPUT.PUT_LINE('start');
    delete from students;
    for hist in get_history(desired_date) loop
                    DBMS_OUTPUT.PUT_LINE('in');
        if(hist.operation = 'insert') then

                        DBMS_OUTPUT.PUT_LINE('inss');
            insert into students(id, name, group_id)
            values(hist.student_id, hist.student_name, hist.student_group_id);
            DBMS_OUTPUT.PUT_LINE('ins');
        end if;

        if(hist.operation = 'delete') then
            delete from students where id = hist.student_id;
            DBMS_OUTPUT.PUT_LINE('del');
        end if;

        if(hist.operation = 'update') then
            update students set id = hist.student_id, name = hist.student_name, group_id = hist.student_group_id
            where id = hist.student_id;
            DBMS_OUTPUT.PUT_LINE('upd');
        end if;
    end loop;
    delete from loggs where date_of_action >= desired_date;
end restore_table_students;


truncate table groups;


create or replace procedure restore_table_students_period(desired_period in interval day to second)
is
begin
    restore_table_students(sysdate - desired_period);
end restore_table_students_period;


--6
create or replace trigger update_c_val
before insert or update or delete
on students
for each row
declare
    idx number;
    PRAGMA AUTONOMOUS_TRANSACTION;
begin

    if inserting then
        select id into idx from groups where :new.group_id=id and rownum<=1;
        if (idx is not null) then
            update groups set c_val = c_val + 1 where id = :new.group_id;
        end if;
    elsif updating then
        begin
            select id into idx from groups where :old.group_id=id and rownum<=1;
        if (idx is not null) then
        update groups set c_val = c_val - 1 where id = :old.group_id;
        end if;
            select id into idx from groups where :new.group_id=id and rownum<=1;
        if (idx is not null) then
            update groups set c_val = c_val + 1 where id = :new.group_id;
        end if;
        end;
    elsif deleting then
        select id into idx from groups where :old.group_id=id and rownum<=1;
        if (idx is not null) then
        update groups set c_val = c_val - 1 where id = :old.group_id;
        end if;
    end if;
    commit;
end update_c_val;

delete from groups where id=43;
