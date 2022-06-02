# ____MODULE_L05___WONDERS_LOGIC
#   Controls all logic around the Wonder tax.
#
# MIT License
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import (
    assert_in_range,
    assert_nn_le,
    unsigned_div_rem,
    assert_not_zero,
)
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_add, uint256_unsigned_div_rem

from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds
from contracts.settling_game.utils.constants import TRUE, FALSE
from contracts.settling_game.interfaces.imodules import IModuleController, IL04_Calculator

from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721

from contracts.settling_game.library.library_module import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
)

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation,
)

###########
# STORAGE #
###########

@storage_var
func epoch_claimed(address : felt) -> (epoch : felt):
end

@storage_var
func total_wonders_staked(epoch : felt) -> (amount : felt):
end

@storage_var
func last_updated_epoch() -> (epoch : felt):
end

@storage_var
func wonder_id_staked(token_id : Uint256) -> (epoch : felt):
end

@storage_var
func wonder_epoch_upkeep(epoch : felt, token_id : Uint256) -> (upkept : felt):
end

@storage_var
func tax_pool(epoch : felt, resource_id : Uint256) -> (supply : Uint256):
end

###############
# CONSTRUCTOR #
###############

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, proxy_admin : felt
):
    MODULE_initializer(address_of_controller)
    Proxy_initializer(proxy_admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy_only_admin()
    Proxy_set_implementation(new_implementation)
    return ()
end

############
# EXTERNAL #
############

# RESOURCE SHARE FOR A GIVEN EPOCH
# DOESNT UPDATE
@view
func get_epoch_tax_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        claiming_epoch : felt) -> (
        resource_claim_amounts_len : felt, resource_claim_amounts : Uint256*):
    alloc_locals
    let (controller) = MODULE_controller_address()

    let (epoch_total_wonders) = get_total_wonders_staked(
        claiming_epoch)

    # Set amounts
    let ( resource_claim_amounts : Uint256* ) = alloc()

    if epoch_total_wonders == 0:
        return (0, resource_claim_amounts)
    end

    let (pool_r_1) = get_tax_pool( claiming_epoch, Uint256(1, 0))
    let (pool_r_2) = get_tax_pool( claiming_epoch, Uint256(2, 0))
    let (pool_r_3) = get_tax_pool( claiming_epoch, Uint256(3, 0))
    let (pool_r_4) = get_tax_pool( claiming_epoch, Uint256(4, 0))
    let (pool_r_5) = get_tax_pool( claiming_epoch, Uint256(5, 0))
    let (pool_r_6) = get_tax_pool( claiming_epoch, Uint256(6, 0))
    let (pool_r_7) = get_tax_pool( claiming_epoch, Uint256(7, 0))
    let (pool_r_8) = get_tax_pool( claiming_epoch, Uint256(8, 0))
    let (pool_r_9) = get_tax_pool( claiming_epoch, Uint256(9, 0))
    let (pool_r_10) = get_tax_pool( claiming_epoch, Uint256(10, 0))
    let (pool_r_11) = get_tax_pool( claiming_epoch, Uint256(11, 0))
    let (pool_r_12) = get_tax_pool( claiming_epoch, Uint256(12, 0))
    let (pool_r_13) = get_tax_pool( claiming_epoch, Uint256(13, 0))
    let (pool_r_14) = get_tax_pool( claiming_epoch, Uint256(14, 0))
    let (pool_r_15) = get_tax_pool( claiming_epoch, Uint256(15, 0))
    let (pool_r_16) = get_tax_pool( claiming_epoch, Uint256(16, 0))
    let (pool_r_17) = get_tax_pool( claiming_epoch, Uint256(17, 0))
    let (pool_r_18) = get_tax_pool( claiming_epoch, Uint256(18, 0))
    let (pool_r_19) = get_tax_pool( claiming_epoch, Uint256(19, 0))
    let (pool_r_20) = get_tax_pool( claiming_epoch, Uint256(20, 0))
    let (pool_r_21) = get_tax_pool( claiming_epoch, Uint256(21, 0))
    let (pool_r_22) = get_tax_pool( claiming_epoch, Uint256(22, 0))

    let (claim_r_1, _) = uint256_unsigned_div_rem(pool_r_1, Uint256(epoch_total_wonders, 0)) 
    let (claim_r_2, _) = uint256_unsigned_div_rem(pool_r_2, Uint256(epoch_total_wonders, 0))
    let (claim_r_3, _) = uint256_unsigned_div_rem(pool_r_3, Uint256(epoch_total_wonders, 0))
    let (claim_r_4, _) = uint256_unsigned_div_rem(pool_r_4, Uint256(epoch_total_wonders, 0))
    let (claim_r_5, _) = uint256_unsigned_div_rem(pool_r_5, Uint256(epoch_total_wonders, 0))
    let (claim_r_6, _) = uint256_unsigned_div_rem(pool_r_6, Uint256(epoch_total_wonders, 0))
    let (claim_r_7, _) = uint256_unsigned_div_rem(pool_r_7, Uint256(epoch_total_wonders, 0))
    let (claim_r_8, _) = uint256_unsigned_div_rem(pool_r_8, Uint256(epoch_total_wonders, 0))
    let (claim_r_9, _) = uint256_unsigned_div_rem(pool_r_9, Uint256(epoch_total_wonders, 0))
    let (claim_r_10, _) = uint256_unsigned_div_rem(pool_r_10, Uint256(epoch_total_wonders, 0))
    let (claim_r_11, _) = uint256_unsigned_div_rem(pool_r_11, Uint256(epoch_total_wonders, 0)) 
    let (claim_r_12, _) = uint256_unsigned_div_rem(pool_r_12, Uint256(epoch_total_wonders, 0))
    let (claim_r_13, _) = uint256_unsigned_div_rem(pool_r_13, Uint256(epoch_total_wonders, 0))
    let (claim_r_14, _) = uint256_unsigned_div_rem(pool_r_14, Uint256(epoch_total_wonders, 0))
    let (claim_r_15, _) = uint256_unsigned_div_rem(pool_r_15, Uint256(epoch_total_wonders, 0))
    let (claim_r_16, _) = uint256_unsigned_div_rem(pool_r_16, Uint256(epoch_total_wonders, 0))
    let (claim_r_17, _) = uint256_unsigned_div_rem(pool_r_17, Uint256(epoch_total_wonders, 0))
    let (claim_r_18, _) = uint256_unsigned_div_rem(pool_r_18, Uint256(epoch_total_wonders, 0))
    let (claim_r_19, _) = uint256_unsigned_div_rem(pool_r_19, Uint256(epoch_total_wonders, 0))
    let (claim_r_20, _) = uint256_unsigned_div_rem(pool_r_20, Uint256(epoch_total_wonders, 0))
    let (claim_r_21, _) = uint256_unsigned_div_rem(pool_r_21, Uint256(epoch_total_wonders, 0))
    let (claim_r_22, _) = uint256_unsigned_div_rem(pool_r_22, Uint256(epoch_total_wonders, 0))

    assert resource_claim_amounts[0] = claim_r_1
    assert resource_claim_amounts[1] = claim_r_2
    assert resource_claim_amounts[2] = claim_r_3
    assert resource_claim_amounts[3] = claim_r_4
    assert resource_claim_amounts[4] = claim_r_5
    assert resource_claim_amounts[5] = claim_r_6
    assert resource_claim_amounts[6] = claim_r_7
    assert resource_claim_amounts[7] = claim_r_8
    assert resource_claim_amounts[8] = claim_r_9
    assert resource_claim_amounts[9] = claim_r_10
    assert resource_claim_amounts[10] = claim_r_11
    assert resource_claim_amounts[11] = claim_r_12
    assert resource_claim_amounts[12] = claim_r_13
    assert resource_claim_amounts[13] = claim_r_14
    assert resource_claim_amounts[14] = claim_r_15
    assert resource_claim_amounts[15] = claim_r_16
    assert resource_claim_amounts[16] = claim_r_17
    assert resource_claim_amounts[17] = claim_r_18
    assert resource_claim_amounts[18] = claim_r_19
    assert resource_claim_amounts[19] = claim_r_20
    assert resource_claim_amounts[20] = claim_r_21
    assert resource_claim_amounts[21] = claim_r_22

    return (22, resource_claim_amounts)
