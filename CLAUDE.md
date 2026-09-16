# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Signal-iOS: the iOS client for the Signal messaging app (Objective-C/Swift, AGPLv3). This is a fork of `signalapp/Signal-iOS`; upstream generally does not accept PRs that add features or change UX — only bug fixes to existing behavior.

## Setup & Build

Submodules (`Pods`, and `SignalServiceKit/tests/MessageBackup/Signal-Message-Backup-Tests`) are required — clone with `--recurse-submodules`, or after the fact:

```
make dependencies   # pod-setup + backup-tests-setup + fetch-ringrtc
```

- `.xcode-version` pins the required Xcode version; `Scripts/check_xcode_version.py --relaxed` verifies it (ignores patch version).
- Open `Signal.xcworkspace` (not the `.xcodeproj`) in Xcode. Per-target code signing Team and several Capabilities (Push Notifications, Apple Pay, Communication Notifications, Data Protection) must be reconfigured for a non-Signal developer account — see [BUILDING.md](BUILDING.md).
- `Pods/` is a git submodule, not gitignored — don't `pod install` casually; use `make dependencies` / `bundle exec pod update <name>` (see [MAINTAINING.md](MAINTAINING.md)).
- For personal local build tweaks (e.g. disabling warnings-as-errors), copy `Config/User.xcconfig.sample` to `Config/User.xcconfig` — it's gitignored and conditionally included by `Config/Project.xcconfig`.

## Build & Test from the CLI

```
Scripts/build-and-test.sh
```

Runs `xcodebuild build test` against the latest available iOS Simulator runtime (auto-detected via `xcrun simctl`), with `-disableAutomaticPackageResolution`. Requires `jq` and `xcbeautify` on PATH.

Test targets: `SignalTests`, `SignalServiceKitTests`, `SignalUITests`. To run a single test, pass `-only-testing:<Target>/<Class>/<testMethod>` to `xcodebuild test` (same `-workspace Signal.xcworkspace -scheme Signal` invocation as above).

## Lint / Format

```
Scripts/precommit.py --ref origin/main
```

Applies clang-format (`.m`/`.mm`/`.h`, config in `.clang-format`) and SwiftFormat (`.swift`, config in `.swiftformat`) to files changed vs. the given ref, sorts the `.pbxproj` file, and checks license headers. CI (`precommit.yml`, on PRs) fails if this produces any diff — run it locally before pushing.

## Architecture

- **Signal/** — the app target: UI, app-level features (Calls, ConversationView, Registration, Settings, etc.), organized by feature area.
- **SignalServiceKit/** — the core framework: networking, storage/database, crypto (Axolotl/Signal Protocol), backups, groups, payments. Most business logic lives here, shared across the app, share extension, and NSE.
- **SignalUI/** — shared UI framework (view controllers, media/image editors, pickers) used by `Signal` and other targets.
- **SignalNSE/** — Notification Service Extension (decrypts and displays push notifications).
- **SignalShareExtension/** — the iOS share sheet extension.
- **Pods/** — CocoaPods dependencies, vendored as a git submodule (`signalapp/Signal-Pods`); falls back to `signalapp/Signal-Pods-Private` in CI when the public submodule ref isn't available (see `.github/actions/clone-everything`).
- **Scripts/sds_codegen/** — generates Swift (de)serialization code for `TSYapDatabaseObject` subclasses (the model/storage layer) from parsed Obj-C class declarations; regenerate via `sds_codegen.sh` rather than hand-editing generated files.
- **Scripts/feature_flags_*.py** — generate `SignalServiceKit/Environment/BuildFlags+Generated.swift`, setting `FeatureBuild.current` for non-DEBUG builds (production/beta/internal; `qa` is a deprecated alias for internal). DEBUG builds are always `.dev`. Internal debug tooling (`Settings → Internal`) is gated by `DebugFlags.internalSettings` (`build <= .internal`).
- **fastlane/** — release automation (see `Fastfile`); **ci_scripts/** — Xcode Cloud hooks.

## CI (GitHub Actions)

- `main.yml` — build+test (`Scripts/build-and-test.sh`) on PRs and pushes to `main`/`release/*`, plus a PR-only job checking `Scripts/translation/auto-genstrings` output is up to date.
- `precommit.yml` — runs `Scripts/precommit.py` against changed files (PRs only).
- `debug-ipa.yml` — on push to `main` or manual dispatch, archives an unsigned Debug-configuration build and publishes it as a GitHub prerelease IPA. This intentionally ships with internal debug tooling exposed (e.g. `Settings → Internal → Export Database`) — that's a deliberate choice for this fork, not an oversight.
- Concurrency groups on `push`-triggered workflows should key on `github.head_ref || github.run_id`, not `github.ref` — `github.ref` is constant across pushes to the same branch, so `cancel-in-progress` would silently cancel an earlier still-running job instead of letting it finish (see the comment above `concurrency:` in `main.yml`).
- A release/tag name built from `github.run_number` alone collides on retry — GitHub keeps `run_number` identical across a "re-run failed jobs" (only `run_attempt` changes), so include `github.run_attempt` too if the workflow creates a release/tag.
- `gh run view <run-id>` shows an ANNOTATIONS section — check it before assuming a workflow YAML bug. A job can fail in ~5s for account-level reasons with no code involved: on this fork, paid larger runners (`macos-26-xlarge`, used by upstream's `main.yml` build job) are refused for billing/spending-limit reasons while standard `macos-26` jobs run fine — use `macos-26` for fork-only workflows.
