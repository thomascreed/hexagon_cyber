# OT Cybersecurity Compliance Verification Portal

## Overview

This project is a React + Vite portal for semi-automated OT endpoint compliance verification.

It combines:

- **Automated Windows evidence collection** using a read-only PowerShell scanner
- **Manual reviewer overrides** for controls that require human validation or exception handling
- **Structured control-by-control review** across the full portal checklist
- **Printable and downloadable reporting** for audit and compliance workflows

The application is intended for employee or endpoint verification workflows where a browser alone cannot inspect local Windows security settings, but a controlled local scanner can collect evidence and return it to the portal as JSON.

---

## Project Scope

The portal currently includes:

- **192 controls**
- **6 control categories**

### Control Categories

1. BIOS / UEFI Configurations
2. Password Policy Configurations
3. Account Lockout Policy Configurations
4. Log Management Policy Configuration
5. Access Control Management Configurations
6. OS Service Hardening Configurations

Controls are loaded from `src/controls.json`.

---

## Core Features

### Portal UI

- Category-by-category review wizard
- Search within the active category
- Live compliance scoring
- Final review status per control
- Automated status visibility per control
- Manual override support
- Evidence reference field
- Reviewer comments / exception notes
- Offline-capable manual review mode after the portal is loaded once online
- Local draft autosave and restore on the same browser/device

### Automated Scanner Workflow

- Downloadable PowerShell scanner script (`.ps1`)
- Downloadable admin launcher (`.cmd`)
- Upload of generated `compliance-results.json`
- Automatic mapping of scanner IDs to portal control IDs
- Import summary with unmatched scanner IDs if any exist

### Reporting

- Printable report view
- Downloadable text report
- Scanner metadata in report output
- Final and automated status summaries
- Full control-level evidence summary

---

## Repository Structure

```text
.
├── public/
│   └── scanner/
│       ├── ot-compliance-scanner.ps1
│       └── run-ot-compliance-scanner-as-admin.cmd
├── scripts/
│   └── update_controls.py
├── src/
│   ├── controls.json
│   ├── main.jsx
│   ├── scannerConfig.js
│   └── style.css
├── docs/
│   └── Home.md
├── index.html
├── package.json
└── README.md
```

### Important Files

- `src/main.jsx` — main portal UI, upload flow, review workflow, reporting logic
- `src/controls.json` — master control definitions
- `src/scannerConfig.js` — scanner status metadata, runbook, download paths, scanner-to-portal ID mapping
- `public/scanner/ot-compliance-scanner.ps1` — read-only Windows evidence collection script
- `public/scanner/run-ot-compliance-scanner-as-admin.cmd` — admin launcher for the scanner

---

## Local Development

### Prerequisites

- Node.js
- npm
- Windows is recommended for validating the scanner workflow

### Install and Run

```bash
npm install
npm run dev
```

The development server starts on:

- `http://localhost:5173/`

### Offline / PWA Support

The portal now supports an offline-capable manual review workflow.

Key behaviors:

- the browser can cache the portal shell for later offline use
- reviewers can keep reading control instructions while disconnected
- manual statuses, evidence references, comments, employee details, and scan metadata are autosaved locally
- saved drafts are restored automatically on the same browser/device

Operational note:

- the reviewer should open the portal successfully at least once while online so the app shell is cached before going offline

### Build for Production

```bash
npm run build
```

### Preview Production Build

```bash
npm run preview
```

---

## Portal Workflow

### 1. Enter Employee / Device Metadata

The reviewer can enter:

- Employee Name
- Employee ID
- Department
- Device Name
- Asset Tag

### 2. Download the Scanner Files

The portal exposes two downloads:

- `ot-compliance-scanner.ps1`
- `run-ot-compliance-scanner-as-admin.cmd`

These files should remain in the same folder when executed.

### 3. Run the Local Scanner

Recommended method:

1. Download both scanner files
2. Save them in the same folder
3. Right-click `run-ot-compliance-scanner-as-admin.cmd`
4. Choose **Run as administrator**
5. Wait for completion
6. Retrieve `compliance-results.json` from the Desktop