end

@external
func fetch_updated_epoch_tax_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt) -> (
        resource_claim_amounts_len : felt, resource_claim_amounts : Uint256*):
    alloc_locals
    # UPDATE FIRST
    update_epoch_pool()

    # GET TAX SHARE FOR EPOCH
    return get_epoch_tax_share(epoch)
end

@external
func fetch_updated_total_wonders_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt) -> (
        amount : felt):
    alloc_locals
    # UPDATE FIRST
    update_epoch_pool()

    # GET CONTROLLER ADDRESS
    let (controller) = MODULE_controller_address()

    let ( amount ) = get_total_wonders_staked(epoch)

    return ( amount )
end

# AVAILABLE WONDER TAX RESOURCE CLAIM FOR GIVEN REALM ID
@external
func fetch_available_tax_claim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (
        resource_claim_amounts_len : felt, resource_claim_amounts : Uint256*):
    alloc_locals
    update_epoch_pool()

    # GET CONTROLLER ADDRESS
    let (controller) = MODULE_controller_address()

    # GET CALCULATOR ADDRESS
    let (calculator_address) = IModuleController.get_module_address(
        controller, ModuleIds.L04_Calculator)

    # GET CURRENT EPOCH
    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)

    # GET EPOCH OF STAKING
    let (staked_epoch) = get_wonder_id_staked(token_id)

    # # Check that its staked
    assert_not_zero(staked_epoch)

    # assert that claim loop starts at a past epoch
    assert_nn_le(staked_epoch + 1, current_epoch - 1)

    let ( resource_claim_amounts : Uint256* ) = alloc()    

    assert resource_claim_amounts[0] = Uint256(0, 0)
    assert resource_claim_amounts[1] = Uint256(0, 0)
    assert resource_claim_amounts[2] = Uint256(0, 0)
    assert resource_claim_amounts[3] = Uint256(0, 0)
    assert resource_claim_amounts[4] = Uint256(0, 0)
    assert resource_claim_amounts[5] = Uint256(0, 0)
    assert resource_claim_amounts[6] = Uint256(0, 0)
    assert resource_claim_amounts[7] = Uint256(0, 0)
    assert resource_claim_amounts[8] = Uint256(0, 0)
    assert resource_claim_amounts[9] = Uint256(0, 0)
    assert resource_claim_amounts[10] = Uint256(0, 0)
    assert resource_claim_amounts[11] = Uint256(0, 0)
    assert resource_claim_amounts[12] = Uint256(0, 0)
    assert resource_claim_amounts[13] = Uint256(0, 0)
    assert resource_claim_amounts[14] = Uint256(0, 0)
    assert resource_claim_amounts[15] = Uint256(0, 0)
    assert resource_claim_amounts[16] = Uint256(0, 0)
    assert resource_claim_amounts[17] = Uint256(0, 0)
    assert resource_claim_amounts[18] = Uint256(0, 0)
    assert resource_claim_amounts[19] = Uint256(0, 0)
    assert resource_claim_amounts[20] = Uint256(0, 0)
    assert resource_claim_amounts[21] = Uint256(0, 0)

    return loop_epochs_claim(
        token_id, staked_epoch + 1,
        22, resource_claim_amounts)
