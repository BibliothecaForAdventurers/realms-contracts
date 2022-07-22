from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt
import time


def run(nre):

    config = Config(nre.network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="arbiter",
        function="approve_module_to_module_write_access",
        arguments=[6, 1]
    )
