# -----------------------------------
# ____Module.L02___RESOURCES_LOGIC
#   Logic to create and issue resources for a given Realm
#
# MIT License
# -----------------------------------
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.utils.game_structs import (
    RealmData,
    ModuleIds,
    ExternalContractIds,
    Cost,
    RealmBuildings,
)

from contracts.settling_game.utils.constants import (
    VAULT_LENGTH,
    DAY,
    BASE_RESOURCES_PER_DAY,
    BASE_LORDS_PER_DAY,
    PILLAGE_AMOUNT,
    MAX_DAYS_ACCURED,
)

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.imodules import (
    IL01_Settling,
    IL04_Calculator,
    IL05_Wonders,
    IL03_Buildings,
)
from contracts.settling_game.library.library_resources import Resources

# -----------------------------------
# Events
# -----------------------------------

@event
func ResourceUpgraded(token_id : Uint256, building_id : felt, level : felt):
end

# -----------------------------------
# Storage
# -----------------------------------

@storage_var
func resource_levels(token_id : Uint256, resource_id : felt) -> (level : felt):
end

@storage_var
func resource_upgrade_cost(resource_id : felt) -> (cost : Cost):
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

# @notice Claim available resources
# @token_id: Staked realm token id
@external
func claim_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
):
    alloc_locals
    let (caller) = get_caller_address()

    # CONTRACT ADDRESSES
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms)
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources)
    let (treasury_address) = Module.get_external_contract_address(ExternalContractIds.Treasury)

    # modules
    let (settling_logic_address) = Module.get_module_address(ModuleIds.L01_Settling)
    let (calculator_address) = Module.get_module_address(ModuleIds.L04_Calculator)

    # FETCH OWNER
    let (owner) = IERC721.ownerOf(s_realms_address, token_id)

    # ALLOW RESOURCE LOGIC ADDRESS TO CLAIM, BUT STILL RESTRICT
    if caller != settling_logic_address:
        Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    # FETCH REALM DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    # CALC DAYS
    let (total_days, remainder) = days_accrued(token_id)

    # CALC VAULT DAYS
    let (total_vault_days, vault_remainder) = get_available_vault_days(token_id)

    # CHECK DAYS + VAULT > 1
    let days = total_days + total_vault_days

    with_attr error_message("RESOURCES: Nothing Claimable."):
        assert_not_zero(days)
    end

    # SET VAULT TIME = REMAINDER - CURRENT_TIME
    IL01_Settling.set_time_staked(settling_logic_address, token_id, remainder)
    IL01_Settling.set_time_vault_staked(settling_logic_address, token_id, vault_remainder)

    # get current buildings on realm
    let (buildings_address) = Module.get_module_address(ModuleIds.L03_Buildings)
    let (current_buildings : RealmBuildings) = IL03_Buildings.get_effective_buildings(
        buildings_address, token_id
    )

    # resources ids
    let (resource_ids) = Resources._calculate_realm_resource_ids(realms_data)

    let (resource_mint) = Resources._calculate_total_mintable_resources(
        current_buildings.House, 100, realms_data, days, 100
    )

    # FETCH OWNER
    let (owner) = realms_IERC721.ownerOf(s_realms_address, token_id)

    let (local data : felt*) = alloc()
    assert data[0] = 0

    # MINT USERS RESOURCES
    IERC1155.mintBatch(
        resources_address,
        owner,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        resource_mint,
        1,
        data,
    )

    return ()
end

# @notice Pillage resources after a succesful raid
# @param token_id: Staked realm id
# @param claimer: Resource receiver address
@external
func pillage_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, claimer : felt
):
    alloc_locals
    let (caller) = get_caller_address()

    # ONLY COMBAT CAN CALL
    let (combat_address) = Module.get_module_address(ModuleIds.L06_Combat)

    with_attr error_message("RESOURCES: ONLY COMBAT MODULE CAN CALL"):
        assert caller = combat_address
    end

    # EXTERNAL CONTRACTS
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms)
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources)
    let (settling_logic_address) = Module.get_module_address(ModuleIds.L01_Settling)
    let (calculator_address) = Module.get_module_address(ModuleIds.L04_Calculator)

    # FETCH REALM DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    # resources ids
    let (resource_ids : Uint256*) = Resources._calculate_realm_resource_ids(realms_data)

    # CALC PILLAGABLE DAYS
    let (total_pillagable_days, pillagable_remainder) = vault_days_accrued(token_id)

    # CHECK IS RAIDABLE
    with_attr error_message("RESOURCES: NOTHING TO RAID!"):
        assert_not_zero(total_pillagable_days)
    end

    # SET VAULT TIME = REMAINDER - CURRENT_TIME
    IL01_Settling.set_time_vault_staked(settling_logic_address, token_id, pillagable_remainder)

    # get current buildings on realm
    let (buildings_address) = Module.get_module_address(ModuleIds.L03_Buildings)
    let (current_buildings : RealmBuildings) = IL03_Buildings.get_effective_buildings(
        buildings_address, token_id
    )

    # No happiness cap for pillaging
    let (resource_mint : Uint256*) = Resources._calculate_total_mintable_resources(
        current_buildings.House, 100, realms_data, total_pillagable_days, PILLAGE_AMOUNT
    )

    let (local data : felt*) = alloc()
    assert data[0] = 0

    # MINT PILLAGED RESOURCES TO VICTOR
    IERC1155.mintBatch(
        resources_address,
        claimer,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        resource_mint,
        1,
        data,
    )

    return ()
