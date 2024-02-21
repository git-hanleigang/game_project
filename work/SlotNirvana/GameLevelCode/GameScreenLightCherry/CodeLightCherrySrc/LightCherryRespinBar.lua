---
--xcyy
--2018年5月29日
--LightCherryRespinBar.lua

local LightCherryRespinBar = class("LightCherryRespinBar", util_require("base.BaseView"))

function LightCherryRespinBar:initUI(data)
    self:createCsbNode("LightCherry_respin_bar.csb")
    self.m_nRespinNum = 0
    self.m_TotalRespin = 0

    local parent =  self:findChild("Node_0")
    self.m_respinItem = util_createView("CodeLightCherrySrc.LightCherryRespinBarItem")
    parent:addChild(self.m_respinItem)

    self.m_countNode = self:findChild("Node_2")
    self.m_completeNode = self:findChild("Node_1")
end

function LightCherryRespinBar:onEnter()
    gLobalNoticManager:addObserver(self, function()  -- 显示 freespin count
        if self and self.updateLeftCount then
            self:updateLeftCount(globalData.slotRunData.iReSpinCount)
        end
    end,ViewEventType.SHOW_RESPIN_SPIN_NUM)
end

function LightCherryRespinBar:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function LightCherryRespinBar:showRespinBar(totalRespin)
    self:runCsbAction("freespinnum"..totalRespin)

    self:showCompleteNode(false)
    self.m_TotalRespin = totalRespin
    self.m_respinItem:changeMaxCountShow(totalRespin)
end

-- 更新 respin 次数
function LightCherryRespinBar:updateLeftCount(respinCount,isInit)
    self.m_nRespinNum = respinCount
    self.m_respinItem:updateCurCount(respinCount,isInit)
end

function LightCherryRespinBar:showCompleteNode(isShow)
    self.m_countNode:setVisible(not isShow)
    self.m_completeNode:setVisible(isShow)
end
return LightCherryRespinBar