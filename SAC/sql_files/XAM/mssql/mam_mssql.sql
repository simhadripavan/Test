-- CXM-20167 Switch to using Read Committed Snapshot Isolation in SQL Server
DECLARE @dbname VARCHAR(200), @cmd VARCHAR(500);
SET @dbname =  (SELECT DB_NAME());
SET @cmd = 'ALTER DATABASE "'+@dbname+'" SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;';
EXEC(@cmd);

CREATE TABLE Id_Generator (
  table_name NVARCHAR(255) NOT NULL,
  next_id BIGINT NOT NULL,
  CONSTRAINT [EWHILO_PKEY_XAM] PRIMARY KEY CLUSTERED ( table_name ASC ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

CREATE TABLE static_content (
id bigint not null PRIMARY KEY,
content_hash NVARCHAR(128) not null,
type NVARCHAR(5) not null,
ref_count INTEGER,
content VARBINARY(MAX),
is_stock BIT DEFAULT 0
);

CREATE TABLE icon_details(
id bigint not null PRIMARY KEY,
ref_name NVARCHAR(1024) not null,
xres INTEGER not null,
yres INTEGER,
sc_id bigint,
FOREIGN KEY (sc_id) REFERENCES static_content (id)
);

-- -----------------------------------------------------
-- TABLE:info_log_level_type
-- -----------------------------------------------------
CREATE TABLE info_log_level_type (
    id smallint NOT NULL CHECK(id < 7),
    name NVARCHAR(32) NOT NULL UNIQUE,
    PRIMARY KEY(id)
);

-- -----------------------------------------------------
-- TABLE:debug_log_level_type
-- -----------------------------------------------------
CREATE TABLE debug_log_level_type (
    id smallint NOT NULL CHECK (id < 9),
    name NVARCHAR(32) NOT NULL UNIQUE,
    PRIMARY KEY(id)
);

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
-- TABLE:certificate
-- -----------------------------------------------------
GO

CREATE TABLE certificate (
    name NVARCHAR(256) NOT NULL,
    description NVARCHAR(max),
    cert nvarchar(max),
    private_key varbinary(max),
    cert_type NVARCHAR(10) NOT NULL CHECK (cert_type IN('ca', 'csr', 'entity', 'chain', 'saml','apns','apnsCsr','listener','deviceca')),
    valid_from DATE,
    valid_to DATE,
    active BIT DEFAULT 0,
    metadata nvarchar(max),
    reference BIGINT,
    id BIGINT NOT NULL PRIMARY KEY
);

CREATE TABLE device_log_info (
        token_id NVARCHAR (64) NOT NULL PRIMARY KEY,
        token_req_time datetime2(7) DEFAULT getdate(),
        status int NOT NULL,
        metadata NVARCHAR(max)
);

CREATE TABLE enrollment_profile
(
  name NVARCHAR(128) NOT NULL UNIQUE,
  description NVARCHAR(max),
  whencreated datetime2(7) DEFAULT getdate(),
  whenupdated  datetime2(7) DEFAULT getdate(),
  id BIGINT NOT NULL PRIMARY KEY
);


CREATE TABLE enrollment_profile_details
(
  property_key NVARCHAR(128) NOT NULL,
  property_value NVARCHAR(max),
  ep_id bigint NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  UNIQUE (ep_id, property_key),
  FOREIGN KEY (ep_id) REFERENCES enrollment_profile (id) ON DELETE CASCADE
);

CREATE TABLE delivery_group_enrollment_profile
(
  dg_id BIGINT NOT NULL,
  ep_id BIGINT NOT NULL,
  UNIQUE (dg_id, ep_id),
  id BIGINT NOT NULL PRIMARY KEY,
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
 position int NOT NULL,
 id BIGINT NOT NULL PRIMARY KEY,
 FOREIGN KEY (ssl_cert_id) REFERENCES certificate (id),
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

-- -----------------------------------------------------
-- TABLE:versions
-- -----------------------------------------------------
CREATE TABLE versions (
    id int NOT NULL CHECK(id = 0),
    version_schema NVARCHAR(16) NOT NULL,
    version_config NVARCHAR(32) DEFAULT NULL,
    revision BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY(id)
);

-- -----------------------------------------------------
-- TABLE:sc_revisions
-- -----------------------------------------------------
CREATE TABLE sc_revisions (
    folder_name NVARCHAR(20) NOT NULL CHECK (folder_name IN('icons', 'mobileapps', 'certs', 'branding')),
    last_updated datetime2(7) DEFAULT getdate(),
    revision BIGINT NOT NULL DEFAULT 0,
    id BIGINT NOT NULL PRIMARY KEY
);

-- -----------------------------------------------------
-- access_gateway (AGEE)
-- -----------------------------------------------------
CREATE TABLE access_gateway (
    url NVARCHAR(1024) NOT NULL UNIQUE,
    display_name NVARCHAR(512) NOT NULL UNIQUE,
    default_gateway BIT NOT NULL DEFAULT 0,
    logon_type NVARCHAR(15) NOT NULL DEFAULT 'Domain' CHECK (logon_type IN('Domain', 'RSA', 'DomainAndRSA', 'Cert', 'CertAndDomain','CertAndRSA')),
    ag_no_password BIT NOT NULL DEFAULT 0,
    alias NVARCHAR(1024),
    is_cloud BIT NOT NULL DEFAULT 0,
    id BIGINT NOT NULL PRIMARY KEY,
);

-- -----------------------------------------------------
-- ag_callback
--
-- when there are multiple entries for a given AG, ignore the entry with empty VIP
-- -----------------------------------------------------
CREATE TABLE ag_callback (
    ag_id BIGINT NOT NULL,
    callback_host NVARCHAR(1024) NOT NULL,
    callback_port int NOT NULL DEFAULT 443,
    callback_secure BIT NOT NULL DEFAULT 1,
    callback_path NVARCHAR(1024) NOT NULL DEFAULT '/CitrixAuthService/AuthService.asmx',
    callback_vip NVARCHAR(32),
    id BIGINT NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY (ag_id) REFERENCES access_gateway (id) ON DELETE CASCADE
);

-- formerly cluster table
CREATE TABLE auth_settings (
    name NVARCHAR(64) NOT NULL,
    secure BIT DEFAULT 0 NOT NULL,
    ticket_ttl int NOT NULL DEFAULT 100,
    session_token_ttl int NOT NULL DEFAULT 604800,
    wsf_auth BIT DEFAULT 0,
    wsf_enable BIT DEFAULT 0,
    ag_enable BIT DEFAULT 0,
    wsf_host NVARCHAR(256) NOT NULL DEFAULT '',
    wsf_port INT NOT NULL DEFAULT 443,
    account_update_server NVARCHAR(256) NOT NULL DEFAULT '',
    account_update_type NVARCHAR(30) NOT NULL DEFAULT 'none' CHECK (account_update_type IN('none', 'Citrix', 'CitrixInstallOnly', 'MerchandisingServer')),
    save_password BIT DEFAULT 0,
    id int NOT NULL CHECK(id = 0) DEFAULT 0,
    PRIMARY KEY(id)
);

-- -----------------------------------------------------
-- PSQL:get_user_param
-- -----------------------------------------------------
CREATE TABLE user_apps_subscriptions
(
    name NVARCHAR(64) UNIQUE NOT NULL,
    sid NVARCHAR(64),
    data NVARCHAR(max) NOT NULL,
    id BIGINT NOT NULL PRIMARY KEY
);
CREATE INDEX user_apps_subscriptions_index ON user_apps_subscriptions(sid);

-- Table: applications
--- This table contains the unique internal name returned by Apere/ Mobile app API
--- Contains the type of application
CREATE TABLE applications
(
  name NVARCHAR(256) NOT NULL UNIQUE,
  app_type NVARCHAR(20) NOT NULL CHECK (app_type IN('mobile_ios', 'mobile_macosx', 'mobile_android', 'mobile_android_knox', 'mobile_android_work', 'mobile_windows', 'mobile_windows8','web_link', 'fmd', 'sas','sas_ent','mobile_windows_ce','mobile_rpi')),
  subdomain NVARCHAR(256) DEFAULT NULL,
  displayname NVARCHAR(256) NOT NULL,
  disabled BIT NOT NULL DEFAULT 0,
  pkg_uuid NVARCHAR(128) NOT NULL UNIQUE,
  id BIGINT NOT NULL PRIMARY KEY
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
  target_os NVARCHAR(32) NOT NULL,
  hash NVARCHAR(128) NOT NULL,
  app_version NVARCHAR(64),
  minplatform NVARCHAR(32),
  maxplatform NVARCHAR(32),
  excludedevicetypes TEXT,
  PRIMARY KEY (app_pkg_id),
  FOREIGN KEY (app_pkg_id) REFERENCES applications(id) ON DELETE CASCADE
);

-- Table: app_settings
-- This table contains the key value pair for the policy settings
-- Here value could contain whole xml file of policies
CREATE TABLE app_settings
(
  app_settings_key NVARCHAR(128) NOT NULL,
  value NVARCHAR(max),
  app_id bigint NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  UNIQUE (app_id, app_settings_key),
  FOREIGN KEY (app_id) REFERENCES applications (id) ON DELETE CASCADE
);

CREATE TABLE appsettingsui
(
  appsettingsui_key NVARCHAR(128) NOT NULL,
  value NVARCHAR(max),
  appsettingsui_usage NVARCHAR(16) DEFAULT NULL,
  datatype NVARCHAR(64) DEFAULT NULL,
  app_id bigint NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  UNIQUE (app_id, appsettingsui_key),
  FOREIGN KEY (app_id) REFERENCES applications (id) ON DELETE CASCADE
);

-- Table: app_file
-- This table contains name of the files related to mobile app, whole path is derived from uuid.
CREATE TABLE app_file
(
  app_file_id bigint NOT NULL,
  file_type NVARCHAR(4) NOT NULL DEFAULT 'png' CHECK (file_type IN('ico', 'png', 'gif', 'pkg')),
  name NVARCHAR(512) NOT NULL,
  xres int,
  yres int,
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (app_file_id) REFERENCES applications (id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- this table stores device information
-- -----------------------------------------------------
CREATE TABLE devices
(
  device_id NVARCHAR(512) NOT NULL,
  device_token NVARCHAR(1024) NOT NULL,
  table_id BIGINT NOT NULL PRIMARY KEY,
  CONSTRAINT "UQ_devices_id_uniq_key" UNIQUE ("device_id")
);

-- -----------------------------------------------------
-- TABLE:devices2users
-- this table stores device to users information
-- -----------------------------------------------------
CREATE TABLE devices2users
(
  device_id NVARCHAR(512) NOT NULL,
  deprovisioned BIT NOT NULL DEFAULT 0,
  device_user_id BIGINT,
  table_id BIGINT NOT NULL PRIMARY KEY,
  table_id2 BIGINT NOT NULL,
  FOREIGN KEY (table_id2) REFERENCES devices(table_id) ON DELETE CASCADE
);
CREATE INDEX device2users_index ON devices2users(device_id);

-- -----------------------------------------------------
-- TABLE:device_access_data
-- this table stores device last logon time
-- -----------------------------------------------------
CREATE TABLE device_access_data (
  device_id NVARCHAR(512) NOT NULL UNIQUE,
  device_ip NVARCHAR(256),
  last_logon datetime,
  id BIGINT NOT NULL PRIMARY KEY,
  d_id bigint NOT NULL,
  FOREIGN KEY (d_id) REFERENCES devices(table_id) ON DELETE CASCADE
);

CREATE TABLE xenvault_secret
(
  xvs_user_id NVARCHAR(256) NOT NULL,
  device_id NVARCHAR(512) NOT NULL,
  vault_name NVARCHAR(1024) NOT NULL,
  vault_number SMALLINT NOT NULL,
  secret NVARCHAR(max) NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);
CREATE INDEX xenvault_secret_index ON xenvault_secret(xvs_user_id);
CREATE INDEX xenvault_secret_device_id_idx on xenvault_secret(device_id);

CREATE TABLE sta_tickets (
    ticket_id NVARCHAR(512) NOT NULL UNIQUE,
    expiration_time BIGINT NOT NULL,
    device_id NVARCHAR(512),
    sta_user_id NVARCHAR(1024),
    mobile_app_id NVARCHAR(256),
    id BIGINT NOT NULL PRIMARY KEY,
    use_cc_sta BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (mobile_app_id) REFERENCES applications(name) ON DELETE CASCADE
);
CREATE INDEX sta_expiration_index ON sta_tickets (expiration_time);

-- PNA server configuration
CREATE TABLE pnaserver
(
    CONNECTOR_SERVER_NAME VARCHAR(256) DEFAULT NULL,
    CONNECTOR_RESOURCE_LOCATION VARCHAR(256) DEFAULT NULL,
    host NVARCHAR(512) NOT NULL UNIQUE,
    port int NOT NULL,
    path NVARCHAR(1024) NOT NULL,
    secure BIT NOT NULL DEFAULT 0,
    refresh_in_minutes int NOT NULL DEFAULT 0,
    id BIGINT NOT NULL PRIMARY KEY
);

------------------------------------------------------------------------------
-- Table account
-- This table contains AppC account information.
-- There is only one account per AppC, hence this table will have a single row.
-------------------------------------------------------------------------------
CREATE TABLE account
(
 id BIGINT NOT NULL PRIMARY KEY,
 account_id BIGINT NOT NULL UNIQUE,
 name NVARCHAR(256) NOT NULL DEFAULT 'Store',
 description TEXT DEFAULT 'Store'
);

CREATE TABLE store_credentials
(
  store NVARCHAR(10) NOT NULL CHECK (store IN('google', 'amazon')),
  username NVARCHAR(256) DEFAULT NULL,
  password NVARCHAR(256) DEFAULT NULL,
  device_id NVARCHAR(128) NOT NULL UNIQUE,
  id BIGINT NOT NULL PRIMARY KEY
);

-----------------------------------------------------------------------------
-- Table store
-- This table contains the store information.
-- There is one account per AppC and for each account there is a single store.
-- Each store is linked to a beacon table for beacons for the AppC.
-------------------------------------------------------------------------------
CREATE TABLE store
(
 store_name NVARCHAR(128) NOT NULL DEFAULT 'Store',
 store_id NVARCHAR(128) NOT NULL UNIQUE  ,
 account_id BIGINT NOT NULL,
 description TEXT DEFAULT 'Store',
 use_appc_intbeacon BIT NOT NULL DEFAULT 1,
 use_ag_extbeacon BIT NOT NULL DEFAULT 1,
 id BIGINT NOT NULL PRIMARY KEY,
 FOREIGN KEY (account_id) REFERENCES account (account_id) ON DELETE CASCADE
);

-----------------------------------------------------------------------------------
-- Table beacon
-- This table contains beacons information.
-- Beacons can be internal or external
------------------------------------------------------------------------------------
CREATE TABLE beacon
(
  name NVARCHAR(256) NOT NULL,
  beacon_type NVARCHAR(10) NOT NULL CHECK (beacon_type IN('internal','external')),
  b_order int NOT NULL DEFAULT 0,
  store_id NVARCHAR(128) NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (store_id) REFERENCES store (store_id) ON DELETE CASCADE
);

-- Property bag configuration. This is used to support GTA
CREATE TABLE account_properties
(
    display_name NVARCHAR(128) NOT NULL,
    description NVARCHAR(max),
    acc_properties_key NVARCHAR(128) NOT NULL UNIQUE,
    value NVARCHAR(max) DEFAULT NULL,
    readOnly BIT DEFAULT 0,
    id BIGINT NOT NULL PRIMARY KEY,
    advertise_mode VARCHAR(16) NOT NULL DEFAULT 'ALL' CHECK (advertise_mode  IN('GSI', 'AP', 'ALL')),
    is_visible BIT DEFAULT 1
);

CREATE TABLE acc_service_plugin (
    plugin_id uniqueidentifier NOT NULL UNIQUE,
    description TEXT,
    plugin_used BIT DEFAULT 0 NOT NULL,
    id BIGINT NOT NULL,
    PRIMARY KEY(id)
);

GO

CREATE TABLE system_shared (
    notify_port int NOT NULL DEFAULT 9002,
    ticket_ttl int NOT NULL DEFAULT 100, -- lifetime of one time tickets for launching apps
    session_token_ttl int NOT NULL DEFAULT 28800, -- lifetime of session tokens, 8 hours
    virtual_ag_id uniqueidentifier DEFAULT NULL,
    hostname NVARCHAR(256) NOT NULL, -- this was in fqdn table before
    fips_mode BIT DEFAULT 0 NOT NULL,
    ssl_listener_certificate BIGINT NOT NULL, -- this is active certificate used by our SSL Listener
    ssl_offloading_enabled BIT DEFAULT 0 NOT NULL,
    hazelcast_port_enabled BIT DEFAULT 0 NOT NULL,
    sta_id BIGINT NOT NULL UNIQUE, -- If we interpret 64 bit number as hex then it satifies 16 max character restriction for STA ID
    database_id int NOT NULL DEFAULT 0,
    id INTEGER NOT NULL CHECK(id = 0),
    PRIMARY KEY(id),
);
GO

CREATE TABLE system_status (
    task VARCHAR(16) DEFAULT 'FBC' NOT NULL CHECK (task IN('FBC', 'UPGRADE')),
    owner VARCHAR(256),
    status VARCHAR(16) DEFAULT 'NotInited' NOT NULL CHECK (status IN('NotInited', 'InProgress', 'InitDone')),
    start_time datetime2(7) DEFAULT getdate(),
    end_time datetime2(7) DEFAULT getdate(),
    current_step VARCHAR(256),
    id BIGINT NOT NULL PRIMARY KEY
);
GO

-- This is used internally.
INSERT INTO database_schema_version VALUES(10, 57);
GO

-- Stocktake that stored device info and installed apps on the device
CREATE TABLE store_stocktake
(
   uid NVARCHAR(512) NOT NULL,
   deviceId NVARCHAR(512) NOT NULL,
   deviceOS NVARCHAR(512) NOT NULL,
   deviceOSVer NVARCHAR(512),
   deviceModel NVARCHAR(512),
   installedApps image,
   PRIMARY KEY(uid, deviceId)
)
GO

-- END OF MAM TABLES
-- store_app_rating: for store social work, store user app rating
CREATE TABLE store_app_rating
(
  appName NVARCHAR(256) NOT NULL,
  uid NVARCHAR(512) NOT NULL,
  appver NVARCHAR(256) NOT NULL,
  toolver NVARCHAR(256) NOT NULL,
  rating float NOT NULL DEFAULT 0,
  commentstime BIGINT,
  comments image,
  headline NVARCHAR(256),
  disabled BIT NOT NULL DEFAULT 0,
  platform NVARCHAR(256),
  device NVARCHAR(1024),
  device_id NVARCHAR(1024),
  anonymous BIT NOT NULL DEFAULT 0,
  id BIGINT NOT NULL PRIMARY KEY,
  UNIQUE (uid, appName)
)
GO

-- store_app_avgrating:
CREATE TABLE store_app_avgrating
(
  appName NVARCHAR(256) NOT NULL UNIQUE,
  avgrating float NOT NULL DEFAULT 0,
  countreviewer BIGINT NOT NULL DEFAULT 0,
  detail NVARCHAR(256),
  id BIGINT NOT NULL PRIMARY KEY
)
GO

---store_app_rating_history: for store social work, store all activities that user rate/review
CREATE TABLE store_app_rating_history
(
  appName NVARCHAR(256) NOT NULL,
  uid NVARCHAR(512) NOT NULL,
  appver NVARCHAR(256) NOT NULL,
  toolver NVARCHAR(256) NOT NULL,
  rating float NOT NULL DEFAULT 0,
  commentstime BIGINT,
  comments image,
  headline NVARCHAR(256),
  platform NVARCHAR(256),
  device NVARCHAR(1024),
  device_id NVARCHAR(1024),
  anonymous BIT NOT NULL DEFAULT 0,
  id BIGINT NOT NULL PRIMARY KEY
)
GO

-- Store_app_faq: for store social work, store faq for each app, adminui will post faq
CREATE TABLE store_app_faq(
  appName NVARCHAR(256) NOT NULL,
  displayOrder int NOT NULL DEFAULT 0,
  question NVARCHAR(MAX) NOT NULL,
  answer NVARCHAR(MAX) NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY
)
GO

---store_content: for store content includes image, css ...
CREATE TABLE store_content(
  contentType VARCHAR(256) NOT NULL,
  data image,
  id BIGINT NOT NULL PRIMARY KEY
)
GO

---store_app_screenshot: for store social work, store screenshots for each app, adminui will post faq
CREATE TABLE store_app_screenshot(
  appName NVARCHAR(256) NOT NULL,
  displayOrder int NOT NULL DEFAULT 0,
  path NVARCHAR(1024) NOT NULL,
  contentId bigint NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (contentId) REFERENCES store_content(id) ON DELETE CASCADE
)
GO

---store_branding: for store branding info
CREATE TABLE store_branding(
  device VARCHAR(256) NOT NULL,
  name VARCHAR(256) NOT NULL,
  contentId bigint NOT NULL,
  id BIGINT NOT NULL PRIMARY KEY,
  FOREIGN KEY (contentId) REFERENCES store_content(id) ON DELETE CASCADE
)
GO

-- store licensing server information
CREATE TABLE licensing_server (
  server_type VARCHAR(16) NOT NULL DEFAULT 'local' CHECK (server_type IN('local', 'remote')),
  server_configured BIT DEFAULT 0,
  remote_address VARCHAR(512),
  remote_port INTEGER DEFAULT 27000 NOT NULL,
  license_type VARCHAR(16) DEFAULT 'none' NOT NULL CHECK (license_type IN('none', 'CXM_ENTU_UD', 'CXM_ENTD_UD', 'CXM_STDU_UD', 'CXM_STDD_UD', 'CXM_MAMU_UD', 'CXM_MAMD_UD')),
  lic_checkout_cache_lifetime INTEGER NOT NULL DEFAULT 86400 CHECK (lic_checkout_cache_lifetime <= 86400),
  lic_inventory_cache_lifetime INTEGER NOT NULL DEFAULT 3600 CHECK (lic_inventory_cache_lifetime <= 86400),
  test_connectivity_timeout INTEGER NOT NULL DEFAULT 5 CHECK (test_connectivity_timeout <= 60),
  id BIGINT NOT NULL PRIMARY KEY,
  server_port INTEGER DEFAULT 8083 NOT NULL
)
GO

-- -----------------------------------------------------
-- TABLE: license_user_info
-- This table stores per user license check out information
-- -----------------------------------------------------
CREATE TABLE license_user_info (
    user_id BIGINT NOT NULL UNIQUE,
    last_check_out_time datetime2(7) NOT NULL DEFAULT getdate(),
    check_out_profile VARCHAR(512) NOT NULL,
    license_type VARCHAR(16) NOT NULL CHECK (license_type IN('CXM_ENTU_UD', 'CXM_ENTD_UD', 'CXM_STDU_UD', 'CXM_STDD_UD', 'CXM_MAMU_UD', 'CXM_MAMD_UD')),
    id BIGINT NOT NULL,
    PRIMARY KEY(id)
)
GO

-- -----------------------------------------------------
-- TABLE: license_device_info
-- This table stores per device license check out information
-- -----------------------------------------------------
CREATE TABLE license_device_info
(
    device_id VARCHAR(512) NOT NULL UNIQUE,
    mode VARCHAR(16) NOT NULL CHECK (mode IN ('MAM', 'MDM')),
    last_check_out_time datetime2(7) NOT NULL DEFAULT getdate(),
    check_out_profile VARCHAR(512) NOT NULL,
    license_type VARCHAR(16) NOT NULL CHECK (license_type IN ('CXM_ENTU_UD', 'CXM_ENTD_UD', 'CXM_STDU_UD', 'CXM_STDD_UD', 'CXM_MAMU_UD', 'CXM_MAMD_UD')),
    id BIGINT NOT NULL,
    PRIMARY KEY(id)
)
GO

-- -----------------------------------------------------
-- TABLE: license_notification
-- This table stores licensing notifcation information
-- -----------------------------------------------------
CREATE TABLE license_notification (
	id BIGINT NOT NULL PRIMARY KEY,
	notification_enabled BIT NOT NULL DEFAULT 0,
	notify_frequency INTEGER DEFAULT 7,			-- frequency of notification in days
	notify_number_days_before_expire INTEGER DEFAULT 60,
	recepient_list NVARCHAR(1024),
	email_content NVARCHAR(max)
)
GO

-- -----------------------------------------------------
-- TABLE: license_delete
-- This table stores the licenses that need to be
-- released from the license server when license server
-- is not reachable.
-- -----------------------------------------------------
CREATE TABLE license_delete (
	id BIGINT NOT NULL PRIMARY KEY,
	check_out_profile NVARCHAR(512) NOT NULL
)
GO

-- -----------------------------------------------------
-- TABLE: system_settings
-- Store web proxy, syslog and other system settings.
-- -----------------------------------------------------
CREATE TABLE system_settings (
	id BIGINT NOT NULL PRIMARY KEY,
	category NVARCHAR(32),
	value NVARCHAR(max),
	site_name NVARCHAR(255),
	CONSTRAINT uniq_site_category UNIQUE(category, site_name)
)
GO
-- -----------------------------------------------------
-- TABLE: worxstore
-- -----------------------------------------------------
CREATE TABLE worxstore (
  id BIGINT NOT NULL PRIMARY KEY,
  worxstore_key NVARCHAR(255) NOT NULL,
  worxstore_value NVARCHAR(255) NOT NULL
);

-- ------------------------------------------------------------------------
-- TABLE: system_files
-- Stores system files like device certificates
-- ------------------------------------------------------------------------
CREATE TABLE system_files (
	id BIGINT NOT NULL PRIMARY KEY,
	name NVARCHAR(255) NOT NULL,
	content varbinary(max) NOT NULL,
	type NVARCHAR(32)
);

-- TABLE: support_serverdetails
-- Stores NSG and TAAS details
-- -----------------------------------------------------
CREATE TABLE support_serverdetails (
   url NVARCHAR(128) NOT NULL PRIMARY KEY,
   username NVARCHAR(64) NOT NULL,
   password NVARCHAR(512),
   server_type NVARCHAR(20) NOT NULL
)
GO

-- ------------------------------------------------------------------------
-- TABLE: app_ott
-- Stores one time tickets for application download
-- ------------------------------------------------------------------------
CREATE TABLE app_ott (
	id BIGINT PRIMARY KEY IDENTITY(1,1),
	appname NVARCHAR(max) NOT NULL,
	ott_expirytime BIGINT NOT NULL,
	onetimetoken NVARCHAR(max) NOT NULL
);
-- Tables for AuthTracker for XMS WebServices --


CREATE TABLE "WSAUTHTRACKER"
(
  "ID" BIGINT NOT NULL PRIMARY KEY,
  "USERNAME" NVARCHAR(255) NOT NULL,
  "IPADDRESS" NVARCHAR(255) NOT NULL,
  "TOKENTYPE" NVARCHAR(50) NOT NULL,
  "TIMESTAMP" datetime2(7) NOT NULL DEFAULT getdate(),
  "SALT" NVARCHAR(255) NOT NULL,
  "HASHVALUE" NVARCHAR(255) NOT NULL
)

-- CEIP TABLES
CREATE TABLE TELEMETRY_DATAPOINTS (
	ID BIGINT NOT NULL identity(1, 1),
	TIMESTAMP datetime2(7) DEFAULT getdate(),
	COLLECTIONDATE VARCHAR(64) NOT NULL,
	CLUSTERID VARCHAR(64) NOT NULL,
	DATAPOINT VARCHAR (511) NOT NULL,
	RESULT TEXT NOT NULL,
	PRIMARY KEY (ID)
);

CREATE TABLE TELEMETRY_COLLECTOR_STATUS (
	ID BIGINT NOT NULL identity(1, 1),
	NAME VARCHAR (255) NOT NULL,
	CLUSTERID VARCHAR(64) NOT NULL,
	FREQUENCY VARCHAR (10) NOT NULL,
	FREQUENCYUNIT VARCHAR(10) NOT NULL,
	OWNER VARCHAR (32) NOT NULL,
	TYPE VARCHAR (32),
	EXECUTABLE VARCHAR (255),
	INPUTARGS VARCHAR (1024),
	TARGET VARCHAR (32),
	LASTRUN datetime2(7) DEFAULT getdate(),
	STATUSOFLASTRUN INT,
	PRIMARY KEY (ID)
);

-- NSGCONFIG SCRIPT GENERATION TABLES
CREATE TABLE ns_script_commandgroup (
	id BIGINT NOT NULL IDENTITY(1, 1),
	command_name varchar(128) NOT NULL,
	command_group varchar(128) NOT NULL,
	deployment_ent INTEGER DEFAULT 1,
	deployment_mam INTEGER DEFAULT 0,
	deployment_mdm INTEGER DEFAULT 0,
	on_prem INTEGER DEFAULT 1,
	on_cloud INTEGER DEFAULT 0,
	logon_category varchar(128) NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE ns_script_commands (
	id BIGINT NOT NULL IDENTITY(1, 1),
	command_name varchar(128) NOT NULL,
	command_string varchar(1024) NOT NULL,
	command_group varchar(128) NOT NULL,
	command_comment varchar(1024) DEFAULT NULL,
	rank INTEGER NOT NULL,
	ns_min_version varchar(10) NOT NULL DEFAULT '10.1',
	PRIMARY KEY (id)
);

GO

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

GO
-- END OF MAM TABLES
