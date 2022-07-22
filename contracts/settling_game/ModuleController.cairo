# -----------------------------------
# ____MODULE_CONTROLLER___SETTLING_LOGIC
#   A long-lived open-ended lookup table that routes logic between modules.
#   Each module must be registered here and Logic vs State write permissions are mapped here.
#
#  Is in control of the addresses game modules use.
#  Is controlled by the Arbiter, who can update addresses. This will be a Multisig.
#  Maintains a generic mapping that is open ended and which
#  can be added to for new modules.
#
#  To be compliant with this system, a new module containint variables
#  intended to be open to the ecosystem MUST implement a check
#  on any contract.
#  1. Get address attempting to write to the variables in the contract.
#  2. Call 'has_write_access()'
#
# This way, new modules can be added to update existing systems a
# and create new dynamics.
#
# MIT LICENSE
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.bool import TRUE, FALSE

# -----------------------------------
# Storage
# -----------------------------------

@storage_var
func arbiter() -> (address : felt):
end

# The contract address for a module.
@storage_var
func address_of_module_id(module_id : felt) -> (address : felt):
end

# The module id of a contract address.
@storage_var
func module_id_of_address(address : felt) -> (module_id : felt):
end

# A mapping of which modules have write access to the others. 1=yes.
@storage_var
func can_write_to(doing_writing : felt, being_written_to : felt) -> (bool : felt):
end

# NON Module Address Lookup table
@storage_var
func external_contract_table(external_contract_id : felt) -> (address : felt):
end

@storage_var
func genesis() -> (time : felt):
end

# -----------------------------------
# CONSTRUCTOR
# -----------------------------------

# @notice Constructor function
# @param arbiter_address: Arbiter contract address
# @param _lords_address: Lords contract address
# @param _resources_address: Resources contract address
# @param _realms_address: Realms erc721 contract address
# @param _treasury_address: Treasury address
# @param _s_realms_address: Staked realms erc721 contract address
# @param crypts_address: Crypts contract address
# @param _s_crypts_address: Staked crypts contract address
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    arbiter_address : felt,
    _lords_address : felt,
    _resources_address : felt,
    _realms_address : felt,
    _treasury_address : felt,
    _s_realms_address : felt,
):
    arbiter.write(arbiter_address)

    # set genesis
    let (block_timestamp) = get_block_timestamp()
    genesis.write(block_timestamp)

    # write patterns known at deployment. E.g., 1->2, 1->3, 5->6.

    # settling to wonders logic
    can_write_to.write(ModuleIds.L01_Settling, ModuleIds.L05_Wonders, TRUE)

    # resources logic to settling state
    can_write_to.write(ModuleIds.L02_Resources, ModuleIds.L01_Settling, TRUE)

    # resources logic to wonders state
    can_write_to.write(ModuleIds.L02_Resources, ModuleIds.L05_Wonders, TRUE)

    # combat can write to resources
    can_write_to.write(ModuleIds.L06_Combat, ModuleIds.L02_Resources, TRUE)

    # # combat can write to settling
    can_write_to.write(ModuleIds.L06_Combat, ModuleIds.L01_Settling, TRUE)

    # # crypts logic to resources
    # can_write_to.write(ModuleIds.L07_Crypts, ModuleIds.L08_Crypts_Resources, TRUE)

    # # resources logic to crypts state
    # can_write_to.write(ModuleIds.L08_Crypts_Resources, ModuleIds.L07_Crypts, TRUE)

    # Lookup table for NON module contracts
    external_contract_table.write(ExternalContractIds.Lords, _lords_address)
    external_contract_table.write(ExternalContractIds.Realms, _realms_address)
    external_contract_table.write(ExternalContractIds.S_Realms, _s_realms_address)
    # external_contract_table.write(ExternalContractIds.Crypts, _crypts_address)
    # external_contract_table.write(ExternalContractIds.S_Crypts, _s_crypts_address)
    external_contract_table.write(ExternalContractIds.Resources, _resources_address)
    external_contract_table.write(ExternalContractIds.Treasury, _treasury_address)

    return ()
end

############
# EXTERNAL #
############

# @notice Called by the Arbiter to set new address mappings
# @param external_contract_id: External contract id
# @param contract_address: New contract address
@external
func set_address_for_external_contract{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(external_contract_id : felt, contract_address : felt):
    only_arbiter()
    external_contract_table.write(external_contract_id, contract_address)

    return ()
end

# @notice Called by the current Arbiter to replace itself.
# @param new_arbiter: New arbiter contract address
@external
func appoint_new_arbiter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_arbiter : felt
):
    only_arbiter()
    arbiter.write(new_arbiter)
    return ()
end

# @notice Called by the Arbiter to set new address mappings
# @param module_id: Module id
# @param module_address: New module address
@external
func set_address_for_module_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    module_id : felt, module_address : felt
):
    only_arbiter()
    module_id_of_address.write(module_address, module_id)
    address_of_module_id.write(module_id, module_address)

    return ()
