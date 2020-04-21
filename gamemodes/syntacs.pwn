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


#define MAX_PLAYER_LOOKSIE 25.0
#define MAX_NAME (MAX_PLAYER_NAME + 1)
#define MAX_PASS 500
#define MAX_EMAIL 220
#define MAX_DATETIME 20
#define MAX_DEATHPICKUP 10

enum pInfo{
    pID,
    pName[MAX_NAME],
    pPass[MAX_PASS],
    pEmail[MAX_EMAIL],
    pReferredPlayers,
    pReputation,
    Float: pCP,
    Float: pPos[4],
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

new 
    pData[MAX_PLAYERS][pInfo],

    bool: pDyingDamageImmune[MAX_PLAYERS],
    bool: isDying[MAX_PLAYERS],
    bool: isCritical[MAX_PLAYERS],

    STREAMER_TAG_PICKUP: deathPickup[MAX_DEATHPICKUP],
    moneyDropped[MAX_DEATHPICKUP],
    dropperId[MAX_DEATHPICKUP],

    Float: spawnLoc[3][4] = {
        {-1605.6788,719.5027,11.9920,180.7348},
        {-2732.8354,-308.5785,7.1875,233.9780},
        {-2584.2507,1362.2104,7.1935,42.6103}
    },

    MySQL: forumdb,
    MySQL: sampdb;

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

YCMD:spawnveh(playerid, params[], help) 
{
    #pragma unused help
    new vehid, color[2];
    if(sscanf(params, "dD{-1}D{-1}", vehid, color[0], color[1])) return CommandHelp(playerid, "spawnveh", "[Vehicle ID] [Color 1(Optional)] [Color 2(Optional)]");
    if(vehid < 400 || vehid > 612) return SendClientMessage(playerid, -1, "INVALID VEHICLE ID");
    new Float: __pPos[4];
    GetPlayerPos(playerid, __pPos[0], __pPos[1], __pPos[2]);
    GetPlayerFacingAngle(playerid, __pPos[3]);
    CreateVehicle(vehid, __pPos[0], __pPos[1], __pPos[2], __pPos[3], color[0], color[1], 0);
    SendClientMessage(playerid, -1, "Vehicle successfully spawned");
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
            inline SaveDisconnect(){
                static const empty_player[pInfo];
                pData[playerid] = empty_player;
            }
            mysql_format(sampdb, query, sizeof query, "UPDATE stg_chardet SET posx = %f, posy = %f, posz = %f, posa = %f, posint = %d, posvw = %d, pgun = %d WHERE pid = %d", pData[playerid][pPos][0], pData[playerid][pPos][1], pData[playerid][pPos][2], pData[playerid][pPos][3], pData[playerid][pInterior], pData[playerid][pVirtualWorld], pData[playerid][pEquippedGun], pData[playerid][pID]);
            MySQL_TQueryInline(sampdb, using inline SaveDisconnect, query);
        #endif
    }
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason){
    if(pData[playerid][pOnline] == false){
        TogglePlayerSpectating(playerid, FALSE);
        TogglePlayerControllable(playerid, TRUE);
        SpawnPlayerEx(playerid);
        SCM(playerid, X11_BLACK, "I don't know why you are in the server but you are not deemed a player.");
        SCM(playerid, X11_BLACK, "Whoever you are please leave, if you hacked your way through then this is a warning.");
        SCM(playerid, X11_SNOW, "If not then sorry for the bug. I don't know why this happened either, unless a tool is used this shouldn't happen");
        SCM(playerid, X11_SNOW, "Oh well! I'll kick you now, Come back again!");
        defer DisconnectPlayer(playerid);
    }
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate){
    if(newstate == oldstate) return 0;
    return 1;
}

public OnPlayerDamage(&playerid, &Float:amount, &issuerid, &weapon, &bodypart){
    if(pDyingDamageImmune[playerid]) return 0;
    return 1;
}

public OnPlayerPrepareDeath(playerid, WC_CONST animlib[32], WC_CONST animname[32], &anim_lock, &respawn_time){
    if(pData[playerid][pOnline]){
        if(!isDying[playerid]){
            pDyingDamageImmune[playerid] = true;
        }
    }
    return 1;
}

public OnPlayerDeathFinished(playerid, bool: cancelable){
    if(pData[playerid][pOnline]){
        new Float: tmpPos[3], tmpInt, tmpWorld, __pickid;
        GetPlayerPos(playerid, tmpPos[0], tmpPos[1], tmpPos[2]);
        tmpInt = GetPlayerInterior(playerid);
        tmpWorld = GetPlayerVirtualWorld(playerid);
        if(isDying[playerid]){
            new mDrop = 0;
            GameTextForPlayer(playerid, "~r~A player has finished you off!~n~You've lost some of your money and items.", 3000, 3);
            if(pData[playerid][pMoney] >= 100){
                new rand = random(20) + 10, Float: perc = float(rand) / 100.0;
                mDrop = floatround(pData[playerid][pMoney] * perc, floatround_floor);
            }
            pData[playerid][pMoney] -= mDrop;
            printf("%d", pData[playerid][pMoney]);
            defer __GivePlayerMoney(playerid);
            __pickid = __GetEmptyDeathPickup();
            SetPlayerPos(playerid, tmpPos[0] + 5.0, tmpPos[1], tmpPos[2]);
            SetPlayerInterior(playerid, tmpInt);
            SetPlayerVirtualWorld(playerid, tmpWorld);
            deathPickup[__pickid] = CreateDynamicPickup(1575, 1, tmpPos[0], tmpPos[1] + 0.5, tmpPos[2], tmpWorld, tmpInt);
            moneyDropped[__pickid] = mDrop;
            dropperId[__pickid] = playerid;
            defer removeDeatchPickup(__pickid);
        }
        isDying[playerid] = true;
        if(isDying[playerid] && pDyingDamageImmune[playerid]){
            GameTextForPlayer(playerid, "~y~You are dying!~n~Medics have been alerted of your location!", 3000, 3);
            pDyingDamageImmune[playerid] = false;
        }
    }
    return 0;
}

public OnPlayerPickUpDynamicPickup(playerid, STREAMER_TAG_PICKUP:pickupid){
    for(new i = 0, j = MAX_DEATHPICKUP; i < j; i++){
        if(deathPickup[i] == pickupid){
            if(dropperId[i] != playerid){
                new string[19 + 11];
                format(string, sizeof string, "You have taken $%d", moneyDropped[i]);
                SCM(playerid, X11_GREEN, string);
                pData[playerid][pMoney] += moneyDropped[playerid];
                __GivePlayerMoney(playerid);
                DestroyDynamicPickup(deathPickup[i]);
                deathPickup[i] = STREAMER_TAG_PICKUP:-1;
                moneyDropped[i] = 0;
                dropperId[i] = INVALID_PLAYER_ID;
                break;
            }
        }
    }
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

timer removeDeatchPickup[10000](pickid){
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