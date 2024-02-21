---
--xcyy
--2018年5月23日
--CashRushJackpotsWildBarView.lua

local CashRushJackpotsWildBarView = class("CashRushJackpotsWildBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CashRushJackpotsPublicConfig"

function CashRushJackpotsWildBarView:initUI()

    self:createCsbNode("CashRushJackpots_Free_WildsAddedTips.csb")

    self.m_wildCount = self:findChild("m_lb_num")
    self:runCsbAction("idle", true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function CashRushJackpotsWildBarView:setShowStart()
    self:setWildCount(0)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
end

function CashRushJackpotsWildBarView:setShowOver()
    gLobalSoundManager:playSound(PublicConfig.Music_Fg_Text_Disappear)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

function CashRushJackpotsWildBarView:changeFreeStarCount(_freeStarCount)
    self:setWildCount(0)
    local freeStarCount = _freeStarCount
    if freeStarCount == 2 then
        self:findChild("sp_wild_2"):setVisible(true)
        self:findChild("sp_wild_3"):setVisible(false)
    else
        self:findChild("sp_wild_3"):setVisible(true)
        self:findChild("sp_wild_2"):setVisible(false)
    end
end

function CashRushJackpotsWildBarView:setWildCount(_wildCount)
    local wildCount = _wildCount
    self.m_wildCount:setString(wildCount)
end

function CashRushJackpotsWildBarView:jumpWildCount(_freeWildCount, _freeStarCount, _delayTime)
    local freeWildCount = _freeWildCount or 30
    local freeStarCount = _freeStarCount or 2
    local delayTime = _delayTime

    util_resetCsbAction(self.m_csbAct)
    if freeStarCount == 2 then
        gLobalSoundManager:playSound(PublicConfig.Music_Fg_Add_Wild_Short)
        --200
        delayTime = 135/60
        self:runCsbAction("shangzhang1", false, function()
            self:setShowOver()
        end)
    else
        gLobalSoundManager:playSound(PublicConfig.Music_Fg_Add_Wild_Long)
        --248
        delayTime = 180/60
        self:runCsbAction("shangzhang2", false, function()
            self:setShowOver()
        end)
    end

    local intervalTime = delayTime / freeWildCount

    local curCount = 0
    -- local countRiseNum =  freeWildCount / (delayTime * 30)  -- 每秒60帧
    -- countRiseNum = math.floor(countRiseNum)
    -- if countRiseNum < 1 then
    --     countRiseNum = 1
    -- end
    local countRiseNum = 1
    self:setWildCount(countRiseNum)

    self.m_scWaitNode:stopAllActions()
    util_schedule(self.m_scWaitNode, function()
        curCount = curCount + countRiseNum
        if curCount >= freeWildCount then
            gLobalSoundManager:playSound(PublicConfig.Music_Fg_Text_EndTips)
            self:setWildCount(freeWildCount)
            self.m_scWaitNode:stopAllActions()
        else
            self:setWildCount(curCount)
        end
    end, intervalTime)
end

return CashRushJackpotsWildBarView
