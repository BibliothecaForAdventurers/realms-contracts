# -----------------------------------
# ____Food Library
#   Food
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.cairo.common.math_cmp import is_le

from contracts.settling_game.utils.constants import FARM_LENGTH, MAX_HARVEST_LENGTH
from contracts.settling_game.utils.game_structs import RealmData, RealmBuildingsIds, HarvestType

namespace Food:
    # calculates how many available farms to harvest
    # max of 3 full harvests accure
    # if more farms than MAX, return MAX and decayed farms. How will loose these harvests.
    func calculate_harvest{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        update_time : felt, block_timestamp : felt
    ) -> (total_farms : felt, total_remaining : felt, decayed_farms : felt):
        alloc_locals

        let time_since_update = block_timestamp - update_time

        # TODO add max days can accure
        let (total_farms, remainding_crops) = unsigned_div_rem(time_since_update, FARM_LENGTH)

        let (le_max_farms) = is_le(total_farms, MAX_HARVEST_LENGTH + 1)

        if le_max_farms == TRUE:
            return (total_farms, remainding_crops, 0)
        end

        return (MAX_HARVEST_LENGTH, remainding_crops, total_farms - MAX_HARVEST_LENGTH)
    end

    func calculate_food_in_store_house{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(current_food_supply : felt, block_timestamp : felt) -> (current : felt):
        alloc_locals

        let current = current_food_supply - block_timestamp

        let (is_empty) = is_le(current, 0)

        if is_empty == TRUE:
            return (0)
        end

        return (current)
    end

    # This returns the real value of food available by taking into account the population
    func calculate_available_food{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(current_food_supply : felt, population : felt) -> (available_food : felt):
        alloc_locals

        let (true_food_supply, _) = unsigned_div_rem(current_food_supply, population)

        let (is_empty) = is_le(true_food_supply, 0)

        if is_empty == TRUE:
            return (0)
        end

        return (true_food_supply)
    end

    func assert_ids{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        food_building_id : felt
    ):
        alloc_locals

        # check
        if food_building_id == RealmBuildingsIds.Farm:
            return ()
        end
        if food_building_id == RealmBuildingsIds.FishingVillage:
            return ()
        end

        # fail
        with_attr error_message("FOOD: Incorrect Building ID"):
            assert_not_zero(0)
        end

        return ()
    end

    func assert_harvest_type{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        harvest_type : felt
    ):
        alloc_locals

        # check
        if harvest_type == HarvestType.Export:
            return ()
        end
        if harvest_type == HarvestType.Store:
            return ()
        end

        # fail
        with_attr error_message("FOOD: Incorrect Building ID"):
            assert_not_zero(0)
        end

        return ()
    end
end
