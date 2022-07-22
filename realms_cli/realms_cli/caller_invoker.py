import os
import re
import subprocess
import asyncio

from nile.core.account import Account
from nile import deployments
from nile.core.call_or_invoke import call_or_invoke


def send_multi(self, to, method, calldata, nonce=None):
    """Execute a tx going through an Account contract. Inspired from openzeppelin."""
    target_address, _ = next(deployments.load(to, self.network)) or to
    calldata = [[int(x) for x in c] for c in calldata]

    if nonce is None:
        nonce = int(
            call_or_invoke(self.address, "call", "get_nonce", [], self.network)
        )

    (call_array, calldata, sig_r, sig_s) = self.signer.sign_transaction(
        sender=self.address,
        calls=[[target_address, method, c] for c in calldata],
        nonce=nonce,
        max_fee='8989832783197500',
    )

    params = []
    params.append(str(len(call_array)))
    params.extend([str(elem) for sublist in call_array for elem in sublist])
    params.append(str(len(calldata)))
    params.extend([str(param) for param in calldata])
    params.append(str(nonce))

    return call_or_invoke(
        contract=self.address,
        type="invoke",
        method="__execute__",
        params=params,
        network=self.network,
        signature=[str(sig_r), str(sig_s)],
        max_fee='8989832783197500',
    )


# bind it to the account class, needed for signage
Account.send_multi = send_multi


def call(network, contract_alias, function, arguments) -> str:
    """Nile call function."""

    command = [
        "nile",
        "call",
        "--network",
        network,
        contract_alias,
        function,
        *map(str, arguments),
    ]
    return subprocess.check_output(command).strip().decode("utf-8")


async def _call_async(network, contract_alias, function, arguments) -> str:
    """Nile async call function."""

    command = " ".join([
        "nile",
        "call",
        "--network",
        network,
        contract_alias,
        function,
        *map(str, arguments),
    ])
    proc = await asyncio.create_subprocess_shell(
        command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE)

    stdout, stderr = await proc.communicate()

    if stderr:
        print(f'[stderr]\n{stderr.decode()}')
    return stdout.decode()


async def _call_sync_manager(network, contract_alias, function, calldata) -> str:
    """"Helper function to create multiple coroutines."""
    stdout = await asyncio.gather(*[
        _call_async(network, contract_alias, function, arguments)
        for arguments in calldata
    ])

    return stdout


def call_multi(network, contract_alias, function, calldata) -> str:
    """Launches the async call manager to launch a pool of calls."""
    return asyncio.run(_call_sync_manager(network, contract_alias, function, calldata))


def wrapped_call(network, contract_alias, function, arguments) -> str:
    """Send command with some extra functionality such as tx status check and built-in timeout.
    (only supported for non-localhost networks)

    tx statuses:
    RECEIVED -> PENDING -> ACCEPTED_ON_L2
    """
    print("------- CALL ----------------------------------------------------")
    print(f"calling {function} from {contract_alias} with {arguments}")
    out = call(network, contract_alias, function, arguments)
    print("------- CALL ----------------------------------------------------")
    # return out such that it can be prettified at a higher level
    return out


def send(network, signer_alias, contract_alias, function, arguments) -> str:
    """Nile send function."""
    account = Account(signer_alias, network)
    if isinstance(arguments[0], list):
        return account.send_multi(contract_alias, function, arguments)
    return account.send_multi(contract_alias, function, [arguments])


def wrapped_send(network, signer_alias, contract_alias, function, arguments):
    """Send command with some extra functionality such as tx status check and built-in timeout.
    (only supported for non-localhost networks)

    tx statuses:
    RECEIVED -> PENDING -> ACCEPTED_ON_L2
    """
    print("------- SEND ----------------------------------------------------")
    print(f"invoking {function} from {contract_alias} with {arguments}")
    out = send(network, signer_alias, contract_alias, function, arguments)
    _, tx_hash = parse_send(out)
    get_tx_status(network, tx_hash,)
    print("------- SEND ----------------------------------------------------")


def get_tx_status(network, tx_hash: str) -> dict:
    """Returns transaction receipt in dict."""
    command = [
        "nile",
        "debug",
        "--network",
        network,
        tx_hash,
    ]
    out_raw = subprocess.check_output(command).strip().decode("utf-8")
    return out_raw


def parse_send(x):
    """Extract information from send command."""
    # address is 64, tx_hash is 64 chars long
    try:
        address, tx_hash = re.findall("0x[\\da-f]{1,64}", str(x))
        return address, tx_hash
    except ValueError:
        print(f"could not get tx_hash from message {x}")
    return 0x0, 0x0


def deploy(network, alias) -> str:
    """Nile deploy function."""
    command = [
        "nile",
        "deploy",
        alias,
        "--network",
        network,
        "--alias",
        alias,
    ]
    return subprocess.check_output(command).strip().decode("utf-8")


def compile(contract_alias) -> str:
    """Nile call function."""
    command = [
        "nile",
        "compile",
        contract_alias,
    ]
    return subprocess.check_output(command).strip().decode("utf-8")


def declare(contract_name, alias) -> str:
    """Nile declare function."""
    command = [
        "nile",
        "declare",
        contract_name,
        "--alias",
        alias,
    ]
    return subprocess.check_output(command).strip().decode("utf-8")
