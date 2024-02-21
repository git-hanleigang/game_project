--[[
    des: 内置链接 粉丝页奖励界面
    author:{author}
    time:2019-07-29 21:45:33
]]

local FanPageReward = class("FanPageReward", util_require("base.BaseView"))

function FanPageReward:initUI(coins)
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    
    self.m_coins = coins

    self:createCsbNode("Option/OptionFanPageReward.csb",isAutoScale)

    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_lb_coins:setString(tostring(util_formatCoins(tonumber(coins), 30)))

end

function FanPageReward:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "Button_collect" then
        self:flyCoins(function()
            self:closeUI()
        end)
    elseif name == "Button_x" then
        self:flyCoins(function()
            self:closeUI()
        end)
    end
end

function FanPageReward:closeUI()
    if self.isClose then
        return
    end
    self.isClose=true
    self:runCsbAction("over",false,function()
        self:removeFromParent(true)
    end,60) 
end


--飞金币
function FanPageReward:flyCoins(callBack)
    local endPos = globalData.flyCoinsEndPos
 
    local startPos = self:findChild("Button_collect"):getParent():convertToWorldSpace(cc.p(self:findChild("Button_collect"):getPosition()))
    local baseCoins = globalData.topUICoinCount 

    gLobalViewManager:pubPlayFlyCoin(startPos,endPos, baseCoins,self.m_coins,function()
          
        if callBack ~= nil then
            callBack()
        end
    end )
end

return FanPageReward