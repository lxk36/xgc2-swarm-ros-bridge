#!/usr/bin/env bash
set -euo pipefail

DEB_DIR=""
APT_REPO_HOST="${APT_REPO_HOST:-}"
APT_REPO_PORT="${APT_REPO_PORT:-22}"
APT_REPO_SSH_KEY="${APT_REPO_SSH_KEY:-}"
APT_REPO_KNOWN_HOSTS="${APT_REPO_KNOWN_HOSTS:-}"
APT_REPO_INCOMING="${APT_REPO_INCOMING:-/srv/apt/incoming}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deb-dir)
      DEB_DIR="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${DEB_DIR}" ]]; then
  echo "--deb-dir is required" >&2
  exit 1
fi
if [[ -z "${APT_REPO_HOST}" || -z "${APT_REPO_SSH_KEY}" || -z "${APT_REPO_KNOWN_HOSTS}" ]]; then
  echo "APT_REPO_HOST, APT_REPO_SSH_KEY, and APT_REPO_KNOWN_HOSTS are required" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

key_file="${tmp_dir}/apt_repo_key"
known_hosts_file="${tmp_dir}/known_hosts"
printf '%s\n' "${APT_REPO_SSH_KEY}" > "${key_file}"
printf '%s\n' "${APT_REPO_KNOWN_HOSTS}" > "${known_hosts_file}"
chmod 0600 "${key_file}" "${known_hosts_file}"

shopt -s nullglob
debs=("${DEB_DIR}"/ros-*-swarm-ros-bridge_*.deb)
shopt -u nullglob
if [[ "${#debs[@]}" -eq 0 ]]; then
  echo "no swarm_ros_bridge debs found in ${DEB_DIR}" >&2
  exit 1
fi

scp -P "${APT_REPO_PORT}" \
  -i "${key_file}" \
  -o UserKnownHostsFile="${known_hosts_file}" \
  -o StrictHostKeyChecking=yes \
  "${debs[@]}" \
  "${APT_REPO_HOST}:${APT_REPO_INCOMING}/"
