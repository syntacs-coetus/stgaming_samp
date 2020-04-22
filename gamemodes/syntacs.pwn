#include <a_samp>

// #define DEVELOPMENT



#define FIXES_ServerVarMsg 0
#include <fixes>
#include <weapon-config>


#define SCM SendClientMessage

#define HOST "127.0.0.1"
#define USER "stgaming"
#define PASS "deJoker123"
#define FORM "syntacs_gaming"
#define SAMP "stgaming_samp"
#include <a_mysql>

#define YSI_YES_HEAP_MALLOC
#define YSI_NO_CACHE_MESSAGE
#define YSI_YES_MODE_CACHE
#define YSI_NO_VERSION_CHECK
#define YSI_NO_OPTIMISATION_MESSAGE
#include <YSI_Data\y_iterate>
#include <YSI_Players\y_groups>
#include <YSI_Visual\y_commands>
#include <YSI_Visual\y_dialog>
#include <YSI_Coding\y_timers>
#include <YSI_Server\y_colours>

#include <samp_bcrypt>
#include <sscanf2>
#include <streamer>
#include <formatex>


#define MIN_PLAYER_LOOKSIE 5.0
#define MAX_PLAYER_LOOKSIE 25.0
#define MAX_NAME (MAX_PLAYER_NAME + 1)
#define MAX_PASS 500
#define MAX_EMAIL 220
#define MAX_DATETIME 20
#define MAX_DEATHPICKUP 10
#define MAX_SERVHOSP 1
#define MAX_SLOTS 12
#define MAX_LISTLENGTH 50
#define IMMUNITY_TIME 5
#define DEATHTIMER_TIME 10
// Administrative Definition
#define MIN_ADMIN_LEVEL 1
#define MAX_ADMIN_LEVEL 6

enum pInfo{
    pID,
    pName[MAX_NAME],
    pPass[MAX_PASS],
    pEmail[MAX_EMAIL],
    pReferredPlayers,
    pReputation,
    Float: pCP,
    Float: pPos[4],
    Float: pHP,
    Float: pArmour,
    pInterior,
    pVirtualWorld,
    pEXP,
    pMoney,
    pEquippedGun,
    pSkin,
    pKills,
    pDeaths,
    pPrisoned,
    pCaught,
    pSaves,
    pVIP,
    pVIPEXP[MAX_DATETIME],
    pAdmin,

    pDepartment,
    pRank,

    Text3D: pTag,

    pGroup,
    Cache: pCache
}

enum pWeaponInfo{
    pWepID,
    pWepAmmo
}

new 
    pData[MAX_PLAYERS][pInfo],
    pWepData[MAX_PLAYERS][MAX_SLOTS][pWeaponInfo],

    bool: pSpawnImmune[MAX_PLAYERS],
    bool: pDyingDamageImmune[MAX_PLAYERS],
    bool: isDying[MAX_PLAYERS],
    bool: isOnline[MAX_PLAYERS],
    // bool: isCritical[MAX_PLAYERS],

    STREAMER_TAG_PICKUP: deathPickup[MAX_DEATHPICKUP],
    droppedWeapon[MAX_DEATHPICKUP][MAX_SLOTS],
    droppedAmmo[MAX_DEATHPICKUP][MAX_SLOTS],
    moneyDropped[MAX_DEATHPICKUP],
    dropperId[MAX_DEATHPICKUP],

    Float: spawnLoc[3][4] = {
        // Administrative Location
        {-1605.6788,719.5027,11.9920,180.7348},
        // Black Mamba Location
        {-2732.8354,-308.5785,7.1875,233.9780},
        // Silver Knight Location
        {-2584.2507,1362.2104,7.1935,42.6103}
    },
    Float: medLoc[1][4] = {
        // San Fierro Medical Hospital
        {-2654.8928,638.5195,14.4531,179.0561}
    },

    MySQL: forumdb,
    MySQL: sampdb,
    
    Group: OnlinePlayers,
    Group: pOwners,
    Group: AdminList,
    Group: pAdmins[MAX_ADMIN_LEVEL + MIN_ADMIN_LEVEL]

    ;

stock const ModeratorNames[][] = {
         "Junior Moderator",
         "General Moderator",
         "Senior Moderator",
         "Median Moderator",
         "Assistant Head Moderator",
         "Head Moderator"
};
stock const ModeratorNicks[][] = {
    "JM", "GM", "SM", "MM", "AHM", "HM"
};

__SetAdminCommand(const command[], level){
    new id = Command_GetID(command);
    Group_SetGlobalCommand(id, false);
    if(level >= MIN_ADMIN_LEVEL){
        new cl = level;
        while(cl != MAX_ADMIN_LEVEL){
            new Group: group = pAdmins[cl];
            Group_SetCommand(group, id, true);
            cl++;
        }
    }
    // All admin commands can be used by the owner/s
    Group_SetCommand(pOwners, id, true);
    return 1;
}

__WeponDropSingleClip(playerid, wepid, wepmo){
    #pragma unused playerid, wepid
    new dropmo = 30;
    if(wepmo < dropmo){
        return wepmo;
    }
    return dropmo;
}

// __GetPlayerWeapons(playerid){
//     for(i = 0, j = MAX_SLOTS; i < j; i++){
//         GetPlayerWeaponData(playerid, i, pWepData[playerid][i][pWepID], pWepData[playerid][i][pWepAmmo]);
//     }
//     return 1;
// }

__GivePlayerWeapons(playerid, weaponid, ammo){
    new wepSlot;
    switch(weaponid){
        // slot 0
        case 1..2:{
            wepSlot = 0;
        }
        // slot 1
        case 3..9:{
            wepSlot = 1;
        }
        // slot 2
        case 22..24:{
            wepSlot = 2;
        }
        // slot 3
        case 25..27:{
            wepSlot = 3;
        }
        // slot 4
        case 28, 29, 32:{
            wepSlot = 4;
        }
        // slot 5
        case 30, 31:{
            wepSlot = 5;
        }
        // slot 6
        case 33, 34:{
            wepSlot = 6;
        }
        // slot 7
        case 35..38:{
            wepSlot = 7;
        }
        // slot 8
        case 16..18:{
            wepSlot = 8;
        }
        // slot 9
        case 41..43:{
            wepSlot = 9;
        }
        // slot 10
        case 10..15:{
            wepSlot = 10;
        }
        // slot 11
        case 44..46:{
            wepSlot = 11;
        }
        // slot 12
        case 40:{
            wepSlot = 12;
        }
    }
    #pragma unused wepSlot
    GivePlayerWeapon(playerid, weaponid, ammo);
    return 1;
}

