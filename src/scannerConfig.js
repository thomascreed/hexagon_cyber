export const STATUS_META = {
  pass: { label: "Pass", tone: "pass" },
  fail: { label: "Fail", tone: "fail" },
  manual_review: { label: "Manual Review", tone: "manual_review" },
  not_checked: { label: "Not Checked", tone: "not_checked" },
  error: { label: "Error", tone: "error" },
};

export const MANUAL_OVERRIDE_OPTIONS = [
  { value: "", label: "Use automated result" },
  { value: "pass", label: "Pass" },
  { value: "fail", label: "Fail" },
  { value: "manual_review", label: "Manual Review" },
  { value: "not_checked", label: "Not Checked" },
  { value: "error", label: "Error" },
];

export const SCANNER_DOWNLOAD_PATH = "/scanner/ot-compliance-scanner.ps1";
export const SCANNER_ADMIN_LAUNCHER_PATH = "/scanner/run-ot-compliance-scanner-as-admin.cmd";

export const SCANNER_RUNBOOK = [
  "Download both files from this portal: the scanner script (.ps1) and the admin launcher (.cmd).",
  "Save both files in the same folder, normally Downloads.",
  "Right-click run-ot-compliance-scanner-as-admin.cmd and choose Run as administrator.",
  "Approve the Windows UAC prompt if it appears. The scanner will run automatically and create compliance-results.json on the Desktop.",
  "If you prefer the manual method: open Windows PowerShell as Administrator, run Set-ExecutionPolicy -Scope Process Bypass, then run the .ps1 file from Downloads.",
  "Upload the compliance-results.json file generated on the Desktop.",
];

export const SCANNER_RESULT_ID_TO_CONTROL_ID = {
  "2.1.01": "C-001",
  "2.1.02": "C-002",
  "2.1.03": "C-003",
  "2.1.04": "C-004",
  "2.2.01": "C-005",
  "2.2.02": "C-006",
  "2.2.03": "C-007",
  "2.2.05": "C-009",
  "2.3.01": "C-012",
  "2.3.02": "C-013",
  "2.3.03": "C-014",
  "2.4.01": "C-015",
  "2.4.02": "C-016",
  "2.4.03": "C-017",
  "2.4.04": "C-018",
  "2.4.05": "C-019",
  "2.4.06": "C-020",
  "2.4.07": "C-021",
  "2.4.08": "C-022",
  "2.4.09": "C-023",
  "2.4.10": "C-024",
  "2.5.01": "C-025",
  "2.5.02": "C-026",
  "2.5.03": "C-027",
  "2.5.04": "C-028",
  "2.5.05": "C-029",
  "2.5.06": "C-030",
  "2.5.07": "C-031",
  "2.5.08": "C-032",
  "2.5.09": "C-033",
  "2.5.10": "C-034",
  "2.5.11": "C-035",
  "2.5.12": "C-036",
  "2.5.13": "C-037",
  "2.6.94": "C-131",
  "2.6.115": "C-152",
  "2.6.116": "C-153",
  "2.6.118": "C-155",
  "2.6.119": "C-156",
  "2.6.121": "C-158",
  "2.6.122": "C-159",
  "2.6.123": "C-160",
  "2.6.124": "C-161",
  "2.6.125": "C-162",
  "2.6.126": "C-163",
  "2.6.127": "C-164",
  "2.6.128": "C-165",
  "2.6.129": "C-166",
  "2.6.130": "C-167",
  "2.6.133": "C-170",
  "2.6.134": "C-171",
  "2.6.135": "C-172",
  "2.6.136": "C-173",
  "2.6.137": "C-174",
  "2.6.138": "C-175",
  "2.6.153": "C-190",
};

export function resolvePortalControlId(scannerId) {
  return SCANNER_RESULT_ID_TO_CONTROL_ID[scannerId] || scannerId;
}