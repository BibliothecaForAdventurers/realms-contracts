import math
import struct

import pytest
from starkware.starkware_utils.error_handling import StarkException

from .game_structs import Troop, Squad, BuildingId, ResourceIds, TroopId, TroopType, TROOP_COSTS

EMPTY_TROOP = Troop(0, 0, 0, 0, 0, 0, 0, 0, 0)
SKIRMISHER = Troop(TroopId.Skirmisher, TroopType.RangedNormal, 1, BuildingId.ArcherTower, 2, 7, 2, 53, 2)
LONGBOW = Troop(TroopId.Longbow, TroopType.RangedNormal, 2, BuildingId.ArcherTower, 4, 7, 3, 53, 3)
CROSSBOW = Troop(TroopId.Crossbow, TroopType.RangedNormal, 3, BuildingId.ArcherTower, 6, 9, 4, 53, 4)
PIKEMAN = Troop(TroopId.Pikeman, TroopType.Melee, 1, BuildingId.Barracks, 7, 4, 5, 53, 1)
KNIGHT = Troop(TroopId.Knight, TroopType.Melee, 2, BuildingId.Barracks, 9, 7, 8, 79, 2)
PALADIN = Troop(TroopId.Paladin, TroopType.Melee, 3, BuildingId.Barracks, 9, 9, 9, 106, 3)
BALLISTA = Troop(TroopId.Ballista, TroopType.Siege, 1, BuildingId.Castle, 4, 11, 4, 53, 2)
MANGONEL = Troop(TroopId.Mangonel, TroopType.Siege, 2, BuildingId.Castle, 4, 10, 5, 53, 3)
TREBUCHET = Troop(TroopId.Trebuchet, TroopType.Siege, 3, BuildingId.Castle, 4, 12, 6, 53, 4)
APPRENTICE = Troop(TroopId.Apprentice, TroopType.RangedMagic, 1, BuildingId.MageTower, 7, 7, 2, 53, 8)
MAGE = Troop(TroopId.Mage, TroopType.RangedMagic, 2, BuildingId.MageTower, 7, 9, 2, 53, 9)
ARCANIST = Troop(TroopId.Arcanist, TroopType.RangedMagic, 3, BuildingId.MageTower, 7, 11, 2, 53, 10)


TROOPS = [
    SKIRMISHER,
    LONGBOW,
    CROSSBOW,
    PIKEMAN,
    KNIGHT,
    PALADIN,
    BALLISTA,
    MANGONEL,
    TREBUCHET,
    APPRENTICE,
    MAGE,
    ARCANIST,
]


def build_default_squad() -> Squad:
    troops = [PIKEMAN] * 9 + [KNIGHT] * 5 + [PALADIN]
    return Squad(*troops)


def build_partial_squad(first_empty_slot: int) -> Squad:
    troops = [PIKEMAN] * 9 + [KNIGHT] * 5 + [PALADIN]
    empties = [EMPTY_TROOP] * (15 - first_empty_slot)
    squad = Squad(*(troops[:first_empty_slot] + empties))
    return squad


def build_empty_squad() -> Squad:
    no_troops = [EMPTY_TROOP] * 15
    return Squad(*no_troops)


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


def pack_troop(troop: Troop) -> int:
    return int.from_bytes(struct.pack("<2b", *[troop.id, troop.vitality]), "little")


def assert_equal_troops(trooplike1, trooplike2):
    # python-built squads have TroopId enum values as
    # troop.id whereas squads returned from Cairo have
    # only integer values in their place; this makes
    # sure we're always comparing only int values
    assert int(trooplike1.id) == int(trooplike2.id)
    assert trooplike1[1:] == trooplike2[1:]


def assert_equal_squads(squadlike1, squadlike2):
    assert len(squadlike1) == len(squadlike2)
    for i in range(len(squadlike1)):
        assert_equal_troops(squadlike1[i], squadlike2[i])


@pytest.mark.asyncio
async def test_run_combat_loop(l06_combat_tests):
    attacker = build_default_squad()
    defender = build_partial_squad(7)

    tx = await l06_combat_tests.test_run_combat_loop(attacker, defender, 1).invoke()

    res = tx.result
    assert len(res) == 3
    assert res.outcome == 1  # attacker wins, most likely outcome since defender is weak


