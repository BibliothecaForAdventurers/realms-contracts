
import { deployContract, getOwnerAccountInt, setupDeploymentDir, getDeployedAddressInt, getSigner, getAccountContract, sendtx } from '../../helpers'
import { BigNumberish, toBN } from 'starknet/dist/utils/number'
import { Uint256, bnToUint256 } from 'starknet/dist/utils/uint256'
import Data from '../../../data/realms_bit.json'

async function main() {

    const Realms_ERC721_Mintable = getDeployedAddressInt('Realms_ERC721_Mintable');
    const realm: Uint256 = bnToUint256("1")

    const res = await getAccountContract(
        [{
            contractAddress: Realms_ERC721_Mintable,
            entrypoint: "set_realm_data",
            calldata: [realm.low.toString(), realm.high.toString(), '101412048018258352123039691248900']
        }]
    )
}

main()