end

@external
func pay_wonder_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt, token_id : Uint256
):
    alloc_locals
    let (controller) = MODULE_controller_address()
    let (caller) = get_caller_address()

    # ADDRESSES
    let (treasury_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Treasury
    )
    let (resources_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )
    let (calculator_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L04_Calculator
    )

    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)

    assert_nn_le(current_epoch, epoch)

    # Set upkept for epoch
    set_wonder_epoch_upkeep(epoch, token_id, 1)

    # Upkeep cost, to be moved
    let (local upkeep_token_ids : Uint256*) = alloc()
    let (local upkeep_token_amounts : Uint256*) = alloc()

    # TODO: Convert into ids and values into storage so can be adjusted dynamically
    assert upkeep_token_ids[0] = Uint256(19, 0)
    assert upkeep_token_ids[1] = Uint256(20, 0)
    assert upkeep_token_ids[2] = Uint256(21, 0)
    assert upkeep_token_ids[3] = Uint256(22, 0)

    assert upkeep_token_amounts[0] = Uint256(28, 0)
    assert upkeep_token_amounts[1] = Uint256(21, 0)
    assert upkeep_token_amounts[2] = Uint256(14, 0)
    assert upkeep_token_amounts[3] = Uint256(7, 0)

    IERC1155.safeBatchTransferFrom(
        resources_address, caller, treasury_address, 4, upkeep_token_ids, 4, upkeep_token_amounts
    )

    return ()
end

# Called when a settlement is staked/unstaked to update the wonder pool
@external
func update_wonder_settlement{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
):
    alloc_locals
    MODULE_only_approved()
    update_epoch_pool()

    let (controller) = MODULE_controller_address()

    # calculator logic contract
    let (calculator_address) = IModuleController.get_module_address(
        controller, ModuleIds.L04_Calculator
    )

    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)
    let (total_wonders_staked) = get_total_wonders_staked(current_epoch)

    let (wonder_id_staked) = get_wonder_id_staked(token_id)

    if wonder_id_staked == 0:
        set_total_wonders_staked(current_epoch, total_wonders_staked + 1)
        set_wonder_id_staked(token_id, current_epoch)
    else:
        set_total_wonders_staked(current_epoch, total_wonders_staked - 1)
        set_wonder_id_staked(token_id, 0)
    end
    return ()
