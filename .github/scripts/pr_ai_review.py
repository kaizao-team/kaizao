from __future__ import annotations

import json
import os
import sys
import textwrap
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any


COMMENT_MARKER = "<!-- openai-gpt54-xhigh-pr-review -->"
COMMENT_TITLE = "OpenAI GPT-5.4 xhigh PR Review"
GITHUB_API_VERSION = "2022-11-28"


def main() -> int:
    event = load_json(Path(required_env("GITHUB_EVENT_PATH")))
    repo = required_env("GITHUB_REPOSITORY")
    github_token = required_env("GITHUB_TOKEN")
    api_key = required_env("OPENAI_API_KEY")
    base_url = required_env("OPENAI_BASE_URL").rstrip("/")
    model = required_env("OPENAI_MODEL")
    reasoning_effort = required_env("OPENAI_REASONING_EFFORT")

    pr = event.get("pull_request") or {}
    pr_number = pr.get("number") or event.get("number")
    if not pr_number:
        raise RuntimeError("pull_request.number is missing from the workflow event payload.")

    prompt = Path(required_env("AI_REVIEW_PROMPT_FILE")).read_text(encoding="utf-8")
    diff_path = Path(required_env("AI_REVIEW_DIFF_FILE"))
    files_path = Path(required_env("AI_REVIEW_FILES_FILE"))
    result_path = Path(required_env("AI_REVIEW_RESULT_FILE"))

    diff_text = diff_path.read_text(encoding="utf-8")
    files_text = files_path.read_text(encoding="utf-8").strip()
    max_diff_chars = int(os.getenv("AI_REVIEW_MAX_DIFF_CHARS", "120000"))
    truncated_diff = clip_text(diff_text, max_diff_chars)

    user_input = build_user_input(pr, files_text, truncated_diff)
    review = run_openai_review(
        base_url=base_url,
        api_key=api_key,
        model=model,
        reasoning_effort=reasoning_effort,
        developer_prompt=prompt,
        user_input=user_input,
    )
    normalized = normalize_review(review)
    result_path.parent.mkdir(parents=True, exist_ok=True)
    result_path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")

    comment_body = render_comment(normalized, model=model, reasoning_effort=reasoning_effort)
    upsert_issue_comment(
        repo=repo,
        issue_number=pr_number,
        github_token=github_token,
        body=comment_body,
    )
    write_step_summary(normalized)

    if normalized["verdict"] == "fail":
        return 1
    return 0


def required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def clip_text(value: str, limit: int) -> str:
    if len(value) <= limit:
        return value
    omitted = len(value) - limit
    suffix = f"\n\n[diff truncated: omitted {omitted} trailing characters]"
    return value[: limit - len(suffix)] + suffix


def build_user_input(pr: dict[str, Any], files_text: str, diff_text: str) -> str:
    title = pr.get("title") or ""
    body = pr.get("body") or ""
    base_ref = pr.get("base", {}).get("ref") or ""
    head_ref = pr.get("head", {}).get("ref") or ""
    author = pr.get("user", {}).get("login") or ""
    changed_files = pr.get("changed_files")
    additions = pr.get("additions")
    deletions = pr.get("deletions")

    return textwrap.dedent(
        f"""\
        Repository pull request metadata:
        - Title: {title}
        - Author: {author}
        - Base ref: {base_ref}
        - Head ref: {head_ref}
        - Changed files count: {changed_files}
        - Additions: {additions}
        - Deletions: {deletions}

        PR description:
        {body or "(empty)"}

        Changed files:
        {files_text or "(no changed files list available)"}

        Unified diff:
        {diff_text}
        """
    )


def run_openai_review(
    *,
    base_url: str,
    api_key: str,
    model: str,
    reasoning_effort: str,
    developer_prompt: str,
    user_input: str,
) -> dict[str, Any]:
    schema = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "verdict": {
                "type": "string",
                "enum": ["pass", "warn", "fail"],
            },
            "summary": {
                "type": "string",
            },
            "findings": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "properties": {
                        "severity": {
                            "type": "string",
                            "enum": ["low", "medium", "high"],
                        },
                        "file": {"type": "string"},
                        "line": {"type": "integer", "minimum": 0},
                        "title": {"type": "string"},
                        "body": {"type": "string"},
                    },
                    "required": ["severity", "file", "line", "title", "body"],
                },
            },
        },
        "required": ["verdict", "summary", "findings"],
    }

    payload = {
        "model": model,
        "store": False,
        "reasoning": {"effort": reasoning_effort},
        "instructions": developer_prompt,
        "input": user_input,
        "max_output_tokens": 3500,
        "text": {
            "format": {
                "type": "json_schema",
                "name": "pr_review_result",
                "strict": True,
                "schema": schema,
            }
        },
    }

    request = urllib.request.Request(
        url=f"{base_url}/responses",
        data=json.dumps(payload).encode("utf-8"),
        method="POST",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=180) as response:
            body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        error_body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"OpenAI review request failed with {exc.code}: {error_body}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"OpenAI review request failed: {exc}") from exc

    raw = json.loads(body)
    output_text = extract_output_text(raw)
    if not output_text:
        raise RuntimeError(f"OpenAI review response did not include output text: {body}")

    try:
        return json.loads(output_text)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Failed to parse model JSON output: {output_text}") from exc


