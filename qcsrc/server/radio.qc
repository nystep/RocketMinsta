
float radio_playing;
float radio_looping;
float radio_starttime;
float radio_tracklen;
float radio_playing_queue;
float radio_queue_advanceat;
float radio_queue_next_request;
string radio_url;
string radio_filename;

void Radio_Init(void) {
    radio_playing_queue = -1;
    sv_radio = CVAR(sv_radio);

    if(!sv_radio)
        return;

    registercvar("_radio_queue", "");
    registercvar("_radio_queue_left", "0");
}

void Radio_SendPreload(entity e, string url) {
    if(!e.radio_enabled)
        return;

    msg_entity = e;
    WriteByte(MSG_ONE, SVC_TEMPENTITY);
    WriteByte(MSG_ONE, TE_CSQC_RADIO);
    WriteByte(MSG_ONE, TRUE);
    WriteString(MSG_ONE, url);
}

void Radio_Announce(entity e) {
    if(radio_playing_queue >= 0)
    if(CVAR(sv_radio_announce)) {
        string desc = cvar_string(strcat("_radio_queue_", ftos(radio_playing_queue), "_desc"));
        if(desc == "")
            desc = "^8(unknown track)";
        desc = strcat("^1[RADIO] ^2Now playing ^3", desc);
        if(radio_tracklen)
            desc = strcat(desc, "^8 (", mmss(radio_tracklen * 10), ")");
        float left = CVAR(_radio_queue_left);
        if(left)
            desc = strcat(desc, "^7 - ", ftos(left), " in queue");

        if(e)
            sprint(e, strcat("\{1}", desc, "\n"));
        else {
            bprint("\{1}", desc, "\n");
            IRC_Announce_Radio(desc);
        }
    }
}

void Radio_SendPlay(entity e) {
    if(!radio_playing)
        return;

    Radio_Announce(e);

    if(!e.radio_enabled)
        return;

    msg_entity = e;
    WriteByte(MSG_ONE, SVC_TEMPENTITY);
    WriteByte(MSG_ONE, TE_CSQC_RADIO);
    WriteByte(MSG_ONE, FALSE);
    WriteString(MSG_ONE, radio_url);
    WriteString(MSG_ONE, radio_filename);
    WriteByte(MSG_ONE, radio_looping);
    if(!radio_looping)
        WriteCoord(MSG_ONE, radio_starttime);
}

void Radio_Preload(string url) {
    if(!sv_radio)
        return;

    if(!CVAR(sv_radio_preload))
        return;

    entity e; FOR_EACH_REALCLIENT(e)
        Radio_SendPreload(e, url);
}

void Radio_Play(string url, string fname, float loop) {
    if(!sv_radio)
        return;

    if(radio_url)       strunzone(radio_url);
    if(radio_filename)  strunzone(radio_filename);

    radio_url = strzone(url);
    radio_filename = strzone(fname);
    radio_looping = loop;
    radio_starttime = time;
    radio_playing = TRUE;
    radio_tracklen = 0;
    radio_playing_queue = -1;

    dprint("URL: ", radio_url, "\n");
    dprint("File: ", radio_filename, "\n");
    dprint("Loop: ", ftos(radio_looping), "\n");
    dprint("Start: ", ftos(radio_starttime), "\n");

    entity e; FOR_EACH_REALCLIENT(e)
        Radio_SendPlay(e);
}

void Radio_Stop(void) {
    if(radio_url)       strunzone(radio_url);
    if(radio_filename)  strunzone(radio_filename);

    if(!radio_playing)
        return;

    radio_playing = FALSE;
    radio_url = radio_filename = string_null;
    radio_playing_queue = -1;

    entity e; FOR_EACH_REALCLIENT(e)
        stuffcmd(e, "cd reset\n");
}

void Radio_Queue_Request(void) {
    radio_queue_next_request = 0;
    if(CVAR(sv_radio_queue_autofill))
        uri_get(CVAR_STR(sv_radio_queue_autofill_server), URI_GET_RADIO);
}

