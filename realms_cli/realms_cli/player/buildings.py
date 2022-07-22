# First, import click dependency
import json
import click

from nile.core.account import Account
from ecdsa import SigningKey, SECP256k1

from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import print_over_colums
from realms_cli.binary_converter import map_realm
from realms_cli.shared import uint


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.argument("building_id", nargs=1)
@click.argument("qty", nargs=1)
@click.option("--network", default="goerli")
def build(realm_token_id, building_id, qty, network):
    """
    Build a building
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_L03_Buildings",
        function="build",
        arguments=[
            realm_token_id,                 # uint 1
            0,                              # uint 2
            building_id,
            qty
        ],
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def buildings(realm_token_id, network):
    """
    Get buildings on a Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_L03_Buildings",
        function="get_effective_buildings",
        arguments=[
            realm_token_id,                 # uint 1
            0
        ],
    )
    out = out.split(" ")
    pretty_out = []
    for i, building in enumerate(config.BUILDINGS):
        pretty_out.append(
            f"{building} : {int(out[i])}")
    print("+------------------ BUILDINGS ON REALM ID: " +
          realm_token_id + " ---------------------+")
    print_over_colums(pretty_out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def buildings_integrity(realm_token_id, network):
    """
    Get buildings on a Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_L03_Buildings",
        function="get_buildings_integrity_unpacked",
        arguments=[
            realm_token_id,                 # uint 1
            0
        ],
    )
    out = out.split(" ")
    pretty_out = []
    for i, building in enumerate(config.BUILDINGS):
        pretty_out.append(
            f"{building} : {int(out[i])}")
    print("+------------------ BUILDINGS INTEGRETIY ON REALM ID: " +
          realm_token_id + " ---------------------+")
    print_over_colums(pretty_out)
