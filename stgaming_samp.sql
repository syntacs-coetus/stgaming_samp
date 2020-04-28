CREATE TABLE IF NOT EXISTS `stg_chardet` (
  `pid` int PRIMARY KEY,
  `posx` float(16, 5) NOT NULL,
  `posy` float(16, 5) NOT NULL,
  `posz` float(16, 5) NOT NULL,
  `posa` float(16, 5) NOT NULL,
  `posint` smallint DEFAULT 0,
  `posvw` smallint DEFAULT 0,
  `phealth` float(5, 2) DEFAULT 100,
  `parmour` float(5, 2) DEFAULT 0,
  `pexp` int DEFAULT 0,
  `pmoney` int DEFAULT 100,
  `pgun` int DEFAULT 0,
  `pskin` int DEFAULT 299,
  `prep` int DEFAULT 0,
  `pkillerpoints` int DEFAULT 0,
  `pkills` int DEFAULT 0,
  `pdeaths` int DEFAULT 0,
  `pprisoned` int DEFAULT 0,
  `pcaught` int DEFAULT 0,
  `psaves` int DEFAULT 0,
  `pvip` int DEFAULT 0,
  `pvipexp` datetime,
  `panticrime` boolean DEFAULT false,
  `panticrimetimer` smallint(6) DEFAULT 30,
  `pjoined` timestamp DEFAULT (current_timestamp)
);

CREATE TABLE IF NOT EXISTS `stg_charguns` (
  `pid` int PRIMARY KEY,
  `gun_0` int DEFAULT 0,
  `ammo_0` int DEFAULT 0,
  `gun_1` int DEFAULT 0,
  `ammo_1` int DEFAULT 0,
  `gun_2` int DEFAULT 0,
  `ammo_2` int DEFAULT 0,
  `gun_3` int DEFAULT 0,
  `ammo_3` int DEFAULT 0,
  `gun_4` int DEFAULT 0,
  `ammo_4` int DEFAULT 0,
  `gun_5` int DEFAULT 0,
  `ammo_5` int DEFAULT 0,
  `gun_6` int DEFAULT 0,
  `ammo_6` int DEFAULT 0,
  `gun_7` int DEFAULT 0,
  `ammo_7` int DEFAULT 0,
  `gun_8` int DEFAULT 0,
  `ammo_8` int DEFAULT 0,
  `gun_9` int DEFAULT 0,
  `ammo_9` int DEFAULT 0,
  `gun_10` int DEFAULT 0,
  `ammo_10` int DEFAULT 0,
  `gun_11` int DEFAULT 0,
  `ammo_11` int DEFAULT 0
);

CREATE TABLE IF NOT EXISTS `stg_charveh` (
  `vehid` int PRIMARY KEY AUTO_INCREMENT,
  `owner` int,
  `model` int NOT NULL,
  `vehx` float(16, 5) NOT NULL,
  `vehy` float(16, 5) NOT NULL,
  `vehz` float(16, 5) NOT NULL,
  `veha` float(16, 5) NOT NULL,
  `vehint` int NOT NULL,
  `vehvw` int NOT NULL,
  `vehcolor1` int NOT NULL,
  `vehcolor2` int NOT NULL,
  `vehlocked` boolean DEFAULT false,
  `vehlockedtype` tinyint DEFAULT 0,
  `vehprice` int NOT NULL,
  `vehbought` timestamp DEFAULT (current_timestamp)
);

