
-- START OF SYSTEM TABLES --

IF EXISTS (SELECT * FROM sys.tables WHERE sys.tables.name = N'system_id_generator') DROP TABLE "system_id_generator";
IF EXISTS (SELECT * FROM sys.tables WHERE sys.tables.name = N'system_property') DROP TABLE "system_property";
IF EXISTS (SELECT * FROM sys.tables WHERE sys.tables.name = N'system_database_schema_version') DROP TABLE "system_database_schema_version";
IF EXISTS (SELECT * FROM sys.tables WHERE sys.tables.name = N'system_data') DROP TABLE "system_data";
IF EXISTS (SELECT * FROM sys.tables WHERE sys.tables.name = N'system_files_store') DROP TABLE "system_files_store";
IF EXISTS (SELECT * FROM sys.tables WHERE sys.tables.name = N'system_certificate_chain_association') DROP TABLE "system_certificate_chain_association";
IF EXISTS (SELECT * FROM sys.tables WHERE sys.tables.name = N'system_certificates') DROP TABLE "system_certificates";
IF EXISTS (SELECT * FROM sys.tables WHERE sys.tables.name = N'system_protection_keys') DROP TABLE "system_protection_keys";


CREATE TABLE "system_id_generator" (
  table_name NVARCHAR(255) NOT NULL,
  next_id BIGINT NOT NULL,
  CONSTRAINT [EWHILO_PKEY_SYSTEM] PRIMARY KEY CLUSTERED ( table_name ASC ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];
GO

-- TABLE "system_property" --

CREATE TABLE "system_property" (
    "id" INT IDENTITY(1,1) PRIMARY KEY,
    "name" NVARCHAR(255) UNIQUE NOT NULL,
    "value" NVARCHAR(MAX) DEFAULT NULL,
    "display_name" NVARCHAR(255) DEFAULT NULL,
    "display_flag" BIT DEFAULT 0,
    "default_value" NVARCHAR(MAX) DEFAULT NULL,
    "description" NVARCHAR(255) DEFAULT NULL,
    "delete_flag" BIT DEFAULT 0,
    "edit_flag" BIT DEFAULT 0,
    "mark_deleted" BIT DEFAULT 0,
    "reboot_reqd" BIT DEFAULT 1
);
GO

-- TABLE "system_database_schema_version"
-- Similar to tenant database_schema_version table
-- Stores the schema version the system DB is currently on
CREATE TABLE "system_database_schema_version" (
	major int NOT NULL,
	minor int NOT NULL,
	PRIMARY KEY(major, minor)
);
GO


-- This is used internally.
INSERT INTO "system_database_schema_version" VALUES(10, 63);
GO

-- TABLE "system_data"
-- Stores system wide data common to all tenants
CREATE TABLE "system_data" (
	cluster_id NVARCHAR(64) NOT NULL,
	hazelcast_port_enabled BIT DEFAULT 0 NOT NULL,
	ssl_offloading_enabled BIT DEFAULT 0 NOT NULL,
	fips_mode BIT DEFAULT 0 NOT NULL,
	sta_id BIGINT NOT NULL UNIQUE,
        hostname NVARCHAR(256) NOT NULL,
	id BIGINT NOT NULL PRIMARY KEY
);
GO

-- TABLE "system_certificates"
-- Stores only the ssl_listener_cert for the time being
CREATE TABLE "system_certificates" (
	name NVARCHAR(256) NOT NULL,
	description NVARCHAR(max),
	cert nvarchar(max),
	private_key varbinary(max),
	cert_type NVARCHAR(10) NOT NULL CHECK (cert_type IN('ca', 'csr', 'chain', 'listener')),
	valid_from DATE,
	valid_to DATE,
	active BIT DEFAULT 0,
	metadata nvarchar(max),
	reference BIGINT,
	id BIGINT NOT NULL PRIMARY KEY
);
GO

-- -----------------------------------------------------
-- TABLE: system_certificate_chain_association
-- this table is used to keep track of certificate chains
-- note that position field is used in order to properly
-- assemble certificate chain (some tools require a proper
-- sequence of certificate chains e.g. first CA, then signed
-- cert.1 then cert.2 signed by cert.1, etc.
-- -----------------------------------------------------
CREATE TABLE "system_certificate_chain_association" (
	ssl_cert_id BIGINT NOT NULL,
	certificate_id BIGINT NOT NULL,
	position int NOT NULL,
	id BIGINT NOT NULL PRIMARY KEY,
	FOREIGN KEY (ssl_cert_id) REFERENCES system_certificates (id),
	FOREIGN KEY (certificate_id) REFERENCES system_certificates (id) ON DELETE CASCADE
);
GO

-- ------------------------------------------------------------------------
-- TABLE: system_files_store
-- Stores files like listener certificates
-- ------------------------------------------------------------------------
CREATE TABLE "system_files_store" (
	id BIGINT NOT NULL PRIMARY KEY,
	name NVARCHAR(255) NOT NULL,
	content varbinary(max) NOT NULL,
	type NVARCHAR(32)
);
GO

CREATE TABLE system_protection_keys
(
  id BIGINT NOT NULL PRIMARY KEY,
  keyname VARCHAR(256),
  keyvalue VARCHAR(max),
  salt VARCHAR(256)
);
GO

-- TODO: bring in NODE_ROSTER table here

-- END OF SYSTEM TABLES --
