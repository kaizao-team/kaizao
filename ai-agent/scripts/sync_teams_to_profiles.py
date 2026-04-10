"""
一次性脚本：从 Go 后端的 teams + users + user_skills 同步到 ai_provider_profiles
运行方式：docker exec vibebuild-ai-agent python -m scripts.sync_teams_to_profiles
"""
import asyncio
import aiomysql
import httpx
import os


MYSQL_URL = os.getenv("MYSQL_URL", "mysql+aiomysql://kaizao:kaizao_prod_2026@kaizao-mysql:3306/kaizao")
SYNC_API = "http://localhost:39528/api/v2/providers/sync"


def parse_mysql_url(url: str):
    """从 SQLAlchemy URL 解析出 aiomysql 参数"""
    # mysql+aiomysql://user:pass@host:port/db
    url = url.replace("mysql+aiomysql://", "")
    auth, rest = url.split("@", 1)
    user, password = auth.split(":", 1)
    hostport, db = rest.split("/", 1)
    db = db.split("?")[0]
    host, port = hostport.split(":", 1)
    return {"host": host, "port": int(port), "user": user, "password": password, "db": db}


async def main():
    params = parse_mysql_url(MYSQL_URL)
    conn = await aiomysql.connect(**params, charset="utf8mb4")
    cursor = await conn.cursor(aiomysql.DictCursor)

    # 查所有团队 + leader 信息 + 技能
    await cursor.execute("""
        SELECT t.uuid as team_uuid, t.name, t.vibe_level, t.vibe_power,
               t.member_count, u.uuid as user_uuid, u.nickname,
               GROUP_CONCAT(s.name SEPARATOR '|') as skill_names
        FROM teams t
        JOIN users u ON t.leader_id = u.id
        LEFT JOIN user_skills us ON us.user_id = u.id
        LEFT JOIN skills s ON us.skill_id = s.id
        WHERE t.status = 1
        GROUP BY t.uuid
    """)
    rows = await cursor.fetchall()
    await cursor.close()
    conn.close()

    print(f"Found {len(rows)} teams to sync")

    async with httpx.AsyncClient(timeout=30) as client:
        success = 0
        failed = 0
        for row in rows:
            skills = []
            if row.get("skill_names"):
                skills = [s.strip() for s in row["skill_names"].split("|") if s.strip()]

            payload = {
                "provider_id": row["team_uuid"],
                "user_id": row["user_uuid"],
                "display_name": row["name"] or row.get("nickname", ""),
                "type": "team",
                "vibe_level": row.get("vibe_level") or "vc-T1",
                "vibe_power": row.get("vibe_power") or 0,
                "skills": skills,
            }

            try:
                resp = await client.post(SYNC_API, json=payload)
                data = resp.json()
                if data.get("code") == 0:
                    success += 1
                    print(f"  ✓ {row['team_uuid'][:12]}  {row['name']}")
                else:
                    failed += 1
                    print(f"  ✗ {row['team_uuid'][:12]}  {data.get('message')}")
            except Exception as e:
                failed += 1
                print(f"  ✗ {row['team_uuid'][:12]}  {e}")

    print(f"\nDone: {success} synced, {failed} failed")


if __name__ == "__main__":
    asyncio.run(main())
