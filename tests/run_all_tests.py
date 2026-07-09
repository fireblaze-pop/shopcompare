#!/usr/bin/env python
"""
ShopCompare v0.3 — Full Test Suite Runner
Runs all available Python tests in order, prints final report.
"""
import subprocess
import sys
import os
import time

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND_DIR = os.path.join(os.path.dirname(TESTS_DIR), "backend")

TESTS = [
    ("Layer 1: API Full Coverage", "test_api_full.py"),
    ("Layer 2: Data Integrity", "test_data_integrity.py"),
    ("Layer 4: E2E User Journeys", "test_e2e_journeys.py"),
    ("Layer 5: Edge Cases", "test_edge_cases.py"),
    ("      Filters (extra)", "test_filters.py"),
]

def check_backend():
    import httpx
    import asyncio
    async def _check():
        try:
            async with httpx.AsyncClient(timeout=3) as c:
                r = await c.get("http://localhost:8000/health")
                return r.status_code == 200
        except Exception:
            return False
    return asyncio.run(_check())

def main():
    print("=" * 60)
    print("  SHOPCOMPARE FULL TEST SUITE v0.3")
    print("=" * 60)

    if not check_backend():
        print("\n[ERROR] Backend not running on http://localhost:8000")
        print("Please start the backend first:")
        print("  cd backend && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000")
        sys.exit(1)

    total_pass = 0
    total_fail = 0
    results = []
    t0 = time.time()

    for name, filename in TESTS:
        filepath = os.path.join(TESTS_DIR, filename)
        if not os.path.exists(filepath):
            print(f"\n[SKIP] {name}: file not found ({filename})")
            results.append((name, "SKIP"))
            continue

        print(f"\n{'=' * 60}")
        print(f"  {name} ({filename})")
        print(f"{'=' * 60}")

        t1 = time.time()
        result = subprocess.run([sys.executable, filepath], capture_output=False, timeout=120)
        elapsed = time.time() - t1

        if result.returncode == 0:
            print(f"\n  [{name}] PASS  ({elapsed:.1f}s)")
            results.append((name, "PASS"))
        else:
            print(f"\n  [{name}] FAIL  ({elapsed:.1f}s)")
            results.append((name, "FAIL"))

    # Final report
    print("\n" + "=" * 60)
    print("  FINAL REPORT")
    print("=" * 60)
    for name, status in results:
        icon = "[PASS]" if status == "PASS" else "[FAIL]" if status == "FAIL" else "[SKIP]"
        print(f"  {icon} {name}")
    total_elapsed = time.time() - t0
    print(f"\n  Total time: {total_elapsed:.1f}s")
    print(f"  Backend tests only.")
    print(f"  ArkTS (Layer 3): Run DevEco Studio ohosTest target")
    print("=" * 60)

    all_pass = all(s != "FAIL" for _, s in results)
    sys.exit(0 if all_pass else 1)


if __name__ == "__main__":
    main()
