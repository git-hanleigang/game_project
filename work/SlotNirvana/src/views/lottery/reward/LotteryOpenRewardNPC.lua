--[[
Author: cxc
Date: 2021-11-19 16:36:10
LastEditTime: 2021-11-19 16:37:25
LastEditors: your name
Description: 乐透开奖npc
FilePath: /SlotNirvana/src/views/lottery/reward/LotteryOpenRewardNPC.lua
--]]
local LotteryOpenRewardNPC = class("LotteryOpenRewardNPC", BaseView)
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")

function LotteryOpenRewardNPC:initUI()
    LotteryOpenRewardNPC.super.initUI(self)

    self.m_audioId = -1
    self.m_audioIdleInfo = {
        TALKING = {name = "idle1", cb = nil},
        IDLEING = {name = "idle2", cb = nil}
    }

    self:initView()

    gLobalNoticManager:addObserver(self, "showNumberEvt", LotteryConfig.EVENT_NAME.NPC_SAY_NUMBER_AUDIO_EVT) --npc读数字
    gLobalNoticManager:addObserver(self, "forceStopAudioEvt", LotteryConfig.EVENT_NAME.MACHINE_OVER_FORCE_STOP_NPC_AUDIO) --机器摇晃玩强制结束npc说话
    gLobalNoticManager:addObserver(self, "showFirstNumberSayEvt", LotteryConfig.EVENT_NAME.SHOW_FIRST_NUMBER_NPC_SAY) --显示摇晃出第一个号码 - npc说话
    gLobalNoticManager:addObserver(self, "openRewardOverEvt", LotteryConfig.EVENT_NAME.MACHINE_OVER_NPC_AUDIO) -- 机器摇晃结束npc说话 领奖

end

function LotteryOpenRewardNPC:getCsbName()
    return "Lottery/csd/Drawlottery/Lottery_Drawlottery_NPC.csb"
end

function LotteryOpenRewardNPC:initView()
    -- local parent = self:findChild("node_NPC")
    -- local spineNode = util_spineCreate("Lottery/spine/chaopiaoren/chaopiaoren", true, true)
    -- parent:addChild(spineNode)
    -- local offViewPos = parent:convertToNodeSpace(cc.p(-display.width*0.5, 0))
    -- spineNode:move(cc.p(offViewPos.x, 0))
    -- self.m_spineNode = spineNode

    -- self:npcSayOverIng()
end

function LotteryOpenRewardNPC:initSpineUI()
    LotteryOpenRewardNPC.super.initSpineUI(self)

    local parent = self:findChild("node_NPC")
    local spineNode = util_spineCreate("Lottery/spine/chaopiaoren/chaopiaoren", true, true, 1)
    parent:addChild(spineNode)
    local offViewPos = parent:convertToNodeSpace(cc.p(-display.width*0.5, 0))
    spineNode:move(cc.p(offViewPos.x, 0))
    self.m_spineNode = spineNode

    self:npcSayOverIng()
end

function LotteryOpenRewardNPC:playShowAct(_cb)
    _cb = _cb or function() end
    -- self:runCsbAction("start", false, _cb, 60)
    local moveTo = cc.MoveTo:create(0.5, cc.p(0,0))
    local endFunc = cc.CallFunc:create(_cb)

    self.m_spineNode:runAction(cc.Sequence:create({moveTo, endFunc})) 
end

-- 播放 骨骼动画
--[[
    idle2_1 张嘴
    idle1 说话中
    idle1_2 闭嘴
    idle2 闭嘴中
    idle2_3 读奖励数字
]]
function LotteryOpenRewardNPC:npcSayIng()
    self.m_bSaying = true
    util_spinePlay(self.m_spineNode, self.m_audioIdleInfo.TALKING.name, false)
    util_spineEndCallFunc(self.m_spineNode, self.m_audioIdleInfo.TALKING.name, function()
        if self.m_audioIdleInfo.TALKING.cb then
            self.m_audioIdleInfo.TALKING.cb()
            self.m_audioIdleInfo.TALKING.cb = nil
            self.m_bSaying = false
        else
            self:npcSayIng()
        end
    end)  

end
function LotteryOpenRewardNPC:npcSayOverIng()
    self.m_bIdleIng = true
    util_spinePlay(self.m_spineNode, self.m_audioIdleInfo.IDLEING.name, false)
    util_spineEndCallFunc(self.m_spineNode, self.m_audioIdleInfo.IDLEING.name, function()
        if self.m_audioIdleInfo.IDLEING.cb then
            self.m_audioIdleInfo.IDLEING.cb()
            self.m_audioIdleInfo.IDLEING.cb = nil
            self.m_bIdleIng = false
        else
            self:npcSayOverIng()
        end
    end)  
end


