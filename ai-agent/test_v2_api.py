#!/usr/bin/env python3
"""
VibeBuild v2 API 完整测试脚本
测试所有 v2 接口，生成详细报告
"""

import asyncio
import json
import sys
from datetime import datetime
from pathlib import Path

import httpx

BASE_URL = "http://localhost:8000"
TIMEOUT = 600.0  # GLM-5 大型 tool 调用可能需要 5-10 分钟

# 测试结果收集
test_results = []


class TestResult:
    def __init__(self, name: str, endpoint: str, method: str):
        self.name = name
        self.endpoint = endpoint
        self.method = method
        self.request_body = None
        self.response_status = None
        self.response_body = None
        self.error = None
        self.duration_ms = 0
        self.success = False

    def to_dict(self):
        return {
            "name": self.name,
            "endpoint": self.endpoint,
            "method": self.method,
            "request_body": self.request_body,
            "response_status": self.response_status,
            "response_body": self.response_body,
            "error": self.error,
            "duration_ms": self.duration_ms,
            "success": self.success,
        }


async def test_api(client: httpx.AsyncClient, result: TestResult, request_body: dict = None):
    """执行单个 API 测试"""
    result.request_body = request_body
    start = asyncio.get_event_loop().time()

    try:
        if result.method == "POST":
            resp = await client.post(result.endpoint, json=request_body, timeout=TIMEOUT)
        elif result.method == "GET":
            resp = await client.get(result.endpoint, timeout=TIMEOUT)
        else:
            raise ValueError(f"Unsupported method: {result.method}")

        result.duration_ms = round((asyncio.get_event_loop().time() - start) * 1000, 2)
        result.response_status = resp.status_code
        result.response_body = resp.json()
        result.success = resp.status_code == 200 and result.response_body.get("code") == 0

    except Exception as e:
        result.duration_ms = round((asyncio.get_event_loop().time() - start) * 1000, 2)
        result.error = str(e)
        result.success = False

    test_results.append(result)
    return result


