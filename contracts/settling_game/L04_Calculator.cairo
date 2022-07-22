# -----------------------------------
# ____MODULE_L04___CONTRACT_LOGIC
#   This modules focus is to calculate the values of the internal
#   multipliers so other modules can use them. The aim is to have this
#   as the core calculator controller that contains no state.
#   It is pure math.
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_nn_le, is_nn, is_le
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    ModuleIds,
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
    RealmCombatData,
)
from contracts.settling_game.utils.constants import VAULT_LENGTH_SECONDS, BASE_LORDS_PER_DAY
from contracts.settling_game.interfaces.imodules import (
    IModuleController,
    IL01_Settling,
    IL03_Buildings,
    IL06_Combat,
)
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.library.library_calculator import Calculator
from contracts.settling_game.library.library_combat import COMBAT

# -----------------------------------
# Initialize & upgrade
# -----------------------------------

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

# -----------------------------------
# Calculators
# -----------------------------------

@view
func calculate_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    epoch : felt
):
    # CALCULATE EPOCH
    let (controller) = Module.controller_address()
    let (genesis_time_stamp) = IModuleController.get_genesis(controller)
    let (block_timestamp) = get_block_timestamp()

    let (epoch, _) = unsigned_div_rem(block_timestamp - genesis_time_stamp, VAULT_LENGTH_SECONDS)
    return (epoch=epoch)
end

@view
func calculate_happiness{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (happiness : felt):
    alloc_locals

    # FETCH VALUES
    let (population) = calculate_population(token_id)
    let (food) = calculate_food(token_id)

    # GET HAPPINESS
    let (happiness) = Calculator.calculate_happiness(population, food)

    return (happiness)
end

@view
func calculate_troop_population{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (troop_population : felt):
    alloc_locals

    # SUM TOTAL TROOP POPULATION
    # let (controller) = Module.controller_address()
    # let (combat_logic) = IModuleController.get_module_address(controller, ModuleIds.L06_Combat)
    # let (realm_combat_data : RealmCombatData) = IL06_Combat.get_realm_combat_data(
    #     combat_logic, token_id
    # )

    # let (attacking_population) = COMBAT.get_troop_population(realm_combat_data.attacking_squad)
    # let (defending_population) = COMBAT.get_troop_population(realm_combat_data.defending_squad)

    return (0)
end

@view
func calculate_population{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (population : felt):
    alloc_locals

    # SUM TOTAL POPULATION
    let (controller) = Module.controller_address()
    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings
    )
    let (current_buildings : RealmBuildings) = IL03_Buildings.get_effective_buildings(
        buildings_logic_address, token_id
    )

    # TROOP POPULATION
    let (troop_population) = calculate_troop_population(token_id)

    let (realm_population) = Calculator.calculate_population(current_buildings, troop_population)

    return (realm_population)
end

@view
func calculate_food{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (food : felt):
    alloc_locals

    # CALCULATE FOOD
    let (controller) = Module.controller_address()
    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings
    )
    let (current_buildings : RealmBuildings) = IL03_Buildings.get_effective_buildings(
        buildings_logic_address, token_id
    )

    let (troop_population) = calculate_troop_population(token_id)

    let (realm_food) = Calculator.calculate_food(current_buildings, troop_population)

    return (realm_food)
end

# TODO: Make LORDS decrease over time...
@view
func calculate_tribute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tribute : felt
):
    # TOD0: Decreasing supply curve of Lords
    # calculate number of buildings realm has

    return (tribute=BASE_LORDS_PER_DAY)
end

@view
func calculate_wonder_tax{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tax_percentage : felt
):
    alloc_locals

    # CALCULATE WONDER TAX
    let (controller) = Module.controller_address()
    let (settle_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.L01_Settling
    )

    let (realms_settled) = IL01_Settling.get_total_realms_settled(settle_state_address)

    let (less_than_tenth_settled) = is_nn_le(realms_settled, 1600)

    if less_than_tenth_settled == 1:
        return (tax_percentage=25)
    else:
        # TODO:
        # hardcode a max %
        # use basis points
        let (tax, _) = unsigned_div_rem(8000 * 5, realms_settled)
        return (tax_percentage=tax)
    end
end

@view
func calculate_troop_coefficent{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (troop_coefficent : felt):
    alloc_locals
    let (controller) = Module.controller_address()
    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings
    )
    let (current_buildings : RealmBuildings) = IL03_Buildings.get_effective_buildings(
        buildings_logic_address, token_id
    )

    let (troop_coefficent) = Calculator.calculate_troop_coefficient(current_buildings)

    return (troop_coefficent)
end
