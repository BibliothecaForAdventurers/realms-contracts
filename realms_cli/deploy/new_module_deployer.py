from collections import namedtuple
from realms_cli.caller_invoker import wrapped_send, declare
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment

Contracts = namedtuple('Contracts', 'alias contract_name id')

# STEPS
# 0. Set new names in array accordingly to the tuple structure
# 1. Deploy implementation
# 2. Deploy proxy
# 3. Initialise
# 4. Set module id in controller via Arbiter
# 5. Set write access if needed
# 6. Set token contract approval if needed - Resources etc

NEW_MODULES = [
    Contracts("Relics", "Relics", "12"),
    Contracts("Food", "Food", "13"),
]


def run(nre):

    config = Config(nre.network)

    #---------------- SET MODULES  ----------------#

    for contract in NEW_MODULES:
        logged_deploy(
            nre,
            contract.contract_name,
            alias=contract.alias,
            arguments=[],
        )

        declare(contract.contract_name, contract.alias)

        predeclared_class = nre.get_declaration(contract.alias)

        logged_deploy(
            nre,
            'PROXY_Logic',
            alias='proxy_' + contract.alias,
            arguments=[strhex_as_strfelt(predeclared_class)],
        )

    #---------------- INIT MODULES  ----------------#
    for contract in NEW_MODULES:

        module, _ = safe_load_deployment(contract.alias, nre.network)

        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.contract_name,
            function="initializer",
            arguments=[strhex_as_strfelt(
                config.CONTROLLER_ADDRESS), strhex_as_strfelt(config.ADMIN_ADDRESS)],
        )

        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="arbiter",
            function="appoint_contract_as_module",
            arguments=[
                strhex_as_strfelt(module),
                contract.id
            ],
        )

        # wrapped_send(
        #     network=config.nile_network,
        #     signer_alias=config.ADMIN_ALIAS,
        #     contract_alias="arbiter",
        #     function="approve_module_to_module_write_access",
        #     arguments=[6, 1]
        # )
