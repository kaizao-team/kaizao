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


SUMMARY_COMMENT_MARKER = "<!-- openai-gpt54-xhigh-pr-review-summary -->"
REVIEW_MARKER = "<!-- openai-gpt54-xhigh-pr-review -->"
COMMENT_TITLE = "OpenAI GPT-5.4 xhigh PR Review"
GITHUB_API_VERSION = "2022-11-28"
GITHUB_ACTIONS_BOT_LOGIN = "github-actions[bot]"
OPENAI_REVIEW_USER_AGENT = os.getenv("OPENAI_REVIEW_USER_AGENT", "kaizao-ai-review/1.0")

TEXT_FILE_EXTENSIONS = {
    ".c",
    ".cc",
    ".conf",
    ".cpp",
    ".css",
    ".csv",
    ".dart",
    ".env",
    ".go",
    ".graphql",
    ".h",
    ".hpp",
    ".html",
    ".ini",
    ".java",
    ".js",
    ".json",
    ".kt",
    ".kts",
    ".md",
    ".mjs",
    ".proto",
    ".py",
    ".rb",
    ".rs",
    ".sh",
    ".sql",
    ".swift",
    ".toml",
    ".ts",
    ".tsx",
    ".txt",
    ".xml",
    ".yaml",
    ".yml",
}

TEXT_FILE_BASENAMES = {
    ".dockerignore",
    ".gitignore",
    "Dockerfile",
    "Makefile",
}

SKIPPED_FILE_SUFFIXES = {
    ".bmp",
    ".class",
    ".dll",
    ".exe",
    ".gif",
    ".ico",
    ".jar",
    ".jpeg",
    ".jpg",
    ".lock",
    ".min.js",
    ".mov",
    ".mp3",
    ".mp4",
    ".otf",
    ".pdf",
    ".png",
    ".pub-cache",
    ".so",
    ".sum",
    ".svg",
    ".ttf",
    ".wav",
    ".webm",
    ".webp",
    ".woff",
    ".woff2",
    ".zip",
}

SKIPPED_FILE_NAMES = {
    "go.sum",
    "package-lock.json",
    "pnpm-lock.yaml",
    "pubspec.lock",
    "yarn.lock",
}

SKIPPED_PATH_PARTS = {
    ".dart_tool",
    ".next",
    ".turbo",
    "build",
    "coverage",
    "dist",
    "node_modules",
}