/* INITIALIZE COMMANDS */

__InitializeCommands(){
    new string[15 + 11];
    Command_SetDeniedReturn(true);
    Group_SetGlobalCommandDefault(false);
    OnlinePlayers = Group_Create("Online Players");
    AdminList = Group_Create("Admins");
    pOwners = Group_Create("Owners");
    Group_SetColor(pOwners, X11_PURPLE_4);
    for(new i = MIN_ADMIN_LEVEL, j = MAX_ADMIN_LEVEL; i <= j; i++){
        format(string, sizeof string, "Admin Level %d", i);
        pAdmins[i] = Group_Create(string);
    }
    __SetAdminCommand("spawnveh", 2);
    __SetAdminCommand("giveplayerweapon", 2);
    __SetAdminCommand("giveplayermoney", 3);
    __SetAdminCommand("admincommands", 1);
    __SetAdminCommand("giveplayerhealth", 3);
    __SetAdminCommand("giveplayerarmour", 3);
    __SetGlobalCommand("kill");
    __SetGlobalCommand("adminsonline");
    return 1;
}

__SetGlobalCommand(const command[]){
    Group_SetGlobalCommand(Command_GetID(command), true);
    return 1;
}

__GetHospitalLocation(playerid){
    new nearmed = -1, Float: dist = 0.0;
    for(new i = 0, j = MAX_SERVHOSP; i < j; i++){
        if(dist != 0.0){
            new Float: tmpDist = GetPlayerDistanceFromPoint(playerid, medLoc[i][0], medLoc[i][1], medLoc[i][2]);
            if(dist > tmpDist){
                dist = tmpDist;
                nearmed = i;
            }
        }else{
            dist = GetPlayerDistanceFromPoint(playerid, medLoc[i][0], medLoc[i][1], medLoc[i][2]);
            nearmed = i;
        }
    }
    return nearmed;
}

__GetEmptyDeathPickup(){
    for(new i = 0, j = MAX_DEATHPICKUP; i < j; i++){
        if(deathPickup[i] == STREAMER_TAG_PICKUP: -1){
            return i;
        }
    }
    return -1;
}

__SetPlayerSkills(playerid){
    for(new i = 0, j = 10; i <= j; i++){
        SetPlayerSkillLevel(playerid, i, 1);
    }
    return 1;
}

MySQL: ForumSecureConnect(){
    new MySQLOpt: option_id = mysql_init_options(), MySQL: db;
    mysql_set_option(option_id, AUTO_RECONNECT, true);

    db = mysql_connect(HOST, USER, PASS, FORM, option_id);
    if(mysql_errno(db) != 0 || db == MYSQL_INVALID_HANDLE){
        print("Secure Connection to the forums has not been established! Shutting down...");
        SendRconCommand("exit");
    }
    return db;
}

MySQL: ServerSecureConnect(){
    new MySQLOpt: option_id = mysql_init_options(), MySQL: db;
    mysql_set_option(option_id, AUTO_RECONNECT, true);

    db = mysql_connect(HOST, USER, PASS, SAMP, option_id);
    if(mysql_errno(db) != 0 || db == MYSQL_INVALID_HANDLE){
        print("Secure Connection to the server has not been established! Shutting down...");
        SendRconCommand("exit");
    }
    return db;
}

