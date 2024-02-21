---
--xcyy
--2018年5月23日
--CollectWildEffect.lua

local CollectWildEffect = class("CollectWildEffect",util_require("base.BaseView"))


function CollectWildEffect:initUI(_data)
    self.m_machine  = _data[1]
    -- self.m_initData = _data

    self:createCsbNode("AZTEC/CollectWildEffect.csb")

    self:runCsbAction("idle") -- 播放时间线
    --金币堆
    self:initGoodData()
    self:createGoodEffect()
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

function CollectWildEffect:runIdle()
    self:runCsbAction("idle")
end

function CollectWildEffect:onEnter()
 

end

function CollectWildEffect:collectNormal(func)
    self:runCsbAction("animation1", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function CollectWildEffect:collectSpecial(func)
    self:runCsbAction("animation0", false, function()
        if func ~= nil then
            func()
        end
        self:runCsbAction("doudong")
    end)
end

function CollectWildEffect:collectCompleted()
    gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_pyramid_coin.mp3")
    self:runCsbAction("animation2")
end

function CollectWildEffect:fsAnimation()
    -- self:runCsbAction("animation3", true)
end

function CollectWildEffect:onExit()
 
end

--默认按钮监听回调
function CollectWildEffect:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

--[[
    金币堆相关
]]
function CollectWildEffect:createGoodEffect()
    local goodParent = self.m_machine.m_gameBg:findChild("Node_good")
    self.m_goodEffect = util_createAnimation("AZTEC_jinbi123.csb") 
    goodParent:addChild(self.m_goodEffect)
    self.m_goodEffect:setPositionX(10)

    self:upDateGoodPosAndScale()
    self:upDateGoodIdleframe()
end
function CollectWildEffect:upDateGoodPosAndScale()
    -- local machineRootScale = self.m_machine.m_machineRootScale
    local scale = self:getScale()
    local offsetY = -40
    local posY = self:getPositionY() + offsetY * scale
    
    self.m_goodEffect:setScale(scale)
    self.m_goodEffect:setPositionY(posY)
end
function CollectWildEffect:initGoodData()
    self.m_goodData = {
        level = 1,        --金币堆等阶
    }
end
function CollectWildEffect:setGoodData(_data)
    for k,v in pairs(_data) do
        self.m_goodData[k] = v 
    end
end
function CollectWildEffect:getGoodLevel()
   return  self.m_goodData.level
end

function CollectWildEffect:playGoodCollectAnim(_level, _playDoudong, _fun)
    local curLv = self:getGoodLevel()
    local nextlv = _level
    local isReset = nextlv < curLv

    local collectName = "collect"
    if curLv > 1 then
        collectName = string.format("collect%d", curLv-1)
    end
    --下一步
    local nextFun = function()
        
        if _playDoudong then
            self:runCsbAction("doudong")
        end
        
        if _fun then
            _fun()
        end

        --重置状态时需要延时到过场动画后
        if not isReset then
            local data = {level = _level}
            self:setGoodData(data)
            self:upDateGoodIdleframe()
        else
            self:upDateGoodIdleframe()
        end
        
    end

    -- 收集 + 升阶
    if nextlv > curLv then
        local actionName = "actionframe"
        if curLv > 1 then
            actionName = string.format("actionframe%d", curLv-1)
        end
        self.m_goodEffect:runCsbAction(collectName, false, function()
            self.m_goodEffect:runCsbAction(actionName, false, function()
                nextFun()
            end)
        end)
    --普通收集
    else
        self.m_goodEffect:runCsbAction(collectName, false, function()
            nextFun()
        end)
    end

    
end
function CollectWildEffect:upDateGoodIdleframe()
    local level = self:getGoodLevel()

    local idleName = "idleframe"
    if level > 1 then
        idleName = string.format("idleframe%d", level-1)
    end

    self.m_goodEffect:runCsbAction(idleName, true)
end

function CollectWildEffect:getGoodFlyEndPos()
    local worldPos = self.m_goodEffect:getParent():convertToWorldSpace(cc.p(self.m_goodEffect:getPosition()))
    return worldPos
end
return CollectWildEffect