-- 说话 开始
function LotteryOpenRewardNPC:npcSayStart(_cb)
    self.m_bSaying = true
    util_spinePlay(self.m_spineNode, "idle2_1", false)
    util_spineEndCallFunc(self.m_spineNode, "idle2_1", function()
        if self.m_audioIdleInfo.TALKING.cb then
            self.m_audioIdleInfo.TALKING.cb()
            self.m_audioIdleInfo.TALKING.cb = nil
            self.m_bSaying = false
        else
            self:npcSayIng()
        end
    end)
    performWithDelay(self, function()
        if _cb then
            _cb()
        end
    end, 52/60)
end

-- 说话 结束
function LotteryOpenRewardNPC:npcSayOver(_cb)
    self.m_bIdleIng = true
    util_spinePlay(self.m_spineNode, "idle1_2", false)
    util_spineEndCallFunc(self.m_spineNode, "idle1_2", function()
        if _cb then
            _cb()
        end

        if self.m_audioIdleInfo.IDLEING.cb then
            self.m_audioIdleInfo.IDLEING.cb()
            self.m_audioIdleInfo.IDLEING.cb = nil
            self.m_bIdleIng = false
        else
            self:npcSayOverIng()
        end

    end)
   
end

-- npc说话 
function LotteryOpenRewardNPC:sayWord(_audioInfo, _startCb, _overCb)
    local audioInfo = _audioInfo
    if not audioInfo then
        return
    end

    local playAudio = function()
        if _startCb then
            _startCb()
        end

        self.m_audioId = gLobalSoundManager:playSound(audioInfo.path)
        local delayTime = audioInfo.time or 0
        performWithDelay(self, function()

            if self.m_bSaying then
                self.m_audioIdleInfo.TALKING.cb = function()
                    self:npcSayOver(_overCb)
                end
            else
                self:npcSayOver(_overCb)
            end

        end, delayTime)
    end

    if self.m_bIdleIng then
        self.m_audioIdleInfo.IDLEING.cb = function()
            self:npcSayStart(playAudio)
        end
    else
        self:npcSayStart(playAudio)
    end
end

-- npc读数字
function LotteryOpenRewardNPC:npcSayNumber(_number, _idx)
    _number = _number or 0
    
    performWithDelay(self, function()
        self.m_audioId = gLobalSoundManager:playSound("Lottery/sounds/reward/number/CT-Lottery-" .. _number .. ".mp3")
    end, 50/60)
   
    util_spinePlay(self.m_spineNode, "idle2_3", false)
    util_spineEndCallFunc(self.m_spineNode, "idle2_3", function()

        if _idx == 5 then
            -- 说话切换到红球
            self:sayWord(LotteryConfig.NPC_WORD_AUDIO_INFO.SWITCH_BALL, function()
                gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.MACHINE_WOBBLE_NEXT_BALL, _idx) -- 机器摇晃下一个球
            end)
        else
            self:npcSayOverIng()

            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.MACHINE_WOBBLE_NEXT_BALL, _idx) -- 机器摇晃下一个球
        end

    end)
end

------------------------------------------- evt -------------------------------------------
-- 机器摇晃处来 球
function LotteryOpenRewardNPC:showNumberEvt(params)
    -- idx = i, number = self.m_numberList[i]
    if not params then
        return
    end

    local idx = params.idx or 1
    local number = params.number

    if self.m_bIdleIng and idx < 6 then
        self.m_audioIdleInfo.IDLEING.cb = function()
            self:npcSayNumber(number, idx)
        end
    else
        self:npcSayNumber(number, idx)
    end
end

-- 第一个号码是
function LotteryOpenRewardNPC:showFirstNumberSayEvt(_idx)
    if self.m_skip then
        return
    end
    local path = ""
    if _idx == 1 then
        path = LotteryConfig.NPC_WORD_AUDIO_INFO.FIRST_NUMBER
        --gLobalSoundManager:playSound("Lottery/sounds/reward/Lottery_cheer.mp3")
    else
        if _idx < 6 then
            path = LotteryConfig.NPC_WORD_AUDIO_INFO.NEXT_NUMBER 
        elseif _idx >= 6 then
            gLobalSoundManager:playSound("Lottery/sounds/reward/Lottery_cheer.mp3")
        end
    end
    if type(path) == "table" then
        self:sayWord(path)
    end
end

-- skip结束动画 强制结束说话
function LotteryOpenRewardNPC:forceStopAudioEvt()
    gLobalSoundManager:stopAudio(self.m_audioId)

    self:stopAllActions()
    util_spinePlay(self.m_spineNode, "idle2", true)
    self.m_skip = true
    self.m_bIdleIng = false
    self.m_bSaying = false
end

-- 本期开奖结束
function LotteryOpenRewardNPC:openRewardOverEvt()
    self:sayWord(LotteryConfig.NPC_WORD_AUDIO_INFO.OVER)
end

------------------------------------------- evt -------------------------------------------

return LotteryOpenRewardNPC