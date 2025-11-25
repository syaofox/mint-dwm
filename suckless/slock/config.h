/* user and group to drop privileges to */
static const char *user  = "nobody";
static const char *group = "nobody";

static const char *colorname[NUMCOLS] = {
	[INIT] =   "#0d1416",     /* after initialization */
	[INPUT] =  "#60DEEC",   /* during input */
	[FAILED] = "#ff7f70",   /* wrong password */
};

/* treat a cleared input like a wrong password (color) */
static const int failonclear = 1;
