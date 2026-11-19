"""A generated record's analysis replaces its sidecar row; only a posted record keeps the old row."""
import unittest

from publish import LAW_META, split_record


class SplitRecordTests(unittest.TestCase):
    OLD = {"id": "L", "subject": "driver", "refs": ["DEF-X"]}

    def test_generated_record_drops_a_field_it_no_longer_has(self):
        _, meta = split_record({"id": "L", "title": "", "text": "t", "source": "s", "subject": "driver"},
                               LAW_META, self.OLD)
        self.assertNotIn("refs", meta)

    def test_posted_record_keeps_its_sidecar_analysis(self):
        _, meta = split_record({"id": "L", "title": "", "text": "t", "source": "s"}, LAW_META, self.OLD)
        self.assertEqual(meta["refs"], ["DEF-X"])


if __name__ == "__main__":
    unittest.main()
