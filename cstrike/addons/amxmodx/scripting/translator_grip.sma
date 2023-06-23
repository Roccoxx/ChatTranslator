#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <grip>
#include <json>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))
#define SwitchPlayerBit(%0,%1)  (IsPlayer(%1) && (%0 ^= (1 << (%1 & 31))))

#pragma semicolon 1

new const PLUGIN_NAME[] = "Chat Translator";
new const PLUGIN_VERSION[] = "1.0";
new const PLUGIN_AUTHOR[] = "Roccoxx & hlstriker";

new const TRANSLATOR_FILE[] = "https://yourhostpijudo.com/extra/TraductorChatGRIP.php";

new g_msgSayText, ConfigFile[64];

public plugin_init(){
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    g_msgSayText = get_user_msgid("SayText");
    register_message(g_msgSayText, "msg_SayText");

    new iEnt = create_entity("info_target");
    if(is_valid_ent(iEnt)){
        RegisterHamFromEntity(Ham_Think, iEnt, "ent_LangMenu");
        entity_set_float(iEnt,EV_FL_nextthink,get_gametime( ) + 5.0);
    }

    get_configsdir(ConfigFile, charsmax(ConfigFile));
    formatex(ConfigFile, charsmax(ConfigFile), "%s/TranslateSay.txt", ConfigFile);
}

/* =========================================================================================
                                            LANGUAGE
========================================================================================= */
public ent_LangMenu(const iEnt){
    if(!is_valid_ent(iEnt)) return HAM_IGNORED;

    static szLanguage[4];
    static iId; iId = 1;
    for(iId = 1; iId <= MAX_PLAYERS; iId++){
        if(!is_user_connected(iId)) continue;
        
        engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, iId), "lang", szLanguage, sizeof(szLanguage)-1);
        if(equal(szLanguage, "") || strlen(szLanguage) > 2) client_cmd(iId, "amx_langmenu");
    }
    
    entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.2);
    return HAM_IGNORED;
}

public msg_SayText(iMsgID, iDest, iReceiver)
{
    if(!is_user_connected(iReceiver)) return PLUGIN_CONTINUE;
    
    static iSender; iSender = get_msg_arg_int(1);

    if(iSender == iReceiver || is_user_bot(iReceiver)) return PLUGIN_CONTINUE;

    static szText[193]; get_msg_arg_string(4, szText, sizeof(szText));

    if(szText[0] == '/') return PLUGIN_CONTINUE;
    
    static szLangFrom[3], szLangTo[3];
    engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, iSender), "lang", szLangFrom, sizeof(szLangFrom)-1);
    engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, iReceiver), "lang", szLangTo, sizeof(szLangTo)-1);
    
    /* If players don't have a language set it to english */
    if(equal(szLangFrom, "")) copy(szLangFrom, sizeof(szLangFrom), "en");
    else if(equal(szLangTo, "")) copy(szLangTo, sizeof(szLangTo), "en");
    
    if(equal(szLangFrom, szLangTo)) return PLUGIN_CONTINUE;
    
    /* macedonian and l33t can't be translated, and Serbian doesn't work well at all */
    if(equal(szLangFrom, "mk") || equal(szLangFrom, "ls") || equal(szLangFrom, "sr")) return PLUGIN_CONTINUE;
    
    /* Change Brazil Portuguese to just Portuguese */
    if(equal(szLangFrom, "bp")) copy(szLangFrom, sizeof(szLangFrom), "pt");
    else if(equal(szLangTo, "bp")) copy(szLangTo, sizeof(szLangTo), "pt");
    
    /* Change Czech's abbreviation to be correct with googles */
    if(equal(szLangFrom, "cz")) copy(szLangFrom, sizeof(szLangFrom), "cs");
    else if(equal(szLangTo, "cz")) copy(szLangTo, sizeof(szLangTo), "cs");
    
    static szMsgType[64];
    
    get_msg_arg_string(2, szMsgType, sizeof(szMsgType));
    
    TranslateText(szText, szMsgType, szLangFrom, szLangTo, iSender, iReceiver);
    
    return PLUGIN_HANDLED;
}

/* =========================================================================================
                                            GRIP
=========================================================================================*/

TranslateText(szText[193], const szMsgType[64], const szLangFrom[3], const szLangTo[3], iSender, iReceiver)
{   
    remove_quotes(szText); trim(szText);

    static szEncodedText[193]; StringURLEncode(szText, szEncodedText, charsmax(szEncodedText));

    static szBuffer[600];
    format(szBuffer, charsmax(szBuffer), "%s?sl=%s&tl=%s&text=%s&id=%d&id2=%d&msgtype=%s", 
    TRANSLATOR_FILE, szLangFrom, szLangTo, szEncodedText, iSender, iReceiver, szMsgType[1]);

    grip_request(
        szBuffer,
        Empty_GripBody,
        GripRequestTypeGet,
        "ReqTranslation"
    );
}

