---
--xcyy
--2018年5月23日
--CleosCoffersColorfulItem.lua
local PublicConfig = require "CleosCoffersPublicConfig"
local CleosCoffersColorfulItem = class("CleosCoffersColorfulItem",util_require("base.BaseView"))


function CleosCoffersColorfulItem:initUI(params)
    self.m_parentView = params.parentView
    self.m_itemID = params.itemID     --索引ID
    self:setClickedState(false)

    self:createCsbNode("CleosCoffers_dfdc_choose.csb")

    self.m_pickSpine = util_spineCreate("Socre_CleosCoffers_Pick",true,true)
    self:findChild("Node_spine"):addChild(self.m_pickSpine)
    util_spinePlay(self.m_pickSpine, "idleframe2", true)
    
    self.m_curRewardType = ""   --当前奖励类型
    self.m_curAniName = ""  --当前时间线

    self:addClick(self:findChild("Panel_click"))
end

--[[
    设置具体的jackpot显示
]]
function CleosCoffersColorfulItem:setJackpotTypeShow(rewardType)
    self.m_curRewardType = rewardType
end

--[[
    重置显示及状态
]]
function CleosCoffersColorfulItem:resetStatus()
    --重置层级
    self:getParent():setLocalZOrder(self.m_itemID)
    self:setClickedState(false)
    self.m_curRewardType = ""
    self.m_curAniName = ""
    
    self:runUnClickIdleAni()

    --设置默认显示
    self:setJackpotTypeShow("default")
end

--[[
    未打开状态idle
]]
function CleosCoffersColorfulItem:runUnClickIdleAni()
    util_spinePlay(self.m_pickSpine, "idleframe2", true)
end

--[[
    打开状态idle
]]
function CleosCoffersColorfulItem:runClickedIdleAni(_callFunc)
    local callFunc = _callFunc
    local isBoost = false
    local actSpineName = "pick_mini"
    if self.m_curRewardType == "grand" then
        actSpineName = "pick_grand"
    elseif self.m_curRewardType == "mega" then
        actSpineName = "pick_mega"
    elseif self.m_curRewardType == "major" then
        actSpineName = "pick_major"
    elseif self.m_curRewardType == "minor" then
        actSpineName = "pick_minor"
    elseif self.m_curRewardType == "mini" then
        actSpineName = "pick_mini"
    elseif self.m_curRewardType == "buff_boost" then
        actSpineName = "pick_boost"
        isBoost = true
    elseif self.m_curRewardType == "buff_mega" then
        actSpineName = "pick_megaboost"
        isBoost = true
    elseif self.m_curRewardType == "buff_super" then
        actSpineName = "pick_superboost"
        isBoost = true
    end

    util_spinePlay(self.m_pickSpine, actSpineName, false)
    util_spineEndCallFunc(self.m_pickSpine, actSpineName, function()
        if isBoost then
            if type(callFunc) == "function" then
                callFunc()
            end
            self:playBuffAction(callFunc)
        else
            self:showCollectAct(callFunc)
        end
    end)
end

-- 播放收集特效
function CleosCoffersColorfulItem:showCollectAct(_callFunc)
    local callFunc = _callFunc
    local actSpineName = "shouji_mini"
    if self.m_curRewardType == "grand" then
        actSpineName = "shouji_grand"
    elseif self.m_curRewardType == "mega" then
        actSpineName = "shouji_mega"
    elseif self.m_curRewardType == "major" then
        actSpineName = "shouji_major"
    elseif self.m_curRewardType == "minor" then
        actSpineName = "shouji_minor"
    elseif self.m_curRewardType == "mini" then
        actSpineName = "shouji_mini"
    end
    util_spinePlay(self.m_pickSpine, actSpineName, false)
    if type(callFunc) == "function" then
        callFunc()
    end
end

-- 翻出boost；播放buff特效
function CleosCoffersColorfulItem:playBuffAction()
    local actSpineName = "actionframe_boost"
    local idleSpineName = "idleframe_boost"
    if self.m_curRewardType == "buff_boost" then
        actSpineName = "actionframe_boost"
        idleSpineName = "idleframe_boost"
    elseif self.m_curRewardType == "buff_mega" then
        actSpineName = "actionframe_megaboost"
        idleSpineName = "idleframe_megaboost"
    elseif self.m_curRewardType == "buff_super" then
        actSpineName = "actionframe_superboost"
        idleSpineName = "idleframe_superboost"
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Pick_Trigger_Boost)
    util_spinePlay(self.m_pickSpine, actSpineName, false)
    util_spineEndCallFunc(self.m_pickSpine, actSpineName, function()
        util_spinePlay(self.m_pickSpine, idleSpineName, true)
        self.m_parentView:addJackpotReward(self.m_itemID)
    end)
