local BoostMeTip=class("BoostMeTip",util_require("base.BaseView"))
function BoostMeTip:initUI(type,data,func)
    self.m_func = func
    if type == 1 then
        self:createCsbNode("BoostMe/Node_1.csb")
        self:initView1(data)
    else
        self:createCsbNode("BoostMe/Node_2.csb")
        self:initView2(data)
    end
    self:runCsbAction("show")
    gLobalViewManager:addAutoCloseTips(self,function()
        if self.closeUI then
            self:closeUI()
        end
    end)
end

function BoostMeTip:initView1(data)
    local preLevel = data[1]
    local curLevel = globalData.userRunData.levelNum
    local rewardCoins = 0 -- 升级到下一级奖励金币
    for i = preLevel, curLevel - 1 do    	
        local curData  = globalData.userRunData:getLevelUpRewardInfo(i)  
        if curData and curData.p_coins then
            rewardCoins = rewardCoins + curData.p_coins  -- 升级到下一级奖励金币
        end
    end
    local mulRewardCoins = rewardCoins * 30

    local m_lb_coins = self:findChild("m_lb_coins")
    if m_lb_coins then
        m_lb_coins:setString(rewardCoins)
        self:updateLabelSize({label = m_lb_coins}, 142)
    end

    local m_mulCoins = self:findChild("m_mulCoins")
    if m_mulCoins then
        m_mulCoins:setString(mulRewardCoins)
        self:updateLabelSize({label = m_lb_coins}, 104)
    end

end

function BoostMeTip:initView2()

end

function BoostMeTip:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end

function BoostMeTip:closeUI()
    if self.isCloseUI then
        return
    end
    self.isCloseUI = true
    self:runCsbAction("over",false,function()
        if self.m_func then
            self.m_func()
        end
        self:removeFromParent()
    end)
end

return BoostMeTip