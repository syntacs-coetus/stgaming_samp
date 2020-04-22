#include <a_samp>

#define DEVELOPMENT



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
#include <YSI_Visual\y_dialog>
#include <YSI_Coding\y_timers>
#include <YSI_Visual\y_commands>
#include <YSI_Server\y_colours>

#include <samp_bcrypt>
#include <sscanf2>
#include <streamer>
#include <formatex>


#define MAX_PLAYER_LOOKSIE 25.0
#define MAX_NAME (MAX_PLAYER_NAME + 1)
#define MAX_PASS 500
#define MAX_EMAIL 220
#define MAX_DATETIME 20
#define MAX_DEATHPICKUP 10
#define MAX_SERVHOSP 1
#define MAX_SLOTS 12
#define IMMUNITY_TIME 5
#define DEATHTIMER_TIME 10

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
    pAdmin,
    pKills,
    pDeaths,
    pPrisoned,
    pCaught,
    pSaves,
    pVIP,
    pVIPEXP[MAX_DATETIME],

    pGroup,
    bool: pOnline,
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
    MySQL: sampdb;

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
        new query[119 + (11 * 3) + (11 * 15)];
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
                            // switch(pData[playerid][pGroup]){
                            //     case 3: pData[playerid][pAdmin] = 5;
                            //     case 4: pData[playerid][pAdmin] = 6;
                            //     case 6: pData[playerid][pAdmin] = 1;
                            // }
                            // mysql_format(sampdb, query, sizeof query, "UPDATE stg_chardet SET padmin = %d WHERE pid = %d", pData[playerid][pAdmin], pData[playerid][pID]);
                            // mysql_query(sampdb, query);
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
                pData[playerid][pOnline] = true;

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
    SendClientMessage(playerid, 0x00FFFF, string);
    return 1;
}

YCMD:giveplayerweapon(playerid, params[], help){
    #pragma unused help
    new targetid, wepid, wepmo;
    if(sscanf(params, "ddd", targetid, wepid, wepmo)) return CommandHelp(playerid, "giveplayerweapon", "[Player ID / Part of Name] [Weapon ID] [Ammo]");
    __GivePlayerWeapons(targetid, wepid, wepmo);
    new string[19 + 32];
    formatex(string, sizeof string, "You have given %W", wepid);
    SCM(playerid, X11_SNOW, string);
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
    CreateVehicle(vehid, __pPos[0], __pPos[1], __pPos[2], __pPos[3], color[0], color[1], 0);
    formatex(string, sizeof string, "%v has been spawned", vehid);
    SCM(playerid, X11_DARK_GOLDENROD_2, string);
    return 1;
}

YCMD:kill(playerid, params[], help){
    #pragma unused params, help
    SetPlayerHealth(playerid, 0);
    return 1;
}

main() {
}

public OnGameModeInit(){
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
    if(pData[playerid][pOnline] == true){
        #if !defined DEVELOPMENT
            new query[116 + (15 * 4) + (11 * 4)];
            GetPlayerPos(playerid, pData[playerid][pPos][0], pData[playerid][pPos][1], pData[playerid][pPos][2]);
            GetPlayerFacingAngle(playerid, pData[playerid][pPos][3]);
            pData[playerid][pInterior] = GetPlayerInterior(playerid);
            pData[playerid][pVirtualWorld] = GetPlayerVirtualWorld(playerid);
            pData[playerid][pEquippedGun] = GetPlayerWeapon(playerid);
            GetPlayerHealth(playerid, pData[playerid][pHP]);
            GetPlayerArmour(playerid, pData[playerid][pArmour]);
            inline SaveDisconnect(){
                __GetPlayerWeapons(playerid);
                static const empty_player[pInfo];
                pData[playerid] = empty_player;
            }
            mysql_format(sampdb, query, sizeof query, "UPDATE stg_chardet SET posx = %f, posy = %f, posz = %f, posa = %f, posint = %d, posvw = %d, pgun = %d WHERE pid = %d", pData[playerid][pPos][0], pData[playerid][pPos][1], pData[playerid][pPos][2], pData[playerid][pPos][3], pData[playerid][pInterior], pData[playerid][pVirtualWorld], pData[playerid][pEquippedGun], pData[playerid][pID]);
            MySQL_TQueryInline(sampdb, using inline SaveDisconnect, query);
        #endif
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
    if(pData[playerid][pOnline] == true){
        if(isDying[playerid] == false){
            pDyingDamageImmune[playerid] = true;
        }
    }
    return 1;
}

public OnPlayerDeathFinished(playerid, bool: cancelable){
    if(pData[playerid][pOnline]){
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