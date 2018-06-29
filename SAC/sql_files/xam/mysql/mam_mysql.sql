CREATE TABLE Id_Generator(
  table_name VARCHAR(255) NOT NULL,
  next_id BIGINT NOT NULL,
  CONSTRAINT EWHILO_PKEY_XAM PRIMARY KEY (table_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE static_content (
id bigint not null PRIMARY KEY,
content_hash VARCHAR(128) not null,
type VARCHAR(5) not null,
ref_count INTEGER,
content MEDIUMBLOB,
is_stock BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE icon_details(
id bigint not null PRIMARY KEY,
ref_name VARCHAR(1024) not null,
xres INTEGER not null,
yres INTEGER,
sc_id bigint,
FOREIGN KEY (sc_id) REFERENCES static_content (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- TABLE:info_log_level_type
-- -----------------------------------------------------
CREATE TABLE info_log_level_type (
    id smallint NOT NULL UNIQUE,
    name VARCHAR(32) NOT NULL UNIQUE,
    PRIMARY KEY(id),
    CHECK(id < 7)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- TABLE:debug_log_level_type
-- -----------------------------------------------------
CREATE TABLE debug_log_level_type (
    id smallint NOT NULL UNIQUE,
    name VARCHAR(32) NOT NULL UNIQUE,
    PRIMARY KEY(id),
    CHECK (id < 9)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO debug_log_level_type VALUES(0, 'off');
INSERT INTO debug_log_level_type VALUES(1, 'critical');
INSERT INTO debug_log_level_type VALUES(2, 'error');
INSERT INTO debug_log_level_type VALUES(3, 'warning');
INSERT INTO debug_log_level_type VALUES(4, 'control');
INSERT INTO debug_log_level_type VALUES(5, 'debug4');
INSERT INTO debug_log_level_type VALUES(6, 'debug5');
INSERT INTO debug_log_level_type VALUES(7, 'debug6');
INSERT INTO debug_log_level_type VALUES(8, 'debug7');

INSERT INTO info_log_level_type VALUES(0, 'emergency');
INSERT INTO info_log_level_type VALUES(1, 'alert');
INSERT INTO info_log_level_type VALUES(2, 'critical');
INSERT INTO info_log_level_type VALUES(3, 'error');
INSERT INTO info_log_level_type VALUES(4, 'warning');
INSERT INTO info_log_level_type VALUES(5, 'notice');
INSERT INTO info_log_level_type VALUES(6, 'info');


-- -----------------------------------------------------
-- TABLE:support_serverdetails
-- -----------------------------------------------------
CREATE TABLE support_serverdetails(
    url VARCHAR(128) NOT NULL PRIMARY KEY ,
    username VARCHAR(64) NOT NULL,
    password VARCHAR(512),
    server_type VARCHAR(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- -----------------------------------------------------
-- TABLE:certificate
-- -----------------------------------------------------
CREATE TABLE certificate (
    name VARCHAR(256) NOT NULL,
    description text,
    cert text,
    private_key BLOB,
    cert_type ENUM('ca', 'csr', 'entity', 'chain', 'saml','apns','apnsCsr','listener','deviceca') NOT NULL,
    valid_from DATE,
    valid_to DATE,
    active BOOLEAN DEFAULT FALSE,
    metadata text,
    reference BIGINT,
    id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE device_log_info (
        token_id VARCHAR (64) NOT NULL PRIMARY KEY,
        token_req_time timestamp DEFAULT now(),
        status int NOT NULL,
        metadata TEXT
);

CREATE TABLE enrollment_profile
(
  name VARCHAR(128) NOT NULL UNIQUE,
  description text,
  whencreated timestamp DEFAULT now(),
  whenupdated timestamp DEFAULT now(),
  id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE enrollment_profile_details
(
  property_key VARCHAR(128) NOT NULL,
  property_value text,
  ep_id bigint NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  UNIQUE (ep_id, property_key),
  FOREIGN KEY (ep_id) REFERENCES enrollment_profile (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE delivery_group_enrollment_profile
(
  dg_id BIGINT NOT NULL,
  ep_id BIGINT NOT NULL,
  UNIQUE (dg_id, ep_id),
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (ep_id) REFERENCES enrollment_profile(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


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
 position int NOT NULL,
 id BIGINT NOT NULL PRIMARY KEY,
 FOREIGN KEY (ssl_cert_id) REFERENCES certificate (id) ON DELETE CASCADE,
 FOREIGN KEY (certificate_id) REFERENCES certificate (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- TABLE:database_schema_version
-- -----------------------------------------------------
CREATE TABLE database_schema_version (
    major int NOT NULL,
    minor int NOT NULL,
    PRIMARY KEY(major, minor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- TABLE:versions
-- -----------------------------------------------------
CREATE TABLE versions (
    id int NOT NULL,
    version_schema VARCHAR(16) NOT NULL,
    version_config VARCHAR(32) DEFAULT NULL,
    revision BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY(id),
    CHECK(id = 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- TABLE:sc_revisions
-- -----------------------------------------------------
CREATE TABLE sc_revisions (
    folder_name ENUM ('icons', 'mobileapps', 'certs', 'branding') NOT NULL,
    last_updated timestamp DEFAULT now(),
    revision BIGINT NOT NULL DEFAULT 0,
    id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- -----------------------------------------------------
-- access_gateway (AGEE)
-- -----------------------------------------------------
CREATE TABLE access_gateway (
    url VARCHAR(1024) NOT NULL UNIQUE,
    display_name VARCHAR(512) NOT NULL UNIQUE,
    default_gateway BOOLEAN NOT NULL DEFAULT FALSE,
    logon_type ENUM('Domain', 'RSA', 'DomainAndRSA', 'Cert', 'CertAndDomain', 'CertAndRSA') NOT NULL DEFAULT 'Domain',
    ag_no_password BOOLEAN NOT NULL DEFAULT FALSE,
    alias VARCHAR(1024),
    is_cloud BOOLEAN NOT NULL DEFAULT FALSE,
    id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- -----------------------------------------------------
-- ag_callback
--
-- when there are multiple entries for a given AG, ignore the entry with empty VIP
-- -----------------------------------------------------
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- formerly cluster table
CREATE TABLE auth_settings (
    name VARCHAR(64) NOT NULL,
    secure BOOLEAN DEFAULT FALSE NOT NULL,
    ticket_ttl int NOT NULL DEFAULT 100, -- lifetime of one time tickets for launching apps
    session_token_ttl int NOT NULL DEFAULT 604800, -- maximum lifetime of session tokens, 7 days
    wsf_auth BOOLEAN DEFAULT FALSE, -- whether WSF is acting as an authentication server
    wsf_enable BOOLEAN DEFAULT FALSE, -- whether WSF can be a front store
    ag_enable BOOLEAN DEFAULT FALSE,
    wsf_host VARCHAR(256) NOT NULL DEFAULT '', -- Windows StoreFront FQDN or IP address
    wsf_port INT NOT NULL DEFAULT 443, -- Windows StoreFront port
    account_update_server VARCHAR(256) NOT NULL DEFAULT '', -- Windows StoreFront FQDN or IP address
    account_update_type ENUM('none', 'Citrix', 'CitrixInstallOnly', 'MerchandisingServer') NOT NULL DEFAULT 'none',
    save_password BOOLEAN DEFAULT FALSE,
    id int NOT NULL UNIQUE DEFAULT 0,
    PRIMARY KEY(id),
    CHECK(id = 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- PSQL:get_user_param
-- -----------------------------------------------------
CREATE TABLE user_apps_subscriptions
(
    name VARCHAR(64) UNIQUE NOT NULL,
    sid VARCHAR(64),
    data text NOT NULL,
    id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE INDEX user_apps_subscriptions_index ON user_apps_subscriptions(sid);

-- Table: applications
-- This table contains the unique internal name returned by Apere/ Mobile app API
-- Contains the type of application
CREATE TABLE applications
(
  name VARCHAR(256) NOT NULL UNIQUE,
  app_type ENUM('mobile_ios', 'mobile_macosx', 'mobile_android', 'mobile_android_knox', 'mobile_android_work', 'mobile_windows', 'mobile_windows8', 'web_link', 'fmd', 'sas', 'sas_ent', 'mobile_windows_ce','mobile_rpi') NOT NULL,
  subdomain VARCHAR(256) DEFAULT NULL,
  displayname VARCHAR(256) NOT NULL,
  disabled BOOLEAN NOT NULL DEFAULT FALSE,
  pkg_uuid VARCHAR(128) NOT NULL UNIQUE,
  id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- Table: app_pkg_info
-- This table contains the metadata from mobile app Manifest
-- UUID generated from admin api will be part of this table
-- More columns might be added here depending on requirement changes
-- This is the table which should be updated in the last operation ( end ).
-- Our replication mechanism will listen to notifications from this table to decide on rsync replication.
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Table: app_settings
-- This table contains the key value pair for the policy settings
-- Here value could contain whole xml file of policies
CREATE TABLE app_settings
(
  app_settings_key VARCHAR(128) NOT NULL,
  value text,
  app_id bigint NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  UNIQUE (app_id, app_settings_key),
  FOREIGN KEY (app_id) REFERENCES applications (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE appsettingsui
(
  appsettingsui_key VARCHAR(128) NOT NULL,
  value mediumtext,
  appsettingsui_usage VARCHAR(16) DEFAULT NULL,
  datatype VARCHAR(64) DEFAULT NULL,
  app_id bigint NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  UNIQUE (app_id, appsettingsui_key),
  FOREIGN KEY (app_id) REFERENCES applications (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Table: app_file
-- This table contains name of the files related to mobile app, whole path is derived from uuid.
CREATE TABLE app_file
(
  app_file_id bigint NOT NULL,
  file_type ENUM('ico', 'png', 'gif', 'pkg') NOT NULL DEFAULT 'png',
  name VARCHAR(512) NOT NULL,
  xres int,
  yres int,
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (app_file_id) REFERENCES applications (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- this table stores device information
-- -----------------------------------------------------
CREATE TABLE devices
(
  device_id varchar(512) NOT NULL UNIQUE,
  device_token VARCHAR(1024) NOT NULL,
  table_id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- -----------------------------------------------------
-- TABLE:devices2users
-- this table stores device to users information
-- -----------------------------------------------------
CREATE TABLE devices2users
(
  device_id varchar(512) NOT NULL,
  deprovisioned BOOLEAN NOT NULL DEFAULT FALSE,
  device_user_id BIGINT,
  table_id BIGINT NOT NULL PRIMARY KEY,
  table_id2 BIGINT NOT NULL,
  FOREIGN KEY (table_id2) REFERENCES devices(table_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
CREATE INDEX device2users_index ON devices2users(device_id);

-- -----------------------------------------------------
-- TABLE:device_access_data
-- this table stores device last logon time
-- -----------------------------------------------------
CREATE TABLE device_access_data (
  device_id varchar(512) NOT NULL UNIQUE,
  device_ip VARCHAR(256),
  last_logon datetime,
  id BIGINT NOT NULL PRIMARY KEY,
  d_id bigint NOT NULL,
  FOREIGN KEY (d_id) REFERENCES devices(table_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

CREATE TABLE xenvault_secret
(
  xvs_user_id varchar(256) NOT NULL,
  device_id varchar(512) NOT NULL,
  vault_name VARCHAR(1024) NOT NULL,
  vault_number SMALLINT NOT NULL,
  secret text NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
CREATE INDEX xenvault_secret_index ON xenvault_secret(xvs_user_id);

CREATE TABLE sta_tickets (
    ticket_id VARCHAR(1024) NOT NULL,
    expiration_time BIGINT NOT NULL,
    device_id varchar(512),
    sta_user_id VARCHAR(1024),
    mobile_app_id varchar(256),
    id BIGINT NOT NULL PRIMARY KEY,
    use_cc_sta BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (mobile_app_id) REFERENCES applications(name) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
CREATE INDEX sta_expiration_index ON sta_tickets (expiration_time);
ALTER TABLE sta_tickets ADD CONSTRAINT unique_sta_ticket_id UNIQUE (ticket_id);

-- PNA server configuration
CREATE TABLE pnaserver
(
    CONNECTOR_SERVER_NAME VARCHAR(256) DEFAULT NULL,
    CONNECTOR_RESOURCE_LOCATION VARCHAR(256) DEFAULT NULL,
    host VARCHAR(512) NOT NULL UNIQUE,
    port int NOT NULL,
    path VARCHAR(1024) NOT NULL,
    secure BOOLEAN NOT NULL DEFAULT FALSE,
    refresh_in_minutes int NOT NULL DEFAULT 0,
    id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------------------------------------------------------
-- Table account
-- This table contains AppC account information.
-- There is only one account per AppC, hence this table will have a single row.
-- -----------------------------------------------------------------------------
CREATE TABLE account
(
 id BIGINT NOT NULL PRIMARY KEY,
 account_id BIGINT NOT NULL UNIQUE,
 name VARCHAR(256) NOT NULL DEFAULT 'Store',
 description varchar(512) DEFAULT 'Store'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE store_credentials
(
  store ENUM('google', 'amazon') NOT NULL,
  username VARCHAR(256) DEFAULT NULL,
  password VARCHAR(256) DEFAULT NULL,
  device_id VARCHAR(512) NOT NULL UNIQUE,
  id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ---------------------------------------------------------------------------
-- Table store
-- This table contains the store information.
-- There is one account per AppC and for each account there is a single store.
-- Each store is linked to a beacon table for beacons for the AppC.
-- -----------------------------------------------------------------------------
CREATE TABLE store
(
 store_name VARCHAR(128) NOT NULL DEFAULT 'Store',
 store_id VARCHAR(128) NOT NULL UNIQUE  ,
 account_id BIGINT NOT NULL,
 description varchar(512) DEFAULT 'Store',
 use_appc_intbeacon BOOLEAN NOT NULL DEFAULT TRUE,
 use_ag_extbeacon BOOLEAN NOT NULL DEFAULT TRUE,
 id BIGINT NOT NULL PRIMARY KEY,
 FOREIGN KEY (account_id) REFERENCES account (account_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ---------------------------------------------------------------------------------
-- Table beacon
-- This table contains beacons information.
-- Beacons can be internal or external
-- ----------------------------------------------------------------------------------
CREATE TABLE beacon
(
  name VARCHAR(256) NOT NULL,
  beacon_type ENUM('internal', 'external') NOT NULL,
  b_order int NOT NULL DEFAULT 0,
  store_id VARCHAR(128) NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (store_id) REFERENCES store (store_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Property bag configuration. This is used to support GTA
CREATE TABLE account_properties
(
    display_name VARCHAR(128) NOT NULL, -- Display name on CP
    description text,
    acc_properties_key VARCHAR(128) NOT NULL UNIQUE,
    value text DEFAULT NULL,
    readOnly BOOLEAN DEFAULT FALSE, -- For future use
    id BIGINT NOT NULL PRIMARY KEY, -- random_salt()
    advertise_mode VARCHAR(16) NOT NULL DEFAULT 'ALL' CHECK (advertise_mode  IN('GSI', 'AP', 'ALL')),
    is_visible BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE acc_service_plugin (
    plugin_id VARCHAR(128) NOT NULL UNIQUE,
    description VARCHAR(1024),
    plugin_used BOOLEAN DEFAULT FALSE NOT NULL,
    id BIGINT NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE system_shared (
    notify_port int NOT NULL DEFAULT 9002,
    ticket_ttl int NOT NULL DEFAULT 100, -- lifetime of one time tickets for launching apps
    session_token_ttl int NOT NULL DEFAULT 28800, -- lifetime of session tokens, 8 hours
    virtual_ag_id varchar(128) DEFAULT NULL,
    hostname VARCHAR(256) NOT NULL, -- this was in fqdn table before
    fips_mode BOOLEAN DEFAULT FALSE NOT NULL,
    ssl_listener_certificate BIGINT NOT NULL, -- this is active certificate used by our SSL Listener
    ssl_offloading_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    hazelcast_port_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    sta_id BIGINT NOT NULL UNIQUE, -- If we interpret 64 bit number as hex then it satifies 16 max character restriction for STA ID
    database_id int NOT NULL DEFAULT 0,
    id INTEGER NOT NULL UNIQUE,
    PRIMARY KEY(id),
    CHECK(id = 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE system_status (
    task VARCHAR(16) DEFAULT 'FBC' NOT NULL CHECK (task IN('FBC', 'UPGRADE')),
    owner VARCHAR(256),
    status VARCHAR(16) DEFAULT 'NotInited' NOT NULL CHECK (status IN('NotInited', 'InProgress', 'InitDone')),
    start_time timestamp DEFAULT now(),
    end_time timestamp,
    current_step VARCHAR(256),
    id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- This is used internally.
INSERT INTO database_schema_version VALUES(10, 63);

-- -Stocktake that stored device info and installed apps on the device
CREATE TABLE store_stocktake
(
   uid varchar(512) NOT NULL,
   deviceId varchar(512) NOT NULL,
   deviceOS varchar(512) NOT NULL,
   deviceOSVer varchar(512),
   deviceModel varchar(512),
   installedApps BLOB,
   PRIMARY KEY(uid, deviceId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- Store_app_rating: for store social work, store user app rating
CREATE TABLE store_app_rating
(
  appName VARCHAR(256) NOT NULL,
  uid VARCHAR(512) NOT NULL,
  appver VARCHAR(256) NOT NULL,
  toolver VARCHAR(256) NOT NULL,
  rating float NOT NULL DEFAULT 0,
  commentstime BIGINT,
  comments BLOB,
  headline VARCHAR(256),
  disabled BOOLEAN NOT NULL DEFAULT FALSE,
  platform VARCHAR(256),
  device VARCHAR(1024),
  device_id varchar(1024),
  anonymous BOOLEAN NOT NULL DEFAULT FALSE,
  id BIGINT NOT NULL PRIMARY KEY,
  UNIQUE (uid, appName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- store_app_avgrating:
CREATE TABLE store_app_avgrating
(
  appName VARCHAR(256) NOT NULL UNIQUE,
  avgrating float NOT NULL DEFAULT 0,
  countreviewer BIGINT NOT NULL DEFAULT 0,
  detail VARCHAR(256),
  id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- store_app_rating_history: for store social work, store all activities that user rate/review
CREATE TABLE store_app_rating_history
(
  appName VARCHAR(256) NOT NULL,
  uid VARCHAR(512) NOT NULL,
  appver VARCHAR(256) NOT NULL,
  toolver VARCHAR(256) NOT NULL,
  rating float NOT NULL DEFAULT 0,
  commentstime BIGINT,
  comments BLOB,
  headline VARCHAR(256),
  platform VARCHAR(256),
  device VARCHAR(1024),
  device_id varchar(1024),
  anonymous BOOLEAN NOT NULL DEFAULT FALSE,
  id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- Store_app_faq: for store social work, store faq for each app, adminui will post faq
CREATE TABLE store_app_faq(
  appName VARCHAR(256) NOT NULL,
  displayOrder int NOT NULL DEFAULT 0,
  question text NOT NULL,
  answer text NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- store_content: for store content includes image, css ...
CREATE TABLE store_content(
  contentType VARCHAR(256) NOT NULL,
  data MEDIUMBLOB,
  id BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- store_app_screenshot: for store social work, store screenshots for each app, adminui will post faq
CREATE TABLE store_app_screenshot(
  appName VARCHAR(256) NOT NULL,
  displayOrder int NOT NULL DEFAULT 0,
  path VARCHAR(1024) NOT NULL,
  contentId BIGINT NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (contentId) REFERENCES store_content(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- store_branding: for store branding info
CREATE TABLE store_branding(
  device VARCHAR(256) NOT NULL,
  name VARCHAR(256) NOT NULL,
  contentId BIGINT NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (contentId) REFERENCES store_content(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- store licensing server information
CREATE TABLE licensing_server (
  server_type ENUM('local', 'remote') NOT NULL DEFAULT 'local',
  server_configured BOOLEAN DEFAULT FALSE,
  remote_address VARCHAR(512),
  remote_port INTEGER DEFAULT 27000 NOT NULL,
  license_type ENUM('none', 'CXM_ENTU_UD', 'CXM_ENTD_UD', 'CXM_STDU_UD', 'CXM_STDD_UD', 'CXM_MAMU_UD', 'CXM_MAMD_UD') DEFAULT 'none',
  lic_checkout_cache_lifetime INTEGER NOT NULL DEFAULT 86400,
  lic_inventory_cache_lifetime INTEGER NOT NULL DEFAULT 3600,
  test_connectivity_timeout INTEGER NOT NULL DEFAULT 5,
  id BIGINT NOT NULL PRIMARY KEY,
  server_port INTEGER DEFAULT 8083 NOT NULL,
  CHECK (lic_checkout_cache_lifetime <= 86400),
  CHECK (lic_inventory_cache_lifetime <= 86400),
  CHECK (test_connectivity_timeout <= 60)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- TABLE: license_user_info
-- This table stores per user license check out information
-- -----------------------------------------------------
CREATE TABLE license_user_info (
    user_id BIGINT NOT NULL UNIQUE,
    last_check_out_time timestamp NOT NULL DEFAULT now(),
    check_out_profile VARCHAR(512) NOT NULL,
    license_type ENUM('CXM_ENTU_UD', 'CXM_ENTD_UD', 'CXM_STDU_UD', 'CXM_STDD_UD', 'CXM_MAMU_UD', 'CXM_MAMD_UD') NOT NULL,
    id BIGINT NOT NULL UNIQUE,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- TABLE: license_device_info
-- This table stores per device license check out information
-- -----------------------------------------------------
CREATE TABLE license_device_info
(
    device_id VARCHAR(512) NOT NULL UNIQUE,
    mode ENUM('MAM', 'MDM') NOT NULL,
    last_check_out_time timestamp DEFAULT now(),
    check_out_profile VARCHAR(512) NOT NULL,
    license_type ENUM('CXM_ENTU_UD', 'CXM_ENTD_UD', 'CXM_STDU_UD', 'CXM_STDD_UD', 'CXM_MAMU_UD', 'CXM_MAMD_UD') NOT NULL,
    id BIGINT NOT NULL UNIQUE,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- -----------------------------------------------------
-- TABLE: license_notification
-- This table stores licensing notifcation information
-- -----------------------------------------------------
CREATE TABLE license_notification (
	id BIGINT NOT NULL PRIMARY KEY,
	notification_enabled BOOLEAN NOT NULL DEFAULT FALSE,
	notify_frequency INTEGER DEFAULT 7,			-- frequency of notification in days
	notify_number_days_before_expire INTEGER DEFAULT 60,
	recepient_list VARCHAR(1024),
	email_content text
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- TABLE: license_delete
-- This table stores the licenses that need to be
-- released from the license server when license server
-- is not reachable.
-- -----------------------------------------------------
CREATE TABLE license_delete (
	id BIGINT NOT NULL PRIMARY KEY,
	check_out_profile VARCHAR(512) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -----------------------------------------------------
-- TABLE: system_settings
-- Store web proxy, syslog and other system settings.
-- -----------------------------------------------------
CREATE TABLE system_settings (
	id BIGINT NOT NULL PRIMARY KEY,
	category VARCHAR(32),
	value text,
	site_name VARCHAR(255),
	CONSTRAINT uniq_site_category UNIQUE(category, site_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- worxstore table
CREATE TABLE worxstore (
  id BIGINT NOT NULL PRIMARY KEY,
  worxstore_key VARCHAR(255) NOT NULL,
  worxstore_value VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- system_files table which stores system files like device certificates
CREATE TABLE system_files (
	id BIGINT NOT NULL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	content BLOB NOT NULL,
	type VARCHAR(32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- app_ott table which stores one time tickets for application download
CREATE TABLE `app_ott` (
	`id` BIGINT NOT NULL AUTO_INCREMENT,
	`appname` VARCHAR(255) NOT NULL,
	`ott_expirytime` BIGINT NOT NULL,
	`onetimetoken` VARCHAR(255) NOT NULL,
	PRIMARY KEY  (`id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- Tables for AuthTracker for XMS WebServices --

CREATE TABLE `WSAUTHTRACKER`
(
  `ID` BIGINT NOT NULL PRIMARY KEY,
  `USERNAME` VARCHAR(255) NOT NULL,
  `IPADDRESS` VARCHAR(255) NOT NULL,
  `TOKENTYPE` VARCHAR(50) NOT NULL,
  `TIMESTAMP` timestamp DEFAULT now(),
  `SALT` VARCHAR(255) NOT NULL,
  `HASHVALUE` VARCHAR(255) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- END OF MAM TABLES

-- Tables for Telemetry Service --

CREATE TABLE `TELEMETRY_DATAPOINTS` (
	`ID` SERIAL PRIMARY KEY,
	`TIMESTAMP` TIMESTAMP NOT NULL,
	`COLLECTIONDATE` VARCHAR(64) NOT NULL,
	`CLUSTERID` VARCHAR(64) NOT NULL,
	`DATAPOINT` VARCHAR (511) NOT NULL,
	`RESULT` LONGTEXT NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `TELEMETRY_COLLECTOR_STATUS` (
	`ID` SERIAL PRIMARY KEY,
	`NAME` VARCHAR (255) NOT NULL,
	`CLUSTERID` VARCHAR(64) NOT NULL,
	`FREQUENCY` VARCHAR (10) NOT NULL,
	`FREQUENCYUNIT` VARCHAR(10) NOT NULL,
	`OWNER` VARCHAR (32) NOT NULL,
	`TYPE` VARCHAR (32),
	`EXECUTABLE` VARCHAR (255),
	`INPUTARGS` VARCHAR (1024),
	`TARGET` VARCHAR (32),
	`LASTRUN` TIMESTAMP,
	`STATUSOFLASTRUN` INTEGER
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- NSGCONFIG SCRIPT GENERATION TABLES
CREATE TABLE `ns_script_commandgroup` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`command_name` varchar(128) NOT NULL,
	`command_group` varchar(128) NOT NULL,
	`deployment_ent` INTEGER DEFAULT 1,
	`deployment_mam` INTEGER DEFAULT 0,
	`deployment_mdm` INTEGER DEFAULT 0,
	`on_prem` INTEGER DEFAULT 1,
	`on_cloud` INTEGER DEFAULT 0,
	`logon_category` varchar(128) NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `ns_script_commands` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`command_name` varchar(128) NOT NULL,
	`command_string` varchar(1024) NOT NULL,
	`command_group` varchar(128) NOT NULL,
	`command_comment` varchar(1024) DEFAULT NULL,
	`rank` INTEGER NOT NULL,
	`ns_min_version` varchar(10) NOT NULL DEFAULT '10.1',
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
