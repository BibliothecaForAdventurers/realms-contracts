# -----------------------------------
# ____Module.L02___RELIC
#   Logic around Relics
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from starkware.cairo.common.bool import TRUE
from contracts.settling_game.library.library_module import Module

from contracts.settling_game.modules.relics.library import Relics
from openzeppelin.upgrades.library import Proxy

# -----------------------------------
# Events
# -----------------------------------

@event
func RelicUpdate(relic_id : Uint256, owner_token_id : Uint256):
end

# -----------------------------------
# Storage
# -----------------------------------

@storage_var
func storage_relic_holder(relic_id : Uint256) -> (owner_token_id : Uint256):
end

# -----------------------------------
# INITIALIZER & UPGRADE
# -----------------------------------

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, proxy_admin : felt
):
    Module.initializer(address_of_controller)
    Proxy.initializer(proxy_admin)
    return ()
end

# @notice Set new proxy implementation
# @dev Can only be set by the arbiter
# @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation)
    return ()
end

# -----------------------------------
# EXTERNAL
# -----------------------------------

# @notice set relic holder external function
# @implicit syscall_ptr
# @implicit range_check_ptr
# @param winner_token_id: winning realm id of battle
# @param loser_token_id: loosing realm id of battle
@external
func set_relic_holder{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    winner_token_id : Uint256, loser_token_id : Uint256
):
    alloc_locals
    # Only Combat
    Module.only_approved()

    let (current_relic_owner) = get_current_relic_holder(loser_token_id)

    let (is_equal) = uint256_eq(current_relic_owner, loser_token_id)

    # Capture Relic if owned by loser
    # If Relic is owned by loser, send to victor
    if is_equal == TRUE:
        _set_relic_holder(loser_token_id, winner_token_id)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    # Capture back if held by loser
    # Check if loser has winners token
    let (winners_relic_owner) = get_current_relic_holder(winner_token_id)

    let (holds_relic) = uint256_eq(winners_relic_owner, loser_token_id)

    if holds_relic == TRUE:
        _set_relic_holder(winner_token_id, winner_token_id)
        return ()
    end

    # TODO: Add Order capture back

    return ()
end

# -----------------------------------
# SETTERS
# -----------------------------------

func _set_relic_holder{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    relic_id : Uint256, owner_token_id : Uint256
):
    storage_relic_holder.write(relic_id, owner_token_id)

    # Emit update whenever Relic changes hands
    RelicUpdate.emit(relic_id, owner_token_id)
    return ()
end

# -----------------------------------
# GETTERS
# -----------------------------------

# @notice gets current relic holder
# @implicit syscall_ptr
# @implicit range_check_ptr
# @param relic_id: id of relic, pass in realm id
# @return token_id: returns realm id of owning relic
@view
func get_current_relic_holder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    relic_id : Uint256
) -> (token_id : Uint256):
    alloc_locals

    let (holder_id) = storage_relic_holder.read(relic_id)

    let (data) = Relics._current_relic_holder(relic_id, holder_id)

    return (data)
end
