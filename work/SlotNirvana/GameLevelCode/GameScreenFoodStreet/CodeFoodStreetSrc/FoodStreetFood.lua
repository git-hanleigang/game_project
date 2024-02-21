---
--xcyy
--2018年5月23日
--FoodStreetFood.lua

local FoodStreetFood = class("FoodStreetFood",util_require("base.BaseView"))


function FoodStreetFood:initUI(data)

    self:createCsbNode("FoodStreet_map_food_"..data..".csb")

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

    self.m_effect = util_createView("CodeFoodStreetSrc.FoodStreetMapIconEffect")
    self:findChild("saoguang"):addChild(self.m_effect)
    self.m_effect:setVisible(false)

    self.m_btnEffect = util_createView("CodeFoodStreetSrc.FoodStreetBtnEffect")
    self:findChild("saoguang"):addChild(self.m_btnEffect)
    self.m_btnEffect:setVisible(false)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function FoodStreetFood:setFoodInfo(index, groupID)
    self.m_index = index
    self.m_group = groupID
    self.m_type = "FOOD"
end

function FoodStreetFood:setTouchFlag(flag)
    self.m_clickFlag = flag
    self.m_btnEffect:setVisible(flag)
end

function FoodStreetFood:getTouchFlag()
    return self.m_clickFlag
end

function FoodStreetFood:showEffect()
    self.m_effect:setVisible(true)
end

function FoodStreetFood:hideEffect()
    self.m_effect:setVisible(false)
end

function FoodStreetFood:onEnter()

end

function FoodStreetFood:onExit()
 
end

--默认按钮监听回调
function FoodStreetFood:clickFunc(sender)
    if self.m_clickFlag == false  then
        return
    end
    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_choose.mp3")
    local name = sender:getName()
    local tag = sender:getTag()

    local info = {}
    info.index = self.m_index
    info.group = self.m_group
    info.type =  self.m_type
    local layer = util_createView("CodeFoodStreetSrc.FoodStreetChooseLayer", info)
    gLobalViewManager:showUI(layer)
end


return FoodStreetFood