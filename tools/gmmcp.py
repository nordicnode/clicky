#!/usr/bin/env python3
"""Minimal stdio MCP client for the GameMaker resourcetool server.
Usage:  gmmcp.py call <tool> '<json args>'
        gmmcp.py list
"""
import json, subprocess, sys

PROJ = "/home/mikey/Desktop/dev/clicky/Clicky/Clicky.yyp"
PROJ_DIR = "/home/mikey/Desktop/dev/clicky/Clicky"

class Client:
    def __init__(self):
        self.p = subprocess.Popen(
            ["npx", "-y", "@gamemaker/gm-cli@2.4.1", "resourcetool", "mcp", PROJ],
            cwd=PROJ_DIR, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, text=True, bufsize=1)
        self.id = 0
        self._send({"jsonrpc": "2.0", "id": self.next_id(), "method": "initialize",
                    "params": {"protocolVersion": "2024-11-05", "capabilities": {},
                               "clientInfo": {"name": "gmmcp", "version": "1"}}})
        self._wait()
        self._send({"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}})

    def next_id(self):
        self.id += 1
        return self.id

    def _send(self, o):
        self.p.stdin.write(json.dumps(o) + "\n")
        self.p.stdin.flush()

    def _wait(self):
        for line in self.p.stdout:
            try:
                d = json.loads(line)
            except Exception:
                continue
            if "id" in d:
                return d
        raise RuntimeError("server closed")

    def call(self, name, args=None):
        rid = self.next_id()
        self._send({"jsonrpc": "2.0", "id": rid, "method": "tools/call",
                    "params": {"name": name, "arguments": args or {}}})
        d = self._wait()
        if "error" in d:
            raise RuntimeError(d["error"])
        res = d.get("result", {})
        out = "\n".join(c.get("text", "") for c in res.get("content", [])
                        if c.get("type") == "text")
        return out

    def close(self):
        try:
            self.p.kill()
        except Exception:
            pass

if __name__ == "__main__":
    c = Client()
    try:
        if sys.argv[1] == "list":
            print(c.call("resource_list", {}))
        else:
            print(c.call(sys.argv[2], json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}))
    finally:
        c.close()
