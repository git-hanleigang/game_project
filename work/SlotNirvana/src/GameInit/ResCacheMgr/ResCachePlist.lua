--[[
    
    author:{author}
    time:2022-01-18 14:45:50
]]
local ResCache = require("GameInit.ResCacheMgr.ResCache")
local ResCachePlist = class("ResCachePlist", ResCache)

function ResCachePlist:ctor()
    ResCachePlist.super.ctor(self)
    self.m_plistInfo = {}
end

function ResCachePlist:parseData(path)
    ResCachePlist.super.parseData(self, path)

    self.m_plistInfo[1] = path .. ".png"
    self.m_plistInfo[2] = path .. ".plist"
end

function ResCachePlist:cleanup()
    local plistInfo = self.m_plistInfo or {}
    if plistInfo and #plistInfo == 2 then
        display.removeSpriteFrames(plistInfo[2], plistInfo[1])
    end
end

return ResCachePlist
