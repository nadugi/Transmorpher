-- CombatPetsDB.lua — All combat pet creatures for WoW 3.3.5a (build 12340)
-- Includes: Hunter pets, Warlock demons, Frost Mage water elemental
-- Format: { "Name", familyName, displayID, "model\\path.m2", npcID }
-- familyName is used for category/type filtering in the UI
-- npcID (optional, 5th field) = creature_template NPC ID for SetCreature() textured preview
--   If npcID is present and > 0, the preview uses SetCreature(npcID) for a fully textured model.
--   If npcID is absent or 0, the preview falls back to SetModel(path) (geometry only).

local _, ns = ...

ns.combatPetsDB = {
    -- ==============================
    -- BEARS
    -- ==============================
    { "Brown Bear",            "Bear",         822,   "Creature\\Bear\\Bear.m2" },
    { "Black Bear",            "Bear",         820,   "Creature\\Bear\\Bear.m2" },
    { "Polar Bear",	"Bear",	27659, "Creature\\Bear2\\Bear2.m2" },
    { "Grizzly Bear",	"Bear",	1083, "Creature\\Bear2\\Bear2.m2" },
    { "Dire Bear (Black)",     "Bear",         15366, "Creature\\Bear2\\Bear2.m2" },
    { "Armored Bear (Brown)",  "Bear",         29756, "Creature\\Bear2\\Bear2.m2" },  -- Fixed: was 29757 (invalid)
    { "Corrupted Bear",        "Bear",         12037, "Creature\\Bear\\Bear.m2" },
    { "Ghost Bear",            "Bear",         26646, "Creature\\Bear2\\Bear2.m2" },  -- Fixed: was 26647 (invalid)
    { "Ironforge Bear",        "Bear",         3809,  "Creature\\Bear\\Bear.m2" },
    { "Ashenvale Bear",	"Bear",	982,  "Creature\\Bear\\Bear.m2" },

    -- ==============================
    -- BOARS
    -- ==============================
    { "Boar (Brown)",          "Boar",         488,   "Creature\\Boar\\Boar.m2" },
    { "Boar (Black)",          "Boar",         2966,  "Creature\\Boar\\Boar.m2" },
    { "Boar (White)",          "Boar",         16195, "Creature\\Boar\\Boar.m2" },
    { "Armored Boar",          "Boar",         25766, "Creature\\Boar\\Boar.m2" },  -- Fixed: was 25767 (invalid)
    { "Dire Boar",             "Boar",         23932, "Creature\\Boar\\Boar.m2" },
    { "Helboar",	"Boar",	11410, "Creature\\HelBoar\\HelBoar.m2" },
    { "Felboar",               "Boar",         20868, "Creature\\HelBoar\\HelBoar.m2" },
    { "Plagued Boar",          "Boar",         7099,  "Creature\\Boar\\Boar.m2" },

    -- ==============================
    -- CATS (Tigers, Lions, Panthers, Lynx)
    -- ==============================
    { "Tiger (Orange)",        "Cat",          275,   "Creature\\Tiger\\Tiger.m2" },  -- Fixed: was 274 (invalid)
    { "Tiger (White)",         "Cat",          1192,  "Creature\\Tiger\\Tiger.m2" },  -- Fixed: was 1191 (invalid)
    { "Snow Leopard",          "Cat",          1713,  "Creature\\Tiger\\Tiger.m2" },
    { "Black Panther",         "Cat",          282,   "Creature\\Panther\\Panther.m2" },
    { "Nightsaber (Purple)",   "Cat",          1554,  "Creature\\Panther\\Panther.m2" },  -- Fixed: was 1553 (invalid)
    { "Nightsaber (Black)",    "Cat",          892,   "Creature\\Panther\\Panther.m2" },
    { "Lion",                  "Cat",          2292,  "Creature\\Lion\\Lion.m2" },
    { "Savannah Prowler",      "Cat",          2386,  "Creature\\Lion\\Lion.m2" },  -- Fixed: was 2385 (invalid)
    { "Ghost Saber",	"Cat",	4472,  "Creature\\Panther\\Panther.m2" },
    { "Lynx (Orange)",         "Cat",          21517, "Creature\\Lynx\\Lynx.m2" },  -- Fixed: was 21516 (invalid)
    { "Lynx (Springpaw)",      "Cat",          20682, "Creature\\Lynx\\Lynx.m2" },
    { "Lynx (White)",          "Cat",          21515, "Creature\\Lynx\\Lynx.m2" },
    { "Saber Worg",            "Cat",          22133, "Creature\\Panther\\Panther.m2" },
    { "Frostsaber",            "Cat",          9551,  "Creature\\Panther\\Panther.m2" },
    { "Shadowclaw",            "Cat",          5765,  "Creature\\Panther\\Panther.m2" },
    { "Stranglethorn Tiger",   "Cat",          1196,  "Creature\\Tiger\\Tiger.m2" },

    -- ==============================
    -- CRABS
    -- ==============================
    { "Crab (Red)",            "Crab",         6761,  "Creature\\Crab\\Crab.m2" },
    { "Crab (Blue)",           "Crab",         2955,  "Creature\\Crab\\Crab.m2" },
    { "Crab (Green)",          "Crab",         14555, "Creature\\Crab\\Crab.m2" },
    { "Ghost Crab",            "Crab",         26899, "Creature\\Crab\\Crab.m2" },
    { "Monstrous Crab",        "Crab",         26089, "Creature\\Crab\\Crab.m2" },
    { "Crab (White)",          "Crab",         26096, "Creature\\Crab\\Crab.m2" },

    -- ==============================
    -- CROCOLISKS
    -- ==============================
    { "Crocolisk (Green)",     "Crocolisk",    540,   "Creature\\Crocolisk\\Crocolisk.m2" },
    { "Crocolisk (Black)",     "Crocolisk",    5765,  "Creature\\Crocolisk\\Crocolisk.m2" },
    { "Crocolisk (Red)",       "Crocolisk",    3231,  "Creature\\Crocolisk\\Crocolisk.m2" },  -- Fixed: was 3230 (invalid)
    { "Outland Crocolisk",     "Crocolisk",    20513, "Creature\\Crocolisk\\Crocolisk.m2" },
    { "Sewer Crocolisk",       "Crocolisk",    26353, "Creature\\Crocolisk\\Crocolisk.m2" },
    { "Crocolisk (White)",     "Crocolisk",    26089, "Creature\\Crocolisk\\Crocolisk.m2" },

    -- ==============================
    -- GORILLAS
    -- ==============================
    { "Gorilla (Gray)",        "Gorilla",      2577,  "Creature\\Gorilla\\Gorilla.m2" },  -- Fixed: was 2578 (invalid)
    { "Gorilla (White)",       "Gorilla",      2580,  "Creature\\Gorilla\\Gorilla.m2" },  -- Fixed: was 2579 (invalid)
    { "Gorilla (Black)",       "Gorilla",      7093,  "Creature\\Gorilla\\Gorilla.m2" },
    { "Un'Goro Gorilla",       "Gorilla",      8214,  "Creature\\Gorilla\\Gorilla.m2" },  -- Fixed: was 8213 (invalid)
    { "Uhk'loc",	"Gorilla",	8129,  "Creature\\Gorilla\\Gorilla.m2" },

    -- ==============================
    -- HYENAS
    -- ==============================
    { "Hyena (Brown)",         "Hyena",        1045,  "Creature\\Hyena\\Hyena.m2" },  -- Fixed: was 1044 (invalid)
    { "Hyena (Striped)",       "Hyena",        2697,  "Creature\\Hyena\\Hyena.m2" },  -- Fixed: was 2696 (invalid)
    { "Hyena (Black)",         "Hyena",        4654,  "Creature\\Hyena\\Hyena.m2" },  -- Fixed: was 4653 (invalid)
    { "Dire Hyena",            "Hyena",        7133,  "Creature\\Hyena\\Hyena.m2" },

    -- ==============================
    -- RAPTORS
    -- ==============================
    { "Raptor (Red)",          "Raptor",       3407,  "Creature\\Raptor\\Raptor.m2" },
    { "Raptor (Green)",        "Raptor",       1130,  "Creature\\Raptor\\Raptor.m2" },  -- Fixed: was 1129 (invalid)
    { "Raptor (Purple)",       "Raptor",       3143,  "Creature\\Raptor\\Raptor.m2" },
    { "Raptor (White)",        "Raptor",       6643,  "Creature\\Raptor\\Raptor.m2" },  -- Fixed: was 6642 (invalid)
    { "Raptor (Black)",        "Raptor",       2577,  "Creature\\Raptor\\Raptor.m2" },  -- Fixed: was 2576 (invalid)
    { "Raptor (Orange)",       "Raptor",       14544, "Creature\\Raptor\\Raptor.m2" },
    { "Outland Raptor",	"Raptor",	19732, "Creature\\Raptor\\Raptor.m2" },

    -- ==============================
    -- SCORPIDS
    -- ==============================
    { "Scorpid (Brown)",       "Scorpid",      1266,  "Creature\\Scorpid\\Scorpid.m2" },  -- Fixed: was 1265 (invalid)
    { "Scorpid (Black)",       "Scorpid",      3127,  "Creature\\Scorpid\\Scorpid.m2" },  -- Fixed: was 3126 (invalid)
    { "Scorpid (Red)",         "Scorpid",      2545,  "Creature\\Scorpid\\Scorpid.m2" },  -- Fixed: was 2544 (invalid)
    { "Scorpid (White)",       "Scorpid",      7140,  "Creature\\Scorpid\\Scorpid.m2" },  -- Fixed: was 7139 (invalid)
    { "Outland Scorpid",       "Scorpid",      20339, "Creature\\Scorpid\\Scorpid.m2" },

    -- ==============================
    -- SERPENTS (Wind Serpents)
    -- ==============================
    { "Wind Serpent (Green)",   "Serpent",      2954,  "Creature\\WindSerpent\\WindSerpent.m2" },
    { "Wind Serpent (Blue)",    "Serpent",      2953,  "Creature\\WindSerpent\\WindSerpent.m2" },
    { "Wind Serpent (Red)",     "Serpent",      4381,  "Creature\\WindSerpent\\WindSerpent.m2" },
    { "Wind Serpent (Yellow)",  "Serpent",      5329,  "Creature\\WindSerpent\\WindSerpent.m2" },  -- Fixed: was 5328 (invalid)
    { "Wind Serpent (White)",   "Serpent",      7094,  "Creature\\WindSerpent\\WindSerpent.m2" },
    { "Outland Wind Serpent",   "Serpent",      20111, "Creature\\WindSerpent\\WindSerpent.m2" },

    -- ==============================
    -- SPIDERS
    -- ==============================
    { "Spider (Black)",        "Spider",       1106,  "Creature\\Spider\\Spider.m2" },  -- Fixed: was 1107 (invalid)
    { "Spider (Red)",          "Spider",       1105,  "Creature\\Spider\\Spider.m2" },
    { "Spider (Green)",        "Spider",       1108,  "Creature\\Spider\\Spider.m2" },
    { "Spider (Brown)",        "Spider",       3251,  "Creature\\Spider\\Spider.m2" },
    { "Spider (Gray)",         "Spider",       4406,  "Creature\\Spider\\Spider.m2" },
    { "Outland Spider",        "Spider",       20145, "Creature\\Spider\\Spider.m2" },
    { "Nerubian Spider",       "Spider",       25574, "Creature\\NerubianAbomination\\NerubianAbomination.m2" },

    -- ==============================
    -- TALLSTRIDERS
    -- ==============================
    { "Tallstrider (Gray)",    "Tallstrider",  1379,  "Creature\\Tallstrider\\Tallstrider.m2" },
    { "Tallstrider (Turquoise)",	"Tallstrider",	6478,  "Creature\\Tallstrider\\Tallstrider.m2" },
    { "Tallstrider (Pink)",	"Tallstrider",	6476,  "Creature\\Tallstrider\\Tallstrider.m2" },
    { "Tallstrider (Green)",   "Tallstrider",  3011,  "Creature\\Tallstrider\\Tallstrider.m2" },
    { "Tallstrider (Red)",     "Tallstrider",  3562,  "Creature\\Tallstrider\\Tallstrider.m2" },  -- Fixed: was 3561 (invalid)

    -- ==============================
    -- TURTLES
    -- ==============================
    { "Turtle (Green)",        "Turtle",       1425,  "Creature\\Turtle\\Turtle.m2" },  -- Fixed: was 1424 (invalid)
    { "Turtle (Brown)",        "Turtle",       4723,  "Creature\\Turtle\\Turtle.m2" },  -- Fixed: was 4722 (invalid)
    { "Turtle (Red)",          "Turtle",       7094,  "Creature\\Turtle\\Turtle.m2" },
    { "Turtle (Blue)",         "Turtle",       2424,  "Creature\\Turtle\\Turtle.m2" },
    { "Outland Turtle",        "Turtle",       20157, "Creature\\Turtle\\Turtle.m2" },  -- Fixed: was 20156 (invalid)

    -- ==============================
    -- WOLVES
    -- ==============================
    { "Wolf (Gray)",           "Wolf",         604,   "Creature\\Wolf\\Wolf.m2" },
    { "Wolf (Black)",          "Wolf",         2956,  "Creature\\Wolf\\Wolf.m2" },
    { "Wolf (White)",          "Wolf",         610,   "Creature\\Wolf\\Wolf.m2" },  -- Fixed: was 611 (invalid)
    { "Wolf (Brown)",          "Wolf",         1138,  "Creature\\Wolf\\Wolf.m2" },  -- Fixed: was 1137 (invalid)
    { "Wolf (Timber)",         "Wolf",         12256, "Creature\\Wolf\\Wolf.m2" },  -- Fixed: was 12255 (invalid)
    { "Worg (Dark Iron)",      "Wolf",         903,   "Creature\\Worg\\Worg.m2" },
    { "Worg (Black)",          "Wolf",         1826,  "Creature\\Worg\\Worg.m2" },
    { "Worg (White)",          "Wolf",         26071, "Creature\\Worg\\Worg.m2" },
    { "Worg (Gray)",           "Wolf",         26061, "Creature\\Worg\\Worg.m2" },
    { "Dire Wolf",             "Wolf",         2577,  "Creature\\Wolf\\Wolf.m2" },
    { "Ghost Wolf",            "Wolf",         10981, "Creature\\Wolf\\Wolf.m2" },

    -- ==============================
    -- OWLS (Bird of Prey in Classic, merged with Birds of Prey in TBC)
    -- ==============================
    { "Owl (Brown)",           "Owl",          1563,  "Creature\\Owl\\Owl.m2" },
    { "Owl (Gray)",            "Owl",          7895,  "Creature\\Owl\\Owl.m2" },
    { "Owl (White)",           "Owl",          7898,  "Creature\\Owl\\Owl.m2" },
    { "Owl (Dark)",            "Owl",          14372, "Creature\\Owl\\Owl.m2" },

    -- ==============================
    -- BIRDS OF PREY (Hawks, Eagles — TBC+)
    -- ==============================
    { "Hawk (Brown)",          "Bird of Prey", 18851, "Creature\\Eagle\\Eagle.m2" },
    { "Eagle (White)",         "Bird of Prey", 18852, "Creature\\Eagle\\Eagle.m2" },
    { "Eagle (Black)",         "Bird of Prey", 18854, "Creature\\Eagle\\Eagle.m2" },
    { "Falcon (Red)",          "Bird of Prey", 24083, "Creature\\Eagle\\Eagle.m2" },
    { "Aotona (Exotic Bird)",  "Bird of Prey", 27419, "Creature\\Eagle\\Eagle.m2" },

    -- ==============================
    -- BATS
    -- ==============================
    { "Bat (Gray)",            "Bat",          2129,  "Creature\\Bat\\Bat.m2" },
    { "Bat (Brown)",           "Bat",          10718, "Creature\\Bat\\Bat.m2" },  -- Fixed: was 10717 (invalid)
    { "Bat (White)",           "Bat",          26081, "Creature\\Bat\\Bat.m2" },
    { "Plagued Bat",           "Bat",          26014, "Creature\\Bat\\Bat.m2" },  -- Fixed: was 26013 (invalid)
    { "Vampire Bat",           "Bat",          14544, "Creature\\Bat\\Bat.m2" },

    -- ==============================
    -- CARRION BIRDS (Vultures, Buzzards)
    -- ==============================
    { "Vulture (Brown)",       "Carrion Bird", 1194,  "Creature\\Vulture\\Vulture.m2" },
    { "Vulture (Black)",       "Carrion Bird", 4235,  "Creature\\Vulture\\Vulture.m2" },
    { "Vulture (Red)",         "Carrion Bird", 4714,  "Creature\\Vulture\\Vulture.m2" },
    { "Carrion Bird (Bone)",   "Carrion Bird", 26074, "Creature\\Vulture\\Vulture.m2" },  -- Fixed: was 26073 (invalid)
    { "Outland Carrion Bird",  "Carrion Bird", 20365, "Creature\\Vulture\\Vulture.m2" },

    -- ==============================
    -- DRAGONHAWKS (TBC+)
    -- ==============================
    { "Dragonhawk (Red)",      "Dragonhawk",  20031, "Creature\\DragonHawk\\DragonHawk.m2" },
    { "Dragonhawk (Blue)",     "Dragonhawk",  20029, "Creature\\DragonHawk\\DragonHawk.m2" },  -- Fixed: was 20035 (invalid)
    { "Dragonhawk (Yellow)",   "Dragonhawk",  20026, "Creature\\DragonHawk\\DragonHawk.m2" },  -- Fixed: was 20032 (invalid)
    { "Dragonhawk (Purple)",   "Dragonhawk",  20033, "Creature\\DragonHawk\\DragonHawk.m2" },
    { "Dragonhawk (Green)",    "Dragonhawk",  20028, "Creature\\DragonHawk\\DragonHawk.m2" },  -- Fixed: was 20034 (invalid)
    { "Dragonhawk (White)",    "Dragonhawk",  20037, "Creature\\DragonHawk\\DragonHawk.m2" },  -- Fixed: was 20036 (invalid)

    -- ==============================
    -- NETHER RAYS (TBC+)
    -- ==============================
    { "Nether Ray (Purple)",   "Nether Ray",  21500, "Creature\\NetherRay\\NetherRay.m2" },
    { "Nether Ray (Red)",      "Nether Ray",  21496, "Creature\\NetherRay\\NetherRay.m2" },  -- Fixed: was 21497 (invalid)
    { "Nether Ray (Blue)",     "Nether Ray",  21501, "Creature\\NetherRay\\NetherRay.m2" },
    { "Nether Ray (Green)",    "Nether Ray",  21499, "Creature\\NetherRay\\NetherRay.m2" },  -- Fixed: was 21498 (invalid)
    { "Nether Ray (Silver)",   "Nether Ray",  21503, "Creature\\NetherRay\\NetherRay.m2" },

    -- ==============================
    -- RAVAGERS (TBC+)
    -- ==============================
    { "Ravager (Red)",         "Ravager",      17378, "Creature\\Ravager\\Ravager.m2" },  -- Fixed: was 17377 (invalid)
    { "Ravager (Orange)",      "Ravager",      20063, "Creature\\Ravager\\Ravager.m2" },
    { "Ravager (Green)",       "Ravager",      20064, "Creature\\Ravager\\Ravager.m2" },
    { "Ravager (White)",       "Ravager",      20066, "Creature\\Ravager\\Ravager.m2" },  -- Fixed: was 20065 (invalid)
    { "Ravager (Blue)",        "Ravager",      20062, "Creature\\Ravager\\Ravager.m2" },

    -- ==============================
    -- SPOREBATS (TBC+)
    -- ==============================
    { "Sporebat (Purple)",     "Sporebat",     17831, "Creature\\Sporebat\\Sporebat.m2" },
    { "Sporebat (Red)",        "Sporebat",     20377, "Creature\\Sporebat\\Sporebat.m2" },  -- Fixed: was 20378 (invalid)
    { "Sporebat (Blue)",       "Sporebat",     20376, "Creature\\Sporebat\\Sporebat.m2" },  -- Fixed: was 20379 (invalid)
    { "Sporebat (Yellow)",     "Sporebat",     20381, "Creature\\Sporebat\\Sporebat.m2" },  -- Fixed: was 20380 (invalid)
    { "Sporebat (White)",      "Sporebat",     20383, "Creature\\Sporebat\\Sporebat.m2" },  -- Fixed: was 20382 (invalid)

    -- ==============================
    -- WARP STALKERS (TBC+)
    -- ==============================
    { "Warp Stalker (Green)",  "Warp Stalker", 20122, "Creature\\WarpStalker\\WarpStalker.m2" },
    { "Warp Stalker (Red)",    "Warp Stalker", 20123, "Creature\\WarpStalker\\WarpStalker.m2" },
    { "Warp Stalker (Blue)",   "Warp Stalker", 20124, "Creature\\WarpStalker\\WarpStalker.m2" },
    { "Warp Stalker (White)",  "Warp Stalker", 20126, "Creature\\WarpStalker\\WarpStalker.m2" },
    { "Warp Stalker (Purple)", "Warp Stalker", 20125, "Creature\\WarpStalker\\WarpStalker.m2" },

    -- ==============================
    -- MOTHS (TBC+)
    -- ==============================
    { "Moth (White)",          "Moth",         20666, "Creature\\Moth\\Moth.m2" },  -- Fixed: was 20667 (invalid)
    { "Moth (Yellow)",         "Moth",         19985, "Creature\\Moth\\Moth.m2" },  -- Fixed: was 20668 (invalid)
    { "Moth (Blue)",           "Moth",         19987, "Creature\\Moth\\Moth.m2" },  -- Fixed: was 20669 (invalid)
    { "Moth (Red)",            "Moth",         20670, "Creature\\Moth\\Moth.m2" },
    { "Moth (Green)",          "Moth",         20671, "Creature\\Moth\\Moth.m2" },

    -- ==============================
    -- WASPS (TBC+)
    -- ==============================
    { "Wasp (Yellow)",         "Wasp",         18284, "Creature\\Wasp\\Wasp.m2" },  -- Fixed: was 18283 (invalid)
    { "Wasp (Red)",            "Wasp",         20585, "Creature\\Wasp\\Wasp.m2" },
    { "Wasp (Blue)",           "Wasp",         20584, "Creature\\Wasp\\Wasp.m2" },
    { "Wasp (Green)",          "Wasp",         20586, "Creature\\Wasp\\Wasp.m2" },

    -- ==============================
    -- SERPENTS (Snakes — not Wind Serpents)
    -- ==============================
    { "Snake (Green)",         "Snake",        3415,  "Creature\\Snake\\Snake.m2" },
    { "Snake (Brown)",         "Snake",        5165,  "Creature\\Snake\\Snake.m2" },
    { "Snake (Black)",         "Snake",        6303,  "Creature\\Snake\\Snake.m2" },
    { "Snake (Red)",           "Snake",        14544, "Creature\\Snake\\Snake.m2" },
    { "Cobra",	"Snake",	4213, "Creature\\Cobra\\Cobra.m2" },
    { "King Cobra",            "Snake",        20578, "Creature\\Cobra\\Cobra.m2" },

    -- ==============================
    -- CHIMERAS (Exotic — BM only, WotLK)
    -- ==============================
    { "Chimera (Blue)",        "Chimera",      25511, "Creature\\HydraMount\\HydraMount.m2" },
    { "Chimera (Green)",       "Chimera",      26360, "Creature\\HydraMount\\HydraMount.m2" },
    { "Chimera (Red)",         "Chimera",      26317, "Creature\\HydraMount\\HydraMount.m2" },  -- Fixed: was 26316 (invalid)
    { "Chimera (White)",       "Chimera",      26361, "Creature\\HydraMount\\HydraMount.m2" },
    { "Chimera (Purple)",      "Chimera",      26359, "Creature\\HydraMount\\HydraMount.m2" },

    -- ==============================
    -- CORE HOUNDS (Exotic — BM only)
    -- ==============================
    { "Core Hound (Orange)",   "Core Hound",   10813, "Creature\\CoreHound\\CoreHound.m2" },
    { "Core Hound (Black)",    "Core Hound",   10957, "Creature\\CoreHound\\CoreHound.m2" },  -- Fixed: was 10956 (invalid)
    { "Core Hound (Purple)",   "Core Hound",   27347, "Creature\\CoreHound\\CoreHound.m2" },
    { "Core Hound (Kurken)",   "Core Hound",   18162, "Creature\\CoreHound\\CoreHound.m2" },
    { "Magmadar",              "Core Hound",   10193, "Creature\\CoreHound\\CoreHound.m2" },

    -- ==============================
    -- DEVILSAURS (Exotic — BM only)
    -- ==============================
    { "Devilsaur (Green)",     "Devilsaur",    7345,  "Creature\\Devilsaur\\Devilsaur.m2" },
    { "Devilsaur (Black)",     "Devilsaur",    8029,  "Creature\\Devilsaur\\Devilsaur.m2" },
    { "King Krush",            "Devilsaur",    26650, "Creature\\Devilsaur\\Devilsaur.m2" },
    { "Devilsaur (White)",     "Devilsaur",    26649, "Creature\\Devilsaur\\Devilsaur.m2" },  -- Fixed: was 26648 (invalid)

    -- ==============================
    -- SILITHIDS (Exotic — BM only)
    -- ==============================
    { "Silithid (Green)",      "Silithid",     8311,  "Creature\\SilithidTank\\SilithidTank.m2" },
    { "Silithid (Red)",        "Silithid",     8314,  "Creature\\SilithidTank\\SilithidTank.m2" },
    { "Silithid (Blue)",       "Silithid",     8309,  "Creature\\SilithidTank\\SilithidTank.m2" },
    { "Silithid (Black)",      "Silithid",     15123, "Creature\\SilithidTank\\SilithidTank.m2" },  -- Fixed: was 15122 (invalid)

    -- ==============================
    -- SPIRIT BEASTS (Exotic — BM only, WotLK)
    -- ==============================
    { "Loque'nahak",           "Spirit Beast", 26349, "Creature\\SpiritBeast\\SpiritBeast.m2" },
    { "Gondria",               "Spirit Beast", 29268, "Creature\\SpiritBeast\\SpiritBeast.m2" },
    { "Skoll",                 "Spirit Beast", 29602, "Creature\\Worg\\Worg.m2" },
    { "Arcturis",              "Spirit Beast", 29756, "Creature\\Bear2\\Bear2.m2" },

    -- ==============================
    -- WORMS (Exotic — BM only, WotLK)
    -- ==============================
    { "Jormungar (White)",     "Worm",         25600, "Creature\\Jormungar\\Jormungar.m2" },
    { "Jormungar (Black)",     "Worm",         26292, "Creature\\Jormungar\\Jormungar.m2" },
    { "Jormungar (Blue)",      "Worm",         26291, "Creature\\Jormungar\\Jormungar.m2" },
    { "Jormungar (Purple)",    "Worm",         26290, "Creature\\Jormungar\\Jormungar.m2" },
    { "Jormungar (Red)",       "Worm",         25601, "Creature\\Jormungar\\Jormungar.m2" },
    { "Oozeling (Green)",      "Worm",         24584, "Creature\\Ooze\\Ooze.m2" },

    -- ==============================
    -- RHINOS (Exotic — BM only, WotLK)
    -- ==============================
    { "Rhino (Gray)",          "Rhino",        24758, "Creature\\Rhino\\Rhino.m2" },
    { "Rhino (Brown)",         "Rhino",        25359, "Creature\\Rhino\\Rhino.m2" },  -- Fixed: was 25360 (invalid)
    { "Rhino (White)",         "Rhino",        24759, "Creature\\Rhino\\Rhino.m2" },  -- Fixed: was 25361 (invalid)
    { "Rhino (Black)",         "Rhino",        24760, "Creature\\Rhino\\Rhino.m2" },  -- Fixed: was 25362 (invalid)

    -- ==============================
    -- CROCOLISKS (Northrend)
    -- ==============================
    { "Mangal Crocolisk",      "Crocolisk",    26077, "Creature\\Crocolisk\\Crocolisk.m2" },

    -- ==============================
    -- GORILLAS (Northrend)
    -- ==============================
    { "Storm Peaks Gorilla",   "Gorilla",      26638, "Creature\\Gorilla\\Gorilla.m2" },

    -- ==============================
    -- WOLVES (Northrend)
    -- ==============================
    { "Northrend Worg (Brown)","Wolf",         26062, "Creature\\Worg\\Worg.m2" },
    { "Northrend Worg (Red)",  "Wolf",         26063, "Creature\\Worg\\Worg.m2" },
    { "Northrend Worg (Black)","Wolf",         26064, "Creature\\Worg\\Worg.m2" },
    { "Northrend Wolf (Black)","Wolf",         26061, "Creature\\Wolf\\Wolf.m2" },  -- Fixed: was 26060 (invalid)
    { "Northrend Wolf (White)","Wolf",         26069, "Creature\\Wolf\\Wolf.m2" },  -- Fixed: was 26068 (invalid)

    -- ==============================
    -- BEARS (Northrend)
    -- ==============================
    { "Northrend Bear (Black)","Bear",         29415, "Creature\\Bear2\\Bear2.m2" },  -- Fixed: was 29414 (invalid)
    { "Northrend Bear (White)","Bear",         26646, "Creature\\Bear2\\Bear2.m2" },  -- Fixed: was 26647 (invalid)

    -- ==============================
    -- CATS (Northrend)
    -- ==============================
    { "Northrend Cat (Saber)", "Cat",          26083, "Creature\\Panther\\Panther.m2" },
    { "Sholazar Tiger",        "Cat",          26669, "Creature\\Tiger\\Tiger.m2" },

    -- ==============================
    -- RAPTORS (Northrend)
    -- ==============================
    { "Northrend Raptor",      "Raptor",       26204, "Creature\\Raptor\\Raptor.m2" },  -- Fixed: was 26203 (invalid)

    -- ==============================
    -- SPIDERS (Northrend)
    -- ==============================
    { "Northrend Spider (White)","Spider",     26047, "Creature\\Spider\\Spider.m2" },  -- Fixed: was 26048 (invalid)
    { "Northrend Spider (Black)","Spider",     26050, "Creature\\Spider\\Spider.m2" },  -- Fixed: was 26049 (invalid)

    -- ==============================
    -- WASPS (Northrend)
    -- ==============================
    { "Northrend Wasp",        "Wasp",         25864, "Creature\\Wasp\\Wasp.m2" },  -- Fixed: was 25863 (invalid)

    -- ==============================
    -- MOTHS (Northrend)
    -- ==============================
    { "Northrend Moth",        "Moth",         25859, "Creature\\Moth\\Moth.m2" },  -- Fixed: was 25858 (invalid)

    -- ==============================
    -- MISCELLANEOUS TAMEABLE
    -- ==============================
    { "Scorpid (Northrend)",   "Scorpid",      26030, "Creature\\Scorpid\\Scorpid.m2" },  -- Fixed: was 26029 (invalid)
    { "Tallstrider (Northrend)","Tallstrider",  26092, "Creature\\Tallstrider\\Tallstrider.m2" },  -- Fixed: was 26091 (invalid)
    { "Turtle (Northrend)",    "Turtle",       26083, "Creature\\Turtle\\Turtle.m2" },  -- Fixed: was 26082 (invalid)
    { "Crab (Northrend)",      "Crab",         25998, "Creature\\Crab\\Crab.m2" },  -- Fixed: was 25997 (invalid)
    { "Bat (Northrend)",       "Bat",          26011, "Creature\\Bat\\Bat.m2" },  -- Fixed: was 26012 (invalid)
    { "Carrion Bird (Northrend)","Carrion Bird",26076,"Creature\\Vulture\\Vulture.m2" },  -- Fixed: was 26075 (invalid)
    { "Dragonhawk (Northrend)","Dragonhawk",   26670, "Creature\\DragonHawk\\DragonHawk.m2" },  -- Fixed: was 26669 (invalid)

    -- ==============================
    -- WARLOCK DEMONS
    -- ==============================
    { "Imp",                   "Warlock",      4449,  "Creature\\Imp\\Imp.m2", 416 },
    { "Imp (Flame)",           "Warlock",      12472, "Creature\\Imp\\Imp.m2" },
    { "Voidwalker",            "Warlock",      1132,  "Creature\\VoidWalker\\VoidWalker.m2", 1860 },
    { "Voidwalker (Dark)",     "Warlock",      23705, "Creature\\VoidWalker\\VoidWalker.m2" },
    { "Succubus",              "Warlock",      4162,  "Creature\\Succubus\\Succubus.m2", 1863 },
    { "Felhunter",             "Warlock",      850,   "Creature\\FelHunter\\FelHunter.m2", 417 },
    { "Felguard",              "Warlock",      18462, "Creature\\FelGuard\\FelGuard.m2", 17252 },
    { "Felguard (Armored)",    "Warlock",      18483, "Creature\\FelGuard\\FelGuard.m2" },
    { "Infernal",              "Warlock",      169,   "Creature\\Infernal\\Infernal.m2", 89 },
    { "Infernal (Abyssal)",    "Warlock",      15654, "Creature\\Infernal\\Infernal.m2" },
    { "Doomguard",             "Warlock",      11380, "Creature\\DoomGuard\\DoomGuard.m2" },
    { "Doomguard (Felfire)",   "Warlock",      21072, "Creature\\DoomGuard\\DoomGuard.m2" },
    { "Fel Stalker",           "Warlock",      15200, "Creature\\FelHunter\\FelHunter.m2" },

    -- ==============================
    -- MAGE PETS
    -- ==============================
    { "Water Elemental",       "Mage",         525,   "Creature\\WaterElemental\\WaterElemental.m2", 510 },
    { "Water Elemental (Large)","Mage",        5765,  "Creature\\WaterElemental\\WaterElemental.m2" },
    { "Water Elemental (Glacial)","Mage",      28232, "Creature\\WaterElemental\\WaterElemental.m2" },  -- Fixed: was 28231 (invalid)
    { "Frost Elemental",       "Mage",         26428, "Creature\\FrostElemental\\FrostElemental.m2" },
    { "Bound Water Elemental", "Mage",         16942, "Creature\\WaterElemental\\WaterElemental.m2" },
}
