# Agent context: Secure SoR backend for Lovable

This repository is the **backend** for the Secure real estate sustainability app. It is intended to be implemented and deployed so that the [Lovable.ai](https://lovable.ai) frontend can call it.

## For AI agents working in this repo

1. **Read the canonical spec first:** `Secure_Canonical_v5.md` defines the product, domain model (Account, Property, Space, System, Data Library, Reporting Boundary), and rules. All new code should align with it.

2. **Use the docs:**  
   - `docs/data-model/` — account, data-library, systems  
   - `docs/architecture/` — system overview, boundary logic, data confidence  
   - `docs/modules/` — reports and other modules  

3. **Lovable integration:**  
   - The frontend is built in Lovable and may call this backend and/or a separate Data Readiness agent API.  
   - The main workspace has `STEP-BY-STEP-CONNECT.md` and `LOVABLE-FIX-CLOUD-API.md` for connecting the Lovable app to the agent and configuring API URLs.

4. **GitHub:** [Apex-TIGRE/Secure-SoR-backend](https://github.com/Apex-TIGRE/Secure-SoR-backend) — clone, push, and open PRs from here. You can add and edit files in this folder; they are part of this repo.

When in doubt, prefer the definitions and types in `Secure_Canonical_v5.md` and the docs over assumptions.
