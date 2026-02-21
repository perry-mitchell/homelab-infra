# Homelab Infrastructure Repository

This repository holds publicly visible homelab infrastructure-as-code that is run with private variable inputs (git ignored). The core of the infrastructure is OpenTofu.

## Structure

 * `./applications/harvester` - The primary homelab infrastructure root (OpenTofu).
 * `./applications/k3s` - Legacy homelab infra, deprecated, not to be updated.
 * `./modules` - Legacy modules for OpenTofu - not to be updated. Can be used as reference.
 * `./modules-harvester` - New modules for OpenTofu. Actively used by the harvester cluster.

## Rules

Follow these rules when performing **ANY AND ALL** operations within the bounds of this repository. This includes general questions and seemingly unrelated prompts. **NEVER SKIP ANY STEP HERE FOR ANY REASON**.

 * Never run `tofu apply`, `tofu destroy` or any other `tofu` command that could be considered a write-operation, including anything under `tofu state ...` that isn't `list` or `show`. Only commands like `tofu plan`, `tofu output` etc. are acceptable. When in doubt, ask the user.
 * Mark sensitive values as sensitive, and pay close attention to never hardcode a secret or sensitive value in a manner that may result it in being committed by accident.
 * At the start of ANY plan or build operation, or any conversation for that matter, mention to the user that you've acknowledged these rules by simply saying "I have read and acknowledged the agent rules." - And ensure that you do so.

