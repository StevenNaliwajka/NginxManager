from Codebase.ssl_manager import get_certificate_if_needed
from pathlib import Path

def test_cert_plugin_missing_email():
    site = {
        "domain": "missingemail.com",
        "enable_ssl": True,
        "cert_plugin": "dns-01",
        "dns_provider": "cloudflare"
    }

    try:
        get_certificate_if_needed(site, Path("/tmp"), test_mode=True)
    except Exception as e:
        assert isinstance(e, KeyError) or "email" in str(e)
