# Clash for Windows Meta Core Patch

> **Project status: an unofficial modified build/patch for Clash for Windows 0.20.39 on Windows x64.**
>
> This is not an official Clash for Windows release and is not affiliated with or endorsed by Fndroid, MetaCubeX, Z-Siqi, or other upstream authors and contributors.

## Purpose

Clash for Windows is discontinued and its legacy core cannot fully handle some modern configurations and protocols. This project preserves the familiar interface while adapting a modern core and restoring Service, TUN, TAP, Mixin, subscription compatibility, and core update functions.

The project provides client compatibility changes only. It does not provide subscriptions, proxy nodes, accounts, servers, or network services.

## Main features

- Downloads the Windows x64 compatible core from the official MetaCubeX GitHub Release.
- Supports Local Mode, System Proxy, Service Mode, TUN Mode and TAP virtual adapter mode.
- Retains YAML and JavaScript Mixin support.
- Improves compatibility with modern subscription configurations and protocols such as AnyTLS.
- Uses a native Windows UAC helper with a PowerShell fallback.
- Replaces the discontinued application updater with a core updater.
- Displays core update progress inside Clash for Windows.
- Verifies downloads, validates the candidate core and active configuration, creates backups and rolls back failures.
- Includes restore and diagnostic tools.

## What the installer does

The installer performs the following high-level operations:

1. Verifies the selected directory contains `Clash for Windows.exe`.
2. Requests administrator permission for program replacement, Windows service installation and TUN/TAP components.
3. Stops running Clash for Windows, legacy core processes and conflicting legacy services.
4. Backs up the original `app.asar`, unpacked runtime, core and service helper.
5. Installs the modified Electron runtime.
6. Downloads the selected architecture from the official MetaCubeX GitHub Release and verifies SHA-256.
7. Installs the core locally and copies a protected Service Mode copy.
8. Creates a random local service token and applies restrictive Windows ACLs.
9. Removes conflicting legacy `Clash Core Service` service/task entries and installs the local Windows service.
10. Writes local logs and stops on critical failure instead of reporting partial success.

See `SECURITY-TRANSPARENCY.md` for paths and system changes.

## What the installer does not do

The published installer/updater does not intentionally:

- upload subscriptions, nodes, configurations, logs or device information;
- collect telemetry, advertising identifiers or usage analytics;
- create accounts, remote desktop access, remote administration or public control listeners;
- install root certificates, browser extensions, keyloggers, screen capture or file-monitoring components;
- create unrelated startup entries or hidden scheduled tasks;
- disable Microsoft Defender, alter security policies or add firewall rules;
- download cores from unknown mirrors;
- delete user subscriptions, profiles or rules.

These statements apply to this project's installer and updater. Clash for Windows itself changes system network state when the user explicitly enables System Proxy, startup, TUN or TAP features.

## Administrator permission

Administrator permission is required to modify files under Program Files, install/remove a Windows service, apply ACLs, manage TAP devices and run a protected TUN core as SYSTEM. User-triggered privileged operations should display a standard Windows UAC prompt and stop when UAC is cancelled.

## Installation

1. Prepare a Clash for Windows 0.20.39 Windows x64 installation.
2. Exit Clash for Windows completely from the system tray.
3. Extract the release archive into a new folder.
4. Run `install.cmd`.
5. Select the folder containing `Clash for Windows.exe`.
6. Approve Windows UAC.
7. Start Clash for Windows normally.

Do not execute scripts directly from inside the ZIP and do not mix files from different patch versions.

## Restore and diagnostics

- `restore.cmd` removes the patch service and protected core, then restores original files when backups exist.
- `diagnose.cmd` reads local version, process, port and service state and tests only the loopback service endpoint.

User profiles, subscriptions and rules are not deleted by the restore utility.

## Security and privacy

The updater queries official upstream Releases, verifies SHA-256, tests the new core and configuration, creates backups, replaces local and Service Mode copies, restarts the service and rolls back failures. Progress and logs remain local.

Never publish subscription URLs, provider tokens, passwords, private keys, cookies or unredacted configurations in an issue.

## Unofficial and warranty notice

This is an unofficial modified Clash for Windows version. Use of the name identifies the compatibility target and does not imply affiliation, trademark authorization or endorsement.

The software is provided “as is”, without warranties of merchantability, fitness for a particular purpose, continuous availability or error-free operation. Users are responsible for installation, configuration and legal compliance.

## Licensing and third-party material

The license for independently authored installer, updater, diagnostic, elevation-helper and service-helper source is defined in this repository. Modified Clash for Windows runtime files, localization material, Electron/npm dependencies and downloaded third-party cores remain subject to their respective rights holders and upstream licenses. The patch-code license does not relicense third-party files.

Legacy internal identifiers containing `CFW` may remain for backward compatibility; they are not used as the public project name.


## Mihomo core source selection

Version 1.5.4 supports downloading the latest stable `windows-amd64-compatible` core from the official MetaCubeX/mihomo GitHub release or installing a verified local package from `bundled-core`. If the online path fails and a local package is available, the installer offers a local fallback. Every package is checked by SHA-256, executable version and configuration compatibility before replacement.

## Full offline bundle

This Full variant bundles the unmodified official `MetaCubeX/mihomo` v1.19.29 `windows-amd64-compatible` archive in `bundled-core`. Its SHA-256 is `322AAA5957BA9E72AFDDA9B71CC4329F691D2D45EC39E70BBCA3F7BF5AA93D52`.

Mihomo is licensed under GPL-3.0. See `MIHOMO-THIRD-PARTY-NOTICE.md`, `MIHOMO-SOURCE-OFFER.md`, and `LICENSES/MIHOMO-GPL-3.0.txt`. Distributors must ensure the corresponding v1.19.29 source remains available under a GPLv3-compliant distribution method.
