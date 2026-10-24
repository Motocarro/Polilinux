import importlib.machinery
import importlib.util
import os
import unittest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
HERE = os.path.dirname(os.path.abspath(__file__))
try:
    loader = importlib.machinery.SourceFileLoader("pw", os.path.join(HERE, "..", "polios-welcome"))
    spec = importlib.util.spec_from_loader("pw", loader)
    pw = importlib.util.module_from_spec(spec)
    loader.exec_module(pw)
except ImportError:  # PyQt5 not installed
    pw = None


@unittest.skipIf(pw is None, "PyQt5 not installed")
class Translations(unittest.TestCase):
    def test_same_keys_in_both_languages(self):
        self.assertEqual(set(pw.STRINGS["it"]), set(pw.STRINGS["en"]))

    def test_placeholders_match(self):
        import string
        fields = lambda t: {f for _, f, _, _ in string.Formatter().parse(t) if f}  # noqa: E731
        for key in pw.STRINGS["it"]:
            self.assertEqual(fields(pw.STRINGS["it"][key]), fields(pw.STRINGS["en"][key]), key)


if __name__ == "__main__":
    unittest.main()
