#!/usr/bin/python3
"""PoliOS Welcome: first-run wizard (Wi-Fi if needed, then course software)."""
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PyQt5.QtCore import QProcess, Qt
from PyQt5.QtWidgets import (QApplication, QFormLayout, QLabel, QLineEdit,
                             QListWidget, QListWidgetItem, QPlainTextEdit,
                             QProgressBar, QVBoxLayout, QWizard, QWizardPage)

import courses as manifests
import wifi

HELPER = "/usr/lib/polios-welcome/install-courses"
DONE_FILE = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "polios" / "welcome-done"

PAGE_WIFI, PAGE_COURSES, PAGE_INSTALL, PAGE_DONE = range(4)


def is_online():
    try:
        out = subprocess.run(["nmcli", "-t", "-g", "CONNECTIVITY", "general"],
                             capture_output=True, text=True, timeout=5).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return False
    return out == "full"


def in_live_session():
    try:
        return "boot=casper" in Path("/proc/cmdline").read_text()
    except OSError:
        return False


def mark_done():
    DONE_FILE.parent.mkdir(parents=True, exist_ok=True)
    DONE_FILE.touch()


class WifiPage(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Connect to the university Wi-Fi")
        self.setSubTitle("Enter your Politecnico credentials. If you are on a virtual "
                         "machine or already online, you can skip this step.")
        form = QFormLayout(self)
        self.user = QLineEdit()
        self.password = QLineEdit()
        self.password.setEchoMode(QLineEdit.Password)
        self.error = QLabel()
        self.error.setStyleSheet("color: #c0392b")
        form.addRow("Username:", self.user)
        form.addRow("Password:", self.password)
        form.addRow(self.error)

    def validatePage(self):
        if not self.user.text() and not self.password.text():
            return True  # skipped
        try:
            wifi.configure(self.user.text(), self.password.text())
        except Exception as e:  # show the problem, let the user continue
            self.error.setText(f"Could not configure Wi-Fi: {e}")
            self.password.clear()
            return False
        return True


class CoursesPage(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Choose your courses")
        self.setSubTitle("Tick the courses you follow: the software they need will be installed.")
        self.setCommitPage(True)
        lay = QVBoxLayout(self)
        self.list = QListWidget()
        self.notice = QLabel()
        self.notice.setWordWrap(True)
        lay.addWidget(self.list)
        lay.addWidget(self.notice)
        self.courses = manifests.load_courses()
        for c in sorted(self.courses.values(), key=lambda c: c["name"].lower()):
            text = c["name"] + (f"\n{c['description']}" if c["description"] else "")
            item = QListWidgetItem(text)
            item.setFlags(item.flags() | Qt.ItemIsUserCheckable)
            item.setCheckState(Qt.Unchecked)
            item.setData(Qt.UserRole, c["id"])
            self.list.addItem(item)
        if not self.courses:
            self.notice.setText("No courses are available yet.")

    def initializePage(self):
        self.wizard().setButtonText(QWizard.CommitButton, "Continue")
        if self.courses and not is_online():
            self.notice.setText("You are not connected to the internet: the installation "
                                "will fail until you connect.")

    def selected_ids(self):
        return [self.list.item(i).data(Qt.UserRole) for i in range(self.list.count())
                if self.list.item(i).checkState() == Qt.Checked]


class InstallPage(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Installing")
        self._done = False
        lay = QVBoxLayout(self)
        self.status = QLabel("Starting...")
        self.bar = QProgressBar()
        self.bar.setRange(0, 0)
        self.log = QPlainTextEdit()
        self.log.setReadOnly(True)
        for w in (self.status, self.bar, self.log):
            lay.addWidget(w)

    def initializePage(self):
        self._done = False
        self.wizard().button(QWizard.CancelButton).setEnabled(False)
        self.status.setText("Installing the selected software (this can take a while)...")
        self.proc = QProcess(self)
        self.proc.setProcessChannelMode(QProcess.MergedChannels)
        self.proc.readyRead.connect(self._read)
        self.proc.finished.connect(self._finished)
        self.proc.errorOccurred.connect(lambda _e: self._end(False, "Could not start the installer."))
        self.proc.start("pkexec", [HELPER, *self.wizard().selected_ids()])

    def _read(self):
        text = bytes(self.proc.readAll()).decode(errors="replace").rstrip()
        if text:
            self.log.appendPlainText(text)

    def _finished(self, code, _status):
        self._end(code == 0, "Done." if code == 0 else f"The installation failed (exit code {code}). See the log.")

    def _end(self, ok, message):
        if self._done:
            return
        self._done = True
        self.wizard().install_ok = ok
        self.status.setText(message)
        self.bar.setRange(0, 1)
        self.bar.setValue(1 if ok else 0)
        self.wizard().button(QWizard.CancelButton).setEnabled(True)
        self.completeChanged.emit()

    def isComplete(self):
        return self._done


class DonePage(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("All set")
        lay = QVBoxLayout(self)
        self.label = QLabel()
        self.label.setWordWrap(True)
        lay.addWidget(self.label)

    def initializePage(self):
        if self.wizard().install_ok:
            self.label.setText("Welcome to PoliOS! You can run \"PoliOS Welcome\" again from "
                               "the menu to add more courses.")
        else:
            self.label.setText("Something went wrong during the installation. Check your "
                               "internet connection and run \"PoliOS Welcome\" again from the menu.")


class Wizard(QWizard):
    def __init__(self):
        super().__init__()
        self.install_ok = True
        self.setWindowTitle("Welcome to PoliOS")
        self.setWizardStyle(QWizard.ModernStyle)
        self.setMinimumSize(640, 480)
        self.setPage(PAGE_WIFI, WifiPage())
        self.setPage(PAGE_COURSES, CoursesPage())
        self.setPage(PAGE_INSTALL, InstallPage())
        self.setPage(PAGE_DONE, DonePage())
        # Wi-Fi comes first: installing courses needs internet.
        self.setStartId(PAGE_WIFI if (wifi.ENABLED and not is_online()) else PAGE_COURSES)

    def selected_ids(self):
        return self.page(PAGE_COURSES).selected_ids()

    def nextId(self):
        cur = self.currentId()
        if cur == PAGE_WIFI:
            return PAGE_COURSES
        if cur == PAGE_COURSES:
            return PAGE_INSTALL if self.selected_ids() else PAGE_DONE
        if cur == PAGE_INSTALL:
            return PAGE_DONE
        return -1


def main():
    if "--first-run" in sys.argv and (DONE_FILE.exists() or in_live_session()):
        return 0
    app = QApplication(sys.argv)
    wiz = Wizard()
    wiz.finished.connect(lambda _result: mark_done())
    wiz.show()
    return app.exec_()


if __name__ == "__main__":
    sys.exit(main())
