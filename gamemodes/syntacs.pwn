#include <a_samp>
#define FIXES_ServerVarMsg 0
#include <fixes>

#define PRODUCTION

#define HOST "127.0.0.1"
#define USER "root"
#define PASS ""
#define FORM "syntacs_gaming"
#define SAMP "stgaming_samp"
#include <a_mysql>

#define YSI_YES_HEAP_MALLOC
#include <YSI_Visual\y_dialog>
#include <YSI_Coding\y_timers>
#include <YSI_Visual\y_commands>

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
    new MySQLOpt: option_id = mysql_init_options();
    mysql_set_option(option_id, AUTO_RECONNECT, true);

    return mysql_connect(HOST, USER, PASS, FORM, option_id);
}

MySQL: ServerSecureConnect(){
    new MySQLOpt: option_id = mysql_init_options();
    mysql_set_option(option_id, AUTO_RECONNECT, true);

    return mysql_connect(HOST, USER, PASS, SAMP, option_id);
}

SpawnPlayerEx(playerid){
    if(cache_is_valid(pData[playerid][pCache])){
        cache_set_active(pData[playerid][pCache]);
        cache_get_value(0, "email", pData[playerid][pEmail], MAX_EMAIL);
        cache_get_value_name_int(0, "referrals", pData[playerid][pReferredPlayers]);
        cache_get_value_int(0, "reputation", pData[playerid][pReputation]);
        cache_get_value_float(0, "newpoints", pData[playerid][pCP]);
        cache_get_value_int(0, "usergroup", pData[playerid][pGroup]);
        if(pData[playerid][pGroup == 2]){
            new affiliation[15];
            cache_get_value(0, "fid6", affiliation, sizeof affiliation);
            if(strcmp(affiliation, "Black Mambas") == 0){
                mysql_format(db, query, sizeof query, "UPDATE stg_users SET usergroup = 12 WHERE uid = %d", pData[playerid][pID]);
                mysql_tquery(db, query);
                pData[playerid][pGroup] = 12;
            }else if(strcmp(affiliation, "Silver Knights") == 0){
                mysql_format(db, query, sizeof query, "UPDATE stg_users SET usergroup = 13 WHERE uid = %d", pData[playerid][pID]);
                mysql_tquery(db, query);
                pData[playerid][pGroup] = 13;
            }else{
                mysql_format(db, query, sizeof query, "UPDATE stg_users SET usergroup = 14 WHERE uid = %d", pData[playerid][pID]);
                mysql_tquery(db, query);
                pData[playerid][pGroup] = 14;
            }
        }
        switch(pData[playerid][pGroup]){
            case 3, 4, 6:{
                pData[playerid][pPos][0] = -1605.6788;
                pData[playerid][pPos][1] = 719.5027;
                pData[playerid][pPos][2] = 11.9920;
                pData[playerid][pPos][3] = 180.7348;
            }
            case 12:{
                pData[playerid][pPos][0] = -2732.8354;
                pData[playerid][pPos][1] = -308.5785;
                pData[playerid][pPos][2] = 7.1875;
                pData[playerid][pPos][3] = 233.9780;
            }
            case 13:{
                pData[playerid][pPos][0] = -2584.2507;
                pData[playerid][pPos][1] = 1362.2104;
                pData[playerid][pPos][2] = 7.1935;
                pData[playerid][pPos][3] = 42.6103;
            }
        }
        // Remove cache because player is now spawned.
        // This is for security to and avoid cache leakge.
        cache_delete(pData[playerid][pCache]);
        pData[playerid][pCache] = MYSQL_INVALID_CACHE;
    }else{
        pData[playerid][pPos][0] = -1605.6788;
        pData[playerid][pPos][1] = 719.5027;
        pData[playerid][pPos][2] = 11.9920;
        pData[playerid][pPos][3] = 180.7348;
    }
    pData[playerid][pOnline] = true;
    TogglePlayerControllable(playerid, TRUE);
    TogglePlayerSpectating(playerid, FALSE);
    SetCameraBehindPlayer(playerid);
    SetPlayerPos(playerid, pData[playerid][pPos][0], pData[playerid][pPos][1], pData[playerid][pPos][2]);
    SetPlayerFacingAngle(playerid, pData[playerid][pPos][3]);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
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

main() {
}

public OnGameModeInit(){
    DisableInteriorEnterExits();
    EnableStuntBonusForAll(false);
    UsePlayerPedAnims();
    SetNameTagDrawDistance(MAX_PLAYER_LOOKSIE);
    ShowNameTags(true);

    new MySQLOpt: option_id = mysql_init_options();
    mysql_set_option(option_id, AUTO_RECONNECT, true);

    db = mysql_connect(HOST, USER, PASS, DATA, option_id);
    if(db == MYSQL_INVALID_HANDLE || mysql_errno(db) != 0){
        print("Cannot connect to MySQL Server, shutting down...");

        SendRconCommand("exit");
        return 1;
    }
    return 1;
}

public OnGameModeExit(){
    mysql_close(db);
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

    #if defined PRODUCTION
        SetPlayerOnConnect(playerid);
    #else
        SpawnPlayerEx(playerid);
    #endif
    return 1;
}

public OnPlayerDisconnect(playerid, reason){
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

public SetPlayerOnConnect(playerid){
    new query[262 + MAX_NAME];
    inline doLogin(){
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
                    SendClientMessage(playerid, -1, "You are leaving the server, come again!");
                    defer DisconnectPlayer(playerid);
                }
            }
            Dialog_ShowCallback(playerid, using inline doLogin, DIALOG_STYLE_PASSWORD, "Login", "Welcome to the server, type in your password to enter into the game.", "Login", "Exit");
        }else{
            SendClientMessage(playerid, -1, "You are not yet registered on the forums");
        }
    }
    mysql_format(db, query, sizeof query, "SELECT * FROM stg_users LEFT JOIN stg_userfields ON stg_users.uid = stg_userfields.ufid WHERE username = '%e'", pData[playerid][pName]);
    MySQL_TQueryInline(db, using inline doLogin, query);
    return 1;
}

timer DisconnectPlayer[100](playerid){
    Kick(playerid);
}