SpawnPlayerEx(playerid){
    if(cache_is_valid(pData[playerid][pCache])){
        new query[157 + (11 * 3) + (11 * 15)];
        cache_set_active(pData[playerid][pCache]);
        cache_get_value(0, "email", pData[playerid][pEmail], MAX_EMAIL);
        cache_get_value_name_int(0, "referrals", pData[playerid][pReferredPlayers]);
        if(pData[playerid][pGroup] == 2){
            new affiliation[15];
            cache_get_value(0, "fid6", affiliation, sizeof affiliation);
            if(strcmp(affiliation, "Black Mambas") == 0){
                mysql_format(forumdb, query, sizeof query, "UPDATE stg_users SET usergroup = 12 WHERE uid = %d", pData[playerid][pID]);
                mysql_query(forumdb, query);
                pData[playerid][pGroup] = 12;
            }else if(strcmp(affiliation, "Silver Knights") == 0){
                mysql_format(forumdb, query, sizeof query, "UPDATE stg_users SET usergroup = 13 WHERE uid = %d", pData[playerid][pID]);
                mysql_query(forumdb, query);
                pData[playerid][pGroup] = 13;
            }else{
                mysql_format(forumdb, query, sizeof query, "UPDATE stg_users SET usergroup = 14 WHERE uid = %d", pData[playerid][pID]);
                mysql_query(forumdb, query);
                pData[playerid][pGroup] = 14;
            }
        }
        // Remove cache because player is now spawned.
        // This is for security to and avoid cache leakge.
        cache_delete(pData[playerid][pCache]);
        pData[playerid][pCache] = MYSQL_INVALID_CACHE;
        inline getCharDet(){
            if(cache_num_rows() != 0){
                cache_get_value_float(0, "posx", pData[playerid][pPos][0]);
                cache_get_value_float(0, "posy", pData[playerid][pPos][1]);
                cache_get_value_float(0, "posz", pData[playerid][pPos][2]);
                cache_get_value_float(0, "posa", pData[playerid][pPos][3]);
                cache_get_value_float(0, "phealth", pData[playerid][pHP]);
                cache_get_value_float(0, "parmour", pData[playerid][pArmour]);
                cache_get_value_int(0, "posint", pData[playerid][pInterior]);
                cache_get_value_int(0, "posvw", pData[playerid][pVirtualWorld]);
                cache_get_value_int(0, "prep", pData[playerid][pReputation]);
                cache_get_value_int(0, "pexp", pData[playerid][pEXP]);
                cache_get_value_int(0, "pmoney", pData[playerid][pMoney]);
                cache_get_value_int(0, "pskin", pData[playerid][pSkin]);
                cache_get_value_int(0, "pgun", pData[playerid][pEquippedGun]);
                cache_get_value_int(0, "pkills", pData[playerid][pKills]);
                cache_get_value_int(0, "pdeaths", pData[playerid][pDeaths]);
                cache_get_value_int(0, "pprisoned", pData[playerid][pPrisoned]);
                cache_get_value_int(0, "pcaught", pData[playerid][pCaught]);
                cache_get_value_int(0, "psaves", pData[playerid][pSaves]);
                cache_get_value_int(0, "pvip", pData[playerid][pVIP]);
                cache_get_value(0, "pvipexp", pData[playerid][pVIPEXP]);
                if(pData[playerid][pPos][0] == 0.0){
                    switch(pData[playerid][pGroup]){
                        case 3, 4, 6:{
                            pData[playerid][pPos][0] = spawnLoc[0][0];
                            pData[playerid][pPos][1] = spawnLoc[0][1];
                            pData[playerid][pPos][2] = spawnLoc[0][2];
                            pData[playerid][pPos][3] = spawnLoc[0][3];
                            pData[playerid][pInterior] = 0;
                            pData[playerid][pVirtualWorld] = 0;
                        }
                        case 12:{
                            pData[playerid][pPos][0] = spawnLoc[1][0];
                            pData[playerid][pPos][1] = spawnLoc[1][1];
                            pData[playerid][pPos][2] = spawnLoc[1][2];
                            pData[playerid][pPos][3] = spawnLoc[1][3];
                            pData[playerid][pInterior] = 0;
                            pData[playerid][pVirtualWorld] = 0;
                        }
                        case 13:{
                            pData[playerid][pPos][0] = spawnLoc[2][0];
                            pData[playerid][pPos][1] = spawnLoc[2][1];
                            pData[playerid][pPos][2] = spawnLoc[2][2];
                            pData[playerid][pPos][3] = spawnLoc[2][3];
                            pData[playerid][pInterior] = 0;
                            pData[playerid][pVirtualWorld] = 0;
                        }
                        case 14:{
                            new const rand = random(sizeof spawnLoc);
                            pData[playerid][pPos][0] = spawnLoc[rand][0];
                            pData[playerid][pPos][1] = spawnLoc[rand][1];
                            pData[playerid][pPos][2] = spawnLoc[rand][2];
                            pData[playerid][pPos][3] = spawnLoc[rand][3];
                            pData[playerid][pInterior] = 0;
                            pData[playerid][pVirtualWorld] = 0;
                        } 
                    }
                    mysql_format(sampdb, query, sizeof query, "UPDATE stg_chardet SET posx = '%f', posy = '%f', posz = '%f', posa = '%f', posint = '%d', posvw = '%d' WHERE pid = '%d'", pData[playerid][pPos][0], pData[playerid][pPos][1], pData[playerid][pPos][2], pData[playerid][pPos][3], pData[playerid][pInterior], pData[playerid]  [pVirtualWorld], pData[playerid][pID]);
                    mysql_query(sampdb, query);
                }
                inline getPlayerAdmin(){
                    if(cache_num_rows() != 0){
                        new level;
                        cache_get_value_int(0, "rank", level);
                        switch(level){
                            case MIN_ADMIN_LEVEL..MAX_ADMIN_LEVEL:{
                                Group_SetPlayer(pAdmins[level], playerid, true);
                                SetPlayerColor(playerid, Group_GetColor(pAdmins[level]));
                                new string[3 + 25];
                                formatex(string, sizeof string, "[%s]", Group_GetName(pAdmins[level]));
                                pData[playerid][pTag] = Create3DTextLabel(string, GetPlayerColor(playerid), 0.0, 0.0, 0.0, MAX_PLAYER_LOOKSIE, 0);
                            }
                            case 100:{
                                Group_SetPlayer(pOwners, playerid, true);
                                SetPlayerColor(playerid, Group_GetColor(pOwners));
                                new string[3 + 25];
                                formatex(string, sizeof string, "[%s]", Group_GetName(pOwners));
                                pData[playerid][pTag] = Create3DTextLabel(string, GetPlayerColor(playerid), 0.0, 0.0, 0.0, MAX_PLAYER_LOOKSIE, 0);
                            }
                        }
                        pData[playerid][pAdmin] = level;
                        Group_SetPlayer(AdminList, playerid, true);
                        Attach3DTextLabelToPlayer(pData[playerid][pTag], playerid, 0.0, 0.0, 0.25);
                    }
                    inline getPlayerDepartment(){
                        if(cache_num_rows() != 0){
                            cache_get_value_int(0, "group", pData[playerid][pDepartment]);
                            cache_get_value_int(0, "rank", pData[playerid][pRank]);
                        }

                        SetCameraBehindPlayer(playerid);
                        SetPlayerPos(playerid, pData[playerid][pPos][0], pData[playerid][pPos][1], pData[playerid][pPos][2]);
                        SetPlayerFacingAngle(playerid, pData[playerid][pPos][3]);
                        SetPlayerVirtualWorld(playerid, pData[playerid][pInterior]);
                        SetPlayerInterior(playerid, pData[playerid][pVirtualWorld]);
                        pSpawnImmune[playerid] = true;
                        defer __RemoveImmunity(playerid);
                        defer __GivePlayerMoney(playerid);
                        defer __SetPlayerSkin(playerid);
                        defer __SetPlayerScoreBoard(playerid);
                        defer __GivePlayerHealth(playerid);
                        defer __GivePlayerArmour(playerid);
                        Group_SetPlayer(OnlinePlayers, playerid, true);

                        // After realizing that Group_GetPlayer does not work OnPlayerDisconnect I will have to make an adjustment
                        // This code will do that
                        isOnline[playerid] = true;
                    }
                    mysql_format(sampdb, query, sizeof query, "SELECT * FROM stg_chargroup INNER JOIN stg_groups ON stg_chargroup.`group` = stg_groups.group_id WHERE stg_groups.group_admins = 0 AND stg_chargroup.pid = %d", pData[playerid][pID]);
                    MySQL_TQueryInline(sampdb, using inline getPlayerDepartment, query);
                }
                mysql_format(sampdb, query, sizeof query, "SELECT * FROM stg_chargroup INNER JOIN stg_groups ON stg_chargroup.`group` = stg_groups.group_id WHERE stg_groups.group_admins = 1 AND stg_chargroup.pid = %d", pData[playerid][pID]);
                MySQL_TQueryInline(sampdb, using inline getPlayerAdmin, query);
            }else{
                inline CreateCharacterDetails(){
                    if(cache_affected_rows() != 0){
                        mysql_format(sampdb, query, sizeof query, "SELECT * FROM stg_chardet WHERE pid = %d", pData[playerid][pID]);
                        MySQL_TQueryInline(sampdb, using inline getCharDet, query);
                    }
                }
                mysql_format(sampdb, query, sizeof query, "INSERT INTO stg_chardet (pid) VALUES (%d)", pData[playerid][pID]);
                MySQL_TQueryInline(sampdb, using inline CreateCharacterDetails, query);
            }
        }
        mysql_format(sampdb, query, sizeof query, "SELECT * FROM stg_chardet WHERE pid = %d", pData[playerid][pID]);
        MySQL_TQueryInline(sampdb, using inline getCharDet, query);
    }else{
        SCM(playerid, X11_FIREBRICK, "A problem has occured during your spawn. Please notify an admin if this has happened a couple of times");
        SCM(playerid, X11_FIREBRICK, "This problem occurs when connecting to the Server Database encountered an error!");
        SCM(playerid, X11_FIREBRICK, "Re-Logging will be the only fix for this.");
        SCM(playerid, X11_FIREBRICK, "Thank you for understanding us, we only want to keep your data's secure");
        defer DisconnectPlayer(playerid);
    }
    return 1;
}

