# OT Cybersecurity Compliance Verification Portal

This is a free, Vercel-ready React/Vite web app for employee cybersecurity verification.

## Documentation

- Full project guide: [`docs/Home.md`](docs/Home.md)
- Scanner workflow, portal usage, reporting, maintenance, and deployment details are documented there.

## Run locally

```bash
npm install
npm run dev
```

## Deploy to Vercel

1. Create a GitHub repository.
2. Upload/push this project to GitHub.
3. Go to Vercel.
4. Click Add New Project.
5. Import the GitHub repository.
6. Click Deploy.

## Main features

- Multi-section employee assessment wizard
- Pass / Fail / Exception / Pending status for each control
- Evidence reference and notes fields
- Live compliance score
- Printable report
- Downloadable text report
- Controls loaded from `src/controls.json`