end

# @notice Called by the Arbiter to batch set new address mappings on deployment
@external
func set_initial_module_addresses{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(
    module_01_addr : felt,
    module_02_addr : felt,
    module_03_addr : felt,
    module_04_addr : felt,
    module_05_addr : felt,
    module_06_addr : felt,
):
    only_arbiter()

    # Settling Logic
    address_of_module_id.write(ModuleIds.L01_Settling, module_01_addr)
    module_id_of_address.write(module_01_addr, ModuleIds.L01_Settling)

    # Resources Logic
    address_of_module_id.write(ModuleIds.L02_Resources, module_02_addr)
    module_id_of_address.write(module_02_addr, ModuleIds.L02_Resources)

    # Buildings Logic
    address_of_module_id.write(ModuleIds.L03_Buildings, module_03_addr)
    module_id_of_address.write(module_03_addr, ModuleIds.L03_Buildings)

    # Calculator Logic
    address_of_module_id.write(ModuleIds.L04_Calculator, module_04_addr)
    module_id_of_address.write(module_04_addr, ModuleIds.L04_Calculator)

    # Wonders Logic
    address_of_module_id.write(ModuleIds.L05_Wonders, module_05_addr)
    module_id_of_address.write(module_05_addr, ModuleIds.L05_Wonders)

    # Combat Logic
    address_of_module_id.write(ModuleIds.L06_Combat, module_06_addr)
    module_id_of_address.write(module_06_addr, ModuleIds.L06_Combat)

    # # Crypts Logic
    # address_of_module_id.write(ModuleIds.L07_Crypts, module_07_addr)
    # module_id_of_address.write(module_07_addr, ModuleIds.L07_Crypts)

    # # Crypts Resources Logic
    # address_of_module_id.write(ModuleIds.L08_Crypts_Resources, module_08_addr)
    # module_id_of_address.write(module_08_addr, ModuleIds.L08_Crypts_Resources)

    return ()
end

# -----------------------------------
# SETTERS
# -----------------------------------

# @notice Called to authorise write access of one module to another.
# @param module_id_doing_writing: Writer module id
# @param module_id_being_written_to: Module id being written to
@external
func set_write_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    module_id_doing_writing : felt, module_id_being_written_to : felt
):
    only_arbiter()
    can_write_to.write(module_id_doing_writing, module_id_being_written_to, TRUE)
    return ()
end

# -----------------------------------
# GETTERS
# -----------------------------------

# @notice Get module address
# @param module_id: Module id
# @return address: Module address
@view
func get_module_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    module_id : felt
) -> (address : felt):
    return address_of_module_id.read(module_id)
end

# @notice Get external contract address
# @param external_contract_id: External contract id
# @return address: External contract address
@view
func get_external_contract_address{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(external_contract_id : felt) -> (address : felt):
    return external_contract_table.read(external_contract_id)
end

# @notice Get time of deployment
# @return genesis_time: Genesis time
@view
func get_genesis{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    time : felt
):
    return genesis.read()
end

# @notice Get arbiter
# @return Arbiter address
@view
func get_arbiter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    return arbiter.read()
end

# -----------------------------------
# INTERNALS
# -----------------------------------

# @notice Check if a module (caller) has write access to another module
# @param address_attempting_to_write
# @return success: 1 if successful, 0 otherwise
@view
func has_write_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_attempting_to_write : felt
) -> (success : felt):
    alloc_locals

    # Approves the write-permissions between two modules, ensuring
    # first that the modules are both active (not replaced), and
    # then that write-access has been given.

    # Get the address of the module calling (being written to).
    let (caller) = get_caller_address()
    let (module_id_being_written_to) = module_id_of_address.read(caller)

    # Make sure the module has not been replaced.
    let (local current_module_address) = address_of_module_id.read(module_id_being_written_to)

    if current_module_address != caller:
        return (FALSE)
    end

    # Get the module id of the contract that is trying to write.
    let (module_id_attempting_to_write) = module_id_of_address.read(address_attempting_to_write)
    # Make sure that module has not been replaced.
    let (local active_address) = address_of_module_id.read(module_id_attempting_to_write)

    if active_address != address_attempting_to_write:
        return (FALSE)
    end
    # See if the module has permission.
    let (bool) = can_write_to.read(module_id_attempting_to_write, module_id_being_written_to)

    if bool == FALSE:
        return (FALSE)
    end

    return (TRUE)
end

# -----------------------------------
# PRIVATES
# -----------------------------------

# @notice Check if caller is the arbiter
# @dev Reverts if caller is not the arbiter
func only_arbiter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (caller) = get_caller_address()
    let (current_arbiter) = arbiter.read()
    assert caller = current_arbiter
    return ()
end
