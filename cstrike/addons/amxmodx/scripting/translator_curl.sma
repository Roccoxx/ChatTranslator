#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <curl>
#include <json>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))
#define SwitchPlayerBit(%0,%1)  (IsPlayer(%1) && (%0 ^= (1 << (%1 & 31))))

#define MSG_TYPE_SIZE 64

// Don't change this pls
#define MAX_RESPONSE_WAIT_TIME 7

#pragma semicolon 1

new const PLUGIN_NAME[] = "Chat Translator";
new const PLUGIN_VERSION[] = "1.1.1";
new const PLUGIN_AUTHOR[] = "Roccoxx & hlstriker";

new g_msgSayText;

new bool:g_bIsInTranslation[33][33];
new Trie:g_tUserTranslations; // key userid+languageToTranslate

new const szClassNameEntPijuda[] = "EntityPijuda";

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    g_msgSayText = get_user_msgid("SayText");
    register_message(g_msgSayText, "SayTextMessage");

    new iEnt = create_entity("info_target");
    if (is_valid_ent(iEnt)){
        entity_set_string(iEnt, EV_SZ_classname, szClassNameEntPijuda);
        register_think(szClassNameEntPijuda, "LangMenuEntity");
        entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 5.0);
    }

    g_tUserTranslations = TrieCreate();
}

public LangMenuEntity(const iEnt)
{
    if (!is_valid_ent(iEnt))
    	return;

    static szLanguage[4];
    static iId;
    for (iId = 1; iId <= MAX_PLAYERS; iId++) {
        if (!is_user_connected(iId)) 
        	continue;
        
        engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, iId), "lang", szLanguage, charsmax(szLanguage));
        
        if (equal(szLanguage, "") || strlen(szLanguage) > 2) 
        	client_cmd(iId, "amx_langmenu");
    }
    
    entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.2);
}

public SayTextMessage(iMsgID, iDest, iReceiver)
{
	if (!is_user_connected(iReceiver)) 
		return PLUGIN_CONTINUE;

	static iSender; 
	iSender = get_msg_arg_int(1);

	if(iSender == iReceiver) 
		return PLUGIN_CONTINUE;

	if (g_bIsInTranslation[iSender][iReceiver]) {
		client_print_color(iSender, iSender, "^4[TRANSLATOR]^1 Wait, your latest message is until in translation...");
		return PLUGIN_CONTINUE;
	}

	static szText[193]; 
	get_msg_arg_string(4, szText, charsmax(szText));

	if(szText[0] == '/') 
		return PLUGIN_CONTINUE;

	static szLangFrom[3], szLangTo[3];
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, iSender), "lang", szLangFrom, charsmax(szLangFrom));
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, iReceiver), "lang", szLangTo, charsmax(szLangTo));

	if(equal(szLangFrom, szLangTo)) 
		return PLUGIN_CONTINUE;

	/* macedonian and l33t can't be translated, and Serbian or Bulgarian doesn't work well at all */
	if (equal(szLangFrom, "mk") || equal(szLangFrom, "ls") || equal(szLangFrom, "sr") || equal(szLangFrom, "bg")) 
		return PLUGIN_CONTINUE;

	/* If players don't have a language set it to english */
	if (equal(szLangFrom, "")) 
		copy(szLangFrom, charsmax(szLangFrom), "en");
		
	if (equal(szLangTo, "")) 
		copy(szLangTo, charsmax(szLangTo), "en");

	/* Change Brazil Portuguese to just Portuguese */
	if (equal(szLangFrom, "bp")) 
		copy(szLangFrom, charsmax(szLangFrom), "pt");

	if (equal(szLangTo, "bp")) 
		copy(szLangTo, charsmax(szLangTo), "pt");

	/* Change Czech's abbreviation to be correct with googles */
	if (equal(szLangFrom, "cz")) 
		copy(szLangFrom, charsmax(szLangFrom), "cs");
	
	if (equal(szLangTo, "cz")) 
		copy(szLangTo, charsmax(szLangTo), "cs");

	static szMsgType[MSG_TYPE_SIZE];
	get_msg_arg_string(2, szMsgType, charsmax(szMsgType));

	TranslateText(szText, szMsgType, szLangFrom, szLangTo, iSender, iReceiver);

	return PLUGIN_HANDLED;
}

