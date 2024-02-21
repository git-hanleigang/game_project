---
--xcyy
--2018年5月23日
--FrozenJewelryBonusView.lua

local FrozenJewelryBonusView = class("FrozenJewelryBonusView",util_require("Levels.BaseLevelDialog"))


function FrozenJewelryBonusView:initUI(params)

    self.m_jackpotCount = {grand = 3,major = 3,minor = 3,mini = 3}

    self.m_machine = params.machine
    self:createCsbNode("FrozenJewelry/PickBonus.csb")

    local jackpotNode = self:findChild("Jackpot")
    if self.m_machine.m_isSpecialView then
        local posY = jackpotNode:getPositionY() + 30
        jackpotNode:setPositionY(posY)
    end

    self:runCsbAction("idle")

    local jackpotBar = util_createView("CodeFrozenJewelrySrc.FrozenJewelryJackPotBarInBonus")
    jackpotNode:addChild(jackpotBar)
    jackpotBar:initMachine(self.m_machine)
    self.m_jackpotBar = jackpotBar

    self.m_boxItems = {}
    for index = 1,12 do
        local boxItem = util_createView("CodeFrozenJewelrySrc.FrozenJewelryBoxItem",{index = index,parentView = self})
        self:findChild("Box__"..(index - 1)):addChild(boxItem)
        self.m_boxItems[index] = boxItem
    end

    self.m_curProcess = 1

    self.m_spine = util_spineCreate("Socre_FrozenJewelry_pick",true,true)
    self:findChild("Elsa"):addChild(self.m_spine)
    local startNode = cc.Node:create()
    util_spinePushBindNode(self.m_spine,"zhongbaidian33",startNode)
    self.m_spine.m_startNode = startNode

    self.m_chooses = {}
end

