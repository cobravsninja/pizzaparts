CREATE OR REPLACE FUNCTION public.create_table_weekly_partition(table_name text, index_column text DEFAULT NULL::text, next_week boolean DEFAULT NULL::boolean)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  _from text; 
  _to text;
  _part text;
  _idx text;
  _output text;
BEGIN
  IF NEXT_WEEK IS NOT NULL THEN
    SELECT INTO _from date_trunc('WEEK',now() + INTERVAL '1 WEEK')::date;
  ELSE
    SELECT INTO _from date_trunc('WEEK',now())::date;
  END IF;
  SELECT INTO _to date_trunc('WEEK',_from::date + INTERVAL '1 WEEK')::date;
  SELECT INTO _part TABLE_NAME || replace(_from,'-',''); -- partname
  EXECUTE 'CREATE TABLE ' || _part || ' PARTITION OF ' || TABLE_NAME || ' FOR VALUES FROM (''' || _from || ''') TO (''' || _to || ''')';
  SELECT INTO _output 'Table ' || _part || ' has been created.';
  IF INDEX_COLUMN IS NOT NULL THEN
    SELECT _part || INDEX_COLUMN INTO _idx;
    EXECUTE 'CREATE UNIQUE INDEX ' || _idx || ' ON ' || _part || '(' || INDEX_COLUMN || ')'; -- table20210101myid_idx (_idx is var from function param)
	SELECT INTO _output _output || ' Index ' || _idx || ' for ' || _part || ' has been created';
  END IF;
  RETURN _output;
END;
$function$
;