TranslateText(szText[193], const szMsgType[MSG_TYPE_SIZE], const szLangFrom[3], const szLangTo[3], iSender, iReceiver)
{
	static CURL:cSession; cSession = curl_easy_init();

	if (!cSession) 
		return;

	static szUserKey[10];
	formatex(szUserKey, charsmax(szUserKey), "%d %s", iSender, szLangTo);

	if (TrieKeyExists(g_tUserTranslations, szUserKey))
		return;

	TrieSetCell(g_tUserTranslations, szUserKey, iSender);

	static szConfigFile[64];
	get_configsdir(szConfigFile, charsmax(szConfigFile));
	format(szConfigFile, charsmax(szConfigFile), "%s/TranslateSay%d_%s.txt", szConfigFile, iSender, szLangTo);

	static iFile;
	iFile = fopen(szConfigFile, "w");

	static szData[MAX_FMT_LENGTH];
	format(szData, charsmax(szData), "%d %d %d %s %s %s", iSender, iReceiver, iFile, szLangFrom, szLangTo, szMsgType);

	static szEncodedText[193]; 
	remove_quotes(szText);
	trim(szText);
	StringURLEncode(szText, szEncodedText, charsmax(szEncodedText));
	replace(szEncodedText, charsmax(szEncodedText), " ", "%20");

	static szRequestURL[500];
	format(szRequestURL, charsmax(szRequestURL), "https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=%s&tl=%s&dt=t&q=%s", szLangFrom, szLangTo, szEncodedText); 

	curl_easy_setopt(cSession, CURLOPT_URL, szRequestURL);
	curl_easy_setopt(cSession, CURLOPT_WRITEDATA, iFile);
	curl_easy_setopt(cSession, CURLOPT_WRITEFUNCTION, "WriteTranslation");
	curl_easy_setopt(cSession, CURLOPT_EXPECT_100_TIMEOUT_MS, MAX_RESPONSE_WAIT_TIME);
	curl_easy_perform(cSession, "CURLVinculationPerform", szData, charsmax(szData));

	remove_task(iSender);
	set_task(float(MAX_RESPONSE_WAIT_TIME), "RemoveUserTranslations", iSender);
}

public WriteTranslation(const data[], size, nmemb, file)
{
    new iCurrentSize = size * nmemb;
    fwrite_blocks(file, data, iCurrentSize, BLOCK_CHAR );
    return iCurrentSize;
}

public client_disconnected(iId, bool:drop, message[], maxlen)
{
	remove_task(iId);
	RemoveUserTranslations(iId);
}

public RemoveUserTranslations(const iSender)
{
	new szUserId[5];
	num_to_str(iSender, szUserId, charsmax(szUserId));

	new TrieIter:iter = TrieIterCreate(g_tUserTranslations);{
		new szKey[32], szValue[5];

		while (!TrieIterEnded(iter)){
			TrieIterGetKey(iter, szKey, charsmax(szKey));
			TrieIterGetString(iter, szValue, charsmax(szValue));

			if (equal(szValue, szUserId))
				TrieDeleteKey(g_tUserTranslations, szKey);

			TrieIterNext(iter);
		}
	}

	TrieIterDestroy(iter);

	arrayset(g_bIsInTranslation[iSender], false, 33);
}

public CURLVinculationPerform(const CURL:CURL, const CURLcode:code, const cData[ ] )
{
	static szSenderIndex[5], szReceiverIndex[5], szFileHandler[20], szLangFrom[3], szLangTo[3], szMsgType[MSG_TYPE_SIZE];
    
	parse(cData, 
		szSenderIndex, charsmax(szSenderIndex), 
		szReceiverIndex, charsmax(szReceiverIndex), 
		szFileHandler, charsmax(szFileHandler), 
		szLangFrom, charsmax(szLangFrom),
		szLangTo, charsmax(szLangTo),
		szMsgType, charsmax(szMsgType)
	);

	static iFile; 
	iFile = str_to_num(szFileHandler);
	fclose(iFile);

	static iSender; 
	iSender = str_to_num(szSenderIndex); 

	static iOriginalReceiver; 
	iOriginalReceiver = str_to_num(szSenderIndex); 

	static szUserKey[10];
	formatex(szUserKey, charsmax(szUserKey), "%d %s", iSender, szLangTo);

	g_bIsInTranslation[iSender][iOriginalReceiver] = false;

	if (!TrieKeyExists(g_tUserTranslations, szUserKey)) {
		curl_easy_cleanup(CURL);
		return;
	}

	TrieDeleteKey(g_tUserTranslations, szUserKey);

	if (!is_user_connected(iSender)) {
		curl_easy_cleanup(CURL);
		return;
	}

	if (code == CURLE_WRITE_ERROR) {
		server_print("Write Translation problem");
		curl_easy_cleanup(CURL);
		return;
	}

	if (code != CURLE_OK) {
	    server_print("Error with status Code: [ %d ]", code);
	    curl_easy_cleanup(CURL);
	    return;
	}

	static status_code; 
	curl_easy_getinfo(CURL, CURLINFO_RESPONSE_CODE, status_code);

	if (status_code != 200) {
		server_print("Error, status_code: %d", status_code);
		curl_easy_cleanup(CURL);
		return;
	}

	curl_easy_cleanup(CURL);

	SendTranslation(iSender, szLangFrom, szLangTo, szMsgType);
}

