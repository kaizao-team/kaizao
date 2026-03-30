from __future__ import annotations

import importlib.util
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "pr_ai_review.py"
SPEC = importlib.util.spec_from_file_location("pr_ai_review", MODULE_PATH)
assert SPEC and SPEC.loader
pr_ai_review = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(pr_ai_review)


def make_finding(*, file: str, title: str, severity: str = "medium", line: int = 10) -> dict:
    return pr_ai_review.attach_finding_key(
        {
            "severity": severity,
            "file": file,
            "line": line,
            "title": title,
            "body": "详细说明。",
        }
    )


def test_render_inline_comment_embeds_hidden_finding_key() -> None:
    finding = make_finding(file="app/lib/home.dart", title="重复评论去重失效")

    body = pr_ai_review.render_inline_comment(finding)

    assert finding["key"] in body
    assert pr_ai_review.extract_finding_key(body=body, path=finding["file"]) == finding["key"]


def test_extract_finding_key_falls_back_to_path_and_title() -> None:
    finding = make_finding(file="app/lib/home.dart", title="重复评论去重失效")
    body = "[中] 重复评论去重失效\n\n这里是说明。"

    assert pr_ai_review.extract_finding_key(body=body, path=finding["file"]) == finding["key"]


def test_sync_review_threads_reuses_resolves_and_reopens(monkeypatch) -> None:
    active = make_finding(file="app/lib/a.dart", title="问题 A")
    reopened = make_finding(file="app/lib/b.dart", title="问题 B")

    resolved_threads: list[str] = []
    reopened_threads: list[str] = []
    monkeypatch.setattr(
        pr_ai_review,
        "resolve_review_thread",
        lambda *, thread_id, github_token: resolved_threads.append(thread_id),
    )
    monkeypatch.setattr(
        pr_ai_review,
        "unresolve_review_thread",
        lambda *, thread_id, github_token: reopened_threads.append(thread_id),
    )

    result = pr_ai_review.sync_review_threads(
        github_token="token",
        findings=[active, reopened],
        existing_threads=[
            {
                "id": "thread-active",
                "key": active["key"],
                "path": active["file"],
                "is_resolved": False,
                "is_outdated": False,
                "created_at": "2026-03-29T10:00:00Z",
            },
            {
                "id": "thread-active-older",
                "key": active["key"],
                "path": active["file"],
                "is_resolved": False,
                "is_outdated": True,
                "created_at": "2026-03-29T09:30:00Z",
            },
            {
                "id": "thread-fixed",
                "key": "old-fixed-key",
                "path": "app/lib/c.dart",
                "is_resolved": False,
                "is_outdated": True,
                "created_at": "2026-03-29T09:00:00Z",
            },
            {
                "id": "thread-reopen",
                "key": reopened["key"],
                "path": reopened["file"],
                "is_resolved": True,
                "is_outdated": True,
                "created_at": "2026-03-29T08:00:00Z",
            },
        ],
        reviewed_files={"app/lib/a.dart", "app/lib/b.dart", "app/lib/c.dart"},
        changed_files={"app/lib/a.dart", "app/lib/b.dart", "app/lib/c.dart"},
    )

    assert resolved_threads == ["thread-active-older", "thread-fixed"]
    assert reopened_threads == ["thread-reopen"]
    assert result["resolved_count"] == 2
    assert result["reopened_count"] == 1
    assert set(result["threads_by_key"]) == {active["key"], reopened["key"]}


def test_sync_review_threads_keeps_unreviewed_changed_files_open(monkeypatch) -> None:
    monkeypatch.setattr(
        pr_ai_review,
        "resolve_review_thread",
        lambda *, thread_id, github_token: (_ for _ in ()).throw(AssertionError("should not resolve")),
    )
    monkeypatch.setattr(
        pr_ai_review,
        "unresolve_review_thread",
        lambda *, thread_id, github_token: (_ for _ in ()).throw(AssertionError("should not unresolve")),
    )

    result = pr_ai_review.sync_review_threads(
        github_token="token",
        findings=[],
        existing_threads=[
            {
                "id": "thread-skipped",
                "key": "legacy-key",
                "path": "app/lib/skipped.dart",
                "is_resolved": False,
                "is_outdated": False,
                "created_at": "2026-03-29T09:00:00Z",
            }
        ],
        reviewed_files=set(),
        changed_files={"app/lib/skipped.dart"},
    )

    assert result["resolved_count"] == 0
    assert result["reopened_count"] == 0
    assert result["threads_by_key"] == {}
