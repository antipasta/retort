/* SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef TORTOS_TITLES_H
#define TORTOS_TITLES_H

#include "library.h"

/* Give a scanned shelf the titles it shows, then sort it by them.
 *
 * For a shelf whose core is fbneo, `dat` - the set table
 * tools/gen-fbneo-titles.py writes - with the brackets cut (lib_title): an
 * arcade zip is named for its set, and "mslug" is not a title. Pass NULL for any
 * other shelf. Otherwise the title lib_scan already gave it from the filename.
 *
 * A missing table is not an error: those shelves show set names, as they did
 * before it existed. */
void titles_apply(game_list *l, const char *folder, const char *dat);

#endif
