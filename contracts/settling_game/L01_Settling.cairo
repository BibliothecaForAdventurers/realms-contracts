# -----------------------------------
# ____Module.L01___SETTLING_LOGIC
#   Core Settling Game logic including setting up the world
#   and staking/unstaking a realm.
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds, RealmData
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721
from contracts.settling_game.interfaces.imodules import IL05_Wonders, IL02_Resources

# -----------------------------------
# Events
# -----------------------------------

@event
func Settled(owner : felt, token_id : Uint256):
end

@event
func UnSettled(owner : felt, token_id : Uint256):
end

@event
func VaultTime(token_id : Uint256, time_staked : felt):
end

@event
func ClaimTime(token_id : Uint256, time_staked : felt):
end

# -----------------------------------
# Storage
# -----------------------------------

# @notice STAKE TIME - THIS IS USED AS THE MAIN IDENTIFIER FOR STAKING TIME
#  IT IS UPDATED ON RESOURCE CLAIM, STAKE, UNSTAKE
@storage_var
func time_staked(token_id : Uint256) -> (time : felt):
end

@storage_var
func time_vault_staked(token_id : Uint256) -> (time : felt):
end

@storage_var
func total_realms_settled() -> (amount : felt):
end

# -----------------------------------
# Initialize & upgrade
# -----------------------------------

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @return proxy_admin: Proxy admin address
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
# External
# -----------------------------------

# @notice Settle realm
# @param token_id: Realm token id
@external
func settle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = Module.controller_address()
    let (contract_address) = get_contract_address()

    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms)

    # TRANSFER REALM
    realms_IERC721.transferFrom(realms_address, caller, contract_address, token_id)

    # MINT S_REALM
    s_realms_IERC721.mint(s_realms_address, caller, token_id)

    # SETS WORLD AND REALM STATE
    _set_world_state(token_id, caller, realms_address)

    # CHECK REALMS STATE
    let (realms_settled) = get_total_realms_settled()
    _set_total_realms_settled(realms_settled + 1)

    # EMIT
    Settled.emit(caller, token_id)

    return (TRUE)
end

# @notice Unsettle realm
# @param token_id: Realm token id
@external
func unsettle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (contract_address) = get_contract_address()

    # FETCH ADDRESSES
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms)
    let (resource_logic_address) = Module.get_module_address(ModuleIds.L02_Resources)

    # CHECK NO PENDING RESOURCES OR LORDS
    let (can_claim) = IL02_Resources.check_if_claimable(resource_logic_address, token_id)

    if can_claim == TRUE:
        IL02_Resources.claim_resources(resource_logic_address, token_id)
        _set_world_state(token_id, caller, realms_address)
    else:
        _set_world_state(token_id, caller, realms_address)
    end

    # TRANSFER REALM BACK TO OWNER
    realms_IERC721.transferFrom(realms_address, contract_address, caller, token_id)

    # BURN S_REALM
    s_realms_IERC721.burn(s_realms_address, token_id)

    # CHECK REALMS STATE
    let (realms_settled) = get_total_realms_settled()
    _set_total_realms_settled(realms_settled - 1)

    # EMIT
    UnSettled.emit(caller, token_id)

    return (TRUE)
end

# @notice Sets time remainder into storage after claiming resources
# @dev THIS ALLOWS FULL DAYS TO BE CLAIMED ONLY AND ALLOWS LESS THAN FULL DAYS TO CONTINUE ACCRUREING
# @param token_id: Realm token id
# @param time_left: How much time is left after claiming (remainder)
@external
func set_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, time_left : felt
):
    Module.only_approved()
    _set_time_staked(token_id, time_left)
    return ()
end

# @notice Sets time of vault being staked
# @dev Wrapper functions for internal _set_time_vault_staked
# @param token_id: Realms token id
# @param time_left: How much time is left after claiming (remainder)
@external
func set_time_vault_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, time_left : felt
):
    Module.only_approved()
    _set_time_vault_staked(token_id, time_left)
    return ()
end

# -----------------------------------
# Internal
# -----------------------------------

func _set_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, time_left : felt
):
    let (block_timestamp) = get_block_timestamp()
    time_staked.write(token_id, block_timestamp - time_left)
    ClaimTime.emit(token_id, block_timestamp - time_left)
    return ()
end

func _set_time_vault_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, time_left : felt
):
    let (block_timestamp) = get_block_timestamp()
    time_vault_staked.write(token_id, block_timestamp - time_left)
    VaultTime.emit(token_id, block_timestamp - time_left)
    return ()
end

func _set_total_realms_settled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : felt
):
    total_realms_settled.write(amount)
    return ()
end

func _set_world_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, caller : felt, realms_address : felt
):
    # SET REALM SETTLED/UNSETTLED STATE - PARSE 0 TO SET CURRENT TIME
    _set_time_staked(token_id, 0)
    _set_time_vault_staked(token_id, 0)

    # GET REALM DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    # UPDATE WONDERS
    if realms_data.wonder != FALSE:
        let (wonders_logic_address) = Module.get_module_address(ModuleIds.L05_Wonders)
        IL05_Wonders.update_wonder_settlement(wonders_logic_address, token_id)
        return ()
    end
    return ()
end

# -----------------------------------
# Getters
# -----------------------------------

# @notice Get time staked
# @param token_id: Realm token id
# @return time: Time staked
@view
func get_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (time : felt):
    return time_staked.read(token_id)
end

# @notice Get vault time staked
# @param token_id: Realm token id
# @return time: Vault time staked
@view
func get_time_vault_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (time : felt):
    return time_vault_staked.read(token_id)
end

# @notice Get the total amount of realms settled
# @return realms_settled: Total amount of realms settled
@view
func get_total_realms_settled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (amount : felt):
    return total_realms_settled.read()
end
