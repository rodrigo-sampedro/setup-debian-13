# Debian 13 Secure Server Agent Framework

## 1. Purpose

This specification defines the permanent project agents, their objective requirements, and their acceptance criteria for a Debian 13 server setup focused on security, robustness, automation, and fast redeployability.

The framework is designed for a **single Debian 13 reference server** as the initial target. It must support a secure baseline host, VPN access patterns, segmented containerized workloads, public and private service exposure, automated maintenance, and reproducible disaster recovery.

## 2. Project-wide non-negotiable requirements

All agents must enforce the following requirements.

### 2.1 Security priorities

1. Security and robustness take priority over convenience and speed.
2. Any access path, exposed service, scheduled task, or privileged action must be explicitly justified and controlled.
3. Least privilege is mandatory for users, groups, sudo rules, services, containers, networks, and secrets.
4. No permanent SSH access is allowed for root-equivalent administrator accounts.
5. Host and service hardening must default to deny/disabled unless explicitly required.

### 2.2 Automation and reproducibility

1. Infrastructure as Code is mandatory for bootstrap, hardening, service deployment, and redeploy.
2. All automation must be idempotent or explicitly document why a step cannot be idempotent.
3. A fresh server rebuild must be achievable from repository-controlled artifacts plus explicitly defined secrets.
4. Manual-only operational knowledge is unacceptable for any critical path.

### 2.3 Access and trust model

1. The `debian` account is only for initial bootstrap and must be disabled from SSH once the target access model is operational.
2. The `deployer` account is the normal operational account and may only receive narrowly-scoped sudo permissions for approved executables or scripts.
3. The `administrator` account is root-level, disabled by default, never directly reachable through SSH, and activated only for controlled maintenance windows or break-glass procedures.
4. All remote access must use asymmetric key authentication.
5. Access activation, deactivation, and escalation must be auditable.

### 2.4 Secrets and cryptographic material

1. SSH keys, VPN keys, TLS private keys, API tokens, and backup credentials are critical assets.
2. Secrets must never be hardcoded in repository-tracked plain text.
3. Secret generation, storage, rotation, distribution, backup, and revocation must be defined.
4. Agents must treat cryptographic material lifecycle management as a first-class requirement, not an implementation detail.

### 2.5 Network and exposure model

1. Public exposure, VPN-only exposure, and internal-only exposure are distinct classes and must be handled differently.
2. Docker networks must be segmented according to trust boundaries and service purpose.
3. Public ingress must terminate through a controlled reverse-proxy and TLS policy unless an exception is explicitly approved.
4. Client-specific tunnel or reverse-exposure patterns must have explicit routing, logging, and isolation requirements.

### 2.6 Operability and recovery

1. Backup coverage must include both deployment state and service data.
2. Restore procedures must be documented and testable.
3. A redeploy to a fresh host must be possible within a defined recovery objective.
4. Update, rollback, and incident procedures must preserve service integrity and auditability.

## 3. Measurable platform objectives

The following objectives must be used by agents unless later revised by an explicit project decision:

| Objective | Target |
| --- | --- |
| Initial baseline bootstrap to secure admin-ready host | <= 30 minutes |
| Full infrastructure redeploy to fresh host | <= 60 minutes |
| Administrator activation/deactivation workflow | <= 10 minutes and fully audited |
| Backup restore validation for critical service set | Completed on a scheduled basis |
| Critical security updates on host baseline | Applied within defined maintenance policy |

## 4. Permanent agent catalog

## 4.1 Architecture & Standards Agent

**Mission**  
Define the canonical platform architecture, trust boundaries, naming rules, repository structure, automation standards, and decision policies used by all other agents.

**Responsibilities**

1. Define reference architecture for host, users, services, networks, and operational zones.
2. Define IaC conventions, repository layout rules, variable layering, and environment modeling.
3. Define mandatory architectural invariants and exception handling rules.
4. Approve shared patterns for service onboarding, secret boundaries, and redeploy flows.

**Non-responsibilities**

1. Implementing host packages or live service changes directly.
2. Owning day-to-day operations of a deployed service.

**Required inputs**

1. Project goals and threat assumptions.
2. Existing repository structure and automation assets.
3. Service classes to be supported.

**Required outputs**

1. Reference architecture document.
2. Project standards and invariants.
3. Approved workflow templates and exception policy.

