"""Offline preservation and navigation checks for the integrated principle handbook."""

from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
BASELINE = 'e8e15afb58c1a48e2ac69f7a6bdafdade4d08d5f'
CORPUS = 'references/input-corpus.md'
PRINCIPLES = {
    'dependency-binding', 'state-transition', 'scope-priority',
    'evidence-completion', 'composition-delegation',
    'representation-interface', 'continuation-examples',
    'salience-density', 'feedback-budget', 'task-specification',
}


def baseline(path):
    return subprocess.check_output(
        ['git', 'show', f'{BASELINE}:{path}'], cwd=ROOT
    ).decode('utf-8-sig')


def current(path):
    return (ROOT / path).read_text(encoding='utf-8-sig')


def cards(text):
    pattern = r'^#### `([^`]+)` ([^\n]+)\n(.*?)(?=^<a id=|^## |^### |\Z)'
    return {m[0]: (m[1], m[2]) for m in re.findall(pattern, text, re.M | re.S)}


def examples(body):
    inputs = re.findall(r'^    ~~~text\n(.*?)\n    ~~~', body, re.M | re.S)
    outputs = re.findall(r'^    > (.*)$', body, re.M)
    return inputs, outputs


class PrincipleHandbookTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.old_text = baseline(CORPUS)
        cls.new_text = current(CORPUS)
        cls.old = cards(cls.old_text)
        cls.new = cards(cls.new_text)

    def test_every_original_card_is_present_once(self):
        ids = re.findall(r'^#### `([^`]+)`', self.new_text, re.M)
        self.assertEqual(105, len(ids))
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(set(self.old), set(self.new))

    def test_original_inputs_and_possible_outputs_are_verbatim(self):
        for case_id, (_, body) in self.old.items():
            with self.subTest(case_id=case_id):
                original = examples(body)
                self.assertEqual((2, 2), tuple(map(len, original)))
                self.assertEqual(original, examples(self.new[case_id][1]))

    def test_original_titles_and_observation_notes_are_preserved(self):
        for case_id, (title, body) in self.old.items():
            with self.subTest(case_id=case_id):
                new_body = self.new[case_id][1]
                self.assertIn(f'- **原题名**：{title}', new_body)
                for label in ['行为检验点', '观察位置', '下一单变量变体']:
                    value = re.search(r'^- \*\*' + label + r'\*\*：(.*)$', body, re.M).group(1)
                    self.assertIn(f'- **原{label}**：{value}', new_body)
                self.assertIn('<details>', new_body)
                self.assertIn('历史材料，不作为当前指导或验收', new_body)

    def test_each_case_is_colocated_with_a_complete_principle(self):
        pattern = r'<a id="([^"\n]+)"></a>\n## ([^\n]+)\n(.*?)(?=^<a id="[^"\n]+"></a>\n## |\Z)'
        sections = re.findall(pattern, self.new_text, re.M | re.S)
        self.assertEqual(PRINCIPLES, {x[0] for x in sections})
        assigned = []
        for anchor, _, body in sections:
            with self.subTest(principle=anchor):
                for label in ['适用与构造', '强化构造例', '压测例', '边界反例', '验收']:
                    self.assertIn(f'**{label}**', body)
                ids = re.findall(r'^#### `([^`]+)`', body, re.M)
                self.assertTrue(ids)
                assigned.extend(ids)
        self.assertEqual(sorted(self.old), sorted(assigned))

    def test_existing_executable_sections_moved_without_loss(self):
        old_playbook = baseline('references/prompt-effectiveness-playbook.md')
        sections = re.findall(r'^### ([^\n]+)\n(.*?)(?=^### |^## |\Z)', old_playbook, re.M | re.S)
        self.assertEqual(8, len(sections))
        new_playbook = current('references/prompt-effectiveness-playbook.md')
        for title, body in sections:
            with self.subTest(section=title):
                self.assertIn(body.strip(), self.new_text)
                self.assertNotIn(body.strip(), new_playbook)

    def test_no_cross_file_case_mapping_or_backlinks(self):
        self.assertNotIn('**指导入口**', self.new_text)
        self.assertNotIn('prompt-effectiveness-playbook.md#', self.new_text)
        for path in ['SKILL.md', 'references/prompt-effectiveness-playbook.md',
                     'references/prompt-validation.md', 'references/prompt-optimization.md',
                     'references/skill-evolution.md']:
            text = current(path)
            self.assertNotRegex(text, r'input-corpus\.md#')
            self.assertNotRegex(text, r'\b(?:EFF|AG|ENG|NV|MM|LANG)-[A-Z0-9-]+-\d{2}\b')

    def test_local_handbook_anchors_resolve(self):
        anchors = re.findall(r'^<a id="([^"\n]+)"></a>', self.new_text, re.M)
        self.assertEqual(len(anchors), len(set(anchors)))
        self.assertEqual(115, len(anchors))
        for target in re.findall(r'\]\(#([^\)]+)\)', self.new_text):
            self.assertIn(target, anchors)

    def test_mechanism_card_titles_do_not_prescribe_an_attack_role(self):
        for case_id, (title, body) in self.new.items():
            with self.subTest(case_id=case_id):
                self.assertNotRegex(title, r'攻击|投毒|劫持|越狱|绕过|窃取|隐蔽C2')
                self.assertIn('**机制定位**', body)
                self.assertIn('**材料性质**', body)

    def test_sample_and_runtime_files_are_untouched(self):
        changed = subprocess.check_output(
            ['git', 'diff', BASELINE, '--name-only'], cwd=ROOT, text=True
        ).splitlines()
        offline_checks = {
            'scripts/test_principle_handbook.py',
            'scripts/test_prompt_lab.py',
        }
        self.assertFalse([
            p for p in changed
            if p.startswith('samples/')
            or (p.startswith('scripts/') and p not in offline_checks)
        ])
        self.assertFalse((ROOT / 'scripts/prompt-lab.py').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
