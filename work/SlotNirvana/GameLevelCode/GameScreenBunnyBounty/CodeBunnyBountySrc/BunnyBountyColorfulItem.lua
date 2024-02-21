---
--xcyy
--2018年5月23日
--BunnyBountyColorfulItem.lua
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyColorfulItem = class("BunnyBountyColorfulItem",util_require("base.BaseView"))


function BunnyBountyColorfulItem:initUI(params)
    self.m_parentView = params.parentView
    self.m_itemID = params.itemID     --索引ID
    self.m_isClicked = false    --是否已经点击

    self.m_spine = util_spineCreate("Socre_BunnyBounty_Bonus2",true,true)
    self:addChild(self.m_spine)

    self.m_curRewardType = ""   --当前奖励类型
    self.m_curAniName = ""  --当前时间线

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(200,200))
    layout:setTouchEnabled(true)
    self:addClick(layout)
end

--[[
    重置显示及状态
]]
function BunnyBountyColorfulItem:resetStatus()
    self:getParent():setLocalZOrder(self.m_itemID)
    self.m_isClicked = false 
    self.m_curRewardType = ""
    self.m_curAniName = ""
    self.m_spine:setSkin("common")
    self:runUnClickIdleAni()
end

--[[
    未打开状态idle
]]
function BunnyBountyColorfulItem:runUnClickIdleAni()
    self:runAnim("idleframe_jackpot",true)
end

--[[
    打开状态idle
]]
function BunnyBountyColorfulItem:runClickedIdleAni()
    self:runAnim("idleframe_jackpot3",true)
end

--[[
    设置皮肤
]]
function BunnyBountyColorfulItem:setSpineSkin(rewardType)
    if rewardType == "mini" then
        self.m_spine:setSkin("mini")
    elseif rewardType == "minor" then
        self.m_spine:setSkin("minor")
    elseif rewardType == "major" then
        self.m_spine:setSkin("major")
    elseif rewardType == "grand" then
        self.m_spine:setSkin("grand")
    elseif rewardType == "grand2X" then
        self.m_spine:setSkin("grand2X")
    elseif rewardType == "levelup" then
        self.m_spine:setSkin("up")
    end

    self.m_curRewardType = rewardType
end

--[[
    获取下一等级
]]
function BunnyBountyColorfulItem:getNextLevelType()
    if self.m_curRewardType == "mini" then
        return "minor"
    elseif self.m_curRewardType == "minor" then
        return "major"
    elseif self.m_curRewardType == "major" then
        return "grand"
    elseif self.m_curRewardType == "grand" then
        return "grand2X"
    end
end

--[[
    晃动idle
]]
function BunnyBountyColorfulItem:runShakeAni(func)
    util_spineMix(self.m_spine,"idleframe_jackpot","idleframe_jackpot2",0.1)
    self:runAnim("idleframe_jackpot2",true,function()
        self:runUnClickIdleAni()
    end)
end

--[[
    压黑动画
]]
function BunnyBountyColorfulItem:runDarkAni()
    self:runAnim("dark")
end

--[[
    显示奖励
]]
function BunnyBountyColorfulItem:showRewardAni(rewardType,func)
    self:setSpineSkin(rewardType)
    self:runAnim("actionframe_jackpot",false,function ()
        self:runClickedIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示预中奖动效
]]
function BunnyBountyColorfulItem:showPreWinnigIdle()
    if self.m_curRewardType == "mini" or self.m_curRewardType == "minor" or self.m_curRewardType == "major" then
        return
    end
    if self.m_curAniName == "idleframe_jackpot4" or self.m_curAniName == "actionframe_jackpot" then
        return
    end
    self:runAnim("idleframe_jackpot4",true)

end

--[[
    显示中奖动效
]]
function BunnyBountyColorfulItem:getRewardAni(func)
    if self.m_curRewardType == "levelup" then
        self:getParent():setLocalZOrder(50 + self.m_itemID)
    else
        self:getParent():setLocalZOrder(100 + self.m_itemID)
    end
    
    self:runAnim("actionframe_jackpot2",false,function()
        -- if self.m_curRewardType ~= "levelup" then
            
        -- end
        self:runAnim("idleframe_jackpot5",true)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    奖励升级动效
]]
function BunnyBountyColorfulItem:runLevelUpAni(func)
    self:getParent():setLocalZOrder(100 + self.m_itemID)
    local aniName = "up"
    if self.m_curRewardType == "grand" then
        aniName = "up2"
    end
    
    self:runAnim(aniName,false,function()
        local nextLevelType = self:getNextLevelType()
        if nextLevelType then
            self:setSpineSkin(nextLevelType)
            self:runAnim("idleframe_jackpot5",true)
        end
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    默认按钮监听回调
]]
function BunnyBountyColorfulItem:clickFunc(sender)
    if self.m_isClicked or self.m_parentView.m_isEnd then
        return
    end

    self.m_isClicked = true

    --点击道具回调
    self.m_parentView:clickItem(self)
end

--[[
    执行动画
]]
function BunnyBountyColorfulItem:runAnim(aniName,loop,func)
    if not loop then
        loop = false
    end
    self.m_curAniName = aniName
    util_spinePlay(self.m_spine,aniName,loop)
    if type(func) == "function" then
        util_spineEndCallFunc(self.m_spine,aniName,function()
            func()
        end)
    end
end

--[[
    判定是否为相同类型
]]
function BunnyBountyColorfulItem:isSameType(rewardType)
    if rewardType == self.m_curRewardType then
        return true
    end

    return false
end

return BunnyBountyColorfulItem