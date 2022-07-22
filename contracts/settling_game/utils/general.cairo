# General Purpose Utilities
#   Utility functions that are used across the project (e.g. compute the unique hash of a list of felts)
#
# MIT License

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.dict import dict_read, dict_write
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.math import assert_le, unsigned_div_rem
from starkware.cairo.common.pow import pow
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import Cost
from contracts.settling_game.utils.pow2 import pow2

const MAX_UINT_PART = 2 ** 128 - 1

# Computes the unique hash of a list of felts.
func list_to_hash{pedersen_ptr : HashBuiltin*, range_check_ptr}(list : felt*, list_len : felt) -> (
    hash : felt
):
    let (list_hash : HashState*) = hash_init()
    let (list_hash : HashState*) = hash_update{hash_ptr=pedersen_ptr}(list_hash, list, list_len)
    return (list_hash.current_hash)
end

# Generic mapping from one range to another.
func scale{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(val_in : felt, in_low : felt, in_high : felt, out_low : felt, out_high : felt) -> (
    val_out : felt
):
    # val_out = ((val_in - in_low) / (in_high - in_low))
    #           * (out_high - out_low) + out_low
    let a = (val_in - in_low) * (out_high - out_low)
    let b = in_high - in_low
    let (c, _) = unsigned_div_rem(a, b)
    let val_out = c + out_low
    return (val_out)
end

# upack data
# parse data, index, mask_size
func unpack_data{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}(data : felt, index : felt, mask_size : felt) -> (score : felt):
    alloc_locals

    # 1. Create a 8-bit mask at and to the left of the index
    # E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    # E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index)
    # 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024 + 2048 = 15
    let mask = mask_size * power

    # 2. Apply mask using bitwise operation: mask AND data.
    let (masked) = bitwise_and(mask, data)

    # 3. Shift element right by dividing by the order of the mask.
    let (result, _) = unsigned_div_rem(masked, power)

    return (score=result)
end

# function takes an array of Cost structs and restructures it into two arrays,
# one holding the resource IDs of tokens and the other the amounts of these tokens
# which can be directly passed into a IERC1155.burnBatch call
# the return value of this function is the length of the token arrays, i.e. the
# count of unique tokens
# the token_ids and token_values argument have to be `alloc()`ed in the calling
# scope:
#
# let (token_ids : Uint256*) = alloc()
# let (token_values : Uint256*) = alloc()
# let (token_len : felt) = transform_costs_to_token_ids_values(costs_len, costs, toekn_ids, token_values)
func transform_costs_to_token_ids_values{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}(costs_len : felt, costs : Cost*, token_ids : Uint256*, token_values : Uint256*) -> (
    tokens : felt
):
    alloc_locals
    # destructure the costs array to two arrays, one
    # holding the IDs of resources and the other one values of resources
    # that are required to build the Troops
    let (resource_ids : felt*) = alloc()
    let (resource_values : felt*) = alloc()
    let (resource_len : felt) = load_resource_ids_and_values_from_costs(
        resource_ids, resource_values, costs_len, costs, 0
    )

    # unify the resources and convert them to a list of Uint256, so that they can
    # be used in a IERC1155 function call
    let (d_len : felt, d : DictAccess*) = sum_values_by_key(
        resource_len, resource_ids, resource_values
    )
    convert_cost_dict_to_tokens_and_values(d_len, d, token_ids, token_values)

    return (d_len)
end

# function takes an array of Cost structs (which hold packed values of
# resource IDs and respective amounts of these resources necessary to build
# something) and unpacks them into two arrays of `ids` and `values` - i.e.
# this func has a side-effect of populating the ids and values arrays;
# it returns the total number of resources as `sum([c.resource_count for c in costs])`
# which is also the length of the ids and values arrays
func load_resource_ids_and_values_from_costs{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}(
    ids : felt*, values : felt*, costs_len : felt, costs : Cost*, cummulative_resource_count : felt
) -> (total_resource_count : felt):
    alloc_locals

    if costs_len == 0:
        return (cummulative_resource_count)
    end

    let current_cost : Cost = [costs]
    load_single_cost_ids_and_values(current_cost, 0, ids, values)

    return load_resource_ids_and_values_from_costs(
        ids + current_cost.resource_count,
        values + current_cost.resource_count,
        costs_len - 1,
        costs + Cost.SIZE,
        cummulative_resource_count + current_cost.resource_count,
    )
end

# helper function for the load_resource_ids_and_values_from_cost
# it works with a single Cost struct, from which it unpacks the packed
# resource IDs and packed resource amounts and appends these to
# the passed in `ids` and `values` array; it recursively calls itself,
# looping through all the resources (resource_count) in the Cost struct
func load_single_cost_ids_and_values{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}(cost : Cost, idx : felt, ids : felt*, values : felt*):
    alloc_locals

    if idx == cost.resource_count:
        return ()
    end

    let (bits_squared) = pow2(cost.bits)
    let (token_id) = unpack_data(cost.packed_ids, cost.bits * idx, bits_squared - 1)
    let (value) = unpack_data(cost.packed_amounts, cost.bits * idx, bits_squared - 1)
    assert [ids + idx] = token_id
    assert [values + idx] = value

    return load_single_cost_ids_and_values(cost, idx + 1, ids, values)
end

# function takes a dictionary where the keys are (ERC1155) token IDs and
# values are the amounts to be bought and populates the passed in `token_ids`
# and `token_values` arrays with Uint256 elements
func convert_cost_dict_to_tokens_and_values{range_check_ptr}(
    len : felt, d : DictAccess*, token_ids : Uint256*, token_values : Uint256*
):
    alloc_locals

    if len == 0:
        return ()
    end

    let current_entry : DictAccess = [d]

    # assuming we will never have token IDs and values with numbers >= 2**128
    with_attr error_message(
            "Token values out of bounds: ID {current_entry.key} value {current_entry.new_value}"):
        assert_le(current_entry.key, MAX_UINT_PART)
        assert_le(current_entry.new_value, MAX_UINT_PART)
    end
    assert [token_ids] = Uint256(low=current_entry.key, high=0)
    assert [token_values] = Uint256(low=current_entry.new_value * 10 ** 18, high=0)

    return convert_cost_dict_to_tokens_and_values(
        len - 1, d + DictAccess.SIZE, token_ids + Uint256.SIZE, token_values + Uint256.SIZE
    )
end

# given two arrays of length `len` which can be though of as key-value mapping split
# into `keys` and `values`, the function computes the sum of values by key
# it returns a Cairo dict
#
# given input
# len = 4
# keys = ["a", "c", "d", "c"]
# values = [2, 2, 2, 2]
#
# the result is
# d_len = 3
# d = {"a": 2, "c": 4, "d": 2}
func sum_values_by_key{range_check_ptr}(len : felt, keys : felt*, values : felt*) -> (
    d_len : felt, d : DictAccess*
):
    alloc_locals

    let (local dict_start : DictAccess*) = default_dict_new(default_value=0)

    let (dict_end : DictAccess*) = sum_values_by_key_loop(dict_start, len, keys, values)

    let (finalized_dict_start, finalized_dict_end) = default_dict_finalize(dict_start, dict_end, 0)

    # figure out the size of the dict, because it's needed to return an array of DictAccess objects
    let ptr_diff = [ap]
    ptr_diff = finalized_dict_end - finalized_dict_start; ap++
    tempvar unique_keys = ptr_diff / DictAccess.SIZE

    return (unique_keys, finalized_dict_start)
end

# helper function for sum_values_by_key, doing the recursive looping
func sum_values_by_key_loop{range_check_ptr}(
    dict : DictAccess*, len : felt, keys : felt*, values : felt*
) -> (dict_end : DictAccess*):
    alloc_locals

    if len == 0:
        return (dict)
    end

    let (current : felt) = dict_read{dict_ptr=dict}(key=[keys])
    let updated = current + [values]
    dict_write{dict_ptr=dict}(key=[keys], new_value=updated)

    return sum_values_by_key_loop(dict, len - 1, keys + 1, values + 1)
end

# calculates cost and returns
func calculate_cost{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(cost : Cost) -> (token_len : felt, token_ids : Uint256*, token_values : Uint256*):
    alloc_locals

    let (costs : Cost*) = alloc()
    assert [costs] = cost
    let (token_ids : Uint256*) = alloc()
    let (token_values : Uint256*) = alloc()

    let (token_len) = transform_costs_to_token_ids_values(1, costs, token_ids, token_values)
    return (token_len, token_ids, token_values)
end
