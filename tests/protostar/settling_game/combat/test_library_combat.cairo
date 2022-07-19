%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc

from contracts.settling_game.library.library_combat import Combat
from contracts.settling_game.utils.game_structs import (
    RealmBuildingsIds,
    Troop,
    TroopId,
    TroopType,
    Squad,
    SquadStats,
)

from protostar.asserts import assert_eq

@external
func __setup__():
    %{
        import os, sys
        sys.path.append(os.path.abspath(os.path.dirname(".")))
    %}

    return ()
end

@external
func test_get_troop_properties{range_check_ptr}():
    alloc_locals

    let (skirmisher : Troop) = build_troop(TroopId.Skirmisher)
    let expected = Troop(
        TroopId.Skirmisher, TroopType.RangedNormal, 1, RealmBuildingsIds.ArcherTower, 2, 7, 2, 53, 2
    )
    assert_troop_eq(skirmisher, expected)

    let (longbow : Troop) = build_troop(TroopId.Longbow)
    let expected = Troop(
        TroopId.Longbow, TroopType.RangedNormal, 2, RealmBuildingsIds.ArcherTower, 4, 7, 3, 53, 3
    )
    assert_troop_eq(longbow, expected)

    let (crossbow : Troop) = build_troop(TroopId.Crossbow)
    let expected = Troop(
        TroopId.Crossbow, TroopType.RangedNormal, 3, RealmBuildingsIds.ArcherTower, 6, 9, 4, 53, 4
    )
    assert_troop_eq(crossbow, expected)

    let (pikeman : Troop) = build_troop(TroopId.Pikeman)
    let expected = Troop(
        TroopId.Pikeman, TroopType.Melee, 1, RealmBuildingsIds.Barracks, 7, 4, 5, 53, 1
    )
    assert_troop_eq(pikeman, expected)

    let (knight : Troop) = build_troop(TroopId.Knight)
    let expected = Troop(
        TroopId.Knight, TroopType.Melee, 2, RealmBuildingsIds.Barracks, 9, 7, 8, 79, 2
    )
    assert_troop_eq(knight, expected)

    let (paladin : Troop) = build_troop(TroopId.Paladin)
    let expected = Troop(
        TroopId.Paladin, TroopType.Melee, 3, RealmBuildingsIds.Barracks, 9, 9, 9, 106, 3
    )
    assert_troop_eq(paladin, expected)

    let (ballista : Troop) = build_troop(TroopId.Ballista)
    let expected = Troop(
        TroopId.Ballista, TroopType.Siege, 1, RealmBuildingsIds.Castle, 4, 11, 4, 53, 2
    )
    assert_troop_eq(ballista, expected)

    let (mangonel : Troop) = build_troop(TroopId.Mangonel)
    let expected = Troop(
        TroopId.Mangonel, TroopType.Siege, 2, RealmBuildingsIds.Castle, 4, 10, 5, 53, 3
    )
    assert_troop_eq(mangonel, expected)

    let (trebuchet : Troop) = build_troop(TroopId.Trebuchet)
    let expected = Troop(
        TroopId.Trebuchet, TroopType.Siege, 3, RealmBuildingsIds.Castle, 4, 12, 6, 53, 4
    )
    assert_troop_eq(trebuchet, expected)

    let (apprentice : Troop) = build_troop(TroopId.Apprentice)
    let expected = Troop(
        TroopId.Apprentice, TroopType.RangedMagic, 1, RealmBuildingsIds.MageTower, 7, 7, 2, 53, 8
    )
    assert_troop_eq(apprentice, expected)

    let (mage : Troop) = build_troop(TroopId.Mage)
    let expected = Troop(
        TroopId.Mage, TroopType.RangedMagic, 2, RealmBuildingsIds.MageTower, 7, 9, 2, 53, 9
    )
    assert_troop_eq(mage, expected)

    let (arcanist : Troop) = build_troop(TroopId.Arcanist)
    let expected = Troop(
        TroopId.Arcanist, TroopType.RangedMagic, 3, RealmBuildingsIds.MageTower, 7, 11, 2, 53, 10
    )
    assert_troop_eq(arcanist, expected)

    return ()
end

@external
func test_get_troop_properties_reverts_id_zero{range_check_ptr}():
    %{ expect_revert() %}
    Combat.get_troop_properties(0)
    return ()
end

@external
func test_get_troop_properties_reverts_id_too_large{range_check_ptr}():
    %{ expect_revert() %}
    Combat.get_troop_properties(TroopId.SIZE)
    return ()
