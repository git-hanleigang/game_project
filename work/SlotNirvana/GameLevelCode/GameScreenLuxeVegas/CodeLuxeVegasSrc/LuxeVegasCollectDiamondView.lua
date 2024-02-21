---
--xcyy
--2018年5月23日
--LuxeVegasCollectDiamondView.lua
local PublicConfig = require "LuxeVegasPublicConfig"
local LuxeVegasCollectDiamondView = class("LuxeVegasCollectDiamondView",util_require("Levels.BaseLevelDialog"))


function LuxeVegasCollectDiamondView:initUI()

    self:createCsbNode("LuxeVegas_FGzhanshi.csb")

    self.m_freeCountData = {1, 1, 1}
    self.m_freeCountAniTbl = {}
    self.m_freeCountTbl = {}
    for i=1, 3 do
        self.m_freeCountAniTbl[i] = util_createAnimation("LuxeVegas_FGzhanshi_number.csb")
        self:findChild("number"..i):addChild(self.m_freeCountAniTbl[i])
        self.m_freeCountTbl[i] = self.m_freeCountAniTbl[i]:findChild("free_count")
    end

    self:playIdle()
end

function LuxeVegasCollectDiamondView:playIdle()
    self:runCsbAction("idle", true)
    for i=1, #self.m_freeCountData do
        if self.m_freeCountData[i] and self.m_freeCountData[i] >= 20 then
            self.m_freeCountAniTbl[i]:runCsbAction("idle2", true)
        else
            self.m_freeCountAniTbl[i]:runCsbAction("idle1", true)
        end
    end
end

function LuxeVegasCollectDiamondView:playTriggerAct(_freeType)
    local freeType = _freeType
    util_resetCsbAction(self.m_csbAct)
    local actName = "actionframe"..freeType
    self.m_freeCountAniTbl[freeType]:runCsbAction("actionframe", false)
    self:runCsbAction(actName, false, function()
        self:playIdle()
    end)
end

function LuxeVegasCollectDiamondView:refreshFreeCount(_curFreeCountData)
    local curFreeCountData = _curFreeCountData
    if curFreeCountData then
        for i=1, 3 do
            self.m_freeCountTbl[i]:setString(curFreeCountData[i])
        end
    else
        for i=1, 3 do
            self.m_freeCountTbl[i]:setString(self.m_freeCountData[i])
        end
    end
end

function LuxeVegasCollectDiamondView:setFreeCountData(_freeCountData, _isRefresh)
    self.m_freeCountData = _freeCountData
    if _isRefresh then
        self:refreshFreeCount()
        self:playIdle()
    end
end

return LuxeVegasCollectDiamondView
