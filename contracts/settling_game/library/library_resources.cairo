# STAKING LIBRARY
#   Helper functions for staking.
#
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.settling_game.utils.game_structs import (
    RealmData,
    ModuleIds,
    ExternalContractIds,
    Cost,
)
from contracts.settling_game.utils.constants import (
    VAULT_LENGTH,
    DAY,
    BASE_RESOURCES_PER_DAY,
    BASE_LORDS_PER_DAY,
    PILLAGE_AMOUNT,
    MAX_DAYS_ACCURED,
    WORK_HUT_COST,
    WORK_HUT_OUTPUT,
)

namespace Resources:
    # Turns IDS into an Array
    func _calculate_realm_resource_ids{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(realms_data : RealmData) -> (resource_ids : Uint256*):
        alloc_locals

        let (local resource_ids : Uint256*) = alloc()

        # ADD VALUES TO TEMP ARRAY FOR EACH AVAILABLE RESOURCE
        assert resource_ids[0] = Uint256(realms_data.resource_1, 0)

        if realms_data.resource_2 != 0:
            assert resource_ids[1] = Uint256(realms_data.resource_2, 0)
        end

        if realms_data.resource_3 != 0:
            assert resource_ids[2] = Uint256(realms_data.resource_3, 0)
        end

        if realms_data.resource_4 != 0:
            assert resource_ids[3] = Uint256(realms_data.resource_4, 0)
        end

        if realms_data.resource_5 != 0:
            assert resource_ids[4] = Uint256(realms_data.resource_5, 0)
        end

        if realms_data.resource_6 != 0:
            assert resource_ids[5] = Uint256(realms_data.resource_6, 0)
        end

        if realms_data.resource_7 != 0:
            assert resource_ids[6] = Uint256(realms_data.resource_7, 0)
        end

        return (resource_ids)
    end

    # gets the cost to build a workhut on a Realm
    func workhut_costs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        realms_data : RealmData, quantity : felt
    ) -> (resource_ids : Uint256*, resource_values : Uint256*):
        alloc_locals

        let (local resource_ids : Uint256*) = alloc()
        let (local resource_values : Uint256*) = alloc()

        let cost = (WORK_HUT_COST * 10 ** 18) * quantity

        # ADD VALUES TO TEMP ARRAY FOR EACH AVAILABLE RESOURCE
        assert resource_ids[0] = Uint256(realms_data.resource_1, 0)
        assert resource_values[0] = Uint256(cost, 0)

        if realms_data.resource_2 != 0:
            assert resource_ids[1] = Uint256(realms_data.resource_2, 0)
            assert resource_values[1] = Uint256(cost, 0)
        end

        if realms_data.resource_3 != 0:
            assert resource_ids[2] = Uint256(realms_data.resource_3, 0)
            assert resource_values[2] = Uint256(cost, 0)
        end

        if realms_data.resource_4 != 0:
            assert resource_ids[3] = Uint256(realms_data.resource_4, 0)
            assert resource_values[3] = Uint256(cost, 0)
        end

        if realms_data.resource_5 != 0:
            assert resource_ids[4] = Uint256(realms_data.resource_5, 0)
            assert resource_values[4] = Uint256(cost, 0)
        end

        if realms_data.resource_6 != 0:
            assert resource_ids[5] = Uint256(realms_data.resource_6, 0)
            assert resource_values[5] = Uint256(cost, 0)
        end

        if realms_data.resource_7 != 0:
            assert resource_ids[6] = Uint256(realms_data.resource_7, 0)
            assert resource_values[6] = Uint256(cost, 0)
        end

        return (resource_ids, resource_values)
    end

    func _calculate_mintable_resources{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(
        realms_data : RealmData,
        resource_mint_1 : Uint256,
        resource_mint_2 : Uint256,
        resource_mint_3 : Uint256,
        resource_mint_4 : Uint256,
        resource_mint_5 : Uint256,
        resource_mint_6 : Uint256,
        resource_mint_7 : Uint256,
    ) -> (resource_mint_len : felt, resource_mint : Uint256*):
        alloc_locals

        let (local resource_mint : Uint256*) = alloc()

        # ADD VALUES TO TEMP ARRAY FOR EACH AVAILABLE RESOURCE
        assert resource_mint[0] = resource_mint_1

        if realms_data.resource_2 != 0:
            assert resource_mint[1] = resource_mint_2
        end

        if realms_data.resource_3 != 0:
            assert resource_mint[2] = resource_mint_3
        end

        if realms_data.resource_4 != 0:
            assert resource_mint[3] = resource_mint_4
        end

        if realms_data.resource_5 != 0:
            assert resource_mint[4] = resource_mint_5
        end

        if realms_data.resource_6 != 0:
            assert resource_mint[5] = resource_mint_6
        end

        if realms_data.resource_7 != 0:
            assert resource_mint[6] = resource_mint_7
        end

        return (realms_data.resource_number, resource_mint)
    end

    func _calculate_resource_claimable{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(days : felt, tax : felt, output : felt) -> (value : Uint256):
        alloc_locals
        # days * current tax * output
        # we multiply by tax before dividing by 100

        let (total_work_generated, _) = unsigned_div_rem(days * tax * output, 100)

        let work_bn = total_work_generated * 10 ** 18

        with_attr error_message("RESOURCES: work bn greater than"):
            assert_nn(work_bn)
        end

        return (Uint256(work_bn, 0))
    end

    func _calculate_resource_output{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(workhuts : felt, happiness : felt) -> (value : felt):
        alloc_locals

        # Add workhut boost
        let extra_output = workhuts * WORK_HUT_OUTPUT

        # HAPPINESS CHECK
        let (production_output, _) = unsigned_div_rem(BASE_RESOURCES_PER_DAY * happiness, 100)

        return (production_output + extra_output)
    end

    func _calculate_all_resource_output{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(workhuts : felt, happiness : felt, realms_data : RealmData) -> (
        resource_1 : felt,
        resource_2 : felt,
        resource_3 : felt,
        resource_4 : felt,
        resource_5 : felt,
        resource_6 : felt,
        resource_7 : felt,
    ):
        alloc_locals

        let (r_1_output) = _calculate_resource_output(workhuts, happiness)
        let (r_2_output) = _calculate_resource_output(workhuts, happiness)
        let (r_3_output) = _calculate_resource_output(workhuts, happiness)
        let (r_4_output) = _calculate_resource_output(workhuts, happiness)
        let (r_5_output) = _calculate_resource_output(workhuts, happiness)
        let (r_6_output) = _calculate_resource_output(workhuts, happiness)
        let (r_7_output) = _calculate_resource_output(workhuts, happiness)

        return (r_1_output, r_2_output, r_3_output, r_4_output, r_5_output, r_6_output, r_7_output)
    end

    func _calculate_total_mintable_resources{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(
        workhuts : felt,
        happiness : felt,
        realms_data : RealmData,
        days : felt,
        mint_percentage : felt,
    ) -> (resource_mint : Uint256*):
        alloc_locals

        let (
            r_1_output, r_2_output, r_3_output, r_4_output, r_5_output, r_6_output, r_7_output
        ) = _calculate_all_resource_output(workhuts, happiness, realms_data)

        # USER CLAIM
        let (r_1_user) = _calculate_resource_claimable(days, mint_percentage, r_1_output)
        let (r_2_user) = _calculate_resource_claimable(days, mint_percentage, r_2_output)
        let (r_3_user) = _calculate_resource_claimable(days, mint_percentage, r_3_output)
        let (r_4_user) = _calculate_resource_claimable(days, mint_percentage, r_4_output)
        let (r_5_user) = _calculate_resource_claimable(days, mint_percentage, r_5_output)
        let (r_6_user) = _calculate_resource_claimable(days, mint_percentage, r_6_output)
        let (r_7_user) = _calculate_resource_claimable(days, mint_percentage, r_7_output)

        let (_, resource_mint : Uint256*) = _calculate_mintable_resources(
            realms_data, r_1_user, r_2_user, r_3_user, r_4_user, r_5_user, r_6_user, r_7_user
        )

        return (resource_mint)
    end
end
