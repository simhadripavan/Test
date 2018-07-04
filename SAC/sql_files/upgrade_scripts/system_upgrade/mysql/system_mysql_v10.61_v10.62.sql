SET SQL_SAFE_UPDATES = 0;

-- Updating the database schema version
UPDATE `system_database_schema_version`
SET minor=62;

-- This need to the last statement -- IMPORTANT NOTE --
SET SQL_SAFE_UPDATES=1;