Manual method:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd $env:USERPROFILE\Downloads
.\ot-compliance-scanner.ps1
```

### 4. Upload `compliance-results.json`

When uploaded, the portal:

- validates the JSON structure
- imports scanner results from the `results` array
- normalizes automated statuses
- maps scanner IDs to portal control IDs
- stores scanner metadata such as version, computer name, user name, and scan date

### 5. Review and Override

Each control shows:

- requirement
- how-to-check guidance
- evidence required
- scanner expected value
- scanner actual value
- scanner source
- scanner notes

The reviewer can then:

- accept the automated result
- apply a manual override
- attach an evidence reference
- add comments or exception details

### 6. Generate Final Output

The reviewer can:

- print the report
- download a text report

### 7. Continue Manual Review Offline When Needed

If an employee or reviewer is temporarily disconnected:

1. open the portal once while online on the intended browser/device
2. allow the browser to cache the app shell
3. continue using the portal offline for manual control review
4. read the existing **How to Check** instructions per control
5. enter manual status, evidence reference, and notes
6. rely on local browser autosave until connectivity returns

The offline workflow is primarily intended for manual review scenarios where the user still needs access to the checklist and instructions even without network access.

---

## Automated Status Model

The scanner and portal use the following statuses:

- `pass`
- `fail`
- `manual_review`
- `not_checked`
- `error`

### Interpretation

- **pass** — requirement appears satisfied
- **fail** — requirement appears not satisfied
- **manual_review** — contextual validation is still required
- **not_checked** — no automated or manual result has been applied
- **error** — the scanner could not evaluate the control reliably

Manual overrides always take precedence over the imported scanner status when calculating the final control result.

---

## Scanner Design

### Safety Model

The PowerShell scanner is intentionally **read-only**.

It is designed to:

- read local configuration values
- collect Windows security evidence
- generate a JSON report on the user Desktop

It is explicitly designed **not** to:

- change registry values
- enable or disable services
- reconfigure the system
- write anything except the results file

### Output File

The scanner writes:

- `compliance-results.json`

to the current user's Desktop.

### Output Shape

The generated JSON contains:

- `scannerVersion`
- `computerName`
- `userName`
- `scanDate`
- `results[]`

Each result entry includes:

- `id`
- `control`
- `actualValue`
- `expectedValue`
- `status`
- `source`
- `notes`

### What the Scanner Evaluates

The scanner includes checks across areas such as:

- password policy
- account lockout policy
- audit policy
- log storage sizing
- local account hygiene
- local administrator membership review support
- screen timeout and lock configuration
- service hardening
- SMB settings
- UAC settings
- RDP settings
- PowerShell logging and execution policy
- optional feature hardening

### What Still Requires Manual Review

Some controls cannot be reliably validated from a generic browser or portable scanner alone. These are intentionally flagged for manual validation, including examples such as:

- BIOS / UEFI configuration
- governance and approval workflows
- role-based access review
- service account justification
- MFA applicability
- segregation of duties
- architecture-dependent exceptions

---

## Scanner-to-Portal Mapping

Imported scanner results are mapped to portal controls through `src/scannerConfig.js`.

That file contains:

- scanner download paths
- portal runbook text
- manual override options
- scanner status metadata
- `SCANNER_RESULT_ID_TO_CONTROL_ID`

If scanner IDs change in the PowerShell script, update the mapping table so imports continue to resolve correctly.

---

## Offline Manual Review Support

The portal now includes a lightweight PWA/offline workflow for manual compliance checks.

### What was added

- web app manifest support
- service worker caching for the application shell and scanner download assets
- local draft autosave using browser storage
- automatic draft restoration on the same browser/device
- in-app status messaging for:
  - connection status
  - autosave status
  - offline readiness

### What works offline

After the portal has been opened successfully while online:

- the cached portal can reopen later without internet on that device/browser
- previously loaded control content remains available
- reviewers can manually inspect controls and enter:
  - final status
  - evidence reference
  - comments
  - employee/device metadata
- progress is stored locally in the browser

### What to tell users

- open the portal once while connected before going offline
- use the same browser/device to continue the saved review later
- do not clear browser storage if the local draft must be preserved

### Important scope note

This offline mode is designed primarily for **manual review continuity**. It helps reviewers keep using the portal while disconnected, but it does not replace broader enterprise sync or multi-device draft-sharing workflows.

---

## Reporting Behavior

### Downloaded Text Report

The text report includes:

- employee and device metadata
- scanner metadata
- overall compliance score
- final and automated status counts
- full control-by-control detail

### Printable Report

The printable report renders:

- report header and generation time
- employee and scan metadata
- score summary
- automated/final summary counts
- tabular control detail

---

## Deployment

### Vercel

This project is Vercel-ready.

Typical deployment flow:

1. Push the repository to GitHub
2. Open Vercel
3. Create a new project
4. Import the GitHub repository
5. Deploy

Because the scanner files are stored in `public/scanner/`, they are served as static assets and are downloadable from the deployed portal.

---

## Maintenance Guide

### Updating Controls

If the compliance checklist changes:

1. Update `src/controls.json`
2. Verify category names and control IDs remain consistent
3. Review any dependencies in reporting or mapping logic

### Updating Scanner Result Mappings

If scanner control IDs are added or changed:

1. Update `public/scanner/ot-compliance-scanner.ps1`
2. Update `src/scannerConfig.js`
3. Verify imports still map to the correct portal controls

### Updating UI Behavior

Most application logic lives in:

- `src/main.jsx`

Areas commonly updated there:

- upload parsing
- status calculation
- report generation
- category navigation
- employee metadata capture
- offline draft persistence
- service worker registration and offline readiness messaging

### Styling

Portal styling is defined in:

- `src/style.css`

### Offline Assets

The offline-capable app shell also depends on:

- `public/manifest.webmanifest`
- `public/sw.js`
- `public/icon.svg`

---

## Known Limitations

- The browser itself cannot inspect local Windows security state
- Some controls remain inherently manual or environment-specific
- The scanner is Windows-oriented and not intended for non-Windows endpoints
- Offline access depends on the portal being loaded successfully at least once while online on that browser/device
- Local drafts are stored only in that browser on that device unless a future export/sync feature is added

---

## Recommended Next Improvements

- Add an explicit in-app install prompt for easier PWA installation
- Add offline draft export/import for transferring reviews between devices
- Split the documentation into multiple pages (Architecture, Scanner, Operations, Deployment)
- Add sample `compliance-results.json` documentation or fixture data
- Add test coverage for import parsing, autosave recovery, and report generation logic
- Add versioning for control baselines and scanner schema

---

## Quick Reference

### Start the app

```bash
npm install
npm run dev
```

### Build the app

```bash
npm run build
```

### Scanner files

- `public/scanner/ot-compliance-scanner.ps1`
- `public/scanner/run-ot-compliance-scanner-as-admin.cmd`

### Main source files

- `src/main.jsx`
- `src/scannerConfig.js`
- `src/controls.json`
- `src/style.css`

### Offline support files

- `public/manifest.webmanifest`
- `public/sw.js`
- `public/icon.svg`
