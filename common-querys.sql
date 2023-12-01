-- بدست آوردن تعداد ستون‌ های موجود در دیتابیس
select [columns],
[tables],
CONVERT(DECIMAL(10,2),1.0*[columns]/[tables]) as average_column_count
from (
select count(*) [columns],
count(distinct schema_name(tab.schema_id) + tab.name) as [tables]
from sys.tables as tab
inner join sys.columns as col
on tab.object_id = col.object_id
)

-- بدست آوردن تعداد جداول یک دیتابیس
select count(*) as [tables]
from sys.tables

-- جستجوی جداول که دارای ستونی با نام مشخص نباشند
select schema_name(t.schema_id) as schema_name,
t.name as table_name
from sys.tables t
where t.object_id not in
(select c.object_id
from sys.columns c
where c.name = 'ModifiedDate')
order by schema_name,
table_name;

--  جستجوی جداول دارای ستونی با نام مشخص
select schema_name(t.schema_id) as schema_name,
t.name as table_name
from sys.tables t
where t.object_id in
(select c.object_id
from sys.columns c
where c.name = 'ProductID')
order by schema_name,
table_name;

-- جستجوی جداولی که در نامشان عدد وجود دارد
select schema_name(t.schema_id) as schema_name,
t.name as table_name
from sys.tables t
where t.name like '%[0-9]%'
order by schema_name,
table_name;

-- جستجوی جداول با عبارتی مشخص در نام
select schema_name(t.schema_id) as schema_name,
t.name as table_name
from sys.tables t
where t.name like '%product%'
order by table_name,
schema_name;

-- جستجوی جداول توسط نام با خاتمه عبارتی مشخص
select schema_name(t.schema_id) as schema_name,
t.name as table_name
from sys.tables t
where t.name like '%tab'
order by table_name,
schema_name;

-- جستجوی جداول توسط نام با شروع عبارتی مشخص
select schema_name(t.schema_id) as schema_name,
t.name as table_name
from sys.tables t
where t.name like 'hr%'
order by table_name,
schema_name;

-- جستجوی یک جدول توسط نام
select schema_name(t.schema_id) as schema_name,
t.name as table_name
from sys.tables t
where t.name = 'customer'
order by schema_name,
table_name;

-- لیست دیتابیس‌های دارای یک جدول خاص
select [name] as [database_name] from sys.databases
where
case when state_desc = 'ONLINE'
then object_id(quotename([name]) + '.[Person].[Address]', 'U')
end is not null
order by 1

-- پرکاربردترین Data Type ها در یک دیتابیس
select t.name as data_type,
count(*) as [columns],
cast(100.0 * count(*) /
(select count(*) from sys.tables tab inner join
sys.columns as col on tab.object_id = col.object_id)
as numeric(36, 1)) as percent_columns,
count(distinct tab.object_id) as [tables],
cast(100.0 * count(distinct tab.object_id) /
(select count(*) from sys.tables) as numeric(36, 1)) as percent_tables
from sys.tables as tab
inner join sys.columns as col
on tab.object_id = col.object_id
left join sys.types as t
on col.user_type_id = t.user_type_id
group by t.name
order by count(*) desc

-- لیست Unique Index های یک دیتابیس
select i.[name] as index_name,
substring(column_names, 1, len(column_names)-1) as [columns],
case when i.[type] = 1 then 'Clustered unique index'
when i.type = 2 then 'Unique index'
end as index_type,
schema_name(t.schema_id) + '.' + t.[name] as table_view,
case when t.[type] = 'U' then 'Table'
when t.[type] = 'V' then 'View'
end as [object_type],
case when c.[type] = 'PK' then 'Primary key'
when c.[type] = 'UQ' then 'Unique constraint'
end as constraint_type,
c.[name] as constraint_name
from sys.objects t
left outer join sys.indexes i
on t.object_id = i.object_id
left outer join sys.key_constraints c
on i.object_id = c.parent_object_id
and i.index_id = c.unique_index_id
cross apply (select col.[name] + ', '
from sys.index_columns ic
inner join sys.columns col
on ic.object_id = col.object_id
and ic.column_id = col.column_id
where ic.object_id = t.object_id
and ic.index_id = i.index_id
order by col.column_id
for xml path ('') ) D (column_names)
where is_unique = 1
and t.is_ms_shipped <> 1
order by i.[name]

-- لیست Index های جداول یک دیتابیس
select schema_name(t.schema_id) + '.' + t.[name] as table_view,
case when t.[type] = 'U' then 'Table'
when t.[type] = 'V' then 'View'
end as [object_type],
i.index_id,
case when i.is_primary_key = 1 then 'Primary key'
when i.is_unique = 1 then 'Unique'
else 'Not unique' end as [type],
i.[name] as index_name,
substring(column_names, 1, len(column_names)-1) as [columns],
case when i.[type] = 1 then 'Clustered index'
when i.[type] = 2 then 'Nonclustered unique index'
when i.[type] = 3 then 'XML index'
when i.[type] = 4 then 'Spatial index'
when i.[type] = 5 then 'Clustered columnstore index'
when i.[type] = 6 then 'Nonclustered columnstore index'
when i.[type] = 7 then 'Nonclustered hash index'
end as index_type
from sys.objects t
inner join sys.indexes i
on t.object_id = i.object_id
cross apply (select col.[name] + ', '
from sys.index_columns ic
inner join sys.columns col
on ic.object_id = col.object_id
and ic.column_id = col.column_id
where ic.object_id = t.object_id
and ic.index_id = i.index_id
order by col.column_id
for xml path ('') ) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
order by schema_name(t.schema_id) + '.' + t.[name], i.index_id