async def run_full_pipeline_test():
    """完整流水线测试：requirement → design → task → pm"""
    print("=" * 80)
    print("开始 VibeBuild v2 API 完整测试")
    print("=" * 80)

    async with httpx.AsyncClient(base_url=BASE_URL) as client:
        project_id = None

        # ========== 1. 健康检查 ==========
        print("\n[1/15] 测试：健康检查")
        result = TestResult("健康检查", "/health", "GET")
        await test_api(client, result)
        result.success = result.response_status == 200
        if result.success:
            print(f"✓ 健康检查通过")
        else:
            print(f"✗ 健康检查失败")
            return

        # ========== 2. 创建项目 ==========
        print("\n[2/15] 测试：创建项目（Pipeline）")
        result = TestResult("创建项目", "/api/v2/pipeline/start", "POST")
        await test_api(client, result, {"title": "AI 驱动的任务管理系统"})
        if result.success:
            project_id = result.response_body["data"]["project_id"]
            print(f"✓ 项目创建成功: {project_id}")
        else:
            print(f"✗ 项目创建失败: {result.error or result.response_body}")
            return

        # ========== 3. 获取项目状态 ==========
        print("\n[3/15] 测试：获取项目状态")
        result = TestResult("获取项目状态", f"/api/v2/pipeline/{project_id}/status", "GET")
        await test_api(client, result)
        if result.success:
            print(f"✓ 项目状态: {json.dumps(result.response_body['data'], ensure_ascii=False)[:200]}")
        else:
            print(f"✗ 获取状态失败")

        # ========== 4. 启动需求分析（一句话需求 → 首轮对话） ==========
        print("\n[4/15] 测试：启动需求分析（首轮对话）")
        result = TestResult("需求分析-启动", "/api/v2/requirement/start", "POST")
        await test_api(client, result, {
            "message": (
                "我想做一个类似 Trello 的任务管理工具。核心功能包括：看板视图、任务卡片拖拽、"
                "团队协作（邀请成员、权限管理）、标签分类、截止日期提醒、评论和附件。"
                "目标用户是 5-20 人的小型创业团队。技术栈用 React + Node.js + PostgreSQL。"
                "需要支持移动端响应式。MVP 先做看板和任务管理核心功能。"
            ),
            "title": "TaskFlow - 团队任务管理工具",
            "project_id": project_id,
        })
        if result.success:
            data = result.response_body["data"]
            print(f"✓ 需求分析启动成功")
            print(f"  - 子阶段: {data['sub_stage']}")
            print(f"  - 完整度: {data['completeness_score']}")
            print(f"  - Agent 回复: {data['agent_message'][:150]}...")
        else:
            print(f"✗ 需求分析启动失败: {result.error or result.response_body}")
            return

        # ========== 5. 多轮对话（补充更多细节以提高完整度） ==========
        print("\n[5/15] 测试：需求对话（补充详细信息）")
        result = TestResult("需求分析-补充信息", f"/api/v2/requirement/{project_id}/message", "POST")
        await test_api(client, result, {
            "message": (
                "补充以下信息：\n"
                "1. 商业模式：免费版支持 5 人团队，Pro 版 ¥29/人/月支持更多功能\n"
                "2. 核心场景：产品团队管理开发任务、运营团队管理活动排期\n"
                "3. 非功能需求：页面加载 <2s，支持 1000 并发，数据每日备份\n"
                "4. 优先级：P0-看板+任务CRUD，P1-团队协作+权限，P2-通知+附件\n"
                "5. 部署：阿里云，Docker 容器化\n"
                "请根据这些信息生成完整的 PRD 文档。"
            ),
        })
        if result.success:
            data = result.response_body["data"]
            sub_stage = data["sub_stage"]
            score = data["completeness_score"]
            print(f"✓ 对话成功，子阶段: {sub_stage}，完整度: {score}")
        else:
            err_detail = result.error or (result.response_body.get("message", "") if result.response_body else "Unknown error")
            print(f"✗ 对话失败: {err_detail}")

        # ========== 6. 如果还在 clarifying，再推一把 ==========
        data = result.response_body.get("data", {}) if result.response_body else {}
        if data.get("sub_stage") == "clarifying":
            print("\n[5.5/15] 追加：要求直接生成 PRD")
            result2 = TestResult("需求分析-强制PRD", f"/api/v2/requirement/{project_id}/message", "POST")
            await test_api(client, result2, {
                "message": "信息已经足够完整了，请直接使用 generate_prd 工具生成完整的 PRD 文档。",
            })
            if result2.success:
                data2 = result2.response_body["data"]
                print(f"✓ 追加对话成功，子阶段: {data2['sub_stage']}，完整度: {data2['completeness_score']}")

        # ========== 7. 确认 PRD → 触发 EARS 拆解 ==========
        print("\n[6/15] 测试：确认PRD → EARS 拆解")
        result = TestResult("需求分析-确认PRD", f"/api/v2/requirement/{project_id}/confirm", "POST")
        await test_api(client, result, {})
        if result.success:
            data = result.response_body["data"]
            print(f"✓ PRD 确认成功，子阶段: {data.get('sub_stage', 'N/A')}")
        else:
            msg = result.response_body.get("message", "") if result.response_body else str(result.error)
            print(f"✗ PRD 确认失败: {msg}")

        # ========== 8. 获取需求文档 ==========
        print("\n[7/15] 测试：获取需求文档")
        result = TestResult("需求分析-获取文档", f"/api/v2/requirement/{project_id}/document", "GET")
        await test_api(client, result)
        if result.success:
            d = result.response_body["data"]
            print(f"✓ 需求文档获取成功，文件: {d['path']}，大小: {d['size']} 字符")
        else:
            msg = result.response_body.get("message", "") if result.response_body else ""
            print(f"✗ 需求文档获取失败: {msg}")

        # ========== 9. 启动架构设计 ==========
        print("\n[8/15] 测试：启动架构设计")
        result = TestResult("架构设计-启动", f"/api/v2/design/{project_id}/start", "POST")
        await test_api(client, result, {})
        if result.success:
            data = result.response_body["data"]
            print(f"✓ 架构设计生成成功")
            print(f"  Agent 回复: {data.get('agent_message', '')[:150]}...")
        else:
            msg = result.response_body.get("message", "") if result.response_body else str(result.error)
            print(f"✗ 架构设计失败: {msg}")

        # ========== 10. 获取设计文档 ==========
        print("\n[9/15] 测试：获取设计文档")
        result = TestResult("架构设计-获取文档", f"/api/v2/design/{project_id}/document", "GET")
        await test_api(client, result)
        if result.success:
            d = result.response_body["data"]
            print(f"✓ 设计文档获取成功，文件: {d['path']}，大小: {d['size']} 字符")
        else:
            print(f"✗ 设计文档未生成")

        # ========== 11. 确认架构设计 ==========
        print("\n[10/15] 测试：确认架构设计")
        result = TestResult("架构设计-确认", f"/api/v2/design/{project_id}/confirm", "POST")
        await test_api(client, result)
        if result.success:
            print(f"✓ 架构设计确认成功")
        else:
            msg = result.response_body.get("message", "") if result.response_body else ""
            print(f"✗ 架构设计确认失败: {msg}")

        # ========== 12. 启动任务分解 ==========
        print("\n[11/15] 测试：启动任务分解")
        result = TestResult("任务分解-启动", f"/api/v2/task/{project_id}/start", "POST")
        await test_api(client, result, {})
        if result.success:
            print(f"✓ 任务分解生成成功")
        else:
            msg = result.response_body.get("message", "") if result.response_body else str(result.error)
            print(f"✗ 任务分解失败: {msg}")

        # ========== 13. 确认任务分解 ==========
        print("\n[12/15] 测试：确认任务分解")
        result = TestResult("任务分解-确认", f"/api/v2/task/{project_id}/confirm", "POST")
        await test_api(client, result)
        if result.success:
            print(f"✓ 任务分解确认成功")
        else:
            msg = result.response_body.get("message", "") if result.response_body else ""
            print(f"✗ 任务分解确认失败: {msg}")

        # ========== 14. 启动项目管理方案 ==========
        print("\n[13/15] 测试：启动项目管理方案")
        result = TestResult("项目管理-启动", f"/api/v2/pm/{project_id}/start", "POST")
        await test_api(client, result, {})
        if result.success:
            print(f"✓ 项目管理方案生成成功")
        else:
            msg = result.response_body.get("message", "") if result.response_body else str(result.error)
            print(f"✗ 项目管理方案失败: {msg}")

        # ========== 15. 确认项目管理方案 + 获取所有文档 ==========
        print("\n[14/15] 测试：确认项目管理方案")
        result = TestResult("项目管理-确认", f"/api/v2/pm/{project_id}/confirm", "POST")
        await test_api(client, result)
        if result.success:
            print(f"✓ 项目管理方案确认成功")
        else:
            msg = result.response_body.get("message", "") if result.response_body else ""
            print(f"✗ 项目管理方案确认失败: {msg}")

        print("\n[15/15] 测试：获取所有文档")
        result = TestResult("流水线-获取所有文档", f"/api/v2/pipeline/{project_id}/documents", "GET")
        await test_api(client, result)
        if result.success:
            docs = result.response_body["data"]["documents"]
            print(f"✓ 获取所有文档成功，共 {len(docs)} 个文档")
            for doc in docs:
                print(f"  - {doc['stage']}: {doc['filename']} ({doc.get('size', 0)} 字符)")
        else:
            print(f"✗ 获取文档失败")

        # 最终项目状态
        print("\n--- 最终项目状态 ---")
        result = TestResult("最终状态检查", f"/api/v2/pipeline/{project_id}/status", "GET")
        await test_api(client, result)
        if result.success:
            print(json.dumps(result.response_body["data"], ensure_ascii=False, indent=2))


