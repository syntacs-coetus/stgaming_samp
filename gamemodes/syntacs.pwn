#include <a_samp>
#define FIXES_ServerVarMsg 0
#include <fixes>

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

#define MAX_PLAYER_LOOKSIE 25.0
#define MAX_NAME (MAX_PLAYER_NAME + 1)
#define MAX_PASS 500
#define MAX_EMAIL 220

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
    pGroup,

    bool: pOnline,
    Cache: pCache
}

new 
    pData[MAX_PLAYERS][pInfo],

    MySQL: forumdb,
    MySQL: sampdb;

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
        cache_get_value_int(0, "reputation", pData[playerid][pReputation]);
        cache_get_value_float(0, "newpoints", pData[playerid][pCP]);
        cache_get_value_int(0, "usergroup", pData[playerid][pGroup]);
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
                cache_get_value_int(0, "pint", pData[playerid][pInterior]);
                cache_get_value_int(0, "pvw", pData[playerid][pVirtualWorld]);
                if(!pData[playerid][pPos][0]){
                    switch(pData[playerid][pGroup]){
                        case 3, 4, 6:{
                            pData[playerid][pPos][0] = -1605.6788;
                            pData[playerid][pPos][1] = 719.5027;
                            pData[playerid][pPos][2] = 11.9920;
                            pData[playerid][pPos][3] = 180.7348;
                            pData[playerid][pInterior] = 0;
                            pData[playerid][pVirtualWorld] = 0;
                        }
                        case 12:{
                            pData[playerid][pPos][0] = -2732.8354;
                            pData[playerid][pPos][1] = -308.5785;
                            pData[playerid][pPos][2] = 7.1875;
                            pData[playerid][pPos][3] = 233.9780;
                            pData[playerid][pInterior] = 0;
                            pData[playerid][pVirtualWorld] = 0;
                        }
                        case 13:{
                            pData[playerid][pPos][0] = -2584.2507;
                            pData[playerid][pPos][1] = 1362.2104;
                            pData[playerid][pPos][2] = 7.1935;
                            pData[playerid][pPos][3] = 42.6103;
                            pData[playerid][pInterior] = 0;
                            pData[playerid][pVirtualWorld] = 0;
                        }
                    }
                    mysql_format(sampdb, query, sizeof query, "UPDATE stg_chardet SET posx = '%f', posy = '%f', posz = '%f', posa = '%f', posint = '%d', posvw = '%d' WHERE pid = '%d'", pData[playerid][pPos][0], pData[playerid][pPos][1], pData[playerid][pPos][2], pData[playerid][pPos][3], pData[playerid][pInterior], pData[playerid]  [pVirtualWorld], pData[playerid][pID]);
                    mysql_query(sampdb, query);
                }
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
    pData[playerid][pOnline] = true;
    TogglePlayerControllable(playerid, TRUE);
    TogglePlayerSpectating(playerid, FALSE);
    SetCameraBehindPlayer(playerid);
    SetPlayerPos(playerid, pData[playerid][pPos][0], pData[playerid][pPos][1], pData[playerid][pPos][2]);
    SetPlayerFacingAngle(playerid, pData[playerid][pPos][3]);
    SetPlayerVirtualWorld(playerid, pData[playerid][pInterior]);
    SetPlayerInterior(playerid, pData[playerid][pVirtualWorld]);
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

main() {}

public OnGameModeInit(){
    DisableInteriorEnterExits();
    EnableStuntBonusForAll(false);
    UsePlayerPedAnims();
    SetNameTagDrawDistance(MAX_PLAYER_LOOKSIE);
    ShowNameTags(true);
    forumdb = ForumSecureConnect();
    sampdb = ServerSecureConnect();
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
    new query[45 + MAX_NAME];

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
            cache_delete(pData[playerid][pCache]);
            pData[playerid][pCache] = MYSQL_INVALID_CACHE;
            defer DisconnectPlayer(playerid);
        }
    }

    mysql_format(forumdb, query, sizeof query, "SELECT * FROM stg_users WHERE username = '%e'", pData[playerid][pName]);
    MySQL_TQueryInline(forumdb, using inline InitiatePlayerLogin, query);
    return 1;
}

public OnPlayerDisconnect(playerid, reason){
    if(pData[playerid][pOnline] == true){
        static const empty_player[pInfo];
        pData[playerid] = empty_player;
    }
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason){
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate){
    if(newstate == oldstate) return 0;
    return 1;
}

//custom public

forward VerifyUserAccount(playerid, bool:success);
forward SetPlayerOnConnect(playerid);

public VerifyUserAccount(playerid, bool:success){
    if(success){
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

timer DisconnectPlayer[100](playerid){
    Kick(playerid);
}