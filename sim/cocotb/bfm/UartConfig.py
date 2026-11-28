# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 11/26/2026
#
# -------------------------------------------------------------------
# Uart Configuration
# -------------------------------------------------------------------

from dataclasses import dataclass


@dataclass
class UartConfig:
    baud: int = 115200
    data_bits: int = 8
    stop_bits: int = 1
    parity: str = "none"
    break_enable: bool = False

    def __post_init__(self):
        """
        Make sure configuration are valid
        """
        if self.baud <= 0:
            raise ValueError("baud must be positive")

        if self.data_bits not in (5, 6, 7, 8):
            raise ValueError("data_bits must be 5, 6, 7, or 8")

        if self.stop_bits not in (1, 2):
            raise ValueError("invalid stop_bits")

        if self.parity not in ("none", "odd", "even", "mark", "space"):
            raise ValueError("invalid parity")
