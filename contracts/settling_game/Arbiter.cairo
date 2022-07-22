# -----------------------------------
# ____ARBITER___
#   The Arbiter has authority over the ModuleController.
#   Responsible for deciding how the controller administers authority.
#   Can be replaced by a vote-based module by calling the
#   appoint_new_arbiter() in the ModuleController.
#   Has an Owner, that may itself be a multisig account contract.
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.access.ownable import Ownable

from contracts.settling_game.interfaces.imodules import IModuleController

@storage_var
func controller_address() -> (address : felt):
end

# 1=locked.
@storage_var
func lock() -> (bool : felt):
end

# @notice Constructor function
# @dev Whoever deploys the arbiter sets the only owner
# @param owner: Arbiter address
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt):
    # Whoever deploys the arbiter sets the only owner.
    Ownable.initializer(owner)
    return ()
end

# @notice Invoked to save the address of the Module Controller
# @param contract_address: Address of the Module Controller
@external
func set_address_of_controller{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    contract_address : felt
):
    Ownable.assert_only_owner()
    let (locked) = lock.read()
    # Locked starts as zero
    assert_not_zero(TRUE - locked)
    lock.write(TRUE)

    controller_address.write(contract_address)
    return ()
end

# @notice Invoked to replace the contract that controls the Arbiter
# @param new_arbiter_address: Address of the new arbiter
@external
func replace_self{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_arbiter_address : felt
):
    Ownable.assert_only_owner()
    let (controller) = controller_address.read()
    # The ModuleController has a fixed address. The Arbiter
    # may be upgraded by calling the ModuleController and declaring
    # the new Arbiter.
    IModuleController.appoint_new_arbiter(controller, new_arbiter_address)

    return ()
end

# @notice Invoked to appoint a new owner
# @param new_owner_address: New owner address
@external
func appoint_new_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_owner_address : felt
):
    Ownable.assert_only_owner()
    Ownable.transfer_ownership(new_owner_address)
    return ()
end

# @notice Invoked to approve a deployed module as identified by an ID
# @param module_address: Module address
# @param module_id: Module id
@external
func appoint_contract_as_module{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    module_address : felt, module_id : felt
):
    Ownable.assert_only_owner()
    let (controller) = controller_address.read()
    # Call the ModuleController and enable the new address.
    IModuleController.set_address_for_module_id(controller, module_id, module_address)
    return ()
end

# @notice Invoked to set an external contract
# @param address: External contract address
# @param contract_id: External contract id
@external
func set_external_contract_address{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(address : felt, contract_id : felt):
    Ownable.assert_only_owner()
    let (controller) = controller_address.read()
    # Call the ModuleController and enable the new address.
    IModuleController.set_address_for_external_contract(controller, contract_id, address)
    return ()
end

# @notice Called to authorise write access of one module to another
# @param module_id_doing_writing: Writing module id
# @param module_id_being_written_to: Writee module id
@external
func approve_module_to_module_write_access{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(module_id_doing_writing : felt, module_id_being_written_to : felt):
    Ownable.assert_only_owner()
    let (controller) = controller_address.read()
    IModuleController.set_write_access(
        contract_address=controller,
        module_id_doing_writing=module_id_doing_writing,
        module_id_being_written_to=module_id_being_written_to,
    )
    return ()
end

# @notice Batch set 8 module addresses in one go
# @param module_01_addr: First module address
# @param module_02_addr: Second module adddress
# @param module_03_addr: Third module address
# @param module_04_addr: Fourth module address
# @param module_05_addr: Fifth module address
# @param module_06_addr: Sixth module address
# @param module_07_addr: Seventh module address
# @param module_08_addr: Eight module address
@external
func batch_set_controller_addresses{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(
    module_01_addr : felt,
    module_02_addr : felt,
    module_03_addr : felt,
    module_04_addr : felt,
    module_05_addr : felt,
    module_06_addr : felt,
):
    Ownable.assert_only_owner()
    let (controller) = controller_address.read()
    IModuleController.set_initial_module_addresses(
        controller,
        module_01_addr,
        module_02_addr,
        module_03_addr,
        module_04_addr,
        module_05_addr,
        module_06_addr,
    )
    return ()
end