end

############
# INTERNAL #
############

# LOOPS THROUGH EPOCHS AND RETURNS THE SUM OF AVAILABLE TAX CLAIM FOR A REALM
func loop_epochs_claim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, claiming_epoch : felt,
        resource_claim_amounts_len : felt, resource_claim_amounts : Uint256*) -> (
        resource_claim_amounts_len : felt, resource_claim_amounts : Uint256*):
    alloc_locals

    # GET CONTROLLER ADDRESS
    let (controller) = MODULE_controller_address()

    # GET CALCULATOR ADDRESS
    let (calculator_address) = IModuleController.get_module_address(
        controller, ModuleIds.L04_Calculator)

    # GET CURRENT EPOCH
    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)

    # GET RESOURCE SHARE FOR CLAIMING EPOCH
    let ( claiming_epoch_amounts_len, claiming_epoch_amounts ) = get_epoch_tax_share(claiming_epoch)

    assert_not_zero(claiming_epoch_amounts_len)

    # IS THE CLAIMING EPOCH BEFORE ONGOING EPOCH?
    let ( local within_max_epoch) = is_nn_le(claiming_epoch, current_epoch - 1)

    # # STOP RECURSING
    if within_max_epoch == FALSE:
        return (resource_claim_amounts_len, resource_claim_amounts)
    end

    # IS WONDER UPKEPT FOR THSI EPOCH
    let (was_epoch_upkept) = get_wonder_epoch_upkeep(
        claiming_epoch, token_id)

    # CONTINUE RECURSION WITHOUT UPDATING CLAIM ARRAY
    # # if epoch wasnt upkept
    if was_epoch_upkept == FALSE:
      return loop_epochs_claim(
        token_id, claiming_epoch + 1,
        22,
        resource_claim_amounts)
    end

    # Add each resource to corresponding current tax claim sum 
    let (resource_1, _) = uint256_add(claiming_epoch_amounts[0], resource_claim_amounts[0])
    let (resource_2, _) = uint256_add(claiming_epoch_amounts[1], resource_claim_amounts[1])
    let (resource_3, _) = uint256_add(claiming_epoch_amounts[2], resource_claim_amounts[2])
    let (resource_4, _) = uint256_add(claiming_epoch_amounts[3], resource_claim_amounts[3])
    let (resource_5, _) = uint256_add(claiming_epoch_amounts[4], resource_claim_amounts[4])
    let (resource_6, _) = uint256_add(claiming_epoch_amounts[5], resource_claim_amounts[5])
    let (resource_7, _) = uint256_add(claiming_epoch_amounts[6], resource_claim_amounts[6])
    let (resource_8, _) = uint256_add(claiming_epoch_amounts[7], resource_claim_amounts[7])
    let (resource_9, _) = uint256_add(claiming_epoch_amounts[8], resource_claim_amounts[8])
    let (resource_10, _) = uint256_add(claiming_epoch_amounts[9], resource_claim_amounts[9])
    let (resource_11, _) = uint256_add(claiming_epoch_amounts[10], resource_claim_amounts[10])
    let (resource_12, _) = uint256_add(claiming_epoch_amounts[11], resource_claim_amounts[11])
    let (resource_13, _) = uint256_add(claiming_epoch_amounts[12], resource_claim_amounts[12])
    let (resource_14, _) = uint256_add(claiming_epoch_amounts[13], resource_claim_amounts[13])
    let (resource_15, _) = uint256_add(claiming_epoch_amounts[14], resource_claim_amounts[14])
    let (resource_16, _) = uint256_add(claiming_epoch_amounts[15], resource_claim_amounts[15])
    let (resource_17, _) = uint256_add(claiming_epoch_amounts[16], resource_claim_amounts[16])
    let (resource_18, _) = uint256_add(claiming_epoch_amounts[17], resource_claim_amounts[17])
    let (resource_19, _) = uint256_add(claiming_epoch_amounts[18], resource_claim_amounts[18])
    let (resource_20, _) = uint256_add(claiming_epoch_amounts[19], resource_claim_amounts[19])
    let (resource_21, _) = uint256_add(claiming_epoch_amounts[20], resource_claim_amounts[20])
    let (resource_22, _) = uint256_add(claiming_epoch_amounts[21], resource_claim_amounts[21])

    let ( updated_claim_amounts : Uint256* ) = alloc()

    assert updated_claim_amounts[0] = resource_1
    assert updated_claim_amounts[1] = resource_2
    assert updated_claim_amounts[2] = resource_3
    assert updated_claim_amounts[3] = resource_4
    assert updated_claim_amounts[4] = resource_5
    assert updated_claim_amounts[5] = resource_6
    assert updated_claim_amounts[6] = resource_7
    assert updated_claim_amounts[7] = resource_8
    assert updated_claim_amounts[8] = resource_9
    assert updated_claim_amounts[9] = resource_10
    assert updated_claim_amounts[10] = resource_11
    assert updated_claim_amounts[11] = resource_12
    assert updated_claim_amounts[12] = resource_13
    assert updated_claim_amounts[13] = resource_14
    assert updated_claim_amounts[14] = resource_15
    assert updated_claim_amounts[15] = resource_16
    assert updated_claim_amounts[16] = resource_17
    assert updated_claim_amounts[17] = resource_18
    assert updated_claim_amounts[18] = resource_19
    assert updated_claim_amounts[19] = resource_20
    assert updated_claim_amounts[20] = resource_21
    assert updated_claim_amounts[21] = resource_22

    # CONTINUE RECURSION WITH UPDATED TAX CLAIM ARRAY
    return loop_epochs_claim(
        token_id, claiming_epoch + 1,
        22,
        updated_claim_amounts)
