import os
import re
import subprocess
import threading
import glob
import uuid
from flask import Flask, request, jsonify, send_from_directory

app = Flask(__name__)
ROOT = os.path.dirname(os.path.abspath(__file__))

# Only one simulation at a time — iverilog shares data_bin.txt
_sim_lock = threading.Lock()


@app.route("/")
def index():
    return send_from_directory(os.path.join(ROOT, "web"), "index.html")


@app.route("/futuristic")
def index_futuristic():
    return send_from_directory(os.path.join(ROOT, "web"), "index_futuristic.html")


@app.route("/api/run", methods=["POST"])
def run():
    data = request.get_json(force=True)
    code = data.get("code", "").strip()
    kbd_input = data.get("kbd_input", "")

    if not code:
        return jsonify({"success": False, "errors": ["No assembly code provided."],
                        "display_output": "", "timed_out": False})

    if not _sim_lock.acquire(blocking=False):
        return jsonify({"success": False,
                        "errors": ["Another simulation is already running. Try again in a moment."],
                        "display_output": "", "timed_out": False})
    try:
        return _run_simulation(code, kbd_input)
    finally:
        _sim_lock.release()


def _run_simulation(code, kbd_input):
    req_id   = uuid.uuid4().hex[:8]
    asm_file = os.path.join(ROOT, f"web_temp_{req_id}.asm")
    kbd_file = os.path.join(ROOT, "kbd_input.txt")          # hardcoded in web_io_tb.v
    bin_file = os.path.join(ROOT, "data_bin.txt")           # hardcoded in memory.v
    bin_tmp  = os.path.join(ROOT, f"data_bin_tmp_{req_id}.txt")
    sim_bin  = os.path.join(ROOT, f"web_io_tb_sim_{req_id}")

    try:
        # Write source files
        with open(asm_file, "w") as f:
            f.write(code + "\n")
        with open(kbd_file, "w") as f:
            f.write(kbd_input)

        # Step 1 — assemble
        asm_result = subprocess.run(
            ["python3", "CPU-Assembler/main.py", asm_file, bin_tmp],
            cwd=ROOT, capture_output=True, text=True, timeout=15,
        )
        if asm_result.returncode != 0:
            raw = (asm_result.stdout + asm_result.stderr).strip()
            # Extract the meaningful error line from a Python traceback
            lines = [l.strip() for l in raw.splitlines() if l.strip()]
            err = next((l for l in reversed(lines) if not l.startswith("File ") and not l.startswith("Traceback")), raw) or "Assembler failed."
            return jsonify({"success": False, "errors": ["Assembler error: " + err],
                            "display_output": "", "timed_out": False})

        # Step 2 — data_init (non-interactive defaults)
        subprocess.run(
            ["python3", "data_init.py", "--input", bin_tmp, "--output", bin_file, "--defaults"],
            cwd=ROOT, capture_output=True, text=True, timeout=15,
        )

        # Step 3 — compile
        cpu_files = sorted(
            f for f in glob.glob(os.path.join(ROOT, "CPU", "*.v"))
            if "_tb" not in os.path.basename(f)
        )
        compile_result = subprocess.run(
            ["iverilog", "-o", sim_bin] + cpu_files + [os.path.join(ROOT, "web_io_tb.v")],
            cwd=ROOT, capture_output=True, text=True, timeout=30,
        )
        if compile_result.returncode != 0:
            err = (compile_result.stdout + compile_result.stderr).strip()
            return jsonify({"success": False, "errors": ["Verilog compile error:\n" + err],
                            "display_output": "", "timed_out": False})

        # Step 4 — simulate
        sim_result = subprocess.run(
            ["vvp", sim_bin],
            cwd=ROOT, capture_output=True, timeout=30,
        )
        output = sim_result.stdout.decode('utf-8', errors='replace')

        # Parse display characters and register state
        display_chars = []
        registers = {}
        for line in output.splitlines():
            if line.startswith("DISP:"):
                display_chars.append(line[5:])
            else:
                m = re.match(r'^(PC|X|Y|A|SP)\s*=\s*([0-9a-fA-F]+)', line.strip())
                if m:
                    registers[m.group(1)] = int(m.group(2), 16)
                else:
                    mf = re.match(r'^Flags:\s*Z=(\d)\s+N=(\d)\s+C=(\d)\s+O=(\d)', line.strip())
                    if mf:
                        registers['flags'] = {'Z': int(mf.group(1)), 'N': int(mf.group(2)),
                                              'C': int(mf.group(3)), 'O': int(mf.group(4))}
        display_output = "".join(display_chars)

        timed_out = "SIM_TIMEOUT" in output

        return jsonify({
            "success": True,
            "errors": ["Simulation timed out — possible infinite loop."] if timed_out else [],
            "display_output": display_output,
            "registers": registers,
            "timed_out": timed_out,
        })

    except subprocess.TimeoutExpired as e:
        return jsonify({"success": False,
                        "errors": [f"Process timed out: {e}"],
                        "display_output": "", "timed_out": True})
    except Exception as e:
        return jsonify({"success": False, "errors": [str(e)],
                        "display_output": "", "timed_out": False})
    finally:
        for path in [asm_file, kbd_file, bin_tmp, sim_bin]:
            try:
                os.remove(path)
            except OSError:
                pass


if __name__ == "__main__":
    print("IAS-Overclockers Web Simulator")
    print("Open http://localhost:5000 in your browser")
    app.run(debug=False, port=5000)
