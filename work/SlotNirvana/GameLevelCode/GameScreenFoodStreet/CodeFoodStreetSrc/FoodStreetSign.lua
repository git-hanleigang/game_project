---
--xcyy
--2018年5月23日
--FoodStreetSign.lua

local FoodStreetSign = class("FoodStreetSign", util_require("base.BaseView"))

function FoodStreetSign:initUI(data)
    self:createCsbNode("FoodStreet_paizi_" .. data .. ".csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听

    -- performWithDelay(节点（必须传入）, function ()
    -- 延时函数
    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
    -- 定时器
    -- xxx 对应定时器调用时间间隔
    -- end,xxxx)

    self:addClick(self:findChild("clickBtn"))
    self.m_clickFlag = true

    self:runCsbAction("idle")

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function FoodStreetSign:setHeadInfo(index, groupID, dogPrice)
    self.m_index = index
    self.m_group = groupID
    self.m_price = dogPrice or 0
end

function FoodStreetSign:setTouchFlag(flag)
    self.m_clickFlag = flag
    if flag == true then
        self:runCsbAction("idle2", true)
    else
        self:runCsbAction("idle")
    end
end

function FoodStreetSign:getTouchFlag()
    return self.m_clickFlag
end

function FoodStreetSign:onEnter()
end

function FoodStreetSign:onExit()
end

--默认按钮监听回调
function FoodStreetSign:clickFunc(sender)
    if self.m_clickFlag == false then
        return
    end
    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_choose.mp3")
    local name = sender:getName()
    local tag = sender:getTag()
    local info = {}
    info.index = self.m_index
    info.group = self.m_group
    info.price = self.m_price
    local layer = util_createView("CodeFoodStreetSrc.FoodStreetChooseLayer", info)
    gLobalViewManager:showUI(layer)
end

return FoodStreetSign