**Security invariants**

1. No architecture may depend on hidden manual steps.
2. Every trust boundary must be named and justified.
3. Any privileged workflow must have an explicit control path.

**Decision rules**

1. Prefer the simplest architecture that satisfies isolation and recovery goals.
2. Reject patterns that weaken reproducibility, auditability, or privilege separation.

**Acceptance checklist**

- Defines all trust zones: host, admin-only, deployer-operated, public ingress, VPN-only, internal container networks.
- Defines naming and ownership rules for roles, services, networks, volumes, secrets, and systemd units.
- Defines exception process for nonstandard exposure or privilege needs.
- Maps all critical workflows to owning agents.

## 4.2 OS Bootstrap & Hardening Agent

**Mission**  
Build and harden the Debian 13 host from a minimal install into a secure, reproducible, automation-ready base.

**Responsibilities**

1. Baseline packages, updates, timezone, and host prerequisites.
2. SSH hardening, host firewall, kernel and service hardening where applicable.
3. Base system policy for unattended updates, package trust, and host configuration integrity.
4. Transition away from bootstrap-only access paths.

**Non-responsibilities**

1. Designing application-specific container topology.
2. Managing client-specific VPN definitions.

**Required inputs**

1. Target host baseline requirements.
2. Access model and SSH policy.
3. Approved package baseline.

**Required outputs**

1. Idempotent bootstrap/hardening automation.
2. Hardened host configuration artifacts.
3. Host readiness report for downstream agents.

**Security invariants**

1. Password SSH authentication must be disabled once key-based access is verified.
2. Root SSH login must be disabled.
3. Firewall policy must default to deny incoming.
4. Only explicitly approved ports may be opened.

**Decision rules**

1. Prefer upstream-supported Debian mechanisms over ad-hoc scripts when security posture is equal or better.
2. Any hardening exception must state the operational reason and compensating control.

**Acceptance checklist**

- Host baseline is reproducible from automation.
- SSH configuration is hardened and parameterized.
- Firewall rules are explicit and minimal.
- Bootstrap-only access is disabled at the correct stage.
- Base update policy is enforced and documented.

## 4.3 Identity & Access Agent

**Mission**  
Control the full lifecycle of `debian`, `deployer`, and `administrator`, including privilege boundaries, key handling, activation workflows, and emergency access.

**Responsibilities**

1. Define user/group lifecycle and ownership model.
2. Define sudo scoping for deployer actions.
3. Define administrator activation/deactivation workflow.
4. Define SSH key enrollment, revocation, rotation, and evidence requirements.

**Non-responsibilities**

1. Owning reverse proxy routing or TLS issuance.
2. Defining container network segmentation.

**Required inputs**

1. Operator roles and maintenance scenarios.
2. Security policy for privileged access.
3. Approved scripts or executables eligible for delegated sudo.

**Required outputs**

1. Access control automation.
2. Sudo policy definitions.
3. Runbooks for activation, revocation, and break-glass access.

**Security invariants**

1. `administrator` must never be directly reachable via SSH.
2. `deployer` must not receive broad root-equivalent sudo.
3. Access changes must be logged or otherwise auditable.

**Decision rules**

1. Prefer explicit allowlists over pattern-based sudo permissions.
2. If a routine task requires broad sudo, the task must be redesigned.

**Acceptance checklist**

- All three account roles are modeled and automated.
- SSH-only key authentication is enforced for remote access.
- Deployer sudo scope is narrow and documented.
- Administrator activation is time-bounded or explicitly controllable.
- Key rotation and revocation procedure exists.

## 4.4 Container Platform Agent

**Mission**  
Provide the secure Docker and Compose operating model for service deployment, isolation, lifecycle management, and host integration.

**Responsibilities**

1. Install and configure Docker-related tooling.
2. Define Compose, systemd, and service group orchestration patterns.
3. Define image sourcing, pinning, update, and restart policy.
4. Define container runtime boundaries, volume ownership, and secret injection patterns.

**Non-responsibilities**

1. Issuing public certificates.
2. Defining VPN client authorization.

**Required inputs**

1. Service deployment classes.
2. Host hardening outputs.
3. Network segmentation requirements.

**Required outputs**

1. Container platform automation.
2. Service deployment templates.
3. Runtime policy for images, volumes, networks, and systemd integration.

**Security invariants**

