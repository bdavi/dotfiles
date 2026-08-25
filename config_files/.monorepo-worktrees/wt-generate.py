#!/usr/bin/env python3
"""Generate the compose file and nginx confs for one monorepo worktree slot.

Called by wnew / wregen / wdc; not intended to be run by hand.

The compose file is derived from the *worktree's own* docker-compose.yml so a
branch that changes a service definition gets its version. Resolving it with
--project-directory pointing at the worktree makes every relative bind source
land in the worktree, and -p makes the named volumes come out already
namespaced per slot, which is why so little patching is left to do here.
"""

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

# short name -> (compose service, in-container public API port, nginx conf)
BRANDS = {
    "cg": ("cycle-gear-redline-webapp", 4042, "cyclegear.conf"),
    "rz": ("revzilla-redline-webapp", 4041, "revzilla.conf"),
    "jp": ("jp-cycles-redline-webapp", 4043, "jp_cycles.conf"),
}

# Services built from monorepo code. Everything else is used from the primary stack.
KEEP = [
    "cycle-gear-redline-webapp",
    "revzilla-redline-webapp",
    "jp-cycles-redline-webapp",
    "ecom-webapp",
    "oban-job",
    "revzilla-translation-worker",
]

DEFAULT_ENABLED = {"cycle-gear-redline-webapp"}

PRIMARY_NETWORK = "zla_default"
SHARED_DATA_VOLUME = "zla_shared-data"
CERTS_VOLUME = "zla_certs"
REDLINE_TARGET = "/rz/redline"
GIT_TARGET = "/rz/redline/.git"


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, capture_output=True, text=True, **kw).stdout


def bind(source, target, read_only=False):
    mount = {"type": "bind", "source": str(source), "target": target}
    if read_only:
        mount["read_only"] = True
    return mount


def resolved_config(worktree: Path, project: str) -> dict:
    """The worktree's own compose file, fully resolved."""
    out = run([
        "docker", "compose",
        "-p", project,
        "-f", str(worktree / "docker-compose.yml"),
        "--project-directory", str(worktree),
        "config", "--format", "json",
    ])
    return json.loads(out)


def running_services(project: str) -> set:
    """Which of this slot's containers are actually up.

    The nginx confs key off what is *running*, not what is merely enabled: an
    `upstream {}` name has to resolve when nginx starts, so pointing at a
    container that doesn't exist would stop the sidecar from starting at all.
    Anything not running falls back to the primary stack's container, which is
    the same bargain as sharing its postgres and redis.
    """
    out = subprocess.run(
        ["docker", "ps", "--format", "{{.Names}}"],
        check=False, capture_output=True, text=True,
    ).stdout
    prefix = f"{project}-"
    return {line[len(prefix):] for line in out.split() if line.startswith(prefix)}


def build_compose(cfg: dict, letter: str, index: int, worktree: Path, state: Path,
                  primary_git: Path) -> dict:
    project = f"wt{letter}"
    services = {}

    for orig in KEEP:
        svc = cfg["services"].get(orig)
        if svc is None:
            continue
        svc = json.loads(json.dumps(svc))  # deep copy
        name = f"{project}-{orig}"

        svc.pop("depends_on", None)   # names services that live in the primary project
        svc.pop("ports", None)        # nothing is published; routing goes through the sidecar
        svc["container_name"] = name
        svc["restart"] = "unless-stopped"
        if orig not in DEFAULT_ENABLED:
            svc["scale"] = 0

        env = svc.setdefault("environment", {})
        for short, (service, _port, _conf) in BRANDS.items():
            if service == orig:
                # Without this the app generates links to the primary instance.
                env["ENDPOINT_HOST"] = f"{letter}-{short}.devzla.com"

        volumes = svc.get("volumes", [])
        mounts_redline = any(v.get("target") == REDLINE_TARGET for v in volumes)
        patched = []
        for vol in volumes:
            if vol.get("target") == GIT_TARGET:
                vol = {**vol, "read_only": True}
            patched.append(vol)
        if mounts_redline:
            # The worktree's .git is a *file* pointing at an absolute path inside
            # the primary's git dir; mount that dir at its own path so the
            # pointer resolves. Compile-time `git rev-parse` depends on it.
            patched.append(bind(primary_git, str(primary_git), read_only=True))
        svc["volumes"] = patched

        svc["networks"] = {"default": None}
        services[name] = svc

    services[f"{project}-gateway"] = gateway_service(cfg, letter, index, worktree, state)

    volumes = {}
    for svc in services.values():
        for vol in svc.get("volumes", []):
            if vol.get("type") != "volume":
                continue
            source = vol["source"]
            if source == "shared-data":
                volumes[source] = {"external": True, "name": SHARED_DATA_VOLUME}
            elif source == "certs":
                volumes[source] = {"external": True, "name": CERTS_VOLUME}
            else:
                volumes[source] = {"name": f"{project}_{source}"}

    return {
        "name": project,
        "services": services,
        "volumes": volumes,
        "networks": {
            "default": {"name": PRIMARY_NETWORK, "external": True},
            "slot": {
                "name": f"{project}_slot",
                "ipam": {"config": [{"subnet": f"172.30.{index}.0/24"}]},
            },
        },
    }


