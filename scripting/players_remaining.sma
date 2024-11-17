#include <amxmodx>
#include <amxmisc>

#if AMXX_VERSION_NUM < 183
	#tryinclude <dhudmessage>
	#include <cstrike>
	#define client_disconnected(%1) client_disconnect(%1)
	#define get_pcvar_bool(%1) bool:get_pcvar_num(%1)
#endif

#define PLUGIN_NAME             "Players Remaining"
#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_AUTHOR           "gabuch2"

#pragma semicolon   1

#define TASK_ID 5756184

new g_cvarEnabled, g_cvarColorRed, g_cvarColorBlue, g_cvarColorGreen, g_cvarHorPos, g_cvarVerPos, g_cvarEffects, g_cvarFxTime, g_cvarHoldTime, g_cvarFadeInTime, g_cvarFadeOutTime;
new bool:g_bEnabled;
new g_iColorRed, g_iColorGreen, g_iColorBlue, g_iEffects;
new Float:g_fHorPos, Float:g_fVerPos, Float:g_fFxTime, Float:g_fHoldTime, Float:g_fFadeInTime, Float:g_fFadeOutTime;
#if AMXX_VERSION_NUM < 183
new g_iTerrorNum;
new g_iCTNum;
#endif

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	#if AMXX_VERSION_NUM < 183
	g_cvarEnabled = register_cvar("amx_pr_enabled", "1");
	g_cvarColorRed = register_cvar("amx_pr_color_red", "125");
	g_cvarColorGreen = register_cvar("amx_pr_color_green", "100");
	g_cvarColorBlue = register_cvar("amx_pr_color_blue", "0");
	g_cvarHorPos = register_cvar("amx_pr_pos_horizontal", "-1.0");
	g_cvarVerPos = register_cvar("amx_pr_pos_vertical", "0.01");
	g_cvarEffects = register_cvar("amx_pr_effects", "0.01");
	g_cvarFxTime = register_cvar("amx_pr_effects_time", "0");
	g_cvarHoldTime = register_cvar("amx_pr_time_hold", "0.6");
	g_cvarFadeInTime = register_cvar("amx_pr_time_fadein", "0.7");
	g_cvarFadeOutTime = register_cvar("amx_pr_time_fadeout", "0.7");
	set_task(1.0, "Task_CacheData182", _, _, _, "b");
	#else
	g_cvarEnabled = create_cvar("amx_pr_enabled", "1", FCVAR_NONE, "Enables Players Remaining.", true, 0.0, true, 1.0);
	g_cvarColorRed = create_cvar("amx_pr_color_red", "125", FCVAR_NONE, "Determines the red color of the hint message.", true, 0.0, true, 255.0);
	g_cvarColorGreen = create_cvar("amx_pr_color_green", "100", FCVAR_NONE, "Determines the green color of the hint message.", true, 0.0, true, 255.0);
	g_cvarColorBlue = create_cvar("amx_pr_color_blue", "0", FCVAR_NONE, "Determines the blue color of the hint message.", true, 0.0, true, 255.0);
	g_cvarHorPos = create_cvar("amx_pr_pos_horizontal", "-1.0", FCVAR_NONE, "Determines the horizontal position of the hint message.", true, -1.0, true, 1.0);
	g_cvarVerPos = create_cvar("amx_pr_pos_vertical", "0.01", FCVAR_NONE, "Determines the vertical position of the hint message.", true, -1.0, true, 1.0);
	g_cvarEffects = create_cvar("amx_pr_effects", "0.01", FCVAR_NONE, "Determines the effect of the hint message. (0:no effects 1:flashing 2:printing letter by letter)", true, 0.0, true, 2.0);
	g_cvarFxTime = create_cvar("amx_pr_effects_time", "0", FCVAR_NONE, "Determines how long should the effect last, if any", true, 0.0);
	g_cvarHoldTime = create_cvar("amx_pr_time_hold", "0.6", FCVAR_NONE, "Determines how long should the hint message should last", true, 0.0);
	g_cvarFadeInTime = create_cvar("amx_pr_time_fadein", "0.7", FCVAR_NONE, "Determines how long should the message take to fade in", true, 0.0);
	g_cvarFadeOutTime = create_cvar("amx_pr_time_fadeout", "0.7", FCVAR_NONE, "Determines how long should the message take to fade out", true, 0.0);
	hook_cvar_change(g_cvarEnabled, "CvarChanged");
	hook_cvar_change(g_cvarColorRed, "CvarChanged");
	hook_cvar_change(g_cvarColorGreen, "CvarChanged");
	hook_cvar_change(g_cvarColorBlue, "CvarChanged");
	hook_cvar_change(g_cvarHorPos, "CvarChanged");
	hook_cvar_change(g_cvarVerPos, "CvarChanged");
	hook_cvar_change(g_cvarEffects, "CvarChanged");
	hook_cvar_change(g_cvarFxTime, "CvarChanged");
	hook_cvar_change(g_cvarHoldTime, "CvarChanged");
	hook_cvar_change(g_cvarFadeInTime, "CvarChanged");
	hook_cvar_change(g_cvarFadeOutTime, "CvarChanged");
	#endif
}

