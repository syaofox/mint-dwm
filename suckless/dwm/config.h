/* See LICENSE file for copyright and license details. */
#include <X11/XF86keysym.h>

/* appearance */
static unsigned int borderpx  = 2;        /* 窗口边框像素 */
static unsigned int snap      = 32;       /* 吸附像素 */
static unsigned int systraypinning = 0;   /* 0: 系统托盘跟随选中的显示器, >0: 将系统托盘固定到显示器 X */
static unsigned int systrayonleft = 0;    /* 0: 系统托盘在右侧, >0: 系统托盘在状态文本左侧 */
static unsigned int systrayspacing = 2;   /* 系统托盘间距 */
static unsigned int systrayiconsize = 16; /* 系统托盘图标高度（像素） */
static int systraypinningfailfirst = 1;   /* 1: 如果固定失败，在第一个显示器显示系统托盘，0: 在最后一个显示器显示系统托盘 */
static int showsystray        = 1;        /* 0 表示不显示系统托盘 */
static unsigned int gappih    = 6;       /* 窗口之间的水平内边距 */
static unsigned int gappiv    = 4;       /* 窗口之间的垂直内边距 */
static unsigned int gappoh    = 4;       /* 窗口与屏幕边缘之间的水平外边距 */
static unsigned int gappov    = 4;       /* 窗口与屏幕边缘之间的垂直外边距 */
static int smartgaps          = 0;        /* 1 表示只有一个窗口时不显示外边距 */
static int showbar            = 1;        /* 0 表示不显示状态栏 */
static int topbar             = 1;        /* 0 表示状态栏在底部 */
static int focusedontoptiled  = 1;        /* 1 means focused tile client is shown on top of floating windows */
static int focusonhover       = 0;        /* 1: 鼠标悬停切换焦点, 0: 不自动切换 */
static int barheight          = 30;        /* 0 表示自动高度 */
static unsigned int tagunderlineheight = 2; /* 选中标签下指示器的高度 */
static unsigned int tagunderlinepad    = 4; /* 指示器的水平内边距 */
static char font[256]            = "JetBrainsMono Nerd Font Propo:style=Bold:size=14:pixelsize=14:antialias=true:autohint=true";
static char dmenufont[256]       = "JetBrainsMono Nerd Font Propo:style=Bold:size=14:pixelsize=14:antialias=true:autohint=true";
static const char *fonts[]          = { font };
static char statusfont[256]      = "JetBrainsMono Nerd Font Propo:style=Bold:size=14:pixelsize=14:antialias=true:autohint=true";
static char tagsfont[256]        = "JetBrainsMono Nerd Font Propo:style=Bold:size=16:pixelsize=16:antialias=true:autohint=true";

static char normbgcolor[64]           = "#0d1416";
static char normbordercolor[64]       = "#1a2529";
static char normfgcolor[64]           = "#2a3539";
static char selfgcolor[64]            = "#c5d9dc";
static char selbordercolor[64]        = "#60DEEC";
static char selbgcolor[64]            = "#0d1416";
static char accentcolor[64]           = "#60DEEC";
static char underlinecolor[64]        = "#ad8ee6";

static char *colors[][3]      = {
	/* fg         bg         border   */
	[SchemeNorm] = { normfgcolor, normbgcolor, normbordercolor }, // 非活动
	[SchemeSel]  = { selfgcolor,  selbgcolor,  selbordercolor  }, // 选中
	[SchemeOcc]  = { accentcolor, normbgcolor, normbordercolor }, // 有窗口: 前景突出色, 背景保持
	[SchemeSelOcc] = { accentcolor, normbgcolor, accentcolor }, // 当前焦点且有窗口: 使用强调色字体
	[SchemeUnderline] = { underlinecolor, normbgcolor, normbgcolor }, // 标签色条
};