CREATE TABLE IF NOT EXISTS `stg_groups` (
  `group_id` int PRIMARY KEY AUTO_INCREMENT,
  `group_name` varchar(65) NOT NULL,
  `group_description` varchar(128) NOT NULL,
  `group_pay` int NOT NULL,
  `group_admins` boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS `stg_chargroup` (
  `grp_id` int PRIMARY KEY AUTO_INCREMENT,
  `pid` int,
  `group_id` int,
  `group_rank` int DEFAULT 1,
  `group_active` boolean DEFAULT true,
  `datejoined` timestamp DEFAULT (current_timestamp)
);

CREATE TABLE IF NOT EXISTS `stg_skills` (
  `skill_id` int PRIMARY KEY AUTO_INCREMENT,
  `skill_name` varchar(65) NOT NULL,
  `skill_desc` varchar(128) NOT NULL,
  `skill_type` smallint DEFAULT 1 COMMENT '1 = Crafstman, 2 = Blacksmith, 3 = Locksmith, 4 = Garbage Collector, 5 = Lawyer, 6 = Hacker',
  `skill_active` boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS `stg_userskill` (
  `uskill_id` int PRIMARY KEY AUTO_INCREMENT,
  `skill_id` int,
  `user_id` int,
  `uskill_exp` int DEFAULT 0,
  `uskill_active` boolean DEFAULT true,
  `uskill_lastactive` datetime,
  `uskill_dateadded` datetime
);

CREATE TABLE IF NOT EXISTS `stg_resources` (
  `res_id` int PRIMARY KEY AUTO_INCREMENT,
  `res_name` varchar(65) NOT NULL,
  `res_description` varchar(128) NOT NULL,
  `res_model` int NOT NULL,
  `res_type` int DEFAULT 0 COMMENT '0 = Metal, 1 = Plastic, 2 = Wood, 3 = Liquid, 4 = Herb, 5 = Rubber, 6 = Glass, 7 = Earth',
  `res_rate` float(5, 2) DEFAULT 10,
  `res_price` int NOT NULL,
  `res_active` boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS `stg_charres` (
  `cr_id` int PRIMARY KEY AUTO_INCREMENT,
  `res_id` int,
  `pid` int,
  `cr_quantity` int DEFAULT 0
);

CREATE TABLE IF NOT EXISTS `stg_craftables` (
  `craft_id` int PRIMARY KEY AUTO_INCREMENT,
  `craft_name` varchar(65) NOT NULL,
  `craft_desc` varchar(128) NOT NULL,
  `craft_model` int NOT NULL,
  `craft_type` smallint DEFAULT 0 COMMENT '0 - Healing, 1 - Armour, 2 - Phone, 3 - Hack',
  `craft_heal` float(5, 2) DEFAULT 0,
  `craft_ar` float(5, 2) DEFAULT 0,
  `craft_phonelevel` smallint DEFAULT 1,
  `craft_hacklevel` smallint DEFAULT 1,
  `craft_stack` int DEFAULT 1,
  `craft_levreq` int DEFAULT 1,
  `craft_active` boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS `stg_craftneeds` (
  `cneed_id` int PRIMARY KEY AUTO_INCREMENT,
  `craft_id` int,
  `res_id` int,
  `need_quant` int,
  `need_active` boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS `stg_charcraft` (
  `cc_id` int PRIMARY KEY AUTO_INCREMENT,
  `craft_id` int,
  `pid` int,
  `cc_quantity` int DEFAULT 0
);

CREATE TABLE IF NOT EXISTS `stg_smiths` (
  `smith_id` int PRIMARY KEY AUTO_INCREMENT,
  `smith_name` varchar(65),
  `smith_desc` varchar(65),
  `smith_model` int,
  `smith_itemid` int,
  `smith_stack` int DEFAULT 1,
  `smith_levreq` int DEFAULT 1,
  `smith_active` boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS `stg_smithneeds` (
  `sneed_id` int PRIMARY KEY AUTO_INCREMENT,
  `smith_id` int,
  `craft_id` int,
  `need_quant` int,
  `need_active` boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS `stg_charsmith` (
  `cs_id` int PRIMARY KEY AUTO_INCREMENT,
  `smith_id` int,
  `pid` int,
  `cs_quantity` int DEFAULT 0
);

CREATE TABLE IF NOT EXISTS `stg_locks` (
  `lock_id` int PRIMARY KEY AUTO_INCREMENT,
  `lock_name` varchar(65),
  `lock_desc` varchar(128),
  `lock_model` int,
  `lock_type` smallint DEFAULT 1,
  `lock_stat` float(5, 2) DEFAULT 10,
  `lock_stack` int DEFAULT 1,
  `lock_levreq` int DEFAULT 1,
  `lock_active` int DEFAULT 1
);

CREATE TABLE IF NOT EXISTS `stg_lockneeds` (
  `lneed_id` int PRIMARY KEY AUTO_INCREMENT,
  `lock_id` int,
  `craft_id` int,
  `need_quant` int,
  `need_active` boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS `stg_charlocks` (
  `cl_id` int PRIMARY KEY AUTO_INCREMENT,
  `lock_id` int,
  `pid` int,
  `cl_quantity` int DEFAULT 0
);

CREATE TABLE IF NOT EXISTS `stg_jobs` (
  `job_id` int PRIMARY KEY AUTO_INCREMENT,
  `job_name` varchar(65) NOT NULL,
  `job_desc` varchar(65) NOT NULL,
  `job_pay` int NOT NULL,
  `job_type` smallint DEFAULT 0,
  `job_level` boolean DEFAULT false,
  `job_active` boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS `stg_jobloc` (
  `jloc_id` int PRIMARY KEY AUTO_INCREMENT,
  `job_id` int,
  `jloc_x` float(16, 5) NOT NULL,
  `jloc_y` float(16, 5) NOT NULL,
  `jloc_z` float(16, 5) NOT NULL,
  `jloc_int` int NOT NULL,
  `jloc_vw` int NOT NULL,
  `jloc_active` boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS `stg_jobveh` (
  `jveh_id` int PRIMARY KEY AUTO_INCREMENT,
  `job_id` int,
  `jveh_model` int NOT NULL,
  `jveh_color1` int DEFAULT 1,
  `jveh_color2` int DEFAULT 2,
  `jveh_x` float(16, 5) NOT NULL,
  `jveh_y` float(16, 5) NOT NULL,
  `jveh_z` float(16, 5) NOT NULL,
  `jveh_a` float(16, 5) NOT NULL,
  `jveh_int` int NOT NULL,
  `jveh_vw` int NOT NULL,
  `jveh_respawn` int DEFAULT 100,
  `jveh_active` boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS `stg_userjobs` (
  `ujobs_id` int PRIMARY KEY AUTO_INCREMENT,
  `job_id` int,
  `user_id` int,
  `ujobs_exp` int DEFAULT 0,
  `ujobs_active` boolean DEFAULT true,
  `ujobs_lastactive` datetime,
  `ujobs_dateadded` datetime
);

CREATE TABLE IF NOT EXISTS `stg_doors` (
  `door_id` int PRIMARY KEY AUTO_INCREMENT,
  `door_type` smallint DEFAULT 0,
  `door_x` float(16, 5) NOT NULL,
  `door_y` float(16, 5) NOT NULL,
  `door_z` float(16, 5) NOT NULL,
  `door_a` float(16, 5) NOT NULL,
  `door_interiorid` int NOT NULL,
  `door_vw` int NOT NULL,
  `door_intx` float(16, 5),
  `door_inty` float(16, 5),
  `door_intz` float(16, 5),
  `door_inta` float(16, 5),
  `door_intinteriorid` int,
  `door_intvw` int,
  `door_locked` boolean DEFAULT 0,
  `door_locktype` smallint DEFAULT 0,
  `door_active` boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS `stg_houses` (
  `house_id` int PRIMARY KEY AUTO_INCREMENT,
  `door_id` int,
  `house_money` int DEFAULT 0
);

ALTER TABLE `stg_charguns` ADD FOREIGN KEY (`pid`) REFERENCES `stg_chardet` (`pid`);

ALTER TABLE `stg_charveh` ADD FOREIGN KEY (`owner`) REFERENCES `stg_chardet` (`pid`);

ALTER TABLE `stg_chargroup` ADD FOREIGN KEY (`pid`) REFERENCES `stg_chardet` (`pid`);

ALTER TABLE `stg_chargroup` ADD FOREIGN KEY (`group_id`) REFERENCES `stg_groups` (`group_id`);

ALTER TABLE `stg_userskill` ADD FOREIGN KEY (`skill_id`) REFERENCES `stg_skills` (`skill_id`);

ALTER TABLE `stg_userskill` ADD FOREIGN KEY (`user_id`) REFERENCES `stg_chardet` (`pid`);

ALTER TABLE `stg_charres` ADD FOREIGN KEY (`res_id`) REFERENCES `stg_resources` (`res_id`);

ALTER TABLE `stg_charres` ADD FOREIGN KEY (`pid`) REFERENCES `stg_chardet` (`pid`);

ALTER TABLE `stg_craftneeds` ADD FOREIGN KEY (`craft_id`) REFERENCES `stg_craftables` (`craft_id`);

ALTER TABLE `stg_craftneeds` ADD FOREIGN KEY (`res_id`) REFERENCES `stg_resources` (`res_id`);

ALTER TABLE `stg_charcraft` ADD FOREIGN KEY (`craft_id`) REFERENCES `stg_craftables` (`craft_id`);

ALTER TABLE `stg_charcraft` ADD FOREIGN KEY (`pid`) REFERENCES `stg_chardet` (`pid`);

ALTER TABLE `stg_smithneeds` ADD FOREIGN KEY (`smith_id`) REFERENCES `stg_smiths` (`smith_id`);

ALTER TABLE `stg_smithneeds` ADD FOREIGN KEY (`craft_id`) REFERENCES `stg_craftables` (`craft_id`);

ALTER TABLE `stg_charsmith` ADD FOREIGN KEY (`smith_id`) REFERENCES `stg_smiths` (`smith_id`);

ALTER TABLE `stg_charsmith` ADD FOREIGN KEY (`pid`) REFERENCES `stg_chardet` (`pid`);

ALTER TABLE `stg_lockneeds` ADD FOREIGN KEY (`lock_id`) REFERENCES `stg_locks` (`lock_id`);

ALTER TABLE `stg_lockneeds` ADD FOREIGN KEY (`craft_id`) REFERENCES `stg_craftables` (`craft_id`);

ALTER TABLE `stg_charlocks` ADD FOREIGN KEY (`lock_id`) REFERENCES `stg_locks` (`lock_id`);

ALTER TABLE `stg_charlocks` ADD FOREIGN KEY (`pid`) REFERENCES `stg_chardet` (`pid`);

ALTER TABLE `stg_jobloc` ADD FOREIGN KEY (`job_id`) REFERENCES `stg_jobs` (`job_id`);

ALTER TABLE `stg_jobveh` ADD FOREIGN KEY (`job_id`) REFERENCES `stg_jobs` (`job_id`);

ALTER TABLE `stg_userjobs` ADD FOREIGN KEY (`job_id`) REFERENCES `stg_jobs` (`job_id`);

ALTER TABLE `stg_userjobs` ADD FOREIGN KEY (`user_id`) REFERENCES `stg_chardet` (`pid`);

ALTER TABLE `stg_houses` ADD FOREIGN KEY (`door_id`) REFERENCES `stg_doors` (`door_id`);
