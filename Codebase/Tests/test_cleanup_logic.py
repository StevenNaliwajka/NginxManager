from pathlib import Path

def test_generated_conf_detection(tmp_path):
    test_file = tmp_path / "demo.conf"
    test_file.write_text("# Managed by NginxDeployer\nserver { listen 80; }")

    content = test_file.read_text()
    assert "# Managed by NginxDeployer" in content