def main() -> int:
    event = load_json(Path(required_env("GITHUB_EVENT_PATH")))
    repo = required_env("GITHUB_REPOSITORY")
    github_token = required_env("GITHUB_TOKEN")
    api_key = required_env("OPENAI_API_KEY")
    base_url = required_env("OPENAI_BASE_URL").rstrip("/")
    model = required_env("OPENAI_MODEL")
    reasoning_effort = required_env("OPENAI_REASONING_EFFORT")

    pr = event.get("pull_request") or {}
    pr_number = pr.get("number") or event.get("number") or os.getenv("PR_NUMBER")
    if not pr_number:
        raise RuntimeError("pull_request.number is missing from the workflow event payload.")
    pr_number = int(pr_number)
    if not pr:
        pr = github_api_request(
            github_token=github_token,
            method="GET",
            path=f"/repos/{repo}/pulls/{pr_number}",
        )

    prompt = Path(required_env("AI_REVIEW_PROMPT_FILE")).read_text(encoding="utf-8")
    result_path = Path(required_env("AI_REVIEW_RESULT_FILE"))
    scope = build_review_scope(repo=repo, pr=pr, github_token=github_token)
    max_comments = env_int("AI_REVIEW_MAX_COMMENTS", 4)

    chunk_reviews = []
    for chunk_index, chunk in enumerate(scope["chunks"], start=1):
        user_input = build_user_input(pr=pr, scope=scope, chunk=chunk, chunk_index=chunk_index)
        chunk_review = run_openai_review(
            base_url=base_url,
            api_key=api_key,
            model=model,
            reasoning_effort=reasoning_effort,
            developer_prompt=prompt,
            user_input=user_input,
        )
        chunk_reviews.append(normalize_review(chunk_review))

    merged_review = merge_reviews(scope=scope, chunk_reviews=chunk_reviews)
    result_path.parent.mkdir(parents=True, exist_ok=True)
    result_path.write_text(
        json.dumps(merged_review, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    review_publication = publish_pull_request_review(
        repo=repo,
        pr_number=pr_number,
        head_sha=scope["head_sha"],
        file_index=scope["file_index"],
        review=merged_review,
        max_comments=max_comments,
        github_token=github_token,
        model=model,
        reasoning_effort=reasoning_effort,
    )
    comment_body = render_summary_comment(
        merged_review,
        model=model,
        reasoning_effort=reasoning_effort,
        review_publication=review_publication,
    )
    upsert_issue_comment(
        repo=repo,
        issue_number=pr_number,
        github_token=github_token,
        body=comment_body,
    )
    write_step_summary(merged_review)

    if merged_review["verdict"] == "fail":
        return 1
    return 0


def required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def env_int(name: str, default: int) -> int:
    value = os.getenv(name)
    if not value:
        return default
    try:
        parsed = int(value)
    except ValueError as exc:
        raise RuntimeError(f"Environment variable {name} must be an integer.") from exc
    return max(parsed, 1)


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def clip_text(value: str, limit: int) -> str:
    if len(value) <= limit:
        return value
    omitted = len(value) - limit
    suffix = f"\n\n[truncated: omitted {omitted} trailing characters]"
    if limit <= len(suffix):
        return suffix[:limit]
    return value[: limit - len(suffix)] + suffix


def build_review_scope(*, repo: str, pr: dict[str, Any], github_token: str) -> dict[str, Any]:
    files = list_pull_request_files(
        repo=repo,
        pr_number=int(pr["number"]),
        github_token=github_token,
    )
    files.sort(key=lambda item: (-coerce_int(item.get("changes")), item.get("filename", "")))

    max_files = env_int("AI_REVIEW_MAX_FILES", 60)
    max_patch_chars = env_int("AI_REVIEW_MAX_PATCH_CHARS", 12000)
    max_file_context_chars = env_int("AI_REVIEW_MAX_FILE_CONTEXT_CHARS", 6000)
    max_chunk_chars = env_int("AI_REVIEW_MAX_CHUNK_CHARS", 90000)
    max_chunks = env_int("AI_REVIEW_MAX_CHUNKS", 4)
    head_sha = pr.get("head", {}).get("sha", "")

    change_summaries = []
    review_sections = []
    omitted_files = []

    for file_info in files:
        filename = str(file_info.get("filename", "")).strip()
        if not filename:
            continue

        change_summaries.append(summarize_file_change(file_info))
        if len(review_sections) >= max_files:
            omitted_files.append(f"{filename} (review file cap reached)")
            continue

        included, payload = build_file_review_section(
            file_info=file_info,
            repo=repo,
            head_sha=head_sha,
            github_token=github_token,
            max_patch_chars=max_patch_chars,
            max_file_context_chars=max_file_context_chars,
        )
        if included:
            review_sections.append(
                {
                    "filename": filename,
                    "text": payload,
                    "file_info": file_info,
                }
            )
        else:
            omitted_files.append(f"{filename} ({payload})")

    pack_result = pack_review_sections(
        review_sections=review_sections,
        max_chunk_chars=max_chunk_chars,
        max_chunks=max_chunks,
    )
    omitted_files.extend(f"{filename} (review chunk cap reached)" for filename in pack_result["omitted_files"])
    included_sections = pack_result["included_sections"]
    return {
        "changed_files_count": len(change_summaries),
        "change_summaries": change_summaries,
        "head_sha": head_sha,
        "included_files": [item["filename"] for item in included_sections],
        "included_files_count": len(included_sections),
        "omitted_files": omitted_files,
        "chunk_count": len(pack_result["chunks"]),
        "chunks": pack_result["chunks"],
        "max_chunks": max_chunks,
        "file_index": {
            item["filename"]: {
                "filename": item["filename"],
                "status": str(item["file_info"].get("status", "modified")).strip(),
                "patch": str(item["file_info"].get("patch", "") or ""),
            }
            for item in included_sections
        },
    }


def summarize_file_change(file_info: dict[str, Any]) -> str:
    filename = str(file_info.get("filename", "")).strip()
    status = str(file_info.get("status", "modified")).strip()
    additions = coerce_int(file_info.get("additions"))
    deletions = coerce_int(file_info.get("deletions"))
    changes = coerce_int(file_info.get("changes"))
    return f"- {status} `{filename}` (+{additions} -{deletions}, changes {changes})"


def build_file_review_section(
    *,
    file_info: dict[str, Any],
    repo: str,
    head_sha: str,
    github_token: str,
    max_patch_chars: int,
    max_file_context_chars: int,
) -> tuple[bool, str]:
    filename = str(file_info.get("filename", "")).strip()
    status = str(file_info.get("status", "modified")).strip()
    reviewable, reason = classify_file_for_review(filename)
    if not reviewable:
        return False, reason

    additions = coerce_int(file_info.get("additions"))
    deletions = coerce_int(file_info.get("deletions"))
    changes = coerce_int(file_info.get("changes"))
    patch = str(file_info.get("patch", "") or "")

    lines = [
        f"### File: {filename}",
        f"- Status: {status}",
        f"- Additions: {additions}",
        f"- Deletions: {deletions}",
        f"- Changes: {changes}",
    ]

    if patch:
        lines.extend(
            [
                "Patch:",
                "```diff",
                clip_text(patch, max_patch_chars),
                "```",
            ]
        )
    else:
        lines.append("Patch: (GitHub API did not provide a textual patch for this file)")

    if should_include_file_context(file_info=file_info, patch=patch):
        file_content = fetch_file_content(
            repo=repo,
            ref=head_sha,
            filename=filename,
            github_token=github_token,
        )
        if file_content:
            lines.extend(
                [
                    "Current file content from PR head (truncated):",
                    f"```{guess_code_fence(filename)}",
                    clip_text(file_content, max_file_context_chars),
                    "```",
                ]
            )
        elif status != "removed":
            lines.append("Current file content from PR head: (unavailable)")

    return True, "\n".join(lines)


def classify_file_for_review(filename: str) -> tuple[bool, str]:
    parts = [part for part in filename.split("/") if part]
    lowered = filename.lower()
    basename = Path(filename).name

    if basename in SKIPPED_FILE_NAMES or lowered in SKIPPED_FILE_NAMES:
        return False, "lockfile or dependency digest"
    if any(part in SKIPPED_PATH_PARTS for part in parts):
        return False, "generated or build artifact path"
    if "generatedpluginregistrant" in lowered:
        return False, "generated platform registrant"
    if basename.startswith("generated_") or lowered.endswith(".g.dart"):
        return False, "generated source file"
    if any(lowered.endswith(suffix) for suffix in SKIPPED_FILE_SUFFIXES):
        return False, "binary or low-signal artifact"
    if basename in TEXT_FILE_BASENAMES:
        return True, ""

    suffix = Path(filename).suffix.lower()
    if suffix in TEXT_FILE_EXTENSIONS:
        return True, ""
    return False, "non-text or unsupported file type"


def should_include_file_context(*, file_info: dict[str, Any], patch: str) -> bool:
    status = str(file_info.get("status", "modified")).strip()
    changes = coerce_int(file_info.get("changes"))
    if status == "removed":
        return False
    if status in {"added", "renamed"}:
        return True
    if not patch:
        return True
    if len(patch) < 1800:
        return True
    if changes <= 40:
        return True
    return False


def fetch_file_content(*, repo: str, ref: str, filename: str, github_token: str) -> str:
    if not ref:
        return ""

    encoded_path = urllib.parse.quote(filename, safe="/._-")
    encoded_ref = urllib.parse.quote(ref, safe="")
    return github_api_text_request(
        github_token=github_token,
        path=f"/repos/{repo}/contents/{encoded_path}?ref={encoded_ref}",
        accept="application/vnd.github.raw",
    )


def guess_code_fence(filename: str) -> str:
    suffix = Path(filename).suffix.lower()
    return {
        ".dart": "dart",
        ".go": "go",
        ".json": "json",
        ".md": "md",
        ".py": "python",
        ".sh": "bash",
        ".sql": "sql",
        ".toml": "toml",
        ".ts": "ts",
        ".tsx": "tsx",
        ".yaml": "yaml",
        ".yml": "yaml",
    }.get(suffix, "")


def pack_review_sections(
    *,
    review_sections: list[dict[str, Any]],
    max_chunk_chars: int,
    max_chunks: int,
) -> dict[str, Any]:
    if not review_sections:
        return {
            "chunks": [{"files": [], "text": "No reviewable changed files were included in scope."}],
            "included_sections": [],
            "omitted_files": [],
        }

    chunks = []
    current_sections: list[dict[str, Any]] = []
    current_length = 0

    for index, section in enumerate(review_sections):
        section_text = section["text"]
        section_length = len(section_text) + 2
        if current_sections and current_length + section_length > max_chunk_chars:
            if len(chunks) + 1 >= max_chunks:
                chunks.append(
                    {
                        "files": [item["filename"] for item in current_sections],
                        "text": "\n\n".join(item["text"] for item in current_sections),
                    }
                )
                included_filenames = {
                    filename
                    for chunk in chunks
                    for filename in chunk["files"]
                }
                included_sections = [
                    item for item in review_sections if item["filename"] in included_filenames
                ]
                return {
                    "chunks": chunks,
                    "included_sections": included_sections,
                    "omitted_files": [
                        item["filename"] for item in review_sections[index:]
                    ],
                }
            chunks.append(
                {
                    "files": [item["filename"] for item in current_sections],
                    "text": "\n\n".join(item["text"] for item in current_sections),
                }
            )
            current_sections = [section]
            current_length = len(section_text)
            continue

        current_sections.append(section)
        current_length += section_length

    if current_sections:
        if len(chunks) >= max_chunks:
            included_filenames = {
                filename
                for chunk in chunks
                for filename in chunk["files"]
            }
            included_sections = [
                item for item in review_sections if item["filename"] in included_filenames
            ]
            return {
                "chunks": chunks,
                "included_sections": included_sections,
                "omitted_files": [item["filename"] for item in current_sections],
            }
        chunks.append(
            {
                "files": [item["filename"] for item in current_sections],
                "text": "\n\n".join(item["text"] for item in current_sections),
            }
        )

    included_filenames = {
        filename
        for chunk in chunks
        for filename in chunk["files"]
    }
    included_sections = [
        item for item in review_sections if item["filename"] in included_filenames
    ]
    return {
        "chunks": chunks,
        "included_sections": included_sections,
        "omitted_files": [],
    }


def build_user_input(
    *,
    pr: dict[str, Any],
    scope: dict[str, Any],
    chunk: dict[str, Any],
    chunk_index: int,
) -> str:
    title = pr.get("title") or ""
    body = pr.get("body") or ""
    base_ref = pr.get("base", {}).get("ref") or ""
    head_ref = pr.get("head", {}).get("ref") or ""
    author = pr.get("user", {}).get("login") or ""
    chunk_count = scope["chunk_count"]
    change_summaries = clip_text("\n".join(scope["change_summaries"]), 6000)
    omitted_summary = (
        clip_text("\n".join(f"- {item}" for item in scope["omitted_files"]), 2500)
        if scope["omitted_files"]
        else "(none)"
    )
    chunk_files = "\n".join(f"- {name}" for name in chunk["files"]) or "(none)"

    return textwrap.dedent(
        f"""\
        Repository pull request metadata:
        - Title: {title}
        - Author: {author}
        - Base ref: {base_ref}
        - Head ref: {head_ref}
        - Changed files count: {scope["changed_files_count"]}
        - Deep-reviewed files count: {scope["included_files_count"]}
        - Omitted files count: {len(scope["omitted_files"])}

        Review boundary for this model call:
        - This is chunk {chunk_index} of {chunk_count}.
        - Review only the files listed under "Files included in this chunk".
        - Use only the provided patch and same-file context.
        - Do not audit the rest of the repository.

        PR description:
        {body or "(empty)"}

        All changed files:
        {change_summaries}

        Files omitted from deep review:
        {omitted_summary}

        Files included in this chunk:
        {chunk_files}

        File sections:
        {chunk["text"]}
        """
    )


def list_pull_request_files(*, repo: str, pr_number: int, github_token: str) -> list[dict[str, Any]]:
    files: list[dict[str, Any]] = []
    page = 1
    while True:
        batch = github_api_request(
            github_token=github_token,
            method="GET",
            path=f"/repos/{repo}/pulls/{pr_number}/files?per_page=100&page={page}",
        )
        if not batch:
            break
        files.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    return files


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
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": OPENAI_REVIEW_USER_AGENT,
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


def merge_reviews(*, scope: dict[str, Any], chunk_reviews: list[dict[str, Any]]) -> dict[str, Any]:
    allowed_files = set(scope.get("included_files", []))
    deduped_findings = []
    seen = set()
    for review in chunk_reviews:
        for item in review["findings"]:
            if item["file"] not in allowed_files:
                continue
            key = (item["file"], item["line"], item["title"], item["body"])
            if key in seen:
                continue
            seen.add(key)
            deduped_findings.append(item)

    deduped_findings.sort(key=lambda item: (-severity_rank(item["severity"]), item["file"], item["line"]))
    verdict = "pass"
    if any(item["severity"] == "high" for item in deduped_findings):
        verdict = "fail"
    elif deduped_findings:
        verdict = "warn"

    summary = build_scope_summary(scope=scope, findings=deduped_findings)
    return {
        "verdict": verdict,
        "summary": summary,
        "findings": deduped_findings,
        "scope": {
            "head_sha": scope["head_sha"],
            "changed_files_count": scope["changed_files_count"],
            "included_files_count": scope["included_files_count"],
            "omitted_files": scope["omitted_files"],
            "chunk_count": scope["chunk_count"],
            "max_chunks": scope["max_chunks"],
        },
    }


def build_scope_summary(*, scope: dict[str, Any], findings: list[dict[str, Any]]) -> str:
    changed = scope["changed_files_count"]
    included = scope["included_files_count"]
    chunks = scope["chunk_count"]
    omitted = len(scope["omitted_files"])
    findings_count = len(findings)

    if findings_count == 0:
        summary = (
            f"Reviewed {included}/{changed} changed files with file-scoped context "
            f"across {chunks} chunk(s). No actionable findings."
        )
    else:
        summary = (
            f"Reviewed {included}/{changed} changed files with file-scoped context "
            f"across {chunks} chunk(s). Found {findings_count} actionable issue(s)."
        )

    if omitted > 0:
        summary += f" Skipped {omitted} non-text, generated, or over-cap file(s)."
    return summary


def severity_rank(value: str) -> int:
    return {"low": 1, "medium": 2, "high": 3}.get(value, 0)


def render_summary_comment(
    review: dict[str, Any],
    *,
    model: str,
    reasoning_effort: str,
    review_publication: dict[str, Any],
) -> str:
    verdict = review["verdict"].upper()
    scope = review.get("scope", {})
    omitted_files = scope.get("omitted_files", [])

    lines = [
        SUMMARY_COMMENT_MARKER,
        f"## {COMMENT_TITLE}",
        "",
        f"- Verdict: `{verdict}`",
        f"- Model label: `{model}` / `{reasoning_effort}`",
        "- Review scope: `changed files only`",
        "- Context strategy: `patch-first`, with same-file content added only when patch context was thin",
        "- Comment identity: `github-actions[bot]` via workflow `GITHUB_TOKEN`",
    ]

    if scope:
        head_sha = str(scope.get("head_sha", ""))
        if head_sha:
            lines.append(f"- Reviewed head SHA: `{head_sha[:12]}`")
        lines.append(
            f"- Files deeply reviewed: `{scope.get('included_files_count', 0)}/{scope.get('changed_files_count', 0)}`"
        )
        lines.append(
            f"- Model review chunks: `{scope.get('chunk_count', 0)}/{scope.get('max_chunks', scope.get('chunk_count', 0))}`"
        )
        if omitted_files:
            lines.append(f"- Files skipped from deep review: `{len(omitted_files)}`")
    lines.append(f"- Inline review comments posted: `{review_publication['published_count']}/{review_publication['total_findings']}`")
    if review_publication["omitted_count"] > 0:
        lines.append(f"- Findings not posted inline: `{review_publication['omitted_count']}`")
    if review_publication["status"] == "skipped_duplicate":
        lines.append("- Inline review submission: `skipped for same head SHA`")

    lines.extend(["", review["summary"]])

    if omitted_files:
        lines.extend(["", "### Skipped Files"])
        for item in omitted_files[:8]:
            lines.append(f"- {item}")
        if len(omitted_files) > 8:
            lines.append(f"- ... and {len(omitted_files) - 8} more")

    findings = review["findings"]
    if findings:
        display_findings = review_publication["published_findings"] or findings[: min(len(findings), 4)]
        lines.extend(["", "### Findings"])
        for item in display_findings:
            location = item["file"] or "(file not provided)"
            if item["line"] > 0:
                location = f"{location}:{item['line']}"
            lines.append(f"- [{item['severity']}] `{location}` {item['title']}")
        if review_publication["omitted_count"] > 0 or len(display_findings) < len(findings):
            remaining = max(len(findings) - len(display_findings), 0)
            if remaining > 0:
                lines.append(f"- ... and {remaining} more finding(s) not posted inline")
    else:
        lines.extend(["", "No actionable findings in the reviewed file scope."])

    return "\n".join(lines).strip() + "\n"


def write_step_summary(review: dict[str, Any]) -> None:
    summary_path = os.getenv("GITHUB_STEP_SUMMARY")
    if not summary_path:
        return

    body = render_summary_comment(
        review,
        model=os.getenv("OPENAI_MODEL", "unknown"),
        reasoning_effort=os.getenv("OPENAI_REASONING_EFFORT", "unknown"),
        review_publication={
            "status": "step_summary",
            "published_count": min(
                len(review.get("findings", [])),
                env_int("AI_REVIEW_MAX_COMMENTS", 4),
            ),
            "total_findings": len(review.get("findings", [])),
            "omitted_count": max(
                len(review.get("findings", [])) - env_int("AI_REVIEW_MAX_COMMENTS", 4),
                0,
            ),
            "published_findings": review.get("findings", [])[: env_int("AI_REVIEW_MAX_COMMENTS", 4)],
        },
    )
    Path(summary_path).write_text(body, encoding="utf-8")


def upsert_issue_comment(*, repo: str, issue_number: int, github_token: str, body: str) -> None:
    comments = github_api_request(
        github_token=github_token,
        method="GET",
        path=f"/repos/{repo}/issues/{issue_number}/comments?per_page=100",
    )

    existing_comment = next(
        (item for item in comments if SUMMARY_COMMENT_MARKER in (item.get("body") or "")),
        None,
    )

    if existing_comment:
        github_api_request(
            github_token=github_token,
            method="PATCH",
            path=f"/repos/{repo}/issues/comments/{existing_comment['id']}",
            payload={"body": body},
        )
        return

    github_api_request(
        github_token=github_token,
        method="POST",
        path=f"/repos/{repo}/issues/{issue_number}/comments",
        payload={"body": body},
    )


def publish_pull_request_review(
    *,
    repo: str,
    pr_number: int,
    head_sha: str,
    file_index: dict[str, dict[str, str]],
    review: dict[str, Any],
    max_comments: int,
    github_token: str,
    model: str,
    reasoning_effort: str,
) -> dict[str, Any]:
    findings = review.get("findings", [])
    publication = {
        "status": "skipped_no_findings",
        "published_count": 0,
        "total_findings": len(findings),
        "omitted_count": len(findings),
        "published_findings": [],
    }
    if not findings or not head_sha:
        return publication

    existing_review = find_existing_review_for_head(
        repo=repo,
        pr_number=pr_number,
        head_sha=head_sha,
        github_token=github_token,
    )
    if existing_review:
        publication["status"] = "skipped_duplicate"
        return publication

    comments = []
    published_findings = []
    for finding in findings:
        if len(comments) >= max_comments:
            break
        location = build_review_comment_location(
            file_info=file_index.get(finding["file"]),
            preferred_line=finding["line"],
        )
        if not location:
            continue
        comments.append(
            {
                "path": finding["file"],
                "line": location["line"],
                "side": "RIGHT",
                "body": render_inline_comment(finding),
            }
        )
        published_findings.append(finding)

    if not comments:
        publication["status"] = "skipped_unanchorable"
        return publication

    create_pull_request_review(
        repo=repo,
        pr_number=pr_number,
        github_token=github_token,
        payload={
            "commit_id": head_sha,
            "event": "COMMENT",
            "body": render_pull_request_review_body(
                review=review,
                model=model,
                reasoning_effort=reasoning_effort,
                published_count=len(comments),
                total_findings=len(findings),
            ),
            "comments": comments,
        },
    )
    publication["status"] = "created"
    publication["published_count"] = len(comments)
    publication["published_findings"] = published_findings
    publication["omitted_count"] = max(len(findings) - len(published_findings), 0)
    return publication


def render_pull_request_review_body(
    *,
    review: dict[str, Any],
    model: str,
    reasoning_effort: str,
    published_count: int,
    total_findings: int,
) -> str:
    scope = review.get("scope", {})
    lines = [
        REVIEW_MARKER,
        f"## {COMMENT_TITLE}",
        "",
        f"- Verdict: `{review['verdict'].upper()}`",
        f"- Model label: `{model}` / `{reasoning_effort}`",
        "- Review mode: `inline PR review comments`",
        f"- Reviewed head SHA: `{str(scope.get('head_sha', ''))[:12]}`",
        f"- Inline comments in this review: `{published_count}/{total_findings}`",
        "",
        review["summary"],
    ]
    if total_findings > published_count:
        lines.append("")
        lines.append(f"Additional findings omitted by cap or anchoring limits: `{total_findings - published_count}`")
    return "\n".join(lines).strip() + "\n"


def render_inline_comment(finding: dict[str, Any]) -> str:
    return f"[{finding['severity']}] {finding['title']}\n\n{finding['body']}"


def find_existing_review_for_head(
    *,
    repo: str,
    pr_number: int,
    head_sha: str,
    github_token: str,
) -> dict[str, Any] | None:
    reviews = github_api_request(
        github_token=github_token,
        method="GET",
        path=f"/repos/{repo}/pulls/{pr_number}/reviews?per_page=100",
    )
    return next(
        (
            item
            for item in reviews
            if item.get("commit_id") == head_sha
            and REVIEW_MARKER in (item.get("body") or "")
            and (item.get("user", {}) or {}).get("login") == GITHUB_ACTIONS_BOT_LOGIN
        ),
        None,
    )


def create_pull_request_review(
    *,
    repo: str,
    pr_number: int,
    github_token: str,
    payload: dict[str, Any],
) -> Any:
    return github_api_request(
        github_token=github_token,
        method="POST",
        path=f"/repos/{repo}/pulls/{pr_number}/reviews",
        payload=payload,
    )


def build_review_comment_location(
    *,
    file_info: dict[str, str] | None,
    preferred_line: int,
) -> dict[str, int] | None:
    if not file_info:
        return None

    reviewable_lines = extract_reviewable_right_side_lines(file_info.get("patch", ""))
    if not reviewable_lines:
        return None
    if preferred_line in reviewable_lines:
        return {"line": preferred_line}

    nearest_line = min(reviewable_lines, key=lambda value: abs(value - preferred_line))
    if preferred_line > 0 and abs(nearest_line - preferred_line) <= 10:
        return {"line": nearest_line}
    if preferred_line <= 0:
        return {"line": min(reviewable_lines)}
    return None


def extract_reviewable_right_side_lines(patch: str) -> set[int]:
    reviewable_lines: set[int] = set()
    old_line = 0
    new_line = 0

    for raw_line in patch.splitlines():
        if raw_line.startswith("@@"):
            old_line, new_line = parse_hunk_header(raw_line)
            continue
        if raw_line.startswith("+") and not raw_line.startswith("+++"):
            reviewable_lines.add(new_line)
            new_line += 1
            continue
        if raw_line.startswith("-") and not raw_line.startswith("---"):
            old_line += 1
            continue
        if raw_line.startswith(" "):
            reviewable_lines.add(new_line)
            old_line += 1
            new_line += 1

    return reviewable_lines


def parse_hunk_header(line: str) -> tuple[int, int]:
    header = line.split("@@", maxsplit=2)[1].strip()
    old_part, new_part = header.split(" ")
    return parse_hunk_start(old_part), parse_hunk_start(new_part)


def parse_hunk_start(part: str) -> int:
    raw_value = part[1:].split(",", maxsplit=1)[0]
    return coerce_int(raw_value)


def github_api_request(
    *,
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


def github_api_text_request(*, github_token: str, path: str, accept: str) -> str:
    request = urllib.request.Request(
        url=f"https://api.github.com{path}",
        method="GET",
        headers={
            "Accept": accept,
            "Authorization": f"Bearer {github_token}",
            "X-GitHub-Api-Version": GITHUB_API_VERSION,
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return ""
        error_body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"GitHub text API request failed with {exc.code}: {error_body}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"GitHub text API request failed: {exc}") from exc


def coerce_int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001
        print(str(exc), file=sys.stderr)
        raise
