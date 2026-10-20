"""Writes assets/licenses/android.txt: the licences of the native Android
libraries bundled in the release build (AndroidX, CameraX, ML Kit, Kotlin...).

Flutter's licence page already covers Dart packages and the Flutter engine,
but not these, so the app adds this file to it (see lib/util/licenses.dart).
Run after changing plugins or dependencies, with JAVA_HOME set:

    JAVA_HOME=/snap/android-studio/current/jbr python3 tool/native_licenses.py

Licences come from each library's Maven POM in the Gradle cache.
"""
import pathlib
import re
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = pathlib.Path.home() / '.gradle/caches/modules-2/files-2.1'
OUT = ROOT / 'assets/licenses/android.txt'
APACHE_URL = 'https://www.apache.org/licenses/LICENSE-2.0.txt'
SEPARATOR = '\n--------\n'
# Covered by Flutter's own licence collection.
SKIP_GROUPS = ('io.flutter',)


def dependencies():
    out = subprocess.run(
        ['./gradlew', '-q', ':app:dependencies', '--configuration', 'releaseRuntimeClasspath'],
        cwd=ROOT / 'android', check=True, capture_output=True, text=True).stdout
    deps = set()
    for line in out.splitlines():
        m = re.search(r'--- ([\w.-]+):([\w.-]+):(\S+)(?: -> (\S+))?', line)
        if not m:
            continue
        group, artifact, version, resolved = m.groups()
        version = resolved or version
        version = re.sub(r'^\{(?:prefer|strictly|require) ([^}]+)\}$', r'\1', version)
        if group not in SKIP_GROUPS and not version.startswith('{'):
            deps.add((group, artifact, version))
    return sorted(deps)


def pom(group, artifact, version):
    hits = list((CACHE / group / artifact / version).glob(f'*/{artifact}-{version}.pom'))
    return ET.parse(hits[0]).getroot() if hits else None


def licences(group, artifact, version, depth=0):
    root = pom(group, artifact, version)
    if root is None or depth > 5:
        return []
    ns = {'m': root.tag.split('}')[0].strip('{')} if root.tag.startswith('{') else {'m': ''}
    q = (lambda p: p.replace('m:', '')) if not ns['m'] else (lambda p: p)
    found = [
        ((l.findtext(q('m:name'), '', ns) or '').strip(), (l.findtext(q('m:url'), '', ns) or '').strip())
        for l in root.findall(q('m:licenses/m:license'), ns)
    ]
    if found:
        return found
    parent = root.find(q('m:parent'), ns)
    if parent is None:
        return []
    return licences(parent.findtext(q('m:groupId'), '', ns), parent.findtext(q('m:artifactId'), '', ns),
                    parent.findtext(q('m:version'), '', ns), depth + 1)


def normalise(name, url):
    if 'apache' in name.lower() or 'apache.org/licenses/LICENSE-2.0' in url:
        return 'Apache License 2.0', APACHE_URL
    return name, url


def main():
    groups = {}
    unknown = []
    for group, artifact, version in dependencies():
        found = licences(group, artifact, version)
        if not found:
            unknown.append(f'{group}:{artifact}:{version}')
            continue
        for name, url in found:
            groups.setdefault(normalise(name, url), []).append(f'{group}:{artifact}')
    if unknown:
        print('No licence found for:\n  ' + '\n  '.join(unknown), file=sys.stderr)
        sys.exit(1)

    apache = urllib.request.urlopen(APACHE_URL, timeout=30).read().decode()
    entries = []
    for (name, url), artifacts in sorted(groups.items()):
        text = apache if url == APACHE_URL else f'{name}\n{url}'
        entries.append(', '.join(sorted(set(artifacts))) + '\n' + text.strip())
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(SEPARATOR.join(entries) + '\n')
    for (name, _), artifacts in sorted(groups.items()):
        print(f'{len(set(artifacts)):4d}  {name}')
    print('wrote', OUT.relative_to(ROOT))


if __name__ == '__main__':
    main()
