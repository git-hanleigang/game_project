---
--xcyy
--2018年5月23日
--BankCrazeBonusMoreView.lua
local PublicConfig = require "BankCrazePublicConfig"
local BankCrazeBonusMoreView = class("BankCrazeBonusMoreView",util_require("Levels.BaseLevelDialog"))

function BankCrazeBonusMoreView:initUI(params)

    -- 是否为金钱袋
    self.m_isGold = params.isGold
    self.m_machine = params.machine
    self.m_endFunc = params.func
    self.m_hideCallFunc = params.hideCallFunc

    self:createCsbNode("BankCraze/BonusGrowthTanban.csb")
    
    -- 光
    local lightAni = util_createAnimation("BankCraze_tanban_guang.csb")
    self:findChild("Node_guang"):addChild(lightAni)
    lightAni:runCsbAction("idle", true)

    -- 金银行
    if self.m_isGold then
        self.m_roleSpine = util_spineCreate("Socre_BankCraze_9",true,true)
    else
        self.m_roleSpine = util_spineCreate("Socre_BankCraze_8",true,true)
    end
    self:findChild("Node_spine"):addChild(self.m_roleSpine)

    self:findChild("Gold"):setVisible(self.m_isGold)
    self:findChild("Silver"):setVisible(not self.m_isGold)
    
    util_spinePlay(self.m_roleSpine, "auto", false)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:showView()

    util_setCascadeOpacityEnabledRescursion(self, true)
end

--[[
    显示界面
]]
function BankCrazeBonusMoreView:showView(winCoin)
    performWithDelay(self.m_scWaitNode, function()
        if type(self.m_hideCallFunc) == "function" then
            self.m_hideCallFunc()
        end
    end, 150/60)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_Show_MoreDialog)
    self:runCsbAction("auto",false,function()
        self.m_machine:showBonusBtnAndTips()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end
        self:removeFromParent()
    end)
end

return BankCrazeBonusMoreView
