--[[
Author: cxc
Date: 2021-11-19 16:07:47
LastEditTime: 2021-11-19 16:07:49
LastEditors: your name
Description: 乐透开奖 主界面
FilePath: /SlotNirvana/src/views/lottery/reward/LotteryOpenReward.lua
--]]
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryOpenReward = class("LotteryOpenReward", BaseActivityMainLayer)

function LotteryOpenReward:ctor()
    LotteryOpenReward.super.ctor(self)
    self.m_data = G_GetMgr(G_REF.Lottery):getData()

    self:setPauseSlotsEnabled(true)
    self:setHideLobbyEnabled(true)

    self:setExtendData("LotteryOpenReward")
    self:setLandscapeCsbName("Lottery/csd/Drawlottery/Lottery_Drawlottery_layer.csb")
    self:setBgm("Lottery/sounds/Lottery_bg_music_2.mp3")
end

-- 初始化节点
function LotteryOpenReward:initCsbNodes()
    LotteryOpenReward.super.initCsbNodes(self)

    self.m_lbTime = self:findChild("lb_time")
    self.m_spineParent = self:findChild("node_spine")
end

function LotteryOpenReward:initView()
    LotteryOpenReward.super.initView(self)

    -- 背景充满屏幕
    local root = self:findChild("root")
    local bg = self:findChild("sp_bg")
    bg:setScale(1 / root:getScale())

    -- 时间
    self:updateTimeUI()
    -- title
    self:initTitleUI()
    -- 机器
    self:initMachineUI()
    -- npc
    self:initNPCUI()
    -- 自己选择的号码区域
    self:initYoursUI()
    -- 中奖号码区域
    self:initRewardNumUI()
    -- bottom
    self:initBottomUI()

    -- -- spine
    -- local spineNode = util_spineCreate("Lottery/spine/kaichangbj/skeleton", true, true)
    -- self.m_spineParent:addChild(spineNode)
    -- spineNode:setScale(bg:getScale()+0.01)
    -- self.m_spinNode = spineNode
    -- spineNode:setVisible(false)
    -- 过场动画
    self.m_guochangAni = util_createAnimation("Lottery/csd/Drawlottery/Lottery_DrawLottery_guochang.csb")
    self.m_guochangAni:setScale(bg:getScale())
    self.m_spineParent:addChild(self.m_guochangAni, 2)
end

function LotteryOpenReward:initSpineUI()
    LotteryOpenReward.super.initSpineUI(self)

    local bg = self:findChild("sp_bg")

    -- spine
    local spineNode = util_spineCreate("Lottery/spine/kaichangbj/skeleton", true, true, 1)
    self.m_spineParent:addChild(spineNode)
    spineNode:setScale(bg:getScale()+0.01)
    self.m_spinNode = spineNode
    spineNode:setVisible(false)
end

function LotteryOpenReward:onExit()
    LotteryOpenReward.super.onExit(self)
    self.actCoroutine = nil
end

-- 界面显示完毕播放动画
function LotteryOpenReward:onShowedCallFunc()
    LotteryOpenReward.super.onShowedCallFunc(self)

    -- 背景音乐
    -- local bgMusicPath = self:getBgMusicPath()
    -- if bgMusicPath and bgMusicPath ~= "" then
    --     gLobalSoundManager:playBgMusic(bgMusicPath)
    --     gLobalSoundManager:setLockBgMusic(true)
    --     gLobalSoundManager:setLockBgVolume(true)
    -- end

    -- spin动画
    self.m_spinNode:setVisible(true)
    util_spinePlay(self.m_spinNode, "start")
    -- util_spineEndCallFunc(self.m_spinNode, "start", handler(self, self.playGuochangAct))
    self:playGuochangAct()
end

-- 标题
function LotteryOpenReward:initTitleUI()
    local parent = self:findChild("node_title")
    local view = util_createView("views/lottery/reward/LotteryOpenRewardTitle")
    parent:addChild(view)
    self.m_titleUI = view
end
-- 机器
function LotteryOpenReward:initMachineUI()
    local parent = self:findChild("node_machine")
    local view = util_createView("views/lottery/reward/LotteryOpenRewardMachine")
    parent:addChild(view)
    view:setVisible(false)
    self.m_machineUI = view
end
-- npc
function LotteryOpenReward:initNPCUI()
    local parent = self:findChild("node_NPC")
    local view = util_createView("views/lottery/reward/LotteryOpenRewardNPC")
    parent:addChild(view)
    self.m_npcUI = view
end
-- 自己选择的号码区域
function LotteryOpenReward:initYoursUI()
    local parent = self:findChild("node_yours")
    local view = util_createView("views/lottery/reward/LotteryOpenRewardYours")
    parent:addChild(view)
    self.m_yoursUI = view
end
-- 中奖号码区域
function LotteryOpenReward:initRewardNumUI()
    local parent = self:findChild("node_show")
    local view = util_createView("views/lottery/reward/LotteryOpenRewardRewardNum")
    parent:addChild(view)
    self.m_rewardNumUI = view