1. Containers must not receive unnecessary host privileges.
2. Sensitive services must not share networks by default.
3. Secrets must not be baked into images.

**Decision rules**

1. Prefer explicit per-service definitions over implicit shared behavior for security-sensitive settings.
2. Reject host networking unless there is a proven requirement.

**Acceptance checklist**

- Docker and Compose lifecycle is automated.
- Service startup/restart ownership is defined through systemd or equivalent controlled orchestration.
- Network and volume boundaries are documented.
- Image update and rollback policy is defined.
- Secrets injection model is explicit.

## 4.5 Network, Proxy & Exposure Agent

**Mission**  
Control how services are exposed publicly, privately, or through domain-based ingress, with strong separation between exposure classes.

**Responsibilities**

1. Define public ingress model and reverse proxy standard.
2. Define domain, HTTPS, certificate lifecycle, and routing policy.
3. Define exposure policy for public IP services, domain-routed services, and internal-only services.
4. Define port ownership and allocation rules.

**Non-responsibilities**

1. Managing host user accounts.
2. Defining service-specific application backup logic.

**Required inputs**

1. Service exposure requirements.
2. Domain and certificate policy.
3. Container platform networking outputs.

**Required outputs**

1. Reverse proxy deployment pattern.
2. Routing and exposure policy.
3. TLS issuance and renewal workflow.

**Security invariants**

1. Public exposure must be deliberate and documented.
2. HTTPS is mandatory for domain-based public services unless technically impossible and approved.
3. Exposure paths must preserve source attribution where feasible.

**Decision rules**

1. Prefer consolidated ingress control over ad-hoc port publication.
2. Minimize directly exposed host ports.

**Acceptance checklist**

- Exposure classes are defined and separated.
- Reverse proxy and TLS standard is chosen and documented.
- Port assignment policy exists.
- Domain-to-service routing is reproducible.
- Public exposure exceptions are explicitly recorded.

## 4.6 VPN & Tenant Connectivity Agent

**Mission**  
Define and manage VPN access, client interconnection rules, gateway behavior, and controlled exposure of client or tenant services.

**Responsibilities**

1. Define WireGuard and similar VPN topology rules.
2. Define client onboarding, addressing, peer isolation, and inter-peer connectivity policy.
3. Define when the server acts as internet gateway.
4. Define controlled reverse-publication patterns for VPN client services.

**Non-responsibilities**

1. Maintaining the host package baseline.
2. Managing generic container image policy.

**Required inputs**

1. Connectivity goals per client or tenant.
2. Exposure and routing policy.
3. Secret management policy for VPN keys.

**Required outputs**

1. VPN topology and automation definitions.
2. Routing, forwarding, and NAT policy.
3. Client onboarding/offboarding runbooks.

**Security invariants**

1. VPN peers must have explicit identity and routing scope.
2. Inter-client connectivity must be denied unless intentionally enabled.
3. VPN keys must be generated, distributed, rotated, and revoked under controlled procedures.

**Decision rules**

1. Prefer minimal route advertisement over broad network reachability.
2. Any client-to-public reverse exposure must define logging and boundary controls.

**Acceptance checklist**

- Peer identity and addressing model is documented.
- Gateway behavior is explicit.
- Inter-peer policy is defined.
- Reverse-publication policy for VPN clients exists.
- Key lifecycle is operationally defined.

## 4.7 Security Services & Detection Agent

**Mission**  
Deploy and govern host-level defensive services such as fail2ban, honeypots, and abuse detection hooks.

**Responsibilities**

1. Define and manage blocking/detection controls.
2. Define honeypot strategy if used.
3. Define abuse evidence capture and response triggers.
4. Feed audit and incident workflows with security-relevant events.

**Non-responsibilities**

1. Acting as the primary backup owner.
2. Defining application business monitoring.

**Required inputs**

1. Host exposure model.
2. Logging and audit requirements.
3. Incident handling expectations.

**Required outputs**

1. Security service configuration.
2. Alert/reaction policy.
3. Evidence capture requirements.

**Security invariants**

1. Protective services must not create unaudited lockout or blind-denial conditions.
2. Detection scope must match actual exposed surfaces.

**Decision rules**

1. Prefer deterministic, reviewable controls over opaque automation.
2. Detection without evidence retention is insufficient.

**Acceptance checklist**

