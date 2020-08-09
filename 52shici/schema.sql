CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE poem_tune(
    id integer not null primary key autoincrement,
    collection_id integer not null,
    name text not null,
    description text
);
CREATE TABLE poem_tune_form(
    id integer not null primary key autoincrement,
    poem_tune_id integer not null,
    author text,
    style text,
    template text not null,
    tips text,
    description text
);
