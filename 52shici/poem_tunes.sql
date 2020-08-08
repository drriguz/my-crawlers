create table poem_tune(
    id integer not null primary key autoincrement,
    collection_id integer not null,
    name text not null,
    description text
);

create table poem_tune_form(
    id integer not null primary key autoincrement,
    poem_tune_id integer not null,
    author text,
    style text,
    template text not null,
    tips text,
    description text
);

delete from poem_tune;
delete from poem_tune_form;