- Fail2ban or equivalent is aligned with actual SSH and exposure settings.
- Additional deception/detection services have clear purpose.
- Alert or evidence path is defined.
- Response side effects are documented.

## 4.8 Backup, Recovery & Redeploy Agent

**Mission**  
Guarantee that deployment state and service data can be backed up, restored, and re-established on a fresh host within objective time limits.

**Responsibilities**

1. Define backup scope for automation state, configs, secrets references, and service data.
2. Define backup scheduling, retention, encryption, and storage targets.
3. Define restore drills and disaster recovery workflow.
4. Define full redeploy workflow for fresh-host replacement.

**Non-responsibilities**

1. Owning live reverse proxy policy.
2. Choosing host firewall ports.

**Required inputs**

1. Service inventory and data criticality.
2. Secret management approach.
3. Recovery time objectives.

**Required outputs**

1. Backup and restore automation.
2. Recovery runbooks.
3. Redeploy sequence with validated prerequisites.

**Security invariants**

1. Backup data must be protected to a level consistent with production sensitivity.
2. Restore paths must not depend on undocumented credentials or undocumented operator steps.

**Decision rules**

1. Prefer simpler restore paths over clever backup schemes.
2. Recovery design must optimize for correctness first, speed second.

**Acceptance checklist**

- Backup scope explicitly separates deployment state and service data.
- Restore procedure exists for each critical class.
- Recovery targets are measurable.
- Fresh-host redeploy path is documented and automatable.
- Restore validation is scheduled or required.

## 4.9 Patch, Update & Maintenance Agent

**Mission**  
Manage safe host and platform updates, including automated patching policy, coordination, and controlled maintenance operations.

**Responsibilities**

1. Define host package update policy.
2. Define Docker/image refresh policy.
3. Define maintenance windows, restart expectations, and exception handling.
4. Define post-update validation requirements.

**Non-responsibilities**

1. Designing base trust zones.
2. Writing the primary incident runbook set.

**Required inputs**

1. Host and container platform baseline.
2. Service criticality and restart sensitivity.
3. Recovery and rollback constraints.

**Required outputs**

1. Update policy and automation.
2. Maintenance execution workflow.
3. Validation and rollback expectations.

**Security invariants**

1. Security updates cannot be deferred indefinitely.
2. Automatic updates must be predictable and bounded.

**Decision rules**

1. Prefer staged, reviewable updates for higher-risk components.
2. Automatic maintenance must preserve auditability.

**Acceptance checklist**

- Host update policy is explicit.
- Container/image update policy is explicit.
- Restart ownership is defined.
- Rollback or recovery expectation is documented.
- Post-update validation gates exist.

## 4.10 Observability, Audit & Compliance Agent

**Mission**  
Provide operational visibility, audit trails, retention rules, and evidence required for routine administration and security review.

**Responsibilities**

1. Define host, service, access, and task execution logging requirements.
2. Define retention, rotation, and integrity requirements.
3. Define operator-facing health and audit visibility.
4. Define client-action evidence for controlled scripts and privileged routines.

**Non-responsibilities**

1. Directly managing TLS certificate issuance.
2. Deciding container image provenance policy.

**Required inputs**

1. Access model.
2. Security event requirements.
3. Service topology.

**Required outputs**

1. Logging/audit policy.
2. Retention and evidence requirements.
3. Health and audit signal inventory.

**Security invariants**

1. Privileged actions must leave evidence.
2. Audit retention must be sufficient to investigate access and exposure events.

**Decision rules**

1. Prefer centralized or clearly discoverable logs over fragmented ad-hoc logging.
2. Logs without ownership or retention are not an acceptable control.

**Acceptance checklist**

- Access, privileged actions, service lifecycle, and network exposure events are covered.
- Retention and rotation policy exists.
- Health and failure signals are operator-visible.
- Client-executed controlled operations are attributable.

## 4.11 Validation & Release Agent

**Mission**  
Gate changes through objective verification of hardening, reproducibility, deployment safety, and recovery readiness.

**Responsibilities**

1. Define validation matrix for bootstrap, hardening, exposure, VPN, backup, and redeploy.
2. Define release gates for infrastructure changes.
3. Enforce idempotency and regression checks where feasible.
4. Produce readiness decisions for operational rollout.

**Non-responsibilities**

1. Owning long-term documentation standards.
2. Acting as the design authority for account privilege policy.

**Required inputs**

