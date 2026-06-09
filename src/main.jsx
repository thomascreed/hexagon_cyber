import React, { useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  ShieldCheck,
  Printer,
  Download,
  Search,
  ChevronRight,
  ChevronLeft,
  Upload,
  Cpu,
  CheckCircle2,
  XCircle,
  TriangleAlert,
  Info,
} from "lucide-react";
import controls from "./controls.json";
import {
  STATUS_META,
  MANUAL_OVERRIDE_OPTIONS,
  SCANNER_DOWNLOAD_PATH,
  SCANNER_ADMIN_LAUNCHER_PATH,
  SCANNER_RUNBOOK,
  resolvePortalControlId,
} from "./scannerConfig";
import "./style.css";

const CONTROL_LOOKUP = new Map(controls.map((control) => [control.id, control]));
const EMPTY_ANSWER = {
  manualStatus: "",
  comments: "",
  evidence: "",
  scanner: null,
};

function groupByCategory(items) {
  return items.reduce((acc, item) => {
    const key = item.category || "Security Controls";
    if (!acc[key]) acc[key] = [];
    acc[key].push(item);
    return acc;
  }, {});
}

function ensureAnswer(answer) {
  return {
    ...EMPTY_ANSWER,
    ...(answer || {}),
    scanner: answer?.scanner || null,
  };
}

function getEffectiveStatus(answer) {
  return answer?.manualStatus || answer?.scanner?.status || "not_checked";
}

function getStatusLabel(status) {
  return STATUS_META[status]?.label || status || "Not Checked";
}

function getStatusIcon(status) {
  switch (status) {
    case "pass":
      return CheckCircle2;
    case "fail":
      return XCircle;
    case "manual_review":
    case "error":
      return TriangleAlert;
    case "not_checked":
    default:
      return Info;
  }
}

function normalizeScannerResult(result) {
  const rawStatus = String(result?.status || "").toLowerCase();
  const status = STATUS_META[rawStatus] ? rawStatus : "error";

  return {
    scannerId: String(result?.id || ""),
    control: String(result?.control || ""),
    actualValue: String(result?.actualValue || ""),
    expectedValue: String(result?.expectedValue || ""),
    status,
    source: String(result?.source || ""),
    notes: String(result?.notes || ""),
  };
}

function formatDate(value) {
  if (!value) return "N/A";
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? value : parsed.toLocaleString();
}

function StatusBadge({ status, label, subtle = false }) {
  const Icon = getStatusIcon(status);
  return (
    <span className={`statusBadge status-${status} ${subtle ? "subtle" : ""}`}>
      <Icon size={14} />
      {label || getStatusLabel(status)}
    </span>
  );
}

