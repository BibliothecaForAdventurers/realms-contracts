from collections import namedtuple
import struct


def str_to_felt(text: str) -> int:
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")


def felt_to_str(felt: int) -> str:
    b_felt = felt.to_bytes(31, "big")
    return b_felt.decode()


def pack_values(values: list) -> int:
    return int.from_bytes(struct.pack(f"<{len(values)}b", *values), "little")


def uint(a):
    return(a, 0)


def uint_decimal(a):
    x = int(a) * 10 ** 18
    return(x, 0)


def expanded_uint_list(arr):
    """
    Convert array of ints into flattened array of uints.
    """
    return list(sum([uint(a) for a in arr], ()))


def expanded_uint_list_decimals(arr):
    """
    Convert array of ints into flattened array of uints.
    """
    return list(sum([uint_decimal(a) for a in arr], ()))


def from_bn(a):
    """
    Convert 18 decimals into 4 decimals
    """
    return round(int(a, 16) / 1000000000000000000, 4)