/* tagging */
static const char *tags[] = { "", "", "3", "", "", "󰠟", "󰟀", "", "󰓦" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class                instance    title       tags mask     isfloating   alwaysontop monitor  height_percent  aspect_ratio  center */
	/* height_percent: 0.0 = 使用默认值, >0.0 = 屏幕高度的百分比 (例如, 0.8 = 80%) */
	/* aspect_ratio: 0.0 = 使用默认值, >0.0 = 宽高比 (例如, 16.0/9.0 = 1.777) */
	/* center: 0 = 不居中, 1 = 居中浮动窗口 */
	/* brave app YutubeMusic */
	{ NULL,                                   "crx_cinhimbnkkaeohfgghhklpknlkffjgod", NULL,                       1 << 7, 0, 0, -1, 0.0, 0.0,      0 },
	/* brave app Youtube */
	{ NULL,                                   "crx_agimnkijcaahngcdmfeangaknmldooml", NULL,                       1 << 7, 0, 0, -1, 0.0, 0.0,      0 },
	{ "Virt-manager",                         NULL,                                   NULL,                       1 << 6, 0, 0, -1, 0.0, 0.0,      0 },
	// { "Brave-browser",                        NULL,                                   NULL,                       1 << 0, 0, 0, -1, 0.0, 0.0,      0 },
	{ "Cursor",                               NULL,                                   NULL,                       1 << 1, 0, 0, -1, 0.0, 0.0,      0 },
	{ "FreeFileSync",                         NULL,                                   NULL,                       1 << 8, 0, 0, -1, 0.0, 0.0,      0 },
	{ "Localsend",                            "localsend",                            NULL,                       1 << 8, 0, 0, -1, 0.0, 0.0,      0 },
	{ "Rofi",                                 NULL,                                   NULL,                       0,      1, 1, -1, 0.0, 0.0,      1 },
	{ "zenity",                               NULL,                                   NULL,                       0,      1, 1, -1, 0.0, 0.0,      1 },
	{ "Bulky.py",                             "bulky.py",                             NULL,                       0,      1, 1, -1, 0.0, 0.0,      1 },
	{ "mpv",                                  NULL,                                   NULL,                       0,      1, 1, -1, 0.0, 0.0, 	   1 },
	{ "feh",                                  NULL,                                   NULL,                       0,      1, 1, -1, 0.0, 0.0,      1 },
	{ "com.github.qarmin.czkawka",            NULL,                                   NULL,                       1 << 8, 0, 0, -1, 0.0, 0.0,      0 },
	{ "Thunar",                               "thunar",                               "Confirm to replace files", 0,      1, 1, -1, 0.0, 0.0,      1 },
	{ "Thunar",                               "thunar",                               "Rename",                   0,      1, 1, -1, 0.0, 0.0,      1 },
	{ "Thunar",                               "thunar",                               "File Operation Progress",  0,      1, 1, -1, 0.0, 0.0,      1 },
	{ "org.gnome.FileRoller",                 "org.gnome.FileRoller",                 NULL,                       0,      1, 1, -1, 0.0, 0.0,      1 },
	{ "tdxcfv",                               "tdxw.fak",                             NULL,                       1 << 5, 0, 0, -1, 0.0, 0.0,      0 },
	{ "Xfce4-appfinder",                      "xfce4-appfinder",                      NULL,                       0,      1, 1, -1, 0.4, 0.0,      1 },
	{ "Io.github.celluloid_player.Celluloid", NULL,                                   NULL,                       0,      1, 1, -1, 0.0, 0.0,      1 },
	{ "Xviewer",                              NULL,                                   NULL,                       0,      1, 1, -1, 0.0, 0.0,      1 },
	{ "fr.handbrake.ghb",                     NULL,                                   NULL,                       1 << 4, 0, 0, -1, 0.0, 0.0,      0 },
	{ "CherryStudio",                     	  NULL,                                   NULL,                       1 << 3, 0, 0, -1, 0.0, 0.0,      0 },

};

/* layout(s) */
static float mfact     = 0.55; /* 主区域大小因子 [0.05..0.95] */
static int nmaster     = 1;    /* 主区域中的客户端数量 */
static int resizehints = 0;    /* 1 表示在平铺调整大小时尊重尺寸提示 */
static const int lockfullscreen = 1; /* 1 将强制聚焦全屏窗口 */
static const int refreshrate = 120;  /* 客户端移动/调整大小时的刷新率（每秒） */

#include "vanitygaps.c"

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* 第一个条目是默认值 */
	{ "[M]",      monocle },
	{ "><>",      NULL },    /* 没有布局函数意味着浮动行为 */
};

/* key definitions */
#define MODKEY Mod4Mask
/* TAGKEYS 宏：为每个标签定义五个快捷键绑定 */
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, /* MODKEY + KEY: 切换到指定标签 */ \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, /* MODKEY + Ctrl + KEY: 切换显示指定标签 */ \
	{ MODKEY|Mod1Mask,              KEY,      tag,            {.ui = 1 << TAG} }, /* MODKEY + Alt + KEY: 将当前窗口移动到指定标签 */ \
	{ MODKEY|ShiftMask,             KEY,      tagandview,     {.ui = 1 << TAG} }, /* MODKEY + Shift + KEY: 将当前窗口移动到指定标签并切换到该标签 */ \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} }, /* MODKEY + Ctrl + Shift + KEY: 切换当前窗口的指定标签 */

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }



