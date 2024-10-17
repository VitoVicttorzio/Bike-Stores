create database Bike_Stores;

# create table customers 

create table if not exists customers (
customer_id int auto_increment,
first_name varchar(30) not null,
last_name varchar(30) not null,
phone varchar(40),
email varchar(50) not null,
street varchar(50),
city varchar(35),
state varchar(2),
zip_code int,
primary key(customer_id)
);

-- load data in the table customers

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\customers.csv'
into table customers
fields terminated by ';'
lines terminated by '\n'
ignore 1 rows;


# create table stores

create table if not exists stores(
store_id int auto_increment,
store_name varchar(40) not null,
phone varchar(30) not null,
email varchar(50) not null,
street varchar(50),
city varchar(30),
state varchar(2),
zip_code int,
primary key(store_id)
);

-- load data in the table stores

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\stores.csv'
into table stores
fields terminated by ';'
lines terminated by '\n'
ignore 1 rows;


# create table staffs 

create table if not exists staffs(
 staff_id int auto_increment,
 first_name varchar(30) not null,
 last_name varchar(30) not null,
 email varchar(50) not null unique,
 phone varchar(30),
 actives int not null,
 store_id int not null,
 manager_id int,
 primary key(staff_id),
 constraint fk_manager_id  foreign key (manager_id) references staffs(staff_id) on delete set null,
 constraint fk_staff_store_id foreign key (store_id) references stores(store_id) on delete cascade on update cascade
 );
 
 
# create table orders 

Create table if not exists orders (
order_id int auto_increment,
customer_id int,
order_status int,
order_date date not null,
required_date date,
shipped_date date,
store_id int not null,
staff_id int not null,
primary key(order_id),
constraint fk_orders_customer_id foreign key (customer_id) references customers(customer_id) on delete cascade on update cascade,
constraint fk_orders_staff_id foreign key (staff_id) references staffs(staff_id) on delete cascade on update cascade,
constraint fk_orders_store foreign key (store_id) references stores(store_id) on delete cascade on update cascade
);

-- load data in the table orders

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\orders.csv' 
into table orders
fields terminated by ';'
lines terminated by '\n'
ignore 1 rows;


# create table categories

Create table if not exists categories(
category_id int auto_increment,
category_name varchar(40) not null,
primary key(category_id)
);


# create table brands

Create table if not exists brands(
brand_id int auto_increment,
brand_name varchar(40) not null,
primary key (brand_id)
);


# create table products

Create table if not exists products(
product_id int auto_increment,
product_name varchar(80) not null,
brand_id int not null,
category_id int not null,
model_year int not null,
list_price decimal (10,2) not null,
primary key (product_id),
constraint fk_product_product_id foreign key (category_id) references categories(category_id) on delete cascade on update cascade,
constraint fk_product_brand_id foreign key (brand_id) references brands(brand_id) on delete cascade on update cascade
);

-- load data in the table products 

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\products.csv' 
into table products
fields terminated by ';'
lines terminated by '\n'
ignore 1 rows;


# create table orders_items
 
Create table if not exists order_items (
order_id int,
item_id int,
product_id int not null,
quantity int not null,
list_price decimal(10,2) not null,
discount decimal(3,2) not null default 0,
primary key(order_id, item_id),
constraint fk_order_items_order_id foreign key (order_id) references orders(order_id) on delete cascade on update cascade,
constraint fk_order_items_prodict_id foreign key (product_id) references products(product_id) on delete cascade on update cascade
);


--  load data in the table order_items

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\order_items.csv' 
replace
into table order_items
fields terminated by ';'
lines terminated by '\n'
ignore 1 rows;


# create table stocks

Create table if not exists stocks(
store_id int,
product_id int,
quantity int not null,
primary key(store_id, product_id),
constraint fk_stocks_store_id foreign key (store_id) references stores(store_id) on delete cascade on update cascade,
constraint fk_stocks_product_id foreign key (product_id) references products(product_id) on delete cascade on update cascade
);

--  load data in the table stocks

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\stocks.csv' 
replace
into table stocks
fields terminated BY ';'
lines terminated by '\n'
ignore 1 rows;