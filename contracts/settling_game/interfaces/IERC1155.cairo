# Interface for ERC1155 Token
#   A standard interface for contracts that manage multiple token types.
#
# MIT License

%lang starknet
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC1155:
    func balanceOf(owner : felt, token_id : Uint256) -> (balance : Uint256):
    end

    func balanceOfBatch(
        owners_len : felt, owners : felt*, tokens_id_len : felt, tokens_id : Uint256*
    ) -> (balance_len : felt, balance : Uint256*):
    end

    func isApprovedForAll(account : felt, operator : felt) -> (res : felt):
    end

    func setApprovalForAll(operator : felt, approved : felt):
    end

    func safeTransferFrom(_from : felt, to : felt, id : Uint256, amount : Uint256):
    end

    func safeBatchTransferFrom(
        _from : felt,
        to : felt,
        ids_len : felt,
        ids : Uint256*,
        amounts_len : felt,
        amounts : Uint256*,
        data_len : felt,
        data : felt*,
    ):
    end

    func mint(to : felt, id : Uint256, amount : Uint256) -> ():
    end

    func mintBatch(
        to : felt,
        ids_len : felt,
        ids : Uint256*,
        amounts_len : felt,
        amounts : Uint256*,
        data_len : felt,
        data : felt*,
    ) -> ():
    end

    func burn(_from : felt, id : Uint256, amount : Uint256):
    end

    func burnBatch(
        _from : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*
    ):
    end
end
