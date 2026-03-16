local addon, ns = ...

-- ============================================================
-- MOUNT MANAGER — Stub (Logic moved to EventLoop.lua)
-- ============================================================

-- This file is now a stub to avoid TOC errors.
-- Logic has been simplified and moved to EventLoop.lua to prevent
-- race conditions and ensure unified vehicle handling.

-- ns.MountManager is now initialized in EventLoop.lua 
-- but we ensure it's available early if needed.
if not ns.MountManager then
    ns.MountManager = {}
end
