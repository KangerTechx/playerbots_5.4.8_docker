-- update_auth_template.sql
-- Cleans up the auth database, creates admin account, and updates the realmlist.

-- Clean up old accounts
DELETE FROM account;
DELETE FROM account_access;

-- Add admin account (username: ADMIN, password: ADMIN)
INSERT INTO account (id, username, sha_pass_hash)
VALUES (1, 'ADMIN', '8301316D0D8448A34FA6D0C6BF1CBFA2B4A1A93A');

INSERT INTO account_access (id, gmlevel, RealmID)
VALUES (1, 4, -1);

-- Update realmlist
DELETE FROM realmlist;

INSERT INTO `realmlist` (`id`, `name`, `address`, `port`, `localAddress`, `localSubnetMask`, `icon`, `flag`, `timezone`, `allowedSecurityLevel`, `population`, `gamebuild`) VALUES 
(1, '${REALM_NAME}', '${REALM_ADDRESS}', ${REALM_PORT}, '127.0.0.1', '255.255.255.0', ${REALM_ICON}, ${REALM_FLAG}, ${REALM_TIMEZONE}, ${REALM_SECURITY}, ${REALM_POP}, ${REALM_BUILD});