end
-- bottom
function LotteryOpenReward:initBottomUI()
    local parent = self:findChild("node_bottom")
    local view = util_createView("views/lottery/reward/LotteryOpenRewardBottom")
    parent:addChild(view)
    self.m_bottomUI = view
end

function LotteryOpenReward:playGuochangAct()
    -- npc说话
    self:npcSayWordStart()

    self.m_guochangAni:playAction(
        "start",
        false,
        function()
            self.m_machineUI:setVisible(true)
            --self.m_spinNode:setVisible(true)
            util_spinePlay(self.m_spinNode, "over")
            util_spineEndCallFunc(self.m_spinNode, "over", handler(self, self.playShowAct))
        end,
        60
    )
end

-- 弹出顺序：lotto机→钞票人→上UI+左上角icon→下UI→左侧个人彩券
function LotteryOpenReward:playShowAct()
    local actList = {}
    actList[#actList + 1] = {self.m_machineUI}
    actList[#actList + 1] = {self.m_npcUI}
    actList[#actList + 1] = {self.m_titleUI, self.m_bottomUI}
    -- actList[#actList + 1] = {self.m_yoursUI}

    function childPlayShowAct(_targetList, _cb)
        if #_targetList == 0 then
            _cb()
            return
        end
        for idx, target in pairs(_targetList) do
            if tolua.isnull(target) then
                break
            end

            if idx == 1 then
                target:playShowAct(_cb)
            else
                target:playShowAct()
            end
        end
    end

    self.actCoroutine =
        coroutine.create(
        function()
            for _, targetList in pairs(actList) do
                childPlayShowAct(
                    targetList,
                    function()
                        util_nextFrameFunc(
                            function()
                                util_resumeCoroutine(self.actCoroutine)
                            end
                        )
                    end
                )
                coroutine.yield()
            end
            self.actCoroutine = nil
            self:_removeBlockMask()
        end
    )

    util_resumeCoroutine(self.actCoroutine)
    self:_addBlockMask()
end

-- 更新倒计时
function LotteryOpenReward:updateTimeUI()
    local curTimeNumber = self.m_data:getCurTimeNumber()
    self.m_lbTime:setString(curTimeNumber)
end

function LotteryOpenReward:btnSkipClickEvt()
    self.m_rewardNumUI:playShowAct()
end

function LotteryOpenReward:registerListener()
    LotteryOpenReward.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "closeUI", LotteryConfig.EVENT_NAME.CLOSE_OPEN_REWARD_LAYER)
    gLobalNoticManager:addObserver(self, "btnSkipClickEvt", LotteryConfig.EVENT_NAME.SKIP_OPEN_REWARD_STEP) -- 跳过摇晃球
end

-- function LotteryOpenReward:closeUI(...)
--     -- 重置之前的背景音乐
--     local bgMusicPath = self:getBgMusicPath()
--     if bgMusicPath and bgMusicPath ~= "" then
--         gLobalSoundManager:setLockBgMusic(false)
--         gLobalSoundManager:setLockBgVolume(false)
--         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESET_BG_MUSIC)
--     end

--     LotteryOpenReward.super.closeUI(self, ...)
-- end

function LotteryOpenReward:npcSayWordStart()
    -- -- 过场动画开始说
    -- self.m_npcUI:sayWord(LotteryConfig.NPC_WORD_AUDIO_INFO.GUO_CHANG, nil, function()

    --     -- 过场动画说完 就介绍自己
    --     self.m_npcUI:sayWord(LotteryConfig.NPC_WORD_AUDIO_INFO.NPC_START, nil, function()

    --         --  介绍完自己 介绍 自己选的号码
    --         self.m_npcUI:sayWord(LotteryConfig.NPC_WORD_AUDIO_INFO.SHOW_YOURS, function()
    --             self.m_yoursUI:playShowAct()
    --         end,
    --         function()

    --         end)

    --     end)

    -- end)

    -- 秒开始播放 自己介绍的号码
    performWithDelay(
        self,
        function()
            self.m_yoursUI:playShowAct()
        end,
        9
    )

    -- 过场动画开始说
    self.m_npcUI:sayWord(
        LotteryConfig.NPC_WORD_AUDIO_INFO.OPEN_START,
        nil,
        function()
            -- 介绍完号码 开始摇奖
            self.m_npcUI:sayWord(
                LotteryConfig.NPC_WORD_AUDIO_INFO.MACHINE_START,
                function()
                    self.m_machineUI:playWobbleAct(1)
                    self.m_rewardNumUI:playShowAct()
                    self:_removeBlockMask()
                    -- 通知UI界面，让skip按钮可以点击
                    self.m_bottomUI:setSkipBtnStatus(true)
                end,
                function()
                    --gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.SHOW_FIRST_NUMBER_NPC_SAY) -- 显示摇晃出第一个号码 - npc说话
                end
            )
        end
    )
end

return LotteryOpenReward
