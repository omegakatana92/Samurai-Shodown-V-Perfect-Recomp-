/*
 * game.c — the Samurai Shodown V Perfect (samsh5pf) ROM set, shared by the
 * player and the generator so both load the program identically.
 *
 * samsh5pf is a fan "bootleg/hack" of Samurai Shodown V Special (272) that
 * ships decrypted graphics and sound ROMs (the "d" suffix). The single 8 MB
 * P ROM (273-p1.bin) holds its fixed bank first: the "NEO-GEO" header sits
 * at $100 of the first megabyte, so the whole file is mapped straight onto
 * the program region and the runtime's standard 1 MB bank scheme applies.
 * The eight 8 MB C ROMs pair into four odd/even bitplane groups, and the
 * two 8 MB ADPCM ROMs concatenate into one 16 MB sample space.
 */
#include "game.h"

const ng_game_t k_samsh5pf = {
    .name = "samsh5pf",
    .title = "Samurai Shodown V Perfect",
    .prom_size = 0x800000,
    .prom = {
        {"273-p1.bin", 0x000000, 0x000000, 0x800000, 1},
    },
    .crom_size = 0x4000000,
    .crom_pairs = {
        {"273-c1d.bin", "273-c2d.bin"},
        {"273-c3d.bin", "273-c4d.bin"},
        {"273-c5d.bin", "273-c6d.bin"},
        {"273-c7d.bin", "273-c8d.bin"},
    },
    .srom = "273-s1.bin",
    .m1 = "273-m1.bin",
    .vrom = {"273-v1d.bin", "273-v2d.bin"},
};
