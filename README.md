# Building and Troubleshooting a Production Linux Web Server

## Project Overview

This project documents the process of turning a clean Ubuntu Server virtual
machine into a working, verifiable Linux web server. The focus was not only on
installing Nginx, but also on understanding the operating-system, networking,
security, service-management, logging, and troubleshooting layers involved.

The lab includes:

- validating the VM's compute, memory, storage, network, and operating-system baseline;
- updating the operating system and configuring the correct timezone;
- configuring SSH public-key authentication from a Windows host;
- deploying a static website through a custom Nginx server block;
- applying host firewall rules with UFW;
- verifying services, listening ports, HTTP responses, and logs;
- troubleshooting controlled HTTP and permission scenarios; and
- confirming SSH, Nginx, UFW, and HTTP availability after a reboot.

This is a production-style learning environment running on a private VMware NAT
network. It is not presented as a fully production-ready internet-facing
system. TLS, disabling SSH password authentication, and additional operating-
system hardening are intentionally deferred to the next hardening lab.

## Architecture

```mermaid
flowchart LR
    Host["Windows Host<br/>PowerShell, browser, SSH client"]
    NAT["VMware NAT<br/>Private DHCP network"]
    UFW["UFW Firewall<br/>Allow 22/tcp and 80/tcp"]
    SSH["OpenSSH Server<br/>TCP 22"]
    Nginx["Nginx<br/>TCP 80"]
    Site["Static website<br/>/var/www/devops-lab"]

    Host --> NAT --> UFW
    UFW --> SSH
    UFW --> Nginx --> Site
```

The Windows host reaches the Ubuntu VM through VMware NAT. UFW denies
unsolicited inbound traffic by default and permits only SSH and HTTP for this
lab. OpenSSH provides administrative access with a passphrase-protected client
key. Nginx listens on port 80 and serves the static website from
`/var/www/devops-lab`.

The VM uses a DHCP-provided private address on `ens33`, so its IP address is not
treated as permanent configuration. The website content is owned by the normal
administrative user, while the Nginx worker runs as `www-data` with read-only
access to the static files.

## Technologies

| Layer | Technology | Purpose |
| --- | --- | --- |
| Host and virtualization | Windows, VMware Workstation | Runs and manages the lab VM |
| Guest operating system | Ubuntu Server 26.04 LTS | Provides the Linux server environment |
| Networking | VMware NAT, DHCP, `iproute2` | Provides private host-to-VM connectivity and network diagnostics |
| Remote administration | OpenSSH, Ed25519 keys | Provides encrypted remote shell access |
| Web server | Nginx 1.28 | Serves the static website over HTTP |
| Service management | systemd | Manages service startup, status, reloads, and boot persistence |
| Host firewall | UFW | Applies default-deny inbound filtering and explicit service rules |
| Diagnostics | `curl`, `ss`, `systemctl`, `tail`, Nginx logs | Verifies each layer and supports troubleshooting |
| Version control | Git | Tracks the website, configuration example, and documentation |

## Repository Structure

```text
.
├── .gitattributes
├── .gitignore
├── README.md
├── configs/
│   └── nginx/
│       └── devops-lab.conf
├── screenshots/
│   ├── 01-custom-site-browser.png
│   ├── 02-final-server-validation.png
│   ├── 03-controlled-404-response.png
│   └── 04-access-log-verification.png
└── site/
    └── index.html
```

- [`configs/nginx/devops-lab.conf`](configs/nginx/devops-lab.conf) is the
  version-controlled copy of the active Nginx server block.
- [`site/index.html`](site/index.html) is the static page deployed to the
  server.
- The repository does not contain passwords, private keys, tokens, or other
  credentials.

## Implementation

1. **Validated the server baseline.** I inspected the hostname, user and sudo
   context, CPU, memory, LVM-backed storage, filesystem usage, network address,
   default route, and existing SSH session before changing the VM.

2. **Prepared the operating system.** I refreshed the APT package metadata,
   reviewed the available upgrades, installed the updates, and configured the
   system timezone for `Europe/Istanbul`.

3. **Configured key-based SSH access.** I generated a passphrase-protected
   Ed25519 key pair on the Windows host, installed only the public key in the
   Ubuntu user's `authorized_keys` file, applied restrictive SSH file
   permissions, and verified a new key-authenticated session.

4. **Installed and validated Nginx.** I confirmed that the service was both
   running and enabled, identified its master and worker processes, and verified
   that it was listening on TCP port 80 for IPv4 and IPv6.

5. **Deployed a dedicated website.** The static page was copied to
   `/var/www/devops-lab`. A dedicated server block was created under
   `sites-available` and enabled with a symbolic link in `sites-enabled`. The
   Ubuntu default site was disabled without deleting its source configuration.

6. **Applied a predictable permission model.** The normal administrative user
   owns the website content. Directories use mode `755` and static files use
   mode `644`, allowing the `www-data` Nginx worker to read the content without
   granting it write access.

7. **Configured the host firewall.** UFW uses `deny incoming` and
   `allow outgoing` defaults. The OpenSSH rule was added before enabling the
   firewall to reduce lockout risk, followed by the Nginx HTTP rule.

8. **Tested before reloading.** Nginx configuration changes were checked with
   `nginx -t` before a graceful reload. HTTP responses and Nginx access logs were
   then used to verify the active configuration.

9. **Verified persistence.** After rebooting the VM, I reconnected with the SSH
   key and confirmed that Nginx, UFW, and HTTP access returned automatically.

## Security Considerations

Implemented controls:

