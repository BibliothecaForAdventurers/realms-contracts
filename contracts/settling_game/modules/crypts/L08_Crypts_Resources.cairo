# ____MODULE_L08___CRYPTS_RESOURCES_LOGIC
#   Logic to create and issue resources for a given Crypt
#
# MIT License
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from contracts.settling_game.utils.game_structs import (
    CryptData,
    ModuleIds,
    ExternalContractIds,
    EnvironmentProduction,
)

from contracts.settling_game.utils.constants import DAY, RESOURCES_PER_CRYPT, LEGENDARY_MULTIPLIER
from contracts.settling_game.library.library_module import Module

from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.crypts_IERC721 import crypts_IERC721
from contracts.settling_game.interfaces.imodules import IModuleController, IL07_Crypts

###############
# CONSTRUCTOR #
###############

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, proxy_admin : felt
):
    Module.initializer(address_of_controller)
    Proxy.initializer(proxy_admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation)
    return ()
end

############
# EXTERNAL #
############

@external
func claim_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
):
    alloc_locals
    let (caller) = get_caller_address()

    # CONTRACT ADDRESSES

    # EXTERNAL CONTRACTS
    # Crypts ERC721 Token
    let (crypts_address) = Module.get_external_contract_address(ExternalContractIds.Crypts)

    # S_Crypts ERC721 Token
    let (s_crypts_address) = Module.get_external_contract_address(ExternalContractIds.S_Crypts)

    # Resources 1155 Token
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources)

    # # INTERNAL CONTRACTS
    # Crypts Logic Contract
    let (crypts_logic_address) = Module.get_module_address(ModuleIds.L07_Crypts)

    # FETCH OWNER
    let (owner) = IERC721.ownerOf(s_crypts_address, token_id)

    # ALLOW RESOURCE LOGIC ADDRESS TO CLAIM, BUT STILL RESTRICT
    if caller != crypts_logic_address:
        # Allwo users to claim directly
        Module.ERC721_owner_check(token_id, ExternalContractIds.S_Crypts)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        # Or allow the Crypts contract to claim on unsettle()
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    let (local resource_ids : Uint256*) = alloc()
    let (local user_resources_value : Uint256*) = alloc()  # How many of this resource get minted

    # FETCH CRYPT DATA
    let (crypts_data : CryptData) = crypts_IERC721.fetch_crypt_data(crypts_address, token_id)

    # CALC DAYS
    let (days, _) = days_accrued(token_id)

    with_attr error_message("RESOURCES: Nothing Claimable."):
        assert_not_zero(days)
    end

    # GET ENVIRONMENT
    let (r_output, r_resource_id) = get_output_per_environment(crypts_data.environment)

    # CHECK IF LEGENDARY
    let r_legendary = crypts_data.legendary

    # CHECK HOW MANY RESOURCES * DAYS WE SHOULD GIVE OUT
    let (r_user_resources_value) = calculate_resource_output(days, r_output, r_legendary)

    # ADD VALUES TO TEMP ARRAY FOR EACH AVAILABLE RESOURCE
    assert resource_ids[0] = Uint256(r_resource_id, 0)
    assert user_resources_value[0] = r_user_resources_value

    # MINT USERS RESOURCES
    IERC1155.mintBatch(
        resources_address,
        owner,
        RESOURCES_PER_CRYPT,
        resource_ids,
        RESOURCES_PER_CRYPT,
        user_resources_value,
    )

    return ()
end

###########
# GETTERS #
###########

# FETCHES AVAILABLE RESOURCES PER DAY
@view
func days_accrued{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (days_accrued : felt, remainder : felt):
    let (controller) = Module.controller_address()
    let (block_timestamp) = get_block_timestamp()
    let (settling_logic_address) = IModuleController.get_module_address(
        controller, ModuleIds.L07_Crypts
    )

    # GET DAYS ACCRUED
    let (last_update) = IL07_Crypts.get_time_staked(settling_logic_address, token_id)
    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY)

    return (days_accrued, seconds_left_over)
end

# CLAIM CHECK
@view
func check_if_claimable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (can_claim : felt):
    alloc_locals

    # FETCH AVAILABLE
    let (days, _) = days_accrued(token_id)

    # ADD 1 TO ALLOW USERS TO CLAIM FULL EPOCH
    let (less_than) = is_le(days + 1, 1)

    if less_than == TRUE:
        return (FALSE)
    end

    return (TRUE)
end

###########
# GETTERS #
###########

# GET OUTPUT PER ENViRONMENT
@view
func get_output_per_environment{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    environment : felt
) -> (r_output : felt, r_resource_id : felt):
    alloc_locals

    # Each environment has a designated resourceId
    with_attr error_message("RESOURCES: resource id overflowed a felt."):
        let r_resource_id = 22 + environment  # Environment struct is 1->6 and Crypts resources are 23->28
    end

    if environment == 1:
        return (EnvironmentProduction.DesertOasis, r_resource_id)
    end
    if environment == 2:
        return (EnvironmentProduction.StoneTemple, r_resource_id)
    end
    if environment == 3:
        return (EnvironmentProduction.ForestRuins, r_resource_id)
    end
    if environment == 4:
        return (EnvironmentProduction.MountainDeep, r_resource_id)
    end
    if environment == 5:
        return (EnvironmentProduction.UnderwaterKeep, r_resource_id)
    end
    # 6 - Ember's glow is theo pnly one left
    return (EnvironmentProduction.EmbersGlow, r_resource_id)
end

############
# INTERNAL #
############

# RETURNS RESOURCE OUTPUT
func calculate_resource_output{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    days : felt, output : felt, legendary : felt
) -> (value : Uint256):
    alloc_locals

    # LEGENDARY MAPS EARN MORE RESOURCES
    let legendary_multiplier = legendary * LEGENDARY_MULTIPLIER

    let (total_work_generated, _) = unsigned_div_rem(days * output * legendary_multiplier, 100)

    return (Uint256(total_work_generated * 10 ** 18, 0))
end
