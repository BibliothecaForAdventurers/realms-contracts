# BUILDINGS LIBRARY
#   functions for
#
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import assert_250_bit
from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    RealmBuildingsSize,
    BuildingsIntegrityLength,
    BuildingsDecaySlope,
    PackedBuildings,
    RealmBuildingsIds,
    Cost,
)

from contracts.settling_game.utils.constants import DAY, BASE_SQM

from contracts.settling_game.utils.general import unpack_data, transform_costs_to_token_ids_values

from contracts.settling_game.utils.constants import SHIFT_41

namespace Buildings:
    # Checks if you can build on a Realm, reverts if you cannot
    func can_build{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt,
        quantity : felt,
        current_buildings : RealmBuildings,
        cities : felt,
        regions : felt,
    ) -> (can_build : felt):
        alloc_locals

        let (is_less_than_zero) = is_le(quantity, 0)

        if is_less_than_zero == TRUE:
            return (FALSE)
        end

        # Get total buildable units on Realm
        let (buildable_units) = get_realm_buildable_area(cities, regions)

        # Pass current_buildings and return buildable units
        let (current_buildings_sqm) = get_current_built_buildings_sqm(current_buildings)

        # Calculate requested building size
        let (building_size) = get_building_size(building_id)

        let (is_less_than_buildable) = is_le(
            building_size * quantity + current_buildings_sqm, buildable_units
        )

        if is_less_than_buildable == TRUE:
            return (TRUE)
        end

        return (FALSE)
    end

    # gets building size for each
    func get_building_size{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt
    ) -> (buildable_area : felt):
        alloc_locals

        let idx = building_id - 1

        let (type_label) = get_label_location(building_area_sqm)

        return ([type_label + idx])

        building_area_sqm:
        dw RealmBuildingsSize.House  # house
        dw RealmBuildingsSize.StoreHouse  # storehouse
        dw RealmBuildingsSize.Granary  # granary
        dw RealmBuildingsSize.Farm  # farm
        dw RealmBuildingsSize.FishingVillage  # fishing village
        dw RealmBuildingsSize.Barracks  # barracks
        dw RealmBuildingsSize.MageTower  # mage tower
        dw RealmBuildingsSize.ArcherTower  # archer tower
        dw RealmBuildingsSize.Castle  # castle
    end

    # gets buildable area for each
    func get_realm_buildable_area(cities : felt, regions : felt) -> (buildable_area : felt):
        # Get buildable units
        return (cities * regions + BASE_SQM)
    end

    # gets current built buildings
    # pass building struct and return sqm
    func get_current_built_buildings_sqm(current_buildings : RealmBuildings) -> (size : felt):
        # Get buildable units

        let House = current_buildings.House * RealmBuildingsSize.House
        let StoreHouse = current_buildings.StoreHouse * RealmBuildingsSize.StoreHouse
        let Granary = current_buildings.Granary * RealmBuildingsSize.Granary
        let Farm = current_buildings.Farm * RealmBuildingsSize.Farm
        let FishingVillage = current_buildings.FishingVillage * RealmBuildingsSize.FishingVillage
        let Barracks = current_buildings.Barracks * RealmBuildingsSize.Barracks
        let MageTower = current_buildings.MageTower * RealmBuildingsSize.MageTower
        let ArcherTower = current_buildings.ArcherTower * RealmBuildingsSize.ArcherTower
        let Castle = current_buildings.Castle * RealmBuildingsSize.Castle

        let size = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle

        return (size)
    end

    # returns time to add
    func get_integrity_length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        block_timestamp : felt, building_id : felt, quantity : felt
    ) -> (time : felt):
        let (length) = integrity_length(building_id)

        # We add length twice so that there is more than 1 building length
        return (length * quantity + length)
    end

    func integrity_length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt
    ) -> (time : felt):
        let idx = building_id - 1

        let (type_label) = get_label_location(building_integrity_length)

        return ([type_label + idx])

        building_integrity_length:
        dw BuildingsIntegrityLength.House  # house
        dw BuildingsIntegrityLength.StoreHouse  # storehouse
        dw BuildingsIntegrityLength.Granary  # granary
        dw BuildingsIntegrityLength.Farm  # farm
        dw BuildingsIntegrityLength.FishingVillage  # fishing village
        dw BuildingsIntegrityLength.Barracks  # barracks
        dw BuildingsIntegrityLength.MageTower  # mage tower
        dw BuildingsIntegrityLength.ArcherTower  # archer tower
        dw BuildingsIntegrityLength.Castle  # castle
    end

    # Gets raw building time left of building on realm. This is only used for precalulations
    func get_base_building_left{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        time_balance : felt, time_stamp : felt, building_id : felt
    ) -> (buildings : felt, time_left : felt):
        alloc_locals

        let time_left = time_balance - time_stamp
        # if time is negative return 0 meaning no effective buildings
        let (is_less_than_zero_time) = is_le(time_left, 0)

        if is_less_than_zero_time == TRUE:
            return (0, 0)
        end

        let (length) = integrity_length(building_id)

        let (buildings_left, _) = unsigned_div_rem(time_left, length)

        return (buildings_left, time_left)
    end

    func get_decay_slope{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt
    ) -> (slope : felt):
        alloc_locals

        let idx = building_id - 1

        let (type_label) = get_label_location(building_decay_slope_bp)

        return ([type_label + idx])

        building_decay_slope_bp:
        dw BuildingsDecaySlope.House  # house
        dw BuildingsDecaySlope.StoreHouse  # storehouse
        dw BuildingsDecaySlope.Granary  # granary
        dw BuildingsDecaySlope.Farm  # farm
        dw BuildingsDecaySlope.FishingVillage  # fishing village
        dw BuildingsDecaySlope.Barracks  # barracks
        dw BuildingsDecaySlope.MageTower  # mage tower
        dw BuildingsDecaySlope.ArcherTower  # archer tower
        dw BuildingsDecaySlope.Castle  # castle
    end

    # Returns decay rate in bp
    # you must convert to float in order to use
    func get_decay_rate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        buildings_left : felt, decay_slope : felt
    ) -> (decay_rate : felt):
        # divide time left by building decay time
        return (decay_slope * buildings_left)
    end

    func findPowLarger{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        base : felt, exp : felt, currVal : felt, target : felt
    ) -> (exp : felt):
        alloc_locals

        # Getting the next power of the base on this iteration

        local newVal = base * currVal

        assert_250_bit(newVal)

        # This handles flooring scenario

        let (isLe) = is_le(newVal, target)

        if isLe == 1:
            return findPowLarger(base, exp + 1, newVal, target)
        end

        # This handles exact match for base ^ exponent = target

        let (isNotEqual) = is_not_zero(newVal - target)

        if isNotEqual == 0:
            return (exp=exp)
        end

        return (exp=exp)
    end

    # Gets effective buildings on Realm
    func get_effective_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        time_balance : felt, building_id : felt
    ) -> (buildings : felt):
        alloc_locals

        # TODO: log function
        # let (effective_buildings) = findPowLarger(2, 0, 1, time_balance)

        let (length) = integrity_length(building_id)

        # TODO: REMOVE this should be made redundent in favour of the log but log is not working
        let (buildings_left, _) = unsigned_div_rem(time_balance, length)

        return (buildings_left)
    end

    # Effective building time calc
    # This takes in the actual time balance and returns a decayed time
    func get_decayed_building_time{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(time_balance : felt, decay_rate : felt) -> (effective_building_time : felt):
        # Calculate effective building time

        # TODO: Add Max decay to stop overflow
        let (effective_building_time, _) = unsigned_div_rem(
            (10000 - decay_rate) * time_balance, 10000
        )

        return (effective_building_time)
    end

    func calculate_effective_buildings{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(building_id : felt, time_balance : felt, block_timestamp : felt) -> (
        effective_buildings : felt
    ):
        alloc_locals

        let (base_building_number, time_left) = get_base_building_left(
            time_balance, block_timestamp, building_id
        )

        let (decay_slope) = get_decay_slope(building_id)

        # pass slope determined by building
        let (decay_rate) = get_decay_rate(base_building_number, decay_slope)

        # pass actual time balance + decay rate
        let (effective_building_time) = get_decayed_building_time(time_left, decay_rate)

        let (effective_buildings) = get_effective_buildings(effective_building_time, building_id)

        return (effective_buildings)
    end

    func unpack_buildings{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(packed_buildings : PackedBuildings) -> (unpacked_buildings : RealmBuildings):
        alloc_locals

        let (House) = unpack_data(packed_buildings.housing, 0, 2199023255551)
        let (StoreHouse) = unpack_data(packed_buildings.economic, 0, 2199023255551)
        let (Granary) = unpack_data(packed_buildings.economic, 41, 2199023255551)
        let (Farm) = unpack_data(packed_buildings.economic, 82, 2199023255551)
        let (FishingVillage) = unpack_data(packed_buildings.economic, 123, 2199023255551)
        let (Barracks) = unpack_data(packed_buildings.military, 0, 2199023255551)
        let (MageTower) = unpack_data(packed_buildings.military, 41, 2199023255551)
        let (ArcherTower) = unpack_data(packed_buildings.military, 82, 2199023255551)
        let (Castle) = unpack_data(packed_buildings.military, 123, 2199023255551)

        return (
            unpacked_buildings=RealmBuildings(
            House=House,
            StoreHouse=StoreHouse,
            Granary=Granary,
            Farm=Farm,
            FishingVillage=FishingVillage,
            Barracks=Barracks,
            MageTower=MageTower,
            ArcherTower=ArcherTower,
            Castle=Castle,
            ),
        )
    end

    func pack_buildings{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(unpacked_buildings : RealmBuildings) -> (packed_buildings : PackedBuildings):
        # Housing
        let House = unpacked_buildings.House * SHIFT_41._1

        # Economy
        let StoreHouse = unpacked_buildings.StoreHouse * SHIFT_41._1
        let Granary = unpacked_buildings.Granary * SHIFT_41._2
        let Farm = unpacked_buildings.Farm * SHIFT_41._3
        let FishingVillage = unpacked_buildings.FishingVillage * SHIFT_41._4

        # Military
        let Barracks = unpacked_buildings.Barracks * SHIFT_41._1
        let MageTower = unpacked_buildings.MageTower * SHIFT_41._2
        let ArcherTower = unpacked_buildings.ArcherTower * SHIFT_41._3
        let Castle = unpacked_buildings.Castle * SHIFT_41._4

        tempvar housing_value = House

        tempvar economic_value = FishingVillage + Farm + Granary + StoreHouse

        tempvar military_value = Castle + ArcherTower + MageTower + Barracks

        return (
            PackedBuildings(military=military_value, economic=economic_value, housing=housing_value)
        )
    end

    func add_time_to_buildings{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(
        current_buildings : RealmBuildings,
        building_id : felt,
        time_stamp : felt,
        time_to_add : felt,
    ) -> (adjusted_buildings : RealmBuildings):
        alloc_locals

        let (buildings : felt*) = alloc()

        if building_id == RealmBuildingsIds.House:
            let (time) = add_building_integrity(time_stamp, current_buildings.House, time_to_add)
            buildings[0] = time
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        else:
            buildings[0] = current_buildings.House
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        end

        if building_id == RealmBuildingsIds.StoreHouse:
            let (time) = add_building_integrity(
                time_stamp, current_buildings.StoreHouse, time_to_add
            )
            buildings[1] = time
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        else:
            buildings[1] = current_buildings.StoreHouse
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        end

        if building_id == RealmBuildingsIds.Granary:
            let (time) = add_building_integrity(time_stamp, current_buildings.Granary, time_to_add)
            buildings[2] = time
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        else:
            buildings[2] = current_buildings.Granary
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        end

        if building_id == RealmBuildingsIds.Farm:
            let (time) = add_building_integrity(time_stamp, current_buildings.Farm, time_to_add)
            buildings[3] = time
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        else:
            buildings[3] = current_buildings.Farm
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        end

        if building_id == RealmBuildingsIds.FishingVillage:
            let (time) = add_building_integrity(
                time_stamp, current_buildings.FishingVillage, time_to_add
            )
            buildings[4] = time
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        else:
            buildings[4] = current_buildings.FishingVillage
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        end

        if building_id == RealmBuildingsIds.Barracks:
            let (time) = add_building_integrity(time_stamp, current_buildings.Barracks, time_to_add)
            buildings[5] = time
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        else:
            buildings[5] = current_buildings.Barracks
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        end

        if building_id == RealmBuildingsIds.MageTower:
            let (time) = add_building_integrity(
                time_stamp, current_buildings.MageTower, time_to_add
            )
            buildings[6] = time
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        else:
            buildings[6] = current_buildings.MageTower
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        end

        if building_id == RealmBuildingsIds.ArcherTower:
            let (time) = add_building_integrity(
                time_stamp, current_buildings.ArcherTower, time_to_add
            )
            buildings[7] = time
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        else:
            buildings[7] = current_buildings.ArcherTower
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        end

        if building_id == RealmBuildingsIds.Castle:
            let (time) = add_building_integrity(time_stamp, current_buildings.Castle, time_to_add)
            buildings[8] = time
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        else:
            buildings[8] = current_buildings.Castle
            tempvar range_check_ptr = range_check_ptr
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
        end

        return (
            adjusted_buildings=RealmBuildings(
            House=buildings[0],
            StoreHouse=buildings[1],
            Granary=buildings[2],
            Farm=buildings[3],
            FishingVillage=buildings[4],
            Barracks=buildings[5],
            MageTower=buildings[6],
            ArcherTower=buildings[7],
            Castle=buildings[8],
            ),
        )
    end

    # adds to building integritiy time or sets newtime from now
    func add_building_integrity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        block_timestamp : felt, building_integrity_length : felt, time_to_add : felt
    ) -> (new_building_integrity : felt):
        let (is_less_than_zero) = is_le(building_integrity_length, block_timestamp)

        if is_less_than_zero == 1:
            return (block_timestamp + time_to_add)
        end

        return (building_integrity_length + time_to_add)
    end

    func get_unpacked_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        unpacked_buildings : RealmBuildings, building_id : felt
    ) -> (time : felt):
        alloc_locals

        let (buildings : felt*) = alloc()

        # Housing
        buildings[0] = unpacked_buildings.House

        # Economy
        buildings[1] = unpacked_buildings.StoreHouse
        buildings[2] = unpacked_buildings.Granary
        buildings[3] = unpacked_buildings.Farm
        buildings[4] = unpacked_buildings.FishingVillage

        # Military
        buildings[5] = unpacked_buildings.Barracks
        buildings[6] = unpacked_buildings.MageTower
        buildings[7] = unpacked_buildings.ArcherTower
        buildings[8] = unpacked_buildings.Castle

        return (buildings[building_id - 1])
    end

    func calculate_building_cost{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(building_cost : Cost) -> (token_len : felt, token_ids : Uint256*, token_values : Uint256*):
        alloc_locals

        let (costs : Cost*) = alloc()
        assert [costs] = building_cost
        let (token_ids : Uint256*) = alloc()
        let (token_values : Uint256*) = alloc()

        let (token_len) = transform_costs_to_token_ids_values(1, costs, token_ids, token_values)
        return (token_len, token_ids, token_values)
    end
end
