from collections import namedtuple
from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy, declare
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment

Contracts = namedtuple('Contracts', 'alias contract_name')

# STEPS
# 0. Set new names in array accordingly to the tuple structure
# 1. Deploy implementation
# 2. Deploy proxy
# 3. Initialise
# 4. Set module id in controller via Arbiter
# 5. Set write access if needed
# 6. Set token contract approval if needed - Resources etc

NEW_MODULES = [
    # Contracts("realms", "Realms_ERC721_Mintable"),
    # Contracts("s_realms", "S_Realms_ERC721_Mintable"),
    Contracts("resources", "Resources_ERC1155_Mintable_Burnable"),
]


def run(nre):

    config = Config(nre.network)

    #---------------- SET MODULES  ----------------#

    for contract in NEW_MODULES:
        with open("goerli.deployments.txt", "r+") as f:
            new_f = f.readlines()
            f.seek(0)
            for line in new_f:
                if contract.contract_name + ".json:" + contract.alias not in line:
                    f.write(line)
            f.truncate()

        with open("goerli.declarations.txt", "r+") as f:
            new_f = f.readlines()
            f.seek(0)
            for line in new_f:
                if contract.alias not in line:
                    f.write(line)
            f.truncate()

        compile(contract_alias="contracts/settling_game/tokens/" +
                contract.contract_name + ".cairo")

        logged_deploy(
            nre,
            contract.contract_name,
            alias=contract.alias,
            arguments=[],
        )

        declare(contract.contract_name, contract.alias)

    #---------------- INIT MODULES  ----------------#
    for contract in NEW_MODULES:

        predeclared_class = nre.get_declaration(contract.alias)

        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.alias,
            function="upgrade",
            arguments=[strhex_as_strfelt(predeclared_class)],
        )