/* commands */
#define SCRIPTS_DIR "$HOME/.config/mint-dwm/scripts/"
#define CONFIG_DIR  "$HOME/.config/mint-dwm/config/"

static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *launchercmd[] = { "/bin/sh", "-c", SCRIPTS_DIR "run-launcher.sh", NULL };
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", normbgcolor, "-nf", normfgcolor, "-sb", accentcolor, "-sf", normbgcolor, NULL };
static const char *termcmd[]  = { "/bin/sh", "-c", SCRIPTS_DIR "run-term.sh", NULL };

/* Xresources preferences to load at startup */
ResourcePref resources[] = {
		{ "font",               STRING,  &font },
		{ "dmenufont",          STRING,  &dmenufont },
		{ "statusfont",         STRING,  &statusfont },
		{ "tagsfont",           STRING,  &tagsfont },
		{ "normbgcolor",        STRING,  &normbgcolor },
		{ "normbordercolor",    STRING,  &normbordercolor },
		{ "normfgcolor",        STRING,  &normfgcolor },
		{ "selbgcolor",         STRING,  &selbgcolor },
		{ "selbordercolor",     STRING,  &selbordercolor },
		{ "selfgcolor",         STRING,  &selfgcolor },
		{ "accentcolor",        STRING,  &accentcolor },
		{ "underlinecolor",     STRING,  &underlinecolor },
		{ "borderpx",          	INTEGER, &borderpx },
		{ "snap",          		INTEGER, &snap },
		{ "showbar",          	INTEGER, &showbar },
		{ "topbar",          	INTEGER, &topbar },
		{ "nmaster",          	INTEGER, &nmaster },
		{ "resizehints",       	INTEGER, &resizehints },
		{ "mfact",      	 	FLOAT,   &mfact },
		{ "gappih",             INTEGER, &gappih },
		{ "gappiv",             INTEGER, &gappiv },
		{ "gappoh",             INTEGER, &gappoh },
		{ "gappov",             INTEGER, &gappov },
		{ "smartgaps",          INTEGER, &smartgaps },
		{ "barheight",          INTEGER, &barheight },
		{ "tagunderlineheight", INTEGER, &tagunderlineheight },
		{ "tagunderlinepad",    INTEGER, &tagunderlinepad },
		{ "systraypinning",     INTEGER, &systraypinning },
		{ "systrayonleft",      INTEGER, &systrayonleft },
		{ "systraypinningfailfirst", INTEGER, &systraypinningfailfirst },
		{ "focusedontoptiled",  INTEGER, &focusedontoptiled },
		{ "systrayspacing",     INTEGER, &systrayspacing },
		{ "systrayiconsize",    INTEGER, &systrayiconsize },
		{ "showsystray",        INTEGER, &showsystray },
		{ "focusonhover",       INTEGER, &focusonhover },
};
static const char *filecmd[]  = { "/usr/bin/nemo",  NULL };
static const char *screenshotcmd[]  = { "/bin/sh", "-c", SCRIPTS_DIR "screenshot.sh copy", NULL };
static const char *screenshotsavedcmd[] = { "/bin/sh", "-c", SCRIPTS_DIR "screenshot.sh save", NULL };
static const char *wallpapercmd[]  = { "/bin/sh", "-c", SCRIPTS_DIR "wallpaper-next.sh", NULL };
static const char *browsercmd[]  = { "/bin/sh", "-c", SCRIPTS_DIR "run-brave.sh", NULL };
static const char *slockcmd[]  = { "/bin/sh", "-c", "slock", NULL };
static const char *fsearchcmd[]  = { "/bin/sh", "-c", SCRIPTS_DIR "run-fsearch.sh", NULL };
static const char *upvol[]   = { "/bin/sh", "-c", SCRIPTS_DIR "volume.sh up",   NULL };
static const char *downvol[] = { "/bin/sh", "-c", SCRIPTS_DIR "volume.sh down", NULL };
static const char *mutevol[] = { "/bin/sh", "-c", SCRIPTS_DIR "volume.sh mute", NULL };
static const char *sysact[] = { "/bin/sh", "-c", SCRIPTS_DIR "sysact.sh", NULL };
static const char *clipman[] = { "/bin/sh", "-c", "xfce4-clipman-history", NULL };


