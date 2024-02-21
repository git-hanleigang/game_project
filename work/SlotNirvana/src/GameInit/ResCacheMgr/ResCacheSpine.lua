--[[
    
    author:{author}
    time:2022-01-18 14:45:50
]]
local ResCache = require("GameInit.ResCacheMgr.ResCache")
local ResCacheSpine = class("ResCacheSpine", ResCache)

function ResCacheSpine:ctor()
    ResCacheSpine.super.ctor(self)
    self.m_resInfo = {}
end

function ResCacheSpine:parseData(atlas, skel, isBinary)
    ResCacheSpine.super.parseData(self, atlas)

    self.m_resInfo[1] = atlas .. ".png"
    if not self.m_resInfo[2] then
        self.m_resInfo[2] = {}
    end
    if isBinary then
        table.insert(self.m_resInfo[2], skel .. ".skel")
    else
        table.insert(self.m_resInfo[2], skel .. ".json")
    end
end

function ResCacheSpine:cleanup()
    local plistInfo = self.m_resInfo or {}
    if plistInfo and #plistInfo == 2 then
        for _key, _value in pairs(self.m_resInfo[2]) do
            xcyy.SlotsUtil:releaseSpineCacheDataByName(_value)
        end
        display.removeImage(self.m_resInfo[1])
        -- self.m_resInfo[2] = {}
    end
end

return ResCacheSpine