end

@external
func test_pack_troop{range_check_ptr}():
    alloc_locals

    let (crossbow : Troop) = build_troop(TroopId.Crossbow)
    let (packed) = Combat.pack_troop(crossbow)
    local expected_packed
    %{
        from tests.protostar.settling_game.combat.utils import pack_troop, CROSSBOW
        ids.expected_packed = pack_troop(CROSSBOW)
    %}
    assert_eq(packed, expected_packed)

    let injured_pikeman : Troop = Troop(TroopId.Pikeman, 0, 0, 0, 0, 0, 0, 20, 0)
    let (packed_injured) = Combat.pack_troop(injured_pikeman)
    local expected_packed_injured
    %{
        from tests.protostar.settling_game.combat.utils import Troop, TroopId
        injured = Troop(TroopId.Pikeman.value, 0, 0, 0, 0, 0, 0, 20, 0)
        ids.expected_packed_injured = pack_troop(injured)
    %}
    assert_eq(packed_injured, expected_packed_injured)

    let (empty : Troop) = build_empty_troop()
    let (packed_empty) = Combat.pack_troop(empty)
    assert_eq(packed_empty, 0)

    return ()
end

@external
func test_pack_troop_reverts_id_too_large{range_check_ptr}():
    %{ expect_revert() %}
    tempvar invalid = new Troop(TroopId.SIZE, 0, 0, 0, 0, 0, 0, 200, 0)
    Combat.pack_troop([invalid])
    return ()
end

@external
func test_pack_troop_reverts_vitality_too_large{range_check_ptr}():
    %{ expect_revert() %}
    tempvar invalid = new Troop(TroopId.Mage, 0, 0, 0, 0, 0, 0, 300, 0)
    Combat.pack_troop([invalid])
    return ()
end

@external
func test_unpack_troop{range_check_ptr}():
    alloc_locals

    unpack_packed_all_loop(TroopId.SIZE - 1)

    let packed_skirmisher_20 = 5121  # TroopId.Skirmisher w/ vitality 20
    let (unpacked : Troop) = Combat.unpack_troop(packed_skirmisher_20)
    tempvar expected = Troop(TroopId.Skirmisher, TroopType.RangedNormal, 1, RealmBuildingsIds.ArcherTower, 2, 7, 2, 20, 2)
    assert_troop_eq(unpacked, expected)

    let packed_empty = 0
    let (unpacked : Troop) = Combat.unpack_troop(packed_empty)
    let (expected : Troop) = build_empty_troop()
    assert_troop_eq(unpacked, expected)

    return ()
end

func unpack_packed_all_loop{range_check_ptr}(troop_id : felt):
    alloc_locals

    if troop_id == 0:
        return ()
    end

    let (t : Troop) = build_troop(troop_id)
    let (packed) = Combat.pack_troop(t)
    let (unpacked) = Combat.unpack_troop(packed)
    assert_troop_eq(unpacked, t)

    return unpack_packed_all_loop(troop_id - 1)
end

@external
func test_pack_squad{range_check_ptr}():
    alloc_locals
    local expected_packed_full
    local expected_packed_partial

    %{
        from tests.protostar.settling_game.combat import utils
        ids.expected_packed_full = utils.pack_squad(utils.build_default_squad())
        ids.expected_packed_partial = utils.pack_squad(utils.build_partial_squad())
    %}

    let (full : Squad) = build_default_squad()
    let (partial : Squad) = build_partial_squad()
    let (packed_full) = Combat.pack_squad(full)
    let (packed_partial) = Combat.pack_squad(partial)

    assert_eq(packed_full, expected_packed_full)
    assert_eq(packed_partial, expected_packed_partial)

    return ()
end

@external
func test_unpack_squad{range_check_ptr}():
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()

    let full : Squad = build_default_squad()
    let partial : Squad = build_partial_squad()
    let (packed_full) = Combat.pack_squad(full)
    let (packed_partial) = Combat.pack_squad(partial)
    let (unpacked_full : Squad) = Combat.unpack_squad(packed_full)
    let (unpacked_partial : Squad) = Combat.unpack_squad(packed_partial)

    assert_arrays_eq(&full, &unpacked_full, Squad.SIZE)
    assert_arrays_eq(&partial, &unpacked_partial, Squad.SIZE)

    return ()
end

