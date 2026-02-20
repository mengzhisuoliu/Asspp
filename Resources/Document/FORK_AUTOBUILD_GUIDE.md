# Fork Auto-Build Guide

Set up your own fork to automatically track upstream updates, sign iOS builds with your developer certificate, and publish OTA-installable releases via GitHub Pages.

Related files:

- Workflow: `.github/workflows/upstream-signed-ios.yml`
- Input generator: `Resources/Scripts/generate.github.action.inputs.sh`

## 1. Prerequisites

- Paid Apple Developer account
- An `Apple Distribution` certificate (`.p12`) and an `Ad Hoc` provisioning profile (`.mobileprovision`) that includes every target device UDID
- GitHub Actions and GitHub Pages enabled on your fork
- Public repository recommended so OTA install links are accessible

## 2. Repository Permissions

1. Go to `Settings -> Actions -> General -> Workflow permissions` and select **Read and write permissions**
2. Go to `Settings -> Pages` and set **Source** to `GitHub Actions`

## 3. Prepare Signing Assets

Have these files ready (paths are examples):

- `./Certificates/apple_distribution.p12`
- `./Certificates/Asspp_AdHoc.mobileprovision`

## 4. Generate Workflow Inputs (Recommended)

Run the helper script to auto-extract Team ID, Bundle ID, and export method, then produce ready-to-apply secrets and variables:

```bash
./Resources/Scripts/generate.github.action.inputs.sh \
  --p12 ./Certificates/apple_distribution.p12 \
  --p12-password 'your-p12-password' \
  --mobileprovision ./Certificates/Asspp_AdHoc.mobileprovision \
  --ota-base-url https://app.example.com
```

Apply the generated output:

```bash
export GITHUB_REPOSITORY="<owner>/<repo>"
<output-dir>/apply-with-gh.sh
```

Alternatively, copy the values from `<output-dir>/secrets` and `<output-dir>/variables` into GitHub manually.

## 5. Secrets & Variables Reference

### Secrets

| Name                              | Required | Description                                |
| --------------------------------- | -------- | ------------------------------------------ |
| `IOS_CERT_P12_BASE64`             | Yes      | Base64-encoded `.p12` certificate          |
| `IOS_CERT_PASSWORD`               | Yes      | Password used when exporting the `.p12`    |
| `IOS_PROVISIONING_PROFILE_BASE64` | Yes      | Base64-encoded `.mobileprovision`          |
| `IOS_KEYCHAIN_PASSWORD`           | No       | Temporary keychain password on CI runner   |
| `IOS_TEAM_ID`                     | No       | Team ID (auto-read from profile if absent) |

### Variables

| Name                   | Required | Example                   | Description                                          |
| ---------------------- | -------- | ------------------------- | ---------------------------------------------------- |
| `IOS_EXPORT_METHOD`    | No       | `ad-hoc`                  | Export method; defaults to `ad-hoc`                  |
| `IOS_SIGNING_IDENTITY` | No       | `Apple Distribution`      | Auto-selected by export method if empty              |
| `IOS_BUNDLE_ID`        | No       | `wiki.qaq.Asspp`          | Override Bundle ID (must match provisioning profile) |
| `IOS_OTA_BASE_URL`     | No       | `https://app.example.com` | Custom OTA base URL; defaults to GitHub Pages URL    |

## 6. First Run

1. Open `Actions -> Upstream Signed iOS Build`
2. Click **Run workflow**
3. After success, verify:
   - Release: `https://github.com/<owner>/<repo>/releases`
   - Install page: `https://<owner>.github.io/<repo>/ios/latest/install.html`
   - Manifest: `https://<owner>.github.io/<repo>/ios/latest/manifest.plist`

> If the repository is named `<owner>.github.io`, omit `/<repo>` from the URL.

## 7. Daily Usage

- The workflow polls upstream `main` every 30 minutes
- New commits trigger an automatic build, sign, and release
- `ios/latest/install.html` always points to the latest signed build

## 8. Manual Trigger Options

In `Actions -> Upstream Signed iOS Build -> Run workflow`:

| Input           | Values / Example       | Description                                           |
| --------------- | ---------------------- | ----------------------------------------------------- |
| `source_kind`   | `upstream` / `fork`    | Build from upstream or your own fork                  |
| `source_branch` | `main`, `feature/test` | Branch to build                                       |
| `source_repo`   | `Lakr233/Asspp`        | Repository (used when `source_kind=upstream`)         |
| `force_build`   | `true` (default)       | Skip commit-change check; always build when triggered |

Examples:

- Build your fork's `feature/sign-fix`: `source_kind=fork`, `source_branch=feature/sign-fix`
- Build upstream `develop`: `source_kind=upstream`, `source_repo=Lakr233/Asspp`, `source_branch=develop`

## 9. Troubleshooting

| Symptom                      | Fix                                                         |
| ---------------------------- | ----------------------------------------------------------- |
| Install button does nothing  | Open the install page in Safari, not an in-app browser      |
| Install fails immediately    | Device UDID is missing from the Ad Hoc provisioning profile |
| Bundle ID mismatch error     | Ensure `IOS_BUNDLE_ID` matches the App ID in your profile   |
| Page loads but install fails | Confirm `manifest.plist` is publicly accessible over HTTPS  |