SendTranslation(const iSender, szLangFrom[3], szLangTo[3], szMsgType[MSG_TYPE_SIZE])
{
	static szConfigFile[64];
	get_configsdir(szConfigFile, charsmax(szConfigFile));
	format(szConfigFile, charsmax(szConfigFile), "%s/TranslateSay%d_%s.txt", szConfigFile, iSender, szLangTo);

	static iFile;
	iFile = fopen(szConfigFile, "r");
	
	static szDataSay[193];

	while (!feof(iFile)) {
	    fgets(iFile, szDataSay, charsmax(szDataSay));

	    if(szDataSay[0] == '{' || szDataSay[0] == '}' || szDataSay[0] == ' ' || equal(szDataSay, "response") || equal(szDataSay, "players") || equal(szDataSay, "0")){
	        szDataSay[0] = EOS;
	        continue;
	    }
	}

	fclose(iFile);

	if (!szDataSay[0]) 
		return;

	new JSON:json_handle = json_parse(szDataSay);

	if (json_handle == Invalid_JSON)
		return;

	json_array_get_string(json_handle, 0, szDataSay, charsmax(szDataSay));
	json_free(json_handle);

	replace_all(szDataSay, charsmax(szDataSay), "%", "");
	format_translation(szDataSay, szLangTo);

	/* Change Brazil Portuguese to just Portuguese */
	if (equal(szLangFrom, "pt")) 
		copy(szLangFrom, charsmax(szLangFrom), "bp");

	if (equal(szLangTo, "pt")) 
		copy(szLangTo, charsmax(szLangTo), "bp");

	/* Change Czech's abbreviation to be correct with googles */
	if (equal(szLangFrom, "cs")) 
		copy(szLangFrom, charsmax(szLangFrom), "cz");
	
	if (equal(szLangTo, "cs")) 
		copy(szLangTo, charsmax(szLangTo), "cz");

	format(szDataSay, charsmax(szDataSay), "[%s->%s] %s^r^n", szLangFrom, szLangTo, szDataSay);

	static iReceiver;
	static szReceiverLang[3];

	for (iReceiver = 1; iReceiver <= MAX_PLAYERS; iReceiver++) {
		if (iSender == iReceiver)
			continue;

		if (!is_user_connected(iReceiver))
        	continue;
        
		engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, iReceiver), "lang", szReceiverLang, charsmax(szReceiverLang));
        
		if (equal(szReceiverLang, szLangTo)) {
			message_begin(MSG_ONE, g_msgSayText, _, iReceiver);
			write_byte(iSender);
			write_string(szMsgType);
			write_string("");
			write_string(szDataSay);
			message_end();
        }

		g_bIsInTranslation[iSender][iReceiver] = false;
    }
}