@external
func test_compute_squad_stats{range_check_ptr}():
    alloc_locals

    let squad : Squad = build_default_squad()
    let stats : SquadStats = Combat.compute_squad_stats(squad)

    assert_eq(stats.agility, 44)
    assert_eq(stats.attack, 107)
    assert_eq(stats.armor, 37)
    assert_eq(stats.vitality, 795)
    assert_eq(stats.wisdom, 37)

    let squad : Squad = build_partial_squad()
    let stats : SquadStats = Combat.compute_squad_stats(squad)

    assert_eq(stats.agility, 28)
    assert_eq(stats.attack, 65)
    assert_eq(stats.armor, 23)
    assert_eq(stats.vitality, 477)
    assert_eq(stats.wisdom, 23)

    return ()
end

@external
func test_compute_squad_vitality{range_check_ptr}():
    alloc_locals

    let full : Squad = build_default_squad()
    let partial : Squad = build_partial_squad()
    let (full_vitality) = Combat.compute_squad_vitality(full)
    let (partial_vitality) = Combat.compute_squad_vitality(partial)

    assert_eq(full_vitality, 795)
    assert_eq(partial_vitality, 477)

    return ()
end

@external
func test_get_troop_population{range_check_ptr}():
    alloc_locals

    let (full : Squad) = build_default_squad()
    let (partial : Squad) = build_partial_squad()
    let (packed_full) = Combat.pack_squad(full)
    let (packed_partial) = Combat.pack_squad(partial)

    let (full_pop) = Combat.get_troop_population(packed_full)
    let (partial_pop) = Combat.get_troop_population(packed_partial)

    assert_eq(full_pop, 15)
    assert_eq(partial_pop, 9)

    return ()
end

@external
func test_hit_squad{range_check_ptr}():
    alloc_locals

    let (full : Squad) = build_default_squad()

    # full kill
    let (hit : Squad) = Combat.hit_squad(full, 15 * 53 + 1)
    let (vitality) = Combat.compute_squad_vitality(hit)
    assert_eq(vitality, 0)

    # partial kill
    let (hit : Squad) = Combat.hit_squad(full, 8 * 53 + 20)
    let (vitality) = Combat.compute_squad_vitality(hit)
    assert_eq(vitality, (15 * 53) - (8 * 53 + 20))
    assert_eq(hit.t1_9.vitality, 53 - 20)
    assert_eq(hit.t2_1.vitality, 53)

    # partial kill of partial squad
    let (partial : Squad) = build_partial_squad()
    let (hit : Squad) = Combat.hit_squad(partial, 6 * 53 + 30)
    let (vitality) = Combat.compute_squad_vitality(hit)
    assert_eq(vitality, (9 * 53) - (6 * 53 + 30))
    assert_eq(hit.t1_5.vitality, 0)
    assert_eq(hit.t2_1.vitality, 0)
    assert_eq(hit.t2_2.vitality, 53 - 30)

    return ()
end

@external
func test_hit_troop{range_check_ptr}():
    alloc_locals

    let (empty : Troop) = build_empty_troop()

    # full kill
    let (skirmisher : Troop) = build_troop(TroopId.Skirmisher)
    let (hit : Troop, remaining : felt) = Combat.hit_troop(skirmisher, 80)
    assert_troop_eq(hit, empty)
    assert_eq(remaining, 80 - skirmisher.vitality)

    # injury
    let (mage : Troop) = build_troop(TroopId.Mage)
    let (hit : Troop, remaining : felt) = Combat.hit_troop(mage, 20)
    let expected = Troop(
        mage.id,
        mage.type,
        mage.tier,
        mage.building,
        mage.agility,
        mage.attack,
        mage.armor,
        mage.vitality - 20,
        mage.wisdom,
    )
    assert_troop_eq(hit, expected)
    assert_eq(remaining, 0)

    # no hit
    let (knight : Troop) = build_troop(TroopId.Knight)
    let (hit : Troop, remaining : felt) = Combat.hit_troop(knight, 0)
    assert_troop_eq(hit, knight)
    assert_eq(remaining, 0)

    return ()
end

