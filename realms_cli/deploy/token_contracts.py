from collections import namedtuple
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.shared import str_to_felt
from realms_cli.caller_invoker import wrapped_send, declare
import time

Contracts = namedtuple('Contracts', 'alias contract_name')

# token tuples
TOKEN_CONTRACT_IMPLEMENTATIONS = [
    Contracts("lords", "Lords_ERC20_Mintable"),
    Contracts("realms", "Realms_ERC721_Mintable"),
    Contracts("s_realms", "S_Realms_ERC721_Mintable"),
    Contracts("resources", "Resources_ERC1155_Mintable_Burnable"),
]

# Lords
LORDS = str_to_felt("Lords")
LORDS_SYMBOL = str_to_felt("LORDS")
DECIMALS = 18

# Resources
REALMS_RESOURCES = str_to_felt("RealmsResources")

# Realms
REALMS = str_to_felt("Realms")
REALMS_SYMBOL = str_to_felt("REALMS")

# S_Realms
S_REALMS = str_to_felt("S_Realms")
S_REALMS_SYMBOL = str_to_felt("S_REALMS")


def run(nre):

    config = Config(nre.network)

    # implementations
    for contract in TOKEN_CONTRACT_IMPLEMENTATIONS:
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

    # testnet slow, so waiting period of time before calling otherwise these fail
    # this should be much faster on mainnet
    print('🕒 Waiting for deploy before invoking')
    time.sleep(120)

    # init proxies
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="initializer",
        arguments=[
            LORDS,
            LORDS_SYMBOL,
            DECIMALS,
            str(config.INITIAL_LORDS_SUPPLY),
            "0",
            strhex_as_strfelt(config.ADMIN_ADDRESS),
            strhex_as_strfelt(config.ADMIN_ADDRESS),
        ],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_realms",
        function="initializer",
        arguments=[
            REALMS,  # name
            REALMS_SYMBOL,  # ticker
            strhex_as_strfelt(config.ADMIN_ADDRESS),  # contract_owner
        ],
    )
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_s_realms",
        function="initializer",
        arguments=[
            S_REALMS,  # name
            S_REALMS_SYMBOL,  # ticker
            strhex_as_strfelt(config.ADMIN_ADDRESS),  # contract_owner
        ],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_resources",
        function="initializer",
        arguments=[
            REALMS_RESOURCES,
            strhex_as_strfelt(config.ADMIN_ADDRESS),  # contract_owner
        ],
    )

    # logged_deploy(
    #     nre,
    #     "Crypts_ERC721_Mintable",
    #     alias="crypts",
    #     arguments=[
    #         "1234",  # name
    #         "1234",  # ticker
    #         strhex_as_strfelt(config.ADMIN_ADDRESS),  # contract_owner
    #     ],
    # )

    # logged_deploy(
    #     nre,
    #     "S_Crypts_ERC721_Mintable",
    #     alias="s_crypts",
    #     arguments=[
    #         "12345",  # name
    #         "12345",  # ticker
    #         strhex_as_strfelt(config.ADMIN_ADDRESS),  # contract_owner
    #     ],
    # )