- Daily administration uses a normal user with `sudo`; the root account is not
  used as the interactive working account.
- The SSH private key remains on the Windows host, is protected by a
  passphrase, and is excluded from version control. Only the public key is
  installed on the server.
- UFW denies unsolicited inbound traffic by default. Only TCP 22 (SSH) and TCP
  80 (HTTP) are allowed for this lab.
- Website write access belongs to the administrative user. Nginx serves the
  content through its unprivileged `www-data` workers.
- Nginx configuration is syntax-tested before reload, reducing the risk of
  applying a broken configuration.
- The repository includes ignore rules for environment files, private-key
  formats, editor metadata, logs, and temporary files. Staged changes will also
  be reviewed before every commit because `.gitignore` is not a secret scanner.

Known limitations and deferred hardening:

- SSH password authentication is still enabled. It will be disabled only after
  hardening and recovery-access checks in the next lab.
- The site currently uses plain HTTP and does not provide TLS encryption.
- The VM is reachable only through the private VMware NAT lab network and has
  not been exposed directly to the internet.
- The server uses DHCP; its private IP address may change after a lease renewal
  or network restart.
- Additional SSH restrictions, brute-force protection, automatic security
  update policy, and further OS hardening are outside this lab's scope.

## Troubleshooting

### Incorrect document-root location

The website directory was initially created as `/var/www/html/devops-lab`,
which would make it a child of Ubuntu's default document root rather than an
independent site root. I compared the filesystem path with the intended Nginx
`root`, moved the directory to `/var/www/devops-lab`, and verified the final URL
mapping through the custom server block.

### systemd unit-change warning

An Nginx reload reported that the unit file or its source had changed on disk.
This was not treated as an Nginx syntax error. The systemd manager configuration
was refreshed with `systemctl daemon-reload`, the Nginx configuration was tested
again, and only then was the service gracefully reloaded. A subsequent HTTP
request confirmed availability.

### Controlled `404 Not Found`

A request to `/does-not-exist` returned `404`, while `/` continued to return
`200`. The access log recorded both results. The current error log remained
empty because `try_files $uri $uri/ =404` intentionally converts a missing
static resource into a controlled HTTP response; not every `4xx` response is a
runtime server error.

### Permission experiment

A controlled permission change did not initially produce the expected denial.
Instead of forcing a conclusion, I checked the Nginx worker identity and group
membership and tested file reads as `www-data`. Because the experiment remained
inconclusive without further ACL evidence, I did not claim an unsupported root
cause. I restored the known-good `755` directory and `644` file policy and
verified the site again with `200 OK`.

## Verification

| Check | Evidence |
| --- | --- |
| Nginx configuration | `nginx -t` reported valid syntax and a successful test |
| Service state | Nginx reported `active` and `enabled` |
| Listening sockets | `ss` showed `sshd` on TCP 22 and Nginx on TCP 80 for IPv4 and IPv6 |
| Firewall policy | UFW reported `active`, default-deny incoming, and only SSH/HTTP inbound rules |
| Local HTTP request | `curl -I http://127.0.0.1/` returned `HTTP/1.1 200 OK` |
| Host-to-VM request | Windows `curl.exe -I` returned `HTTP/1.1 200 OK` through the NAT network |
| SSH authentication | A forced public-key-only test returned the expected hostname and Nginx state |
| Logging | Nginx access logs recorded both successful and controlled `404` requests |
| Reboot persistence | SSH, Nginx, UFW, and HTTP availability were confirmed after reboot |

The final acceptance path was:

```text
valid configuration
→ active and boot-enabled service
→ listening socket
→ permitted firewall rule
→ successful host-to-VM HTTP response
→ successful reboot test
```

## Verification Evidence

### Website reached from the Windows host

The custom page was served by the Ubuntu VM and opened from the Windows host
through the private VMware NAT network.

![Custom Nginx website opened in the Windows browser](screenshots/01-custom-site-browser.png)

### Final server-side validation

The final acceptance check confirmed valid Nginx configuration, active and
boot-enabled service state, SSH and HTTP listening sockets, and the expected UFW
policy.

![Nginx, socket, and UFW validation](screenshots/02-final-server-validation.png)

### Controlled 404 response

Requesting a missing path returned the expected Nginx `404 Not Found` response
without affecting the working root page.

![Controlled Nginx 404 response](screenshots/03-controlled-404-response.png)

### Access-log verification

The access log recorded both the successful root request and the controlled
missing-resource request with their respective `200` and `404` status codes.

![Nginx access log containing 200 and 404 responses](screenshots/04-access-log-verification.png)

## What I Learned

- A successful package installation does not prove that a service is usable;
  configuration, process state, sockets, firewall rules, application responses,
  and logs must be checked as separate layers.
- SSH public-key authentication proves possession of the private key without
  sending that private key to the server. A key passphrase protects the local
  private-key file and is different from the remote account password.
- Nginx configuration and website content have different responsibilities:
  `/etc/nginx` defines how requests are handled, while `/var/www` stores the
  content being served.
- `sites-available` stores candidate configurations and `sites-enabled`
  determines which sites Nginx loads through symbolic links.
- Linux directory permissions require the execute bit for traversal, which is
  why static-site directories and files use different modes (`755` and `644`).
- Configuration should be tested before reload, and a graceful reload is
  preferable when a restart is unnecessary.
- HTTP status codes must be interpreted with logs and request context. A
  controlled `404` is different from a stopped service, a refused connection,
  or a firewall timeout.
- Good troubleshooting records observations, hypotheses, checks, conclusions,
  and verification without inventing a root cause when evidence is incomplete.
