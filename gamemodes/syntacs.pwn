#include <a_samp>
#define FIXES_ServerVarMsg 0
#include <fixes>
#include <a_mysql>

#define PRODUCTION

#define HOST "localhost"
#define USER "root"
#define PASS ""
#define DATA "syntacs_gaming"

#define YSI_NO_HEAP_MALLOC
#include <YSI_Visual\y_dialog>
#include <YSI_Coding\y_timers>
#include <YSI_Visual\y_commands>

#include <samp_bcrypt>
#include <sscanf2>

#define MAX_PLAYER_LOOKSIE 25.0
#define MAX_NAME (MAX_PLAYER_NAME + 1)
#define MAX_PASS 500
#define MAX_EMAIL 220
#define MAX_AFIL 15

enum pInfo{
    pID,
    pName[MAX_NAME],
    pPass[MAX_PASS],
    pEmail[MAX_EMAIL],
    pAffil[MAX_AFIL],
    pReferredPlayers,
    pReputation,
    Float: pCP,
    pGroup
}

new 
    pData[MAX_PLAYERS][pInfo],

    MySQL: db;

SpawnPlayerEx(playerid){
    new query[80 + 11];
    inline loadUserCredentials(){
        if(cache_num_rows() != 0){
            cache_get_value(0, "email", pData[playerid][pEmail], MAX_EMAIL);
            cache_get_value_int(0, "referrals", pData[playerid][pReferredPlayers]);
            cache_get_value_int(0, "reputation", pData[playerid][pReputation]);
            cache_get_value_float(0, "newpoints", pData[playerid][pCP]);
            switch(pData[playerid][pGroup]){
                case 3, 4, 6:{
                    SetPlayerPos(playerid, -1605.6788,719.5027,11.9920);
                    SetPlayerFacingAngle(playerid, 180.7348);
                    SetPlayerVirtualWorld(playerid, 0);
                    SetPlayerInterior(playerid, 0);
                    break;
                }
                case 12:{
                    SetPlayerPos(playerid,-2732.8354,-308.5785,7.1875);
                    SetPlayerFacingAngle(playerid, 233.9780);
                    SetPlayerVirtualWorld(playerid, 0);
                    SetPlayerInterior(playerid, 0);
                    break;
                }
                case 13:{
                    SetPlayerPos(playerid,-2584.2507,1362.2104,7.1935);
                    SetPlayerFacingAngle(playerid, 42.6103);
                    SetPlayerVirtualWorld(playerid, 0);
                    SetPlayerInterior(playerid, 0);
                    break;
                }
            }
            TogglePlayerControllable(playerid, TRUE);
            TogglePlayerSpectating(playerid, FALSE);
            SetCameraBehindPlayer(playerid);
        }
    }
    mysql_format(db, query, sizeof query, "SELECT email, referrals, reputation, newpoints FROM stg_users WHERE uid = '%d'", pData[playerid][pID]);
    MySQL_TQueryInline(db, using inline loadUserCredentials, query);
}

UpdatePlayerGroup(playerid){
    inline updateGroup(){
        if(cache_affected_rows() != 0){
            SetPlayerOnConnect(playerid);
        }
    }
    if(strcmp(pData[playerid][pAffil], "Black Mambas") == 0){
        MySQL_TQueryInline(db, using inline updateGroup, "UPDATE stg_users SET usergroup = 12 WHERE uid = '%d'", pData[playerid][pID]);
    }else if(strcmp(pData[playerid][pAffil], "Silver Knights") == 0){
        MySQL_TQueryInline(db, using inline updateGroup, "UPDATE stg_users SET usergroup = 13 WHERE uid = '%d'", pData[playerid][pID]);
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
    new vehid, color[2];
    if(sscanf(params, "dD{-1}D{-1}", vehid, color[0], color[1])) return CommandHelp(playerid, "spawnveh", "[Vehicle ID] [Color 1(Optional)] [Color 2(Optional)]");
    if(vehid < 400 || vehid > 612) return SendClientMessage(playerid, -1, "INVALID VEHICLE ID");
    new Float: pPos[4];
    GetPlayerPos(playerid, pPos[0], pPos[1], pPos[2]);
    GetPlayerFacingAngle(playerid, pPos[3]);
    CreateVehicle(vehid, pPos[0], pPos[1], pPos[2], pPos[3], color[0], color[1], 0);
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
    return 1;
}

public OnPlayerConnect(playerid){
    SetSpawnInfo(playerid, NO_TEAM, 0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);

    TogglePlayerControllable(playerid, FALSE);
    TogglePlayerSpectating(playerid, TRUE);
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
    new query[69 + MAX_NAME];
    inline loadUserPassword(){
        if(cache_num_rows() != 0){
            cache_get_value_int(0, "uid", pData[playerid][pID]);
            cache_get_value(0, "password", pData[playerid][pPass], MAX_PASS);
            cache_get_value_int(0, "usergroup", pData[playerid][pGroup]);
            print(pData[playerid][pID]);
            print(pData[playerid][pName]);
            print(pData[playerid][pPass]);
            print(pData[playerid][pAffil]);
            print(pData[playerid][pGroup]);
            if(pData[playerid][pGroup] != 2){
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
                inline loadAffiliation(){
                    if(cache_num_rows() != 0){
                        cache_get_value(0, "fid6", pData[playerid][pAffil], MAX_AFIL);
                        if(!isnull(pData[playerid][pAffil])){
                            UpdatePlayerGroup(playerid);
                        }else{
                            SendClientMessage(playerid, -1, "You have not chosen an affiliation yet. Please do it on the forums");
                            defer DisconnectPlayer(playerid);
                        }
                    }else{
                        SendClientMessage(playerid, -1, "You have not chosen an affiliation yet. Please do it on the forums");
                        defer DisconnectPlayer(playerid);
                    }
                }
                mysql_format(db, query, sizeof query, "SELECT fid6 FROM stg_userfields WHERE ufid = '%d'", pData[playerid][pID]);
                MySQL_TQueryInline(db, using inline loadAffiliation, query);
            }
        }else{
            SendClientMessage(playerid, -1, "You are not yet registered on the forums");
        }
    }
    mysql_format(db, query, sizeof query, "SELECT * FROM stg_users WHERE username = '%e'", pData[playerid][pName]);
    MySQL_TQueryInline(db, using inline loadUserPassword, query);

    return 1;
}

timer DisconnectPlayer[100](playerid){
    Kick(playerid);
}