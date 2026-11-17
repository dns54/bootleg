<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Security

What bootleg does to protect the machine, and how to harden it further.

bootleg has no hardware root of trust: Boot Guard is bypassed, so measured boot is only as strong
as the flash write protection.

## Secure Boot

Default: Microsoft keys enrolled, Secure Boot off.

### Own keys

1. `systemctl reboot --firmware-setup` (or Esc at boot) → System Configuration → Secure Boot Configuration
2. Secure Boot Mode: **Custom Mode** → **Enter Setup Mode** → confirm
3. Boot the OS and enroll
4. Secure Boot turns on once a PK is enrolled

- Custom Mode lasts only while in setup; Standard Mode before booting anything (no physical-presence check)
- **Reset Secure Boot Keys**: Microsoft's keys back, Secure Boot stays on. To boot an OS signed with
  own keys: untick **Attempt Secure Boot** (F10), or enroll the keys again

## Flash protection

| Layer | Protects | Lifted by |
|---|---|---|
| Descriptor master locks | Descriptor and ME region, against the CPU, also SMM | Board's descriptor override (service jumper) |
| **BIOS Lock** (setup → Security, default on) | BIOS region: SMM-only writes, so EFI variables and capsules still work | Off in setup |
| Kernel lockdown (`lockdown=integrity`) | Raw hardware access from root: `/dev/mem`, I/O ports, SMM handler, flashprog | Booting without it |

- Always on: SPI configuration lock, BIOS interface lock, SMI lock, SMRAM lock

### Known weakness

- SMMSTORE accepts writes from any kernel code: root can rewrite raw EFI variables (BIOS Lock,
  Secure Boot keys) for the next boot. Dasharo and MrChromebox builds have the same weakness
- Mitigation: Secure Boot + kernel lockdown. Changed options show in PCR1, Secure Boot variables in PCR7

## Hardening

1. Administrator password in setup
2. BIOS Lock on
3. Secure Boot with own keys
4. Kernel `lockdown=integrity`
5. Seal disk keys to PCRs 1 and 7: `systemd-cryptenroll --tpm2-pcrs=1+7`

## TPM and measured boot

- coreboot and EDK2 each measure their own part; the OS sees one combined event log
  ([Dasharo PCR measurements](https://docs.dasharo.com/kb/pcr-measurements/))
- Banks: every active bank coreboot can hash (SHA-1, SHA-256). Others (SHA-384/512) don't replay
- TPM bank selection left alone

| PCR | Extra measurements |
|---|---|
| 1 | Every setup option (`EV_EFI_VARIABLE_DRIVER_CONFIG`, name order), chassis intrusion, RTC power lost |
| 7 | Secure Boot variables |

- Platform hierarchy: random password after physical-presence requests. Owner and lockout operations unaffected
