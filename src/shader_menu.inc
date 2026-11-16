/* SPDX-License-Identifier: GPL-3.0-or-later */
/* Shader menu runner and persistence helpers. Included by src/main.c. */

static void shader_load(app *a)
{
	char path[CFG_STR * 2], key[CFG_STR + 16], name[SL_NAME];
	int i;

	snprintf(path, sizeof path, "%s/shaders/shaders.cfg", P_ROOT);
	sl_load(&a->shaders, path);
	for (i = 0; i < a->sys.count; i++) {
		snprintf(key, sizeof key, "shader.%s", a->sys.systems[i].tag);
		a->view[i].shader = db_get_str(db_dev(), key, name, sizeof name, NULL)
		                    ? sl_find(&a->shaders, name) : 0;
	}
}

static void shader_save(app *a, int sys)
{
	char key[CFG_STR + 16];

	snprintf(key, sizeof key, "shader.%s", a->sys.systems[sys].tag);
	db_set_str(db_dev(), key, a->shaders.e[a->view[sys].shader].name);
}

static const char *shader_fields(app *a, int i, char *f, size_t cap)
{
	char dir[CFG_STR * 2];

	if (a->shaders.count <= 1) return NULL;
	snprintf(dir, sizeof dir, "%s/shaders", P_ROOT);
	if (i == 0 || !sl_fields(&a->shaders, i, dir, f, cap)) return "";
	return f;
}

static int game_shader(app *a, int sys, const game_entry *g)
{
	char key[LIB_PATH + 48], name[SL_NAME];

	if (!g || !g->file[0]) return a->view[sys].shader;
	snprintf(key, sizeof key, "shader.%s.%s", a->sys.systems[sys].tag, g->file);
	return db_get_str(db_dev(), key, name, sizeof name, NULL)
	       ? sl_find(&a->shaders, name) : a->view[sys].shader;
}

static void game_shader_save(app *a, int sys, const game_entry *g, int i)
{
	char key[LIB_PATH + 48];

	if (!g || !g->file[0]) return;
	snprintf(key, sizeof key, "shader.%s.%s", a->sys.systems[sys].tag, g->file);
	db_set_str(db_dev(), key, a->shaders.e[i].name);
}

typedef struct {
	app              *a;
	gm_ctx           *gm;   /* NULL from shelf menu */
	int               sys;  /* owner sys */
	const game_entry *g;    /* NULL from shelf menu */
} sh_ctx;

static int sh_cur(app *a, const sh_ctx *c)
{
	return c->g ? game_shader(a, c->sys, c->g) : a->view[c->sys].shader;
}

static sh_ctx sh_game(app *a, gm_ctx *gm)
{
	sh_ctx c = { a, gm, 0, NULL };

	c.g = playing(a, &c.sys);
	return c;
}

static int sh_build(void *ctx, menu_row *rows, int max, const char **heading)
{
	sh_ctx *c = ctx;
	app *a = c->a;
	int i, n = a->shaders.count < max ? a->shaders.count : max;

	for (i = 0; i < n; i++)
		rows[i] = (menu_row){ a->shaders.e[i].name,
		                      i == sh_cur(a, c) ? "Current" : NULL, true };
	*heading = c->g ? SHADER_LABEL : "Default " SHADER_LABEL;
	return n;
}

static menu_result sh_key(app *a, void *ctx, in_button key, int sel)
{
	sh_ctx *c = ctx;
	char f[1024], dir[CFG_STR * 2];

	if (key != IN_ACCEPT) return MENU_STAY;
	if (sel == sh_cur(a, c)) return MENU_DONE;
	snprintf(dir, sizeof dir, "%s/shaders", P_ROOT);
	if (!sl_fields(&a->shaders, sel, dir, f, sizeof f)) return MENU_DONE;
	plat_resident_line("SETDISPLAY\t%s", f);
	if (!plat_resident_sync_rect(2000)) {
		fprintf(stderr, "shader: %s not applied\n", a->shaders.e[sel].name);
		return MENU_DONE;
	}
	game_shader_save(a, c->sys, c->g, sel);
	return MENU_DONE;
}

static void sh_backdrop(app *a, void *ctx) { gm_backdrop(a, ((sh_ctx *)ctx)->gm); }
static menu_result sh_power(app *a, void *ctx) { return gm_power(a, ((sh_ctx *)ctx)->gm); }

static void shader_screen(app *a, gm_ctx *gm)
{
	sh_ctx c = sh_game(a, gm);
	menu_style st = gm->st;

	st.fixed_w  = 0;
	st.backdrop = sh_backdrop;
	st.on_power = sh_power;
	st.start    = sh_cur(a, &c);
	menu_run(a, &st, sh_build, sh_key, &c);
}

static menu_result shs_key(app *a, void *ctx, in_button key, int sel)
{
	sh_ctx *c = ctx;

	if (key != IN_ACCEPT) return MENU_STAY;
	a->view[c->sys].shader = sel;
	shader_save(a, c->sys);
	return MENU_DONE;
}

static void shelf_shader_screen(app *a, int sys)
{
	sh_ctx c = { a, NULL, sys, NULL };
	menu_style st = { .accent = MENU_ACCENT, .follow_tint = true,
	                  .start = a->view[sys].shader };

	menu_run(a, &st, sh_build, shs_key, &c);
}
