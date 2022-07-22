%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub, uint256_eq
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.settling_game.utils.game_structs import (
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
    RealmBuildings,
    RealmBuildingsIds,
    BuildingsIntegrityLength,
    RealmBuildingsSize,
    BuildingsDecaySlope,
)

from contracts.settling_game.utils.constants import (
    VAULT_LENGTH,
    DAY,
    BASE_RESOURCES_PER_DAY,
    BASE_LORDS_PER_DAY,
    PILLAGE_AMOUNT,
    MAX_DAYS_ACCURED,
    WORK_HUT_OUTPUT,
)

from contracts.settling_game.utils.game_structs import RealmData
from contracts.settling_game.library.library_resources import Resources

from tests.protostar.settling_game.test_structs import (
    TEST_REALM_DATA,
    TEST_HAPPINESS,
    TEST_DAYS,
    TEST_MINT_PERCENTAGE,
    TEST_WORK_HUTS,
)

@external
func test_calculate_realm_resource_ids{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let realmData = RealmData(
        TEST_REALM_DATA.REGIONS,
        TEST_REALM_DATA.CITIES,
        TEST_REALM_DATA.HARBOURS,
        TEST_REALM_DATA.RIVERS,
        TEST_REALM_DATA.RESOURCE_NUMBER,
        TEST_REALM_DATA.RESOURCE_1,
        TEST_REALM_DATA.RESOURCE_2,
        TEST_REALM_DATA.RESOURCE_3,
        TEST_REALM_DATA.RESOURCE_4,
        TEST_REALM_DATA.RESOURCE_5,
        TEST_REALM_DATA.RESOURCE_6,
        TEST_REALM_DATA.RESOURCE_7,
        TEST_REALM_DATA.WONDER,
        TEST_REALM_DATA.ORDER,
    )

    let (resource_ids : Uint256*) = Resources._calculate_realm_resource_ids(realmData)

    assert resource_ids[0].low = TEST_REALM_DATA.RESOURCE_1
    assert resource_ids[1].low = TEST_REALM_DATA.RESOURCE_2
    assert resource_ids[2].low = TEST_REALM_DATA.RESOURCE_3
    assert resource_ids[3].low = TEST_REALM_DATA.RESOURCE_4
    assert resource_ids[4].low = TEST_REALM_DATA.RESOURCE_5
    assert resource_ids[5].low = TEST_REALM_DATA.RESOURCE_6
    assert resource_ids[6].low = TEST_REALM_DATA.RESOURCE_7

    return ()
end

@external
func test_calculate_mintable_resources{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let realmData = RealmData(
        TEST_REALM_DATA.REGIONS,
        TEST_REALM_DATA.CITIES,
        TEST_REALM_DATA.HARBOURS,
        TEST_REALM_DATA.RIVERS,
        TEST_REALM_DATA.RESOURCE_NUMBER,
        TEST_REALM_DATA.RESOURCE_1,
        TEST_REALM_DATA.RESOURCE_2,
        TEST_REALM_DATA.RESOURCE_3,
        TEST_REALM_DATA.RESOURCE_4,
        TEST_REALM_DATA.RESOURCE_5,
        TEST_REALM_DATA.RESOURCE_6,
        TEST_REALM_DATA.RESOURCE_7,
        TEST_REALM_DATA.WONDER,
        TEST_REALM_DATA.ORDER,
    )

    let resource_mint = Uint256(1000, 0)

    let (_, all_resources_mint : Uint256*) = Resources._calculate_mintable_resources(
        realmData,
        resource_mint,
        resource_mint,
        resource_mint,
        resource_mint,
        resource_mint,
        resource_mint,
        resource_mint,
    )

    let (is_equal) = uint256_eq(all_resources_mint[0], resource_mint)

    assert is_equal = 1

    return ()
end

@external
func test_calculate_resource_claimable{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let (value) = Resources._calculate_resource_claimable(TEST_DAYS, TEST_MINT_PERCENTAGE, 100)

    let work_bn = 2 * 100 * 10 ** 18

    let (is_equal) = uint256_eq(value, Uint256(work_bn, 0))

    assert is_equal = 1

    return ()
end

@external
func test_calculate_resource_output{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let (value) = Resources._calculate_resource_output(TEST_WORK_HUTS, TEST_HAPPINESS)

    let (production_output, _) = unsigned_div_rem(BASE_RESOURCES_PER_DAY * TEST_HAPPINESS, 100)

    assert value = production_output + TEST_WORK_HUTS * WORK_HUT_OUTPUT

    return ()
end

@external
func test_calculate_total_mintable_resources{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let realmData = RealmData(
        TEST_REALM_DATA.REGIONS,
        TEST_REALM_DATA.CITIES,
        TEST_REALM_DATA.HARBOURS,
        TEST_REALM_DATA.RIVERS,
        TEST_REALM_DATA.RESOURCE_NUMBER,
        TEST_REALM_DATA.RESOURCE_1,
        TEST_REALM_DATA.RESOURCE_2,
        TEST_REALM_DATA.RESOURCE_3,
        TEST_REALM_DATA.RESOURCE_4,
        TEST_REALM_DATA.RESOURCE_5,
        TEST_REALM_DATA.RESOURCE_6,
        TEST_REALM_DATA.RESOURCE_7,
        TEST_REALM_DATA.WONDER,
        TEST_REALM_DATA.ORDER,
    )

    let (resource_mint : Uint256*) = Resources._calculate_total_mintable_resources(
        TEST_WORK_HUTS, TEST_HAPPINESS, realmData, TEST_DAYS, TEST_MINT_PERCENTAGE
    )

    let resource_1 = resource_mint[0].low

    %{ print('Resource Mint:', ids.resource_1) %}

    return ()
end