-- لیست تمامی Index های تعریف شده در یک دیتابیس
select i.[name] as index_name,
substring(column_names, 1, len(column_names)-1) as [columns],
case when i.[type] = 1 then 'Clustered index'
when i.[type] = 2 then 'Nonclustered unique index'
when i.[type] = 3 then 'XML index'
when i.[type] = 4 then 'Spatial index'
when i.[type] = 5 then 'Clustered columnstore index'
when i.[type] = 6 then 'Nonclustered columnstore index'
when i.[type] = 7 then 'Nonclustered hash index'
end as index_type,
case when i.is_unique = 1 then 'Unique'
else 'Not unique' end as [unique],
schema_name(t.schema_id) + '.' + t.[name] as table_view,
case when t.[type] = 'U' then 'Table'
when t.[type] = 'V' then 'View'
end as [object_type]
from sys.objects t
inner join sys.indexes i
on t.object_id = i.object_id
cross apply (select col.[name] + ', '
from sys.index_columns ic
inner join sys.columns col
on ic.object_id = col.object_id
and ic.column_id = col.column_id
where ic.object_id = t.object_id
and ic.index_id = i.index_id
order by col.column_id
for xml path ('') ) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
order by i.[name]

-- لیست تمامی constraint های تعریف شده روی جداول یک دیتابیس (PK,UK,FK,Check,Default)
select table_view,
object_type,
constraint_type,
constraint_name,
details
from (
select schema_name(t.schema_id) + '.' + t.[name] as table_view,
case when t.[type] = 'U' then 'Table'
when t.[type] = 'V' then 'View'
end as [object_type],
case when c.[type] = 'PK' then 'Primary key'
when c.[type] = 'UQ' then 'Unique constraint'
when i.[type] = 1 then 'Unique clustered index'
when i.type = 2 then 'Unique index'
end as constraint_type,
isnull(c.[name], i.[name]) as constraint_name,
substring(column_names, 1, len(column_names)-1) as [details]
from sys.objects t
left outer join sys.indexes i
on t.object_id = i.object_id
left outer join sys.key_constraints c
on i.object_id = c.parent_object_id
and i.index_id = c.unique_index_id
cross apply (select col.[name] + ', '
from sys.index_columns ic
inner join sys.columns col
on ic.object_id = col.object_id
and ic.column_id = col.column_id
where ic.object_id = t.object_id
and ic.index_id = i.index_id
order by col.column_id
for xml path ('') ) D (column_names)
where is_unique = 1
and t.is_ms_shipped <> 1
union all
select schema_name(fk_tab.schema_id) + '.' + fk_tab.name as foreign_table,
'Table',
'Foreign key',
fk.name as fk_constraint_name,
schema_name(pk_tab.schema_id) + '.' + pk_tab.name
from sys.foreign_keys fk
inner join sys.tables fk_tab
on fk_tab.object_id = fk.parent_object_id
inner join sys.tables pk_tab
on pk_tab.object_id = fk.referenced_object_id
inner join sys.foreign_key_columns fk_cols
on fk_cols.constraint_object_id = fk.object_id
union all
select schema_name(t.schema_id) + '.' + t.[name],
'Table',
'Check constraint',
con.[name] as constraint_name,
con.[definition]
from sys.check_constraints con
left outer join sys.objects t
on con.parent_object_id = t.object_id
left outer join sys.all_columns col
on con.parent_column_id = col.column_id
and con.parent_object_id = col.object_id
union all
select schema_name(t.schema_id) + '.' + t.[name],
'Table',
'Default constraint',
con.[name],
col.[name] + ' = ' + con.[definition]
from sys.default_constraints con
left outer join sys.objects t
on con.parent_object_id = t.object_id
left outer join sys.all_columns col
on con.parent_column_id = col.column_id
and con.parent_object_id = col.object_id) a
order by table_view, constraint_type, constraint_name

-- خلاصه‌ای از Default Constraint‍ های تعریف شده در یک دیتابیس
select
con.[definition] as default_definition,
count(distinct t.object_id) as [tables],
count(col.column_id) as [columns]
from sys.objects t
inner join sys.all_columns col
on col.object_id = t.object_id
left outer join sys.default_constraints con
on con.parent_object_id = t.object_id
and con.parent_column_id = col.column_id
where t.type = 'U'
group by con.[definition]
order by [columns] desc, [tables] desc


















