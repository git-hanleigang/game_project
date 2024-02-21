---
--xcyy
--2018年5月23日
--AliceCollectProgress.lua

local AliceCollectProgress = class("AliceCollectProgress",util_require("base.BaseView"))

local GAMES_ICON_NAME = {"hat", "card", "tree", "mushroom", "rose", "castle"}
AliceCollectProgress.m_currGameName = nil
local PROGRESS_WIDTH = 812

function AliceCollectProgress:initUI(data)

    self:createCsbNode("Alice_progress.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_progress = self:findChild("LoadingBar_1")
    for i = 1, #GAMES_ICON_NAME, 1 do
        local gameIcon = self:findChild(GAMES_ICON_NAME[i])
        if gameIcon ~= nil then
            gameIcon:setVisible(false)
        end
        local iconEffect = self:findChild(GAMES_ICON_NAME[i].."_0")
        if iconEffect ~= nil then
            iconEffect:setVisible(false)
        end
    end
    self.m_labCollectNum = self:findChild("m_lab_num")
    self.m_parent = data
    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self:showIdle()

    self.m_collectEffect = util_createView("CodeAliceSrc.AliceCollectProgressEffect")
    self:findChild("rabbit"):addChild(self.m_collectEffect)
    -- self.m_collectLight = util_createView("CodeAliceSrc.AliceCollectProgressLight")
    -- self:findChild("Node_light"):addChild(self.m_collectLight)

    self.m_collectLight = util_createView("CodeAliceSrc.AliceProgressLight")
    self:findChild("glow"):addChild(self.m_collectLight)
    self.m_collectLight:setVisible(false)
    
end

function AliceCollectProgress:showIdle()
    self:runCsbAction("idle", true)
end

function AliceCollectProgress:initProgress(map)
    if self.m_currGameName ~= nil then
        local gameIcon = self:findChild(self.m_currGameName)
        if gameIcon ~= nil then
            gameIcon:setVisible(false)
        end
    end
    self.m_currGameName = map.nextGameName
    if self.m_currGameName == nil then
        self.m_currGameName = "castle"
    end
    local gameIcon = self:findChild(self.m_currGameName)
    gameIcon:setVisible(true)

    local percent = 0
    if map.collectSignalNum >= map.max then
        percent = 100
    else
        percent = map.collectSignalNum * 100 / map.max
    end
    self.m_progress:setPercent(percent)
    self.m_labCollectNum:setString(map.collectSignalNum.."/".. map.max)
end

function AliceCollectProgress:updateGameIcon(map)
    local gameIcon = self:findChild(self.m_currGameName)
    gameIcon:setVisible(false)
    self:initProgress(map)
end

function AliceCollectProgress:updatePercent(collectNum, maxNum, func)
    if collectNum > maxNum then
        collectNum = maxNum
    end
    self.m_labCollectNum:setString(collectNum.."/".. maxNum)
    local percent = collectNum * 100 / maxNum
    self:collectAnim(function()
        -- self:runCsbAction("start")
        if self.m_percentAction ~= nil then
            self:stopAction(self.m_percentAction)
            self.m_percentAction = nil
            if self.m_particleEffect ~= nil then
                self.m_particleEffect:removeFromParent()
                self.m_particleEffect = nil
            end
        end

        local oldPercent = self.m_progress:getPercent()
        local effect, act = util_csbCreate("Alice_progress_jindutiao.csb")
        self:findChild("Panel_1"):addChild(effect)
        local posX = oldPercent * 0.01 * PROGRESS_WIDTH
        effect:setPosition(posX, 14)
        util_csbPlayForKey(act, "actionframe1")
        self.m_particleEffect = effect
        
        self.m_percentAction = schedule(self, function()
            oldPercent = oldPercent + 1
            if oldPercent >= percent then
                self:stopAction(self.m_percentAction)
                self.m_percentAction = nil
                if func ~= nil then
                    performWithDelay(self, function()
                        func()
                        effect:removeFromParent()
                        self.m_particleEffect = nil
                    end, 0.5)
                end
                oldPercent = percent
            end
            self.m_progress:setPercent(oldPercent)
            posX = oldPercent * 0.01 * PROGRESS_WIDTH
            effect:setPositionX(posX)
            -- self:progressEffect(oldPercent)
        end, 0.08)
    end)
end

function AliceCollectProgress:getCollectEndPos()
    local node = self:findChild("Alice_jindu_rim_2")
    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    return worldPos
end

function AliceCollectProgress:collectAnim(func)
    
    self.m_collectEffect:showEffect()
    -- self.m_collectLight:showEffect()

    if func ~= nil then
        func()
    end
end

function AliceCollectProgress:completedAnim(func)
    gLobalSoundManager:setBackgroundMusicVolume(0)
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_collect_completed.mp3")
    local iconEffect = self:findChild(self.m_currGameName.."_0")
    if iconEffect ~= nil then
        iconEffect:setVisible(true)
    end
    self.m_collectLight:setVisible(true)
    util_playFadeInAction(self.m_collectLight, 0.3)
    self:runCsbAction("actionframe2", false, function()
        if func ~= nil then
            func()
        end
        if iconEffect ~= nil then
            iconEffect:setVisible(false)
        end
        util_playFadeOutAction(self.m_collectLight, 0.3, function()
            self.m_collectLight:setVisible(false)
        end)
        
        performWithDelay(self, function()
            self:showIdle()
        end, 1.5)
    end)
end

function AliceCollectProgress:onEnter()
 

end

function AliceCollectProgress:showAdd()
    
end
function AliceCollectProgress:onExit()
 
end

--默认按钮监听回调
function AliceCollectProgress:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "click" then
        self.m_parent:clickProgress()
    end
end


return AliceCollectProgress