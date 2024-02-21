---
--xcyy
--2018年5月23日
--GirlsMagicCredits.lua

local GirlsMagicCredits = class("GirlsMagicCredits",util_require("base.BaseView"))


function GirlsMagicCredits:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("GirlsMagic_Credits.csb")

    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_node_tip = self:findChild("Node_Tip")
    
    self.m_tip = util_createAnimation("GirlsMagic_Credits_Tip.csb")
    self.m_node_tip:addChild(self.m_tip)
    if params.isShowTip then
        self:showTip()
    else
        self.m_tip:setVisible(false)
    end
    

    self.m_isWaitting = false
end


function GirlsMagicCredits:onEnter()
    self:refreshScore()
end


function GirlsMagicCredits:onExit()
 
end

--[[
    显示提示框
]]
function GirlsMagicCredits:showTip()
    self.m_tip:setVisible(true)
    self.m_tip:runCsbAction("show",false,function()
        self.m_tip:runCsbAction("idle")
        self.m_isWaitting = false
    end)

    performWithDelay(self,function(  )
        self:hideTip()
    end,5)
end

--[[
    隐藏提示框
]]
function GirlsMagicCredits:hideTip()
    if not self.m_tip:isVisible() then
        return
    end

    self.m_tip:runCsbAction("over",false,function()
        self.m_tip:setVisible(false)
        self.m_isWaitting = false
    end)
end

--默认按钮监听回调
function GirlsMagicCredits:clickFunc(sender)
    --防止连续点击
    if self.m_isWaitting then
        return
    end

    if self.m_tip:isVisible() then
        self:hideTip()
    else
        self:showTip()
    end

    self.m_isWaitting = true
end

--[[
    刷新分数
]]
function GirlsMagicCredits:refreshScore()
    local roomData = self.m_machine.m_roomData:getRoomData()
    local score = 1 
    if roomData and roomData.result then
        score = roomData.result.data.userScore[globalData.userRunData.userUdid] or 1
    elseif roomData and roomData.extra then
        score = roomData.extra.score or 1
    end
    if score < 1 then
        score = 1 
    end
    self.m_lb_coins:setString(util_formatCoins(score, 4))
    local info={label = self.m_lb_coins,sx = 1,sy = 1}
    self:updateLabelSize(info,190)
end


return GirlsMagicCredits