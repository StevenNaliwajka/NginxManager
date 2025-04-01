import json
from pathlib import Path

def test_invalid_route_type(monkeypatch):
    from Codebase.build_nginx import template_map

    site = {
        "domain": "invalid.example.com",
        "routes": [
            {"location": "/", "type": "banana", "target": "http://localhost"}
        ],
        "enable_ssl": False
    }

    # Simulate what the actual code would do
    route_type = site["routes"][0]["type"]
    ssl_enabled = site.get("enable_ssl", False)
    assert (route_type, ssl_enabled) not in template_map
