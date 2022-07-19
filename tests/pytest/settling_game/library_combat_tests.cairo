%lang starknet

from contracts.settling_game.utils.game_structs import Squad, PackedSquad, SquadStats, Troop
from contracts.settling_game.library.library_combat import Combat

@view
func test_add_troop_to_squad(t : Troop, s : Squad) -> (updated : Squad):
    let (updated) = Combat.add_troop_to_squad(t, s)
    return (updated)
end

@view
func test_remove_troop_from_squad{range_check_ptr}(troop_idx : felt, s : Squad) -> (
    updated : Squad
):
    let (updated) = Combat.remove_troop_from_squad(troop_idx, s)
    return (updated)
end

@view
func test_compute_squad_stats(s : Squad) -> (stats : SquadStats):
    let (stats) = Combat.compute_squad_stats(s)
    return (stats)
end

@view
func test_compute_squad_vitality(s : Squad) -> (vitality : felt):
    let (vitality) = Combat.compute_squad_vitality(s)
    return (vitality)
end

@view
func test_pack_troop{range_check_ptr}(t : Troop) -> (packed : felt):
    let (p) = Combat.pack_troop(t)
    return (p)
end

@view
func test_unpack_troop{range_check_ptr}(packed : felt) -> (t : Troop):
    let (t) = Combat.unpack_troop(packed)
    return (t)
end

@view
func test_pack_squad{range_check_ptr}(s : Squad) -> (p : PackedSquad):
    let (p) = Combat.pack_squad(s)
    return (p)
end

@view
func test_unpack_squad{range_check_ptr}(p : PackedSquad) -> (s : Squad):
    let (s : Squad) = Combat.unpack_squad(p)
    return (s)
end

@view
func test_find_first_free_troop_slot_in_squad(s : Squad, tier : felt) -> (free_slot_index : felt):
    let (idx) = Combat.find_first_free_troop_slot_in_squad(s, tier)
    return (idx)
end

@view
func test_add_troops_to_squad{range_check_ptr}(
    s : Squad, troop_ids_len : felt, troop_ids : felt*
) -> (squad : Squad):
    let (s : Squad) = Combat.add_troops_to_squad(s, troop_ids_len, troop_ids)
    return (s)
end

@view
func test_remove_troops_from_squad{range_check_ptr}(
    s : Squad, troop_idxs_len : felt, troop_idxs : felt*
) -> (squad : Squad):
    let (s : Squad) = Combat.remove_troops_from_squad(s, troop_idxs_len, troop_idxs)
    return (s)
end

@view
func test_get_troop_population{range_check_ptr}(squad : PackedSquad) -> (population : felt):
    alloc_locals
    let (population) = Combat.get_troop_population(squad)

    return (population)
end