end

# -----------------------------------
# GETTERS
# -----------------------------------

# @notice Gets the number of accrued days
# @param token_id: Staked realm token id
# @return days_accrued: Number of days accrued
# @return remainder: Time remainder after division in seconds
@view
func days_accrued{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (days_accrued : felt, remainder : felt):
    alloc_locals

    let (block_timestamp) = get_block_timestamp()
    let (settling_logic_address) = Module.get_module_address(ModuleIds.L01_Settling)

    # GET DAYS ACCRUED
    let (last_update) = IL01_Settling.get_time_staked(settling_logic_address, token_id)
    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY)

    let (is_less_than_max) = is_le(days_accrued, MAX_DAYS_ACCURED + 1)

    if is_less_than_max == TRUE:
        return (days_accrued, seconds_left_over)
    end

    return (MAX_DAYS_ACCURED, seconds_left_over)
end

# @notice Gets the number of accrued days for the vault
# @param token_id: Staked realm token id
# @return days_accrued: Number of days accrued for the vault
# @return remainder: Time remainder after division in seconds
@view
func vault_days_accrued{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (days_accrued : felt, remainder : felt):
    alloc_locals

    let (block_timestamp) = get_block_timestamp()
    let (settling_logic_address) = Module.get_module_address(ModuleIds.L01_Settling)

    # GET DAYS ACCRUED
    let (last_update) = IL01_Settling.get_time_vault_staked(settling_logic_address, token_id)
    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY)

    return (days_accrued, seconds_left_over)
end

# @notice Fetches vault days available for realm owner only
# @dev Only returns value if days are over epoch length - set to 7 day cycles
# @param token_id: Staked realm token id
# @return days_accrued: Number of days accrued
# @return remainder: Remaining seconds
@view
func get_available_vault_days{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (days_accrued : felt, remainder : felt):
    alloc_locals

    # CALC REMAINING DAYS
    let (days_accrued, seconds_left_over) = vault_days_accrued(token_id)

    # returns true if days <= vault_length -1 (we minus 1 so the user can claim when they have 7 days)
    let (less_than) = is_le(days_accrued, VAULT_LENGTH - 1)

    # return no days and no remainder
    if less_than == TRUE:
        return (0, 0)
    end

    # else return days and remainder
    return (days_accrued, seconds_left_over)
end

# @notice check if resources are claimable
# @param token_id: Staked realm token id
# @return can_claim: Return if resources can be claimed
@view
func check_if_claimable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (can_claim : felt):
    alloc_locals

    # FETCH AVAILABLE
    let (days, _) = days_accrued(token_id)
    let (epochs, _) = get_available_vault_days(token_id)

    # ADD 1 TO ALLOW USERS TO CLAIM FULL EPOCH
    let (less_than) = is_le(days + epochs + 1, 1)

    if less_than == TRUE:
        return (FALSE)
    end

    return (TRUE)
end

# @notice Calculate all claimable resources
# @param token_id: Staked realms token id
# @return user_mint_len: Lenght of user_mint
# @return user_mint: List of users to mint to
# @return lords_available: Available lord tokens
@view
func get_all_resource_claimable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (user_mint_len : felt, user_mint : Uint256*):
    alloc_locals
    let (caller) = get_caller_address()

    # CONTRACT ADDRESSES
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (calculator_address) = Module.get_module_address(ModuleIds.L04_Calculator)

    # FETCH REALM DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    # CALC DAYS
    let (total_days, remainder) = days_accrued(token_id)

    # CALC VAULT DAYS
    let (total_vault_days, vault_remainder) = get_available_vault_days(token_id)

    # CHECK DAYS + VAULT > 1
    let days = total_days + total_vault_days

    # GET WONDER TAX
    let (wonder_tax) = IL04_Calculator.calculate_wonder_tax(calculator_address)

    # TODO: No wonder tax yet
    # SET MINT
    let user_mint_rel_perc = 100

    let (happiness) = IL04_Calculator.calculate_happiness(calculator_address, token_id)

    # get current buildings on realm
    let (buildings_address) = Module.get_module_address(ModuleIds.L03_Buildings)
    let (current_buildings : RealmBuildings) = IL03_Buildings.get_effective_buildings(
        buildings_address, token_id
    )

    let (resource_mint : Uint256*) = Resources._calculate_total_mintable_resources(
        current_buildings.House, happiness, realms_data, days, user_mint_rel_perc
    )

    return (realms_data.resource_number, resource_mint)
end

@view
func get_all_vault_raidable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (user_mint_len : felt, user_mint : Uint256*):
    alloc_locals
    let (caller) = get_caller_address()

    # CONTRACT ADDRESSES
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)

    # FETCH REALM DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    # CALC VAULT DAYS
    let (total_vault_days, vault_remainder) = vault_days_accrued(token_id)

    let (buildings_address) = Module.get_module_address(ModuleIds.L03_Buildings)
    let (current_buildings : RealmBuildings) = IL03_Buildings.get_effective_buildings(
        buildings_address, token_id
    )

    # pass 100 for base happiness
    let (resource_mint : Uint256*) = Resources._calculate_total_mintable_resources(
        current_buildings.House, 100, realms_data, total_vault_days, PILLAGE_AMOUNT
    )

    return (realms_data.resource_number, resource_mint)
