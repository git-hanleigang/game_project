---
--xcyy
--2018年5月23日
--FrozenJewelryCollectBar.lua

local FrozenJewelryCollectBar = class("FrozenJewelryCollectBar",util_require("Levels.BaseLevelDialog"))


function FrozenJewelryCollectBar:initUI()
    self.m_status = 1
    -- self:createCsbNode("FrozenJewelry_Box.csb")
    self.m_spine = util_spineCreate("FrozenJewelry_Box",true,true)
    self:addChild(self.m_spine)
end

--[[
    变更状态
]]
function FrozenJewelryCollectBar:changeStatus(status,func)
    if status ~= self.m_status then
        self.m_status = status
        if status == 1 then
            self:playSpineAni(self.m_spine,"switch3",false,function()
                self:playSpineAni(self.m_spine,"idleframe",true)
                if type(func) == "function" then
                    func()
                end
            end)
        elseif status == 2 then
            self:playSpineAni(self.m_spine,"switch",false,function()
                self:playSpineAni(self.m_spine,"idleframe2",true)
                if type(func) == "function" then
                    func()
                end
            end)
        else
            self:playSpineAni(self.m_spine,"switch2",false,function()
                self:playSpineAni(self.m_spine,"idleframe3",true)
                if type(func) == "function" then
                    func()
                end
            end)
        end
    end
end

--[[
    设置当前状态
]]
function FrozenJewelryCollectBar:setStatus(status)
    if status == 1 then
        self:playSpineAni(self.m_spine,"idleframe",true)
    elseif status == 2 then
        self:playSpineAni(self.m_spine,"idleframe2",true)
    else
        self:playSpineAni(self.m_spine,"idleframe3",true)
    end
    self.m_status = status
end

--[[
    收集动画
]]
function FrozenJewelryCollectBar:collectAni(status,func)
    if status ~= self.m_status then
        self:changeStatus(status,func)
        return
    end
    if self.m_status == 1 then
        self:playSpineAni(self.m_spine,"shouji",false,function()
            self:playSpineAni(self.m_spine,"idleframe",true)
            if type(func) == "function" then
                func()
            end
        end)
    elseif self.m_status == 2 then
        self:playSpineAni(self.m_spine,"shouji2",false,function()
            self:playSpineAni(self.m_spine,"idleframe2",true)
            if type(func) == "function" then
                func()
            end
        end)
    else
        self:playSpineAni(self.m_spine,"shouji3",false,function()
            self:playSpineAni(self.m_spine,"idleframe3",true)
            if type(func) == "function" then
                func()
            end
        end)
    end
end

function FrozenJewelryCollectBar:playSpineAni(spine,key,loop,func,frameKey,keyFunc)
    util_spinePlay(spine,key,loop)
    
    if keyFunc then
        util_spineFrameCallFunc(spine,key,frameKey,keyFunc,func)
    else
        util_spineEndCallFunc(spine,key,func)
    end
end

function FrozenJewelryCollectBar:getStatus()
    return self.m_status
end

function FrozenJewelryCollectBar:changeSceneAni(func,keyFunc)
    self:playSpineAni(self.m_spine,"actionframe3",false,function()
        self:playSpineAni(self.m_spine,"guochang3",false,func,"show",keyFunc)
    end)
end

return FrozenJewelryCollectBar