from pathlib import Path

import pytest

from Codebase.ssl_manager import get_certificate_if_needed


def test_cert_plugin_missing_email():
    site = {
        "domain": "missingemail.com",
        "enable_ssl": True,
        "cert_plugin": "dns-01",
        "dns_provider": "cloudflare"
    }

    with pytest.raises(ValueError, match="Missing cert_email"):
        get_certificate_if_needed(site, Path("/tmp"), test_mode=True)
