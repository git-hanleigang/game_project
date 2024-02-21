---
--xcyy
--2018年5月23日
--JackpotElvesColorfulItem.lua

local JackpotElvesColorfulItem = class("JackpotElvesColorfulItem",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "JackpotElvesPublicConfig"
local JACKPOT_TYPE = {
    "epic",
    "grand",
    "ultra",
    "mega",
    "major",
    "minor",
    "mini"
}

function JackpotElvesColorfulItem:initUI(params)
    self.m_index = params.index
    self.m_parentView = params.parent
    self.m_itemType = params.type
    self.m_isClicked = false
    self.m_isDarkStatus = false
    self:createCsbNode("JackpotElves_jackpot_gift_"..self.m_itemType..".csb")

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(150,100))
    layout:setTouchEnabled(true)
    self:addClick(layout)

    self.m_spineGift = util_spineCreate("JackpotElves_jackpot_gift", true, true)
    self.m_spineGift:setSkin(self.m_itemType)
    self:addChild(self.m_spineGift)

end

--[[
    刷新显示
]]
function JackpotElvesColorfulItem:updateUI(uiType, jackpotType)

    self:findChild("Node_jackpot"):setVisible(uiType == "jackpot")
    self:findChild("Node_buff"):setVisible(uiType == "buff")
    if jackpotType then
        for i,targetType in ipairs(JACKPOT_TYPE) do
            self:findChild("Node_"..targetType):setVisible(jackpotType == targetType)
            self:findChild(targetType):setVisible(jackpotType == targetType)
        end
    end
    
end

--[[
    重置状态
]]
function JackpotElvesColorfulItem:resetStatus()
    self:updateUI()
    self.m_spineGift:setVisible(true)
    self:playSpineAnim(self.m_spineGift, "idle", true)
    self.m_isClicked = false
    self.m_isDarkStatus = false
    if self.m_itemType == "red" then
        self:pauseForIndex(0)
    else
        self:pauseForIndex(200)
    end
    
end
--[[
    提示点击
]]
function JackpotElvesColorfulItem:clickRemindAnim()
    self:playSpineAnim(self.m_spineGift, "dou", false, function()
        self:playSpineAnim(self.m_spineGift, "idle", true)
    end)
end
--[[
    打开礼物盒
]]
function JackpotElvesColorfulItem:openGiftBox(type,func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_BoxFankui)
    self:playSpineAnim(self.m_spineGift, "fankui1", false, function ()
        self.m_spineGift:setVisible(false)
        if func then
            func()
        end
    end)

    self:delayCallBack(10 / 30, function()
        self:runCsbAction("show")
    end)
    self:delayCallBack(10/30 + 10 / 60,function ()
        if type == "table" then
            if self.m_itemType == "red" then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_redClickJackpot)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_lvClickJackpot)
            end
        end
    end)
end
--[[
    中奖动画
]]
function JackpotElvesColorfulItem:jackptRewardAnim(isLoop)
    
    self:runCsbAction("actionframe2", isLoop ~= true)
end
--[[
    压黑动画
]]
function JackpotElvesColorfulItem:giftBoxDarkAnim(func)
    if self.m_isDarkStatus then
        return
    end
    self.m_isDarkStatus = true
    self.m_isClicked = true
    self:runCsbAction("dark1", false, function ()
        if func ~= nil then
            func()
        end
    end)
    self:playSpineAnim(self.m_spineGift, "over", false, function()
        self.m_spineGift:setVisible(false)
    end)
end

function JackpotElvesColorfulItem:jackpotDarkAnim(func)
    if self.m_isDarkStatus then
        return
    end
    self.m_isDarkStatus = true
    self:runCsbAction("dark", false, function()
        if func then
            func()
        end
    end)
end

function JackpotElvesColorfulItem:buffTrrigerDarkAnim(func)
    if self.m_isDarkStatus then
        return
    end
    self.m_isDarkStatus = true
    self.m_isClicked = true
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_triggerJackpotBoxOpen)
    self:playSpineAnim(self.m_spineGift, "fankui1", false, function ()
        self.m_spineGift:setVisible(false)
        if func then
            func()
        end
    end)
    self:delayCallBack(10 / 30, function()
        self:runCsbAction("dark1")
    end)
end

function JackpotElvesColorfulItem:runIdleAnim()
    self:runCsbAction("idle")
end

--[[
    星星显示jackpot
]]
function JackpotElvesColorfulItem:starChangeJackpot()
    self:runCsbAction("bian")
end

--默认按钮监听回调
function JackpotElvesColorfulItem:clickFunc(sender)
    if self.m_isClicked or self.m_parentView.m_isClicked then
        return
    end
    self.m_isClicked = true
    self.m_parentView:clickItem(self.m_index)

end

--[[
    spine 动画
]]
function JackpotElvesColorfulItem:playSpineAnim(spNode, animName, isLoop, func)
    util_spinePlay(spNode, animName, isLoop == true)
    if func ~= nil then
        util_spineEndCallFunc(spNode, animName, function()
            func()
        end)
    end
end

--[[
    延迟回调
]]
function JackpotElvesColorfulItem:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return JackpotElvesColorfulItem