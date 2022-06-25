
import { deployContract, getDeployedAddressInt, getOwnerAccountInt } from '../../helpers'
import { toFelt } from 'starknet/dist/utils/number'

async function main() {
    const contractName = 'realms_erc721_stakeable'

    // Collect params
    const ownerAccount = getOwnerAccountInt()
    const name: string = toFelt("1234")
    const symbol: string = toFelt("1234")

    // Magically deploy + write all files and stuff 
    await deployContract(contractName, contractName, [name, symbol, ownerAccount])
}

export default main().then(e => console.error(e))