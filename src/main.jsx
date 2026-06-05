
import React, { useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import { ShieldCheck, FileText, Printer, Download, Search, CheckCircle2, AlertTriangle, XCircle, ChevronRight, ChevronLeft } from "lucide-react";
import controls from "./controls.json";
import "./style.css";

const STATUS = {
  pass: { label: "Pass", icon: CheckCircle2 },
  fail: { label: "Fail", icon: XCircle },
  exception: { label: "Exception", icon: AlertTriangle },
  pending: { label: "Pending", icon: AlertTriangle },
};

function groupByCategory(items) {
  return items.reduce((acc, item) => {
    const key = item.category || "Security Controls";
    if (!acc[key]) acc[key] = [];
    acc[key].push(item);
    return acc;
  }, {});
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

  const currentCategory = categories[step] || "";
  const currentControls = grouped[currentCategory] || [];

  const filteredControls = currentControls.filter((c) => {
    const q = search.toLowerCase();
    return !q || [c.id, c.control, c.requirement].join(" ").toLowerCase().includes(q);
  });

  const total = controls.length;
  const completed = Object.values(answers).filter((a) => a.status && a.status !== "pending").length;
  const passed = Object.values(answers).filter((a) => a.status === "pass").length;
  const failed = Object.values(answers).filter((a) => a.status === "fail").length;
  const exceptions = Object.values(answers).filter((a) => a.status === "exception").length;
  const score = total ? Math.round((passed / total) * 100) : 0;

  function updateAnswer(id, update) {
    setAnswers((prev) => ({
      ...prev,
      [id]: { ...(prev[id] || { status: "pending", notes: "", evidence: "" }), ...update },
    }));
  }

  function downloadReport() {
    const report = buildReportText(employee, controls, answers, score, passed, failed, exceptions);
    const blob = new Blob([report], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `cybersecurity-compliance-report-${employee.deviceName || "device"}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  }

  function printReport() {
    window.print();
  }

  return (
    <div className="app">
      <aside className="sidebar no-print">
        <div className="brand">
          <div className="brandIcon"><ShieldCheck size={28} /></div>
          <div>
            <h1>OT Cybersecurity</h1>
            <p>Compliance Verification Portal</p>
          </div>
        </div>

        <div className="progressCard">
          <div className="score">{score}%</div>
          <div>
            <strong>Compliance Score</strong>
            <p>{completed} of {total} controls completed</p>
          </div>
        </div>

        <div className="miniStats">
          <span className="pass">Pass: {passed}</span>
          <span className="fail">Fail: {failed}</span>
          <span className="exception">Exceptions: {exceptions}</span>
        </div>

        <nav>
          {categories.map((cat, idx) => {
            const catItems = grouped[cat];
            const done = catItems.filter((c) => answers[c.id]?.status && answers[c.id]?.status !== "pending").length;
            return (
              <button key={cat} className={idx === step ? "active" : ""} onClick={() => setStep(idx)}>
                <span>{cat}</span>
                <small>{done}/{catItems.length}</small>
              </button>
            );
          })}
        </nav>
      </aside>

      <main className="main">
        <section className="hero no-print">
          <div>
            <h2>Employee Device Verification</h2>
            <p>Complete each security control, attach evidence references, and generate a printable compliance report.</p>
          </div>
          <div className="actions">
            <button onClick={downloadReport}><Download size={16} /> Download Report</button>
            <button onClick={printReport}><Printer size={16} /> Print Report</button>
          </div>
        </section>

        <section className="employeeCard no-print">
          <input placeholder="Employee Name" value={employee.name} onChange={(e) => setEmployee({...employee, name: e.target.value})} />
          <input placeholder="Employee ID" value={employee.employeeId} onChange={(e) => setEmployee({...employee, employeeId: e.target.value})} />
          <input placeholder="Department" value={employee.department} onChange={(e) => setEmployee({...employee, department: e.target.value})} />
          <input placeholder="Device Name" value={employee.deviceName} onChange={(e) => setEmployee({...employee, deviceName: e.target.value})} />
          <input placeholder="Asset Tag" value={employee.assetTag} onChange={(e) => setEmployee({...employee, assetTag: e.target.value})} />
        </section>

        <section className="controlsPanel no-print">
          <div className="panelHeader">
            <div>
              <p>Step {step + 1} of {categories.length}</p>
              <h3>{currentCategory}</h3>
            </div>
            <div className="searchBox">
              <Search size={16} />
              <input placeholder="Search controls in this section..." value={search} onChange={(e) => setSearch(e.target.value)} />
            </div>
          </div>

          <div className="controlList">
            {filteredControls.map((control) => {
              const answer = answers[control.id] || { status: "pending", notes: "", evidence: "" };
              return (
                <article className={`controlCard status-${answer.status}`} key={control.id}>
                  <div className="controlTop">
                    <div>
                      <span className="controlId">{control.id}</span>
                      <h4>{control.control}</h4>
                    </div>
                    <select value={answer.status} onChange={(e) => updateAnswer(control.id, { status: e.target.value })}>
                      <option value="pending">Pending</option>
                      <option value="pass">Pass</option>
                      <option value="fail">Fail</option>
                      <option value="exception">Exception</option>
                    </select>
                  </div>

                  <div className="infoGrid">
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

                  <div className="answerGrid">
                    <input placeholder="Evidence reference / screenshot filename / ticket number" value={answer.evidence || ""} onChange={(e) => updateAnswer(control.id, { evidence: e.target.value })} />
                    <textarea placeholder="Notes, exception justification, or remediation comments" value={answer.notes || ""} onChange={(e) => updateAnswer(control.id, { notes: e.target.value })} />
                  </div>
                </article>
              );
            })}
          </div>

          <div className="stepNav">
            <button disabled={step === 0} onClick={() => setStep(step - 1)}><ChevronLeft size={16}/> Previous</button>
            <button disabled={step === categories.length - 1} onClick={() => setStep(step + 1)}>Next <ChevronRight size={16}/></button>
          </div>
        </section>

        <section className="printReport">
          <Report employee={employee} controls={controls} answers={answers} score={score} passed={passed} failed={failed} exceptions={exceptions} />
        </section>
      </main>
    </div>
  );
}

function buildReportText(employee, controls, answers, score, passed, failed, exceptions) {
  const lines = [];
  lines.push("OT CYBERSECURITY COMPLIANCE VERIFICATION REPORT");
  lines.push("Generated: " + new Date().toLocaleString());
  lines.push("");
  lines.push(`Employee: ${employee.name || "N/A"}`);
  lines.push(`Employee ID: ${employee.employeeId || "N/A"}`);
  lines.push(`Department: ${employee.department || "N/A"}`);
  lines.push(`Device Name: ${employee.deviceName || "N/A"}`);
  lines.push(`Asset Tag: ${employee.assetTag || "N/A"}`);
  lines.push("");
  lines.push(`Compliance Score: ${score}%`);
  lines.push(`Pass: ${passed}`);
  lines.push(`Fail: ${failed}`);
  lines.push(`Exceptions: ${exceptions}`);
  lines.push("");
  controls.forEach((c) => {
    const a = answers[c.id] || {};
    lines.push(`${c.id} - ${c.control}`);
    lines.push(`Category: ${c.category}`);
    lines.push(`Requirement: ${c.requirement}`);
    lines.push(`Status: ${a.status || "Pending"}`);
    lines.push(`Evidence: ${a.evidence || "N/A"}`);
    lines.push(`Notes: ${a.notes || "N/A"}`);
    lines.push("");
  });
  return lines.join("\n");
}

function Report({ employee, controls, answers, score, passed, failed, exceptions }) {
  return (
    <div className="reportDoc">
      <div className="reportHeader">
        <div>
          <h1>OT Cybersecurity Compliance Verification Report</h1>
          <p>Generated on {new Date().toLocaleString()}</p>
        </div>
        <ShieldCheck size={44}/>
      </div>

      <div className="reportMeta">
        <p><strong>Employee:</strong> {employee.name || "N/A"}</p>
        <p><strong>Employee ID:</strong> {employee.employeeId || "N/A"}</p>
        <p><strong>Department:</strong> {employee.department || "N/A"}</p>
        <p><strong>Device:</strong> {employee.deviceName || "N/A"}</p>
        <p><strong>Asset Tag:</strong> {employee.assetTag || "N/A"}</p>
      </div>

      <div className="reportScore">
        <h2>{score}%</h2>
        <p>Overall Compliance Score</p>
        <span>Pass: {passed}</span>
        <span>Fail: {failed}</span>
        <span>Exceptions: {exceptions}</span>
      </div>

      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Control</th>
            <th>Status</th>
            <th>Evidence</th>
            <th>Notes</th>
          </tr>
        </thead>
        <tbody>
          {controls.map((c) => {
            const a = answers[c.id] || {};
            return (
              <tr key={c.id}>
                <td>{c.id}</td>
                <td>{c.control}</td>
                <td>{a.status || "Pending"}</td>
                <td>{a.evidence || ""}</td>
                <td>{a.notes || ""}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  )
}

createRoot(document.getElementById("root")).render(<App />);
