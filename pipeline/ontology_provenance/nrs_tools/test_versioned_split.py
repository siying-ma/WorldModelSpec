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


class RosterTests(unittest.TestCase):
    LAWS = [{'id': 'NRS-484B-100', 'title': '', 'text': 'a', 'source': 'NRS 484B.100'},
            {'id': 'NRS-484B-200-1', 'title': '', 'text': 'b', 'source': 'NRS 484B.200(1)'},
            {'id': 'NRS-484B-300-1', 'title': '', 'text': 'c', 'source': 'NRS 484B.300(1)'}]

    def test_partition_keeps_corpus_order(self):
        policy = {'training_law_ids': ['NRS-484B-300-1', 'NRS-484B-100'], 'heldout_law_ids': ['NRS-484B-200-1']}
        train, test = split.partition(self.LAWS, policy)
        self.assertEqual([x['id'] for x in train], ['NRS-484B-100', 'NRS-484B-300-1'])
        self.assertEqual([x['id'] for x in test], ['NRS-484B-200-1'])

    def test_partition_refuses_a_roster_that_misses_or_repeats_a_line(self):
        for policy in ({'training_law_ids': ['NRS-484B-100'], 'heldout_law_ids': ['NRS-484B-200-1']},
                       {'training_law_ids': ['NRS-484B-100', 'NRS-484B-300-1'],
                        'heldout_law_ids': ['NRS-484B-200-1', 'NRS-484B-100']}):
            with self.assertRaises(SystemExit):
                split.partition(self.LAWS, policy)

    def test_a_training_line_citing_a_held_out_line_is_found(self):
        train = [{'id': 'NRS-484B-300-1', 'text': 'Except as provided in NRS 484B.307 [NRS-484B-307-2a, NRS-484B-307-6a], ...'},
                 {'id': 'NRS-484D-165-3', 'text': 'during the times mentioned in NRS 484D.100'}]
        meta = {'NRS-484D-165-3': {'refs': ['NRS-484D-100-1']}}
        found = split.training_citations_of_heldout(train, {'NRS-484B-307-2a', 'NRS-484D-100-1'}, meta)
        self.assertEqual(found, [('NRS-484B-300-1', 'NRS-484B-307-2a'), ('NRS-484D-165-3', 'NRS-484D-100-1')])
        self.assertEqual(split.training_citations_of_heldout(train, {'NRS-484B-250-3'}, meta), [])

    def test_definitions_follow_the_lines_they_resolve_from(self):
        definitions = [{'id': 'DEF-NRS-484A-230', 'title': 'School bus defined', 'source': 'NRS 484A.230',
                        'text': '\u201cSchool bus\u201d means every motor vehicle used to transport pupils.'},
                       {'id': 'DEF-NRS-484A-080', 'title': 'Driver defined', 'source': 'NRS 484A.080',
                        'text': '\u201cDriver\u201d means every person who drives a vehicle.'},
                       {'id': 'DEF-LVMC-11-02-130', 'title': 'Roundabout defined', 'source': 'LVMC 11.02.130',
                        'text': '\u201cRoundabout\u201d means an intersection with a circulatory roadway.'}]
        rows = [{'id': 'NRS-484B-353-1', 'title': '', 'source': 'NRS 484B.353(1)',
                 'text': 'The driver of any vehicle, when meeting any school bus, shall stop.'}]
        got = [d['id'] for d in split.split_definitions(rows, definitions)]
        self.assertEqual(got, ['DEF-NRS-484A-230', 'DEF-NRS-484A-080'])