@external
func test_add_troops_to_empty_squad{range_check_ptr}():
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()

    let (troops : felt*) = alloc()
    assert troops[0] = TroopId.Skirmisher
    assert troops[1] = TroopId.Skirmisher
    assert troops[2] = TroopId.Skirmisher
    assert troops[3] = TroopId.Skirmisher
    assert troops[4] = TroopId.Skirmisher
    assert troops[5] = TroopId.Skirmisher
    assert troops[6] = TroopId.Skirmisher
    assert troops[7] = TroopId.Skirmisher
    assert troops[8] = TroopId.Skirmisher
    assert troops[9] = TroopId.Longbow
    assert troops[10] = TroopId.Longbow
    assert troops[11] = TroopId.Longbow
    assert troops[12] = TroopId.Longbow
    assert troops[13] = TroopId.Longbow
    assert troops[14] = TroopId.Crossbow

    let (empty : Squad) = build_empty_squad()
    let (built : Squad) = Combat.add_troops_to_squad(empty, 15, troops)
    let (expected : Squad) = build_default_squad()

    # putting the values to be compared into a memory segment
    # so that assert_arrays_eq will work; for some reason,
    # just using &built and &expected doesn't work :shrug:
    let (memory : Squad*) = alloc()
    assert memory[0] = built
    assert memory[1] = expected
    assert_arrays_eq(memory, &(memory[1]), Squad.SIZE)

    return ()
end

@external
func test_add_troops_to_partial_squad{range_check_ptr}():
    alloc_locals

    let (troops : felt*) = alloc()
    assert troops[0] = TroopId.Skirmisher
    assert troops[1] = TroopId.Longbow
    assert troops[2] = TroopId.Longbow
    let (empty_troop : Troop) = build_empty_troop()
    let (partial : Squad) = build_partial_squad()
    let (built : Squad) = Combat.add_troops_to_squad(partial, 3, troops)

    assert_troop_eq(built.t1_5, built.t1_6)
    assert_troop_eq(built.t1_7, empty_troop)
    assert_troop_eq(built.t1_8, empty_troop)
    assert_troop_eq(built.t1_9, empty_troop)
    assert_troop_eq(built.t2_3, built.t2_4)
    assert_troop_eq(built.t2_4, built.t2_5)

    return ()
end

@external
func test_add_troops_to_full_squad_reverts{range_check_ptr}():
    alloc_locals

    let (troops : felt*) = alloc()
    assert troops[0] = TroopId.Skirmisher
    let (full : Squad) = build_default_squad()

    %{ expect_revert() %}
    let (built : Squad) = Combat.add_troops_to_squad(full, 1, troops)

    return ()
end

@external
func test_remove_troops_from_squad{range_check_ptr}():
    alloc_locals

    let (full : Squad) = build_default_squad()
    let (empty : Troop) = build_empty_troop()
    let (memory : Troop*) = alloc()
    assert [memory] = empty

    remove_troops_from_squad_loop(full, memory, 0, Squad.SIZE / Troop.SIZE)

    return ()
end

func remove_troops_from_squad_loop{range_check_ptr}(s : Squad, empty : Troop*, idx, stop_at):
    alloc_locals

    if idx == stop_at:
        return ()
    end

    let (updated : Squad) = Combat.remove_troop_from_squad(idx, s)

    let (memory : Squad*) = alloc()
    assert [memory] = updated
    assert_arrays_eq(memory + idx * Troop.SIZE, empty, Troop.SIZE)

    return remove_troops_from_squad_loop(s, empty, idx + 1, stop_at)
end

@external
func test_remove_troops_from_squad_reverts_idx_too_large{range_check_ptr}():
    alloc_locals

    let (full : Squad) = build_default_squad()
    %{ expect_revert() %}
    let (updated : Squad) = Combat.remove_troop_from_squad(44, full)

    return ()
end

@external
func test_find_first_free_troop_slot_in_squad{range_check_ptr}():
    alloc_locals

    let (partial : Squad) = build_partial_squad()
    let (empty : Squad) = build_empty_squad()
    let (t1_slot) = Combat.find_first_free_troop_slot_in_squad(partial, 1)
    let (t2_slot) = Combat.find_first_free_troop_slot_in_squad(partial, 2)
    let (t3_slot) = Combat.find_first_free_troop_slot_in_squad(empty, 3)

    assert_eq(t1_slot, 5 * Troop.SIZE)
    assert_eq(t2_slot, (9 + 3) * Troop.SIZE)
    assert_eq(t3_slot, (9 + 5) * Troop.SIZE)

    return ()
end

# TODO:
# test_load_troop_costs???
# test_transform_costs_to_token_ids_values???

#
# helper functions
#

func build_troop{range_check_ptr}(troop_id) -> (troop : Troop):
    let (
        type, tier, building, agility, attack, armor, vitality, wisdom
    ) = Combat.get_troop_properties(troop_id)
    return (Troop(troop_id, type, tier, building, agility, attack, armor, vitality, wisdom))
end

func build_empty_troop() -> (troop : Troop):
    return (Troop(0, 0, 0, 0, 0, 0, 0, 0, 0))
