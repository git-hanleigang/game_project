---
--xcyy
--2018年5月23日
--GhostCaptainChooseBetView.lua

local GhostCaptainChooseBetView = class("GhostCaptainChooseBetView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "GhostCaptainPublicConfig"

function GhostCaptainChooseBetView:initUI(_params)
    self.m_machine = _params.machine
    self:createCsbNode("GhostCaptain/GhostCaptain_base_bet_message.csb")
    self.m_col = 5
    self.m_coinLabel = {}
    self.m_itemTab = {}
    self:addClick(self:findChild("Panel_1"))
    for index = 1, self.m_col do
        local item = util_createAnimation("GhostCaptain_reels_reward.csb")
        self:findChild("Node_reel_"..index):addChild(item)
        self:addClick(item:findChild("click_Btn"))
        item:findChild("click_Btn"):setTag(index)
        self:initItemCol(item, index)
        table.insert(self.m_coinLabel, item:findChild("m_lb_coins"))
        table.insert(self.m_itemTab, item)
    end

    -- 扫光
    local guangSpine = util_spineCreate("GhostCaptain_tb_2", true, true)
    self:findChild("Node_zi_sg"):addChild(guangSpine)
    util_spinePlay(guangSpine, "2_idle", true)
end


function GhostCaptainChooseBetView:onEnter()
 
    GhostCaptainChooseBetView.super.onEnter(self)
end

function GhostCaptainChooseBetView:showAdd()
    
end

function GhostCaptainChooseBetView:onExit()
    GhostCaptainChooseBetView.super.onExit(self)
end

function GhostCaptainChooseBetView:initItemCol(item, curIndex)
    for index = 1,self.m_col do
        item:findChild("GhostCaptain_tb_bet"..index):setVisible(index == curIndex)
    end
    if curIndex == 5 then
        item:runCsbAction("idle4", true)
    else
        item:runCsbAction("idleframe3", true)
    end
end

--默认按钮监听回调
function GhostCaptainChooseBetView:clickFunc(sender)
    if not self.m_canClick then
        return
    end
    self.m_canClick = false
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_1" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_click)
        self:hideView()
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_betView_click)
        self:setUI(tag)
    end
end

function GhostCaptainChooseBetView:setUI(_tag)
    for i=1,#self.m_itemTab do
        if i == _tag then
            self.m_itemTab[i]:runCsbAction("actionframe", false, function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_betView_over)
                self:hideView(function()
                    self.m_machine:chooseBetLevel(_tag)
                    self.m_machine.m_controlBetView:playIdle2()
                end)
            end)
        else
            if self.m_isEnter then
                self.m_itemTab[i]:runCsbAction("yaan_start", false, function()
                    self.m_itemTab[i]:runCsbAction("yaan_idle", true)
                end)
            else
                if self.m_curSelectIndex and self.m_curSelectIndex == i then
                    self.m_itemTab[i]:runCsbAction("yaan_start", false, function()
                        self.m_itemTab[i]:runCsbAction("yaan_idle", true)
                    end)
                end
            end
        end
    end
end

function GhostCaptainChooseBetView:hideView(callBack)
    self:runCsbAction("over", false, function()
        if callBack then
            callBack()
        else
            self.m_machine:setSpinTounchType(true)
        end
        self.m_machine.m_controlBetView:playIdle2()
        self:setVisible(false)
    end)
end
 
function GhostCaptainChooseBetView:showView(_iBetLevel)
    self:setVisible(true)
    self:initcoins()
    if _iBetLevel and _iBetLevel >= 0 then
        self.m_isEnter = false
        self:playItemYaAnEffect(_iBetLevel)
    else
        self.m_isEnter = true
    end
    self.m_machine.m_controlBetView:playIdle3()
    if _iBetLevel then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_betView_start)
    end
    self:runCsbAction("start", false, function()
        self.m_canClick = true
        self:playIdle()
    end)
end

function GhostCaptainChooseBetView:initcoins()
    for index = 1, self.m_col do
        local lable = self.m_coinLabel[index]
        local strCoins = self.m_machine:getBetLevelCoins(index)
        local strCoins = util_formatCoins(strCoins, 3)
        lable:setString(strCoins)
    end
end

function GhostCaptainChooseBetView:playIdle()
    self:runCsbAction("idle", true)
end

function GhostCaptainChooseBetView:playItemYaAnEffect(_iBetLevel)
    for index = 1, #self.m_itemTab do
        if index ~= (_iBetLevel+1) then
            self.m_itemTab[index]:runCsbAction("yaan_idle", true)
        else
            if index == 5 then
                self.m_itemTab[index]:runCsbAction("idle4", true)
            else
                self.m_itemTab[index]:runCsbAction("idleframe3", true)
            end
            self.m_curSelectIndex = index
        end
    end
end

return GhostCaptainChooseBetView