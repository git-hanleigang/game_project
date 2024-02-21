---
--xcyy
--2018年5月23日
--PiggyLegendPirateProgressView.lua

local PiggyLegendPirateProgressView = class("PiggyLegendPirateProgressView",util_require("Levels.BaseLevelDialog"))

local PROGRESS_WIDTH = 740

function PiggyLegendPirateProgressView:initUI()

    self:createCsbNode("PiggyLegendPirate_jindutiao.csb")

    self.m_progress = self.m_csbOwner["Node_jindutiao"]
    self:initLoadingbar(0)

    -- 进度条上的猪
    self.m_progressZhuSpine = util_spineCreate("PiggyLegendPirate_jindutiao_zhu", true, true)
    self:findChild("pigSpine"):addChild(self.m_progressZhuSpine)
    util_spinePlay(self.m_progressZhuSpine, "idleframe", true)

    -- 进度条开始的猪
    self.m_ZhuSpine = util_spineCreate("Socre_PiggyLegendPirate_Bonus1", true, true)
    self:findChild("pig"):addChild(self.m_ZhuSpine)
    util_spinePlay(self.m_ZhuSpine, "idle2_1", true)

    self.m_jindutiaoTip = util_createAnimation("PiggyLegendPirate_jindutiaozhongdian.csb")
    self:findChild("Node_zhongdian"):addChild(self.m_jindutiaoTip)

    self.m_progressdituSpine = util_spineCreate("PiggyLegendPirate_jindutiao_ditu", true, true)
    self.m_jindutiaoTip:findChild("map"):addChild(self.m_progressdituSpine)
    util_spinePlay(self.m_progressdituSpine, "idleframe", true)

    self.m_progressTips = util_createAnimation("PiggyLegendPirate_tips.csb")
    self.m_jindutiaoTip:findChild("Node_tips"):addChild(self.m_progressTips)
    self.m_progressTips:setVisible(false)
    
    self.actNode = cc.Node:create()
    self:addChild(self.actNode)

    self:addClick(self:findChild("Panel_dianji"))
    -- self:addClick(self.m_jindutiaoTip:findChild("Button_1"))
end

function PiggyLegendPirateProgressView:onEnter()

    PiggyLegendPirateProgressView.super.onEnter(self)

end

function PiggyLegendPirateProgressView:onExit()
    
    PiggyLegendPirateProgressView.super.onExit(self)

end

function PiggyLegendPirateProgressView:updateLoadingbar(per,update)
    local percent = self:getPercent(per)
    if update then
        self:updateLoadingAct(percent)
        
    else
        self:initLoadingbar(percent)
    end
end

function PiggyLegendPirateProgressView:getPercent(percent)
    
    if percent then
        local percent1 = 0
        if percent > 100 then
            percent1 = 100
        elseif percent < 0 then
            percent1 = 0
        else
            percent1 = percent
        end
        return percent1
    end

    return percent
end

function PiggyLegendPirateProgressView:initLoadingbar(percent)
    self.m_progress:setPositionX(percent * 0.01 * PROGRESS_WIDTH)
end

function PiggyLegendPirateProgressView:updateLoadingAct(percent)
    self.actNode:stopAllActions() 
    local oldPercent = self.m_progress:getPositionX() / PROGRESS_WIDTH * 100
    local curOldPercent = self.m_progress:getPositionX() / PROGRESS_WIDTH * 100
    util_schedule(self.actNode,function( )
        oldPercent = oldPercent + (percent-curOldPercent)/12

        if oldPercent >= percent then
            oldPercent = percent
            self.m_progress:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
            self.actNode:stopAllActions() 
        else
            self.m_progress:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
        end
    end,0.05)
end

--默认按钮监听回调
function PiggyLegendPirateProgressView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if  name == "Panel_dianji" then 
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")

    end
end

function PiggyLegendPirateProgressView:showJiMan(func)
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_progress_jiman.mp3")
    self:runCsbAction("jiman",true)
    util_spinePlay(self.m_progressdituSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_progressdituSpine, "actionframe", function()
        util_spinePlay(self.m_progressdituSpine, "idleframe", true)
        self:runCsbAction("idle",true)

        if func then
            func()
        end
    end)
end

return PiggyLegendPirateProgressView