def generate_report():
    """生成测试报告"""
    report_path = Path("test_report_v2.md")

    total = len(test_results)
    success = sum(1 for r in test_results if r.success)
    failed = total - success

    lines = []
    lines.append("# VibeBuild v2 API 测试报告\n")
    lines.append(f"**测试时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    lines.append(f"**LLM 模型**: 智谱 GLM-5\n")
    lines.append(f"**测试结果**: {success}/{total} 通过，{failed} 失败\n")
    lines.append("---\n")

    # 接口汇总表
    lines.append("## 接口汇总\n")
    lines.append("| # | 测试名称 | 方法 | 接口路径 | 状态 | 耗时(ms) |")
    lines.append("|---|---------|------|---------|------|---------|")
    for i, r in enumerate(test_results, 1):
        status = "✅" if r.success else "❌"
        lines.append(f"| {i} | {r.name} | {r.method} | `{r.endpoint}` | {status} | {r.duration_ms} |")
    lines.append("")

    # 详细结果
    lines.append("---\n")
    lines.append("## 详细测试结果\n")

    for i, result in enumerate(test_results, 1):
        status = "✅ 成功" if result.success else "❌ 失败"
        lines.append(f"### {i}. {result.name} {status}\n")
        lines.append(f"- **接口**: `{result.method} {result.endpoint}`")
        lines.append(f"- **耗时**: {result.duration_ms} ms")
        lines.append(f"- **HTTP 状态码**: {result.response_status}\n")

        if result.request_body:
            lines.append("**请求体 (Request Body)**:\n")
            lines.append("```json")
            lines.append(json.dumps(result.request_body, ensure_ascii=False, indent=2))
            lines.append("```\n")

        if result.response_body:
            lines.append("**响应体 (Response Body)**:\n")
            lines.append("```json")
            resp_str = json.dumps(result.response_body, ensure_ascii=False, indent=2)
            if len(resp_str) > 3000:
                resp_str = resp_str[:3000] + "\n... (截断，完整内容过长)"
            lines.append(resp_str)
            lines.append("```\n")

        if result.error:
            lines.append(f"**错误信息**:\n\n```\n{result.error}\n```\n")

        lines.append("---\n")

    # 接口入参出参规格
    lines.append("## 接口规格文档\n")
    lines.append("""
### 1. 流水线管理

#### `POST /api/v2/pipeline/start` — 创建项目

**入参**:
```json
{
  "title": "string (必填，项目标题)",
  "project_id": "string (选填，不传则自动生成)"
}
```

**出参**:
```json
{
  "code": 0,
  "message": "项目已创建",
  "data": {
    "project_id": "string",
    "title": "string",
    "current_stage": "requirement",
    "version": 1,
    "stages": {
      "requirement": {"status": "pending", "sub_stage": null},
      "design": {"status": "pending", "sub_stage": null},
      "task": {"status": "pending", "sub_stage": null},
      "pm": {"status": "pending", "sub_stage": null}
    }
  }
}
```

#### `GET /api/v2/pipeline/{project_id}/status` — 获取项目进度

**入参**: 无（路径参数 project_id）

**出参**: 同创建项目的 data 结构

#### `GET /api/v2/pipeline/{project_id}/documents` — 获取所有文档

**入参**: 无

**出参**:
```json
{
  "code": 0,
  "data": {
    "documents": [
      {
        "stage": "requirement",
        "filename": "requirement.md",
        "path": "outputs/{project_id}/v1/requirement.md",
        "content": "Markdown 内容",
        "status": "confirmed"
      }
    ]
  }
}
```

---

### 2. 需求分析

#### `POST /api/v2/requirement/start` — 创建项目 + 首轮对话

**入参**:
```json
{
  "message": "string (必填，用户需求描述)",
  "title": "string (选填，项目标题)",
  "project_id": "string (选填)"
}
```

**出参**:
```json
{
  "code": 0,
  "data": {
    "project_id": "string",
    "session_id": "string",
    "agent_message": "string (Agent 回复文本)",
    "sub_stage": "clarifying | prd_draft | prd_confirmed | tasks_ready",
    "completeness_score": 0-100,
    "tool_result": {
      "tool_name": "ask_clarification | generate_prd",
      "agent_message": "string",
      "completeness_score": 35,
      "questions": [{"question": "...", "category": "scope|user|tech|business|priority"}]
    }
  }
}
```

#### `POST /api/v2/requirement/{project_id}/message` — 多轮对话

**入参**:
```json
{
  "message": "string (必填，用户回复)"
}
```

**出参**: 同 start 的 data 结构

#### `POST /api/v2/requirement/{project_id}/confirm` — 确认 PRD

**入参**:
```json
{
  "feedback": "string (选填，修改意见)"
}
```

**出参**: 同 start 的 data 结构（sub_stage 变为 tasks_ready）

#### `GET /api/v2/requirement/{project_id}/document` — 获取文档

**出参**:
```json
{
  "code": 0,
  "data": {
    "content": "Markdown 文档内容",
    "filename": "requirement.md"
  }
}
```

---

### 3. 架构设计 / 任务分解 / 项目管理（模式一致）

#### `POST /api/v2/{design|task|pm}/{project_id}/start` — 启动生成

**入参**:
```json
{
  "feedback": "string (选填，修改意见)"
}
```

**出参**:
```json
{
  "code": 0,
  "data": {
    "project_id": "string",
    "agent_message": "string (Agent 回复)",
    "tool_result": { ... }
  }
}
```

#### `POST /api/v2/{design|task|pm}/{project_id}/confirm` — 确认

**入参**: 无

**出参**:
```json
{
  "code": 0,
  "message": "阶段 design 已确认，可以开始 task 阶段",
  "data": { "project_id": "...", "stages": { ... } }
}
```

#### `GET /api/v2/{design|task|pm}/{project_id}/document` — 获取文档

**出参**:
```json
{
  "code": 0,
  "data": {
    "content": "Markdown 文档内容",
    "filename": "design.md | task.md | project-plan.md"
  }
}
```
""")

    report_content = "\n".join(lines)
    report_path.write_text(report_content, encoding="utf-8")
    print(f"\n测试报告已生成: {report_path.absolute()}")


async def main():
    print("正在等待服务启动...")
    await asyncio.sleep(2)

    try:
        await run_full_pipeline_test()
    except Exception as e:
        print(f"\n测试过程中发生异常: {e}")
        import traceback
        traceback.print_exc()
    finally:
        generate_report()

        print("\n" + "=" * 80)
        print("测试完成")
        print("=" * 80)
        total = len(test_results)
        success = sum(1 for r in test_results if r.success)
        print(f"总计: {total} 个测试")
        print(f"成功: {success}")
        print(f"失败: {total - success}")


if __name__ == "__main__":
    asyncio.run(main())
