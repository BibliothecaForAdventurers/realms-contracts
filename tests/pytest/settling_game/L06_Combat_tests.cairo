%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.L06_Combat import (
    run_combat_loop,
    attack,
    compute_min_roll_to_hit,
    load_troop_costs,
)
from contracts.settling_game.utils.game_structs import Troop, Squad, Cost

@view
func test_run_combat_loop{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    attacker : Squad, defender : Squad, attack_type : felt
) -> (attacker : Squad, defender : Squad, outcome : felt):
    let (a, d, o) = run_combat_loop(Uint256(1, 0), Uint256(2, 0), attacker, defender, attack_type)
    return (a, d, o)
end

@view
func test_attack{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    a : Squad, d : Squad, attack_type : felt
) -> (d_after_attack : Squad):
    let (d_after_attack) = attack(Uint256(1, 0), Uint256(2, 0), a, d, attack_type)
    return (d_after_attack)
end

@view
func test_compute_min_roll_to_hit{range_check_ptr}(a : felt, d : felt) -> (min_roll : felt):
    let (r) = compute_min_roll_to_hit(a, d)
    return (r)
end

@view
func test_load_troop_costs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    troop_ids_len : felt, troop_ids : felt*
) -> (costs_len : felt, costs : Cost*):
    alloc_locals

    let (costs : Cost*) = alloc()
    load_troop_costs(troop_ids_len, troop_ids, 0, costs)

    return (troop_ids_len, costs)
end
