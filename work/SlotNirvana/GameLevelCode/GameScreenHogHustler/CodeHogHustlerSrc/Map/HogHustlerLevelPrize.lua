---
--xcyy
--2018年5月23日
--HogHustlerLevelPrize.lua

local HogHustlerLevelPrize = class("HogHustlerLevelPrize",util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")


function HogHustlerLevelPrize:initUI(map)
    self.m_curLevel = 0
    self.m_map = map
    self:createCsbNode("HogHustler_levelprize.csb")
    self.m_light = util_createAnimation("HogHustler_levelprize_guang.csb")
    self:findChild("guang"):addChild(self.m_light)
    self.m_light:setVisible(false)
    self.m_mapMul = {1, 1, 1}
    self.m_isClick = false
    self.m_badge_num = 0


    self.m_light:findChild("Panel_1"):setContentSize(cc.size(20000, 20000))
    
    self.m_badge = util_createAnimation("HogHustler_More.csb")
    self:findChild("Node_huizhang"):addChild(self.m_badge)
    self.m_badge:setVisible(false)
    self.m_badge:setScale(2.2)

    util_setCascadeOpacityEnabledRescursion(self,true)

    self:runCsbAction("idle2", true)

    self:findChild("Button_1"):setVisible(false)
end


function HogHustlerLevelPrize:onEnter()
    HogHustlerLevelPrize.super.onEnter(self)
end


function HogHustlerLevelPrize:onExit()
    HogHustlerLevelPrize.super.onExit(self)
end

--默认按钮监听回调
function HogHustlerLevelPrize:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_isClick and "Button_1" == name then
        self.m_isClick = true
        self.m_map:changeCoinsUIZorder()
        self:waitWithDelay(0.2, function()
            local start_coins = self.m_prize * self.m_mapMul[self.m_curLevel + 1] * (1 + self.m_badge_num/100)
            self.m_map:flyCoins(start_coins)
        end)
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
        self:runCsbAction("over", false, function()
            self:findChild("Button_1"):setVisible(false)
        end)
        self:waitWithDelay(2.5, function()
            self.m_map:changeMapItem()
        end)

        self:waitWithDelay(3, function()
            --local delay_tiem = self.m_curLevel == 2 and 1.5 or 2.5
            local delay_tiem = 1.5
            self:upLevelNum()
            -- self.m_map:changeMapItem()
            self:waitWithDelay(delay_tiem, function()
                self:overUpLevel()
            end)
        end)
    end
end

function HogHustlerLevelPrize:updataShowPrizeNum()
    local node = self:findChild("m_lb_coins")
    local coins = self.m_prize * self.m_mapMul[self.m_curLevel + 1]
    node:setString(util_formatCoins(coins, 40))
    self:updateLabelSize({label=node,sx=1,sy=1},604)
    node:setVisible(coins ~= 0)
    self:findChild("jinbi"):setVisible(coins ~= 0)
end

--引导前 未传值前更新
function HogHustlerLevelPrize:updateLevelPrize(mapMul, totalBet)
    if self.m_prize and self.m_prize == 0 then
        local node = self:findChild("m_lb_coins")
        local coins = totalBet * mapMul[self.m_curLevel + 1]
        node:setString(util_formatCoins(coins, 40))
        self:updateLabelSize({label=node,sx=1,sy=1},604)
        node:setVisible(coins ~= 0)
        self:findChild("jinbi"):setVisible(coins ~= 0)
    end
end

function HogHustlerLevelPrize:setMapPrizeInfo(prize)
    self.m_prize = prize or 0
end

function HogHustlerLevelPrize:initLevel(pos)
    self.m_curLevel = pos
    -- self:findChild("level_1"):setVisible(0 == pos)
    -- self:findChild("level_2"):setVisible(1 == pos)
    -- self:findChild("level_3"):setVisible(2 == pos)


    self:findChild("m_lb_num"):setString(tostring(pos + 1))
    
end

function HogHustlerLevelPrize:upLevel()
    self.m_light:setVisible(true)
    self.m_light:playAction("start", false, function()
        self.m_light:playAction("idle", true)
    end)
    -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_levelPrize_show.mp3")
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_levelprize_popup)

    self:runCsbAction("start", false, function()
        if self.m_badge_num > 0 then
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_levelprize_passstage_fly_buff)
            self:runCsbAction("fly", false, function()
                self:findChild("Button_1"):setVisible(true)
                self:runCsbAction("start2", false)
            end)
            self:waitWithDelay(1.12, function()
                local start_coins = self.m_prize * self.m_mapMul[self.m_curLevel + 1]
                local end_coins = self.m_prize * self.m_mapMul[self.m_curLevel + 1] * (1 + self.m_badge_num/100)
                -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_levelPrize_addLevel.mp3")
                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_levelprize_flycoins2allwin_jump)
                
                self:addLevelPrizeNum(start_coins, end_coins)
            end)
        else
            self:findChild("Button_1"):setVisible(true)
            self:runCsbAction("start2", false)
        end
    end)
end

