# -----------------------------------
# ____Module.Food
#   Logic around Food system
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.utils.constants import BASE_HARVESTS, BASE_FOOD_PRODUCTION
from contracts.settling_game.utils.general import calculate_cost
from contracts.settling_game.utils.game_structs import (
    RealmData,
    ModuleIds,
    ExternalContractIds,
    ResourceIds,
    Cost,
    HarvestType,
    RealmBuildingsIds,
)
from contracts.settling_game.modules.food.library import Food
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from openzeppelin.upgrades.library import Proxy
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.imodules import IL04_Calculator, IL03_Buildings

# -----------------------------------
# Events
# -----------------------------------

# @storage_var
# func Food(token_id : felt) -> (farms_left : felt, last_farm_update : felt):
# end

# -----------------------------------
# Storage
# -----------------------------------

# -------FARMS-------#
@storage_var
func farms_built(token_id : Uint256) -> (farms_built : felt):
end

# each farms build can be harvested X times
@storage_var
func farm_harvests_left(token_id : Uint256) -> (farm_harvests_left : felt):
end

@storage_var
func last_farm_update(token_id : Uint256) -> (last_farm_update : felt):
end

# -------FISHING-------#
@storage_var
func fishing_villages_built(token_id : Uint256) -> (fishing_villages_built : felt):
end

# each farms build can be harvested X times
@storage_var
func fishing_villages_harvests_left(token_id : Uint256) -> (fishing_villages_harvests_left : felt):
end

@storage_var
func last_fishing_villages_update(token_id : Uint256) -> (last_fishing_villages_update : felt):
end

# -------STORE HOUSE-------#
@storage_var
func store_house(token_id : Uint256) -> (available_food : felt):
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

@external
func create{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256, qty : felt, food_building_id : felt):
    alloc_locals
    # check id
    Food.assert_ids(food_building_id)

    # checks
    Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms)

    # contracts
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (realm_data) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    let (owner) = realms_IERC721.ownerOf(s_realms_address, token_id)

    # checks
    if food_building_id == RealmBuildingsIds.Farm:
        let (enough_rivers) = is_le(qty, realm_data.rivers + 1)
        with_attr error_message("FOOD: Not enough Rivers"):
            assert enough_rivers = TRUE
        end
    else:
        let (enough_harbours) = is_le(qty, realm_data.harbours + 1)
        with_attr error_message("FOOD: Not enough Harbours"):
            assert enough_harbours = TRUE
        end
    end

    # set plant time
    let (block_timestamp) = get_block_timestamp()

    # build required building
    if food_building_id == RealmBuildingsIds.Farm:
        last_farm_update.write(token_id, block_timestamp)
        # save number of farms
        farms_built.write(token_id, qty)
        # save harvests
        farm_harvests_left.write(token_id, BASE_HARVESTS)
    else:
        last_fishing_villages_update.write(token_id, block_timestamp)
        # save number of fishing villages
        fishing_villages_built.write(token_id, qty)
        # save harvests
        fishing_villages_harvests_left.write(token_id, BASE_HARVESTS)
    end

    let (buildings_address) = Module.get_module_address(ModuleIds.L03_Buildings)

    # Costs
    let (cost, _) = IL03_Buildings.get_building_cost(buildings_address, food_building_id)
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources)

    let (token_len, token_ids, token_values) = calculate_cost(cost)

    # BURN RESOURCES
    IERC1155.burnBatch(resources_address, owner, token_len, token_ids, token_len, token_values)

    return ()
end

@external
func harvest{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, harvest_type : felt, food_building_id : felt
):
    alloc_locals

    # check id and harvest type
    Food.assert_ids(food_building_id)
    Food.assert_harvest_type(harvest_type)

    # check owner
    Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms)

    # contracts
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms)
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources)
    let (owner) = realms_IERC721.ownerOf(s_realms_address, token_id)

    # farm expirary time
    let (block_timestamp) = get_block_timestamp()

    tempvar total_harvest = 0
    tempvar total_remaining = 0
    tempvar decayed_farms = 0

    # build required building
    if food_building_id == RealmBuildingsIds.Farm:
        let (plant_time) = last_farm_update.read(token_id)
        let (total_harvest, total_remaining, decayed_farms) = Food.calculate_harvest(
            plant_time, block_timestamp
        )
        tempvar total_harvest = total_harvest
        tempvar total_remaining = total_remaining
        tempvar decayed_farms = decayed_farms
    else:
        let (plant_time) = last_fishing_villages_update.read(token_id)
        let (total_harvest, total_remaining, decayed_farms) = Food.calculate_harvest(
            plant_time, block_timestamp
        )
        tempvar total_harvest = total_harvest
        tempvar total_remaining = total_remaining
        tempvar decayed_farms = decayed_farms
    end

    # total food to harvest
    let total_food = total_harvest * BASE_FOOD_PRODUCTION * 10 ** 18

    let (current_harvests) = farm_harvests_left.read(token_id)
    farm_harvests_left.write(token_id, current_harvests - total_harvest - decayed_farms)

    # mint food
    if harvest_type == HarvestType.Export:
        if food_building_id == RealmBuildingsIds.Farm:
            # wheat
            IERC1155.mint(
                resources_address, owner, Uint256(ResourceIds.wheat, 0), Uint256(total_food, 0)
            )
            tempvar syscall_ptr = syscall_ptr
            tempvar range_check_ptr = range_check_ptr
            tempvar pedersen_ptr = pedersen_ptr
        else:
            # fish
            IERC1155.mint(
                resources_address, owner, Uint256(ResourceIds.fish, 0), Uint256(total_food, 0)
            )
            tempvar syscall_ptr = syscall_ptr
            tempvar range_check_ptr = range_check_ptr
            tempvar pedersen_ptr = pedersen_ptr
        end
    else:
        # turn directly into useable food
        convert_to_store(token_id, total_food)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    return ()
end

# -----------------------------------
# INTERNAL
# -----------------------------------

# Convert harvest into storehouse.
func convert_to_store{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, quantity : felt
):
    alloc_locals
    let (block_timestamp) = get_block_timestamp()

    let (current) = food_in_store(token_id)

    store_house.write(token_id, current + quantity + block_timestamp)

    return ()
end

# This is the raw available food if there was no population. This is only used for internal functions.
func food_in_store{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (available : felt):
    alloc_locals
    let (block_timestamp) = get_block_timestamp()

    let (current_food_supply) = store_house.read(token_id)

    let (available) = Food.calculate_food_in_store_house(current_food_supply, block_timestamp)

    return (available)
end

# -----------------------------------
# GETTERS
# -----------------------------------
# This is the available food
# Equals total food / population - each digital population consumes 1 food per second.
@view
func available_food_in_store{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (available : felt):
    alloc_locals

    let (calculator_address) = Module.get_module_address(ModuleIds.L04_Calculator)

    # get raw amount
    let (current) = food_in_store(token_id)

    # get population
    let (population) = IL04_Calculator.calculate_population(calculator_address, token_id)

    # get actual food
    let (available) = Food.calculate_available_food(current, population)

    return (available)
end

# -----------------------------------
# HOOKS
# -----------------------------------

# updates food value to match computed.
# this stops food ever returning to a greater value than what it was
@external
func update_food_hook{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
):
    alloc_locals
    Module.only_approved()

    let (block_timestamp) = get_block_timestamp()

    let (current_food_supply) = available_food_in_store(token_id)

    let (is_empty) = is_le(current_food_supply, 0)

    if is_empty == TRUE:
        store_house.write(token_id, 0)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        store_house.write(token_id, current_food_supply + block_timestamp)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    return ()
end
