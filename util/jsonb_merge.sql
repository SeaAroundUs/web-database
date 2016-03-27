CREATE OR REPLACE FUNCTION jsonb_merge(i_left JSONB, i_right JSONB)
RETURNS JSONB
AS $$
SELECT
  CASE WHEN jsonb_typeof(i_left) = 'object' AND jsonb_typeof(i_right) = 'object' THEN
       (SELECT json_object_agg(COALESCE(o.key, n.key), CASE WHEN n.key IS NOT NULL THEN n.value ELSE o.value END)::jsonb
        FROM jsonb_each(i_left) o
        FULL JOIN jsonb_each(i_right) n ON (n.key = o.key))
   ELSE 
     (CASE WHEN jsonb_typeof(i_left) = 'array' THEN LEFT(i_left::text, -1) ELSE '['||i_left::text END ||', '||
      CASE WHEN jsonb_typeof(i_right) = 'array' THEN RIGHT(i_right::text, -1) ELSE i_right::text||']' END)::jsonb
   END     
$$ LANGUAGE sql IMMUTABLE STRICT;

--CREATE OPERATOR || ( LEFTARG = jsonb, RIGHTARG = jsonb, PROCEDURE = jsonb_merge );
