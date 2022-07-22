from collections import namedtuple
from enum import IntEnum
from realms_cli.shared import pack_values

Cost = namedtuple('Cost', 'resource_count bits packed_ids packed_amounts')
CostWithLords = namedtuple(
    'Cost', 'resource_count bits packed_ids packed_amounts lords')
Troop = namedtuple('Troop', 'type tier agility attack defense vitality wisdom')


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
    DesertGlass = 23
    DivineCloth = 24
    CuriousSpore = 25
    UnrefinedOre = 26
    SunkenShekel = 27
    Demonhide = 28


class BuildingId(IntEnum):
    WorkHut = 1
    StoreHouse = 2
    Granary = 3
    Farm = 4
    FishingVillage = 5
    Barracks = 6
    MageTower = 7
    ArcherTower = 8
    Castle = 9


BUILDING_COSTS = {
    BuildingId.WorkHut: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.StoreHouse: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.Granary: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.Farm: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.FishingVillage: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.Barracks: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.MageTower: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.ArcherTower: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.Castle: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    )
}


TROOP_COSTS = {
    TroopId.Skirmisher: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Longbow: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Crossbow: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Pikeman: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Knight: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Paladin: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Ballista: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Mangonel: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Trebuchet: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Apprentice: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Mage: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    ),
    TroopId.Arcanist: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper]),
        pack_values([2, 3, 5]),
    )
}
