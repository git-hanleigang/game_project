---
--xcyy
--2018年5月23日
--SaharaTreasureChooseView.lua

local SaharaTreasureChooseView = class("SaharaTreasureChooseView",util_require("base.BaseView"))


function SaharaTreasureChooseView:initUI(data)

    self:createCsbNode("SaharaTreasure/ChooseView.csb")

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
    self.m_gameInfo = data
    self.m_vecCard = {}
    self.m_vecDiamond = {}
    self.m_gameProgress = 0
    self.m_clickFlag = true

    local index = 1
    while true do
        local parent = self:findChild("ka"..index)
        if parent ~= nil then
            local card = util_createView("CodeSaharaTreasureSrc.SaharaTreasureChooseCard", index)
            parent:addChild(card)
            self.m_vecCard[#self.m_vecCard + 1] = card
        else
            break
        end
        index = index + 1
    end

    index = 1
    while true do
        local parent = self:findChild("zuan_"..index)
        if parent ~= nil then
            local diamond = util_createView("CodeSaharaTreasureSrc.SaharaTreasureChooseDiamond", index)
            parent:addChild(diamond)
            self.m_vecDiamond[#self.m_vecDiamond + 1] = diamond
            
            diamond:initBtn()
            diamond:setClickCall(function(id)
                return self:clickDiamond(id)
            end)
        else
            break
        end
        index = index + 1
    end
    util_setCascadeOpacityEnabledRescursion(self, true)

    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idleframe", true)
    end)

    self:diamondAnim()
    gLobalSoundManager:playBgMusic( "SaharaTreasureSounds/music_SaharaTreasure_choose_bgm.mp3")
end

function SaharaTreasureChooseView:diamondAnim()
    local vecDiamonds = self:getDiamondArray()
    for i = 1, #vecDiamonds, 1 do
        local index = vecDiamonds[i]
        local diamond = self.m_vecDiamond[index]
        diamond:runAnimation("idleframe")
    end
    
    schedule(self, function()
        local vecDiamonds = self:getDiamondArray()
        for i = 1, #vecDiamonds, 1 do
            local index = vecDiamonds[i]
            local diamond = self.m_vecDiamond[index]
            diamond:runAnimation("idleframe")
        end
    end, 1.5)
end

function SaharaTreasureChooseView:getDiamondArray()
    local total = math.random(2, 5)
    local vecDiamonds = {}
    while true do
        local index = math.random(1, #self.m_vecDiamond)
        local flag = false
        if self.m_vecDiamond[index]:getClickFlag() == true then
            for i = 1, #vecDiamonds, 1 do
                if vecDiamonds[i] == index then
                    flag = true
                    break
                end
            end
            if flag == false then
                vecDiamonds[#vecDiamonds + 1] = index
                total = total - 1
            end
            if total == 0 then
                break
            end
        end
    end

    return vecDiamonds
end

function SaharaTreasureChooseView:clickDiamond(index)
    if self.m_clickFlag == false then
        return true
    end
    gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_clik_diamond.mp3")
    self.m_clickFlag = false
    self.m_gameProgress = self.m_gameProgress + 1
    local result = tonumber(self.m_gameInfo.pick[self.m_gameProgress])
    local diamond = self.m_vecDiamond[index]
    diamond:updateUI(result)
    diamond:runAnimation("actionframe", false, function()
        self:updataCard(result)
    end)
    if result == 7 then
        for i = 1, #self.m_vecCard, 1 do
            local card = self.m_vecCard[i]
            card:collectAnim()
        end
    else
        local card = self.m_vecCard[result]
        card:collectAnim()
    end
    if self.m_gameProgress < #self.m_gameInfo.pick then
        self.m_clickFlag = true
    end
    return false
end

function SaharaTreasureChooseView:updataCard(index)
    gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_diamond.mp3")
    
    -- performWithDelay(self, function()
        if self.m_gameProgress < #self.m_gameInfo.pick then
            -- self.m_clickFlag = true
        else
            self:stopAllActions()
            gLobalSoundManager:stopBgMusic()
            self.m_clickFlag = false
            local result = tonumber(self.m_gameInfo.freeType)
            local card = self.m_vecCard[result]
            
            local parent = self:findChild("ka")
            local posNode = self:findChild("ka"..result)
            local effect = util_createAnimation("SaharaTreasure_zuan_win.csb")
            parent:addChild(effect)
            effect:setPosition(posNode:getPosition())
            self:chooseOver()
            gLobalSoundManager:playSound("SaharaTreasureSounds/ound_SaharaTreasure_choose_over.mp3")

            for i = 1, #self.m_vecCard, 1 do
                local id = tonumber(self.m_gameInfo.freeType)
                local card = self.m_vecCard[i]
                card:collectOver(id == i)
            end
        end
    -- end, 1)
end

function SaharaTreasureChooseView:chooseOver()
    local index = 1
    for i = 1, #self.m_vecDiamond, 1 do
        local diamond = self.m_vecDiamond[i]
        if diamond:getClickFlag() == true then
            local resutl = tonumber(self.m_gameInfo.left[index])
            diamond:updateUI(resutl)
            diamond:runAnimation("dark")
            index = index + 1
        end
    end
    performWithDelay(self, function()
        if self.m_gameInfo.func ~= nil then
            self.m_gameInfo.func()
        end
        self:removeAllChildren()
        self:removeFromParent()
    end, 3)
end

function SaharaTreasureChooseView:onEnter()

end

function SaharaTreasureChooseView:onExit()
    
end

--默认按钮监听回调
function SaharaTreasureChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return SaharaTreasureChooseView