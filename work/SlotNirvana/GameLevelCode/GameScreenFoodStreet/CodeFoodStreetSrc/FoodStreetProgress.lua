---
--xcyy
--2018年5月23日
--FoodStreetProgress.lua

local FoodStreetProgress = class("FoodStreetProgress", util_require("base.BaseView"))

local PROGRESS_WIDTH = 461

function FoodStreetProgress:initUI()
    self:createCsbNode("FoodStreet_jindutiao.csb")

    self:runCsbAction("idle") -- 播放时间线
    self.m_progress = self:findChild("progress")

    self.m_nodeCat = util_createView("CodeFoodStreetSrc.FoodStreetCat")
    self:findChild("Node_cat"):addChild(self.m_nodeCat)
    self.m_nodeCat:setVisible(false)

    local effect = util_createAnimation("FoodStreet_jindutiao_0.csb")
    self:findChild("jindutiao_0"):addChild(effect)
    effect:runCsbAction("actionframe", true)
end

function FoodStreetProgress:initProgress(percent)
    self:runCsbAction("idle")
    local posX = percent * 0.01 * PROGRESS_WIDTH
    self.m_progress:setPositionX(posX)
end

function FoodStreetProgress:updatePercent(percent, func)
    self:runCsbAction("shouji")
    if self.m_percentAction ~= nil then
        self:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end

    local oldPercent = self.m_progress:getPositionX() / (0.01 * PROGRESS_WIDTH)

    self.m_percentAction =
        schedule(
        self,
        function()
            oldPercent = oldPercent + 1
            if oldPercent >= percent then
                self:stopAction(self.m_percentAction)
                self.m_percentAction = nil
                if func ~= nil then
                    performWithDelay(
                        self,
                        function()
                            func()
                        end,
                        0.5
                    )
                end
                oldPercent = percent
            end
            local posX = oldPercent * 0.01 * PROGRESS_WIDTH
            self.m_progress:setPositionX(posX)
        end,
        0.08
    )
end

function FoodStreetProgress:showCat()
    if not self.m_nodeCat:isVisible() then
        local posX = PROGRESS_WIDTH - 20
        self.m_nodeCat:setPositionX(posX)
        self.m_nodeCat:runAnim("start", false)
    end
    self.m_nodeCat:setVisible(true)
end

function FoodStreetProgress:hideCat()
    if self.m_nodeCat:isVisible() then
        self.m_nodeCat:runAnim(
            "over",
            false,
            function()
                self.m_nodeCat:setVisible(false)
            end
        )
    end
end

function FoodStreetProgress:collectFailed(func)
    self.m_nodeCat:setPositionX(PROGRESS_WIDTH - 20)

    local oldPercent = self.m_progress:getPositionX() / (0.01 * PROGRESS_WIDTH)
    local movePercent = 100 - oldPercent
    local posX = oldPercent * 0.01 * PROGRESS_WIDTH
    local endPos = cc.p(self.m_nodeCat:getPosition())
    endPos.x = posX + 50
    local moveTo = cc.MoveTo:create(movePercent * 0.03, endPos)
    self.m_catSound = gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_cat_move.mp3")
    self.m_nodeCat:setVisible(true)
    self.m_nodeCat:runAnim("start",false)
    local delay = cc.DelayTime:create(0.5)
    local delay2 = cc.DelayTime:create(0.1)
    local callback =
        cc.CallFunc:create(
        function()
            if self.m_catSound then
                gLobalSoundManager:stopAudio(self.m_catSound)
                self.m_catSound = nil
            end

            self.m_sound = gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_cat_collect.mp3")

            self.m_nodeCat:runAnim("actionframe", true)

            self.m_percentAction =
                schedule(
                self,
                function()
                    oldPercent = oldPercent - 1
                    if oldPercent <= 0 then
                        if self.m_sound then
                            gLobalSoundManager:stopAudio(self.m_sound)
                            self.m_sound = nil
                        end

                        self:stopAction(self.m_percentAction)
                        self.m_percentAction = nil
                        self.m_nodeCat:runAnim(
                            "over",
                            false,
                            function()
                                self.m_nodeCat:setVisible(false)
                            end
                        )
                        if func ~= nil then
                            performWithDelay(
                                self,
                                function()
                                    func()
                                end,
                                0.5
                            )
                        end
                        oldPercent = 0
                    end
                    posX = oldPercent * 0.01 * PROGRESS_WIDTH
                    self.m_nodeCat:setPositionX(posX + 50)
                    self.m_progress:setPositionX(posX)
                end,
                0.04
            )
        end
    )
    self.m_nodeCat:runAction(cc.Sequence:create(delay, moveTo, delay2, callback))
end

function FoodStreetProgress:collectSuccess(func)
    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_collect_over.mp3")
    self:runCsbAction(
        "jiman",
        false,
        function()
            func()
        end
    )
end

function FoodStreetProgress:onEnter()
end

function FoodStreetProgress:onExit()
    if self.m_catSound then
        gLobalSoundManager:stopAudio(self.m_catSound)
        self.m_catSound = nil
    end

    if self.m_sound then
        gLobalSoundManager:stopAudio(self.m_sound)
        self.m_sound = nil
    end
end

return FoodStreetProgress
