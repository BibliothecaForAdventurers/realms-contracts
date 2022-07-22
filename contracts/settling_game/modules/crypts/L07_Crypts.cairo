# ____MODULE_L07___CRYPTS_LOGIC
#   Staking/Unstaking a crypt.
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.interfaces.s_crypts_IERC721 import s_crypts_IERC721
from contracts.settling_game.interfaces.imodules import IModuleController, IL08_Crypts_Resources

# -----------------------------------
# Events
# -----------------------------------

# Staked = 🗝️ unlocked
# Unstaked = 🔒 locked (because Lore ofc)

@event
func Settled(owner : felt, token_id : Uint256):
end

@event
func UnSettled(owner : felt, token_id : Uint256):
end

# -----------------------------------
# Storage
# -----------------------------------

# STAKE TIME - This is used as the main identifier for staking time
# It is updated on Resource Claim, Stake, Unstake
@storage_var
func time_staked(token_id : Uint256) -> (time : felt):
end

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

# SETTLES CRYPT
@external
func settle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = Module.controller_address()
    let (contract_address) = get_contract_address()

    let (crypts_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Crypts
    )
    let (s_crypts_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Crypts
    )

    # TRANSFER CRYPT
    IERC721.transferFrom(crypts_address, caller, contract_address, token_id)

    # MINT S_CRYPT
    s_crypts_IERC721.mint(s_crypts_address, caller, token_id)

    # SETS TIME STAKED FOR FUTURE CLAIMS
    _set_time_staked(token_id, 0)

    # EMIT
    Settled.emit(caller, token_id)

    return (TRUE)
end

# UNSETTLES CRYPT
@external
func unsettle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = Module.controller_address()
    let (contract_address) = get_contract_address()

    # FETCH ADDRESSES
    let (crypts_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Crypts
    )
    let (s_crypts_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Crypts
    )

    let (resource_logic_address) = IModuleController.get_module_address(
        controller, ModuleIds.L08_Crypts_Resources
    )

    # CHECK NO PENDING RESOURCES
    let (can_claim) = IL08_Crypts_Resources.check_if_claimable(resource_logic_address, token_id)

    if can_claim == TRUE:
        IL08_Crypts_Resources.claim_resources(resource_logic_address, token_id)
        _set_time_staked(token_id, 0)
    else:
        _set_time_staked(token_id, 0)
    end

    # TRANSFER CRYPT BACK TO OWNER
    IERC721.transferFrom(crypts_address, contract_address, caller, token_id)

    # BURN S_CRYPT
    s_crypts_IERC721.burn(s_crypts_address, token_id)

    # EMIT
    UnSettled.emit(caller, token_id)

    return (TRUE)
end

# TIME_LEFT -> WHEN PLAYER CLAIMS, THIS IS THE REMAINDER TO BE PASSED BACK INTO STORAGE
# THIS ALLOWS FULL DAYS TO BE CLAIMED ONLY AND ALLOWS LESS THAN FULL DAYS TO CONTINUE ACCRUREING
@external
func set_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, time_left : felt
):
    Module.only_approved()
    _set_time_staked(token_id, time_left)
    return ()
end

############
# INTERNAL #
############

func _set_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, time_left : felt
):
    let (block_timestamp) = get_block_timestamp()
    time_staked.write(token_id, block_timestamp - time_left)
    return ()
end

###########
# GETTERS #
###########

@view
func get_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (time : felt):
    let (time) = time_staked.read(token_id)

    return (time=time)
end
