---
--xcyy
--2018年5月23日
--FrozenJewelryBoxItem.lua

local FrozenJewelryBoxItem = class("FrozenJewelryBoxItem",util_require("Levels.BaseLevelDialog"))

local jackpots = {"grand","major","minor","mini"}

function FrozenJewelryBoxItem:initUI(params)
    self.m_index = params.index
    self.m_parentView = params.parentView

    self:createCsbNode("FrozenJewelry_Pick_Box.csb")

    self.m_jackpotItem = util_createAnimation("FrozenJewelry_Pick_Box_jewelry.csb")
    self:findChild("jewelry"):addChild(self.m_jackpotItem)

    self:resetStatus()

    self:addClick(self:findChild("Panel_1"))

    self.m_isIdle = false
    self.m_isOpen = false
    self.m_jackpotType = nil
end

function FrozenJewelryBoxItem:changeStatus(isOpen)
    self.m_isOpen = isOpen
end

function FrozenJewelryBoxItem:resetStatus()
    self.m_jackpotType = nil
    self:changeStatus(false)
end

function FrozenJewelryBoxItem:showAnim(func)
    self:runCsbAction("show",false,function()
        self:runCsbAction("idleframe2")
        if type(func) == "function" then
            func()
        end
    end)
    self:resetStatus()
end

function FrozenJewelryBoxItem:idleAni(func)
    self.m_isIdle = true
    self:runCsbAction("idleframe1",false,function()
        self.m_isIdle = false
        self:runCsbAction("idleframe2")
        if type(func) == "function" then
            func()
        end
    end)
end

function FrozenJewelryBoxItem:initIdleAni()
    self:runCsbAction("idleframe")
end

function FrozenJewelryBoxItem:openAni(func)
    self.m_isIdle = false
    self:runCsbAction("actionframe",false,function()
        self:runCsbAction("shouji",false,function()
            self:runCsbAction("idleframe3",true)
        end)
        if type(func) == "function" then
            func()
        end
    end)
end

--默认按钮监听回调
function FrozenJewelryBoxItem:clickFunc(sender)
    if self.m_isOpen or self.m_parentView.m_isOver or self.m_parentView.m_isWaitting then
        return
    end

    self:runCsbAction("dianji",false,function()
        self:runCsbAction("idleframe4")
    end)

    local process = self.m_parentView.m_data.process
    local curProcess = self.m_parentView.m_curProcess

    local jackpotType = process[curProcess]
    self.m_jackpotType = jackpotType
    
    for index = 1,4 do
        self.m_jackpotItem:findChild("jewelry_"..jackpots[index]):setVisible(jackpots[index] == jackpotType)
        self:findChild(jackpots[index]):setVisible(jackpots[index] == jackpotType)
    end
    self.m_jackpotItem:setVisible(true)
    self.m_jackpotItem:runCsbAction("actionframe")
    self:changeStatus(true)
    

    self.m_parentView:clickFunc(self,jackpotType)
end

function FrozenJewelryBoxItem:hideJackpotItem()
    self.m_jackpotItem:setVisible(false)
end

--播放动画
function FrozenJewelryBoxItem:runCsbAction(key, loop, func, fps)
    self:stopAllActions()

    if not self.m_csbAct or not key then
        if type(func) == "function" then
            func()
        end
        return
    end

    if loop then
        loop = true
    else
        loop = false
    end

    if util_csbActionExists(self.m_csbAct, key, self.__cname) then
        self.m_csbAct:play(key, loop)
    end

    if func then
        local time = util_csbGetAnimTimes(self.m_csbAct, key, fps)
        if time > 0 then
            util_performWithDelay(self, func, time)
        else
            if func then
                func()
            end
        end
    end

end

function FrozenJewelryBoxItem:runOverAni(jackpotType)
    if not self.m_isOpen then
        self.m_jackpotItem:setVisible(false)
        for index = 1,4 do
            self:findChild(jackpots[index]):setVisible(jackpots[index] == jackpotType)
        end
        self.m_jackpotType = jackpotType
    end

    local winType = self.m_parentView.m_data.winjackpotname[1]
    if self.m_jackpotType and self.m_jackpotType == winType then
        self:runCsbAction("idleframe6",true)
    else
        self:runCsbAction("dark",false,function()
            self:runCsbAction("idleframe5")
        end)
    end

    
end

return FrozenJewelryBoxItem