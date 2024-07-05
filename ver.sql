 --основные таблицы

CREATE TABLE iorder (
  id BIGINT NOT NULL PRIMARY KEY,
  priority INT,
  cost FLOAT, 
  deadline DATE,
  start_date DATE
  
);
CREATE TABLE plan (
  id BIGINT NOT NULL PRIMARY KEY,
  start_date DATE,
  deadline DATE
  
);

CREATE TABLE commodity (
  id BIGINT NOT NULL PRIMARY KEY,
  name VARCHAR NOT NULL
  
);

CREATE TABLE workers (
  id BIGINT NOT NULL PRIMARY KEY,
  amount BIGINT,
  rank VARCHAR,
  profession VARCHAR
);

CREATE TABLE machines (
  id BIGINT NOT NULL PRIMARY KEY,
  type VARCHAR,
  name VARCHAR,
  amount BIGINT
);
CREATE TABLE operations (
  id BIGINT NOT NULL PRIMARY KEY,
  long TIME,
  type VARCHAR,
  cost REAL,
  name VARCHAR
);

CREATE TABLE item (
  id BIGINT NOT NULL PRIMARY KEY,
  name VARCHAR
);
--связующие таблицы

CREATE TABLE iorder_commodity (
  amount BIGINT NOT NULL,
  order_id BIGINT NOT NULL,
  commodity_id BIGINT NOT NULL,

  CONSTRAINT order_id_fk FOREIGN KEY (order_id) REFERENCES iorder (id),
  CONSTRAINT commodity_id_fk FOREIGN KEY (commodity_id) REFERENCES commodity (id)
);

CREATE TABLE plan_commodity (
  amount BIGINT NOT NULL,

  plan_id BIGINT NOT NULL,
  commodity_id BIGINT NOT NULL,

  CONSTRAINT plan_id_fk FOREIGN KEY (plan_id) REFERENCES plan (id),
  CONSTRAINT commodity_id_fk FOREIGN KEY (commodity_id) REFERENCES commodity (id)
);


CREATE TABLE workers_machines (

  workers_id BIGINT NOT NULL,
  machines_id BIGINT NOT NULL,

  CONSTRAINT workers_id_fk FOREIGN KEY (workers_id) REFERENCES workers (id),
  CONSTRAINT machines_id_fk FOREIGN KEY (machines_id) REFERENCES machines (id)
);

CREATE TABLE plan_item (
  amount BIGINT NOT NULL,

  plan_id BIGINT NOT NULL,
  item_id BIGINT NOT NULL,

  CONSTRAINT plan_id_fk FOREIGN KEY (plan_id) REFERENCES plan (id),
  CONSTRAINT item_id_fk FOREIGN KEY (item_id) REFERENCES item (id)
);

CREATE TABLE operations_item (
  amount BIGINT NOT NULL,

  operations_id BIGINT NOT NULL,
  item_id BIGINT NOT NULL,

  CONSTRAINT operations_id_fk FOREIGN KEY (operations_id) REFERENCES operations (id),
  CONSTRAINT item_id_fk FOREIGN KEY (item_id) REFERENCES item (id)
);
