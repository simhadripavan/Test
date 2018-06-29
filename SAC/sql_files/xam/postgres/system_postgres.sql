BEGIN;

-- START OF SYSTEM TABLES --

DROP TABLE IF EXISTS "system_id_generator";
DROP TABLE IF EXISTS "system_property";
DROP TABLE IF EXISTS "system_database_schema_version";
DROP TABLE IF EXISTS "system_data";
DROP TABLE IF EXISTS "system_files_store";
DROP TABLE IF EXISTS "system_certificate_chain_association";
DROP TABLE IF EXISTS "system_certificates";
DROP TABLE IF EXISTS "system_protection_keys";

DROP SEQUENCE IF EXISTS "system_property_id_seq";

CREATE TABLE "system_id_generator" (
  "table_name" VARCHAR(255) NOT NULL,
  "next_id" BIGINT NOT NULL,
  CONSTRAINT EWHILO_PKEY_SYSTEM PRIMARY KEY ("table_name")
);

-- TABLE: "system_property" --

CREATE SEQUENCE "system_property_id_seq";

CREATE TABLE "system_property" (
    "id" INTEGER PRIMARY KEY DEFAULT nextval('"system_property_id_seq"'),
    "name" VARCHAR(255) UNIQUE NOT NULL,
    "value" TEXT DEFAULT NULL,
    "display_name" VARCHAR(255) DEFAULT NULL,
    "display_flag" BOOLEAN DEFAULT 'FALSE',
    "default_value" TEXT DEFAULT NULL,
    "description" VARCHAR(255) DEFAULT NULL,
    "delete_flag" BOOLEAN DEFAULT 'FALSE',
    "edit_flag" BOOLEAN DEFAULT 'FALSE',
    "mark_deleted" BOOLEAN DEFAULT 'FALSE',
    "reboot_reqd"  BOOLEAN DEFAULT 'TRUE'
);

-- TABLE "system_database_schema_version"
-- Similar to tenant database_schema_version table
-- Stores the schema version the system DB is currently on
CREATE TABLE system_database_schema_version (
	major int NOT NULL,
	minor int NOT NULL,
	PRIMARY KEY(major, minor)
);

-- This is used internally.
INSERT INTO system_database_schema_version VALUES(10, 61);

-- TABLE "system_data"
-- Stores system wide data common to all tenants
CREATE TABLE system_data (
	cluster_id VARCHAR(64) NOT NULL,
	hazelcast_port_enabled BOOLEAN DEFAULT FALSE NOT NULL,
	ssl_offloading_enabled BOOLEAN DEFAULT FALSE NOT NULL,
	fips_mode BOOLEAN DEFAULT FALSE NOT NULL,
	id BIGINT NOT NULL UNIQUE,
        hostname VARCHAR(256) NOT NULL,
	sta_id BIGINT NOT NULL UNIQUE,
	PRIMARY KEY(id)
);

-- TABLE "system_certificates"
-- Stores only the ssl_listener_cert for the time being
CREATE TABLE system_certificates (
	name VARCHAR(256) NOT NULL,
	description VARCHAR(1024),
	cert VARCHAR,
	private_key bytea,
	cert_type VARCHAR(10) NOT NULL CHECK (cert_type LIKE 'ca' OR cert_type LIKE 'csr' OR cert_type LIKE 'chain' OR cert_type LIKE 'listener'),
	valid_from DATE,
	valid_to DATE,
	active BOOLEAN DEFAULT FALSE,
	metadata VARCHAR(2048),
	reference BIGINT,
	id BIGINT NOT NULL UNIQUE,
	PRIMARY KEY(id)
);

-- -----------------------------------------------------
-- TABLE:certificate_chain_association
-- this table is used to keep track of certificate chains
-- note that position field is used in order to properly
-- assemble certificate chain (some tools require a proper
-- sequence of certificate chains e.g. first CA, then signed
-- cert.1 then cert.2 signed by cert.1, etc.
-- -----------------------------------------------------
CREATE TABLE system_certificate_chain_association (
	ssl_cert_id BIGINT NOT NULL,
	certificate_id BIGINT NOT NULL,
	position INTEGER NOT NULL,
	id BIGINT NOT NULL UNIQUE,
	PRIMARY KEY (id),
	FOREIGN KEY (ssl_cert_id) REFERENCES system_certificates (id) ON DELETE CASCADE,
	FOREIGN KEY (certificate_id) REFERENCES system_certificates (id) ON DELETE CASCADE
);

-- system_files_store table which stores system files like listener certificates
CREATE TABLE system_files_store (
	id BIGINT NOT NULL PRIMARY KEY,
	name VARCHAR(255) NOT NULL UNIQUE,
	content BYTEA NOT NULL,
	type VARCHAR(32)
);


CREATE TABLE system_protection_keys (

  id BIGINT NOT NULL PRIMARY KEY,

  keyname VARCHAR(256),

  keyvalue text,

  salt VARCHAR(256)

);


-- TODO: bring in NODE_ROSTER table here

COMMIT;
-- END OF SYSTEM TABLES --