end

func build_default_squad{range_check_ptr}() -> (s : Squad):
    let t1_1 : Troop = build_troop(TroopId.Skirmisher)
    let t1_2 : Troop = build_troop(TroopId.Skirmisher)
    let t1_3 : Troop = build_troop(TroopId.Skirmisher)
    let t1_4 : Troop = build_troop(TroopId.Skirmisher)
    let t1_5 : Troop = build_troop(TroopId.Skirmisher)
    let t1_6 : Troop = build_troop(TroopId.Skirmisher)
    let t1_7 : Troop = build_troop(TroopId.Skirmisher)
    let t1_8 : Troop = build_troop(TroopId.Skirmisher)
    let t1_9 : Troop = build_troop(TroopId.Skirmisher)

    let t2_1 : Troop = build_troop(TroopId.Longbow)
    let t2_2 : Troop = build_troop(TroopId.Longbow)
    let t2_3 : Troop = build_troop(TroopId.Longbow)
    let t2_4 : Troop = build_troop(TroopId.Longbow)
    let t2_5 : Troop = build_troop(TroopId.Longbow)

    let t3_1 : Troop = build_troop(TroopId.Crossbow)

    return (
        Squad(
        t1_1, t1_2, t1_3, t1_4, t1_5, t1_6, t1_7,
        t1_8, t1_9, t2_1, t2_2, t2_3, t2_4, t2_5, t3_1),
    )
end

func build_partial_squad{range_check_ptr}() -> (s : Squad):
    let t1_1 : Troop = build_troop(TroopId.Skirmisher)
    let t1_2 : Troop = build_troop(TroopId.Skirmisher)
    let t1_3 : Troop = build_troop(TroopId.Skirmisher)
    let t1_4 : Troop = build_troop(TroopId.Skirmisher)
    let t1_5 : Troop = build_troop(TroopId.Skirmisher)
    let t1_6 : Troop = build_empty_troop()
    let t1_7 : Troop = build_empty_troop()
    let t1_8 : Troop = build_empty_troop()
    let t1_9 : Troop = build_empty_troop()

    let t2_1 : Troop = build_troop(TroopId.Longbow)
    let t2_2 : Troop = build_troop(TroopId.Longbow)
    let t2_3 : Troop = build_troop(TroopId.Longbow)
    let t2_4 : Troop = build_empty_troop()
    let t2_5 : Troop = build_empty_troop()

    let t3_1 : Troop = build_troop(TroopId.Crossbow)

    return (
        Squad(
        t1_1, t1_2, t1_3, t1_4, t1_5, t1_6, t1_7,
        t1_8, t1_9, t2_1, t2_2, t2_3, t2_4, t2_5, t3_1),
    )
end

func build_empty_squad{range_check_ptr}() -> (s : Squad):
    let t1_1 : Troop = build_empty_troop()
    let t1_2 : Troop = build_empty_troop()
    let t1_3 : Troop = build_empty_troop()
    let t1_4 : Troop = build_empty_troop()
    let t1_5 : Troop = build_empty_troop()
    let t1_6 : Troop = build_empty_troop()
    let t1_7 : Troop = build_empty_troop()
    let t1_8 : Troop = build_empty_troop()
    let t1_9 : Troop = build_empty_troop()

    let t2_1 : Troop = build_empty_troop()
    let t2_2 : Troop = build_empty_troop()
    let t2_3 : Troop = build_empty_troop()
    let t2_4 : Troop = build_empty_troop()
    let t2_5 : Troop = build_empty_troop()

    let t3_1 : Troop = build_empty_troop()

    return (
        Squad(
        t1_1, t1_2, t1_3, t1_4, t1_5, t1_6, t1_7,
        t1_8, t1_9, t2_1, t2_2, t2_3, t2_4, t2_5, t3_1),
    )
end

#
# helper asserts
#

func assert_arrays_eq(a1 : felt*, a2 : felt*, size : felt):
    if size == 0:
        return ()
    end
    assert a1[0] = a2[0]
    return assert_arrays_eq(a1 + 1, a2 + 1, size - 1)
end

func assert_troop_eq(t1 : Troop, t2 : Troop):
    assert t1.id = t2.id
    assert t1.type = t2.type
    assert t1.tier = t2.tier
    assert t1.building = t2.building
    assert t1.agility = t2.agility
    assert t1.attack = t2.attack
    assert t1.armor = t2.armor
    assert t1.vitality = t2.vitality
    assert t1.wisdom = t2.wisdom
    return ()
end
