---
--island
--2018年4月12日
--Christmas2021JackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local Christmas2021JackPotWinView = class("Christmas2021JackPotWinView", util_require("base.BaseView"))
Christmas2021JackPotWinView.m_strNodeName = {"Node_GRAND", "Node_MAJOR", "Node_MINOR", "Node_MINI"}

function Christmas2021JackPotWinView:initUI(_machine)
    self.m_click = false

    local resourceFilename = "Christmas2021/Jackpot.csb"
    self:createCsbNode(resourceFilename)

    -- 男女角色
    self.m_boyNode = util_spineCreate("Socre_Christmas2021_nanhai", true, true)
    self.m_boyNode:setVisible(false)
    self:findChild("Node_nanhai"):addChild(self.m_boyNode)

    self.m_girlNode = util_spineCreate("Socre_Christmas2021_nvhai", true, true)
    self.m_girlNode:setVisible(false)
    self:findChild("Node_nvhai"):addChild(self.m_girlNode)

    self:createGrandShare(_machine)
end

function Christmas2021JackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_jackpotIndex = index

    self:runCsbAction("start",false,function()
        self:runCsbAction("idle")
        globalData.slotRunData:checkViewAutoClick(self,"Button_1")
    end)

    self.m_boyNode:setVisible(true)
    util_spinePlay(self.m_boyNode, "start2", false)
    util_spineEndCallFunc(self.m_boyNode, "start2", function()
        util_spinePlay(self.m_boyNode, "idle2", true)
    end)

    self.m_girlNode:setVisible(true)
    util_spinePlay(self.m_girlNode, "start2", false)
    util_spineEndCallFunc(self.m_girlNode, "start2", function()
        util_spinePlay(self.m_girlNode, "idle2", true)
    end)

    self:showJackPotType(index)

    self.m_callFun = callBackFun
    local labCoin = self:findChild("m_lb_coins_"..index)
    labCoin:setString(coins)
    
    self:updateLabelSize({label=labCoin,sx=0.45,sy=0.45},980)
    self:jumpCoinsFinish()
    
    self.m_bgSoundId =  gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_jackpot_win".. index ..".mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_jackpotIndex)
end

-- 显示对应的jackpot
function Christmas2021JackPotWinView:showJackPotType( index )
    for i,v in ipairs(self.m_strNodeName) do
        local node = self:findChild(v)

        if index == i then
            node:setVisible(true)
        else
            node:setVisible(false)
        end
    end
    
end

function Christmas2021JackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    local name = sender:getName()
    if name == "Button_1" then
        if self.m_click == true then
            return 
        end
        self.m_click = true

        self:jackpotViewOver(function()
            self:runCsbAction("over")
            performWithDelay(self,function()
                if self.m_callFun then
                    self.m_callFun()
                end
                self:removeFromParent()
            end,1)
        end)
    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取
--[[
    自动分享 | 手动分享
]]
function Christmas2021JackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function Christmas2021JackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function Christmas2021JackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function Christmas2021JackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return Christmas2021JackPotWinView