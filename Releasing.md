# Releasing `motoko-core`

Steps to publish a new version of the `core` package:

1. In `mops.toml`, update the `version` field.
2. In `README.md`, update the version shown in the `mops.toml` code snippet (checked by CI).
3. In `Changelog.md`:
   * Update the `## Next` header to the new version, e.g. `## 1.2.3` (checked by CI).
   * Create an empty `## Next` section at the top of the file.
4. Open a PR with the above changes.
5. Create and push a git tag, e.g. `v1.2.3`.
6. Verify that the [`core` Mops package](https://mops.one/core) was published successfully after pushing the tag.
