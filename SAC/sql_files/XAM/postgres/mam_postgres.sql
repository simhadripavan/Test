BEGIN;

CREATE TABLE Id_Generator(
  table_name VARCHAR(255) NOT NULL,
  next_id BIGINT NOT NULL,
  CONSTRAINT EWHILO_PKEY_XAM PRIMARY KEY (table_name)
);

CREATE TABLE static_content (
id bigint not null PRIMARY KEY,
content_hash VARCHAR(128) not null,
type VARCHAR(5) not null,
ref_count INTEGER,
content bytea,
is_stock BOOLEAN NOT NULL DEFAULT FALSE
);

create TABLE icon_details(
id bigint not null PRIMARY KEY,
ref_name VARCHAR(1024) not null,
xres INTEGER not null,
yres INTEGER,
sc_id bigint,
FOREIGN KEY (sc_id) REFERENCES static_content (id)
);

CREATE TABLE info_log_level_type (
    id SMALLINT NOT NULL UNIQUE CHECK(id < 7),
    name VARCHAR(32) NOT NULL UNIQUE,
    PRIMARY KEY(id)
);

CREATE TABLE debug_log_level_type (
    id SMALLINT NOT NULL UNIQUE CHECK(id < 9),
    name VARCHAR(32) NOT NULL UNIQUE,
    PRIMARY KEY(id)
);

INSERT INTO debug_log_level_type VALUES(0, $$off$$);
INSERT INTO debug_log_level_type VALUES(1, $$critical$$);
INSERT INTO debug_log_level_type VALUES(2, $$error$$);
INSERT INTO debug_log_level_type VALUES(3, $$warning$$);
INSERT INTO debug_log_level_type VALUES(4, $$control$$);
INSERT INTO debug_log_level_type VALUES(5, $$debug4$$);
INSERT INTO debug_log_level_type VALUES(6, $$debug5$$);
INSERT INTO debug_log_level_type VALUES(7, $$debug6$$);
INSERT INTO debug_log_level_type VALUES(8, $$debug7$$);

INSERT INTO info_log_level_type VALUES(0, $$emergency$$);
INSERT INTO info_log_level_type VALUES(1, $$alert$$);
INSERT INTO info_log_level_type VALUES(2, $$critical$$);
INSERT INTO info_log_level_type VALUES(3, $$error$$);
INSERT INTO info_log_level_type VALUES(4, $$warning$$);
INSERT INTO info_log_level_type VALUES(5, $$notice$$);
INSERT INTO info_log_level_type VALUES(6, $$info$$);

CREATE TABLE  support_serverdetails (
   url VARCHAR(128) NOT NULL UNIQUE,
   username VARCHAR(64) NOT NULL,
   password VARCHAR(512),
   server_type VARCHAR(20) NOT NULL,
   PRIMARY KEY (url)

  );



