from collections import namedtuple
from enum import IntEnum
from shared import pack_values


Cost = namedtuple('Cost', 'resource_count bits packed_ids packed_amounts')
CostWithLords = namedtuple('Cost', 'resource_count bits packed_ids packed_amounts lords')
Troop = namedtuple('Troop', 'id type tier building agility attack defense vitality wisdom')
Squad = namedtuple(
    'Squad',
    't1_1 t1_2 t1_3 t1_4 t1_5 t1_6 t1_7 t1_8 t1_9 t2_1 t2_2 t2_3 t2_4 t2_5 t3_1',
)


class TroopId(IntEnum):
    Skirmisher = 1
    Longbow = 2
    Crossbow = 3
    Pikeman = 4
    Knight = 5
    Paladin = 6
    Ballista = 7
    Mangonel = 8
    Trebuchet = 9
    Apprentice = 10
    Mage = 11
    Arcanist = 12


class TroopType(IntEnum):
    RangedNormal = 1
    RangedMagic = 2
    Melee = 3
    Siege = 4


class ResourceIds(IntEnum):
    Wood = 1
    Stone = 2
    Coal = 3
    Copper = 4
    Obsidian = 5
    Silver = 6
    Ironwood = 7
    ColdIron = 8
    Gold = 9
    Hartwood = 10
    Diamonds = 11
    Sapphire = 12
    Ruby = 13
    DeepCrystal = 14
    Ignium = 15
    EtherealSilica = 16
    TrueIce = 17
    TwilightQuartz = 18
    AlchemicalSilver = 19
    Adamantine = 20
    Mithral = 21
    Dragonhide = 22


class BuildingId(IntEnum):
    Fairgrounds = 1
    RoyalReserve = 2
    GrandMarket = 3
    Castle = 4
    Guild = 5
    OfficerAcademy = 6
    Granary = 7
    Housing = 8
    Amphitheater = 9
    ArcherTower = 10
    School = 11
    MageTower = 12
    TradeOffice = 13
    Architect = 14
    ParadeGrounds = 15
    Barracks = 16
    Dock = 17
    Fishmonger = 18
    Farms = 19
    Hamlet = 20


BUILDING_COSTS = {
    BuildingId.Fairgrounds: CostWithLords(
        6,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Stone,
                ResourceIds.Silver,
                ResourceIds.AlchemicalSilver,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([40, 50, 40, 90, 8, 1, 1]),
        50,
    ),
    BuildingId.RoyalReserve: CostWithLords(
        6,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Stone,
                ResourceIds.Ironwood,
                ResourceIds.TrueIce,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([50, 20, 50, 10, 1, 1]),
        50,
    ),
    BuildingId.GrandMarket: CostWithLords(
        6,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Stone,
                ResourceIds.Gold,
                ResourceIds.TwilightQuartz,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([35, 40, 20, 10, 1, 1]),
        50,
    ),
    BuildingId.Castle: CostWithLords(
        6,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Stone,
                ResourceIds.Copper,
                ResourceIds.Adamantine,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([30, 50, 100, 4, 1, 1]),
        50,
    ),
    BuildingId.Guild: CostWithLords(
        6,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Stone,
                ResourceIds.Coal,
                ResourceIds.EtherealSilica,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([50, 50, 120, 12, 2, 1]),
        50,
    ),
    BuildingId.OfficerAcademy: CostWithLords(
        6,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Stone,
                ResourceIds.ColdIron,
                ResourceIds.Ignium,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([40, 20, 45, 12, 1, 1]),
        50,
    ),
    BuildingId.Granary: CostWithLords(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Obsidian, ResourceIds.EtherealSilica, ResourceIds.TrueIce]),
        pack_values([10, 10, 4, 4]),
        15,
    ),
    BuildingId.Housing: CostWithLords(
        4,
        8,
        pack_values([ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Copper, ResourceIds.Ironwood]),
        pack_values([50, 120, 120, 70]),
        35,
    ),
    BuildingId.Amphitheater: CostWithLords(
        4,
        8,
        pack_values([ResourceIds.Stone, ResourceIds.Diamonds, ResourceIds.Sapphire, ResourceIds.TwilightQuartz]),
        pack_values([5, 5, 1, 2]),
        10,
    ),
    BuildingId.ArcherTower: CostWithLords(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Obsidian, ResourceIds.Ironwood]),
        pack_values([10, 10, 25, 5]),
        5,
    ),
    BuildingId.School: CostWithLords(
        4,
        8,
        pack_values([ResourceIds.Stone, ResourceIds.Diamonds, ResourceIds.DeepCrystal, ResourceIds.AlchemicalSilver]),
        pack_values([10, 4, 3, 3]),
        15,
    ),
    BuildingId.MageTower: CostWithLords(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Diamonds, ResourceIds.Ignium]),
        pack_values([2, 2, 4, 1]),
        5,
    ),
    BuildingId.TradeOffice: CostWithLords(
        4,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Stone,
                ResourceIds.Gold,
                ResourceIds.Sapphire,
            ]
        ),
        pack_values([10, 4, 15, 10]),
        15,
    ),
    # BuildingId.ExplorersGuild: CostWithLords(
    #     7,
    #     8,
    #     pack_values(
    #         [
    #             ResourceIds.Wood,
    #             ResourceIds.Coal,
    #             ResourceIds.Copper,
    #             ResourceIds.Gold,
    #             ResourceIds.Hartwood,
    #             ResourceIds.AlchemicalSilver,
    #             ResourceIds.Dragonhide,
    #         ]
    #     ),
    #     pack_values([70, 110, 110, 100, 100, 10, 1]),
    #     10
    # ),
    BuildingId.ParadeGrounds: CostWithLords(
        4,
        8,
        pack_values([ResourceIds.Stone, ResourceIds.Sapphire, ResourceIds.Ignium, ResourceIds.Adamantine]),
        pack_values([10, 4, 4, 1]),
        15,
    ),
    # BuildingId.ResourceFacility: CostWithLords(
    #     9,
    #     8,
    #     pack_values(
    #         [
    #             ResourceIds.Wood,
    #             ResourceIds.Silver,
    #             ResourceIds.ColdIron,
    #             ResourceIds.Gold,
    #             ResourceIds.Diamonds,
    #             ResourceIds.Sapphire,
    #             ResourceIds.Ruby,
    #             ResourceIds.Mithral,
    #             ResourceIds.Dragonhide,
    #         ]
    #     ),
    #     pack_values([120, 100, 100, 100, 20, 20, 20, 10, 1]),
    #     10
    # ),
    BuildingId.Dock: CostWithLords(
        3, 8, pack_values([ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Ruby]), pack_values([2, 15, 4]), 5
    ),
    BuildingId.Fishmonger: CostWithLords(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Obsidian, ResourceIds.Silver, ResourceIds.ColdIron]),
        pack_values([30, 55, 6, 5]),
        10,
    ),
    BuildingId.Farms: CostWithLords(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Copper, ResourceIds.Silver, ResourceIds.Hartwood]),
        pack_values([20, 5, 30, 10]),
        10,
    ),
    BuildingId.Hamlet: CostWithLords(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.ColdIron, ResourceIds.Gold, ResourceIds.Ruby]),
        pack_values([25, 20, 20, 10]),
        20,
    ),
}

