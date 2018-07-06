
-- START OF SYSTEM TABLES --

DROP TABLE IF EXISTS `system_id_generator`;
DROP TABLE IF EXISTS `system_property`;
DROP TABLE IF EXISTS `system_database_schema_version`;
DROP TABLE IF EXISTS `system_data`;
DROP TABLE IF EXISTS `system_files_store`;
DROP TABLE IF EXISTS `system_certificate_chain_association`;
DROP TABLE IF EXISTS `system_certificates`;
DROP TABLE IF EXISTS `system_protection_keys`;

-- TABLE STRUCTURE FOR TABLE `system_property` --

CREATE TABLE `system_property` (

    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(255) UNIQUE NOT NULL,
    `value` TEXT DEFAULT NULL,
    `display_name` VARCHAR(255) DEFAULT NULL,
    `display_flag` BOOLEAN DEFAULT FALSE,
    `default_value` TEXT DEFAULT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `delete_flag` BOOLEAN DEFAULT FALSE,
    `edit_flag` BOOLEAN DEFAULT FALSE,
    `mark_deleted` BOOLEAN DEFAULT FALSE,
    `reboot_reqd` BOOLEAN DEFAULT TRUE

)ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `system_id_generator` (
	`table_name` VARCHAR(255) NOT NULL,
	`next_id` BIGINT NOT NULL,
	CONSTRAINT EWHILO_PKEY_SYSTEM PRIMARY KEY (table_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `system_database_schema_version` (
	`major` int NOT NULL,
	`minor` int NOT NULL,
	PRIMARY KEY(major, minor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- This is used internally.
INSERT INTO `system_database_schema_version` VALUES(10, 72);

CREATE TABLE `system_data` (
	`cluster_id` VARCHAR(64) NOT NULL,
	`hazelcast_port_enabled` BOOLEAN DEFAULT FALSE NOT NULL,
	`ssl_offloading_enabled` BOOLEAN DEFAULT FALSE NOT NULL,
	`fips_mode` BOOLEAN DEFAULT FALSE NOT NULL,
        `hostname` VARCHAR(256) NOT NULL,
	`sta_id` BIGINT NOT NULL UNIQUE,
	`id` BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `system_certificates` (
	`name` VARCHAR(256) NOT NULL,
	`description` text,
	`cert` text,
	`private_key` BLOB,
	`cert_type` ENUM('ca', 'csr', 'listener', 'chain') NOT NULL,
	`valid_from` DATE,
	`valid_to` DATE,
	`active` BOOLEAN DEFAULT FALSE,
	`metadata` text,
	`reference` BIGINT,
	`id` BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- TABLE:certificate_chain_association
-- this table is used to keep track of certificate chains
-- note that position field is used in order to properly
-- assemble certificate chain (some tools require a proper
-- sequence of certificate chains e.g. first CA, then signed
-- cert.1 then cert.2 signed by cert.1, etc.
-- -----------------------------------------------------
CREATE TABLE `system_certificate_chain_association` (
	`ssl_cert_id` BIGINT NOT NULL,
	`certificate_id` BIGINT NOT NULL,
	`position` int NOT NULL,
	`id` BIGINT NOT NULL PRIMARY KEY,
	FOREIGN KEY (ssl_cert_id) REFERENCES system_certificates (id) ON DELETE CASCADE,
	FOREIGN KEY (certificate_id) REFERENCES system_certificates (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- system_files_store table which stores files like listener certificates
CREATE TABLE `system_files_store` (
	`id` BIGINT NOT NULL PRIMARY KEY,
	`name` VARCHAR(255) NOT NULL,
	`content` BLOB NOT NULL,
	`type` VARCHAR(32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `system_protection_keys` (

  `id` BIGINT NOT NULL PRIMARY KEY,

  `keyname` varchar(256),

  `keyvalue` Text,

  `salt` varchar(256)

)ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- TODO: bring in NODE_ROSTER table here


-- END OF SYSTEM TABLES --
