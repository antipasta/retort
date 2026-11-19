/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "titles.h"

#include <stdio.h>
#include <string.h>

#include "fbneodat.h"

void titles_apply(game_list *l, const char *folder, const char *dat)
{
	int i, sets = 0;

	if (!l || l->count <= 0 || !dat) return;
	for (i = 0; i < l->count; i++) {
		game_entry *g = &l->items[i];
		const char *desc = fbneo_desc(dat, g->name);

		if (!desc) continue;
		lib_title(desc, g->title, sizeof g->title);
		sets++;
	}
	if (sets) {
		fprintf(stderr, "titles: %-16s %d from FBNeo's list\n", folder ? folder : "", sets);
		lib_sort(l);
	}
}