end

# Called everytime a user settled, unsettles or claims taxesget_tax_pool
# Recurses for every epoch that passed since last update
func update_epoch_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (controller) = MODULE_controller_address()
    let (calculator_address) = IModuleController.get_module_address(
        controller, ModuleIds.L04_Calculator)

    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)
    let (last_updated_epoch) = get_last_updated_epoch()

    # Epochs that havent been updated since last update or recursion
    let epochs_to_update = current_epoch - last_updated_epoch

    if epochs_to_update == 0:
        return ()
    else:
        let updating_epoch = current_epoch - epochs_to_update

        # roll over total wonders staked for the next epoch
        let (total_wonders_staked) = get_total_wonders_staked(
            updating_epoch)
        set_total_wonders_staked(
            updating_epoch + 1, total_wonders_staked)

        set_last_updated_epoch(updating_epoch + 1)

        return update_epoch_pool()
    end
end


###########
# SETTERS #
###########

@external
func set_total_wonders_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, amount : felt):
    MODULE_only_approved()

    total_wonders_staked.write(epoch, amount)
    return ()
end

@external
func set_last_updated_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt):
    MODULE_only_approved()

    last_updated_epoch.write(epoch)
    return ()
end

@external
func set_wonder_id_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, epoch : felt):
    MODULE_only_approved()

    wonder_id_staked.write(token_id, epoch)
    return ()
end

@external
func set_wonder_epoch_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, token_id : Uint256, upkept : felt):
    MODULE_only_approved()

    wonder_epoch_upkeep.write(epoch, token_id, upkept)
    return ()
end

func set_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, resource_id : Uint256, amount : Uint256):
    tax_pool.write(epoch, resource_id, amount)
    return ()
end

@external
func batch_set_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, resource_ids_len : felt, resource_ids : Uint256*, amounts_len : felt,
        amounts : Uint256*):
    alloc_locals
    MODULE_only_approved()
    # Update tax pool
    if resource_ids_len == 0:
        return ()
    end

    let cur_amount : Uint256 = [amounts]
    let cur_id : Uint256 = [resource_ids]

    let (tax_pool) = get_tax_pool(epoch, cur_id)
    let (new_tax_pool, _) = uint256_add(tax_pool, cur_amount)

    set_tax_pool(epoch, cur_id, new_tax_pool)

    # Recurse
    return batch_set_tax_pool(
        epoch, resource_ids_len - 1, resource_ids + Uint256.SIZE, amounts_len - 1, amounts + Uint256.SIZE)
end

###########
# GETTERS #
###########

@view
func get_total_wonders_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt) -> (amount : felt):
    let (amount) = total_wonders_staked.read(epoch)

    return (amount=amount)
end

@view
func get_last_updated_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (epoch : felt):
    let (epoch) = last_updated_epoch.read()

    return (epoch=epoch)
end

@view
func get_wonder_id_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (epoch : felt):
    let (epoch) = wonder_id_staked.read(token_id)

    return (epoch=epoch)
end

@view
func get_wonder_epoch_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, token_id : Uint256) -> (upkept : felt):
    let (upkept) = wonder_epoch_upkeep.read(epoch, token_id)

    return (upkept=upkept)
end

@view
func get_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, resource_id : Uint256) -> (supply : Uint256):
    let (supply) = tax_pool.read(epoch, resource_id)

    return (supply)
end
