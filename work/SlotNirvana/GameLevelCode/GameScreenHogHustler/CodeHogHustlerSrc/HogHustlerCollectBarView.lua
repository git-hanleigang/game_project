---
--xcyy
--2018年5月23日
--HogHustlerCollectBarView.lua

local HogHustlerCollectBarView = class("HogHustlerCollectBarView",util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

HogHustlerCollectBarView.m_maxNum = 10

local uiGloomyNodeName = {"Hdi", "odi", "gdi", "Hdi2", "Udi", "sdi", "tdi", "ldi", "Edi", "rdi"}
local uiHighlightNodeName = {"HDI", "oDI", "gDi", "hDi2", "UDi", "sDi", "tDi", "lDi", "EDi", "rDi"}
local effectHighNodeName = {"HDI_0", "oDI_0", "gDi_0", "hDi2_0", "UDi_0", "sDi_0", "tDi_0", "lDi_0", "EDi_0", "rDi_0"}

function HogHustlerCollectBarView:initUI(machine)
    self.m_machine = machine
    self:createCsbNode("HogHustler_shoujitiao.csb")
    self.m_letterGloomy_tab = {}    --暗图标
    self.m_letterHighlight_tab = {} --亮图标
    self.m_letterEffectHighlight_tab = {}    --高亮效果
    self.m_letterLableBg_tab = {}   --图标label背景
    self.m_tippingPoint_tab = {}    --爆点
    self.m_collect_box = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0} --当前收集字母的数量
    
    self.m_isFankui = false

    self.m_collectBarDice = util_createAnimation("HogHustler_shoujitiao_0.csb")
    self:findChild("shoujitiao_0"):addChild(self.m_collectBarDice)

    self.m_dice_Label = self.m_collectBarDice:findChild("m_lb_num")

    for i = 1, self.m_maxNum do
        table.insert(self.m_letterGloomy_tab, self:findChild(uiGloomyNodeName[i]))
        table.insert(self.m_letterHighlight_tab, self:findChild(uiHighlightNodeName[i]))
        table.insert(self.m_letterEffectHighlight_tab, self:findChild(effectHighNodeName[i]))
        local geshu = util_createAnimation("HogHustler_shoujitiao_geshu.csb")
        geshu.m_curNum = 0
        self:findChild("Node_"..i):addChild(geshu)
        table.insert(self.m_letterLableBg_tab, geshu)
        geshu:playAction("idle")
        local tippingPoint = util_createAnimation("HogHustler_shoujitiao_fankui.csb")
        table.insert(self.m_tippingPoint_tab, tippingPoint)
        local pos = util_convertToNodeSpace(self:findChild(uiGloomyNodeName[i]), self)
        self:addChild(tippingPoint)
        tippingPoint:setPosition(pos)
        tippingPoint:setVisible(false)
    end
    self:refreshLabel()
    self:setDiceNum(0)
    --> self:addClick(self:findChild("diceBg"))
    self:addClick(self:findChild("Panel_Click_Dice"))
    self:addClick(self:findChild("Panel_Click"))
    self.m_canClick = true
    self:playIdle()
    util_setCascadeOpacityEnabledRescursion(self,true)

end


function HogHustlerCollectBarView:onEnter()
    HogHustlerCollectBarView.super.onEnter(self)
end

function HogHustlerCollectBarView:onExit()
    HogHustlerCollectBarView.super.onExit(self)
end

function HogHustlerCollectBarView:setDiceNum(num)
    self.m_diceNum = num
    self.m_dice_Label:setString(self.m_diceNum)

    self:updateLabelSize({label=self.m_dice_Label,sx=0.45,sy=0.45},79)
    -- self.m_machine:setDiceNum(num)
end