format_translation(szTranslation[193], const szLangTo[3])
{
	if (equal(szLangTo, "de")) {
		replace(szTranslation, charsmax(szTranslation), "Ä", "Ae");
		replace(szTranslation, charsmax(szTranslation), "ä", "ae");
		replace(szTranslation, charsmax(szTranslation), "Ö", "Oe");
		replace(szTranslation, charsmax(szTranslation), "ö", "oe");
		replace(szTranslation, charsmax(szTranslation), "Ü", "Ue");
		replace(szTranslation, charsmax(szTranslation), "ü", "ue");
		replace(szTranslation, charsmax(szTranslation), "ß", "ss");
	}
	else if(equal(szLangTo, "tr"))
	{
		// Turkish
		replace(szTranslation, charsmax(szTranslation), "Ö", "O");
		replace(szTranslation, charsmax(szTranslation), "ö", "o");
		replace(szTranslation, charsmax(szTranslation), "Ü", "U");
		replace(szTranslation, charsmax(szTranslation), "ü", "u");
		replace(szTranslation, charsmax(szTranslation), "Ç", "C");
		replace(szTranslation, charsmax(szTranslation), "ç", "c");
		replace(szTranslation, charsmax(szTranslation), "ý", "y");
		replace(szTranslation, charsmax(szTranslation), "þ", "p");
	}
	else if(equal(szLangTo, "fr"))
	{
		// French
		replace(szTranslation, charsmax(szTranslation), "à", "a");
		replace(szTranslation, charsmax(szTranslation), "è", "e");
		replace(szTranslation, charsmax(szTranslation), "ô", "o");
		replace(szTranslation, charsmax(szTranslation), "ù", "u");
		replace(szTranslation, charsmax(szTranslation), "Ç", "C");
		replace(szTranslation, charsmax(szTranslation), "Œ", "CE");
		replace(szTranslation, charsmax(szTranslation), "â", "a");
		replace(szTranslation, charsmax(szTranslation), "ê", "e");
		replace(szTranslation, charsmax(szTranslation), "î", "i");
		replace(szTranslation, charsmax(szTranslation), "û", "u");
		replace(szTranslation, charsmax(szTranslation), "é", "e");
		replace(szTranslation, charsmax(szTranslation), "ë", "e");
		replace(szTranslation, charsmax(szTranslation), "ï", "i");
		replace(szTranslation, charsmax(szTranslation), "ç", "c");
	}
	else if(equal(szLangTo, "sv"))
	{
		// Swedish
		replace(szTranslation, charsmax(szTranslation), "ö", "o");
		replace(szTranslation, charsmax(szTranslation), "å", "a");
		replace(szTranslation, charsmax(szTranslation), "ä", "a");
		replace(szTranslation, charsmax(szTranslation), "Ö", "O");
		replace(szTranslation, charsmax(szTranslation), "Å", "A");
		replace(szTranslation, charsmax(szTranslation), "Ä", "A");
	}
	else if(equal(szLangTo, "da"))
	{
		// Danish
		replace(szTranslation, charsmax(szTranslation), "å", "aa");
		replace(szTranslation, charsmax(szTranslation), "ø", "o");
		replace(szTranslation, charsmax(szTranslation), "æ", "ae");
		replace(szTranslation, charsmax(szTranslation), "Å", "Aa");
		replace(szTranslation, charsmax(szTranslation), "Æ", "Ae");
		replace(szTranslation, charsmax(szTranslation), "Ø", "Oe");
	}
	else if(equal(szLangTo, "nl"))
	{
		// Dutch
		replace(szTranslation, charsmax(szTranslation), "ë", "e");
		replace(szTranslation, charsmax(szTranslation), "ï", "i");
	}
	else if(equal(szLangTo, "fi"))
	{
		// Finnish
		replace(szTranslation, charsmax(szTranslation), "Ä", "A");
		replace(szTranslation, charsmax(szTranslation), "Ö", "O");
		replace(szTranslation, charsmax(szTranslation), "ä", "a");
		replace(szTranslation, charsmax(szTranslation), "ö", "o");
	}
	else if(equal(szLangTo, "ro"))
	{
		// Romanian
		replace(szTranslation, charsmax(szTranslation), "A", "A");
		replace(szTranslation, charsmax(szTranslation), "Î", "I");
		replace(szTranslation, charsmax(szTranslation), "S", "S");
		replace(szTranslation, charsmax(szTranslation), "T", "T");
		replace(szTranslation, charsmax(szTranslation), "Â", "A");
		replace(szTranslation, charsmax(szTranslation), "a", "a");
		replace(szTranslation, charsmax(szTranslation), "î", "i");
		replace(szTranslation, charsmax(szTranslation), "s", "s");
		replace(szTranslation, charsmax(szTranslation), "t", "t");
		replace(szTranslation, charsmax(szTranslation), "â", "a");
	}
	else if(equal(szLangTo, "lt"))
	{
		// Lithuania
		replace(szTranslation, charsmax(szTranslation), "Ą", "A");
		replace(szTranslation, charsmax(szTranslation), "ą", "a");
		replace(szTranslation, charsmax(szTranslation), "Č", "C");
		replace(szTranslation, charsmax(szTranslation), "č", "c");
		replace(szTranslation, charsmax(szTranslation), "Ę", "E");
		replace(szTranslation, charsmax(szTranslation), "ę", "e");
		replace(szTranslation, charsmax(szTranslation), "Ė", "E");
		replace(szTranslation, charsmax(szTranslation), "ė", "e");
		replace(szTranslation, charsmax(szTranslation), "Į", "I");
		replace(szTranslation, charsmax(szTranslation), "į", "i");
		replace(szTranslation, charsmax(szTranslation), "Š", "S");
		replace(szTranslation, charsmax(szTranslation), "š", "s");
		replace(szTranslation, charsmax(szTranslation), "Ų", "U");
		replace(szTranslation, charsmax(szTranslation), "ų", "u");
		replace(szTranslation, charsmax(szTranslation), "Ū", "U");
		replace(szTranslation, charsmax(szTranslation), "ū", "u");
		replace(szTranslation, charsmax(szTranslation), "Ž", "Z");
		replace(szTranslation, charsmax(szTranslation), "ž", "z");
	}
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