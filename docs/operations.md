# Operations

Runbooks for keeping images current and the Proxmox storage tidy. Each runbook: goal,
preconditions, steps, expected result, check.

## Monthly rebuild

- **Goal:** fresh templates with current security updates.
- **How:** automatic, 03:00 UTC on the 1st (`build` schedule, `image = all`, prune enabled).
- **Check:** the run is green; `tools/find-template.sh ubuntu-2404 base` returns the new version;
  review `*-openscap-summary.json` and the Trivy report for new High/Critical findings.
- **If it fails:** [Troubleshooting](troubleshooting.md); the previous templates stay untouched.

## Update the Ubuntu ISO

1. Find the new point release on <https://releases.ubuntu.com/noble/> and its line in `SHA256SUMS`.
2. Edit `images/ubuntu-2404-base/ubuntu-2404-base.pkrvars.hcl`:

    ```hcl
    iso_url      = "https://releases.ubuntu.com/noble/ubuntu-24.04.N-live-server-amd64.iso"
    iso_checksum = "sha256:<value from SHA256SUMS>"
    ```

3. Pull request; after merge run **build** with `image = all`.
4. Optional: delete the old ISO in Proxmox (**Datacenter → Storage → local → ISO Images**).

Expected result: the first job downloads the new ISO (up to 30 minutes, `task_timeout`).

## Update Kubernetes

Renovate opens a pull request changing `k8s_version` in `images/ubuntu-2404-k8s/variables.pkr.hcl`.

1. Check that pkgs.k8s.io publishes the matching revision (`k8s_package_revision`, usually `1.1`).
2. Merge; run **build** with `image = k8s`.
3. Expected: a template tagged `k8s-<major>-<minor>`; older minor versions stay until pruned.

## Kubernetes repository key expiry

The pkgs.k8s.io signing key is pinned by fingerprint (`K8S_KEY_FPR` in
`scripts/debian-family/kubernetes.sh`) and expires on **2026-12-29**. Before that date:

1. Download the renewed key from `https://pkgs.k8s.io/core:/stable:/v<major>.<minor>/deb/Release.key`.
2. Compare its fingerprint with the value published in the Kubernetes documentation.
3. Update `K8S_KEY_FPR` if it changed; open a pull request.

## Update locked Python dependencies

- **Goal:** regenerate a hash-locked requirements file after editing its `.in` file
  (Renovate does this automatically for version updates).
- **Files:**

    | Input | Lock file | Used by |
    |---|---|---|
    | `tools/requirements-ci.in` | `tools/requirements-ci.txt` | `tools/ci-install.sh` (ansible-core) |
    | `.github/requirements-lint.in` | `.github/requirements-lint.txt` | `validate` workflow (yamllint, zizmor, ansible-lint) |
    | `.github/requirements-docs.in` | `.github/requirements-docs.txt` | `docs` workflow, local `mkdocs serve` |

- **Preconditions:** Python 3.12 (same as the CI runner), `pip-tools` 7.5.1 (works with `pip` 25.2).

1. Edit the `.in` file (exact `==` pins only).
2. From the repository root run, for each changed pair:

    ```bash
    python3 -m piptools compile --quiet --generate-hashes --allow-unsafe --strip-extras \
      -o tools/requirements-ci.txt tools/requirements-ci.in
    ```

    Add `--upgrade` only when you intend to update transitive dependencies.

3. Keep the generated header: Renovate reads the `pip-compile` command from it to regenerate the
   file. Never use `--no-header`.
4. If the command line in the header contains `--no-index` (added by a local pip configuration),
   remove that flag from the header; otherwise Renovate cannot download packages.
5. Review `git diff`: only the intended packages and their hashes change.

- **Check:** `python3 -m pip install --require-hashes -r <lock file>` succeeds; the `validate` and
  `docs` workflows pass.

## Roll back to a previous template

Templates are immutable. To roll back, point consumers to the previous template name (or remove
the bad template so tag-based selection returns the previous one):

```bash
tools/find-template.sh ubuntu-2404 base
```

Then delete the bad template in Proxmox (**VM → More → Remove**) after checking that no VM uses it
as a linked-clone base.

## Prune old templates

- Automatic: `prune` job (monthly, or manual with `prune = true`) keeps the 3 newest templates of
  each image and skips templates that have linked clones.
- Manual dry run and apply:

    ```bash
    tools/prune-templates.sh ubuntu-2404 base 3
    tools/prune-templates.sh ubuntu-2404 base 3 --apply
    ```

## Rotate credentials

| Credential | Steps |
|---|---|
| Proxmox token | `pveum user token remove packer@pve ci` → create again ([setup](setup.md#proxmox-ve)) → update `PROXMOX_TOKEN` |
| WireGuard runner key | Generate a new pair → replace the peer `PublicKey` on the hub → update `WG_RUNNER_PRIVATE_KEY` |
| `SCORECARD_TOKEN` | Regenerate the fine-grained token before expiry → update the repository secret |

Check: **build** with `image = base` passes; **scorecard** passes.

## Update the Talos schematic

1. Edit `talos/schematic.yaml` (extensions).
2. Get the new ID ([Usage → Talos images](usage.md#talos-images)) and update `talos/README.md`.
3. Update the schematic ID wherever clusters consume it.

## Add a new OS version

Example: Ubuntu Server 26.04 LTS next to 24.04.

1. Copy `images/ubuntu-2404-base` to `images/ubuntu-2604-base`; change `image_name`, tags
   (`ubuntu-2604`), ISO URL and checksum, template description.
2. Check the autoinstall boot menu (`boot_command`) and the OpenSCAP profile (`ssg-ubuntu2604-ds.xml`
   if available in SCAP Security Guide; otherwise document the deviation).
3. Add goss checks if anything differs; add the image to `build.yml` and the supported matrix.
4. Do not remove the previous LTS until its standard support ends.

## Move to a different Proxmox host or network

Change `PROXMOX_URL`, `PROXMOX_CA_PEM`, `build_ip_cidr`, `build_gateway` (and the WireGuard
routes); run **build** with `image = base`.
