--Task1
alter session set "_ORACLE_SCRIPT"=true;

create user development identified by development;
grant all privileges to development;
drop user development;

create user production identified by production;
grant all privileges to production;
drop user production;


create table development.MyTable
(
    id NUMBER GENERATED BY DEFAULT AS IDENTITY,
    val number,
    my_dev_table_id NUMBER,
    constraint mytable_pk primary key(id)
);

create table development.MyDevTable(
    id number generated by default as identity,
    val number,
    my_table_id number,
    constraint mydevtabel_pk primary key(id),
    constraint fk_my_table foreign key (my_table_id) references MYTABLE(id)
);

alter table DEVELOPMENT.MYTABLE add constraint fk_my_dev_table foreign key (my_dev_table_id ) references MYDEVTABLE(id);

create table PRODUCTION.MyTable
(
    id number generated by default as identity,
    val number,
    my_dev_table_id number,
    constraint mytable_pk primary key(id)
);

