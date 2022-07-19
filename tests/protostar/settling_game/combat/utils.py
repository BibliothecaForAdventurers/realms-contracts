from collections import namedtuple
from enum import IntEnum

import struct


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


Troop = namedtuple('Troop', 'id type tier building agility attack armor vitality wisdom')
Squad = namedtuple(
    'Squad',
    't1_1 t1_2 t1_3 t1_4 t1_5 t1_6 t1_7 t1_8 t1_9 t2_1 t2_2 t2_3 t2_4 t2_5 t3_1',
)

EMPTY_TROOP = Troop(0, 0, 0, 0, 0, 0, 0, 0, 0)
SKIRMISHER = Troop(TroopId.Skirmisher.value, TroopType.RangedNormal.value, 1, 8, 2, 7, 2, 53, 2)
LONGBOW = Troop(TroopId.Longbow.value, TroopType.RangedNormal.value, 2, 8, 4, 7, 3, 53, 3)
CROSSBOW = Troop(TroopId.Crossbow.value, TroopType.RangedNormal.value, 3, 8, 6, 9, 4, 53, 4)


def build_default_squad() -> Squad:
    troops = [SKIRMISHER] * 9 + [LONGBOW] * 5 + [CROSSBOW]
    return Squad(*troops)


def build_partial_squad() -> Squad:
    troops = [SKIRMISHER] * 5 + [EMPTY_TROOP] * 4 + [LONGBOW] * 3 + [EMPTY_TROOP] * 2 + [CROSSBOW]
    return Squad(*troops)


def pack_troop(t: Troop):
    return int.from_bytes(struct.pack("<2b", *[t.id, t.vitality]), "little")


def pack_squad(squad: Squad) -> int:
    shift = 0x100
    packed = (
        pack_troop(squad.t1_1)
        + pack_troop(squad.t1_2) * shift**2
        + pack_troop(squad.t1_3) * shift**4
        + pack_troop(squad.t1_4) * shift**6
        + pack_troop(squad.t1_5) * shift**8
        + pack_troop(squad.t1_6) * shift**10
        + pack_troop(squad.t1_7) * shift**12
        + pack_troop(squad.t1_8) * shift**14
        + pack_troop(squad.t1_9) * shift**16
        + pack_troop(squad.t2_1) * shift**18
        + pack_troop(squad.t2_2) * shift**20
        + pack_troop(squad.t2_3) * shift**22
        + pack_troop(squad.t2_4) * shift**24
        + pack_troop(squad.t2_5) * shift**26
        + pack_troop(squad.t3_1) * shift**28
    )
    return packed


def assign_default_squad(squad_segment, segments):
    troops = [SKIRMISHER] * 9 + [LONGBOW] * 5 + [CROSSBOW]
    for sidx, squad_troop_field in enumerate(Squad._fields):
        troop = troops[sidx]
        # troop_segment = segments.add_temp_segment()
        # assign_troop_to_segment(troop_segment, troop)
        troop_segment = segments.gen_arg(troop)
        setattr(squad_segment, squad_troop_field, troop_segment)
        # for tidx, troop_member_field in enumerate(Troop._fields):
        #     setattr(squad_segment, f"{squad_troop_field}.{troop_member_field}", troop[tidx])


def assign_troop_to_segment(troop_segment, troop):
    for idx, field in enumerate(Troop._fields):
        setattr(troop_segment, field, troop[idx])