end

--[[
    晃动idle
]]
function CleosCoffersColorfulItem:runShakeAni(func)
    util_spinePlay(self.m_pickSpine, "idleframe", false)
end

--[[
    压黑动画
]]
function CleosCoffersColorfulItem:runDarkAni()
    local actSpineName = "darkstart_mini"
    local idleSpineName = "darkidle_mini"
    if self.m_curRewardType == "grand" then
        actSpineName = "darkstart_grand"
        idleSpineName = "darkidle_grand"
    elseif self.m_curRewardType == "mega" then
        actSpineName = "darkstart_mega"
        idleSpineName = "darkidle_mega"
    elseif self.m_curRewardType == "major" then
        actSpineName = "darkstart_major"
        idleSpineName = "darkidle_major"
    elseif self.m_curRewardType == "minor" then
        actSpineName = "darkstart_minor"
        idleSpineName = "darkidle_minor"
    elseif self.m_curRewardType == "mini" then
        actSpineName = "darkstart_mini"
        idleSpineName = "darkidle_mini"
    elseif self.m_curRewardType == "buff_boost" then
        actSpineName = "darkstart_boost"
        idleSpineName = "darkidle_boost"
    elseif self.m_curRewardType == "buff_mega" then
        actSpineName = "darkstart_megaboost"
        idleSpineName = "darkidle_megaboost"
    elseif self.m_curRewardType == "buff_super" then
        actSpineName = "darkstart_superboost"
        idleSpineName = "darkidle_superboost"
    end

    util_spinePlay(self.m_pickSpine, actSpineName, false)
    util_spineEndCallFunc(self.m_pickSpine, actSpineName, function()
        util_spinePlay(self.m_pickSpine, idleSpineName, true)
    end)
end

--[[
    显示奖励
]]
function CleosCoffersColorfulItem:showRewardAni(rewardType, _func)
    local callFunc = _func
    self:setJackpotTypeShow(rewardType)
    self:runClickedIdleAni(callFunc)
end

--[[
    显示中奖动效
]]
function CleosCoffersColorfulItem:getRewardAni(func)
    --中奖时对应的节点提到最上层
    self:getParent():setLocalZOrder(100 + self.m_itemID)

    local actSpineName = "actionframe_mini"
    if self.m_curRewardType == "grand" then
        actSpineName = "actionframe_grand"
    elseif self.m_curRewardType == "mega" then
        actSpineName = "actionframe_mega"
    elseif self.m_curRewardType == "major" then
        actSpineName = "actionframe_major"
    elseif self.m_curRewardType == "minor" then
        actSpineName = "actionframe_minor"
    elseif self.m_curRewardType == "mini" then
        actSpineName = "actionframe_mini"
    elseif self.m_curRewardType == "buff_boost" then
        actSpineName = "actionframe_boost"
    elseif self.m_curRewardType == "buff_mega" then
        actSpineName = "actionframe_megaboost"
    elseif self.m_curRewardType == "buff_super" then
        actSpineName = "actionframe_superboost"
    end

    -- jackpot_cf（0，60）
    util_spinePlay(self.m_pickSpine, actSpineName, false)
end

--[[
    默认按钮监听回调
]]
function CleosCoffersColorfulItem:clickFunc(sender)
    --点击屏蔽
    if self:getClickedState() or self.m_parentView.m_isEnd or self.m_parentView.m_isBuffClick then
        return
    end

    self:setClickedState(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_ClickPick_FeedBack)

    --点击道具回调
    self.m_parentView:clickItem(self)
end

--[[
    执行动画
]]
function CleosCoffersColorfulItem:runAnim(aniName,loop,func)
    if not loop then
        loop = false
    end
    self.m_curAniName = aniName
    self:runCsbAction(aniName,loop,func)
    -- 若为spine动画用下面的逻辑
    -- util_spinePlay(self.m_spine,aniName,loop)
    -- if type(func) == "function" then
    --     util_spineEndCallFunc(self.m_spine,aniName,function()
    --         func()
    --     end)
    -- end
end

-- 按钮状态
function CleosCoffersColorfulItem:setClickedState(_state)
    self.m_isClicked = _state
end

-- 按钮状态
function CleosCoffersColorfulItem:getClickedState()
    return self.m_isClicked
end

--[[
    判定是否为相同类型
]]
function CleosCoffersColorfulItem:isSameType(rewardType)
    if rewardType == self.m_curRewardType then
        return true
    end

    return false
end

return CleosCoffersColorfulItem