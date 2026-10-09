# Security Policy

## Reporting a vulnerability

Do not open a public issue. Use
[Private Vulnerability Reporting](https://github.com/sogeor/images/security/advisories/new).

Reports are accepted in English or Russian. Initial response within 7 days.
Fix targets: Critical — 7 days, High — 30 days.

## Response process

1. Acknowledge the report within 7 days.
2. Confirm and assess severity (CVSS) privately in a draft security advisory.
3. Fix in a private fork of the advisory; rebuild affected templates.
4. Publish the advisory and a CHANGELOG entry, crediting the reporter unless they ask for anonymity.
5. Request a CVE through GitHub when applicable.

Fix targets apply from confirmation. What the images do and do not guarantee is described in [docs/security.md](docs/security.md).

## Scope

- Packer templates, scripts, the image playbook;
- GitHub Actions workflows;
- Talos Image Factory schematic.
