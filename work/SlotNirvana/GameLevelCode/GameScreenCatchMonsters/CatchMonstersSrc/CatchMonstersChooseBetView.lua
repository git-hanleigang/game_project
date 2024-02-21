---
--xcyy
--2018年5月23日
--CatchMonstersChooseBetView.lua

local CatchMonstersChooseBetView = class("CatchMonstersChooseBetView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CatchMonstersPublicConfig"
local COINS_NAME = {"mini_bet_coins", "minor_bet_coins", "major_bet_coins", "grand_bet_coins"}

function CatchMonstersChooseBetView:initUI(_params)
    self.m_machine = _params.machine
    self:createCsbNode("CatchMonsters/CatchMonsters_basebet.csb")
    self.m_col = 4
    self.m_coinLabel = {}
    self.m_itemTab = {}
    self:addClick(self:findChild("Panel_5"))
    for index = 1, self.m_col do
        local item = util_createAnimation("CatchMonsters_BaseBet_choose.csb")
        self:findChild("Node_reel_"..index):addChild(item)
        self:addClick(self:findChild("Panel_"..index))
        local coinsNode = util_createAnimation("CatchMonsters_BaseBet_coins.csb")
        item:findChild(COINS_NAME[index]):addChild(coinsNode)
        self:findChild("Panel_"..index):setTag(index)
        self:initItemCol(item, index)
        table.insert(self.m_coinLabel, coinsNode)
        table.insert(self.m_itemTab, item)
    end

    -- tips界面
    self.m_chooseBetTipsView = util_createView("CatchMonstersSrc.CatchMonstersChooseBetTipsView")
    self:findChild("Node_tips"):addChild(self.m_chooseBetTipsView)
    self.m_chooseBetTipsView:setVisible(false)
end


function CatchMonstersChooseBetView:onEnter()
 
    CatchMonstersChooseBetView.super.onEnter(self)
end

function CatchMonstersChooseBetView:showAdd()
    
end

function CatchMonstersChooseBetView:onExit()
    CatchMonstersChooseBetView.super.onExit(self)
end

function CatchMonstersChooseBetView:initItemCol(item, curIndex)
    for index = 1,self.m_col do
        item:findChild("Node_"..index):setVisible(index == curIndex)
    end
end

--默认按钮监听回调
function CatchMonstersChooseBetView:clickFunc(sender)
    
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_click)
        self.m_chooseBetTipsView:showView()
    elseif name == "Panel_5" then
        if not self.m_canClick then
            return
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_click)
        self.m_canClick = false
        self:hideView()
    else
        if not self.m_canClick then
            return
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_click)
        self.m_canClick = false
        self:setUI(tag)
    end
end

function CatchMonstersChooseBetView:setUI(_tag)
    for i=1,#self.m_itemTab do
        if i == _tag then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_betView_select)
            util_changeNodeParent(self:findChild("Node_new_reel"..i), self.m_itemTab[i])
            self.m_itemTab[i]:runCsbAction("actionframe", false, function()
                self.m_itemTab[i]:runCsbAction("idle2", true)
                self:hideView(function()
                    util_changeNodeParent(self:findChild("Node_reel_"..i), self.m_itemTab[i])
                    self.m_machine:chooseBetLevel(_tag)
                    self.m_machine.m_controlBetView:playChangeEffect()
                    if not self.m_machine.m_kuangParticle[1]:isVisible() then
                        self.m_machine:showKuangLines(true)
                    end
                end)
            end)
        else
            self.m_itemTab[i]:runCsbAction("darkstart", false, function()
                self.m_itemTab[i]:runCsbAction("darkidle", true)
            end)
        end
    end
end

function CatchMonstersChooseBetView:hideView(callBack)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_betView_over)
    self:runCsbAction("over", false, function()
        if callBack then
            callBack()
        else
            self.m_machine:setSpinTounchType(true)
        end
        self:setVisible(false)
    end)
end
 
function CatchMonstersChooseBetView:showView(_iBetLevel)
    if self.m_isCanOpen then
        return
    end
    self.m_isCanOpen = true
    self:setVisible(true)
    self:initcoins()
    self:playItemYaAnEffect()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_betView_start)
    self:runCsbAction("start", false, function()
        self.m_canClick = true
        self.m_isCanOpen = false
        self:playIdle()
    end)
end

function CatchMonstersChooseBetView:initcoins()
    for index = 1, self.m_col do
        local lable = self.m_coinLabel[index]
        local strCoins = self.m_machine:getBetLevelCoins(index)
        local strCoins = util_formatCoins(strCoins, 3)
        lable:findChild("m_lb_coins"):setString(strCoins)
        local node = lable:findChild("m_lb_coins")
        lable:updateLabelSize({label = node, sx = 1, sy = 1}, 106)
    end
end

function CatchMonstersChooseBetView:playIdle()
    self:runCsbAction("idle", true)
end

function CatchMonstersChooseBetView:playItemYaAnEffect()
    for index = 1, #self.m_itemTab do
        self.m_itemTab[index]:runCsbAction("idle", true)
    end
end

return CatchMonstersChooseBetView