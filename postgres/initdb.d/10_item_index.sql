--
-- Create item index for given table name, if no exists
--

CREATE OR REPLACE FUNCTION create_item_index(table_name regclass)
  RETURNS VOID
AS
$$
DECLARE idx_name TEXT = table_name || 'idx_time_value';
BEGIN
  IF exists (SELECT relname FROM pg_class WHERE  relkind = 'i' and relname = idx_name) THEN
    RETURN;
  ELSE
    EXECUTE $QRY$CREATE INDEX $QRY$ || idx_name || $QRY$ ON $QRY$ || table_name || $QRY$(time, value)$QRY$;
  END IF;
END;
$$  LANGUAGE plpgsql;

--
-- Create index for all item0000 tables
--

CREATE OR REPLACE FUNCTION create_item_index_all()
  RETURNS event_trigger
AS
$$
BEGIN
    PERFORM
      create_item_index(table_name)
    FROM
      information_schema.tables
    WHERE table_name ~ '^item[0-9]{4}$'
    ORDER BY table_name;
    RETURN;
END;
$$ LANGUAGE plpgsql;

--
-- Create trigger on create table event
--
CREATE EVENT TRIGGER create_item_index_trigger ON ddl_command_end
  WHEN TAG IN ('CREATE TABLE')
   EXECUTE PROCEDURE create_item_index_all();