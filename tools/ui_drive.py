"""Tiny XML-RPC bridge: lets external scripts tap/swipe/key the simulator.

Runs on the Mac host; talks to the booted simulator over idb if available,
else falls back to AppleScript UI scripting on the Simulator window.
Usage: python3 tools/ui_bridge.py serve
"""