CommandHelp(playerid, const cmd[], const cmdtext[]){
    new string[144 + 1];
    format(string, sizeof string, "/%s %s", cmd, cmdtext);
    SendClientMessage(playerid, X11_LIGHT_GOLDENROD, string);
    return 1;
}

CommandPlayerCheck(playerid, targetid){
    if(!IsPlayerConnected(targetid)) return SCM(playerid, X11_DARK_GOLDENROD_2, "Player is not connected"), 0;
    if(!Group_GetPlayer(OnlinePlayers, targetid)) return SCM(playerid, X11_DARK_GOLDENROD_2, "Player is not online"), 0;
    return 1;
}

CommandError(const playerid, const text[]){
    SCM(playerid, X11_FIREBRICK, text);
    return 1;
}

/* COMMANDS */

YCMD:giveplayerarmour(playerid, params[], help){
    #pragma unused help
    new targetid, Float: ar;
    if(sscanf(params, "df", targetid, ar)) return CommandHelp(playerid, "giveplayerhealth", "[Player ID / Part of Name] [Armour Points]"), 1;
    if(!CommandPlayerCheck(playerid, targetid)) return 1;
    if(pSpawnImmune[targetid]) return SCM(playerid, X11_DARK_GOLDENROD_2, "Player is under immunity, armour is not needed"), 1;
    if(pDyingDamageImmune[targetid]) return SCM(playerid, X11_DARK_GOLDENROD_2, "Player is dying immune, thus armour is not permitted"), 1;
    if(isDying[targetid]) return SCM(playerid, X11_DARK_GOLDENROD_2, "Player is dying, giving armour is not possible"), 1;
    if(pData[targetid][pArmour] >= 100) return SCM(playerid, X11_DARK_GOLDENROD_2, "Player armour is full"), 1;
    if(ar <= 5 || ar > 100) return SCM(playerid, X11_DARK_GOLDENROD_2, "Armour Points should not be greater than 100 or less than 5");
    new Float: afterQuip = pData[targetid][pArmour] + ar;
    if(afterQuip > 100.0){
        afterQuip = 100.0 -pData[playerid][pArmour];
        pData[targetid][pArmour] = 100.0;
    }else{
        pData[targetid][pArmour] += ar;
        afterQuip = ar;
    }
    defer __GivePlayerArmour(playerid);
    new string[65 + MAX_NAME + 16 + 1];
    formatex(string, sizeof string, "You have given an additional armour to %P%C by %.2f Armour Points", targetid, X11_GREEN, afterQuip);
    SCM(playerid, X11_GREEN, string);
    formatex(string, sizeof string, "%P%C has given you an additional armour with %.2f Armour Points", playerid, X11_GREEN, afterQuip);
    SCM(targetid, X11_GREEN, string);
    return 1;
}

YCMD:giveplayerhealth(playerid, params[], help){
    #pragma unused help
    new targetid, Float: hp;
    if(sscanf(params, "df", targetid, hp)) return CommandHelp(playerid, "giveplayerhealth", "[Player ID / Part of Name] [Health Points]"), 1;
    if(!CommandPlayerCheck(playerid, targetid)) return 1;
    if(pSpawnImmune[targetid]) return SCM(playerid, X11_DARK_GOLDENROD_2, "Player is under immunity, healing is not needed"), 1;
    if(pDyingDamageImmune[targetid]) return SCM(playerid, X11_DARK_GOLDENROD_2, "Player is dying immune, thus healing is not permitted"), 1;
    if(isDying[targetid]) return SCM(playerid, X11_DARK_GOLDENROD_2, "Player is dying, giving health is not possible"), 1;
    new Float: afterHeal = pData[targetid][pHP] + hp;
    if(pData[targetid][pHP] >= 100) return SCM(playerid, X11_DARK_GOLDENROD_2, "Player health is full"), 1;
    if(hp <= 5 || hp > 100) return SCM(playerid, X11_DARK_GOLDENROD_2, "Health Points should not be greater than 100 or less than 5");
    /*  If after heal is higher than 100
        Just set player health to 100 */
    if(afterHeal > 100.0){
        afterHeal = 100.0 - pData[playerid][pHP];
        pData[targetid][pHP] = 100.0;
    }else{
        pData[targetid][pHP] += hp;
        afterHeal = hp;
    }
    defer __GivePlayerHealth(playerid);
    new string[44 + MAX_NAME + 16 + 1];
    formatex(string, sizeof string, "You have healed %P%C with %.2f Health Points", targetid, X11_GREEN, afterHeal);
    SCM(playerid, X11_GREEN, string);
    formatex(string, sizeof string, "%P%C has healed you with %.2f Health Points", playerid, X11_GREEN, afterHeal);
    SCM(targetid, X11_GREEN, string);
    return 1;
}

