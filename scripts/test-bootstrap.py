#!/usr/bin/env python3
"""Run bootstrap against temporary command stubs, never real installers."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class BootstrapTest(unittest.TestCase):
    def run_bootstrap(self, scenario):
        with tempfile.TemporaryDirectory(prefix="dotfiles-bootstrap-test-") as directory:
            root = Path(directory)
            commands = root / "bin"
            commands.mkdir()
            stubs = {
                "xcode-select": '''
if [ "$1" = --install ]; then echo CLT_INSTALL; exit 0; fi
[ "$SCENARIO" != missing-clt ]
''',
                "curl": '''
echo DOWNLOAD >&2
payload='echo INSTALLER_EXECUTED'
if [ "$SCENARIO" = installer-failure ]; then payload="$payload; exit 9"; fi
output=''
while [ "$#" -gt 0 ]; do
  if [ "$1" = -o ]; then output="$2"; shift; fi
  shift
done
if [ -n "$output" ]; then printf '%s\\n' "$payload" > "$output"; else printf '%s\\n' "$payload"; fi
if [ "$SCENARIO" = download-failure ]; then exit 18; fi
''',
                "brew": '''
if [ "$1" = shellenv ]; then echo ':'; else echo BREW_INSTALL; fi
''',
                "chezmoi": 'echo "CHEZMOI_$1"\n',
            }
            for name, body in stubs.items():
                executable = commands / name
                executable.write_text("#!/bin/bash\n" + body)
                executable.chmod(0o700)
            bash_env = root / "bash-env"
            bash_env.write_text('''command() {
if [[ "$1" == -v && "${2:-}" == brew && "$SCENARIO" != existing ]]; then return 1; fi
builtin command "$@"
}
''')
            original = Path(__file__).with_name("bootstrap.sh").read_text()
            # Redirect the fixed Apple Silicon brew path into the same command fixture.
            script = root / "bootstrap.sh"
            script.write_text(original.replace("/opt/homebrew/bin/brew", str(commands / "brew")))
            environment = dict(os.environ, PATH=f"{commands}:/usr/bin:/bin",
                               BASH_ENV=str(bash_env), SCENARIO=scenario, TMPDIR=str(root))
            result = subprocess.run(["/bin/bash", str(script)], env=environment,
                                    text=True, capture_output=True)
            self.assertEqual(list(root.glob("dotfiles-homebrew*")), [], "installer temp file leaked")
            return result.returncode, result.stdout + result.stderr

    def test_download_failure_never_executes_partial_script(self):
        code, output = self.run_bootstrap("download-failure")
        self.assertNotEqual(code, 0)
        self.assertNotIn("INSTALLER_EXECUTED", output)
        self.assertNotIn("BREW_INSTALL", output)
        self.assertNotIn("CHEZMOI_", output)

    def test_fresh_install(self):
        code, output = self.run_bootstrap("fresh")
        self.assertEqual(code, 0, output)
        self.assertIn("INSTALLER_EXECUTED", output)
        self.assertIn("CHEZMOI_apply", output)

    def test_existing_brew_skips_installer(self):
        code, output = self.run_bootstrap("existing")
        self.assertEqual(code, 0, output)
        self.assertNotIn("DOWNLOAD", output)
        self.assertNotIn("INSTALLER_EXECUTED", output)
        self.assertIn("CHEZMOI_apply", output)

    def test_installer_failure_stops_bootstrap(self):
        code, output = self.run_bootstrap("installer-failure")
        self.assertNotEqual(code, 0)
        self.assertNotIn("BREW_INSTALL", output)

    def test_missing_clt_stops_before_download(self):
        code, output = self.run_bootstrap("missing-clt")
        self.assertNotEqual(code, 0)
        self.assertIn("CLT_INSTALL", output)
        self.assertNotIn("DOWNLOAD", output)


if __name__ == "__main__":
    unittest.main()