function App() {
  const grouped = useMemo(() => groupByCategory(controls), []);
  const categories = Object.keys(grouped);

  const [step, setStep] = useState(0);
  const [answers, setAnswers] = useState({});
  const [search, setSearch] = useState("");
  const [employee, setEmployee] = useState({
    name: "",
    employeeId: "",
    department: "",
    deviceName: "",
    assetTag: "",
  });
  const [scanInfo, setScanInfo] = useState(null);
  const [uploadFeedback, setUploadFeedback] = useState(null);

  const currentCategory = categories[step] || "";
  const currentControls = grouped[currentCategory] || [];

  const filteredControls = currentControls.filter((control) => {
    const query = search.toLowerCase().trim();
    return !query || [control.id, control.control, control.requirement, control.howToCheck].join(" ").toLowerCase().includes(query);
  });

  const portalCounts = useMemo(() => {
    const base = { pass: 0, fail: 0, manual_review: 0, not_checked: 0, error: 0 };
    controls.forEach((control) => {
      const status = getEffectiveStatus(answers[control.id]);
      base[status] += 1;
    });
    return base;
  }, [answers]);

  const automatedCounts = useMemo(() => {
    const base = { pass: 0, fail: 0, manual_review: 0, not_checked: 0, error: 0 };
    Object.values(answers).forEach((answer) => {
      if (answer?.scanner?.status) {
        base[answer.scanner.status] += 1;
      }
    });
    return base;
  }, [answers]);

  const total = controls.length;
  const completed = total - portalCounts.not_checked;
  const score = total ? Math.round((portalCounts.pass / total) * 100) : 0;

  function updateAnswer(id, update) {
    setAnswers((prev) => ({
      ...prev,
      [id]: {
        ...ensureAnswer(prev[id]),
        ...update,
      },
    }));
  }

  async function handleScanUpload(event) {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      const text = await file.text();
      const payload = JSON.parse(text);

      if (!payload || !Array.isArray(payload.results)) {
        throw new Error("Uploaded JSON must contain a top-level results array.");
      }

      const unmatchedIds = [];
      const matchedControlIds = [];
      const imported = {};

      payload.results.forEach((rawResult) => {
        const normalized = normalizeScannerResult(rawResult);
        const controlId = resolvePortalControlId(normalized.scannerId);

        if (!CONTROL_LOOKUP.has(controlId)) {
          unmatchedIds.push(normalized.scannerId || "(missing id)");
          return;
        }

        matchedControlIds.push(controlId);
        imported[controlId] = normalized;
      });

      setAnswers((prev) => {
        const next = { ...prev };
        Object.entries(imported).forEach(([controlId, scanner]) => {
          next[controlId] = {
            ...ensureAnswer(prev[controlId]),
            scanner,
          };
        });
        return next;
      });

      setScanInfo({
        scannerVersion: payload.scannerVersion || "Unknown",
        computerName: payload.computerName || "Unknown",
        userName: payload.userName || "Unknown",
        scanDate: payload.scanDate || "",
        importedCount: matchedControlIds.length,
        unmatchedIds,
        fileName: file.name,
      });

      setUploadFeedback({
        tone: unmatchedIds.length ? "manual_review" : "pass",
        message: unmatchedIds.length
          ? `Imported ${matchedControlIds.length} results. ${unmatchedIds.length} scanner IDs did not match portal controls.`
          : `Imported ${matchedControlIds.length} automated results successfully.`,
      });
    } catch (error) {
      setUploadFeedback({
        tone: "error",
        message: error.message || "Failed to parse uploaded JSON file.",
      });
    } finally {
      event.target.value = "";
    }
  }

  function downloadReport() {
    const report = buildReportText({
      employee,
      controls,
      answers,
      score,
      portalCounts,
      automatedCounts,
      scanInfo,
    });

    const blob = new Blob([report], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = `ot-compliance-report-${employee.deviceName || scanInfo?.computerName || "device"}.txt`;
    anchor.click();
    URL.revokeObjectURL(url);
  }

  function printReport() {
    window.print();
  }

  return (
    <div className="app">
      <aside className="sidebar no-print">
        <div className="brand">
          <div className="brandIcon">
            <ShieldCheck size={28} />
          </div>
          <div>
            <h1>OT Cybersecurity</h1>
            <p>Semi-Automated Compliance Verification Portal</p>
          </div>
        </div>

        <div className="progressCard">
          <div className="score">{score}%</div>
          <div>
            <strong>Overall Compliance Score</strong>
            <p>
              {completed} of {total} controls resolved
            </p>
          </div>
        </div>

        <div className="miniStats">
          <span className="pass">Pass: {portalCounts.pass}</span>
          <span className="fail">Fail: {portalCounts.fail}</span>
          <span className="manual_review">Manual Review: {portalCounts.manual_review}</span>
          <span className="not_checked">Not Checked: {portalCounts.not_checked}</span>
          <span className="error">Error: {portalCounts.error}</span>
        </div>

        <nav>
          {categories.map((category, index) => {
            const categoryControls = grouped[category];
            const done = categoryControls.filter((control) => getEffectiveStatus(answers[control.id]) !== "not_checked").length;

            return (
              <button key={category} className={index === step ? "active" : ""} onClick={() => setStep(index)}>
                <span>{category}</span>
                <small>
                  {done}/{categoryControls.length}
                </small>
              </button>
            );
          })}
        </nav>
      </aside>

      <main className="main">
        <section className="hero no-print">
          <div>
            <h2>Employee Device Verification</h2>
            <p>
              Combine automated scanner evidence with manual overrides, employee comments, and printable reporting for OT endpoint compliance reviews.
            </p>
          </div>
          <div className="actions">
            <button onClick={downloadReport}>
              <Download size={16} /> Download Report
            </button>
            <button onClick={printReport}>
              <Printer size={16} /> Print Report
            </button>
          </div>
        </section>

        <section className="employeeCard no-print">
          <input placeholder="Employee Name" value={employee.name} onChange={(event) => setEmployee({ ...employee, name: event.target.value })} />
          <input placeholder="Employee ID" value={employee.employeeId} onChange={(event) => setEmployee({ ...employee, employeeId: event.target.value })} />
          <input placeholder="Department" value={employee.department} onChange={(event) => setEmployee({ ...employee, department: event.target.value })} />
          <input placeholder="Device Name" value={employee.deviceName} onChange={(event) => setEmployee({ ...employee, deviceName: event.target.value })} />
          <input placeholder="Asset Tag" value={employee.assetTag} onChange={(event) => setEmployee({ ...employee, assetTag: event.target.value })} />
        </section>

        <section className="scanPanel no-print">
          <div className="scanHeader">
            <div>
              <p className="eyebrow">Automated Scan</p>
              <h3>Download, run, and upload the local compliance scanner</h3>
              <p className="mutedText">
                The browser portal cannot directly inspect Windows security settings. Use the read-only PowerShell scanner to collect local evidence, then upload the generated JSON file here.
              </p>
            </div>
            <div className="actions">
              <a className="downloadLink" href={SCANNER_DOWNLOAD_PATH} download>
                <Download size={16} /> Download Scanner Script (.ps1)
              </a>
              <a className="downloadLink" href={SCANNER_ADMIN_LAUNCHER_PATH} download>
                <Download size={16} /> Download Admin Launcher (.cmd)
              </a>
            </div>
          </div>

          <div className="scanContent">
            <div className="scanInstructions">
              <h4>Runbook</h4>
              <ol>
                {SCANNER_RUNBOOK.map((stepText) => (
                  <li key={stepText}>{stepText}</li>
                ))}
              </ol>
            </div>

            <div className="scanUploader">
              <h4>Upload compliance-results.json</h4>
              <label className="uploadBox">
                <Upload size={18} />
                <span>Select scanner JSON file</span>
                <input type="file" accept=".json,application/json" onChange={handleScanUpload} />
              </label>

              {uploadFeedback && (
                <div className={`feedbackBox status-${uploadFeedback.tone}`}>
                  <StatusBadge status={uploadFeedback.tone} />
                  <p>{uploadFeedback.message}</p>
                </div>
              )}

              <div className="commandBlock">
                <code>Recommended: right-click run-ot-compliance-scanner-as-admin.cmd &gt; Run as administrator</code>
                <code>The command window should stay open, run the scan, then show a success or error message</code>
                <code>Set-ExecutionPolicy -Scope Process Bypass</code>
                <code>cd $env:USERPROFILE\Downloads</code>
                <code>.\ot-compliance-scanner.ps1</code>
              </div>
            </div>
          </div>
        </section>

        <section className="summaryGrid no-print">
          <article className="summaryCard">
            <div className="summaryTitle">
              <Cpu size={18} />
              <h4>Scanner Metadata</h4>
            </div>
            <div className="metaList compact">
              <p><strong>Scanner Version:</strong> {scanInfo?.scannerVersion || "Not uploaded"}</p>
              <p><strong>Computer Name:</strong> {scanInfo?.computerName || "Not uploaded"}</p>
              <p><strong>User Name:</strong> {scanInfo?.userName || "Not uploaded"}</p>
              <p><strong>Scan Date:</strong> {formatDate(scanInfo?.scanDate)}</p>
              <p><strong>Imported Results:</strong> {scanInfo?.importedCount || 0}</p>
              <p><strong>Uploaded File:</strong> {scanInfo?.fileName || "N/A"}</p>
              {scanInfo?.unmatchedIds?.length ? <p><strong>Unmatched IDs:</strong> {scanInfo.unmatchedIds.join(", ")}</p> : null}
            </div>
          </article>

          <article className="summaryCard">
            <div className="summaryTitle">
              <ShieldCheck size={18} />
              <h4>Automated Check Summary</h4>
            </div>
            <div className="summaryStats">
              <StatusBadge status="pass" label={`Pass: ${automatedCounts.pass}`} subtle />
              <StatusBadge status="fail" label={`Fail: ${automatedCounts.fail}`} subtle />
              <StatusBadge status="manual_review" label={`Manual Review: ${automatedCounts.manual_review}`} subtle />
              <StatusBadge status="not_checked" label={`Not Checked: ${automatedCounts.not_checked}`} subtle />
              <StatusBadge status="error" label={`Error: ${automatedCounts.error}`} subtle />
            </div>
          </article>

          <article className="summaryCard">
            <div className="summaryTitle">
              <Info size={18} />
              <h4>Final Review Summary</h4>
            </div>
            <div className="summaryStats">
              <StatusBadge status="pass" label={`Pass: ${portalCounts.pass}`} subtle />
              <StatusBadge status="fail" label={`Fail: ${portalCounts.fail}`} subtle />
              <StatusBadge status="manual_review" label={`Manual Review: ${portalCounts.manual_review}`} subtle />
              <StatusBadge status="not_checked" label={`Not Checked: ${portalCounts.not_checked}`} subtle />
              <StatusBadge status="error" label={`Error: ${portalCounts.error}`} subtle />
            </div>
          </article>
        </section>

        <section className="controlsPanel no-print">
          <div className="panelHeader">
            <div>
              <p>
                Step {step + 1} of {categories.length}
              </p>
              <h3>{currentCategory}</h3>
            </div>
            <div className="searchBox">
              <Search size={16} />
              <input placeholder="Search controls in this section..." value={search} onChange={(event) => setSearch(event.target.value)} />
            </div>
          </div>

          <div className="controlList">
            {filteredControls.map((control) => {
              const answer = ensureAnswer(answers[control.id]);
              const status = getEffectiveStatus(answer);
              const automatedStatus = answer.scanner?.status || "not_checked";

              return (
                <article className={`controlCard status-${status}`} key={control.id}>
                  <div className="controlTop">
                    <div>
                      <span className="controlId">{control.id}</span>
                      <h4>{control.control}</h4>
                    </div>

                    <div className="controlStatusGroup">
                      <StatusBadge status={status} label={`Final: ${getStatusLabel(status)}`} />
                      <StatusBadge status={automatedStatus} label={`Automated: ${getStatusLabel(automatedStatus)}`} subtle />
                    </div>
                  </div>

                  <div className="infoGrid infoGridWide">
                    <div>
                      <strong>Requirement</strong>
                      <p>{control.requirement}</p>
                    </div>
                    <div className="howToCheckBlock">
                      <strong>How to Check</strong>
                      <p className="howToCheckText">{control.howToCheck}</p>
                    </div>
                    <div>
                      <strong>Evidence Required</strong>
                      <p>{control.evidence}</p>
                    </div>
                  </div>

                  <div className="scannerEvidenceCard">
                    <div className="scannerEvidenceHeader">
                      <h5>Scanner Result</h5>
                      {answer.scanner ? <StatusBadge status={answer.scanner.status} /> : <StatusBadge status="not_checked" label="No automated data" subtle />}
                    </div>

                    <div className="scannerEvidenceGrid">
                      <div>
                        <strong>Expected Value</strong>
                        <p>{answer.scanner?.expectedValue || "No scanner data uploaded for this control."}</p>
                      </div>
                      <div>
                        <strong>Actual Value</strong>
                        <p>{answer.scanner?.actualValue || "No scanner data uploaded for this control."}</p>
                      </div>
                      <div>
                        <strong>Source</strong>
                        <p>{answer.scanner?.source || "N/A"}</p>
                      </div>
                      <div>
                        <strong>Scanner Notes</strong>
                        <p>{answer.scanner?.notes || "N/A"}</p>
                      </div>
                    </div>
                  </div>

                  <div className="answerGrid answerGridStacked">
                    <div className="fieldBlock">
                      <label>Manual Override / Final Status</label>
                      <select value={answer.manualStatus} onChange={(event) => updateAnswer(control.id, { manualStatus: event.target.value })}>
                        {MANUAL_OVERRIDE_OPTIONS.map((option) => (
                          <option value={option.value} key={option.value || "default"}>
                            {option.label}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="fieldBlock">
                      <label>Evidence Reference</label>
                      <input
                        placeholder="Screenshot filename, ticket number, asset reference, or evidence path"
                        value={answer.evidence}
                        onChange={(event) => updateAnswer(control.id, { evidence: event.target.value })}
                      />
                    </div>

                    <div className="fieldBlock fullWidth">
                      <label>Employee Comments / Manual Notes</label>
                      <textarea
                        placeholder="Add reviewer comments, remediation details, exception justification, or confirmation notes"
                        value={answer.comments}
                        onChange={(event) => updateAnswer(control.id, { comments: event.target.value })}
                      />
                    </div>
                  </div>
                </article>
              );
            })}

            {!filteredControls.length ? (
              <div className="emptyState">
                <Info size={18} />
                <p>No controls match your current search in this section.</p>
              </div>
            ) : null}
          </div>

          <div className="stepNav">
            <button disabled={step === 0} onClick={() => setStep(step - 1)}>
              <ChevronLeft size={16} /> Previous
            </button>
            <button disabled={step === categories.length - 1} onClick={() => setStep(step + 1)}>
              Next <ChevronRight size={16} />
            </button>
          </div>
        </section>

        <section className="printReport">
          <Report employee={employee} controls={controls} answers={answers} score={score} portalCounts={portalCounts} automatedCounts={automatedCounts} scanInfo={scanInfo} />
        </section>
      </main>
    </div>
  );
}

function buildReportText({ employee, controls, answers, score, portalCounts, automatedCounts, scanInfo }) {
  const lines = [];

  lines.push("OT CYBERSECURITY COMPLIANCE VERIFICATION REPORT");
  lines.push(`Generated: ${new Date().toLocaleString()}`);
  lines.push("");
  lines.push("EMPLOYEE DETAILS");
  lines.push(`Employee Name: ${employee.name || "N/A"}`);
  lines.push(`Employee ID: ${employee.employeeId || "N/A"}`);
  lines.push(`Department: ${employee.department || "N/A"}`);
  lines.push(`Device Name: ${employee.deviceName || "N/A"}`);
  lines.push(`Asset Tag: ${employee.assetTag || "N/A"}`);
  lines.push("");
  lines.push("SCANNER METADATA");
  lines.push(`Scanner Version: ${scanInfo?.scannerVersion || "N/A"}`);
  lines.push(`Computer Name: ${scanInfo?.computerName || "N/A"}`);
  lines.push(`User Name: ${scanInfo?.userName || "N/A"}`);
  lines.push(`Scan Date: ${formatDate(scanInfo?.scanDate)}`);
  lines.push(`Uploaded File: ${scanInfo?.fileName || "N/A"}`);
  lines.push("");
  lines.push("SUMMARY");
  lines.push(`Overall Score: ${score}%`);
  lines.push(`Final Pass: ${portalCounts.pass}`);
  lines.push(`Final Fail: ${portalCounts.fail}`);
  lines.push(`Final Manual Review: ${portalCounts.manual_review}`);
  lines.push(`Final Not Checked: ${portalCounts.not_checked}`);
  lines.push(`Final Error: ${portalCounts.error}`);
  lines.push(`Automated Pass: ${automatedCounts.pass}`);
  lines.push(`Automated Fail: ${automatedCounts.fail}`);
  lines.push(`Automated Manual Review: ${automatedCounts.manual_review}`);
  lines.push(`Automated Not Checked: ${automatedCounts.not_checked}`);
  lines.push(`Automated Error: ${automatedCounts.error}`);
  lines.push("");
  lines.push("CONTROL DETAILS");

  controls.forEach((control) => {
    const answer = ensureAnswer(answers[control.id]);
    const scanner = answer.scanner;

    lines.push(`${control.id} - ${control.control}`);
    lines.push(`Category: ${control.category}`);
    lines.push(`Requirement: ${control.requirement}`);
    lines.push(`Expected Value: ${scanner?.expectedValue || "N/A"}`);
    lines.push(`Actual Value: ${scanner?.actualValue || "N/A"}`);
    lines.push(`Source: ${scanner?.source || "N/A"}`);
    lines.push(`Automated Status: ${scanner ? getStatusLabel(scanner.status) : "Not Checked"}`);
    lines.push(`Final Status: ${getStatusLabel(getEffectiveStatus(answer))}`);
    lines.push(`Scanner Notes: ${scanner?.notes || "N/A"}`);
    lines.push(`Evidence Reference: ${answer.evidence || "N/A"}`);
    lines.push(`Employee Comments: ${answer.comments || "N/A"}`);
    lines.push("");
  });

  return lines.join("\n");
}

function Report({ employee, controls, answers, score, portalCounts, automatedCounts, scanInfo }) {
  return (
    <div className="reportDoc">
      <div className="reportHeader">
        <div>
          <h1>OT Cybersecurity Compliance Verification Report</h1>
          <p>Generated on {new Date().toLocaleString()}</p>
        </div>
        <ShieldCheck size={44} />
      </div>

      <div className="reportMeta reportMetaWide">
        <p><strong>Employee:</strong> {employee.name || "N/A"}</p>
        <p><strong>Employee ID:</strong> {employee.employeeId || "N/A"}</p>
        <p><strong>Department:</strong> {employee.department || "N/A"}</p>
        <p><strong>Device:</strong> {employee.deviceName || "N/A"}</p>
        <p><strong>Asset Tag:</strong> {employee.assetTag || "N/A"}</p>
        <p><strong>Scanner Version:</strong> {scanInfo?.scannerVersion || "N/A"}</p>
        <p><strong>Computer Name:</strong> {scanInfo?.computerName || "N/A"}</p>
        <p><strong>User Name:</strong> {scanInfo?.userName || "N/A"}</p>
        <p><strong>Scan Date:</strong> {formatDate(scanInfo?.scanDate)}</p>
      </div>

      <div className="reportScore reportScoreGrid">
        <div>
          <h2>{score}%</h2>
          <p>Overall Compliance Score</p>
        </div>

        <div className="reportScoreStats">
          <span>Final Pass: {portalCounts.pass}</span>
          <span>Final Fail: {portalCounts.fail}</span>
          <span>Final Manual Review: {portalCounts.manual_review}</span>
          <span>Final Not Checked: {portalCounts.not_checked}</span>
          <span>Final Error: {portalCounts.error}</span>
        </div>

        <div className="reportScoreStats">
          <span>Automated Pass: {automatedCounts.pass}</span>
          <span>Automated Fail: {automatedCounts.fail}</span>
          <span>Automated Manual Review: {automatedCounts.manual_review}</span>
          <span>Automated Not Checked: {automatedCounts.not_checked}</span>
          <span>Automated Error: {automatedCounts.error}</span>
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Control</th>
            <th>Requirement</th>
            <th>Expected Value</th>
            <th>Actual Value</th>
            <th>Source</th>
            <th>Status</th>
            <th>Notes</th>
          </tr>
        </thead>
        <tbody>
          {controls.map((control) => {
            const answer = ensureAnswer(answers[control.id]);
            const scanner = answer.scanner;

            return (
              <tr key={control.id}>
                <td>{control.id}</td>
                <td>{control.control}</td>
                <td>{control.requirement}</td>
                <td>{scanner?.expectedValue || "N/A"}</td>
                <td>{scanner?.actualValue || "N/A"}</td>
                <td>{scanner?.source || "N/A"}</td>
                <td>{getStatusLabel(getEffectiveStatus(answer))}</td>
                <td>
                  <div><strong>Scanner:</strong> {scanner?.notes || "N/A"}</div>
                  <div><strong>Evidence:</strong> {answer.evidence || "N/A"}</div>
                  <div><strong>Comments:</strong> {answer.comments || "N/A"}</div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

createRoot(document.getElementById("root")).render(<App />);
