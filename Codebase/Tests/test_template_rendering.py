from jinja2 import Environment, FileSystemLoader
from pathlib import Path

def test_all_templates_render():
    template_dir = Path("../Codebase/Templates")
    env = Environment(loader=FileSystemLoader(str(template_dir)))

    context = {
        "domain": "test.example.com",
        "routes": [{"location": "/", "type": "proxy", "target": "http://localhost"}],
        "cert_path": "/fake/cert/path"
    }

    for tmpl in template_dir.glob("*.j2"):
        template = env.get_template(tmpl.name)
        rendered = template.render(**context)
        assert "server_name" in rendered, f"{tmpl.name} did not render correctly"
