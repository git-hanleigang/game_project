---
--xcyy
--2018年5月23日
--BeastlyBeautyPregressBarView.lua

local BeastlyBeautyPregressBarView = class("BeastlyBeautyPregressBarView",util_require("Levels.BaseLevelDialog"))

local PROGRESS_WIDTH = 920

function BeastlyBeautyPregressBarView:initUI()

    self:createCsbNode("BeastlyBeauty_jindutiao.csb")

    self.m_progress = self.m_csbOwner["Node_jindutiao"]

    -- 按钮
    self.m_anniuBtn = util_createAnimation("BeastlyBeauty_btnTip.csb")
    self:findChild("Node_anniu"):addChild(self.m_anniuBtn)

    -- 说明tips
    self.m_shoujiTips = util_createAnimation("BeastlyBeauty_shoujitishi.csb")
    self.m_anniuBtn:findChild("Node_shuoming"):addChild(self.m_shoujiTips)
    self.m_shoujiTips:setVisible(false)

    -- 集满
    self.m_jiManNode = util_spineCreate("BeastlyBeauty_jindutiao_you",true,true)
    self:findChild("Node_jiman"):addChild(self.m_jiManNode)
    util_spinePlay(self.m_jiManNode, "idle", true)

    -- 锁定
    self.m_suoDingNode2 = util_spineCreate("BeastlyBeauty_jindutiao_lock02",true,true)
    self:findChild("Node_suoding"):addChild(self.m_suoDingNode2,100)
    self.m_suoDingNode2:setVisible(false)

    self.m_suoDingNode1 = util_spineCreate("BeastlyBeauty_jindutiao_lock01",true,true)
    self:findChild("Node_suoding"):addChild(self.m_suoDingNode1,200)
    self.m_suoDingNode1:setVisible(false)

    self.actNode = cc.Node:create()
    self:addChild(self.actNode)

    self:addClick(self:findChild("click_pregress"))
    self:addClick(self.m_anniuBtn:findChild("Button"))

    self:runCsbAction("idle",true)
end

--默认按钮监听回调
function BeastlyBeautyPregressBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button" then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_click)
        gLobalNoticManager:postNotification("SHOW_BTN_Tip")

    elseif name == "click_pregress" then 
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_click)
        gLobalNoticManager:postNotification("SHOW_UNLOCK_PREGRESS")

    end
end

function BeastlyBeautyPregressBarView:initMachine(machine)
    self.m_machine = machine
end

-- function BeastlyBeautyPregressBarView:progressEffect(percent,isPlay)
--     self.m_progress:setPercent(percent)

-- end

function BeastlyBeautyPregressBarView:updateLoadingbar(per,update)
    local percent = self:getPercent(per)
    if update then
        self:updateLoadingAct(percent)
        
    else
        self:initLoadingbar(percent)
    end
end

function BeastlyBeautyPregressBarView:getPercent(percent)
    
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

function BeastlyBeautyPregressBarView:initLoadingbar(percent)
    self.m_progress:setPositionX(percent * 0.01 * PROGRESS_WIDTH)
end

function BeastlyBeautyPregressBarView:updateLoadingAct(percent)
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


return BeastlyBeautyPregressBarView