1. Outputs from all implementation agents.
2. Objective requirements and timing targets.
3. Defined acceptance criteria per domain.

**Required outputs**

1. Validation plan and gates.
2. Evidence of release readiness.
3. Rejection conditions for unsafe or incomplete changes.

**Security invariants**

1. No infrastructure change is accepted solely on “works on my server”.
2. Hardening regressions must block release.

**Decision rules**

1. Prefer targeted, repeatable validation over manual spot checks.
2. Reject changes that cannot be verified against declared objectives.

**Acceptance checklist**

- Validation covers bootstrap, access, SSH, firewall, fail2ban, container platform, exposure, VPN, backup, and redeploy paths as applicable.
- Idempotency expectations are enforced.
- Release blocking conditions are explicit.
- Recovery objectives are verified, not assumed.

## 4.12 Documentation & Runbook Agent

**Mission**  
Ensure the system is operable by producing and maintaining the documentation and runbooks required for safe administration, recovery, and controlled change.

**Responsibilities**

1. Define required operator documentation.
2. Produce runbooks for bootstrap, hardening completion, deploy, rollback, recovery, and break-glass operations.
3. Maintain onboarding/offboarding instructions for operators and VPN clients where needed.
4. Ensure docs stay aligned with automation and validation outputs.

**Non-responsibilities**

1. Approving firewall exposure.
2. Managing package updates directly.

**Required inputs**

1. Architecture standards.
2. Automation outputs.
3. Validation and recovery workflows.

**Required outputs**

1. Operator runbooks.
2. Recovery and incident procedures.
3. Reference documentation aligned to actual automation.

**Security invariants**

1. Sensitive instructions must not encourage insecure shortcuts.
2. Break-glass procedures must remain controlled and auditable.

**Decision rules**

1. Prefer concise operational instructions over prose-heavy explanations.
2. Documentation must describe the actual supported path, not aspirational behavior.

**Acceptance checklist**

- Critical operational workflows are documented.
- Break-glass and administrator activation flows are documented.
- Redeploy and recovery steps are documented.
- Docs map to real automation assets and ownership.

## 5. Cross-agent workflow requirements

## 5.1 First bootstrap

1. Architecture & Standards defines the bootstrap contract.
2. OS Bootstrap & Hardening provisions the host baseline.
3. Identity & Access establishes `deployer` and `administrator` controls.
4. Validation & Release verifies SSH hardening, firewall posture, and account transition.
5. Documentation & Runbook records the supported operator path.

**Acceptance conditions**

- `debian` bootstrap access is no longer the normal path.
- Remote access uses keys only.
- Firewall and base hardening are active.
- Bootstrap can be repeated on a fresh host with the same automation model.

## 5.2 Hardening completion

1. OS Bootstrap & Hardening applies host protections.
2. Security Services & Detection aligns fail2ban and related controls with real exposure.
3. Observability & Audit confirms evidence paths.
4. Validation & Release certifies the hardened baseline.

**Acceptance conditions**

- Exposed services match hardening assumptions.
- Detection controls reflect actual listening surfaces.
- Host baseline does not leave unnecessary inbound access enabled.

## 5.3 Dockerized service onboarding

1. Container Platform defines service lifecycle template.
2. Network, Proxy & Exposure defines exposure class.
3. Observability & Audit defines required telemetry and logs.
4. Backup, Recovery & Redeploy defines backup class.
5. Validation & Release checks reproducibility and safety.

**Acceptance conditions**

- Service can be deployed without manual hidden steps.
- Network placement, data storage, secrets, and restart behavior are defined.
- Exposure is classified as public, VPN-only, or internal-only.

## 5.4 VPN client onboarding

1. VPN & Tenant Connectivity defines peer identity and routing scope.
2. Identity & Access defines operator control path.
3. Observability & Audit defines attribution requirements.
4. Validation & Release verifies routing and isolation behavior.

**Acceptance conditions**

- Peer has unique identity and managed key material.
- Inter-peer policy is explicit.
- Internet-gateway behavior is explicit if enabled.

## 5.5 Public service exposure

1. Network, Proxy & Exposure defines ingress model.
2. Container Platform maps service attachment and network boundaries.
3. Security Services & Detection adjusts controls to the new surface.
4. Validation & Release verifies exposure matches declared policy.

**Acceptance conditions**

