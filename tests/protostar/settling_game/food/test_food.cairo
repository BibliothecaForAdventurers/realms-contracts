%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.settling_game.modules.food.library import Food

from contracts.settling_game.utils.constants import FARM_LENGTH, GENESIS_TIMESTAMP
from contracts.settling_game.utils.game_structs import RealmData, RealmBuildingsIds

from tests.protostar.settling_game.test_structs import (
    TEST_REALM_DATA,
    TEST_HAPPINESS,
    TEST_DAYS,
    TEST_MINT_PERCENTAGE,
)

const UPDATE_TIME = GENESIS_TIMESTAMP - (FARM_LENGTH * 10)

@external
func test_current_relic_holder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (total_farms, remainding_crops, decayed_farms) = Food.calculate_harvest(
        UPDATE_TIME, GENESIS_TIMESTAMP
    )

    assert total_farms = 10

    return ()
end

const STORE_HOUSE_FULL = GENESIS_TIMESTAMP + (FARM_LENGTH * 10)
const STORE_HOUSE_EMPTY = GENESIS_TIMESTAMP - (FARM_LENGTH * 10)
@external
func test_calculate_food_in_store_house{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let (full_store) = Food.calculate_food_in_store_house(STORE_HOUSE_FULL, GENESIS_TIMESTAMP)

    # Assert full
    assert full_store = STORE_HOUSE_FULL - GENESIS_TIMESTAMP

    let (empty_store) = Food.calculate_food_in_store_house(STORE_HOUSE_EMPTY, GENESIS_TIMESTAMP)

    # Assert empty
    assert empty_store = 0

    return ()
end

const AVAILABLE_FOOD = 2000
const POPULATION = 25

@external
func test_calculate_available_food{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let (available_food) = Food.calculate_available_food(AVAILABLE_FOOD, POPULATION)

    # Assert full
    assert available_food = AVAILABLE_FOOD / POPULATION

    return ()
end
