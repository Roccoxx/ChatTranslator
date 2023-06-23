#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <curl>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))
#define SwitchPlayerBit(%0,%1)  (IsPlayer(%1) && (%0 ^= (1 << (%1 & 31))))

#pragma semicolon 1

new const PLUGIN_NAME[] = "Chat Translator";
new const PLUGIN_VERSION[] = "1.0";
new const PLUGIN_AUTHOR[] = "Roccoxx & hlstriker";

new const TRANSLATOR_FILE[] = "https://yourhostpijudo.com/TraductorChat.php";

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

    if(iSender == iReceiver) return PLUGIN_CONTINUE;

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

TranslateText(szText[193], const szMsgType[64], const szLangFrom[3], const szLangTo[3], iSender, iReceiver)
{
    static CURL:cSession; cSession = curl_easy_init();

    if(!cSession) return;

    static iData[70]; 

    iData[0] = fopen(ConfigFile, "w");

    iData[1] = iSender; iData[2] = iReceiver;
    format(iData[3], charsmax(iData), szMsgType);

    curl_easy_setopt(cSession, CURLOPT_BUFFERSIZE, 1024);

    remove_quotes(szText);
    trim(szText);

    static szEncodedText[193]; StringURLEncode(szText, szEncodedText, charsmax(szEncodedText));
 
    static szBuffer[500];
    format(szBuffer, charsmax(szBuffer), "%s?sl=%s&tl=%s&text=%s", TRANSLATOR_FILE, szLangFrom, szLangTo, szEncodedText);

    curl_easy_setopt(cSession, CURLOPT_URL, szBuffer);
    curl_easy_setopt(cSession, CURLOPT_WRITEDATA, iData[0]);
    curl_easy_setopt(cSession, CURLOPT_WRITEFUNCTION, "write");
    curl_easy_perform(cSession, "OnCURL_Vinculation_Perform", iData, sizeof(iData));

    log_amx("Test iData %s", iData);
} 

public write(const data[], size, nmemb, file)
{
    new iCurrentSize = size * nmemb;
    fwrite_blocks(file, data, iCurrentSize, BLOCK_CHAR );
    log_amx("Test write %s - %s", file, data);
    return iCurrentSize;
}

public OnCURL_Vinculation_Perform(const CURL:CURL, const CURLcode:szCode, const cData[ ] )
{
    if(szCode == CURLE_WRITE_ERROR) server_print("Ocurrio un problema al realizar la traduccion");

    fclose(cData[0]);
    curl_easy_cleanup(CURL);

    static iFile; iFile = fopen(ConfigFile, "r");
    static szDataSay[200];

    while(!feof(iFile))
    {
        fgets(iFile, szDataSay, charsmax(szDataSay));

        if(szDataSay[0] == '{' || szDataSay[0] == '}' || szDataSay[0] == ' ' || equal(szDataSay, "response") || equal(szDataSay, "players") || equal(szDataSay, "0")){
            szDataSay[0] = EOS;
            continue;
        }
    }

    fclose( iFile );

    log_amx("Test 1");

    if(!szDataSay[0]) return;

    static iSender; iSender = cData[1]; 
    static iReceiver; iReceiver = cData[2];

    static szMsgType[64]; format(szMsgType, sizeof(szMsgType), "%s", cData[3]);
            
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

    log_amx("Test %s", szDataSay);

    szDataSay[192] = '^0';
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