function FrozenJewelryBonusView:randIdleAni()
    self:stopAllActions()

    local func = function()
        local tempAry = {}
        for k,boxItem in pairs(self.m_boxItems) do
            if not boxItem.m_isOpen and not boxItem.m_isIdle then
                tempAry[#tempAry + 1] = boxItem
            end
        end

        local randIndex = math.random(1,#tempAry)
        if tempAry[randIndex] then
            tempAry[randIndex]:idleAni()
        end
        
    end
    util_schedule(self,function()
        func()
    end,1.2) 

    func()
end

--[[
    重置界面
]]
function FrozenJewelryBonusView:resetView()
    for k,jackpotType in pairs(self.m_jackpotCount) do
        self.m_jackpotCount[k] = 3
    end
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_box_turn_to_box.mp3")
    for k,boxItem in pairs(self.m_boxItems) do
        boxItem:showAnim()
    end
end

--[[
    显示界面
]]
function FrozenJewelryBonusView:showView(data,func)
    self.m_data = data
    self.m_endFunc = func
    self.m_curProcess = 1
    self.m_chooses = {}
    self.m_isOver = false
    self.m_isCollecting = false
    self:setVisible(true)
    self:initBox()
    self.m_isWaitting = true
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        self:resetView()
        --宝箱随机播idle
        self.m_machine:delayCallBack(1,function()
            self.m_isWaitting = false
            self:randIdleAni()
        end)
    end)
    self.m_jackpotBar:resetView()

    self.m_machine:playSpineAni(self.m_spine,"start",false,function()
        self.m_machine:playSpineAni(self.m_spine,"idleframe",true)
    end)
end

--[[
    初始化箱子
]]
function FrozenJewelryBonusView:initBox()
    for k,boxItem in pairs(self.m_boxItems) do
        boxItem:initIdleAni()
    end
end

--[[
    隐藏界面
]]
function FrozenJewelryBonusView:hideView()
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_girl_happy.mp3")
    

    local winType = self.m_data.winJackpot[1]
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_show_jackpot_win_"..winType..".mp3")
    --高兴动画
    self.m_machine:playSpineAni(self.m_spine,"happy",false,function()
        self.m_machine:playSpineAni(self.m_spine,"over",false,function()
            self:setVisible(false)
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
                self.m_endFunc = nil
                self.m_data = nil
            end
        end)
    end)
end

function FrozenJewelryBonusView:runNextBox(func)
    --获取队列动作
    local boxData = self:popChoose()
    if not boxData then
        self.m_isCollecting = false
        self:stopAllActions()
        if type(func) == "function" then
            func()
        end
        return
    end

    self.m_isCollecting = true

    local boxItem = boxData.boxItem
    local jackpotType = boxData.jackpotType
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_girl_show_magic.mp3")
    --spine挥动魔棒
    self.m_machine:playSpineAni(self.m_spine,"actionframe",false,function()
        self.m_machine:playSpineAni(self.m_spine,"idleframe",true)
        self:runNextBox(func)
    end)
    self.m_machine:delayCallBack(11 / 30,function()
        self:flyChooseAni(self.m_spine.m_startNode,boxItem,function()
            boxItem:openAni(function()
                local endNode = self.m_jackpotBar:getCurProcessNode(jackpotType)
                boxItem:hideJackpotItem()
                --飞粒子动画
                self:flyJackpotAni(boxItem.m_jackpotItem,endNode,jackpotType,function()
                    self.m_jackpotBar:refreshCollect(jackpotType)
                end)
            end)
        end)
        
    end)
end

--[[
    按钮回调
]]
function FrozenJewelryBonusView:clickFunc(boxItem,jackpotType)
    if self.m_isWaitting then
        return
    end
    self.m_jackpotCount[jackpotType] = self.m_jackpotCount[jackpotType] - 1
    if self.m_curProcess >= #self.m_data.process then
        self.m_isOver = true
    else
        self.m_curProcess = self.m_curProcess + 1
    end

    local data = {
        boxItem = boxItem,
        jackpotType = jackpotType
    }
    --存入动作队列
    self:pushChoose(data)

    if not self.m_isCollecting then
        self:runNextBox(function()
            --选择结束
            if self.m_isOver then
                self.m_machine:delayCallBack(2,function()
                    
                    self:hideView()
                end)
                self.m_machine:delayCallBack(1.1,function()
                    --箱子变黑
                    for k,boxItem in pairs(self.m_boxItems) do
                        local jackpotType
                        if not boxItem.m_isOpen then
                            --获取未打开的箱子的jackpot
                            for tempType,leftCount in pairs(self.m_jackpotCount) do
                                if leftCount > 0 then
                                    self.m_jackpotCount[tempType] = self.m_jackpotCount[tempType] - 1
                                    jackpotType = tempType
                                    break
                                end
                            end
                        end

                        boxItem:runOverAni(jackpotType)
                    end
                end)
            end
        end)
    end
end

function FrozenJewelryBonusView:pushChoose(data)
    self.m_chooses[#self.m_chooses + 1] = data
end

function FrozenJewelryBonusView:popChoose()
    if #self.m_chooses == 0 then
        return
    end
    local data = self.m_chooses[1]
    table.remove(self.m_chooses,1,1)
    return data
end

--[[
    飞粒子动画
]]
function FrozenJewelryBonusView:flyChooseAni(startNode,endNode,func)
    --粒子
    local particle = util_createAnimation("FrozenJewelry_Pick_tw.csb")
    for index = 1,3 do
        local par = particle:findChild("Particle_"..index)
        if not tolua.isnull(par) then
            par:setPositionType(0)
        end
    end
    


    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    self:addChild(particle,1000)
    particle:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(20 / 60,endPos),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
            for index = 1,3 do
                local par = particle:findChild("Particle_"..index)
                if not tolua.isnull(par) then
                    par:stopSystem()
                end
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    particle:runAction(seq)
end

--[[
    飞粒子动画
]]
function FrozenJewelryBonusView:flyJackpotAni(startNode,endNode,jackpotType,func)
    local tempNode = util_createAnimation("FrozenJewelry_Pick_Box_jewelry.csb")

    local jackpots = {"grand","major","minor","mini"}
    for index = 1,4 do
        local isShow = jackpots[index] == jackpotType
        tempNode:findChild("jewelry_"..jackpots[index]):setVisible(isShow)
    end

    --粒子
    local particle = util_createAnimation("FrozenJewelry_Pick_jewelry_tw.csb")
    for index = 1,2 do
        local par = particle:findChild("Particle_"..index)
        if not tolua.isnull(par) then
            par:setPositionType(0)
        end
    end

    tempNode:findChild("root"):addChild(particle,10)
    tempNode:findChild("Node_jevelry"):setLocalZOrder(20)

    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    self:addChild(tempNode,1000)
    tempNode:setPosition(startPos)

    tempNode:runCsbAction("shouji")

    local seq = cc.Sequence:create({
        cc.DelayTime:create(10 / 60),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_jackpot_fly.mp3")
        end),
        cc.MoveTo:create(14 / 60,endPos),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_jackpot_fly_feed_back.mp3")
            if type(func) == "function" then
                func()
            end
            for index = 1,2 do
                local par = particle:findChild("Particle_"..index)
                if not tolua.isnull(par) then
                    par:stopSystem()
                end
            end
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create(true)
    })

    tempNode:runAction(seq)
end




return FrozenJewelryBonusView