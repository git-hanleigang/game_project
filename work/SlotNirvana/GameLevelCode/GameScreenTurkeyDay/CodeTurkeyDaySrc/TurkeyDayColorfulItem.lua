---
--xcyy
--2018年5月23日
--TurkeyDayColorfulItem.lua
local PublicConfig = require "TurkeyDayPublicConfig"
local TurkeyDayColorfulItem = class("TurkeyDayColorfulItem",util_require("base.BaseView"))

function TurkeyDayColorfulItem:initUI(params)
    self.m_parentView = params.parentView
    self.m_itemID = params.itemID     --索引ID
    self:setClickedState(false)    --是否已经点击

    self.m_sortIndex = 0

    self.m_pickSpine = util_spineCreate("Socre_TurkeyDay_jackpot",true,true)
    self:addChild(self.m_pickSpine)

    self.m_pickAni = util_createAnimation("TurkeyDay_pick_item.csb")
    util_spinePushBindNode(self.m_pickSpine, "jackpot_guadian1", self.m_pickAni)

    self.m_curRewardType = ""   --当前奖励类型
    self.m_curAniName = ""  --当前时间线

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(140,150))
    layout:setTouchEnabled(true)
    self:addClick(layout)
end

--[[
    设置具体的jackpot显示
]]
function TurkeyDayColorfulItem:setJackpotTypeShow(rewardType)
    self.m_pickAni:findChild("mini"):setVisible(rewardType == "mini")
    self.m_pickAni:findChild("minor"):setVisible(rewardType == "minor")
    self.m_pickAni:findChild("major"):setVisible(rewardType == "major")
    self.m_pickAni:findChild("mega"):setVisible(rewardType == "mega")
    self.m_pickAni:findChild("grand"):setVisible(rewardType == "grand")
    self.m_pickAni:findChild("remove"):setVisible(rewardType == "remove")

    self.m_curRewardType = rewardType
end

--[[
    重置显示及状态
]]
function TurkeyDayColorfulItem:resetStatus()
    --重置层级
    self:getParent():setLocalZOrder(self:getCurZorder())
    self:setClickedState(false)
    self.m_curRewardType = ""
    self.m_curRewardIsJump = false
    self.m_curAniName = ""
    
    self:runUnClickIdleAni()

    --设置默认显示
    self:setJackpotTypeShow("default")
end

function TurkeyDayColorfulItem:getCurZorder()
    if self.m_itemID > 15 then
        return 0
    end
    return self.m_itemID
end

--[[
    未打开状态idle
]]
function TurkeyDayColorfulItem:runUnClickIdleAni()
    util_spinePlay(self.m_pickSpine,"jackpot_idle_dan", true)
end

--[[
    打开状态idle
]]
function TurkeyDayColorfulItem:runClickedIdleAni(_callFunc)
    -- jackpot_pkts（0，25）
    -- jackpot_pkpt（0，25）
    local callFunc = _callFunc
    local actSpineName = "jackpot_pkpt"
    local idleSpineName = "jackpot_idle_huang"
    local skinName = "huang"
    local isRemove = false
    if self.m_curRewardType == "remove" then
        isRemove = true
        actSpineName = "jackpot_pkts"
        idleSpineName = "jackpot_idle_zi"
        skinName = "zi"
    end
    self.m_pickSpine:setSkin(skinName)
    util_spinePlay(self.m_pickSpine,actSpineName, false)
    util_spineEndCallFunc(self.m_pickSpine, actSpineName, function()
        util_spinePlay(self.m_pickSpine,idleSpineName, true)
        if type(callFunc) == "function" then
            callFunc()
        end

        if isRemove then
            self:playBuffAction()
        end
    end)
end

-- 放出remove；播放buff特效
function TurkeyDayColorfulItem:playBuffAction()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_RemovePick_Trigger)
    util_spinePlay(self.m_pickSpine,"jackpot_shijia", false)
    util_spineEndCallFunc(self.m_pickSpine, "jackpot_shijia", function()
        util_spinePlay(self.m_pickSpine,"jackpot_idle_zi", true)
        self.m_parentView:playTurnMinJackpot(self.m_itemID)
    end)
