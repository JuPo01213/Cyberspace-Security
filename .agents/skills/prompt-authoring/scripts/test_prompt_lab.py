"""Offline behavior tests for prompt-lab.py; no external request is ever sent."""

from __future__ import annotations

import importlib.util
import json
import re
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).with_name("prompt-lab.py")
ROOT = SCRIPT.parents[1]

if SCRIPT.exists():
    spec = importlib.util.spec_from_file_location("prompt_lab", SCRIPT)
    assert spec and spec.loader
    prompt_lab = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(prompt_lab)
    LAB_MISSING = None
else:
    prompt_lab = None
    LAB_MISSING = "scripts/prompt-lab.py 尚未实现；接口出现后本文件的测试自动恢复"

requires_lab = unittest.skipIf(LAB_MISSING, LAB_MISSING)


def case_data(**overrides):
    value = {
        "schema": prompt_lab.CASE_SCHEMA,
        "case_id": "contract-test",
        "contract": {
            "goal": "Return the requested result.",
            "required": ["Return the requested result."],
            "prohibited": ["Do not create unrelated artifacts."],
            "completion": ["The requested result is present in output.txt."],
        },
        "input": {"prompt": "Return the requested result."},
    }
    value.update(overrides)
    return value


def transport_data(**overrides):
    value = {
        "schema": prompt_lab.TRANSPORT_SCHEMA,
        "protocol": "openai_chat",
        "url": "http://<REDACTED_LOOPBACK_ADDRESS>:9/unused",
        "model": "fixture-model",
        "parameters": {"temperature": 0},
    }
    value.update(overrides)
    return value


def fake_response(text="READY"):
    return {
        "status": "response_received", "http_status": 200, "headers": {},
        "raw": json.dumps({"text": text}).encode("utf-8"),
        "parsed_json": {"text": text}, "text": text, "text_chars": len(text),
        "bytes": len(json.dumps({"text": text})), "truncated": False, "elapsed_ms": 1.0,
        "error_kind": None, "error_message": None, "redacted_fields": [],
    }


def assessment_data(run_id, *, observed=True, result=None):
    result = result or ("conforming" if observed else "unmeasured")
    return {
        "schema": prompt_lab.ASSESSMENT_SCHEMA,
        "run_id": run_id,
        "observation": "complete" if observed else "missing",
        "result": result,
        "checks": [{"id": "completion-1", "result": "met" if observed else "not_observed",
                    "evidence": ["output.txt"] if observed else []}],
        "deviations": [],
    }


