from collections import namedtuple
from realms_cli.deployer import logged_deploy
from realms_cli.caller_invoker import wrapped_send, declare
from realms_cli.shared import str_to_felt
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
import time

Contracts = namedtuple('Contracts', 'alias contract_name')

# token tuples
MODULE_CONTRACT_IMPLEMENTATIONS = [
    Contracts("L01_Settling", "L01_Settling"),
    Contracts("L02_Resources", "L02_Resources"),
    Contracts("L03_Buildings", "L03_Buildings"),
    Contracts("L04_Calculator", "L04_Calculator"),
    Contracts("L05_Wonders", "L05_Wonders"),
    Contracts("L06_Combat", "L06_Combat")
]


def run(nre):

    config = Config(nre.network)

    # logged_deploy(
    #     nre,
    #     "Arbiter",
    #     alias="arbiter",
    #     arguments=[
    #         strhex_as_strfelt(config.ADMIN_ADDRESS),
    #     ],
    # )

    # logged_deploy(
    #     nre,
    #     "xoroshiro128_starstar",
    #     alias="xoroshiro128_starstar",
    #     arguments=[
    #         '0x10AF',
    #     ],
    # )
    # module, _ = safe_load_deployment("arbiter", nre.network)

    # logged_deploy(
    #     nre,
    #     "ModuleController",
    #     alias="moduleController",
    #     arguments=[
    #         strhex_as_strfelt(module),
    #         strhex_as_strfelt(config.LORDS_PROXY_ADDRESS),
    #         strhex_as_strfelt(config.RESOURCES_PROXY_ADDRESS),
    #         strhex_as_strfelt(config.REALMS_PROXY_ADDRESS),
    #         strhex_as_strfelt(config.ADMIN_ADDRESS),
    #         strhex_as_strfelt(config.S_REALMS_PROXY_ADDRESS)
    #     ],
    # )

    # module, _ = safe_load_deployment("moduleController", nre.network)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="arbiter",
    #     function="set_address_of_controller",
    #     arguments=[
    #         strhex_as_strfelt(module),
    #     ]
    # )

    #---------------- IMPLEMENTATIONS  ----------------#
    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
        logged_deploy(
            nre,
            contract.contract_name,
            alias=contract.alias,
            arguments=[],
        )
        declare(contract.contract_name, contract.alias)

    #---------------- PROXY  ----------------#
    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
        predeclared_class = nre.get_declaration(contract.alias)

        logged_deploy(
            nre,
            'PROXY_Logic',
            alias='proxy_' + contract.alias,
            arguments=[strhex_as_strfelt(predeclared_class)],
        )

    # wait 120s - this will reduce on mainnet
    print('🕒 Waiting for deploy before invoking')
    time.sleep(120)

    #---------------- INIT MODULES  ----------------#
    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.contract_name,
            function="initializer",
            arguments=[strhex_as_strfelt(
                config.CONTROLLER_ADDRESS), strhex_as_strfelt(config.ADMIN_ADDRESS)],
        )