def gateway_service(cfg: dict, letter: str, index: int, worktree: Path, state: Path) -> dict:
    nginx = worktree / "zlaverse" / "dev" / "nginx"
    image = cfg["services"].get("gateway", {}).get("image", "nginx:1.24")
    return {
        "image": image,
        "container_name": f"wt{letter}-gateway",
        "restart": "unless-stopped",
        "volumes": [
            bind(worktree / "ecom" / "public", "/rz/shared/data/public"),
            bind(nginx / "nginx.conf", "/etc/nginx/nginx.conf", read_only=True),
            bind(nginx / "mime.types", "/etc/nginx/mime.types", read_only=True),
            bind(nginx / "dhparams.pem", "/etc/nginx/dhparams.pem", read_only=True),
            bind(state / "nginx", "/etc/nginx-upstreams", read_only=True),
            {"type": "volume", "source": "certs", "target": "/mnt/certs", "read_only": True},
        ],
        "networks": {
            "default": None,
            "slot": {"ipv4_address": f"172.30.{index}.10"},
        },
    }


def write_nginx(worktree: Path, state: Path, letter: str, running: set) -> None:
    """Derive the vhost confs from the branch's own.

    Hand-written confs would lose revzilla.conf's `map $request_path $upstream`,
    which routes /admin and ~20 other paths to ecom and which cyclegear.conf
    depends on too. Every conf is emitted so that every `upstream {}` name
    resolves at nginx startup: a brand this worktree isn't running simply points
    at the primary's container, the same way postgres and redis are shared.
    """
    project = f"wt{letter}"
    src = worktree / "zlaverse" / "dev" / "nginx" / "upstreams"
    dst = state / "nginx"
    if dst.exists():
        shutil.rmtree(dst)
    dst.mkdir(parents=True)

    ecom = (src / "ecom.conf").read_text()
    if "ecom-webapp" in running:
        ecom = ecom.replace("server ecom-webapp:", f"server {project}-ecom-webapp:")
    (dst / "ecom.conf").write_text(ecom)

    shutil.copyfile(src / "prod_asset_host.conf", dst / "prod_asset_host.conf")

    for short, (service, port, conf) in BRANDS.items():
        text = (src / conf).read_text()
        host = f"{letter}-{short}.devzla.com"
        text = re.sub(r'server_name\s+"[^"]*";', f"server_name {host};", text)
        if service in running:
            text = text.replace(f"server {service}:4000;", f"server {project}-{service}:4000;")
            text += api_server_block(host, port, f"{project}-{service}")
        (dst / conf).write_text(text)


def api_server_block(host: str, port: int, upstream: str) -> str:
    """Mirror the primary's http://cg.devzla.com:4042/swaggerui ergonomics."""
    return f"""
# Public API endpoint, mirroring the primary's published {port}
server {{
  listen {port};
  server_name {host};

  location / {{
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://{upstream}:{port};
  }}
}}
"""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--letter", required=True)
    parser.add_argument("--index", required=True, type=int)
    parser.add_argument("--worktree", required=True, type=Path)
    parser.add_argument("--state", required=True, type=Path)
    parser.add_argument("--nginx-only", action="store_true",
                        help="refresh only the vhost confs (used after up/restart)")
    args = parser.parse_args()

    project = f"wt{args.letter}"
    worktree = args.worktree.resolve()
    state = args.state

    if not args.nginx_only:
        primary_git = Path(run(["git", "-C", str(worktree), "rev-parse", "--git-common-dir"]).strip())
        if not primary_git.is_absolute():
            primary_git = (worktree / primary_git).resolve()

        cfg = resolved_config(worktree, project)
        generated = build_compose(cfg, args.letter, args.index, worktree, state, primary_git)
        state.mkdir(parents=True, exist_ok=True)
        (state / "compose.yaml").write_text(
            "# Generated by wt-generate.py. Machine-owned: rewritten by wregen.\n"
            "# Put local changes in compose.override.yaml instead.\n"
            + yaml.safe_dump(generated, sort_keys=False, width=1000)
        )

    running = running_services(project)
    write_nginx(worktree, state, args.letter, running)

    brands = sorted(short for short, (svc, _p, _c) in BRANDS.items() if svc in running)
    if brands:
        print(f"slot {args.letter}: routing to this worktree for {', '.join(brands)}")
    else:
        print(f"slot {args.letter}: nothing running yet — routing falls back to the primary stack")
    return 0


if __name__ == "__main__":
    sys.exit(main())
