--[[
    LEVEL UP PASS
]]

local LevelUpPassNet = require("activities.Activity_LevelUpPass.net.LevelUpPassNet")
local LevelUpPassMgr = class("LevelUpPassMgr", BaseActivityControl)

function LevelUpPassMgr:ctor()
    LevelUpPassMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.LevelUpPass)
    self.m_net = LevelUpPassNet:getInstance()
    self.m_chekcCount = 0
end

function LevelUpPassMgr:showMainLayer(_data)
    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function LevelUpPassMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function LevelUpPassMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function LevelUpPassMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function LevelUpPassMgr:getEntryPath(entryName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. entryName .. "EntryNode" 
 end

function LevelUpPassMgr:sendCollect(_data, _type)
    self.m_net:sendCollect(_data, _type)
end

function LevelUpPassMgr:buyUnlock(_data)
    self.m_net:buyUnlock(_data)
end

function LevelUpPassMgr:checkMainLayerOpen()
    self.m_chekcCount = self.m_chekcCount + 1
    if self.m_chekcCount ~= 2 then
        return
    end

    local data = self:getRunningData()
    if data then
        local rewardCount = data:getCanCollectCount()
        if rewardCount > 0 then
            return self:showMainLayer()
        end
    end
end

function LevelUpPassMgr:resetCheckCount()
    self.m_chekcCount = 0
end

return LevelUpPassMgr
