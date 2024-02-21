---
--xcyy
--2018年5月23日
--RobinIsHoodColorfulItem.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local RobinIsHoodColorfulItem = class("RobinIsHoodColorfulItem",util_require("base.BaseView"))


function RobinIsHoodColorfulItem:initUI(params)
    self.m_parentView = params.parentView
    self.m_itemID = params.itemID     --索引ID
    self.m_isClicked = false    --是否已经点击

    self.m_spine = util_spineCreate("Socre_RobinIsHood_pick",true,true)
    self:addChild(self.m_spine)
    

    self.m_curRewardType = ""   --当前奖励类型
    self.m_curAniName = ""  --当前时间线
    self.m_isDark = false

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(120,120))
    layout:setTouchEnabled(true)
    self:addClick(layout)

    -- layout:setBackGroundColor(cc.c3b(255, 0, 0))
    -- layout:setBackGroundColorOpacity(255)
    -- layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

--[[
    设置具体的jackpot显示
]]
function RobinIsHoodColorfulItem:setJackpotTypeShow(rewardType)
    self.m_spine:setSkin(rewardType)

    self.m_curRewardType = rewardType
end

--[[
    未点击的位置压黑
]]
function RobinIsHoodColorfulItem:runUnClickDarkAni(rewardType)
    if self.m_isDark then
        return
    end
    
    self:setJackpotTypeShow(rewardType)
    self:runAnim("dark1")
    local aniTime = self.m_spine:getAnimationDurationTime("dark1")
    return aniTime
end

--[[
    重置显示及状态
]]
function RobinIsHoodColorfulItem:resetStatus()
    --重置层级
    self:setLocalZOrder(self.m_itemID)
    self.m_isClicked = false 
    self.m_curRewardType = ""
    self.m_curAniName = ""
    self.m_isDark = false
    
    self:runUnClickIdleAni()

    --设置默认显示
    self:setJackpotTypeShow("default")
end

--[[
    未打开状态idle
]]
function RobinIsHoodColorfulItem:runUnClickIdleAni()
    self:runAnim("idleframe",true)
end

--[[
    打开状态idle
]]
function RobinIsHoodColorfulItem:runClickedIdleAni()
    self:runAnim("idleframe3",true)
end

--[[
    期待idle
]]
function RobinIsHoodColorfulItem:runNoticeIdle()
    if self.m_curAniName == "actionframe" or self.m_curAniName == "actionframe2" then
        return
    end
    self:runAnim("idleframe4",true)
end

--[[
    晃动idle
]]
function RobinIsHoodColorfulItem:runShakeAni(func)
    self:runAnim("idleframe2",false,function()
        self:runUnClickIdleAni()
    end)
end

--[[
    压黑动画
]]
function RobinIsHoodColorfulItem:runDarkAni()
    if self.m_isDark then
        return
    end
    self.m_isDark = true
    self:runAnim("dark2")
end

--[[
    显示奖励
]]
function RobinIsHoodColorfulItem:showRewardAni(rewardType,isNotice,func)
    self:setJackpotTypeShow(rewardType)
    local aniName = "actionframe"
    if isNotice then
        aniName = "actionframe2"
    end
    self:runAnim(aniName,false,function ()
        -- self.m_curAniName = ""
        -- if self.m_parentView.m_left_item_counts[rewardType] <= 1 then
        --     self:runNoticeIdle()
        -- else
        --     self:runClickedIdleAni()
        -- end

        self:runClickedIdleAni()
        
        
    end)

    local aniTime = self.m_spine:getAnimationDurationTime(aniName)

    performWithDelay(self,function()
        if type(func) == "function" then
            func()
        end
    end,aniTime)
    return aniTime
end

--[[
    显示中奖动效
]]
function RobinIsHoodColorfulItem:getRewardAni(func)
    --中奖时对应的节点提到最上层
    self:setLocalZOrder(100 + self.m_itemID)
    local aniName = "actionframe2_"..self.m_curRewardType
    self:runAnim(aniName,false,function()
        self:runAnim("actionframe2_idle",true)
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_spine:getAnimationDurationTime(aniName)
    return aniTime
end

--[[
    默认按钮监听回调
]]
function RobinIsHoodColorfulItem:clickFunc(sender)
    --点击屏蔽
    if self.m_isClicked or self.m_parentView.m_isEnd or not self.m_parentView.m_clickEnabled then
        return
    end

    self.m_isClicked = true

    --点击道具回调
    self.m_parentView:clickItem(self)
end

--[[
    执行动画
]]
function RobinIsHoodColorfulItem:runAnim(aniName,loop,func)
    if self.m_curAniName == aniName then
        return
    end
    self.m_curAniName = aniName
    if not loop then
        loop = false
    end
    -- 若为spine动画用下面的逻辑
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
function RobinIsHoodColorfulItem:isSameType(rewardType)
    if rewardType == self.m_curRewardType then
        return true
    end

    return false
end

return RobinIsHoodColorfulItem