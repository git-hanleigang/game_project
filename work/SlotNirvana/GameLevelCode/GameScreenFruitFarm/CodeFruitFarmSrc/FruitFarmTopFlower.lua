---
--xcyy
--2018年5月23日
--FruitFarmTopFlower.lua

local FruitFarmTopFlower = class("FruitFarmTopFlower",util_require("base.BaseView"))

function FruitFarmTopFlower:initUI()

    self:createCsbNode("FruitFarm_TopFlower.csb")
    self:runCsbAction("idle_dark")
    util_setCascadeOpacityEnabledRescursion(self:findChild("spin1"), true)

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

end


function FruitFarmTopFlower:onEnter()
 

end

function FruitFarmTopFlower:showAdd()
    
end
function FruitFarmTopFlower:onExit()
 
end

--默认按钮监听回调
function FruitFarmTopFlower:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    
end

--点亮
function FruitFarmTopFlower:flowerLightUp(isFree)
    self:runCsbAction("actionframe",false, function(  )
        self:runCsbAction("idle", true)
    end, 60)
    self:findChild("spin1"):setVisible(isFree)
    if isFree then
        self:findChild("spin1"):stopAllActions()
        self:findChild("spin1"):setOpacity(255)
        util_schedule(self:findChild("spin1"), function(  )
            self:findChild("spin1"):runAction(cc.FadeOut:create(0.33))
        end, 0.5)
    end
    gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_flower_light.mp3")
end

--变暗
function FruitFarmTopFlower:flowerDark(  )
    self:runCsbAction("actionframe2",false, function(  )
        self:runCsbAction("idle_dark")
    end, 60)
end

--闪烁
function FruitFarmTopFlower:flowerFlash(  )
    self:runCsbAction("liang",false, function(  )
        self:runCsbAction("idle_dark")
    end, 60)
end

function FruitFarmTopFlower:flowerIdle(isFree)
    self:runCsbAction("idle", true)
    self:findChild("spin1"):setVisible(false)
end

return FruitFarmTopFlower