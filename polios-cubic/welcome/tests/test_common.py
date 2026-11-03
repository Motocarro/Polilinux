import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import polios_common as common  # noqa: E402


def conf(text):
    f = tempfile.NamedTemporaryFile("w", suffix=".conf", delete=False)
    f.write(text)
    f.close()
    return f.name


class Username(unittest.TestCase):
    def test_adds_realm(self):
        self.assertEqual(common.normalize_username(" 10123456 "), "10123456@polimi.it")

    def test_keeps_realm(self):
        self.assertEqual(common.normalize_username("10123456@Polimi.it"), "10123456@polimi.it")

    def test_rejects_bad(self):
        for bad in ("", "  ", "a b", "x@gmail.com", "@polimi.it", "a@b@polimi.it"):
            with self.assertRaises(ValueError, msg=bad):
                common.normalize_username(bad)


class Courses(unittest.TestCase):
    def load(self, text):
        path = conf(text)
        try:
            return common.load_courses(path)
        finally:
            os.unlink(path)

    def test_valid_and_multiline(self):
        courses, problems = self.load(
            "[computer]\ntitle = Comp\ndescription = D\napt = gcc\n  gdb git\nflatpak = org.kicad.KiCad\n")
        self.assertEqual(problems, [])
        self.assertEqual(courses[0].apt, ["gcc", "gdb", "git"])
        self.assertEqual(courses[0].flatpak, ["org.kicad.KiCad"])

    def test_bad_sections_reported_not_fatal(self):
        courses, problems = self.load(
            "[Bad_ID]\napt = gcc\n[inject]\napt = gcc;rm\n[empty]\ntitle = x\n[good]\napt = gcc\n")
        self.assertEqual([c.id for c in courses], ["good"])
        self.assertEqual(len(problems), 3)

    def test_option_like_name_rejected(self):
        _, problems = self.load("[a]\napt = --allow-unauthenticated\n")
        self.assertEqual(len(problems), 1)

    def test_disabled_hidden(self):
        courses, _ = self.load("[a]\napt = gcc\nenabled = no\n")
        self.assertEqual(courses, [])

    def test_extra_known_and_unknown(self):
        courses, problems = self.load("[a]\nextra = google-chrome\n[b]\nextra = evil-script\n")
        self.assertEqual([c.id for c in courses], ["a"])
        self.assertEqual(courses[0].extra, ["google-chrome"])
        self.assertEqual(len(problems), 1)

    def test_duplicate_section_does_not_crash(self):
        courses, problems = common.parse_courses_text("[a]\napt = gcc\n[a]\napt = gdb\n")
        self.assertEqual((courses, len(problems)), ([], 1))

    def test_missing_file(self):
        self.assertEqual(common.load_courses("/nonexistent")[0], [])

    def test_percent_not_interpolated(self):
        courses, _ = self.load("[a]\ntitle = 100% Linux\napt = gcc\n")
        self.assertEqual(courses[0].title, "100% Linux")


if __name__ == "__main__":
    unittest.main()


class Localized(unittest.TestCase):
    def test_fallback_to_default_text(self):
        path = conf("[a]\ntitle = Ciao\ndescription = Desc\napt = gcc\n[b]\ntitle = Ciao\n"
                    "title_en = Hello\ndescription_en = Hi\napt = gcc\n")
        a, b = common.load_courses(path)[0]
        os.unlink(path)
        self.assertEqual(common.localized(a, "en"), ("Ciao", "Desc"))
        self.assertEqual(common.localized(b, "en"), ("Hello", "Hi"))
        self.assertEqual(common.localized(b, "it"), ("Ciao", ""))


class Remote(unittest.TestCase):
    def test_url_rules(self):
        ok = "https://raw.githubusercontent.com/ORG/REPO/main/courses.conf"
        self.assertTrue(common.valid_remote_url(ok))
        for bad in ("http://raw.githubusercontent.com/ORG/REPO/main/courses.conf",
                    "https://evil.example/ORG/REPO/main/courses.conf",
                    "https://raw.githubusercontent.com.evil.example/x/y",
                    "https://user@raw.githubusercontent.com/x/y",
                    "https://raw.githubusercontent.com/", "file:///etc/passwd", ""):
            self.assertFalse(common.valid_remote_url(bad), bad)

    def test_settings_file(self):
        good = conf("[remote]\ncourses_url = https://raw.githubusercontent.com/O/R/main/c.conf\n")
        bad = conf("[remote]\ncourses_url = http://example.com/c.conf\n")
        try:
            self.assertEqual(common.remote_url(good), "https://raw.githubusercontent.com/O/R/main/c.conf")
            self.assertEqual(common.remote_url(bad), "")
            self.assertEqual(common.remote_url("/nonexistent"), "")
        finally:
            os.unlink(good); os.unlink(bad)

    def test_fetch_and_fallback(self):
        import http.server, threading
        body = b"[remote-course]\ntitle = Online\napt = gcc\n"
        class H(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                data = b"x" * (common.MAX_REMOTE_BYTES + 10) if self.path == "/big" else body
                self.send_response(200); self.end_headers(); self.wfile.write(data)
            def log_message(self, *a):
                pass
        srv = http.server.HTTPServer(("127.0.0.1", 0), H)
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        base = "http://127.0.0.1:%d" % srv.server_port
        try:
            self.assertEqual(common.fetch_text(base + "/ok"), body.decode())
            with self.assertRaises(ValueError):
                common.fetch_text(base + "/big")
            saved = common.remote_url, common.fetch_text
            try:
                common.remote_url = lambda *a: base + "/ok"
                courses, _, source = common.load_best()
                self.assertEqual((source, courses[0].id), ("remote", "remote-course"))
                common.remote_url = lambda *a: "http://127.0.0.1:9/none"      # unreachable
                self.assertEqual(common.load_best()[2], "local")
            finally:
                common.remote_url, common.fetch_text = saved
        finally:
            srv.shutdown()

    def test_dict_roundtrip(self):
        c = common.parse_courses_text("[a]\ntitle = T\napt = gcc gdb\nextra = google-chrome\n")[0][0]
        self.assertEqual(common.course_from_dict(common.course_to_dict(c)), c)
