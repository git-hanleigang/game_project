---
--FortuneCatsCollectView.lua

local FortuneCatsCollectView = class("FortuneCatsCollectView", util_require("base.BaseView"))

FortuneCatsCollectView.m_nGrowTime = 1 -- 增长时间 默认1秒钟
FortuneCatsCollectView.m_nUpdateRateSchID = nil -- 增长定时器

function FortuneCatsCollectView:initUI()
    self:createCsbNode("FortuneCats_zjm_collect.csb")
    self:runCsbAction("idle1", true)
    self.m_totalNum = 0
    self:initViewData(self.m_totalNum)
end

function FortuneCatsCollectView:initTotalNum(num)
    self.m_totalNum = num
    self:initViewData(self.m_totalNum)
end

function FortuneCatsCollectView:initViewData(coins)
    local node = self:findChild("m_lb_num")
    node:setString(util_formatCoins(coins, 20))
    self:updateLabelSize({label = node, sx = 1, sy = 1}, 204)
end

--@_collect: 收集类型 0 普通收集 1 小轮盘收集
function FortuneCatsCollectView:updateCollect(coins, _collect)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
        local node = self:findChild("m_lb_num")
        node:setString(util_formatCoins(self.m_totalNum, 20))
        self:updateLabelSize({label = node, sx = 1, sy = 1}, 204)
    end
    if _collect == 0 then
        if coins >= 20 then
            self:runCsbAction("animation0", false)
            performWithDelay(
                self,
                function()
                    self.m_startCoins = self.m_totalNum
                    self.m_totalNum = self.m_totalNum + coins
                    self:jumpCoins(self.m_totalNum)
                end,
                0.2
            )
        else
            self:runCsbAction("animation3", false)
            self.m_startCoins = self.m_totalNum
            self.m_totalNum = self.m_totalNum + coins
            self:jumpCoins(self.m_totalNum)
        end
        gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_collect_over.mp3")

    else
        if coins == 0 then
            self:runCsbAction("animation3", false)
        else
            self:runCsbAction(
                "animation1",
                false,
                function()
                    self:runCsbAction("idle1", false)
                end
            )
            self.m_startCoins = self.m_totalNum
            self.m_totalNum = self.m_totalNum + coins
            self:jumpCoins(self.m_totalNum)
        end
    end

end

-- coins 金币数量
function FortuneCatsCollectView:updateChangeCollect(coins)
    self.m_totalNum = coins
    local node = self:findChild("m_lb_num")
    node:setString(util_formatCoins(self.m_totalNum, 20))
    self:updateLabelSize({label = node, sx = 1, sy = 1}, 204)
end

function FortuneCatsCollectView:getCollectPos()
    local sp = self.m_csbOwner["Sprite_1"]
    local pos = sp:getParent():convertToWorldSpace(cc.p(sp:getPosition()))
    return pos
end

function FortuneCatsCollectView:getFlyCollectPos()
    local sp = self.m_csbOwner["FortuneCats_di"]
    local pos = sp:getParent():convertToWorldSpace(cc.p(sp:getPosition()))
    return pos
end

function FortuneCatsCollectView:onEnter()
end

function FortuneCatsCollectView:onExit()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function FortuneCatsCollectView:jumpCoins(coins)
    local node = self:findChild("m_lb_num")
    local coinRiseNum = (coins - self.m_startCoins) / 30 -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = self.m_startCoins

    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            -- print("++++++++++++  " .. curCoins)

            curCoins = curCoins + coinRiseNum

            if curCoins >= coins then
                curCoins = coins

                local node = self:findChild("m_lb_num")
                node:setString(util_formatCoins(curCoins, 20))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 204)

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                -- gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_jackpot_over.mp3")
                end
            else
                local node = self:findChild("m_lb_num")
                node:setString(util_formatCoins(curCoins, 20))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 204)
            end
        end
    )
    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                -- gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_jackpot_over.mp3")
                end
                local node = self:findChild("m_lb_num")
                node:setString(util_formatCoins(self.m_totalNum, 20))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 204)
            end
        end,
        1
    )
end

function FortuneCatsCollectView:setBtnTouch(_bTouch)
end

function FortuneCatsCollectView:progressEffect(percent)
end

function FortuneCatsCollectView:setButtonTouchEnabled(_enabled)
    -- self.m_csbOwner["Button_1"]:setTouchEnabled(_enabled)
end

return FortuneCatsCollectView
