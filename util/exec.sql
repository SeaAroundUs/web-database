CREATE OR REPLACE FUNCTION exec(text) 
returns text AS 
$f$ 
  BEGIN 
    EXECUTE $1; 
    RETURN $1; 
  END; 
$f$
LANGUAGE plpgsql volatile;
