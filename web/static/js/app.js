tailwind.config = {
    darkMode: 'class',
}

document.addEventListener('DOMContentLoaded', () => {
    const themeToggle = document.getElementById('theme-toggle');
    const html = document.documentElement;
    
    // Check local storage for theme
    if (localStorage.getItem('theme') === 'dark') {
        html.classList.add('dark');
        html.dataset.theme = 'dark';
    }

    if (themeToggle) {
        themeToggle.addEventListener('click', () => {
            html.classList.toggle('dark');
            if (html.classList.contains('dark')) {
                localStorage.setItem('theme', 'dark');
                html.dataset.theme = 'dark';
            } else {
                localStorage.setItem('theme', 'light');
                html.dataset.theme = 'light';
            }
        });
    }

    const sidebarToggle = document.getElementById('sidebar-toggle');
    const sidebar = document.getElementById('sidebar');
    
    if (sidebarToggle && sidebar) {
        sidebarToggle.addEventListener('click', () => {
            sidebar.classList.toggle('hidden');
        });
    }

    // WebSocket connection for dashboard
    if (document.getElementById('cpu-value')) {
        connectWS();
    }
});

function connectWS() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const ws = new WebSocket(`${protocol}//${window.location.host}/ws`);
    
    ws.onmessage = (event) => {
        try {
            const data = JSON.parse(event.data);
            if (data.cpu !== undefined) {
                document.getElementById('cpu-value').innerText = data.cpu.toFixed(1);
                if (document.getElementById('cpu-bar')) {
                    document.getElementById('cpu-bar').style.width = `${data.cpu}%`;
                }
            }
            if (data.ram_percent !== undefined) {
                document.getElementById('ram-percent').innerText = data.ram_percent.toFixed(1);
                document.getElementById('ram-bar').style.width = `${data.ram_percent}%`;
            }
        } catch (e) {
            console.error(e);
        }
    };
    
    ws.onclose = () => {
        setTimeout(connectWS, 3000);
    };
}
