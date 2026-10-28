"""Regression checks for roster-based vocabulary and dependent runtime projection."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from nrs_tools import split

sys.path.insert(0, str(split.LAWS_ROOT.parent))
from harness.tools import split as runtime_split


class VersionedViewsTests(unittest.TestCase):
    def test_training_definition_exposes_shared_vocabulary(self):
        laws = [{'id':'H', 'title':'', 'text':'School buses display brake lights.'}]
        definitions = [{'id':'D', 'title':'', 'text':'School bus means a designated bus.'}]
        with patch.object(split, 'provenance_support', return_value={}):
            atoms, _, _ = split.training_vocabulary(laws, definitions, {'H'},
                                                   {'ru.school_bus', 'sig.brake_lamp'})
        self.assertEqual(atoms, ['sig.brake_lamp'])

    def test_new_ontology_atom_is_retained_without_lexical_support(self):
        with patch.object(split, 'provenance_support', return_value={}):
            atoms, _, zero = split.training_vocabulary([], [], set(), {'st.on_way'})
        self.assertEqual(atoms, [])
        self.assertEqual(zero, ['st.on_way'])

    def test_contract_row_precedes_unit_row(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp)/'ATOMS.md'
            path.write_text('| `kin.speed` | speed contract | m/s |\n| `kin.speed` | `kin_speed` | m/s |\n')
            with patch.object(split, 'ATOMS_MD', path):
                row = split.held_out_rows(['kin.speed'])['kin.speed']['row']
            self.assertIn('speed contract', row)

    def test_runtime_projection_removes_withheld_fields_and_accessor_families(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp)/'train'
            policy = Path(temp)/'split.json'
            policy.write_text(json.dumps({'test_only_atoms':['dev.school_bus_signal','sig.brake_lamp']}))
            full = runtime_split.SPLITS/'full/TrafficSpec/Core'
            with patch.object(runtime_split, 'SPLIT_ATOMS', policy):
                runtime_split.generate_train(full, out)
            for rel in runtime_split.DEPENDENT:
                text = (out/rel).read_text()
                self.assertNotIn('brakeLamp', text, rel)
                self.assertNotIn('sig_brake_lamp', text, rel)
                self.assertNotIn('dev_school_bus_signal', text, rel)
                for name in ('redFlashing','amberFlashing','stopArm','onTrack'):
                    self.assertNotIn(name, text, rel)
            self.assertIn('sig_brake_lamp', (full/runtime_split.SEMANTICS).read_text())

    def test_training_contract_keeps_prose_without_withheld_identifier(self):
        from nrs_tools.atoms_train import filter_atoms_md
        text = '| `kin.parking_brake` | not the brake lamp (`sig.brake_lamp`) | general |\n'
        filtered = filter_atoms_md(text, ['sig.brake_lamp'], [], [])
        self.assertNotIn('sig.brake_lamp', filtered)
        self.assertIn('not the brake lamp', filtered)