/* autostart */
static const char *const autostart[] = {
	NULL /* terminate */
};

static const AppKey appkeys[] = {
	/* class                                      modifier key   function        argument */
	{ "Io.github.celluloid_player.Celluloid",     0,       XK_q, killclient,     {0} },
	{ "Xviewer",     							  0,       XK_q, killclient,     {0} },
};

static const Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_space,  spawn,          {.v = launchercmd } }, /* 启动菜单 */
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } }, /* 启动终端 */
    { MODKEY,                       XK_e,      spawn,          {.v = filecmd } }, /* 启动thunar */
    { MODKEY,                       XK_a,      spawn,          {.v = screenshotcmd } }, /* 截图 */
    { MODKEY|ShiftMask,        		XK_a,      spawn,          {.v = screenshotsavedcmd } }, /* 截图并保存 */
    { MODKEY|ShiftMask,             XK_w,      spawn,          {.v = wallpapercmd } }, /* 切换壁纸 */
    { MODKEY,                       XK_w,      spawn,          {.v = browsercmd } }, /* 启动浏览器 */
    { MODKEY|ShiftMask,             XK_l,      spawn,          {.v = slockcmd } }, /* 锁屏 */
	{ MODKEY,                       XK_f,      spawn,          {.v = fsearchcmd } }, /* 搜索 */
	{ MODKEY,                       XK_v,      spawn,          {.v = clipman } }, /* 剪贴板 */
	{ 0,                            XF86XK_AudioMute,        spawn, {.v = mutevol } },
	{ 0,                            XF86XK_AudioLowerVolume, spawn, {.v = downvol } },
	{ 0,                            XF86XK_AudioRaiseVolume, spawn, {.v = upvol } },
	{ ControlMask|Mod1Mask,         XK_Delete, spawn,          {.v = sysact } },
	{ MODKEY,                       XK_b,      togglebar,      {0} }, /* 切换状态栏显示 */
	{ MODKEY,                       XK_grave,  focusstack,     {.i = +1 } }, /* 聚焦下一个窗口 */
	{ MODKEY|ShiftMask,             XK_grave,  focusstack,     {.i = -1 } }, /* 聚焦上一个窗口 */
	{ MODKEY,                       XK_comma,  setmfact,       {.f = -0.05} }, /* 减小主区域大小 */
	{ MODKEY,                       XK_period, setmfact,       {.f = +0.05} }, /* 增大主区域大小 */
	{ MODKEY,                       XK_s,      zoom,           {0} }, /* 交换主窗口和栈窗口 */
	{ MODKEY,                       XK_u,      incrgaps,       {.i = +1 } }, /* 增加间距 */
	{ MODKEY|ShiftMask,             XK_u,      incrgaps,       {.i = -1 } }, /* 减少间距 */
	{ MODKEY,                       XK_0,      togglegaps,     {0} }, /* 切换间距 */
	{ MODKEY|ShiftMask,             XK_0,      defaultgaps,    {0} }, /* 恢复默认间距 */
	{ MODKEY,                       XK_Tab,    viewnexttag,    {0} }, /* 切换到下一个标签 */
	{ MODKEY,            		    XK_q,      killclient,     {0} }, /* 关闭当前窗口 */
	{ MODKEY,            			XK_m,  	   cyclelayout,    {.i = +1} }, /* 循环切换布局 */
	{ MODKEY,            			XK_t,  	   setlayout,      {.v = &layouts[0]} }, /* 强制切换回 Tile 布局 */
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
};

/* button definitions */
/* 点击区域可以是 ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, 或 ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        cyclelayout,    {.i = +1} }, /* 点击布局符号循环切换布局 */
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[1]} }, /* 右键点击布局符号切换到 monocle 布局 */
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} }, /* 中键点击窗口标题栏交换主窗口 */
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } }, /* 中键点击状态栏启动终端 */
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} }, /* 按住 MODKEY 拖动窗口 */
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} }, /* 按住 MODKEY 中键切换浮动 */
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} }, /* 按住 MODKEY 右键调整窗口大小 */
	{ ClkTagBar,            0,              Button1,        view,           {0} }, /* 点击标签切换到该标签 */
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} }, /* 右键点击标签切换显示该标签 */
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} }, /* 按住 MODKEY 点击标签将窗口移动到该标签 */
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} }, /* 按住 MODKEY 右键点击标签切换窗口的标签 */
};