public plugin_cfg()
{
	CacheConVars();
}

public CvarChanged(cvarHandle, const szOldValue[], const szNewValue[])
{
	CacheConVars();
}

CacheConVars()
{
	g_bEnabled = get_pcvar_bool(g_cvarEnabled);
	if(g_bEnabled)
	{
		g_iColorRed = get_pcvar_num(g_cvarColorRed);
		g_iColorGreen = get_pcvar_num(g_cvarColorGreen);
		g_iColorBlue = get_pcvar_num(g_cvarColorBlue);
		g_iEffects = get_pcvar_num(g_cvarEffects);
		g_fHorPos = get_pcvar_float(g_cvarHorPos);
		g_fVerPos = get_pcvar_float(g_cvarVerPos);
		g_fFxTime = get_pcvar_float(g_cvarFxTime);
		g_fHoldTime = get_pcvar_float(g_cvarHoldTime);
		g_fFadeInTime = get_pcvar_float(g_cvarFadeInTime);
		g_fFadeOutTime = get_pcvar_float(g_cvarFadeOutTime);

		EnableTimers();
	}
	else
		DisableTimers();
}

EnableTimers()
{
	for(new iClient = 0; iClient < get_maxplayers(); iClient++)
	{
		if(is_user_connected(iClient) && !is_user_bot(iClient) && !task_exists(TASK_ID+iClient))
			set_task(1.0, "Task_ShowHint", TASK_ID+iClient, _, _, "b");
	}
}

DisableTimers()
{
	for(new iClient = 0; iClient < get_maxplayers(); iClient++)
	{
		if(task_exists(TASK_ID+iClient))
			remove_task(TASK_ID+iClient);
	}
}

public client_putinserver(iClient) 
{
	if(!is_user_bot(iClient) && !task_exists(TASK_ID+iClient))
		set_task(1.0, "Task_ShowHint", TASK_ID+iClient, _, _, "b");
}

public client_disconnected(iClient)
{
	if(task_exists(TASK_ID+iClient))
		remove_task(TASK_ID+iClient);
}

public Task_ShowHint(iTaskId)
{
	new iClient = iTaskId-TASK_ID;
	if(is_user_alive(iClient))
	{
		#if defined _dhudmessage_included || AMXX_VERSION_NUM > 183
		set_dhudmessage(g_iColorRed, g_iColorGreen, g_iColorBlue, g_fHorPos, g_fVerPos, g_iEffects, g_fFxTime, g_fHoldTime, g_fFadeInTime, g_fFadeOutTime);
		#else 
		set_hudmessage(g_iColorRed, g_iColorGreen, g_iColorBlue, g_fHorPos, g_fVerPos, g_iEffects, g_fFxTime, g_fHoldTime, g_fFadeInTime, g_fFadeOutTime, -1);
		#endif
		#if AMXX_VERSION_NUM < 183
		#if defined _dhudmessage_included
		show_dhudmessage(iClient, "%d CTs vs %i Ts", g_iCTNum, g_iTerrorNum);
		#else
		show_hudmessage(iClient, "%d CTs vs %i Ts", g_iCTNum, g_iTerrorNum);
		#endif
		#else
		show_dhudmessage(iClient, "%d CTs vs %i Ts", get_playersnum_ex(GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT"), get_playersnum_ex(GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST"));
		#endif
	}
}

#if AMXX_VERSION_NUM < 183
public Task_CacheData182()
{
	//honestly, I don't care about 182 support it should've been deprecated a long time ago
	//but this rather inneficient method should provide the same functionality
	CacheConVars();
	if(g_bEnabled)
	{
		g_iCTNum = 0;
		g_iTerrorNum = 0;
		for(new iClient = 0; iClient < get_maxplayers(); iClient++)
		{
			if(is_user_alive(iClient))
			{
				if(cs_get_user_team(iClient) == CS_TEAM_CT)
					g_iCTNum++;
				else if(cs_get_user_team(iClient) == CS_TEAM_T)
					g_iTerrorNum++;
			}
		}
	}
}
#endif