YCMD:adminsonline(playerid, params[], help){
    #pragma unused params, help
    new string[15 + 24 + 1], nameString[23 + MAX_NAME + 24 + 1], lString[(13 + MAX_NAME + 25) * MAX_LISTLENGTH];

    inline emptyDialog(pid, dialogid, response, listitem, string:inputtext[]){
        #pragma unused pid, dialogid, response, listitem, inputtext
    }
    if(Group_GetCount(AdminList) != 0){
        if(Group_IsValid(AdminList)){
            foreach(new targetid : GroupMember(AdminList)){
                if(strlen(lString) == 0){
                    switch(pData[playerid][pAdmin]){
                        case 1..6:{
                            formatex(nameString, sizeof nameString, "Admin\tPosition\n%P\t%s", targetid, ModeratorNames[pData[playerid][pAdmin]]);
                        }case 100:{
                            formatex(nameString, sizeof nameString, "Admin\tPosition\n%P\%s", targetid, Group_GetName(pOwners));
                        }
                    }
                }else{
                    switch(pData[playerid][pAdmin]){
                        case 1..6:{
                            formatex(nameString, sizeof nameString, "\n%P\t%s", targetid, ModeratorNames[pData[playerid][pAdmin]]);
                        }case 100:{
                            formatex(nameString, sizeof nameString, "\n%P\%s", targetid, Group_GetName(pOwners));
                        }
                    }
                }
                strcat(lString, nameString, sizeof lString);
            }
        }
        formatex(string, sizeof string, "Online %s List", Group_GetName(AdminList));
        Dialog_ShowCallback(playerid, using inline emptyDialog, DIALOG_STYLE_TABLIST_HEADERS, string, lString, "Close");    
    }else{
        SCM(playerid, X11_DARK_ORCHID_4, "There are no admins online!");
    }
    return 1;
}

YCMD:admincommands(playerid, params[], help){
    #pragma unused help, params

    return 1;
}

YCMD:giveplayermoney(playerid, params[], help){
    #pragma unused help
    new targetid, amount;
    if(sscanf(params, "dd", targetid, amount)) return CommandHelp(playerid, "giveplayermoney", "[Player ID / Part of Name] [Amount]");
    if(!CommandPlayerCheck(playerid, targetid)) return 1;
    pData[targetid][pMoney] += amount;
    new string[MAX_NAME + 11 + 24 + 1];
    formatex(string, sizeof string, "You have given $%d to %P", amount, targetid);
    SCM(playerid, X11_GREEN, string);
    formatex(string, sizeof string, "%P%C has given you $%d", playerid, X11_GREEN, amount);
    SCM(targetid, X11_GREEN, string);
    defer __GivePlayerMoney(targetid);
    return 1;
}

YCMD:giveplayerweapon(playerid, params[], help){
    #pragma unused help
    new targetid, wepid, wepmo;
    if(sscanf(params, "ddd", targetid, wepid, wepmo)) return CommandHelp(playerid, "giveplayerweapon", "[Player ID / Part of Name] [Weapon ID] [Ammo]");
    if(!CommandPlayerCheck(playerid, targetid)) return 1;
    new string[39 + 32 + MAX_NAME + 11 + 1];
    formatex(string, sizeof string, "You have given %W to %P%C with %d ammo.", wepid, targetid, X11_GREEN, wepmo);
    SCM(playerid, X11_GREEN, string);
    formatex(string, sizeof string, "%P%C have given you %W with %d ammo.", playerid, X11_GREEN, wepid, wepmo);
    SCM(targetid, X11_GREEN, string);
    __GivePlayerWeapons(targetid, wepid, wepmo);
    return 1;
}

YCMD:spawnveh(playerid, params[], help) 
{
    #pragma unused help
    new vehid, color[2];
    if(sscanf(params, "dD(-1)D(-1)", vehid, color[0], color[1])) return CommandHelp(playerid, "spawnveh", "[Vehicle ID] [Color 1(Optional)] [Color 2(Optional)]");
    if(vehid < 400 || vehid > 612) return SendClientMessage(playerid, -1, "INVALID VEHICLE ID");
    new Float: __pPos[4], string[20 + 32];
    GetPlayerPos(playerid, __pPos[0], __pPos[1], __pPos[2]);
    GetPlayerFacingAngle(playerid, __pPos[3]);
    formatex(string, sizeof string, "%v has been spawned", vehid);
    SCM(playerid, X11_GREEN, string);
    CreateVehicle(vehid, __pPos[0], __pPos[1], __pPos[2], __pPos[3], color[0], color[1], 0);
    return 1;
}

YCMD:kill(playerid, params[], help){
    #pragma unused params, help
    SetPlayerHealth(playerid, 0);
    return 1;
}

/*
        Error & Return type

    COMMAND_ZERO_RET      = 0 , // The command returned 0.
    COMMAND_OK            = 1 , // Called corectly.
    COMMAND_UNDEFINED     = 2 , // Command doesn't exist.
    COMMAND_DENIED        = 3 , // Can't use the command.
    COMMAND_HIDDEN        = 4 , // Can't use the command don't let them know it exists.
    COMMAND_NO_PLAYER     = 6 , // Used by a player who shouldn't exist.
    COMMAND_DISABLED      = 7 , // All commands are disabled for this player.
    COMMAND_BAD_PREFIX    = 8 , // Used "/" instead of "#", or something similar.
    COMMAND_INVALID_INPUT = 10, // Didn't type "/something".
*/
public e_COMMAND_ERRORS:OnPlayerCommandReceived(playerid, cmdtext[], e_COMMAND_ERRORS:success)
{
    
    switch (success)
    {
        case COMMAND_UNDEFINED:
        {
            return CommandError(playerid, "[STG]: Command does not exists"), COMMAND_DENIED;
        }
        case COMMAND_DENIED:{
            CommandError(playerid, "[STG]: You are not allowed to use this command");
        }
        case COMMAND_ZERO_RET:{
            CommandError(playerid, "[STG]: Something went wrong");
        }
    }
    return success;
}


