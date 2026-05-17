"""本地 LLM 调用测试 — 分别测 GPT-5.4 和 智谱 GLM"""
import asyncio
import os
import sys
import time

from dotenv import load_dotenv

load_dotenv()

# ── 1. 测试 GPT-5.4 (codex-for.me 代理) ──────────────────────
async def test_gpt():
    from openai import AsyncOpenAI

    api_key = os.getenv("OPENAI_API_KEY", "")
    base_url = os.getenv("OPENAI_BASE_URL", "https://api-hk.codex-for.me/v1")
    model = os.getenv("OPENAI_MODEL", "gpt-5.4")

    if not api_key:
        print("[GPT] SKIP — OPENAI_API_KEY 未配置")
        return False

    print(f"[GPT] base_url={base_url}  model={model}  key={api_key[:12]}...")
    client = AsyncOpenAI(api_key=api_key, base_url=base_url, timeout=30)

    t0 = time.time()
    try:
        # 先试非流式
        print("[GPT] 尝试非流式调用...")
        resp = await client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "回复OK两个字"}],
            max_tokens=32,
            temperature=0,
            stream=False,
        )
        text = resp.choices[0].message.content
        print(f"[GPT] 非流式成功 ({time.time()-t0:.1f}s): {text!r}")
        return True
    except Exception as e:
        print(f"[GPT] 非流式失败: {e}")

    t0 = time.time()
    try:
        # 再试流式
        print("[GPT] 尝试流式调用...")
        stream = await client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "回复OK两个字"}],
            max_tokens=32,
            temperature=0,
            stream=True,
        )
        content = ""
        async for chunk in stream:
            if chunk.choices and chunk.choices[0].delta.content:
                content += chunk.choices[0].delta.content
        print(f"[GPT] 流式成功 ({time.time()-t0:.1f}s): {content!r}")
        return True
    except Exception as e:
        print(f"[GPT] 流式失败: {e}")
        return False


# ── 2. 测试智谱 GLM ──────────────────────────────────────────
async def test_zhipu():
    from openai import AsyncOpenAI

    api_key = os.getenv("ZHIPU_API_KEY", "")
    model = os.getenv("ZHIPU_MODEL", "GLM-4-FlashX")

    if not api_key:
        print("[智谱] SKIP — ZHIPU_API_KEY 未配置")
        return False

    print(f"[智谱] model={model}  key={api_key[:12]}...")
    client = AsyncOpenAI(
        api_key=api_key,
        base_url="https://open.bigmodel.cn/api/paas/v4/",
        timeout=30,
    )

    t0 = time.time()
    try:
        resp = await client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "回复OK两个字"}],
            max_tokens=32,
            temperature=0,
        )
        text = resp.choices[0].message.content
        print(f"[智谱] 成功 ({time.time()-t0:.1f}s): {text!r}")
        return True
    except Exception as e:
        print(f"[智谱] 失败: {e}")
        return False


async def main():
    print("=" * 50)
    print("LLM 调用测试")
    print("=" * 50)

    gpt_ok = await test_gpt()
    print()
    zhipu_ok = await test_zhipu()

    print()
    print("=" * 50)
    print(f"结果: GPT-5.4={'OK' if gpt_ok else 'FAIL'}  智谱={'OK' if zhipu_ok else 'FAIL'}")
    if not gpt_ok and not zhipu_ok:
        print("所有模型都不可用！")
        sys.exit(1)
    elif not gpt_ok:
        print("GPT-5.4 不可用，智谱可兜底")
    print("=" * 50)


if __name__ == "__main__":
    asyncio.run(main())