void Radio_Queue_PlayFirst(void) {
    if(!sv_radio)
        return;

    if(!realclients || gameover) {
        Radio_Stop();
        return;
    }

    string q = CVAR_STR(_radio_queue);

    if(q == "") {
        Radio_Stop();
        Radio_Queue_Request();
        return;
    }

    float n = tokenizebyseparator(q, " ");

    string id    = argv(0);
    string url   = cvar_string(strcat("_radio_queue_", id, "_url"));
    string fname = cvar_string(strcat("_radio_queue_", id, "_fname"));

    Radio_Play(url, fname, FALSE);

    radio_tracklen = cvar(strcat("_radio_queue_", id, "_len"));
    radio_playing_queue = stof(id);
    radio_queue_advanceat = radio_starttime + radio_tracklen * CVAR(sv_radio_queue_advanceat);

    // preload next track
    id = argv(1);
    if(id != "")
        Radio_Preload(cvar_string(strcat("_radio_queue_", id, "_url")));

    cvar_set("_radio_queue_left", ftos(n-1));
    Radio_Announce(world);
}

string Radio_Queue_GetFreeID(void) {
    float id;
    string qs = strcat(" ", CVAR_STR(_radio_queue), " ");

    for(id = 0 ;; ++id) {
        string s = ftos(id);
        if(strstrofs(qs, strcat(" ", s, " "), 0) < 0)
            return s;
    }
}

void Radio_Queue(string url, string fname, float len, string desc) {
    if(!sv_radio)
        return;

    radio_queue_next_request = 0;

    string id = Radio_Queue_GetFreeID();

    string url_var   = strcat("_radio_queue_", id, "_url");
    string fname_var = strcat("_radio_queue_", id, "_fname");
    string len_var   = strcat("_radio_queue_", id, "_len");
    string desc_var  = strcat("_radio_queue_", id, "_desc");

    registercvar(url_var, "");
    registercvar(fname_var, "");
    registercvar(len_var, "");
    registercvar(desc_var, "");

    cvar_set(url_var, url);
    cvar_set(fname_var, fname);
    cvar_set(len_var, ftos(len));
    cvar_set(desc_var, desc);

    string q = CVAR_STR(_radio_queue);
    if(q == "")
        cvar_set("_radio_queue", id);
    else
        cvar_set("_radio_queue", strcat(q, " ", id));

    cvar_set("_radio_queue_left", ftos(CVAR(_radio_queue_left) + 1));

    if(radio_playing_queue < 0)
        Radio_Queue_PlayFirst();
    else if(strstrofs(q, " ", 0) < 0)
        Radio_Preload(url);
}

void Radio_Queue_Advance(void) {
    string q = CVAR_STR(_radio_queue);
    float sp = strstrofs(q, " ", 0);

    if(sp < 0) {
        cvar_set("_radio_queue", "");
        return;
    }

    cvar_set("_radio_queue", substring(q, sp+1, strlen(q)));
}

void Radio_Queue_Skip(void) {
    if(radio_playing_queue < 0)
        return;

    if(CVAR(sv_radio_log_skips)) {
        float fh = fopen("skiplog", FILE_APPEND);
        if(fh >= 0) {
            fputs(fh, strcat(strftime(TRUE, "%a %b %e %H:%M:%S %Z %Y "), radio_url, " ", radio_filename, "\n"));
            fclose(fh);
        }
    }

    if(radio_queue_advanceat)
        Radio_Queue_Advance();
    Radio_Queue_PlayFirst();
}

void Radio_Frame(void) {
    if(radio_queue_next_request)
    if(time > radio_queue_next_request)
        Radio_Queue_Request();

    if(radio_playing_queue < 0)
        return;

    if(radio_queue_advanceat > 0)
    if(time > radio_queue_advanceat) {
        Radio_Queue_Advance();
        radio_queue_advanceat = 0;

        if(CVAR_STR(_radio_queue) == "")
            Radio_Queue_Request();
    }

    if(time > radio_starttime + radio_tracklen)
        Radio_Queue_PlayFirst();
}

void Radio_URI_Get_Callback(float id, float status, string data) {
    if(status) {
        radio_queue_next_request = time + CVAR(sv_radio_queue_autofill_retry);
        return;
    }

    float n = tokenizebyseparator(data, " ");
    string d = "";

    if(n > 3) {
        d = substring(data, argv_start_index(3), strlen(data));
        d = strcat(d, " ^8(autoqueue)");
    }

    Radio_Queue(argv(0), argv(1), stof(argv(2)), d);
}

void Radio_ClientConnect_Delayed(void) {
    Radio_SendPlay(self);
}

void Radio_ClientConnect(void) {
    if(!radio_playing)
        return;

    if(clienttype(self) != CLIENTTYPE_REAL)
        return;

    if(CVAR(sv_radio_preload))
        Radio_SendPreload(self, radio_url);
    defer(3, Radio_ClientConnect_Delayed);
}