@pytest.mark.asyncio
async def test_attack(l06_combat_tests):
    attack_vs_defense = 1
    wisdom_vs_agility = 2
    for attack_type in [attack_vs_defense, wisdom_vs_agility]:
        a = build_default_squad()
        d = build_default_squad()
        tx = await l06_combat_tests.test_attack(a, d, attack_type).invoke()

        # assuming at least one hit
        assert tx.result.d_after_attack.t1_1.vitality < d.t1_1.vitality


@pytest.mark.asyncio
async def test_compute_min_roll_to_hit(l06_combat_tests):
    # NOTE: takes about 3 mins to go through the whole combo
    for a in range(20, 120):
        for d in range(20, 120):
            exp = min(math.ceil((a / d) * 7), 12)
            tx = await l06_combat_tests.test_compute_min_roll_to_hit(a, d).invoke()
            res = tx.result.min_roll
            assert exp == res

    # test when there's no defence
    tx = await l06_combat_tests.test_compute_min_roll_to_hit(40, 0).invoke()
    assert tx.result.min_roll == 0


@pytest.mark.asyncio
async def test_update_squad_in_realm(s06_combat):
    realm_id = (1, 0)
    packed_empty_squad = 0
    default_squad = build_default_squad()
    packed_default_squad = pack_squad(default_squad)

    tx = await s06_combat.get_realm_combat_data(realm_id).invoke()

    assert tx.result.combat_data.attacking_squad == packed_empty_squad
    assert tx.result.combat_data.defending_squad == packed_empty_squad

    # set attack slot
    await s06_combat.update_squad_in_realm(default_squad, realm_id, 1).invoke()

    tx = await s06_combat.get_realm_combat_data(realm_id).invoke()
    assert tx.result.combat_data.attacking_squad == packed_default_squad
    assert tx.result.combat_data.defending_squad == packed_empty_squad

    # set defend slot
    await s06_combat.update_squad_in_realm(default_squad, realm_id, 2).invoke()

    tx = await s06_combat.get_realm_combat_data(realm_id).invoke()
    assert tx.result.combat_data.attacking_squad == packed_default_squad
    assert tx.result.combat_data.defending_squad == packed_default_squad

    # try setting wrong slot, noop
    await s06_combat.update_squad_in_realm(default_squad, realm_id, 9).invoke()

    tx = await s06_combat.get_realm_combat_data(realm_id).invoke()
    assert tx.result.combat_data.attacking_squad == packed_default_squad
    assert tx.result.combat_data.defending_squad == packed_default_squad


@pytest.mark.asyncio
async def test_get_set_troop_cost(s06_combat):
    for troop_id, troop_cost in TROOP_COSTS.items():
        await s06_combat.set_troop_cost(troop_id, troop_cost).invoke()
        tx = await s06_combat.get_troop_cost(troop_id).invoke()
        assert tx.result.cost == troop_cost


# even though this tests a func in utils, it is
# kept here because of easy access to TROOP_COST
# as a side-effect, testing this function also asserts the correctness
# of load_resource_ids_and_values_from_cost, convert_cost_dict_to_tokens_and_values
# and sum_values_by_key in general.cairo file, as it calls them all
@pytest.mark.asyncio
async def test_transform_costs_to_token_ids_values(utils_general_tests):
    costs = [TROOP_COSTS[TroopId.Watchman], TROOP_COSTS[TroopId.Guard]]
    tx = await utils_general_tests.test_transform_costs_to_token_ids_values(costs).invoke()

    expected_ids = [
        ResourceIds.Wood,
        ResourceIds.Stone,
        ResourceIds.Copper,
    ]
    expected_values = [6, 9, 15]

    assert tx.result.ids == [utils_general_tests.Uint256(low=v, high=0) for v in expected_ids]
    assert tx.result.values == [utils_general_tests.Uint256(low=v, high=0) for v in expected_values]


@pytest.mark.asyncio
async def test_load_troop_costs(l06_combat_tests):
    troops = [TroopId.Watchman, TroopId.Guard, TroopId.Scorpio]

    # set_troop_cost is automatically imported/exposed in the contract
    # due to the way how the compiler works, so we can call it directly
    for troop_id in troops:
        await l06_combat_tests.set_troop_cost(troop_id, TROOP_COSTS[troop_id]).invoke()
    tx = await l06_combat_tests.test_load_troop_costs(troops).invoke()

    assert len(tx.result.costs) == len(troops)
    for idx, troop_id in enumerate(troops):
        assert tx.result.costs[idx] == TROOP_COSTS[troop_id]