main() {
}

public OnGameModeInit(){

    SetGameModeText("v 0.0.1");

    DisableInteriorEnterExits();
    EnableStuntBonusForAll(false);
    UsePlayerPedAnims();
    SetNameTagDrawDistance(MAX_PLAYER_LOOKSIE);
    ShowNameTags(true);
    // Weapon-Config Settings
    SetVehiclePassengerDamage(true);
    SetDisableSyncBugs(true);

    forumdb = ForumSecureConnect();
    sampdb = ServerSecureConnect();

    for(new i = 0, j = MAX_DEATHPICKUP; i < j; i++){
        deathPickup[i] = STREAMER_TAG_PICKUP: -1;
    }

    __InitializeCommands();
    return 1;
}

public OnGameModeExit(){
    if(sampdb == MYSQL_DEFAULT_HANDLE){
        mysql_close(sampdb);
    }
    if(forumdb == MYSQL_DEFAULT_HANDLE){
        mysql_close(sampdb);
    }
    return 1;
}

public OnPlayerConnect(playerid){
    SetSpawnInfo(playerid, NO_TEAM, 0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);

    TogglePlayerControllable(playerid, FALSE);
    TogglePlayerSpectating(playerid, TRUE);
    
	static const empty_player[pInfo];
	pData[playerid] = empty_player;

    GetPlayerName(playerid, pData[playerid][pName], MAX_NAME);

    __SetPlayerSkills(playerid);
    SetPlayerColor(playerid, X11_SNOW);
    new query[112 + MAX_NAME];

    inline InitiatePlayerLogin(){
        if(cache_num_rows() != 0){
            cache_get_value_int(0, "uid", pData[playerid][pID]);
            cache_get_value(0, "password", pData[playerid][pPass], MAX_PASS);
            cache_get_value_int(0, "usergroup", pData[playerid][pGroup]);
            pData[playerid][pCache] = cache_save();
            inline doLogin(pid, dialogid, response, listitem, string:inputtext[]){
                #pragma unused pid, dialogid, listitem
                if(response){
                    bcrypt_verify(playerid, "VerifyUserAccount", inputtext, pData[playerid][pPass]);
                }else{
                    SendClientMessage(playerid, X11_FIREBRICK, "You are leaving the server, come again!");
                    defer DisconnectPlayer(playerid);
                }
            }
            Dialog_ShowCallback(playerid, using inline doLogin, DIALOG_STYLE_PASSWORD, "Login", "Welcome to the server, type in your password to enter into the game.", "Login", "Exit");
        }else{
            SCM(playerid, X11_DARK_GOLDENROD_2, "You are not registered on the forums. Please try again.");
            if(cache_is_valid(pData[playerid][pCache]) || pData[playerid][pCache] != MYSQL_INVALID_CACHE){
                cache_delete(pData[playerid][pCache]);
                pData[playerid][pCache] = MYSQL_INVALID_CACHE;
            }
            defer DisconnectPlayer(playerid);
        }
    }

    mysql_format(forumdb, query, sizeof query, "SELECT * FROM stg_users INNER JOIN stg_userfields ON stg_users.uid = stg_userfields.ufid WHERE username = '%e'", pData[playerid][pName]);
    MySQL_TQueryInline(forumdb, using inline InitiatePlayerLogin, query);
    return 1;
}

public OnPlayerDisconnect(playerid, reason){
    #pragma unused reason
    // This will be temporary until I see that Group_GetPlayer has been fixed by the creator/maintainer
    // Ones this data provided here will start giving 1's and not 0's then it means isOnline will be removed for good.
    printf("%d", Group_GetPlayer(OnlinePlayers, playerid));
    if(Group_GetPlayer(OnlinePlayers, playerid) == true || isOnline[playerid] == true){
        // Removing owner level
        if(Group_GetPlayer(pOwners, playerid) == true){
            Group_SetPlayer(pOwners, playerid, false);
        }
        // Removing administrative level
        if(pData[playerid][pAdmin] != 0 && pData[playerid][pAdmin] <= 6 && Group_GetPlayer(pAdmins[pData[playerid][pAdmin]], playerid) == true){
            Group_SetPlayer(pAdmins[pData[playerid][pAdmin]], playerid, false);
        }
        if(pData[playerid][pTag] != INVALID_3DTEXT_ID){
            Delete3DTextLabel(pData[playerid][pTag]);
            pData[playerid][pTag] = INVALID_3DTEXT_ID;
        }
        new query[116 + (15 * 4) + (11 * 4)];
        GetPlayerPos(playerid, pData[playerid][pPos][0], pData[playerid][pPos][1], pData[playerid][pPos][2]);
        GetPlayerFacingAngle(playerid, pData[playerid][pPos][3]);
        pData[playerid][pInterior] = GetPlayerInterior(playerid);
        pData[playerid][pVirtualWorld] = GetPlayerVirtualWorld(playerid);
        pData[playerid][pEquippedGun] = GetPlayerWeapon(playerid);
        GetPlayerHealth(playerid, pData[playerid][pHP]);
        GetPlayerArmour(playerid, pData[playerid][pArmour]);
        inline SaveDisconnect(){
            // __GetPlayerWeapons(playerid);
            static const empty_player[pInfo];
            pData[playerid] = empty_player;
            Group_SetPlayer(OnlinePlayers, playerid, false);
        }
        mysql_format(sampdb, query, sizeof query, "UPDATE stg_chardet SET posx = %f, posy = %f, posz = %f, posa = %f, phealth = %f, parmour = %f, posint = %d, posvw = %d, pgun = %d WHERE pid = %d", pData[playerid][pPos][0], pData[playerid][pPos][1], pData[playerid][pPos][2], pData[playerid][pPos][3], pData[playerid][pHP], pData[playerid][pArmour], pData[playerid][pInterior], pData[playerid][pVirtualWorld], pData[playerid][pEquippedGun], pData[playerid][pID]);
        MySQL_TQueryInline(sampdb, using inline SaveDisconnect, query);
    }
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate){
    if(newstate == oldstate) return 0;
    return 1;
}

