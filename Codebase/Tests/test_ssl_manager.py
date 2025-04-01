from Codebase.ssl_manager import get_certificate_if_needed
from pathlib import Path

def test_unknown_cert_plugin(monkeypatch):
    site = {
        "domain": "invalid.example.com",
        "cert_plugin": "not-a-real-plugin",
        "dns_provider": "cloudflare"
    }

    reloaded = []

    def fake_reload():
        reloaded.append(True)

    monkeypatch.setattr("Codebase.ssl_manager.reload_nginx", fake_reload)

    get_certificate_if_needed(site, cert_path=Path("/tmp/fake_cert_path"), test_mode=True)

    assert not reloaded, "Nginx should not reload for invalid cert plugin"
