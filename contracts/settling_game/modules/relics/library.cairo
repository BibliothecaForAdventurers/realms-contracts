# STAKING LIBRARY
#   Helper functions for staking.
#
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.bool import TRUE

namespace Relics:
    # @notice gets current relic holder
    # @implicit syscall_ptr
    # @implicit range_check_ptr
    # @param relic_id: id of relic, pass in realm id
    # @return token_id: returns realm id of owning relic
    func _current_relic_holder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        relic_id : Uint256, holder_id : Uint256
    ) -> (token_id : Uint256):
        alloc_locals

        # If 0 the relic is still in the hands of the owner
        # else realm is in new owner
        let (is_equal) = uint256_eq(holder_id, Uint256(0, 0))

        if is_equal == TRUE:
            return (relic_id)
        end

        return (holder_id)
    end
end
