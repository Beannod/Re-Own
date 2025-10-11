import subprocess
import sys
import os
import json

if __name__ == "__main__":
    # Dev convenience: bypass DB session checks to avoid 401s after hot-reload
    os.environ.setdefault("BYPASS_DB_SESSION", "true")
    print("Starting backend...")
    backend = subprocess.Popen([sys.executable, "-m", "uvicorn", "backend.app.main:app", "--reload"])
    
    print("Starting frontend...")
    frontend = subprocess.Popen([sys.executable, "-m", "http.server", "8080"], cwd="frontend/public")
    
    # Write PIDs to file for restart/stop scripts
    pid_file = os.path.join(os.getcwd(), "reown_pids.json")
    try:
        with open(pid_file, 'w', encoding='utf-8') as f:
            json.dump({
                "backend_pid": backend.pid,
                "frontend_pid": frontend.pid
            }, f, indent=2)
    except Exception as e:
        print(f"Warning: failed to write pid file: {e}")
    
    print("Backend: http://127.0.0.1:8000")
    print("Frontend: http://127.0.0.1:8080")
    print("Press Ctrl+C to stop")
    
    try:
        backend.wait()
    except KeyboardInterrupt:
        backend.terminate()
        frontend.terminate()
    finally:
        # Clean up pid file
        try:
            if os.path.exists(pid_file):
                os.remove(pid_file)
        except Exception:
            pass
