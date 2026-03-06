local addon, ns = ...

-- WoW 3.3.5a Companion Pet (Critter) Database
-- Format: { name, spellID, displayID, "model\\path.m2" }
-- displayID = CreatureDisplayInfo ID used to overwrite the critter's UNIT_FIELD_DISPLAYID
-- modelPath = M2 model file for 3D preview

ns.petsDB = {
    ---------------------------------------------------------------------------
    -- CATS
    ---------------------------------------------------------------------------
    { "Black Tabby Cat",            10675,  6368,   "Creature\\Cat\\Cat.m2" },
    { "Bombay Cat",                 10673,  5554,   "Creature\\Cat\\Cat.m2" },
    { "Calico Cat",                 10674,  6367,   "Creature\\Cat\\Cat.m2" },
    { "Cornish Rex Cat",            10676,  5586,   "Creature\\Cat\\Cat.m2" },
    { "Orange Tabby Cat",           10680,  7382,   "Creature\\Cat\\Cat.m2" },
    { "Siamese Cat",                10677,  7380,   "Creature\\Cat\\Cat.m2" },
    { "Silver Tabby Cat",           10678,  5585,   "Creature\\Cat\\Cat.m2" },
    { "White Kitten",               10679,  7560,   "Creature\\Cat\\Cat.m2" },

    ---------------------------------------------------------------------------
    -- SNAKES
    ---------------------------------------------------------------------------
    { "Black Kingsnake",            10714,  6200,   "Creature\\Snake\\Snake.m2" },
    { "Brown Snake",                10716,  6202,   "Creature\\Snake\\Snake.m2" },
    { "Crimson Snake",              10717,  6201,   "Creature\\Snake\\Snake.m2" },
    { "Albino Snake",               10713,  7556,   "Creature\\Snake\\Snake.m2" },

    ---------------------------------------------------------------------------
    -- BIRDS / OWLS / PARROTS
    ---------------------------------------------------------------------------
    { "Cockatiel",                  10683,  7389,   "Creature\\Parrot\\Parrot.m2" },
    { "Green Wing Macaw",           10684,  7387,   "Creature\\Parrot\\Parrot.m2" },
    { "Hyacinth Macaw",             10682,  7391,   "Creature\\Parrot\\Parrot.m2" },
    { "Senegal",                    10684,  7388,   "Creature\\Parrot\\Parrot.m2" },
    { "Hawk Owl",                   10706,  7555,   "Creature\\Owl\\Owl.m2" },
    { "Great Horned Owl",           10707,  7553,   "Creature\\Owl\\Owl.m2" },
    { "Westfall Chicken",           10685,  304,    "Creature\\Chicken\\Chicken.m2" },
    { "Ancona Chicken",             10685,  2512,   "Creature\\Chicken\\Chicken.m2" },
    { "Plucky Johnson",             12243,  303,    "Creature\\Chicken\\Chicken.m2" },

    ---------------------------------------------------------------------------
    -- RABBITS / RODENTS
    ---------------------------------------------------------------------------
    { "Snowshoe Rabbit",            10711,  328,    "Creature\\Rabbit\\Rabbit.m2" },
    { "Spring Rabbit",              61725,  28905,  "Creature\\Rabbit\\Rabbit.m2" },
    { "Brown Prairie Dog",          10709,  1155,   "Creature\\PrairieDog\\PrairieDog.m2" },
    { "Black Prairie Dog",          10709,  1155,   "Creature\\PrairieDog\\PrairieDog.m2" },
    { "Squirrel",                   10709,  134,    "Creature\\Squirrel\\Squirrel.m2" },
    { "Rat",                        10709,  2176,   "Creature\\Rat\\Rat.m2" },
    { "Undercity Cockroach",        10688,  6534,   "Creature\\Cockroach\\Cockroach.m2" },

    ---------------------------------------------------------------------------
    -- FROGS / TOADS / CRITTERS
    ---------------------------------------------------------------------------
    { "Tree Frog",                  10695,  865,    "Creature\\Frog\\Frog.m2" },
    { "Wood Frog",                  10696,  864,    "Creature\\Frog\\Frog.m2" },
    { "Mojo",                       43918,  1536,   "Creature\\Frog\\Frog.m2" },
    { "Jubling",                    23811,  10979,  "Creature\\Frog\\Frog.m2" },

    ---------------------------------------------------------------------------
    -- BUGS / INSECTS
    ---------------------------------------------------------------------------
    { "Firefly",                    36034,  20029,  "Creature\\Firefly\\Firefly.m2" },
    { "Bombadier Beetle",           61688,  27690,  "Creature\\Beetle\\Beetle.m2" },
    { "Dung Beetle",                61689,  27691,  "Creature\\Beetle\\Beetle.m2" },
    { "Gold Beetle",                61690,  27692,  "Creature\\Beetle\\Beetle.m2" },

    ---------------------------------------------------------------------------
    -- MECHANICAL
    ---------------------------------------------------------------------------
    { "Mechanical Squirrel",        4055,   1340,   "Creature\\Squirrel\\Squirrel.m2" },
    { "Pet Bombling",               15048,  8984,   "Creature\\BombBot\\BombBot.m2" },
    { "Lil' Smoky",                 15049,  8986,   "Creature\\SmallSmoke\\SmallSmoke.m2" },
    { "Mechanical Chicken",         12243,  5765,   "Creature\\MechanicalChicken\\MechanicalChicken.m2" },
    { "Clockwork Rocket Bot",       24968,  24270,  "Creature\\RocketBot\\RocketBot.m2" },
    { "Blue Clockwork Rocket Bot",  75134,  31690,  "Creature\\RocketBot\\RocketBot.m2" },
    { "Tranquil Mechanical Yeti",   26010,  15114,  "Creature\\Yeti\\Yeti.m2" },
    { "Lifelike Mechanical Toad",   19772,  6297,   "Creature\\Frog\\Frog.m2" },
    { "Lil' XT",                    75906,  30414,  "Creature\\Xt002\\Xt002.m2" },

    ---------------------------------------------------------------------------
    -- DRAGONS / WHELPS
    ---------------------------------------------------------------------------
    { "Azure Whelpling",            10696,  10357,  "Creature\\FaerieDragon\\FaerieDragon.m2" },
    { "Crimson Whelpling",          10697,  1206,   "Creature\\WhelpRed\\WhelpRed.m2" },
    { "Dark Whelpling",             10695,  4543,   "Creature\\WhelpBlack\\WhelpBlack.m2" },
    { "Emerald Whelpling",          10698,  7862,   "Creature\\WhelpGreen\\WhelpGreen.m2" },
    { "Onyxian Whelpling",          69002,  29684,  "Creature\\WhelpBlack\\WhelpBlack.m2" },
    { "Sprite Darter Hatchling",    15067,  9199,   "Creature\\FaerieDragon\\FaerieDragon.m2" },
    { "Proto-Drake Whelp",          61350,  28017,  "Creature\\ProtoDrakeWhelp\\ProtoDrakeWhelp.m2" },
    { "Nether Ray Fry",             51716,  25541,  "Creature\\NetherRay\\NetherRay.m2" },

    ---------------------------------------------------------------------------
    -- MOTHS
    ---------------------------------------------------------------------------
    { "Blue Moth",                  35907,  20071,  "Creature\\Moth\\Moth.m2" },
    { "Red Moth",                   35909,  20073,  "Creature\\Moth\\Moth.m2" },
    { "White Moth",                 35911,  20074,  "Creature\\Moth\\Moth.m2" },
    { "Yellow Moth",                35910,  20075,  "Creature\\Moth\\Moth.m2" },

    ---------------------------------------------------------------------------
    -- DRAGONHAWKS
    ---------------------------------------------------------------------------
    { "Golden Dragonhawk Hatchling",36027,  20023,  "Creature\\DragonHawk\\DragonHawk.m2" },
    { "Red Dragonhawk Hatchling",   36028,  20025,  "Creature\\DragonHawk\\DragonHawk.m2" },
    { "Silver Dragonhawk Hatchling",36029,  20026,  "Creature\\DragonHawk\\DragonHawk.m2" },
    { "Blue Dragonhawk Hatchling",  36031,  20022,  "Creature\\DragonHawk\\DragonHawk.m2" },

    ---------------------------------------------------------------------------
    -- DOGS / WOLVES
    ---------------------------------------------------------------------------
    { "Worg Pup",                   15999,  10259,  "Creature\\Worg\\Worg.m2" },
    { "Perky Pug",                  70613,  30089,  "Creature\\Pug\\Pug.m2" },

    ---------------------------------------------------------------------------
    -- SCORPIONS
    ---------------------------------------------------------------------------
    { "Scorpid",                    10709,  4081,   "Creature\\Scorpion\\Scorpion.m2" },

    ---------------------------------------------------------------------------
    -- TURTLES
    ---------------------------------------------------------------------------
    { "Speedy",                     10709,  6125,   "Creature\\Turtle\\Turtle.m2" },
    { "Loggerhead Snapjaw",         10709,  7937,   "Creature\\Turtle\\Turtle.m2" },
    { "Turtle (normal)",            10709,  6127,   "Creature\\Turtle\\Turtle.m2" },

    ---------------------------------------------------------------------------
    -- SPOREBATS / OUTLAND
    ---------------------------------------------------------------------------
    { "Tiny Sporebat",              45082,  22487,  "Creature\\SporeBat\\SporeBat.m2" },
    { "Mana Wyrmling",              35156,  19737,  "Creature\\ManaWyrm\\ManaWyrm.m2" },

    ---------------------------------------------------------------------------
    -- NORTHREND
    ---------------------------------------------------------------------------
    { "Tickbird Hatchling",         61348,  27566,  "Creature\\Tickbird\\Tickbird.m2" },
    { "White Tickbird Hatchling",   61349,  27567,  "Creature\\Tickbird\\Tickbird.m2" },
    { "Cobra Hatchling",            61351,  27562,  "Creature\\CobraHatchling\\CobraHatchling.m2" },
    { "Pengu",                      61357,  24698,  "Creature\\Penguin\\Penguin.m2" },
    { "Kirin Tor Familiar",         61472,  27914,  "Creature\\ArcaneGuardian\\ArcaneGuardian.m2" },
    { "Ghostly Skull",              53316,  25901,  "Creature\\SkeletonMage\\SkeletonMage.m2" },

    ---------------------------------------------------------------------------
    -- TCG / PROMO / BLIZZCON
    ---------------------------------------------------------------------------
    { "Bananas (Monkey)",           30156,  17310,  "Creature\\Monkey\\Monkey.m2" },
    { "Egbert (Hawkstrider)",       40614,  17510,  "Creature\\Hawkstrider\\Hawkstrider.m2" },
    { "Peanut (Elekk)",             40634,  17512,  "Creature\\Elekk\\Elekk.m2" },
    { "Willy (Sleepy Willy)",       40613,  17282,  "Creature\\WillyBlinky\\WillyBlinky.m2" },
    { "Lurky (Murloc)",             24988,  15357,  "Creature\\BabyMurloc\\BabyMurloc.m2" },
    { "Murky (Murloc)",             24696,  15361,  "Creature\\BabyMurloc\\BabyMurloc.m2" },
    { "Gurky (Murloc)",             24697,  15360,  "Creature\\BabyMurloc\\BabyMurloc.m2" },
    { "Terky (Murloc)",             24988,  15357,  "Creature\\BabyMurloc\\BabyMurloc.m2" },
    { "Murloc Costume (Murloc)",    24696,  15362,  "Creature\\BabyMurloc\\BabyMurloc.m2" },
    { "Grunty (Murloc Marine)",     66030,  29348,  "Creature\\BabyMurloc\\BabyMurloc.m2" },
    { "Deathy (Murloc Deathwing)",  75906,  31957,  "Creature\\BabyMurloc\\BabyMurloc.m2" },
    { "Baby Blizzard Bear",         61855,  27807,  "Creature\\Bear2\\Bear2.m2" },
    { "Frosty (Frost Wyrm)",        52615,  25652,  "Creature\\FrostWyrm\\FrostWyrm.m2" },
    { "Mini Tyrael",                39656,  21120,  "Creature\\Tyrael\\Tyrael.m2" },
    { "Spirit of Competition",      48406,  24187,  "Creature\\Hippogryph\\Hippogryph.m2" },
    { "Netherwhelp",                32298,  17255,  "Creature\\WhelpNether\\WhelpNether.m2" },
    { "Pandaren Monk",              69541,  30156,  "Creature\\PandarenMonk\\PandarenMonk.m2" },
    { "Lil' K.T.",                  69677,  30507,  "Creature\\LichKing\\LichKing.m2" },

    ---------------------------------------------------------------------------
    -- ORPHAN WEEK
    ---------------------------------------------------------------------------
    { "Curious Oracle Hatchling",   65381,  25909,  "Creature\\WolvarPup\\WolvarPup.m2" },
    { "Curious Wolvar Pup",         65382,  25895,  "Creature\\WolvarPup\\WolvarPup.m2" },

    ---------------------------------------------------------------------------
    -- ARGENT TOURNAMENT
    ---------------------------------------------------------------------------
    { "Argent Squire",              67068,  29249,  "Creature\\Humanmale\\HumanMale.m2" },
    { "Argent Gruntling",           67069,  29248,  "Creature\\OrcMaleChild\\OrcMaleChild.m2" },
    { "Mechanopeep",                63715,  28889,  "Creature\\Mechanostrider\\Mechanostrider.m2" },
    { "Shimmering Wyrmling",        64351,  28988,  "Creature\\ManaWyrm\\ManaWyrm.m2" },
    { "Sen'jin Fetish",             66567,  29224,  "Creature\\FetishTroll\\FetishTroll.m2" },
    { "Tirisfal Batling",           62564,  28524,  "Creature\\Bat\\Bat.m2" },
    { "Dun Morogh Cub",             62508,  28521,  "Creature\\Bear2\\Bear2.m2" },
    { "Teldrassil Sproutling",      62491,  28525,  "Creature\\TreantWardling\\TreantWardling.m2" },
    { "Elwynn Lamb",                62516,  28520,  "Creature\\Sheep\\Sheep.m2" },
    { "Durotar Scorpion",           62513,  28526,  "Creature\\Scorpion\\Scorpion.m2" },
    { "Mulgore Hatchling",          62542,  28519,  "Creature\\Tallstrider\\Tallstrider.m2" },
    { "Ammen Vale Lashling",        62562,  28523,  "Creature\\LashVine\\LashVine.m2" },
    { "Enchanted Broom",            62564,  28521,  "Creature\\EnchantedBroom\\EnchantedBroom.m2" },

    ---------------------------------------------------------------------------
    -- VARIOUS / SEASONAL
    ---------------------------------------------------------------------------
    { "Disgusting Oozeling",        25162,  15429,  "Creature\\Ooze\\Ooze.m2" },
    { "Tiny Crimson Whelpling",     10697,  1206,   "Creature\\WhelpRed\\WhelpRed.m2" },
    { "Sinister Squashling",        42609,  21955,  "Creature\\PumpkinSoldier\\PumpkinSoldier.m2" },
    { "Vampiric Batling",           51851,  25744,  "Creature\\Bat\\Bat.m2" },
    { "Phoenix Hatchling",          46599,  23191,  "Creature\\Phoenix\\Phoenix.m2" },
    { "Magical Crawdad",            33050,  18169,  "Creature\\Lobster\\Lobster.m2" },
    { "Mr. Wiggles (Pig)",          10709,  4928,   "Creature\\Boar\\Boar.m2" },
    { "Whiskers the Rat",           10709,  2176,   "Creature\\Rat\\Rat.m2" },
    { "Stinker (Skunk)",            40990,  21510,  "Creature\\Skunk\\Skunk.m2" },
    { "Smolderweb Hatchling",       10709,  1185,   "Creature\\Spider\\Spider.m2" },
    { "Willy (Sleepy Eye)",         40613,  17282,  "Creature\\WillyBlinky\\WillyBlinky.m2" },
    { "Wolpertinger",               39709,  21168,  "Creature\\Wolpertinger\\Wolpertinger.m2" },
    { "Little Fawn",                61991,  27856,  "Creature\\Deer\\Deer.m2" },
    { "Leaping Hatchling",          36871,  20210,  "Creature\\Raptor\\Raptor.m2" },
    { "Darting Hatchling",          36872,  20211,  "Creature\\Raptor\\Raptor.m2" },
    { "Deviate Hatchling",          36873,  20209,  "Creature\\Raptor\\Raptor.m2" },
    { "Ravasaur Hatchling",         36874,  20212,  "Creature\\Raptor\\Raptor.m2" },
    { "Razormaw Hatchling",         36875,  20208,  "Creature\\Raptor\\Raptor.m2" },
    { "Razzashi Hatchling",         36876,  20213,  "Creature\\Raptor\\Raptor.m2" },
    { "Obsidian Hatchling",         67417,  29599,  "Creature\\Raptor\\Raptor.m2" },
    { "Captured Firefly",           36034,  20029,  "Creature\\Firefly\\Firefly.m2" },
    { "Strand Crawler",             62561,  28529,  "Creature\\Crab\\Crab.m2" },
    { "Giant Sewer Rat",            59250,  28033,  "Creature\\Rat\\Rat.m2" },
    { "Chuck (Crocodile)",          46426,  22095,  "Creature\\BabyCrocolisk\\BabyCrocolisk.m2" },
    { "Muckbreath (Crocodile)",     43698,  22087,  "Creature\\BabyCrocolisk\\BabyCrocolisk.m2" },
    { "Snarly (Crocodile)",         46425,  22094,  "Creature\\BabyCrocolisk\\BabyCrocolisk.m2" },
    { "Toothy (Crocodile)",         43697,  22089,  "Creature\\BabyCrocolisk\\BabyCrocolisk.m2" },

    ---------------------------------------------------------------------------
    -- ICC PETS
    ---------------------------------------------------------------------------
    { "Core Hound Pup",             69452,  30089,  "Creature\\LavaSpawn\\LavaSpawn.m2" },
    { "Toxic Wasteling",            71840,  31158,  "Creature\\Ooze\\Ooze.m2" },
    { "Frigid Frostling",           74932,  31581,  "Creature\\WaterElemental\\WaterElemental.m2" },
}
