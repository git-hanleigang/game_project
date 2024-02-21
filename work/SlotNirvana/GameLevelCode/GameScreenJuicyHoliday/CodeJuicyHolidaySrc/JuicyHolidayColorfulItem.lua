---
--xcyy
--2018年5月23日
--JuicyHolidayColorfulItem.lua
local PublicConfig = require "JuicyHolidayPublicConfig"
local JuicyHolidayColorfulItem = class("JuicyHolidayColorfulItem",util_require("base.BaseView"))

local JACKPOT_COLOR = {
    grand = "red",
    major = "violet",
    minor = "bule",
    mini = "green"
}

function JuicyHolidayColorfulItem:initUI(params)
    self.m_parentView = params.parentView
    self.m_itemID = params.itemID     --索引ID
    self.m_isClicked = false    --是否已经点击

    self.m_spine = util_spineCreate("JuicyHoliday_beizi",true,true)
    self:addChild(self.m_spine)
    

    self.m_curRewardType = ""   --当前奖励类型
    self.m_curAniName = ""  --当前时间线
    self.m_isDark = false

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(120,200))
    layout:setTouchEnabled(true)
    self:addClick(layout)

    -- layout:setBackGroundColor(cc.c3b(255, 0, 0))
    -- layout:setBackGroundColorOpacity(255)
    -- layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

--[[
    设置具体的jackpot显示
]]
function JuicyHolidayColorfulItem:setJackpotTypeShow(rewardType)
    self.m_curRewardType = rewardType
end

--[[
    未点击的位置压黑
]]
function JuicyHolidayColorfulItem:runUnClickDarkAni(rewardType)
    if self.m_isDark then
        return
    end
    
    self:setJackpotTypeShow(rewardType)

    local aniName = "actionframe_fk_"..JACKPOT_COLOR[rewardType]

    self:runAnim(aniName)
    local aniTime = self.m_spine:getAnimationDurationTime(aniName)
    return aniTime
end

--[[
    重置显示及状态
]]
function JuicyHolidayColorfulItem:resetStatus()
    --重置层级
    local parent = self:getParent()
    if not tolua.isnull(parent) then
        parent:setLocalZOrder(self.m_itemID)
    end
    
    self.m_isClicked = false 
    self.m_curRewardType = ""
    self.m_curAniName = ""
    self.m_isDark = false
    
    self:runUnClickIdleAni()
end

--[[
    未打开状态idle
]]
function JuicyHolidayColorfulItem:runUnClickIdleAni()
    self:runAnim("idle",true)
end

--[[
    打开状态idle
]]
function JuicyHolidayColorfulItem:runClickedIdleAni()
    local aniName = "idleframe2_"..JACKPOT_COLOR[self.m_curRewardType]
    self:runAnim(aniName,true)
end

--[[
    期待idle
]]
function JuicyHolidayColorfulItem:runNoticeIdle()
    if self.m_curAniName == "idleframe3_"..JACKPOT_COLOR[self.m_curRewardType] or self.m_curAniName == "actionframe_dao_"..JACKPOT_COLOR[self.m_curRewardType] then
        return
    end
    local aniName = "idleframe3_"..JACKPOT_COLOR[self.m_curRewardType]
    self:runAnim(aniName,true)
end

--[[
    晃动idle
]]
function JuicyHolidayColorfulItem:runShakeAni(func)
    self:runAnim("idle",false,function()
        self:runUnClickIdleAni()
    end)
end

--[[
    压黑动画
]]
function JuicyHolidayColorfulItem:runDarkAni()
    if self.m_isDark then
        return
    end
    self.m_isDark = true
    local aniName = "idleframe_no_"..JACKPOT_COLOR[self.m_curRewardType]
    self:runAnim(aniName)
end

--[[
    显示奖励
]]
function JuicyHolidayColorfulItem:showRewardAni(rewardType,isNotice,func)
    self:setJackpotTypeShow(rewardType)
    local aniName = "actionframe_dao_"..JACKPOT_COLOR[self.m_curRewardType]
    self:runAnim(aniName,false,function ()
        if self.m_parentView.m_left_item_counts[rewardType] == 1 then
            self.m_curAniName = ""
            self:runNoticeIdle()
        else
            self:runClickedIdleAni()
        end
        -- self:runClickedIdleAni()
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
function JuicyHolidayColorfulItem:getRewardAni(func)
    --中奖时对应的节点提到最上层
    local parent = self:getParent()
    if not tolua.isnull(parent) then
        parent:setLocalZOrder(100 + self.m_itemID)
    end
    
    local aniName = "actionframe_"..JACKPOT_COLOR[self.m_curRewardType]
    self:runAnim(aniName,false,function()
        self:runClickedIdleAni()
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
function JuicyHolidayColorfulItem:clickFunc(sender)
    --点击屏蔽
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
function JuicyHolidayColorfulItem:runAnim(aniName,loop,func)
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
function JuicyHolidayColorfulItem:isSameType(rewardType)
    if rewardType == self.m_curRewardType then
        return true
    end

    return false
end

--[[
    切换idle
]]
function JuicyHolidayColorfulItem:changeIdle()
    if self.m_curAniName == "idleframe3_"..JACKPOT_COLOR[self.m_curRewardType] then
        self:runClickedIdleAni()
    end
end

return JuicyHolidayColorfulItem