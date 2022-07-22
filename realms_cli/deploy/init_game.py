from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config, strhex_as_strfelt


def run(nre):

    config = Config(nre.network)

    # --------- CONTROLLER SETUP Approvals ------- #

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="arbiter",
        function="batch_set_controller_addresses",
        arguments=[
            strhex_as_strfelt(config.L01_SETTLING_PROXY_ADDRESS),
            strhex_as_strfelt(config.L02_RESOURCES_PROXY_ADDRESS),
            strhex_as_strfelt(config.L03_BUILDINGS_PROXY_ADDRESS),
            strhex_as_strfelt(config.L04_CALCULATOR_PROXY_ADDRESS),
            strhex_as_strfelt(config.L05_WONDERS_PROXY_ADDRESS),
            strhex_as_strfelt(config.L06_COMBAT_PROXY_ADDRESS),
        ],
    )

    # --------- L01_SETTLING_PROXY_ADDRESS Approvals ------- #

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_s_realms",
        function="Set_module_access",
        arguments=[
            strhex_as_strfelt(config.L01_SETTLING_PROXY_ADDRESS),
        ]
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_realms",
        function="setApprovalForAll",
        arguments=[
            strhex_as_strfelt(config.L01_SETTLING_PROXY_ADDRESS),
            "1",
        ]
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="approve",
        arguments=[
            strhex_as_strfelt(config.L01_SETTLING_PROXY_ADDRESS),
            str(config.INITIAL_LORDS_SUPPLY), 0
        ]
    )

    # --------- L02_RESOURCES_PROXY_ADDRESS Approvals ------- #

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_resources",
        function="Set_module_access",
        arguments=[
            strhex_as_strfelt(config.L02_RESOURCES_PROXY_ADDRESS),
        ]
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="approve",
        arguments=[
            strhex_as_strfelt(config.L02_RESOURCES_PROXY_ADDRESS),
            str(config.INITIAL_LORDS_SUPPLY), 0
        ]
    )

    # --------- L03_BUILDINGS_PROXY_ADDRESS Approvals ------- #

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="approve",
        arguments=[
            strhex_as_strfelt(config.L03_BUILDINGS_PROXY_ADDRESS),
            str(config.INITIAL_LORDS_SUPPLY), 0
        ]
    )