end

#########
# deprecated #
#########

# @external
# func set_resource_upgrade_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
#     resource_id : felt, cost : Cost
# ):
#     Proxy_only_admin()
#     resource_upgrade_cost.write(resource_id, cost)
#     return ()
# end

#
# # SET LEVEL
# func set_resource_level{
#     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
# }(token_id : Uint256, resource_id : felt, level : felt) -> ():
#     resource_levels.write(token_id, resource_id, level)
#     return ()
# end
# GET RESOURCE LEVEL

# @view
# func get_resource_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     token_id : Uint256, resource : felt
# ) -> (level : felt):
#     let (level) = resource_levels.read(token_id, resource)
#     return (level=level)
# end

# # GET COSTS
# @view
# func get_resource_upgrade_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
#     resource_id : felt
# ) -> (cost : Cost):
#     let (cost) = resource_upgrade_cost.read(resource_id)
#     return (cost)
# end

# @external
# func upgrade_resource{
#     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
# }(token_id : Uint256, resource_id : felt) -> ():
#     alloc_locals

# let (can_claim) = check_if_claimable(token_id)

# if can_claim == TRUE:
#         claim_resources(token_id)
#         tempvar syscall_ptr = syscall_ptr
#         tempvar range_check_ptr = range_check_ptr
#         tempvar pedersen_ptr = pedersen_ptr
#     else:
#         tempvar syscall_ptr = syscall_ptr
#         tempvar range_check_ptr = range_check_ptr
#         tempvar pedersen_ptr = pedersen_ptr
#     end

# let (caller) = get_caller_address()
#     let (controller) = Module.controller_address()

# # CONTRACT ADDRESSES
#     let (resource_address) = IModuleController.get_external_contract_address(
#         controller, ExternalContractIds.Resources
#     )

# # AUTH
#     Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms)

# # GET RESOURCE LEVEL
#     let (level) = get_resource_level(token_id, resource_id)

# # GET UPGRADE VALUE
#     let (upgrade_cost : Cost) = get_resource_upgrade_cost(resource_id)
#     let (costs : Cost*) = alloc()
#     assert [costs] = upgrade_cost
#     let (token_ids : Uint256*) = alloc()
#     let (token_values : Uint256*) = alloc()
#     let (token_len : felt) = transform_costs_to_token_ids_values(1, costs, token_ids, token_values)

# # BURN RESOURCES
#     IERC1155.burnBatch(resource_address, caller, token_len, token_ids, token_len, token_values)

# # INCREASE LEVEL
#     set_resource_level(token_id, resource_id, level + 1)

# # EMIT
#     ResourceUpgraded.emit(token_id, resource_id, level + 1)
#     return ()
# end
