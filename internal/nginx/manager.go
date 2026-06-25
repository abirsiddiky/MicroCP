package nginx

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"text/template"
)

type VhostData struct {
	Domain       string
	DocumentRoot string
	PHPVersion   string
}

const vhostTemplate = `
server {
    listen 80;
    listen [::]:80;
    server_name {{.Domain}} www.{{.Domain}};
    root {{.DocumentRoot}};
    index index.php index.html;

    access_log /var/log/nginx/{{.Domain}}.access.log;
    error_log /var/log/nginx/{{.Domain}}.error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php{{.PHPVersion}}-fpm-{{.Domain}}.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
`

func CreateVhost(data VhostData) error {
	t, err := template.New("vhost").Parse(vhostTemplate)
	if err != nil {
		return err
	}

	var buf bytes.Buffer
	if err := t.Execute(&buf, data); err != nil {
		return err
	}

	confPath := filepath.Join("/etc/nginx/sites-available", data.Domain+".conf")
	if err := os.WriteFile(confPath, buf.Bytes(), 0644); err != nil {
		return err
	}

	symlinkPath := filepath.Join("/etc/nginx/sites-enabled", data.Domain+".conf")
	os.Remove(symlinkPath)
	os.Symlink(confPath, symlinkPath)

	return nil
}

func Reload() error {
	cmd := exec.Command("nginx", "-s", "reload")
	return cmd.Run()
}