--刷新徽章显示
function HogHustlerLevelPrize:updataShowBadgeNum(isInit)
    if isInit then
        local node = self.m_badge:findChild("m_lb_num")
        local num_str = tostring(self.m_badge_num)
        if self.m_badge_num > 0 then
            -- num_str = "+"..num_str.."%"
            num_str = num_str.."%"
        end
        node:setString(num_str)
        self:updateLabelSize({label=node,sx=2.12,sy=2.12},103)
        -- self:findChild("Node_huizhang"):setVisible(self.m_badge_num ~= 0)
        self.m_badge:setVisible(self.m_badge_num ~= 0)

        -- if self.m_badge_num > 0 then
            -- self:findChild("Node_huizhang"):setScale(0.4)
        -- end

    else
        if self.m_badge_num == 0 then
            return
        end
        -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_start_fankui.mp3")
        local node = self.m_badge:findChild("m_lb_num")
        -- self:findChild("Node_huizhang"):setVisible(true)
        -- self:findChild("Node_huizhang"):setScale(0.4)

        self.m_badge:setVisible(true)


        self:runCsbAction("actionframe2")
        local action_list = {}
        local addNum = self.m_addNum or 0
        local step_num = math.floor(addNum / 5)
        local starNum = self.m_badge_num - addNum
        if starNum == 0 then
            -- local num_str = "+"..self.m_badge_num.."%"
            local num_str = self.m_badge_num.."%"
            node:setString(num_str)
            self:updateLabelSize({label=node,sx=2.12,sy=2.12},103)
        else
            for i = 1,5 do
                local index = i
                action_list[#action_list + 1] = cc.CallFunc:create(function()
                    local curNumber = starNum + index * step_num
                    if index == 5 then
                        curNumber  = self.m_badge_num
                    end
                    -- local num_str = "+"..curNumber.."%"
                    local num_str = curNumber.."%"
                    node:setString(num_str)
                    self:updateLabelSize({label=node,sx=2.12,sy=2.12},103)
                end)
                action_list[#action_list + 1] = cc.DelayTime:create(0.1)
            end
            local sq = cc.Sequence:create(action_list)
            self:findChild("Node_huizhang"):runAction(sq)
        end
    end
end

--徽章
function HogHustlerLevelPrize:initBadgeNum(num)
    self.m_addNum = num -  self.m_badge_num
    self.m_badge_num = num
end

function HogHustlerLevelPrize:addLevelPrizeNum(start_coins, end_coins, _step)
    local step = _step or 60
    local node = self:findChild("m_lb_coins")
    local addValue = (end_coins - start_coins) / step
    util_jumpNum(node,start_coins,end_coins,addValue,1/60,{30}, nil, nil,function(  )

    end,function()
        self:updateLabelSize({label=node,sx=1,sy=1},604)
    end)
end

function HogHustlerLevelPrize:upLevelNum()
    if self.m_curLevel < 2 then
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_levelup)
        -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_levelPrize_show.mp3")
        self.m_curLevel  = self.m_curLevel + 1
        self:runCsbAction("actionframe")
        self:waitWithDelay(5/60, function()
            self:initLevel(self.m_curLevel)
        end)
    end
end

function HogHustlerLevelPrize:subLevelPrizeNum()
    local start_coins = self.m_prize * self.m_mapMul[self.m_curLevel + 1] * (1 + self.m_badge_num/100)
    local end_coins = 0
    local node = self:findChild("m_lb_coins")
    local addValue = (end_coins - start_coins) / 120
    util_cutDownNum(node,start_coins,end_coins,addValue,1/60,{30}, nil, nil,function(  )

    end,function()
        self:updateLabelSize({label=node,sx=1,sy=1},604)
    end)
    gLobalNoticManager:postNotification("MAP_ADD_COINS_SMELLYRICH", {start_coins, 120})
end

function HogHustlerLevelPrize:overUpLevel()
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_levelprize_over)
    self.m_badge_num = 0
    self:updataShowBadgeNum(true)
    self.m_map:upRichMainEnd()
    self:runCsbAction("over2", false, function()
        self.m_jumpSoundId = gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_levelprize_over_jumpcoins)

        local start_coins = self.m_prize * self.m_mapMul[self.m_curLevel]
        local end_coins = self.m_prize * self.m_mapMul[self.m_curLevel + 1]
        self:addLevelPrizeNum(start_coins, end_coins, 240)
        self.m_light:setVisible(false)
        self.m_isClick = false

        self:runCsbAction("idle3", true)
        self:waitWithDelay(4, function()
            if self.m_jumpSoundId then
                gLobalSoundManager:stopAudio(self.m_jumpSoundId)
                self.m_jumpSoundId = nil
            end
            self:runCsbAction("idle2", true)
        end)
    end)

    
    self.m_light:playAction("over2", false, function()
        self.m_light:setVisible(false)
    end)
end

function HogHustlerLevelPrize:upLevelAni()
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_levelprize_pre_open)
    self:runCsbAction("actionframe3", true)
end

--延时
function HogHustlerLevelPrize:waitWithDelay(time, endFunc, parent)
    time = time or 0
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        waitNode:removeFromParent()
    end, time)
end

return HogHustlerLevelPrize