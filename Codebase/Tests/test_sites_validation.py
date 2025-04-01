import json
from pathlib import Path

SITES_FILE = Path("../Config/sites.json")

def test_sites_json_valid_structure():
    with open(SITES_FILE) as f:
        sites = json.load(f)

    assert isinstance(sites, list), "sites.json must be a list"

    for site in sites:
        assert "domain" in site, "Each site must have a 'domain'"
        assert isinstance(site.get("routes"), list), "Each site must have a list of 'routes'"
        for route in site["routes"]:
            assert "type" in route, "Each route must have a 'type'"
            assert "target" in route, "Each route must have a 'target'"
            assert route["type"] in ("proxy", "host"), f"Invalid route type: {route['type']}"
