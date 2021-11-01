CREATE OR REPLACE FUNCTION public.create_table_weekly_outgoing_subpartitions(next_week boolean DEFAULT NULL::boolean)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  _from text;
  _to text;
  _output text;
  _part text;
  _part1 text;
  _part2 text;
BEGIN
  IF NEXT_WEEK IS NOT NULL THEN
    SELECT INTO _from date_trunc('WEEK',now() + INTERVAL '1 WEEK')::date;
  ELSE
    SELECT INTO _from date_trunc('WEEK',now())::date;
  END IF;
  SELECT INTO _to date_trunc('WEEK',_from::date + INTERVAL '1 WEEK')::date;
  
  -- part names
  SELECT INTO _part 'outgoing_msgs' || replace(_from,'-',''); -- partname
  EXECUTE 'CREATE TABLE ' || _part || ' PARTITION OF outgoing_msgs FOR VALUES FROM (''' || _from || ''') TO (''' || _to || ''') PARTITION BY LIST(outgoing_status_id)';
  -- CREATE TABLE outgoing_msgs_new20210906 PARTITION OF outgoing_msgs_new FOR VALUES FROM ('2021-09-06'::date) TO ('2021-09-13'::date) PARTITION BY LIST(outgoing_status_id);
  
  SELECT INTO _part1 _part || 'p1';
  SELECT INTO _part2 _part || 'p2';
  -- RETURN 'part1 is ' || _part1 || ', part2 is ' || _part2;
  -- RETURN 'sss';
  
  -- sub creating
  EXECUTE 'CREATE TABLE ' || _part1 || ' PARTITION OF ' || _part || ' FOR VALUES IN (0)';
  EXECUTE 'CREATE TABLE ' || _part2 || ' PARTITION OF ' || _part || ' DEFAULT';
  
  -- index stuff
  EXECUTE 'CREATE UNIQUE INDEX ' || _part1 || '_id ON ' || _part1 || '(id)'; -- CREATE UNIQUE INDEX outgoing_msgs_new20210906p1_id ON outgoing_msgs_new20210906p1  (id);
  EXECUTE 'CREATE UNIQUE INDEX ' || _part2 || '_id ON ' || _part2 || '(id)'; -- CREATE UNIQUE INDEX outgoing_msgs_new20210906p2_id ON outgoing_msgs_new20210906p2  (id);
  EXECUTE 'CREATE UNIQUE INDEX ' || _part2 || '_lsim_id ON ' || _part2 || '(lsim_id)'; -- CREATE UNIQUE INDEX outgoing_msgs_new20210906p2_lsim_id ON outgoing_msgs_new20210906p2  (lsim_id); -- not necessary to create lsim index with status id 0
  SELECT INTO _output 'Sub parts ' || _part1 || ', ' || _part2 || ' have been created';
  RETURN _output;
END;
$function$
;