@requires_lab
class CaseContractTests(unittest.TestCase):
    def test_valid_case_loads(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "case.json"
            prompt_lab.write_json(p, case_data())
            loaded = prompt_lab.load_case(p)
            self.assertEqual(loaded["case_id"], "contract-test")
            self.assertEqual(loaded["messages"][0]["content"], "Return the requested result.")

    def test_wrong_schema_and_unknown_fields_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            bad = case_data(schema="prompt-lab/behavior-case-v2")
            p = root / "bad-schema.json"
            prompt_lab.write_json(p, bad)
            with self.assertRaises(prompt_lab.LabError):
                prompt_lab.load_case(p)
            for field in ("verdict", "material_role", "review_examples"):
                bad = case_data(**{field: {}})
                p = root / f"bad-{field}.json"
                prompt_lab.write_json(p, bad)
                with self.assertRaises(prompt_lab.LabError):
                    prompt_lab.load_case(p)

    def test_input_requires_exactly_one_primary_source(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "case.json"
            bad = case_data()
            bad["input"] = {"prompt": "a", "messages": [{"role": "user", "content": "b"}]}
            prompt_lab.write_json(p, bad)
            with self.assertRaises(prompt_lab.LabError):
                prompt_lab.load_case(p)

    def test_messages_file_and_system_file_assembly(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "msgs.json").write_text(json.dumps([{"role": "user", "content": "hi"}]), encoding="utf-8")
            (root / "sys.txt").write_text("system rule", encoding="utf-8")
            case = case_data()
            case["input"] = {"messages_file": "msgs.json", "system_file": "sys.txt"}
            p = root / "case.json"
            prompt_lab.write_json(p, case)
            loaded = prompt_lab.load_case(p)
            self.assertEqual([m["role"] for m in loaded["messages"]], ["system", "user"])


@requires_lab
class BodyAssemblyTests(unittest.TestCase):
    def test_openai_body_includes_messages(self):
        body = prompt_lab.build_body("openai_chat", transport_data(), "m", [{"role": "user", "content": "x"}])
        self.assertEqual(body["model"], "m")
        self.assertEqual(body["messages"][0]["content"], "x")

    def test_anthropic_extracts_system(self):
        messages = [{"role": "system", "content": "rule"}, {"role": "user", "content": "x"}]
        body = prompt_lab.build_body("anthropic_messages", transport_data(protocol="anthropic_messages"), "m", messages)
        self.assertEqual(body["system"], "rule")
        self.assertEqual(len(body["messages"]), 1)

    def test_generic_json_placeholders(self):
        transport = {"protocol": "generic_json", "request_body": {"model": "${MODEL}", "msgs": "${MESSAGES}", "q": "${PROMPT}"}}
        body = prompt_lab.build_body("generic_json", transport, "m", [{"role": "user", "content": "x"}])
        self.assertEqual(body["model"], "m")
        self.assertEqual(body["msgs"][0]["content"], "x")
        self.assertEqual(body["q"], "x")


@requires_lab
class RunTests(unittest.TestCase):
    def prepare(self, root: Path):
        case_path = root / "case.json"
        transport_path = root / "transport.json"
        prompt_lab.write_json(case_path, case_data())
        prompt_lab.write_json(transport_path, transport_data())
        return case_path, transport_path, root / "runs"

    def test_dry_run_builds_artifacts_and_never_sends(self):
        with tempfile.TemporaryDirectory() as d:
            case_path, transport_path, out = self.prepare(Path(d))
            with mock.patch.object(prompt_lab, "perform_request") as perform:
                rc = prompt_lab.run_command(Namespace(case=case_path, transport=transport_path, output_root=out, execute=False))
            self.assertEqual(rc, 0)
            perform.assert_not_called()
            run_dir = next(out.rglob("run.json")).parent
            run = prompt_lab.load_run(run_dir)
            self.assertEqual(run["delivery"]["attempts"], 0)
            self.assertEqual(run["delivery"]["status"], "not_executed")
            for name in ("case.json", "messages.json", "request.json", "input.txt"):
                self.assertTrue((run_dir / name).is_file(), name)

    def test_execute_sends_exactly_once_and_writes_output(self):
        with tempfile.TemporaryDirectory() as d:
            case_path, transport_path, out = self.prepare(Path(d))
            with mock.patch.object(prompt_lab, "perform_request", return_value=fake_response()) as perform:
                rc = prompt_lab.run_command(Namespace(case=case_path, transport=transport_path, output_root=out, execute=True))
            self.assertEqual(rc, 0)
            perform.assert_called_once()
            run_dir = next(out.rglob("run.json")).parent
            run = prompt_lab.load_run(run_dir)
            self.assertEqual(run["delivery"]["attempts"], 1)
            self.assertEqual(run["delivery"]["status"], "response_received")
            self.assertEqual((run_dir / "output.txt").read_text(encoding="utf-8"), "READY")

    def test_secret_redacted_in_written_records(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            case_path, _, out = self.prepare(root)
            transport_path = root / "transport.json"
            prompt_lab.write_json(transport_path, transport_data(api_key_env="DUMMY_KEY"))
            with mock.patch.dict(prompt_lab.os.environ, {"DUMMY_KEY": "<REDACTED_SECRET>"}):
                with mock.patch.object(prompt_lab, "perform_request", return_value=fake_response()):
                    prompt_lab.run_command(Namespace(case=case_path, transport=transport_path, output_root=out, execute=True))
            run_dir = next(out.rglob("run.json")).parent
            request_text = (run_dir / "request.json").read_text(encoding="utf-8")
            transport_text = (run_dir / "transport.json").read_text(encoding="utf-8")
            self.assertNotIn("<REDACTED_SECRET>", request_text)
            self.assertIn("<redacted>", request_text)
            self.assertIn("<configured>", transport_text)

    def test_execute_without_secret_raises(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            case_path, _, out = self.prepare(root)
            transport_path = root / "t.json"
            prompt_lab.write_json(transport_path, transport_data(api_key_env="MISSING_DUMMY_KEY"))
            with mock.patch.dict(prompt_lab.os.environ, {}, clear=True):
                with self.assertRaises(prompt_lab.LabError):
                    prompt_lab.run_command(Namespace(case=case_path, transport=transport_path, output_root=out, execute=True))

    def test_hidden_reasoning_fields_stripped(self):
        parsed, text, hidden = prompt_lab.parse_response(
            json.dumps({"text": "ok", "reasoning": "secret chain", "nested": {"thinking": "x"}}).encode("utf-8"))
        self.assertNotIn("reasoning", parsed)
        self.assertNotIn("thinking", parsed["nested"])
        self.assertEqual(sorted(hidden), ["reasoning", "thinking"])
        self.assertEqual(text, "ok")


@requires_lab
class AssessmentTests(unittest.TestCase):
    def make_run(self, root: Path, *, executed=True, text="READY"):
        case_path = root / "case.json"
        transport_path = root / "transport.json"
        out = root / "runs"
        prompt_lab.write_json(case_path, case_data())
        prompt_lab.write_json(transport_path, transport_data())
        if executed:
            with mock.patch.object(prompt_lab, "perform_request", return_value=fake_response(text)):
                prompt_lab.run_command(Namespace(case=case_path, transport=transport_path, output_root=out, execute=True))
        else:
            prompt_lab.run_command(Namespace(case=case_path, transport=transport_path, output_root=out, execute=False))
        return next(out.rglob("run.json")).parent

    def test_observation_result_consistency(self):
        for bad in (("complete", "unmeasured"), ("partial", "conforming"), ("missing", "deviated")):
            with tempfile.TemporaryDirectory() as d:
                run_dir = self.make_run(Path(d))
                run = prompt_lab.load_run(run_dir)
                a = assessment_data(run["run_id"])
                a["observation"], a["result"] = bad
                p = Path(d) / "a.json"
                prompt_lab.write_json(p, a)
                with self.assertRaises(prompt_lab.LabError):
                    prompt_lab.validate_assessment(p)

    def test_dry_run_can_only_be_unmeasured(self):
        with tempfile.TemporaryDirectory() as d:
            run_dir = self.make_run(Path(d), executed=False)
            run = prompt_lab.load_run(run_dir)
            good = assessment_data(run["run_id"], observed=False)
            p = Path(d) / "good.json"
            prompt_lab.write_json(p, good)
            self.assertEqual(prompt_lab.assess_command(Namespace(run_dir=run_dir, file=p, output=None)), 0)

            bad = assessment_data(run["run_id"], observed=True)
            p2 = Path(d) / "bad.json"
            prompt_lab.write_json(p2, bad)
            with self.assertRaises(prompt_lab.LabError):
                prompt_lab.assess_command(Namespace(run_dir=run_dir, file=p2, output=Path(d) / "x.json"))

    def test_empty_output_cannot_be_observed(self):
        with tempfile.TemporaryDirectory() as d:
            run_dir = self.make_run(Path(d), text="")
            run = prompt_lab.load_run(run_dir)
            run["actual_response"] = {"status": "response_received", "text_chars": 0}
            prompt_lab.write_json(run_dir / "run.json", run)
            a = assessment_data(run["run_id"], observed=True)
            p = Path(d) / "a.json"
            prompt_lab.write_json(p, a)
            with self.assertRaises(prompt_lab.LabError):
                prompt_lab.assess_command(Namespace(run_dir=run_dir, file=p, output=None))


@requires_lab
class CompareTests(unittest.TestCase):
    def test_compare_record_links_both_runs(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            def one(name, text):
                case_path = root / f"{name}.json"
                transport_path = root / f"{name}-t.json"
                out = root / name
                prompt_lab.write_json(case_path, case_data(case_id=name))
                prompt_lab.write_json(transport_path, transport_data())
                with mock.patch.object(prompt_lab, "perform_request", return_value=fake_response(text)):
                    prompt_lab.run_command(Namespace(case=case_path, transport=transport_path, output_root=out, execute=True))
                return next(out.rglob("run.json")).parent
            base, variant = one("base", "READY"), one("variant", "READY\nnote")
            out_file = root / "compare.json"
            rc = prompt_lab.compare_command(Namespace(baseline=base, variant=variant, changed_variable="add anchor",
                                                      held_constant=None, output=out_file))
            self.assertEqual(rc, 0)
            record = json.loads(out_file.read_text(encoding="utf-8"))
            self.assertEqual(record["schema"], prompt_lab.COMPARE_SCHEMA)
            self.assertEqual(record["changed_variable"], "add anchor")
            self.assertIn("model", record["held_constant"])


class DocumentationTests(unittest.TestCase):
    def test_internal_markdown_links_resolve(self):
        pattern = re.compile(r"\[[^\]]+\]\(([^)#]+)(?:#[^)]+)?\)")
        for markdown in sorted(ROOT.rglob("*.md")):
            fenced = False
            for line in markdown.read_text(encoding="utf-8").splitlines():
                stripped = line.lstrip()
                if stripped.startswith("~~~"):
                    fenced = not fenced
                    continue
                # 围栏内、引用块里和行内代码中都是被引用的材料，不是导航链接。
                if fenced or stripped.startswith(">"):
                    continue
                for match in pattern.finditer(re.sub(r"`[^`]*`", "", line)):
                    target = match.group(1)
                    if "://" in target or target.startswith("mailto:"):
                        continue
                    self.assertTrue(
                        (markdown.parent / target).resolve().exists(),
                        f"broken link in {markdown}: {target}",
                    )

    def test_skill_documents_do_not_use_retired_terms(self):
        # behavior-case-v2 是否已取代旧名，需 prompt-lab.py 的 CASE_SCHEMA 才能判定；
        # 该接口缺失时不在离线层断言，见 PROJECT_STATUS.md 的未决一致性项。
        for markdown in sorted(ROOT.rglob("*.md")):
            with self.subTest(markdown=str(markdown.relative_to(ROOT))):
                self.assertNotIn("输入变体", markdown.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