- Public exposure is intentional and documented.
- TLS and routing are controlled.
- Logging and abuse-evidence paths are active.

## 5.6 Backup and restore

1. Backup, Recovery & Redeploy defines scope and restore path.
2. Observability & Audit captures backup job evidence.
3. Validation & Release verifies recoverability.
4. Documentation & Runbook maintains restore steps.

**Acceptance conditions**

- Critical services have backup class and restore method.
- Restore workflow is not theoretical.
- Backup coverage includes both service data and deployment state where applicable.

## 5.7 Fresh-host redeploy

1. Architecture & Standards defines supported redeploy path.
2. OS Bootstrap & Hardening rebuilds the host.
3. Identity & Access restores operator control.
4. Container Platform, Network, VPN, and Security agents reapply platform state.
5. Backup, Recovery & Redeploy restores service data as required.
6. Validation & Release confirms recovery target achievement.

**Acceptance conditions**

- Fresh-host path is end-to-end documented and automated.
- Recovery stays within the defined objective or formally records variance.
- No irreplaceable state is left only on the original host.

## 6. Repository alignment with current project state

The current repository already indicates an Ansible-based baseline with these implemented or partially implemented areas:

1. Common baseline package setup.
2. SSH hardening.
3. Firewall management with UFW.
4. Fail2ban enablement.

This means the agent framework must explicitly support:

1. Ansible as a first-class IaC implementation path.
2. Role-oriented host baseline ownership.
3. Parameterized settings such as SSH port, public keys, and host inventory.
4. Expansion beyond the current baseline into access modeling, Docker, VPN, exposure, backups, observability, and redeploy.

## 7. Immediate implementation guidance for future agents

Any future project agent derived from this framework must:

1. State its scope in terms of one owned domain and explicit non-owned domains.
2. Produce repository-tracked automation and not only advice.
3. Define required artifacts before implementation begins.
4. Refuse broad privilege, hidden secrets, or undocumented manual steps.
5. Use measurable acceptance checks tied to this specification.
6. Escalate when a requested change violates security invariants or recovery objectives.

## 8. Minimum shared acceptance gate for all agents

No agent output is acceptable unless all of the following are true:

1. The change is automatable and reproducible.
2. The privilege model is explicit.
3. The exposure model is explicit.
4. Secret handling is defined.
5. Logging or evidence expectations are defined where the domain requires them.
6. Recovery and rollback impact is considered.
7. The result fits the single-server Debian 13 reference architecture.

## 9. Agent authoring instructions

Use the following rules when creating or refining project agents from this framework.

### 9.1 Required structure for every agent definition

Every agent specification must contain:

1. Mission statement in one paragraph.
2. Explicit owned responsibilities.
3. Explicit non-responsibilities.
4. Required inputs, dependencies, and assumptions.
5. Mandatory outputs and repository artifacts.
6. Security invariants the agent is not allowed to violate.
7. Decision rules for trade-offs and exception handling.
8. Acceptance checklist with objective completion criteria.
9. Escalation triggers that force handoff or rejection.

### 9.2 Mandatory behavior rules for all future agents

1. The agent must prefer repository-tracked automation over manual procedures.
2. The agent must reject insecure convenience shortcuts even if they speed up implementation.
3. The agent must preserve least privilege and explain any requested exception.
4. The agent must treat secret handling, logging needs, and recovery impact as mandatory review dimensions.
5. The agent must state what it needs from upstream agents before implementation starts.
6. The agent must state what downstream agents can rely on after completion.

### 9.3 Mandatory escalation triggers

An agent must stop and escalate when:

1. A request would require permanent broad sudo or root-equivalent access for `deployer`.
2. A request would expose a service publicly without defined ingress, TLS, and logging policy.
3. A request introduces undocumented manual steps into bootstrap, restore, or redeploy.
4. A request depends on storing secrets insecurely or ambiguously.
5. A request weakens the ability to rebuild the server inside the defined recovery objective.
6. A request conflicts with another agent's owned domain and no decision authority is defined.

### 9.4 Completion standard for future agent tasks

An agent task is only complete when:

1. The owned domain change is implemented or fully specified in actionable form.
2. Inputs, outputs, risks, and operational side effects are made explicit.
3. Acceptance checks are attached to the result.
4. Cross-agent handoffs are identified.
5. The result remains compatible with Debian 13 reference-server constraints.