public ReqTranslation()
{
    static GripResponseState:responseState; responseState = grip_get_response_state();

    if(responseState != GripResponseStateSuccessful)
    {
        server_print("Response Status Faild: [ %d ]", responseState);
        return;
    }

    static GripHTTPStatus:status; status = grip_get_response_status_code();
    if (status != GripHTTPStatusOk)
    {
        server_print("Status Code: [ %d ]", status);
        return;
    }

    static szResponse[1024];
    
    static GripJSONValue:responseBody; responseBody = grip_json_parse_response_body(szResponse, charsmax(szResponse));
    
    if(responseBody == Invalid_GripJSONValue)
    {
        server_print("JSON Invalido: [ %d ]", Invalid_GripJSONValue);
        return;
    }

    static szId[6];

    static GripJSONValue:jValue; jValue = grip_json_object_get_value(responseBody, "sender");
    grip_json_get_string(jValue, szId, charsmax(szId));
    grip_destroy_json_value(jValue);

    static iSender; iSender = str_to_num(szId);

    jValue = grip_json_object_get_value(responseBody, "receiver");
    grip_json_get_string(jValue, szId, charsmax(szId));
    grip_destroy_json_value(jValue);

    static iReceiver; iReceiver = str_to_num(szId);

    if(iSender <= 0 || iReceiver <= 0){
        server_print("Emisor o Receptor no válido: %d & %d", iSender, iReceiver);
        grip_destroy_json_value(responseBody);
        return;
    }

    static szMsgType[64];
    jValue = grip_json_object_get_value(responseBody, "msgtype");
    grip_json_get_string(jValue, szMsgType, charsmax(szMsgType));
    grip_destroy_json_value(jValue);

    format(szMsgType, charsmax(szMsgType), "#%s", szMsgType);

    static szDataSay[192]; 
    jValue = grip_json_object_get_value(responseBody, "text");
    grip_json_get_string(jValue, szDataSay, charsmax(szDataSay));
    grip_destroy_json_value(jValue);

    grip_destroy_json_value(responseBody);

    static szLangFrom[3], szLangTo[3];
    engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, iSender), "lang", szLangFrom, sizeof(szLangFrom)-1);
    engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, iReceiver), "lang", szLangTo, sizeof(szLangTo)-1);
    strtoupper(szLangFrom); strtoupper(szLangTo);
            
    /* If players don't have a language set it to english */

    if(equal(szLangFrom, "")) copy(szLangFrom, sizeof(szLangFrom), "EN");
    else if(equal(szLangTo, "")) copy(szLangTo, sizeof(szLangTo), "EN");

    replace_all(szDataSay, charsmax(szDataSay), "%", "");

    format(szDataSay, sizeof(szDataSay), "[%s->%s] %s^r^n", szLangFrom, szLangTo, szDataSay);
                        
    message_begin(MSG_ONE, g_msgSayText, _, iReceiver);
    write_byte(iSender);
    write_string(szMsgType);
    write_string("");
    write_string(szDataSay);
    message_end();

    iSender = 0;
    iReceiver = 0;
    szDataSay[0] = '^0';
}

stock StringURLEncode( const szInput[ ], szOutput[ ], const iLen )
{
    static const HEXCHARS[ 16 ] = {
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
        0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66
    };
    
    new iPos, cChar, iFLen;
    while( ( cChar = szInput[ iPos ] ) && iFLen < iLen )
    {
        if( cChar == 0x20 )
        {
            szOutput[ iFLen++ ] = 0x2B;
        }
        else if( !( 0x41 <= cChar <= 0x5A )
        && !( 0x61 <= cChar <= 0x7A )
        && !( 0x30 <= cChar <= 0x39 )
        && cChar != 0x2D
        && cChar != 0x2E
        && cChar != 0x5F )
        {
            if( ( iFLen + 3 ) > iLen )
            {
                break;
            }
            else if( cChar > 0xFF
            || cChar < 0x00 )
            {
                cChar = 0x2A;
            }
            
            szOutput[ iFLen++ ] = 0x25;
            szOutput[ iFLen++ ] = HEXCHARS[ cChar >> 4 ];
            szOutput[ iFLen++ ] = HEXCHARS[ cChar & 15 ];
        }
        else
        {
            szOutput[ iFLen++ ] = cChar;
        }
        
        iPos++;
    }
    
    szOutput[ iFLen ] = 0;
    return iFLen;
}