RESOURCE_UPGRADE_COST = {
    ResourceIds.Wood: Cost(
        5,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Copper, ResourceIds.Obsidian]),
        pack_values([20, 20, 20, 20, 20]),
    ),
    ResourceIds.Stone: Cost(
        5,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Copper, ResourceIds.Obsidian]),
        pack_values([20, 20, 20, 20, 20]),
    ),
    ResourceIds.Coal: Cost(
        5,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Copper, ResourceIds.Obsidian]),
        pack_values([20, 20, 20, 20, 20]),
    ),
    ResourceIds.Copper: Cost(
        5,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Copper, ResourceIds.Obsidian]),
        pack_values([20, 20, 20, 20, 20]),
    ),
}

TROOP_COSTS = {
    TroopId.Skirmisher: Cost(
        1,
        8,
        pack_values([ResourceIds.AlchemicalSilver]),
        pack_values([1]),
    ),
    TroopId.Longbow: Cost(
        1,
        8,
        pack_values([ResourceIds.Adamantine]),
        pack_values([1]),
    ),
    TroopId.Crossbow: Cost(
        4,
        8,
        pack_values([ResourceIds.Stone, ResourceIds.Gold, ResourceIds.Mithral, ResourceIds.Dragonhide]),
        pack_values([20, 5, 1, 1]),
    ),
    TroopId.Pikeman: Cost(
        1,
        8,
        pack_values([ResourceIds.Diamonds]),
        pack_values([1]),
    ),
    TroopId.Knight: Cost(
        1,
        8,
        pack_values([ResourceIds.Sapphire]),
        pack_values([4]),
    ),
    TroopId.Paladin: Cost(
        4,
        8,
        pack_values([ResourceIds.ColdIron, ResourceIds.Diamonds, ResourceIds.Ruby, ResourceIds.DeepCrystal]),
        pack_values([20, 2, 5, 7]),
    ),
    TroopId.Ballista: Cost(
        2,
        8,
        pack_values([ResourceIds.Stone, ResourceIds.Coal]),
        pack_values([8, 8]),
    ),
    TroopId.Mangonel: Cost(
        3,
        8,
        pack_values([ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Silver]),
        pack_values([10, 10, 20]),
    ),
    TroopId.Trebuchet: Cost(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Copper, ResourceIds.Obsidian, ResourceIds.Ironwood]),
        pack_values([50, 40, 40, 43]),
    ),
    TroopId.Apprentice: Cost(
        1,
        8,
        pack_values([ResourceIds.Ignium]),
        pack_values([1]),
    ),
    TroopId.Mage: Cost(
        1,
        8,
        pack_values([ResourceIds.EtherealSilica]),
        pack_values([3]),
    ),
    TroopId.Arcanist: Cost(
        5,
        8,
        pack_values(
            [ResourceIds.Wood, ResourceIds.Gold, ResourceIds.Hartwood, ResourceIds.TrueIce, ResourceIds.TwilightQuartz]
        ),
        pack_values([50, 6, 12, 3, 2]),
    ),
}