public OnPlayerDamage(&playerid, &Float:amount, &issuerid, &weapon, &bodypart){
    if(pDyingDamageImmune[playerid] == true) return 0;
    if(pSpawnImmune[playerid] == true) return 0;
    return 1;
}

public OnPlayerPrepareDeath(playerid, WC_CONST animlib[32], WC_CONST animname[32], &anim_lock, &respawn_time){
    if(Group_GetPlayer(OnlinePlayers, playerid) == true){
        if(isDying[playerid] == false){
            pDyingDamageImmune[playerid] = true;
        }
    }
    return 1;
}

public OnPlayerDeathFinished(playerid, bool: cancelable){
    if(Group_GetPlayer(OnlinePlayers, playerid) == true){
        if(isDying[playerid] == true){
            new mDrop = 0,Float: tmpPos[3], tmpInt, tmpWorld, __pickid, __medid;
            GetPlayerPos(playerid, tmpPos[0], tmpPos[1], tmpPos[2]);
            tmpInt = GetPlayerInterior(playerid);
            tmpWorld = GetPlayerVirtualWorld(playerid);
            GameTextForPlayer(playerid, "~r~A player has finished you off!~n~You've lost some of your money and items.~w~~n~Respawning to the nearest hospital...", 3000, 3);
            if(pData[playerid][pMoney] >= 100){
                new rand = random(20) + 10, Float: perc = float(rand) / 100.0;
                mDrop = floatround(pData[playerid][pMoney] * perc, floatround_floor);
            }
            pData[playerid][pMoney] -= mDrop;
            defer __GivePlayerMoney(playerid);
            __pickid = __GetEmptyDeathPickup();
            __medid = __GetHospitalLocation(playerid);
            // Respawn Player
            SetPlayerPos(playerid, medLoc[__medid][0], medLoc[__medid][1], medLoc[__medid][2]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            // Removes weapons during spawn :D
            SetPlayerArmedWeapon(playerid, 0);
            pSpawnImmune[playerid] = true;
            defer __RemoveImmunity(playerid);
            deathPickup[__pickid] = CreateDynamicPickup(1575, 1, tmpPos[0], tmpPos[1] + 0.5, tmpPos[2], tmpWorld, tmpInt);
            for(new i = 0, j = MAX_SLOTS; i < j; i++){
                if(i != 0 || i != 1 || i != 10 || i != 12){
                    GetPlayerWeaponData(playerid, i, pWepData[playerid][i][pWepID], pWepData[playerid][i][pWepAmmo]);
                    if(pWepData[playerid][i][pWepID] != -1){
                        droppedAmmo[__pickid][i] = __WeponDropSingleClip(playerid, pWepData[playerid][i][pWepID], pWepData[playerid][i][pWepAmmo]);
                        droppedWeapon[__pickid][i] = pWepData[playerid][i][pWepID];
                        pWepData[playerid][i][pWepAmmo] -= droppedAmmo[__pickid][i];
                        __GivePlayerWeapons(playerid, pWepData[playerid][i][pWepID], -droppedAmmo[__pickid][i]);
                    }
                }
            }
            moneyDropped[__pickid] = mDrop;
            dropperId[__pickid] = playerid;
            defer removeDeatchPickup(__pickid);
            pData[playerid][pArmour] = 0;
            pData[playerid][pHP] = 25;
            defer __GivePlayerArmour(playerid);
            defer __GivePlayerHealth(playerid);
            isDying[playerid] = false;
        }else{
            isDying[playerid] = true;
            if(isDying[playerid] == true && pDyingDamageImmune[playerid] == true){
                GameTextForPlayer(playerid, "~y~You are dying!~n~Medics have been alerted of your location!", 3000, 3);
                pDyingDamageImmune[playerid] = false;
            }
        }
    }else{
        TogglePlayerSpectating(playerid, FALSE);
        TogglePlayerControllable(playerid, TRUE);
        SpawnPlayerEx(playerid);
        SCM(playerid, X11_BLACK, "I don't know why you are in the server but you are not deemed a player.");
        SCM(playerid, X11_BLACK, "Whoever you are please leave, if you hacked your way through then this is a warning.");
        SCM(playerid, X11_SNOW, "If not then sorry for the bug. I don't know why this happened either, unless a tool is used this shouldn't happen");
        SCM(playerid, X11_SNOW, "Oh well! I'll kick you now, Come back again!");
        defer DisconnectPlayer(playerid);
    }
    return 0;
}

public OnPlayerPickUpDynamicPickup(playerid, STREAMER_TAG_PICKUP:pickupid){
    for(new i = 0, j = MAX_DEATHPICKUP; i < j; i++){
        if(deathPickup[i] == pickupid){
            // if(dropperId[i] != playerid){
                new string[40 + 11];
                format(string, sizeof string, "You have taken $%d", moneyDropped[i]);
                SCM(playerid, X11_GREEN, string);
                pData[playerid][pMoney] += moneyDropped[i];
                __GivePlayerMoney(playerid);
                for(new k = 0, l = MAX_SLOTS; k < l; k++){
                    if(k != 0 || k != 1 || k != 10 || k != 12){
                        GetPlayerWeaponData(playerid, k, pWepData[playerid][k][pWepID], pWepData[playerid][k][pWepAmmo]);
                        if(pWepData[playerid][k][pWepID] != -1){
                            if(pWepData[playerid][k][pWepID] != 0){
                                if(pWepData[playerid][k][pWepID] == droppedWeapon[i][k]){
                                    __GivePlayerWeapons(playerid, droppedWeapon[i][k], droppedWeapon[i][k]);
                                    formatex(string, sizeof string, "%d of ammo has been added to your %W", droppedAmmo[i][k], droppedWeapon[i][k]);
                                    SCM(playerid, X11_GREEN, string);
                                }
                            }else{
                                if(droppedWeapon[i][k] != 0){
                                    __GivePlayerWeapons(playerid, droppedWeapon[i][k], droppedAmmo[i][k]);
                                    formatex(string, sizeof string, "%d of ammo has been added to your %W", droppedAmmo[i][k], droppedWeapon[i][k]);
                                    SCM(playerid, X11_GREEN, string);
                                }
                            }
                        }
                        droppedWeapon[i][k] = 0;
                        droppedAmmo[i][k] = 0;
                    }
                }
                DestroyDynamicPickup(deathPickup[i]);
                deathPickup[i] = STREAMER_TAG_PICKUP:-1;
                moneyDropped[i] = 0;
                dropperId[i] = INVALID_PLAYER_ID;
                break;
            // }
        }
    }
    return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys){
    return 1;
}

public OnPlayerText(playerid, text[]){
    if(Group_GetPlayer(OnlinePlayers, playerid) == false){
        return SCM(playerid, X11_FIREBRICK, "You are not allowed to use chat when not online"), 0;
    }
    if(strlen(text) >= 128){
        return SCM(playerid, X11_FIREBRICK, "Message too long.");
    }
    new nameString[16 + MAX_NAME + 8 + 4], newText[144], Float: __pos[3];
    GetPlayerPos(playerid, __pos[0], __pos[1], __pos[2]);
    foreach(new targetid : GroupMember(OnlinePlayers)){
        for(new Float: i = MAX_PLAYER_LOOKSIE, Float: j = MIN_PLAYER_LOOKSIE; i >= j; i -= 5.0){
            if(IsPlayerInRangeOfPoint(targetid, i, __pos[0], __pos[1], __pos[2])){
                if(pData[playerid][pAdmin] != 0){
                    switch(pData[playerid][pAdmin]){
                        case 1..6:{
                            formatex(nameString, sizeof nameString, "[%C%s%C]%p: ", GetPlayerColor(playerid), Group_GetName(pAdmins[pData[playerid][pAdmin]]), X11_SNOW, playerid);
                        }
                        case 100:{
                            formatex(nameString, sizeof nameString, "[%C%s%C]%p: ", GetPlayerColor(playerid), Group_GetName(pOwners), X11_SNOW, playerid);
                        }
                    }
                }else{
                    if(pData[playerid][pVIP] != 0){

                    }else{
                        formatex(nameString, sizeof nameString, "%P%C: ", playerid, X11_SNOW);
                    }
                }
                format(newText, sizeof newText, "%s%s", nameString, text);
                SetPlayerChatBubble(playerid, text, X11_SNOW, MAX_PLAYER_LOOKSIE, 15);
                SCM(targetid, X11_SNOW, newText);
                break;
            }
        }
    }
    return 0;
}

public OnPlayerUpdate(playerid){
    return 0;
}

//custom public

forward VerifyUserAccount(playerid, bool:success);
forward SetPlayerOnConnect(playerid);

public VerifyUserAccount(playerid, bool:success){
    if(success){
        TogglePlayerSpectating(playerid, FALSE);
        TogglePlayerControllable(playerid, TRUE);
        SpawnPlayerEx(playerid);
    }else{
        inline doLogin(pid, dialogid, response, listitem, string:inputtext[]){
            #pragma unused pid, dialogid, listitem
            if(response){
                bcrypt_verify(playerid, "VerifyUserAccount", inputtext, pData[playerid][pPass]);
            }else{
                SendClientMessage(playerid, -1, "You are leaving the server, come again!");
                defer DisconnectPlayer(playerid);
            }
        }
        Dialog_ShowCallback(playerid, using inline doLogin, DIALOG_STYLE_PASSWORD, "Login", "Welcome to the server, type in your password to enter into the game.", "Login", "Exit");
    }
}

/* TIMERS */

/*  
    Most of this timers are just for anti-cheats.
    I'm using timers for the specific reason of giving delays to the functions
    With that the giving of items or etc will have a much more fluid adjustment
    Letting the system buffer the data before directly placing into the system
    Although it really doesn't do much, It's just a force of habit plus it's
    Just a 100 ms differential
*/

timer __GivePlayerArmour[100](playerid){
    SetPlayerArmour(playerid, pData[playerid][pArmour]);
}

timer __GivePlayerHealth[100](playerid){
    SetPlayerHealth(playerid, pData[playerid][pHP]);
}

timer __RemoveImmunity[1000 * IMMUNITY_TIME](playerid){
    if(pSpawnImmune[playerid] == true){
        pSpawnImmune[playerid] = false;
    }
}

timer removeDeatchPickup[(1000 * DEATHTIMER_TIME)](pickid){
    DestroyDynamicPickup(deathPickup[pickid]);
    deathPickup[pickid] = STREAMER_TAG_PICKUP: -1;
    moneyDropped[pickid] = 0;
    dropperId[pickid] = INVALID_PLAYER_ID;
}

timer DisconnectPlayer[100](playerid){
    Kick(playerid);
}

timer __SetPlayerScoreBoard[100](playerid){
    switch(pData[playerid][pEXP]){
        case 0..50:{
            if(GetPlayerScore(playerid) != 1){
                SetPlayerScore(playerid, 1);
            }
        }
        case 51..100:{
            if(GetPlayerScore(playerid) != 2){
                SetPlayerScore(playerid, 2);
            }
        }
        case 101..150:{
            if(GetPlayerScore(playerid) != 3){
                SetPlayerScore(playerid, 3);
            }
        }
        case 151..200:{
            if(GetPlayerScore(playerid) != 4){
                SetPlayerScore(playerid, 4);
            }
        }
        case 201..250:{
            if(GetPlayerScore(playerid) != 5){
                SetPlayerScore(playerid, 5);
            }
        }
        case 251..300:{
            if(GetPlayerScore(playerid) != 6){
                SetPlayerScore(playerid, 6);
            }
        }
    }
}

timer __GivePlayerMoney[100](playerid){
    if(GetPlayerMoney(playerid) != 0){
        ResetPlayerMoney(playerid);
    }
    GivePlayerMoney(playerid, pData[playerid][pMoney]);
}

timer __SetPlayerSkin[100](playerid){
    SetPlayerSkin(playerid, pData[playerid][pSkin]);
}