CREATE TABLE certificate (
    name VARCHAR(256) NOT NULL,
    description VARCHAR(1024),
    cert VARCHAR,
    private_key bytea,
    cert_type VARCHAR(10) NOT NULL CHECK (cert_type LIKE 'ca' OR cert_type LIKE 'csr' OR cert_type LIKE 'entity' or cert_type LIKE 'chain' or cert_type LIKE 'saml' or cert_type LIKE 'apns' or cert_type LIKE 'apnsCsr' or cert_type LIKE 'listener' or cert_type LIKE 'deviceca'),
    valid_from DATE,
    valid_to DATE,
    active BOOLEAN DEFAULT FALSE,
    metadata VARCHAR(2048),
    reference BIGINT,
    id BIGINT NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

CREATE TABLE device_log_info (
        token_id VARCHAR (64) NOT NULL UNIQUE,
        token_req_time TIMESTAMPTZ DEFAULT now(),
        status int NOT NULL,
        metadata text,
        PRIMARY KEY(token_id)
);

CREATE TABLE enrollment_profile
(
name VARCHAR(128) NOT NULL UNIQUE,
description text,
whencreated timestamp without time zone DEFAULT now(),
whenupdated timestamp without time zone DEFAULT now(),
id BIGINT NOT NULL UNIQUE ,
PRIMARY KEY (id)
);

CREATE TABLE enrollment_profile_details
(
property_key VARCHAR(128) NOT NULL,
property_value text,
ep_id bigint NOT NULL,
id BIGINT NOT NULL UNIQUE ,
UNIQUE ( ep_id, property_key),
PRIMARY KEY (id),
FOREIGN KEY (ep_id) REFERENCES enrollment_profile (id) ON DELETE CASCADE
);

CREATE TABLE delivery_group_enrollment_profile
(
dg_id BIGINT NOT NULL,
ep_id BIGINT NOT NULL,
UNIQUE (dg_id, ep_id),
id BIGINT NOT NULL UNIQUE ,
PRIMARY KEY (id),
FOREIGN KEY (ep_id) REFERENCES enrollment_profile(id) ON DELETE CASCADE
);



-- -----------------------------------------------------
-- TABLE:certificate_chain_association
-- this table is used to keep track of certificate chains
-- note that position field is used in order to properly
-- assemble certificate chain (some tools require a proper
-- sequence of certificate chains e.g. first CA, then signed
-- cert.1 then cert.2 signed by cert.1, etc.
-- -----------------------------------------------------
CREATE TABLE certificate_chain_association (
    ssl_cert_id BIGINT NOT NULL,
    certificate_id BIGINT NOT NULL,
    position INTEGER NOT NULL,
    id BIGINT NOT NULL UNIQUE,
    PRIMARY KEY (id),
    FOREIGN KEY (ssl_cert_id) REFERENCES certificate (id) ON DELETE CASCADE,
    FOREIGN KEY (certificate_id) REFERENCES certificate (id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- TABLE:database_schema_version
-- -----------------------------------------------------
CREATE TABLE database_schema_version (
    major int NOT NULL,
    minor int NOT NULL,
    PRIMARY KEY(major, minor)
);

CREATE TABLE versions (
    id INTEGER NOT NULL UNIQUE CHECK(id = 0),
    version_schema VARCHAR(16) NOT NULL,
    version_config VARCHAR(32) DEFAULT NULL,
    revision BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY(id)
);

CREATE TABLE sc_revisions (
    name VARCHAR(20) NOT NULL CHECK (name LIKE 'icons' OR name LIKE 'mobileapps' OR name LIKE 'certs' OR name LIKE 'branding'),
    last_updated TIMESTAMPTZ DEFAULT now(),
    revision BIGINT NOT NULL DEFAULT 0,
    id BIGINT NOT NULL UNIQUE ,
    PRIMARY KEY(id)
);

CREATE TABLE access_gateway (
    url VARCHAR(1024) NOT NULL UNIQUE,
    display_name VARCHAR(512) NOT NULL UNIQUE,
    default_gateway BOOLEAN NOT NULL DEFAULT FALSE,
    logon_type VARCHAR(20) NOT NULL DEFAULT 'Domain' CHECK (logon_type LIKE 'Domain' OR logon_type LIKE 'RSA' OR logon_type LIKE 'DomainAndRSA'
      OR logon_type LIKE 'Cert' OR logon_type LIKE 'CertAndDomain' OR logon_type LIKE 'CertAndRSA'),
    ag_no_password BOOLEAN NOT NULL DEFAULT FALSE,
    alias VARCHAR(1024),
    is_cloud BOOLEAN NOT NULL DEFAULT FALSE,
    id BIGINT NOT NULL UNIQUE ,
    PRIMARY KEY(id)
);

CREATE TABLE ag_callback (
    ag_id BIGINT NOT NULL,
    callback_host VARCHAR(1024) NOT NULL,
    callback_port int NOT NULL DEFAULT 443,
    callback_secure BOOLEAN NOT NULL DEFAULT TRUE,
    callback_path VARCHAR(1024) NOT NULL DEFAULT '/CitrixAuthService/AuthService.asmx',
    callback_vip VARCHAR(32),
    id BIGINT NOT NULL UNIQUE,
    PRIMARY KEY(id),
    FOREIGN KEY (ag_id) REFERENCES access_gateway (id) ON DELETE CASCADE
);

-- formerly cluster table
CREATE TABLE auth_settings (
    name VARCHAR(64) NOT NULL,
    secure BOOLEAN DEFAULT FALSE NOT NULL,
    ticket_ttl INTEGER NOT NULL DEFAULT 100,
    session_token_ttl INTEGER NOT NULL DEFAULT 604800,
    wsf_auth BOOLEAN DEFAULT FALSE,
    wsf_enable BOOLEAN DEFAULT FALSE,
    ag_enable BOOLEAN DEFAULT FALSE,
    wsf_host VARCHAR(256) NOT NULL DEFAULT '',
    wsf_port INT NOT NULL DEFAULT 443,
    account_update_server VARCHAR(256) NOT NULL DEFAULT '',
    account_update_type VARCHAR(30) NOT NULL DEFAULT 'none' CHECK (account_update_type LIKE 'none' OR account_update_type LIKE 'citrix' OR account_update_type LIKE 'CitrixInstallOnly' OR account_update_type LIKE 'MerchandisingServer'),
    save_password BOOLEAN DEFAULT FALSE,
    id INTEGER NOT NULL UNIQUE CHECK(id = 0) DEFAULT 0,
    PRIMARY KEY(id)
);

CREATE TABLE user_apps_subscriptions (
    name VARCHAR(64),
    sid VARCHAR(64),
    data VARCHAR(1024) NOT NULL,
    id BIGINT NOT NULL UNIQUE ,
    subscriptionStatus VARCHAR(64) NOT NULL,
    managed BOOLEAN DEFAULT FALSE,
    PRIMARY KEY(id)
);
CREATE INDEX ON user_apps_subscriptions(sid);

CREATE TABLE applications
(
  name VARCHAR(256) NOT NULL UNIQUE,
  app_type VARCHAR(20) NOT NULL CHECK (app_type LIKE 'mobile_ios' OR app_type LIKE 'mobile_macosx' OR app_type LIKE 'mobile_android' OR app_type LIKE 'mobile_android_knox' OR app_type LIKE 'mobile_android_work' OR app_type LIKE 'mobile_windows' OR app_type LIKE 'mobile_windows8' OR app_type LIKE 'mobile_rpi'
    OR app_type LIKE 'web_link' OR app_type LIKE 'fmd' OR app_type LIKE 'sas' OR app_type LIKE 'sas_ent' OR app_type LIKE 'mobile_windows_ce'),
  subdomain VARCHAR(256) DEFAULT NULL,
  displayname VARCHAR(256) NOT NULL,
  disabled BOOLEAN NOT NULL DEFAULT FALSE,
  pkg_uuid VARCHAR(128) NOT NULL UNIQUE,
  id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY (id)
);

-- Table: app_pkg_info
--- This table contains the metadata from mobile app Manifest
--- UUID generated from admin api will be part of this table
--- More columns might be added here depending on requirement changes
--- This is the table which should be updated in the last operation ( end ).
--- Our replication mechanism will listen to notifications from this table to decide on rsync replication.
CREATE TABLE app_pkg_info
(
  app_pkg_id bigint NOT NULL,
  target_os VARCHAR(32) NOT NULL,
  hash VARCHAR(128) NOT NULL,
  app_version VARCHAR(64),
  minplatform VARCHAR(32),
  maxplatform VARCHAR(32),
  excludedevicetypes VARCHAR(1024),
  PRIMARY KEY (app_pkg_id),
  FOREIGN KEY (app_pkg_id) REFERENCES applications(id) ON DELETE CASCADE
);

-- Table: app_settings
-- This table contains the key value pair for the policy settings
-- Here value could contain whole xml file of policies
CREATE TABLE app_settings
(
  app_settings_key VARCHAR(128) NOT NULL,
  value text,
  app_id bigint NOT NULL,
  id BIGINT NOT NULL UNIQUE ,
  UNIQUE (app_id, app_settings_key),
  PRIMARY KEY (id),
  FOREIGN KEY (app_id) REFERENCES applications (id) ON DELETE CASCADE
);

CREATE TABLE appsettingsui
(
  appsettingsui_key VARCHAR(128) NOT NULL,
  value text,
  appsettingsui_usage VARCHAR(16) DEFAULT NULL,
  datatype VARCHAR(64) DEFAULT NULL,
  app_id bigint NOT NULL,
  id BIGINT NOT NULL UNIQUE ,
  UNIQUE (app_id, appsettingsui_key),
  PRIMARY KEY (id),
  FOREIGN KEY (app_id) REFERENCES applications (id) ON DELETE CASCADE
);

-- Table: app_file
-- This table contains name of the files related to mobile app, whole path is derived from uuid.
CREATE TABLE app_file
(
  app_file_id bigint NOT NULL,
  file_type VARCHAR(5) NOT NULL DEFAULT 'png' CHECK (file_type LIKE 'ico' OR file_type LIKE 'png' OR file_type LIKE 'gif'),
  name VARCHAR(512) NOT NULL,
  xres INTEGER,
  yres INTEGER,
  id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY (id),
  FOREIGN KEY (app_file_id) REFERENCES applications (id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- this table stores device information
-- -----------------------------------------------------
CREATE TABLE devices
(
  device_id VARCHAR(512) NOT NULL UNIQUE,
  device_token VARCHAR(1024) NOT NULL UNIQUE,
  table_id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY (table_id)
);
-- -----------------------------------------------------
-- TABLE:devices2users
-- this table stores device to users information
-- -----------------------------------------------------
CREATE TABLE devices2users
(
  device_id VARCHAR(1024) NOT NULL,
  deprovisioned BOOLEAN NOT NULL DEFAULT FALSE,
  device_user_id BIGINT,
  table_id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY (table_id),
  table_id2 BIGINT NOT NULL,
  FOREIGN KEY (table_id2) REFERENCES devices(table_id) ON DELETE CASCADE
);
CREATE INDEX ON devices2users(device_id);

-- -----------------------------------------------------
-- TABLE:device_access_data
-- this table stores device last logon time
-- -----------------------------------------------------
CREATE TABLE device_access_data (
  device_id VARCHAR(1024) NOT NULL UNIQUE,
  device_ip VARCHAR(256),
  last_logon timestamp,
  id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY (id),
  d_id bigint NOT NULL,
  FOREIGN KEY (d_id) REFERENCES devices(table_id) ON DELETE CASCADE
);

CREATE TABLE xenvault_secret
(
  xvs_user_id VARCHAR(1024) NOT NULL,
  device_id VARCHAR(512) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  vault_name VARCHAR(1024) NOT NULL,
  vault_number SMALLINT NOT NULL,
  secret VARCHAR(1024) NOT NULL,
  id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY(id)
);
CREATE INDEX ON xenvault_secret(xvs_user_id);
CREATE INDEX xenvault_secret_device_id_idx ON xenvault_secret USING btree (device_id COLLATE pg_catalog."default");

CREATE TABLE sta_tickets (
    ticket_id VARCHAR(1024) NOT NULL UNIQUE,
    expiration_time BIGINT NOT NULL,
    device_id VARCHAR(512) REFERENCES devices(device_id) ON DELETE CASCADE,
    sta_user_id VARCHAR(1024),
    mobile_app_id VARCHAR(1024) REFERENCES applications(name) ON DELETE CASCADE,
    id BIGINT NOT NULL UNIQUE ,
    use_cc_sta BOOLEAN NOT NULL DEFAULT FALSE ,
    PRIMARY KEY(id)
);
CREATE INDEX sta_expiration_index ON sta_tickets (expiration_time);

CREATE TABLE pnaserver
(
    CONNECTOR_SERVER_NAME VARCHAR(256) DEFAULT NULL,
    CONNECTOR_RESOURCE_LOCATION VARCHAR(256) DEFAULT NULL,
    host VARCHAR(512) NOT NULL UNIQUE,
    port INTEGER NOT NULL,
    path VARCHAR(1024) NOT NULL,
    secure BOOLEAN NOT NULL DEFAULT FALSE,
    refresh_in_minutes INTEGER NOT NULL DEFAULT 0,
    id BIGINT NOT NULL UNIQUE ,
    PRIMARY KEY (id)
);

------------------------------------------------------------------------------
-- Table account
-- This table contains AppC account information.
-- There is only one account per AppC, hence this table will have a single row.
-------------------------------------------------------------------------------
CREATE TABLE account
(
 id BIGINT NOT NULL UNIQUE ,
 account_id BIGINT NOT NULL UNIQUE,
 name VARCHAR(256) NOT NULL DEFAULT 'Store',
 description VARCHAR(1024) DEFAULT 'Store',
 PRIMARY KEY (id)
);

CREATE TABLE store_credentials
(
  store VARCHAR(10) NOT NULL CHECK (store LIKE 'google' OR store LIKE 'amazon'),
  username VARCHAR(256) DEFAULT NULL,
  password VARCHAR(256) DEFAULT NULL,
  device_id VARCHAR(128) NOT NULL UNIQUE,
  id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY (id)
);

-----------------------------------------------------------------------------
-- Table store
-- This table contains the store information.
-- There is one account per AppC and for each account there is a single store.
-- Each store is linked to a beacon table for beacons for the AppC.
-------------------------------------------------------------------------------
CREATE TABLE store
(
  store_name VARCHAR(128) NOT NULL DEFAULT 'Store',
  store_id VARCHAR(128) NOT NULL UNIQUE ,
  account_id BIGINT NOT NULL,
  description VARCHAR(1024) DEFAULT 'Store',
  use_appc_intbeacon BOOLEAN NOT NULL DEFAULT TRUE,
  use_ag_extbeacon BOOLEAN NOT NULL DEFAULT TRUE,
  id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY (id),
  FOREIGN KEY (account_id) REFERENCES account (account_id) ON DELETE CASCADE
);

-----------------------------------------------------------------------------------
-- Table beacon
-- This table contains beacons information.
-- Beacons can be internal or external
------------------------------------------------------------------------------------
CREATE TABLE beacon
(
  name VARCHAR(256) NOT NULL,
  beacon_type VARCHAR(20) NOT NULL CHECK (beacon_type LIKE 'internal' OR beacon_type LIKE 'external'),
  b_order INTEGER NOT NULL DEFAULT 0,
  store_id VARCHAR(256) NOT NULL,
  id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY(id),
  FOREIGN KEY (store_id) REFERENCES store (store_id) ON DELETE CASCADE
);

-- Property bag configuration. This is used to support GTA
CREATE TABLE account_properties
(
    display_name VARCHAR(128) NOT NULL,
    description VARCHAR(1024),
    acc_properties_key VARCHAR(128) NOT NULL UNIQUE,
    value VARCHAR(1024) DEFAULT NULL,
    readOnly BOOLEAN DEFAULT FALSE,
    id BIGINT NOT NULL UNIQUE ,
    PRIMARY KEY (id),
    advertise_mode VARCHAR(16) NOT NULL DEFAULT 'ALL' CHECK (advertise_mode  IN('GSI', 'AP', 'ALL')),
    is_visible BOOLEAN DEFAULT TRUE NOT NULL
);

CREATE TABLE acc_service_plugin (
    plugin_id UUID NOT NULL UNIQUE,
    description VARCHAR(1024),
    plugin_used BOOLEAN DEFAULT FALSE NOT NULL,
    id BIGINT NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE system_shared (
    notify_port INTEGER NOT NULL DEFAULT 9002,
    ticket_ttl INTEGER NOT NULL DEFAULT 100,
    session_token_ttl INTEGER NOT NULL DEFAULT 28800,
    virtual_ag_id UUID DEFAULT NULL,
    hostname VARCHAR(256) NOT NULL,
    fips_mode BOOLEAN DEFAULT FALSE NOT NULL,
    ssl_listener_certificate BIGINT NOT NULL,
    ssl_offloading_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    hazelcast_port_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    sta_id BIGINT NOT NULL UNIQUE,
    database_id INTEGER NOT NULL DEFAULT 0,
    id INTEGER NOT NULL UNIQUE CHECK(id = 0),
    PRIMARY KEY(id)
);

CREATE TABLE system_status (
    task VARCHAR(16) DEFAULT 'FBC' NOT NULL CHECK (task LIKE 'FBC' OR task LIKE 'UPGRADE'),
    owner VARCHAR(256),
    status VARCHAR(16) DEFAULT 'NotInited' NOT NULL CHECK (status LIKE 'NotInited' OR status LIKE 'InProgress' OR status LIKE 'InitDone'),
    start_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    end_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    current_step VARCHAR(256),
    id BIGINT NOT NULL UNIQUE,
    PRIMARY KEY(id)
);

-- This is used internally.
INSERT INTO database_schema_version VALUES(10, 57);

---Stocktake that stored device info and installed apps on the device
CREATE TABLE store_stocktake
(
   uid VARCHAR(512) NOT NULL,
   deviceId VARCHAR(512) NOT NULL,
   deviceOS VARCHAR(512) NOT NULL,
   deviceOSVer VARCHAR(512),
   deviceModel VARCHAR(512),
   installedApps bytea,
   PRIMARY KEY(uid, deviceId)
);

-- store_app_rating: for store social work, store user app rating
CREATE TABLE store_app_rating
(
  appName VARCHAR(256) NOT NULL,
  uid VARCHAR(512) NOT NULL,
  appver VARCHAR(256) NOT NULL,
  toolver VARCHAR(256) NOT NULL,
  rating float NOT NULL DEFAULT 0,
  commentstime BIGINT,
  comments bytea,
  headline VARCHAR(256),
  disabled BOOLEAN NOT NULL DEFAULT FALSE,
  platform VARCHAR(256),
  device VARCHAR(1024),
  device_id VARCHAR(1024),
  anonymous BOOLEAN NOT NULL DEFAULT FALSE,
  id BIGINT NOT NULL UNIQUE ,
  UNIQUE (uid, appName),
  PRIMARY KEY (id)
);

-- store_app_avgrating:
CREATE TABLE store_app_avgrating
(
  appName VARCHAR(256) NOT NULL UNIQUE,
  avgrating float NOT NULL DEFAULT 0,
  countreviewer BIGINT NOT NULL DEFAULT 0,
  detail VARCHAR(256),
  id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY (id)
);

---store_app_rating_history: for store social work, store all activities that user rate/review
CREATE TABLE store_app_rating_history
(
  appName VARCHAR(256) NOT NULL,
  uid VARCHAR(512) NOT NULL,
  appver VARCHAR(256) NOT NULL,
  toolver VARCHAR(256) NOT NULL,
  rating float NOT NULL DEFAULT 0,
  commentstime BIGINT,
  comments bytea,
  headline VARCHAR(256),
  platform VARCHAR(256),
  device VARCHAR(1024),
  device_id VARCHAR(1024),
  anonymous BOOLEAN NOT NULL DEFAULT FALSE,
  id BIGINT NOT NULL UNIQUE ,
  PRIMARY KEY (id)
);

---store_app_faq: for store social work, store faq for each app, adminui will post faq
CREATE TABLE store_app_faq(
  appName VARCHAR(256) NOT NULL,
  displayOrder int NOT NULL DEFAULT 0,
  question VARCHAR(1024) NOT NULL,
  answer VARCHAR(1024) NOT NULL,
  id BIGINT NOT NULL UNIQUE,
  PRIMARY KEY(id)
);

---store_content: for store content includes image, css ...
CREATE TABLE store_content(
  contentType VARCHAR(256) NOT NULL,
  data bytea,
  id BIGINT NOT NULL UNIQUE,
  PRIMARY KEY(id)
);

---store_app_screenshot: for store social work, store screenshots for each app, adminui will post faq
CREATE TABLE store_app_screenshot(
  appName VARCHAR(256) NOT NULL,
  displayOrder int NOT NULL DEFAULT 0,
  path VARCHAR(1024) NOT NULL,
  id BIGINT NOT NULL UNIQUE,
  contentId BIGINT NOT NULL,
  PRIMARY KEY(id),
  FOREIGN KEY (contentId) REFERENCES store_content(id) ON DELETE CASCADE
);

---store_branding: for store branding info
CREATE TABLE store_branding(
  device VARCHAR(256) NOT NULL,
  name VARCHAR(256) NOT NULL,
  contentId BIGINT NOT NULL,
  id BIGINT NOT NULL UNIQUE,
  PRIMARY KEY(id),
  FOREIGN KEY (contentId) REFERENCES store_content(id) ON DELETE CASCADE
);

-- store licensing server information
-- license_type specifies the license type to use; 'none' mean no license type is selected
-- lic_checkout_cache_lifetime specifies how long to cache license check out result, in seconds
-- lic_inventory_cache_lifetime specifies how long to cache license inventory list, in seconds
-- test_connectivity_timeout specifies timeout value in testing connectivity to remote licensing server, in seconds
CREATE TABLE licensing_server (
  server_type VARCHAR(16) NOT NULL DEFAULT 'local' CHECK (server_type LIKE 'local' OR server_type LIKE 'remote'),
  server_configured BOOLEAN DEFAULT FALSE,
  remote_address VARCHAR(512),
  remote_port INTEGER DEFAULT 27000 NOT NULL,
  license_type VARCHAR(16) DEFAULT 'none' CHECK (license_type LIKE 'none' OR license_type LIKE 'CXM_ENTU_UD' OR license_type LIKE 'CXM_ENTD_UD' OR license_type LIKE 'CXM_STDU_UD' OR license_type LIKE 'CXM_STDD_UD' OR license_type LIKE 'CXM_MAMU_UD' OR license_type LIKE 'CXM_MAMD_UD'),
  lic_checkout_cache_lifetime INTEGER NOT NULL DEFAULT 86400 CHECK (lic_checkout_cache_lifetime <= 86400),
  lic_inventory_cache_lifetime INTEGER NOT NULL DEFAULT 3600 CHECK (lic_inventory_cache_lifetime <= 86400),
  test_connectivity_timeout INTEGER NOT NULL DEFAULT 5 CHECK (test_connectivity_timeout <= 60),
  id BIGINT NOT NULL UNIQUE,
  server_port INTEGER DEFAULT 8083 NOT NULL,
  PRIMARY KEY(id)
);

-- stores per user license check out information
CREATE TABLE license_user_info (
    user_id BIGINT NOT NULL UNIQUE,
    last_check_out_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    check_out_profile VARCHAR(512) NOT NULL,
    license_type VARCHAR(16) NOT NULL CHECK (license_type LIKE 'CXM_ENTU_UD' OR license_type LIKE 'CXM_ENTD_UD' OR license_type LIKE 'CXM_STDU_UD' OR license_type LIKE 'CXM_STDD_UD' OR license_type LIKE 'CXM_MAMU_UD' OR license_type LIKE 'CXM_MAMD_UD'),
    id BIGINT NOT NULL UNIQUE,
    PRIMARY KEY(id)
);

-- stores per device license check out information
CREATE TABLE license_device_info (
    device_id VARCHAR(512) NOT NULL UNIQUE,
    mode VARCHAR(16) NOT NULL CHECK (mode LIKE 'MAM' OR mode LIKE 'MDM'),
    last_check_out_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    check_out_profile VARCHAR(512) NOT NULL,
    license_type VARCHAR(16) NOT NULL CHECK (license_type LIKE 'CXM_ENTU_UD' OR license_type LIKE 'CXM_ENTD_UD' OR license_type LIKE 'CXM_STDU_UD' OR license_type LIKE 'CXM_STDD_UD' OR license_type LIKE 'CXM_MAMU_UD' OR license_type LIKE 'CXM_MAMD_UD'),
    id BIGINT NOT NULL UNIQUE,
    PRIMARY KEY(id)
);

-- stores licensing notifcation information
CREATE TABLE license_notification (
	id BIGINT NOT NULL PRIMARY KEY,
	notification_enabled BOOLEAN NOT NULL DEFAULT FALSE,
	notify_frequency INTEGER DEFAULT 7,			-- frequency of notification in days
	notify_number_days_before_expire INTEGER DEFAULT 60,
	recepient_list VARCHAR(1024),
	email_content TEXT
);

-- stores the licenses that need to be released from the license server when license server is not reachable.
CREATE TABLE license_delete (
	id BIGINT NOT NULL PRIMARY KEY,
	check_out_profile VARCHAR(512) NOT NULL
);

-- store web proxy, syslog and other system settings.
CREATE TABLE system_settings (
	id BIGINT NOT NULL PRIMARY KEY,
	category VARCHAR(32),
	value TEXT,
	site_name VARCHAR(255),
	CONSTRAINT uniq_site_category UNIQUE(category, site_name)
);

-- worxstore table
CREATE TABLE worxstore (
	id BIGINT NOT NULL PRIMARY KEY,
	worxstore_key VARCHAR(255) NOT NULL,
	worxstore_value VARCHAR(255) NOT NULL
);

-- system_files table which stores system files like device certificates
CREATE TABLE system_files (
	id BIGINT NOT NULL PRIMARY KEY,
	name VARCHAR(255) NOT NULL UNIQUE,
	content BYTEA NOT NULL,
	type VARCHAR(32)
);

-- app_ott table which stores one time tickets for application download
CREATE SEQUENCE "ONETIME_TICKET_ID_SEQ" ;

CREATE TABLE app_ott (
	id BIGINT PRIMARY KEY DEFAULT NEXTVAL('"ONETIME_TICKET_ID_SEQ"'),
	appname VARCHAR(255) NOT NULL,
	ott_expirytime BIGINT NOT NULL,
	onetimetoken VARCHAR(255) NOT NULL
);


-- Tables for AuthTracker for XMS WebServices --


CREATE TABLE "WSAUTHTRACKER"
(
  "ID" BIGINT NOT NULL PRIMARY KEY,
  "USERNAME" VARCHAR(255) NOT NULL,
  "IPADDRESS" VARCHAR(255) NOT NULL,
  "TOKENTYPE" VARCHAR(50) NOT NULL,
  "TIMESTAMP" timestamp without time zone NOT NULL DEFAULT now(),
  "SALT" VARCHAR(255) NOT NULL,
  "HASHVALUE" VARCHAR(255) NOT NULL
);

-- Tables for Telemetry Collector status --

CREATE SEQUENCE "DATAPOINTSEQUENCE";

CREATE TABLE "TELEMETRY_DATAPOINTS" (
	"ID" BIGINT NOT NULL DEFAULT NEXTVAL('"DATAPOINTSEQUENCE"') PRIMARY KEY,
	"TIMESTAMP" TIMESTAMPTZ NOT NULL,
	"COLLECTIONDATE" VARCHAR(64) NOT NULL,
	"CLUSTERID" VARCHAR(64) NOT NULL,
	"DATAPOINT" VARCHAR (511) NOT NULL,
	"RESULT"  TEXT NOT NULL
);

CREATE SEQUENCE "COLLECTORSTATUSSEQUENCE";
CREATE TABLE "TELEMETRY_COLLECTOR_STATUS" (
	"ID" BIGINT NOT NULL DEFAULT NEXTVAL('"COLLECTORSTATUSSEQUENCE"') PRIMARY KEY,
	"NAME" VARCHAR (255) NOT NULL,
	"CLUSTERID" VARCHAR(64) NOT NULL,
	"FREQUENCY" VARCHAR (10) NOT NULL,
	"FREQUENCYUNIT" VARCHAR(10) NOT NULL,
	"OWNER" VARCHAR (32) NOT NULL,
	"TYPE" VARCHAR (32),
	"EXECUTABLE" VARCHAR (255),
	"INPUTARGS" VARCHAR (1024),
	"TARGET" VARCHAR (32),
	"LASTRUN" TIMESTAMPTZ,
	"STATUSOFLASTRUN" INTEGER NOT NULL
);

-- NSGCONFIG SCRIPT GENERATION TABLES
CREATE SEQUENCE "NSGCOMMANDGROUP_SEQUENCE";
CREATE TABLE "ns_script_commandgroup" (
	"id" BIGINT NOT NULL DEFAULT NEXTVAL('"NSGCOMMANDGROUP_SEQUENCE"') PRIMARY KEY,
	"command_name" varchar(128) NOT NULL,
	"command_group" varchar(128) NOT NULL,
	"deployment_ent" INTEGER DEFAULT 1,
	"deployment_mam" INTEGER DEFAULT 0,
	"deployment_mdm" INTEGER DEFAULT 0,
	"on_prem" INTEGER DEFAULT 1,
	"on_cloud" INTEGER DEFAULT 0,
	"logon_category" varchar(128) NOT NULL
);

CREATE SEQUENCE "NSGCOMMAND_SEQUENCE";
CREATE TABLE "ns_script_commands" (
	"id" BIGINT NOT NULL DEFAULT NEXTVAL('"NSGCOMMAND_SEQUENCE"') PRIMARY KEY,
	"command_name" varchar(128) NOT NULL,
	"command_string" varchar(1024) NOT NULL,
	"command_group" varchar(128) NOT NULL,
	"command_comment" varchar(1024) DEFAULT NULL,
	"rank" INTEGER NOT NULL,
	"ns_min_version" varchar(10) NOT NULL DEFAULT '10.1'
);

-- -----------------------------------------------------
-- INDEXES FOR FOREIGN KEY REFERENCES
-- -----------------------------------------------------
CREATE INDEX ag_callback_ag_id_index ON ag_callback (ag_id);
CREATE INDEX app_file_app_file_id_index ON app_file (app_file_id);
CREATE INDEX beacon_store_id_index ON beacon (store_id);
CREATE INDEX certificate_chain_association_ssl_cert_id_index ON certificate_chain_association (ssl_cert_id);
CREATE INDEX certificate_chain_association_certificate_id_index ON certificate_chain_association (certificate_id);
CREATE INDEX delivery_group_enrollment_profile_ep_id_index ON delivery_group_enrollment_profile (ep_id);
CREATE INDEX device_access_data_d_id_index ON device_access_data (d_id);
CREATE INDEX devices2users_table_id2_index ON devices2users (table_id2);
CREATE INDEX icon_details_sc_id_index ON icon_details (sc_id);
CREATE INDEX sta_tickets_device_id_index ON sta_tickets (device_id);
CREATE INDEX sta_tickets_mobile_app_id_index ON sta_tickets (mobile_app_id);
CREATE INDEX store_app_screenshot_contentId_index ON store_app_screenshot (contentId);
CREATE INDEX store_branding_contentId_index ON store_branding (contentId);

COMMIT;
-- End of MAM tables creation
