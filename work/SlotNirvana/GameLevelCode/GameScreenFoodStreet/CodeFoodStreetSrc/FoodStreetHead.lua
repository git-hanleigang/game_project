---
--xcyy
--2018年5月23日
--FoodStreetHead.lua

local FoodStreetHead = class("FoodStreetHead",util_require("base.BaseView"))

FoodStreetHead.m_clickFlag = nil
function FoodStreetHead:initUI(data)

    self:createCsbNode("FoodStreet_map_head_"..data..".csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    --  -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    if data ~= 0 then
        self:addClick(self:findChild("clickBtn"))
        self.m_clickFlag = true
    end

    self.m_effect = util_createView("CodeFoodStreetSrc.FoodStreetMapIconEffect")
    self:findChild("saoguang"):addChild(self.m_effect)
    self.m_effect:setVisible(false)

    self.m_btnEffect = util_createView("CodeFoodStreetSrc.FoodStreetBtnEffect")
    self:findChild("saoguang"):addChild(self.m_btnEffect)
    self.m_btnEffect:setVisible(false)
    
    self.m_effect2 = util_createView("CodeFoodStreetSrc.FoodStreetMapIconEffect2")
    self:findChild("saoguang2"):addChild(self.m_effect2)
    self.m_effect2:setVisible(false)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function FoodStreetHead:setHeadInfo(index, groupID)
    self.m_index = index
    self.m_group = groupID
end

function FoodStreetHead:setTouchFlag(flag)
    self.m_clickFlag = flag
    self.m_btnEffect:setVisible(flag)
end

function FoodStreetHead:getTouchFlag()
    return self.m_clickFlag
end

function FoodStreetHead:runStarAnim(index, func)
    self:runCsbAction("star"..index, false, function()
        if func ~= nil then
            func()
        end
    end)
end

function FoodStreetHead:showStarIdle(index)
    self:runCsbAction("idle"..index)
end

function FoodStreetHead:showEffect()
    self.m_effect:setVisible(true)
    self.m_effect2:setVisible(true)
end

function FoodStreetHead:hideEffect()
    self.m_effect:setVisible(false)
    self.m_effect2:setVisible(false)
end

function FoodStreetHead:onEnter()

end

function FoodStreetHead:onExit()
 
end

--默认按钮监听回调
function FoodStreetHead:clickFunc(sender)
    if self.m_clickFlag == false  then
        return
    end
    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_choose.mp3")
    local name = sender:getName()
    local tag = sender:getTag()
    local info = {}
    info.index = self.m_index
    info.group = self.m_group
    local layer = util_createView("CodeFoodStreetSrc.FoodStreetChooseLayer", info)
    gLobalViewManager:showUI(layer)
end


return FoodStreetHead