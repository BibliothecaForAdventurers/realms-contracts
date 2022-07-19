%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from contracts.settling_game.utils.game_structs import Cost, Squad

const MODULE_CONTROLLER_ADDR = 120325194214501
const FAKE_OWNER_ADDR = 20

# custom interface with only the funcs used in the tests
@contract_interface
namespace IL06:
    func initializer(controller_addr, xoroshiro_addr, proxy_admin):
    end

    func set_troop_cost(troop_id, cost : Cost):
    end

    func build_squad_from_troops_in_realm(
        troop_ids_len, troop_ids : felt*, realm_id : Uint256, slot
    ):
    end

    func view_troops(realm_id : Uint256) -> (attacking_troops : Squad, defending_troops : Squad):
    end
end

@external
func __setup__{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local xoroshiro_address
    local L06_Combat_address
    %{
        context.xoroshiro_address = deploy_contract("./contracts/utils/xoroshiro128_starstar.cairo", [921374095]).contract_address
        ids.xoroshiro_address = context.xoroshiro_address
        context.L06_Combat_address = deploy_contract("./contracts/settling_game/L06_Combat.cairo", []).contract_address
        ids.L06_Combat_address = context.L06_Combat_address
    %}
    IL06.initializer(L06_Combat_address, MODULE_CONTROLLER_ADDR, xoroshiro_address, 1)

    return ()
end

@external
func test_build_squad{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (troop_ids : felt*) = alloc()
    let (troop_ids_2 : felt*) = alloc()

    assert troop_ids[0] = 1
    assert troop_ids_2[0] = 1
    assert troop_ids_2[1] = 2

    local L06_Combat : felt
    %{ ids.L06_Combat = context.L06_Combat_address %}
    IL06.set_troop_cost(L06_Combat, 1, Cost(3, 8, 262657, 328450))
    IL06.set_troop_cost(L06_Combat, 2, Cost(3, 8, 262657, 656900))

    %{
        # this block ensures that the IERC721.ownerOf returns the same value
        # as is returned by get_caller_address inside the ERC721_owner_check,
        # which guarantees teh `assert caller = owner` check passes
        fake_addr = 721_1155
        start_prank(ids.FAKE_OWNER_ADDR, context.L06_Combat_address)
        mock_call(ids.MODULE_CONTROLLER_ADDR, "get_external_contract_address", [fake_addr])
        mock_call(fake_addr, "ownerOf", [ids.FAKE_OWNER_ADDR])

        # now that we faked our way around the ownerOf, we also mock
        # the call to IERC1155.burnBatch
        mock_call(fake_addr, "burnBatch", [])
    %}

    IL06.build_squad_from_troops_in_realm(L06_Combat, 1, troop_ids, Uint256(1, 0), 1)
    IL06.build_squad_from_troops_in_realm(L06_Combat, 2, troop_ids_2, Uint256(1, 0), 1)

    let (attacking_s : Squad, defending_s : Squad) = IL06.view_troops(L06_Combat, Uint256(1, 0))
    #let a = cast(&attacking_s, felt*)

    %{
        print(ids.attacking_s)
        print(ids.attacking_s.t1_1.vitality)
    %}

    return ()
end

# TODO:
# test_run_combat_loop
# test_attack
# test_compute_min_roll_to_hit
# test_update_squad_in_realm
# test_get_set_troop_costs
