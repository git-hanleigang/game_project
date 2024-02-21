--[[
    完成任务装饰圣诞树
]]

local MissionsToDIYGuideMgr = require("activities.Activity_MissionsToDIY.controller.MissionsToDIYGuideMgr")
local MissionsToDIYConfig = require("activities.Activity_MissionsToDIY.config.MissionsToDIYConfig")
local MissionsToDIYNet = require("activities.Activity_MissionsToDIY.net.MissionsToDIYNet")
local MissionsToDIYMgr = class("MissionsToDIYMgr", BaseActivityControl)

function MissionsToDIYMgr:ctor()
    MissionsToDIYMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.MissionsToDIY)
    self.m_net = MissionsToDIYNet:getInstance()
    self.m_guide = MissionsToDIYGuideMgr:getInstance()
end

function MissionsToDIYMgr:showMainLayer(_data)
    local view = self:createPopLayer(_data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function MissionsToDIYMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function MissionsToDIYMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function MissionsToDIYMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function MissionsToDIYMgr:getEntryPath(entryName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. entryName .. "EntryNode" 
end

function MissionsToDIYMgr:sendCollect(_index, _selections)
    self.m_net:sendCollect(_index, _selections)
end

function MissionsToDIYMgr:setSaveData(_saveData)
    self.m_net:setSaveData(_saveData)
end

function MissionsToDIYMgr:sendRefreshData()
    self.m_net:sendRefreshData()
end

function MissionsToDIYMgr:saveDecorateSelect(_idx, _type)
    local gameData = self:getRunningData()
    if gameData then
        local saveTime = gLobalDataManager:getNumberByField("MissionsToDIYTime", 0)
        local expireAt = gameData:getExpireAt()
        if expireAt > saveTime then
            local data = {}
            data[_idx] = _type
            local str = cjson.encode(data)
            gLobalDataManager:setNumberByField("MissionsToDIYTime", expireAt)
            gLobalDataManager:setStringByField("MissionsToDIY", str)
        else
            local saveData = gLobalDataManager:getStringByField("MissionsToDIY", "{}")
            local data = cjson.decode(saveData)
            data[_idx] = _type
            local str = cjson.encode(data)
            gLobalDataManager:setStringByField("MissionsToDIY", str)
        end
    end
end

function MissionsToDIYMgr:getDecorateSelect()
    local tb = {}
    local gameData = self:getRunningData()
    if gameData then
        local saveTime = gLobalDataManager:getNumberByField("MissionsToDIYTime", 0)
        local expireAt = gameData:getExpireAt()
        if expireAt <= saveTime then
            local saveData = gLobalDataManager:getStringByField("MissionsToDIY", "{}")
            tb = cjson.decode(saveData)
        end

        if #tb == 0 then
            local selections = gameData:getSelections()
            for i,v in ipairs(selections) do
                table.insert(tb, v)
            end
        end 
    end

    return tb
end

function MissionsToDIYMgr:parseSpinData(_data)
    if not _data then
        return
    end

    local gameData = self:getRunningData()
    if not gameData then
        return
    end
    
    gameData:parseSpinData(_data)
end

function MissionsToDIYMgr:getGuide()
    return self.m_guide
end

function MissionsToDIYMgr:triggerGuide(view, name)
    if tolua.isnull(view) or not name then
        return false
    end
    return self.m_guide:triggerGuide(view, name, ACTIVITY_REF.MissionsToDIY)
end

return MissionsToDIYMgr
