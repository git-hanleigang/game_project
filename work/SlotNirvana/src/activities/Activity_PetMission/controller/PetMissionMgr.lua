--[[
    宠物-7日任务
]]

local PetMissionNet = require("activities.Activity_PetMission.net.PetMissionNet")
local PetMissionMgr = class("PetMissionMgr", BaseActivityControl)

function PetMissionMgr:ctor()
    PetMissionMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.PetMission)
    self.m_netModel = PetMissionNet:getInstance()   -- 网络模块
end

function PetMissionMgr:showMainLayer(_data)
    local view = self:createPopLayer(_data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function PetMissionMgr:createEntryView(_data)
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity_PetMission.Activity.PetMissionEntryNode")
    return view
end

function PetMissionMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function PetMissionMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function PetMissionMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function PetMissionMgr:sendMissionReward(_day, _id)
    self.m_netModel:sendMissionReward(_day, _id)
end

function PetMissionMgr:sendPassReward(_idx)
    self.m_netModel:sendPassReward(_idx)
end

function PetMissionMgr:sendAllReward()
    self.m_netModel:sendAllReward()
end

function PetMissionMgr:sendPetInteraction()
    self.m_netModel:sendPetInteraction()
end

function PetMissionMgr:parseSpinData(_data)
    local gameData = self:getRunningData()
    if gameData and _data then
        gameData:parseSpinMissionData(_data)
    end
end

return PetMissionMgr
