from robot.libraries.BuiltIn import BuiltIn
from axe_selenium_python import Axe
from pathlib import Path
import json, re

def run_axe_and_save(output_dir: str, page_name: str=None, fail_on: str="serious"):
    """Keyword: Run Axe And Save"""
    sl = BuiltIn().get_library_instance('SeleniumLibrary')
    driver = sl.driver

    axe = Axe(driver)
    axe.inject()
    results = axe.run()

    Path(output_dir).mkdir(parents=True, exist_ok=True)

    if not page_name:
        title = (driver.title or "page").lower()
        page_name = re.sub(r"[^a-z0-9\-]+", "-", title).strip("-") or "page"

    json_path = Path(output_dir) / f"{page_name}.axe.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    counts = {k: 0 for k in ["minor","moderate","serious","critical"]}
    for v in results.get("violations", []):
        imp = (v.get("impact") or "").lower()
        if imp in counts:
            counts[imp] += 1

    order = ["minor","moderate","serious","critical"]
    if fail_on and fail_on.lower() in order:
        idx = order.index(fail_on.lower())
        severities = set(order[idx:])
        to_fail = sum(counts[s] for s in severities)
        if to_fail > 0:
            raise AssertionError(
                f"A11y: {to_fail} violações >= {fail_on}. Resumo {counts} (arquivo: {json_path})"
            )

    return {"file": str(json_path), "violations_total": len(results.get("violations", [])), "by_impact": counts}