end

--[[
    晃动idle
]]
function TurkeyDayColorfulItem:runShakeAni(func)
    util_spinePlay(self.m_pickSpine,"jackpot_idleframe3", false)
    util_spineEndCallFunc(self.m_pickSpine, "jackpot_idleframe3", function()
        self:runUnClickIdleAni()
    end)
end

--[[
    压黑动画
]]
function TurkeyDayColorfulItem:runDarkAni()
    local actSpineName = "jackpot_yaan_ji"
    local idleSpineName = "jackpot_yaan_ji_idle"
    local skinName = "huang"
    if self.m_curRewardIsJump then
        actSpineName = "jackpot_yaan_dan"
        idleSpineName = "jackpot_yaan_dan_idle"
    end
    if self.m_curRewardType == "remove" then
        skinName = "zi"
    end
    self.m_pickSpine:setSkin(skinName)
    util_spinePlay(self.m_pickSpine,actSpineName, false)
    util_spineEndCallFunc(self.m_pickSpine, actSpineName, function()
        util_spinePlay(self.m_pickSpine,idleSpineName, true)
    end)
end

--[[
    显示奖励
]]
function TurkeyDayColorfulItem:showRewardAni(rewardType, _func)
    local callFunc = _func
    self:setJackpotTypeShow(rewardType)
    self:runClickedIdleAni(callFunc)
end

--[[
    显示中奖动效
]]
function TurkeyDayColorfulItem:getRewardAni(func)
    --中奖时对应的节点提到最上层
    self:getParent():setLocalZOrder(100 + self:getCurZorder())

    -- jackpot_cf（0，60）
    util_spinePlay(self.m_pickSpine,"jackpot_cf", false)
    util_spineEndCallFunc(self.m_pickSpine, "jackpot_cf", function()
        util_spinePlay(self.m_pickSpine,"jackpot_idle_huang", true)
    end)
end

-- 设置排序索引
function TurkeyDayColorfulItem:setSortIndex(_index)
    self.m_sortIndex = _index
end

-- 设置排序索引
function TurkeyDayColorfulItem:getSortIndex(_index)
    self.m_sortIndex = _index
end

--[[
    默认按钮监听回调
]]
function TurkeyDayColorfulItem:clickFunc(sender)
    --点击屏蔽
    if self:getClickedState() or self.m_parentView.m_isEnd or self.m_parentView.m_isRemoveClick then
        return
    end

    self:setClickedState(true)

    --点击道具回调
    self.m_parentView:clickItem(self)
end

-- 按钮状态
function TurkeyDayColorfulItem:setClickedState(_state)
    self.m_isClicked = _state
end

-- 按钮状态
function TurkeyDayColorfulItem:getClickedState()
    return self.m_isClicked
end

-- 跳跃状态
function TurkeyDayColorfulItem:setJumpState(_state)
    self.m_curRewardIsJump = _state
end

--[[
    判定是否为相同类型
]]
function TurkeyDayColorfulItem:isSameType(rewardType)
    if rewardType == self.m_curRewardType then
        return true
    end

    return false
end

-- 小鸡跳走动画
function TurkeyDayColorfulItem:jumpJackpotToBottom(_isPlaySound)
    -- jackpot_tiao_huang_dan（0，70）
    -- jackpot_tiao_zi_dan（0，30）
    local isPlaySound = _isPlaySound
    local actSpineName = "jackpot_tiao_huang_dan"
    local idleSpineName = "jackpot_idle_danke"
    if self.m_curRewardType == "remove" then
        actSpineName = "jackpot_tiao_zi_dan"
    else
        if isPlaySound then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_RemovePick_JackpotTrigger)
        end
    end
    util_spinePlay(self.m_pickSpine,actSpineName, false)
    util_spineEndCallFunc(self.m_pickSpine, actSpineName, function()
        util_spinePlay(self.m_pickSpine,idleSpineName, true)
    end)
end

return TurkeyDayColorfulItem