function HogHustlerCollectBarView:initLetterNum(index,num, isInit)
    self:findChild("Node_"..index):setOpacity(255)
    self.m_letterGloomy_tab[index]:setOpacity(255)
    self.m_letterHighlight_tab[index]:setOpacity(255)
    self.m_letterLableBg_tab[index]:setOpacity(255)
    self.m_letterGloomy_tab[index]:setVisible(num == 0)
    self.m_letterHighlight_tab[index]:setVisible(num > 0)
    -- self.m_letterEffectHighlight_tab[index]:setVisible(num > 0)
    self.m_letterLableBg_tab[index]:setVisible(num > 1)
    local curNum = self.m_letterLableBg_tab[index].m_curNum or 0
    self.m_letterLableBg_tab[index].m_curNum = num
    local isPlay = true
    if curNum ~= num and not isInit then
        local tippingPoint = self.m_tippingPoint_tab[index]
        if num == 2 then
            self.m_letterLableBg_tab[index]:playAction("actionframe")
        elseif num > 2 then
            isPlay = false
            self.m_letterLableBg_tab[index]:playAction("actionframe2")
        end
        tippingPoint:setVisible(true)
        tippingPoint:playAction("shouji", false, function()
            tippingPoint:setVisible(false)
        end)
    end
    if isPlay then
        self.m_letterLableBg_tab[index]:findChild("m_lb_num1"):setString(num - 1)
        
        self:updateLabelSize({label=self.m_letterLableBg_tab[index]:findChild("m_lb_num1"),sx=1,sy=1},15)
    else
        performWithDelay(self, function ()
            self.m_letterLableBg_tab[index]:findChild("m_lb_num1"):setString(num - 1)
            self:updateLabelSize({label=self.m_letterLableBg_tab[index]:findChild("m_lb_num1"),sx=1,sy=1},15)
        end, 20/60)
    end

end

function HogHustlerCollectBarView:getTargetNode(collectType)
    local index = collectType - 900  --collectType 是 901~910
    if index > 0 and index <= self.m_maxNum then
        return self.m_letterHighlight_tab[index]
    end
end

function HogHustlerCollectBarView:refreshLabel(isInit)
    for i = 1, self.m_maxNum do
        local num = self.m_collect_box[i] or 0
        self:initLetterNum(i, num, isInit)
    end
    self:checkPrompt()
end

--最后一个提示
function HogHustlerCollectBarView:checkPrompt()
    local left_num = 0
    local lastIdx = 1
    for i = 1, self.m_maxNum do
        local num = self.m_collect_box[i] or 0
        if num == 0 then
            lastIdx = i
            left_num  = left_num + 1
        end
    end
    if left_num == 1 then
        for i = 1, self.m_maxNum do
            if self.m_letterEffectHighlight_tab[i] then
                self.m_letterEffectHighlight_tab[i]:setVisible(lastIdx == i)
            end
        end
        
        self:runCsbAction("shouji", true) -- 播放时间线
    elseif left_num == 0 then
        self:playIdle()
    end
end

function HogHustlerCollectBarView:setLetterNum(collect_box)
    if collect_box and type(collect_box) == "table" then
        self.m_collect_box = collect_box
    end
end

--默认按钮监听回调
function HogHustlerCollectBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_Click" then
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
        gLobalNoticManager:postNotification("TIP_SHOW_SMELLYRICH")
    elseif name == "Panel_Click_Dice" then
        if self.m_canClick then
            self.m_canClick = false
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
            gLobalNoticManager:postNotification("MAP_SHOW_CLICK_SMELLYRICH")
        end
    end
end

function HogHustlerCollectBarView:playIdle()
    self:runCsbAction("idle", true) -- 播放时间线
end

function HogHustlerCollectBarView:resetClick()
    self.m_canClick = true
end

function HogHustlerCollectBarView:reset()
    if self.m_isFankui then
        self.m_isFankui = false
        -- self.m_collectBarDice:setVisible(false)
        self.m_collect_box = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0} --当前收集字母的数量
        self:runCsbAction("over", false, function()
            self:refreshLabel(true)
        end)

        -- self:refreshLabel(true)
    else
        self:refreshLabel(true)
    end
end

function HogHustlerCollectBarView:fankui(diceNum)
    -- gLobalSoundManager:playSound("HogHustlerSounds/sound_HogHustler_collect_full.mp3")
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_collectbar_all_trigger)

    self.m_isFankui = true
    -- self.m_collectBarDice:setVisible(true)
    self.m_collectBarDice:playAction("actionframe")
    for i = 1, self.m_maxNum do
        if self.m_letterEffectHighlight_tab[i] then
            self.m_letterEffectHighlight_tab[i]:setVisible(false)
        end
    end
    -- self:findChild("Particle_1"):resetSystem()
    -- self:findChild("Particle_1"):setPositionType(0)
    -- self:findChild("Particle_2"):resetSystem()
    -- self:findChild("Particle_2"):setPositionType(0)
    -- self:findChild("Particle_1"):setDuration(-1)
    -- self:findChild("Particle_2"):setDuration(-1)
    -- self:setLocalZOrder(600)
    self:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)
    self:runCsbAction("actionframe", false, function()
        -- self:setLocalZOrder(300)
        self:playIdle()
    end)
    performWithDelay(self, function ()
        self:setDiceNum(diceNum)
    end, 65/60)
end

return HogHustlerCollectBarView