def extract_output_text(response_body: dict[str, Any]) -> str:
    parts: list[str] = []
    for output_item in response_body.get("output", []):
        for content_item in output_item.get("content", []):
            if content_item.get("type") == "output_text":
                parts.append(content_item.get("text", ""))
    return "".join(parts).strip()


def normalize_review(review: dict[str, Any]) -> dict[str, Any]:
    verdict = review.get("verdict", "warn")
    if verdict not in {"pass", "warn", "fail"}:
        verdict = "warn"

    findings = []
    for item in review.get("findings", []):
        severity = item.get("severity", "medium")
        if severity not in {"low", "medium", "high"}:
            severity = "medium"

        line_value = item.get("line", 0)
        if not isinstance(line_value, int) or line_value < 0:
            line_value = 0

        findings.append(
            {
                "severity": severity,
                "file": str(item.get("file", "")).strip(),
                "line": line_value,
                "title": str(item.get("title", "")).strip(),
                "body": str(item.get("body", "")).strip(),
            }
        )

    highest = max((severity_rank(item["severity"]) for item in findings), default=0)
    if highest >= severity_rank("high"):
        verdict = "fail"
    elif findings and verdict == "pass":
        verdict = "warn"
    elif not findings and verdict == "fail":
        verdict = "warn"

    summary = str(review.get("summary", "")).strip() or "No summary provided."
    findings.sort(key=lambda item: (-severity_rank(item["severity"]), item["file"], item["line"]))
    return {
        "verdict": verdict,
        "summary": summary,
        "findings": findings,
    }


def severity_rank(value: str) -> int:
    return {"low": 1, "medium": 2, "high": 3}.get(value, 0)


def render_comment(review: dict[str, Any], *, model: str, reasoning_effort: str) -> str:
    verdict = review["verdict"].upper()
    lines = [
        COMMENT_MARKER,
        f"## {COMMENT_TITLE}",
        "",
        f"- Verdict: `{verdict}`",
        f"- Model label: `{model}` / `{reasoning_effort}`",
        "- Comment transport: `github-actions[bot]` via workflow token",
        "",
        review["summary"],
    ]

    findings = review["findings"]
    if findings:
        lines.extend(["", "### Findings"])
        for item in findings:
            location = item["file"] or "(file not provided)"
            if item["line"] > 0:
                location = f"{location}:{item['line']}"
            lines.extend(
                [
                    f"- [{item['severity']}] `{location}` {item['title']}",
                    f"  {item['body']}",
                ]
            )
    else:
        lines.extend(["", "No actionable findings in this diff."])

    return "\n".join(lines).strip() + "\n"


def write_step_summary(review: dict[str, Any]) -> None:
    summary_path = os.getenv("GITHUB_STEP_SUMMARY")
    if not summary_path:
        return

    body = render_comment(
        review,
        model=os.getenv("OPENAI_MODEL", "unknown"),
        reasoning_effort=os.getenv("OPENAI_REASONING_EFFORT", "unknown"),
    )
    Path(summary_path).write_text(body, encoding="utf-8")


def upsert_issue_comment(*, repo: str, issue_number: int, github_token: str, body: str) -> None:
    comments = github_api_request(
        repo=repo,
        github_token=github_token,
        method="GET",
        path=f"/repos/{repo}/issues/{issue_number}/comments?per_page=100",
    )

    existing_comment = next(
        (item for item in comments if COMMENT_MARKER in (item.get("body") or "")),
        None,
    )

    if existing_comment:
        github_api_request(
            repo=repo,
            github_token=github_token,
            method="PATCH",
            path=f"/repos/{repo}/issues/comments/{existing_comment['id']}",
            payload={"body": body},
        )
        return

    github_api_request(
        repo=repo,
        github_token=github_token,
        method="POST",
        path=f"/repos/{repo}/issues/{issue_number}/comments",
        payload={"body": body},
    )


def github_api_request(
    *,
    repo: str,
    github_token: str,
    method: str,
    path: str,
    payload: dict[str, Any] | None = None,
) -> Any:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url=f"https://api.github.com{path}",
        data=data,
        method=method,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {github_token}",
            "Content-Type": "application/json",
            "X-GitHub-Api-Version": GITHUB_API_VERSION,
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            response_body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        error_body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"GitHub API request failed with {exc.code}: {error_body}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"GitHub API request failed: {exc}") from exc

    if not response_body:
        return None
    return json.loads(response_body)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001
        print(str(exc), file=sys.stderr)
        raise
