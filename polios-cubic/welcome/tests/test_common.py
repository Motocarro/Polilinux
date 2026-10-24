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
