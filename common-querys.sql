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

-- لیست Check Constraintهای تعریف شده روی یک جدول
select schema_name(t.schema_id) + '.' + t.[name] as [table],
col.column_id,
col.[name] as column_name,
con.[definition],
case when con.is_disabled = 0
then 'Active'
else 'Disabled'
end as [status],
con.[name] as constraint_name
from sys.check_constraints con
left outer join sys.objects t
on con.parent_object_id = t.object_id
left outer join sys.all_columns col
on con.parent_column_id = col.column_id
and con.parent_object_id = col.object_id
order by schema_name(t.schema_id) + '.' + t.[name],
col.column_id

-- لیست تمامی Check Constraint های تعریف شده در یک دیتابیس
[select con.[name] as constraint_name,
schema_name(t.schema_id) + '.' + t.[name] as [table],
col.[name] as column_name,
con.[definition],
case when con.is_disabled = 0
then 'Active'
else 'Disabled'
end as [status]
from sys.check_constraints con
left outer join sys.objects t
on con.parent_object_id = t.object_id
left outer join sys.all_columns col
on con.parent_column_id = col.column_id
and con.parent_object_id = col.object_id
order by con.name

-- لیست Unique Key ها و Index های یک دیتابیس
select schema_name(t.schema_id) + '.' + t.[name] as table_view,
case when t.[type] = 'U' then 'Table'
when t.[type] = 'V' then 'View'
end as [object_type],
case when c.[type] = 'PK' then 'Primary key'
when c.[type] = 'UQ' then 'Unique constraint'
when i.[type] = 1 then 'Unique clustered index'
when i.type = 2 then 'Unique index'
end as constraint_type,
c.[name] as constraint_name,
substring(column_names, 1, len(column_names)-1) as [columns],
i.[name] as index_name,
case when i.[type] = 1 then 'Clustered index'
when i.type = 2 then 'Index'
end as index_type
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
order by schema_name(t.schema_id) + '.' + t.[name]

-- لیست جداول همراه با تعداد ارجاعات (پر ارجاع ترین جداول)
select schema_name(tab.schema_id) + '.' + tab.name as [table],
count(fk.name) as [references],
count(distinct fk.parent_object_id) as referencing_tables
from sys.tables as tab
left join sys.foreign_keys as fk
on tab.object_id = fk.referenced_object_id
group by schema_name(tab.schema_id), tab.name
having count(fk.name) &amp;gt; 0
order by 2 desc

-- لیست جداولی که توسط هیچ FK مورد ارجاع قرار نگرفته‌اند
select 'No FKs >-' foreign_keys,
schema_name(fk_tab.schema_id) as schema_name,
fk_tab.name as table_name
from sys.tables fk_tab
left outer join sys.foreign_keys fk
on fk_tab.object_id = fk.referenced_object_id
where fk.object_id is null
order by schema_name(fk_tab.schema_id),
fk_tab.name

-- لیست جداول ارجاع کننده به یک جدول خاص (توسط FK)
select distinct
schema_name(fk_tab.schema_id) + '.' + fk_tab.name as foreign_table,
'>-' as rel,
schema_name(pk_tab.schema_id) + '.' + pk_tab.name as primary_table
from sys.foreign_keys fk
inner join sys.tables fk_tab
on fk_tab.object_id = fk.parent_object_id
inner join sys.tables pk_tab
on pk_tab.object_id = fk.referenced_object_id
where pk_tab.[name] = 'Your table' -- enter table name here
-- and schema_name(pk_tab.schema_id) = 'Your table schema name'
order by schema_name(fk_tab.schema_id) + '.' + fk_tab.name,
schema_name(pk_tab.schema_id) + '.' + pk_tab.name

-- لیست جداول مورد ارجاع توسط Foreign Key در یک جدول
select distinct
schema_name(fk_tab.schema_id) + '.' + fk_tab.name as foreign_table,
'>-' as rel,
schema_name(pk_tab.schema_id) + '.' + pk_tab.name as primary_table
from sys.foreign_keys fk
inner join sys.tables fk_tab
on fk_tab.object_id = fk.parent_object_id
inner join sys.tables pk_tab
on pk_tab.object_id = fk.referenced_object_id
where fk_tab.[name] = 'Your table' -- enter table name here
-- and schema_name(fk_tab.schema_id) = 'Your table schema name'
order by schema_name(fk_tab.schema_id) + '.' + fk_tab.name,
schema_name(pk_tab.schema_id) + '.' + pk_tab.name

-- لیست Foreign Key Constraint های یک دیتابیس
select schema_name(fk_tab.schema_id) + '.' + fk_tab.name as foreign_table,
'>-' as rel,
schema_name(pk_tab.schema_id) + '.' + pk_tab.name as primary_table,
substring(column_names, 1, len(column_names)-1) as [fk_columns],
fk.name as fk_constraint_name
from sys.foreign_keys fk
inner join sys.tables fk_tab
on fk_tab.object_id = fk.parent_object_id
inner join sys.tables pk_tab
on pk_tab.object_id = fk.referenced_object_id
cross apply (select col.[name] + ', '
from sys.foreign_key_columns fk_c
inner join sys.columns col
on fk_c.parent_object_id = col.object_id
and fk_c.parent_column_id = col.column_id
where fk_c.parent_object_id = fk_tab.object_id
and fk_c.constraint_object_id = fk.object_id
order by col.column_id
for xml path ('') ) D (column_names)
order by schema_name(fk_tab.schema_id) + '.' + fk_tab.name,
schema_name(pk_tab.schema_id) + '.' + pk_tab.name

-- لیست تمامی ستون‌ های یک جدول خاص
select
col.column_id as id,
col.name,
t.name as data_type,
col.max_length,
col.precision,
col.is_nullable
from sys.tables as tab
inner join sys.columns as col
on tab.object_id = col.object_id
left join sys.types as t
on col.user_type_id = t.user_type_id
where tab.name = 'Table name' -- enter table name here
-- and schema_name(tab.schema_id) = 'Schema name'
order by tab.name, column_id;

-- لیست جداول با بیشترین تعداد Foreign Key
select schema_name(fk_tab.schema_id) + '.' + fk_tab.name as [table],
count(*) foreign_keys,
count (distinct referenced_object_id) referenced_tables
from sys.foreign_keys fk
inner join sys.tables fk_tab
on fk_tab.object_id = fk.parent_object_id
group by schema_name(fk_tab.schema_id) + '.' + fk_tab.name
order by count(*) desc

-- لیست ستون‌های یک جدول به همراه Foreign Key‌ های آنها
select schema_name(tab.schema_id) + '.' + tab.name as [table],
col.column_id,
col.name as column_name,
case when fk.object_id is not null then '>-' else null end as rel,
schema_name(pk_tab.schema_id) + '.' + pk_tab.name as primary_table,
pk_col.name as pk_column_name,
fk_cols.constraint_column_id as no,
fk.name as fk_constraint_name
from sys.tables tab
inner join sys.columns col
on col.object_id = tab.object_id
left outer join sys.foreign_key_columns fk_cols
on fk_cols.parent_object_id = tab.object_id
and fk_cols.parent_column_id = col.column_id
left outer join sys.foreign_keys fk
on fk.object_id = fk_cols.constraint_object_id
left outer join sys.tables pk_tab
on pk_tab.object_id = fk_cols.referenced_object_id
left outer join sys.columns pk_col
on pk_col.column_id = fk_cols.referenced_column_id
and pk_col.object_id = fk_cols.referenced_object_id
order by schema_name(tab.schema_id) + '.' + tab.name,
col.column_id

-- لیست ستون‌های شرکت کننده در Foreign Key Constraint های یک دیتابیس
select schema_name(fk_tab.schema_id) + '.' + fk_tab.name as foreign_table,
'>-' as rel,
schema_name(pk_tab.schema_id) + '.' + pk_tab.name as primary_table,
fk_cols.constraint_column_id as no,
fk_col.name as fk_column_name,
' = ' as [join],
pk_col.name as pk_column_name,
fk.name as fk_constraint_name
from sys.foreign_keys fk
inner join sys.tables fk_tab
on fk_tab.object_id = fk.parent_object_id
inner join sys.tables pk_tab
on pk_tab.object_id = fk.referenced_object_id
inner join sys.foreign_key_columns fk_cols
on fk_cols.constraint_object_id = fk.object_id
inner join sys.columns fk_col
on fk_col.column_id = fk_cols.parent_column_id
and fk_col.object_id = fk_tab.object_id
inner join sys.columns pk_col
on pk_col.column_id = fk_cols.referenced_column_id
and pk_col.object_id = pk_tab.object_id
order by schema_name(fk_tab.schema_id) + '.' + fk_tab.name,
schema_name(pk_tab.schema_id) + '.' + pk_tab.name,
fk_cols.constraint_column_id

-- لیست تمامی Primary Key های یک دیتابیس
select schema_name(tab.schema_id) as [schema_name],
pk.[name] as pk_name,
substring(column_names, 1, len(column_names)-1) as [columns],
tab.[name] as table_name
from sys.tables tab
inner join sys.indexes pk
on tab.object_id = pk.object_id
and pk.is_primary_key = 1
cross apply (select col.[name] + ', '
from sys.index_columns ic
inner join sys.columns col
on ic.object_id = col.object_id
and ic.column_id = col.column_id
where ic.object_id = tab.object_id
and ic.index_id = pk.index_id
order by col.column_id
for xml path ('') ) D (column_names)
order by schema_name(tab.schema_id),
pk.[name]

-- لیست جداول به همراه Primary Key آنها
select schema_name(tab.schema_id) as [schema_name],
tab.[name] as table_name,
pk.[name] as pk_name,
substring(column_names, 1, len(column_names)-1) as [columns]
from sys.tables tab
left outer join sys.indexes pk
on tab.object_id = pk.object_id
and pk.is_primary_key = 1
cross apply (select col.[name] + ', '
from sys.index_columns ic
inner join sys.columns col
on ic.object_id = col.object_id
and ic.column_id = col.column_id
where ic.object_id = tab.object_id
and ic.index_id = pk.index_id
order by col.column_id
for xml path ('') ) D (column_names)
order by schema_name(tab.schema_id),
tab.[name]

-- لیست تمامی ستون‌ های جداول یک دیتابیس
select schema_name(tab.schema_id) as schema_name,
tab.name as table_name,
col.column_id,
col.name as column_name,
t.name as data_type,
col.max_length,
col.precision
from sys.tables as tab
inner join sys.columns as col
on tab.object_id = col.object_id
left join sys.types as t
on col.user_type_id = t.user_type_id
order by schema_name,
table_name,
column_id;

-- لیست جداول Graph در یک دیتابیس
select case when is_node = 1 then 'Node'
when is_edge = 1 then 'Edge'
end table_type,
schema_name(schema_id) as schema_name,
name as table_name
from sys.tables
where is_node = 1 or is_edge = 1
order by is_edge, schema_name, table_name

-- لیست Temporal Table ها در یک دیتابیس
select schema_name(t.schema_id) as temporal_table_schema,
t.name as temporal_table_name,
schema_name(h.schema_id) as history_table_schema,
h.name as history_table_name,
case when t.history_retention_period = -1
then 'INFINITE'
else cast(t.history_retention_period as varchar) + ' ' +
t.history_retention_period_unit_desc + 'S'
end as retention_period
from sys.tables t
left outer join sys.tables h
on t.history_table_id = h.object_id
where t.temporal_type = 2order by temporal_table_schema, temporal_table_name

-- لیست جداول یک دیتابیس
select schema_name(t.schema_id) as schema_name,
t.name as table_name,
t.create_date,
t.modify_date
from sys.tables t
order by schema_name,
table_name

-- لیست Schema های ایجاد شده توسط کاربر در یک دیتابیس
select s.name as schema_name,
s.schema_id,
u.name as schema_owner
from sys.schemas s
inner join sys.sysusers u
on u.uid = s.principal_id
where u.issqluser = 1
and u.name not in ('sys', 'guest', 'INFORMATION_SCHEMA')

-- لیست Schema های موجود در یک دیتابیس
select s.name as schema_name,
s.schema_id,
u.name as schema_owner
from sys.schemas s
inner join sys.sysusers u
on u.uid = s.principal_id
order by s.name

-- لیست دیتابیس‌های موجود در یک Instance
select [name] as database_name,
database_id,
create_date
from sys.databases
order by name

-- لیست ستون های Non Nullable جداول یک دیتابیس
select schema_name(tab.schema_id) as schema_name,
tab.name as table_name,
col.column_id,
col.name as column_name,
t.name as data_type,
col.max_length,
col.precision
from sys.tables as tab
inner join sys.columns as col
on tab.object_id = col.object_id
left join sys.types as t
on col.user_type_id = t.user_type_id
where col.is_nullable = 0
order by schema_name,
table_name,
column_name;

-- لیست جداول بدون ارتباط Loner Tables
select 'No FKs >-' refs,
fks.tab as [table],
'>- no FKs' fks
from
(select schema_name(tab.schema_id) + '.' + tab.name as tab,
count(fk.name) as fk_cnt
from sys.tables as tab
left join sys.foreign_keys as fk
on tab.object_id = fk.parent_object_id
group by schema_name(tab.schema_id), tab.name) fks
inner join
(select schema_name(tab.schema_id) + '.' + tab.name as tab,
count(fk.name) ref_cnt
from sys.tables as tab
left join sys.foreign_keys as fk
on tab.object_id = fk.referenced_object_id
group by schema_name(tab.schema_id), tab.name) refs
on fks.tab = refs.tab
where fks.fk_cnt + refs.ref_cnt = 0

-- درصد جداول Loner – تعداد جداول فاقد ارتباط
select count(*) [table_count],
sum(case when fks.cnt + refs.cnt = 0 then 1 else 0 end)
as [loner_tables],
cast(cast(100.0 * sum(case when fks.cnt + refs.cnt = 0 then 1 else 0 end)
/ count(*) as decimal(36, 1)) as varchar) + '%' as [loner_ratio]
from (select schema_name(tab.schema_id) + '.' + tab.name as tab,
count(fk.name) cnt
from sys.tables as tab
left join sys.foreign_keys as fk
on tab.object_id = fk.parent_object_id
group by schema_name(tab.schema_id), tab.name) fks
inner join
(select schema_name(tab.schema_id) + '.' + tab.name as tab,
count(fk.name) cnt
from sys.tables as tab
left join sys.foreign_keys as fk
on tab.object_id = fk.referenced_object_id
group by schema_name(tab.schema_id), tab.name) refs
on fks.tab = refs.tab

-- لیست ستون‌هایی با انواع داده‌ای LOB در یک دیتابیس
select t.table_schema as schema_name,
t.table_name,
c.column_name,
c.data_type
from information_schema.columns c
inner join information_schema.tables t
on c.table_schema = t.table_schema
and c.table_name = t.table_name
where t.table_type = 'BASE TABLE'
and ((c.data_type in ('VARCHAR', 'NVARCHAR') and character_maximum_length = -1)
or c.data_type in ('TEXT', 'NTEXT', 'IMAGE', 'VARBINARY', 'XML', 'FILESTREAM'))
order by t.table_schema,
t.table_name,
c.column_name

-- بدست آوردن میزان فضای تخصیص یافته LOB های یک دیتابیس
select case when spc.type in (1, 3) then 'Regular data'
else 'LOB data' end as allocation_type,
cast(sum(spc.used_pages * 8) / 1024.00 as numeric(36, 2)) as used_mb,
cast(sum(spc.total_pages * 8) / 1024.00 as numeric(36, 2)) as allocated_mb
from sys.tables tab
inner join sys.indexes ind
on tab.object_id = ind.object_id
inner join sys.partitions part
on ind.object_id = part.object_id and ind.index_id = part.index_id
inner join sys.allocation_units spc
on part.partition_id = spc.container_id
group by case when spc.type in (1, 3) then 'Regular data'
else 'LOB data' end

-- لیست Default Constraint های جداول یک دیتابیس
select schema_name(t.schema_id) + '.' + t.[name] as [table],
col.column_id,
col.[name] as column_name,
con.[definition],
case when con.is_disabled = 0
then 'Active'
else 'Disabled'
end as [status],
con.[name] as constraint_name
from sys.check_constraints con
left outer join sys.objects t
on con.parent_object_id = t.object_id
left outer join sys.all_columns col
on con.parent_column_id = col.column_id
and con.parent_object_id = col.object_id
order by schema_name(t.schema_id) + '.' + t.[name],
col.column_id

-- مقایسه جداول و ستون‌های دو دیتابیس
select isnull(db1.table_name, db2.table_name) as [table],
isnull(db1.column_name, db2.column_name) as [column],
db1.column_name as database1,
db2.column_name as database2
from
(select schema_name(tab.schema_id) + ‘.’ + tab.name as table_name,
col.name as column_name
from [dataedo_6.0].sys.tables as tab
inner join [dataedo_6.0].sys.columns as col
on tab.object_id = col.object_id) db1
full outer join
(select schema_name(tab.schema_id) + ‘.’ + tab.name as table_name,
col.name as column_name
from [dataedo_7.0].sys.tables as tab
inner join [dataedo_7.0].sys.columns as col
on tab.object_id = col.object_id) db2
on db1.table_name = db2.table_name
and db1.column_name = db2.column_name
where (db1.column_name is null or db2.column_name is null)
order by 1, 2, 3

--  تعیین نوع جداول در SQL Server 2017
select schema_name(schema_id) as schema_name,
name as table_name,
case when is_external = 1 then 'External table'
when is_node = 1 then 'Graph node table'
when is_edge = 1 then 'Graph edge table'
when temporal_type = 2 then 'System versioned table'
when temporal_type = 1 then 'History table'
when is_filetable = 1 then 'File table'
else 'Regular table'
end as table_type
from sys.tables
order by schema_name, table_name





























