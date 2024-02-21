--[[
Author:cxc
Date: 2021-11-19 16:36:09
LastEditTime: 2021-11-19 16:36:47
LastEditors:cxc
Description: 乐透开奖界面 机器
FilePath: /SlotNirvana/src/views/lottery/reward/LotteryOpenRewardMachine.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryOpenRewardMachine = class("LotteryOpenRewardMachine", BaseView)

function LotteryOpenRewardMachine:initDatas()
    LotteryOpenRewardMachine.super.initDatas(self)

    self:initNumberDataBase()
    local data = G_GetMgr(G_REF.Lottery):getData()
    self.m_numberList = data:getHitNumberList()
end

function LotteryOpenRewardMachine:initNumberDataBase()
    self.m_whiteNumberList = {}
    for i=1, 30 do
        table.insert(self.m_whiteNumberList, i)
    end
    self.m_redNumberList = {}
    for i=1, 9 do
        table.insert(self.m_redNumberList, i)
    end
end

function LotteryOpenRewardMachine:initUI()
    LotteryOpenRewardMachine.super.initUI(self)
    
    self:initView()

    gLobalNoticManager:addObserver(self, function()
        self:playOverBallAct(true)
    end, LotteryConfig.EVENT_NAME.SKIP_OPEN_REWARD_STEP) -- 跳过摇晃球
    
    gLobalNoticManager:addObserver(self, function(target, _idx)
        if _idx == 5 then
            self:playSwitchWobbleRedAct()
        elseif _idx < 6 then
            self:playWobbleAct(_idx + 1)
        end
    end, LotteryConfig.EVENT_NAME.MACHINE_WOBBLE_NEXT_BALL) -- 机器摇晃下一个球

end

-- 初始化节点
function LotteryOpenRewardMachine:initCsbNodes()
    LotteryOpenRewardMachine.super.initCsbNodes(self)

    self.m_resultBallNodeList = {} 
end

function LotteryOpenRewardMachine:getCsbName()
    return "Lottery/csd/Drawlottery/Lottery_Drawlottery_machine.csb"
end

function LotteryOpenRewardMachine:initView()
    -- 机器spine
    -- local parent = self:findChild("spine")
    -- local spineNode = util_spineCreate("Lottery/spine/quxian/quxian", true, true)
    -- parent:addChild(spineNode)
    -- util_spinePlay(spineNode, "idle", false)
    -- self.m_machineSpine = spineNode

    -- -- 旋转碰撞的球
    -- self.m_spineBallNodeList = {}
    -- local whiteNumberList = clone(self.m_whiteNumberList)
    -- for i=1, 17 do
    --     local spineBall = self:createBallSpine()
    --     spineBall:setRotation(util_random(0, 360))
    --     util_spinePushBindNode(spineNode,  string.format("%02d", i) .. "qiu", spineBall)
    --     table.insert(self.m_spineBallNodeList, spineBall)
    --     local idx = util_random(1, #whiteNumberList)
    --     local random = whiteNumberList[idx]
    --     util_spinePlay(spineBall, "qiu" .. random, false)
    --     table.remove(whiteNumberList, idx)
    -- end

    -- 中奖的球
    self.m_resultBallNodeList = {} 
    for i=1, #self.m_numberList do
        local number = self.m_numberList[i]
        local parent = self:findChild("node_qiu" .. i)
        local nodeBall = self:createBallItem(number, i == #self.m_numberList)
        nodeBall:setRotation(util_random(0, 360))
        parent:addChild(nodeBall)
        table.insert(self.m_resultBallNodeList, nodeBall)
    end
end

function LotteryOpenRewardMachine:initSpineUI()
    LotteryOpenRewardMachine.super.initSpineUI(self)

    -- 机器spine
    local parent = self:findChild("spine")
    local spineNode = util_spineCreate("Lottery/spine/quxian/quxian", true, true, 1)
    parent:addChild(spineNode)
    util_spinePlay(spineNode, "idle", false)
    self.m_machineSpine = spineNode

    -- 旋转碰撞的球
    self.m_spineBallNodeList = {}
    local whiteNumberList = clone(self.m_whiteNumberList)
    for i=1, 17 do
        local spineBall = self:createBallSpine()
        spineBall:setRotation(util_random(0, 360))
        util_spinePushBindNode(spineNode,  string.format("%02d", i) .. "qiu", spineBall)
        table.insert(self.m_spineBallNodeList, spineBall)
        local idx = util_random(1, #whiteNumberList)
        local random = whiteNumberList[idx]
        util_spinePlay(spineBall, "qiu" .. random, false)
        table.remove(whiteNumberList, idx)
    end
end

function LotteryOpenRewardMachine:createBallSpine()
    local spineQiuNode = util_spineCreate("Lottery/spine/qiu/skeleton", true, true, 1)
    return spineQiuNode
end

function LotteryOpenRewardMachine:createBallItem(_number, _bRed)
    local view = util_createView("views.lottery.base.LotteryBall", {number = _number, bRed = _bRed})
    view:setVisible(false)
    return view
end

-- 更新球 的显隐
function LotteryOpenRewardMachine:updateBallVisible(_idx)
    for i=1, #self.m_resultBallNodeList do
        local nodeBall = self.m_resultBallNodeList[i]
        nodeBall:setVisible(_idx >= i)
    end
end

function LotteryOpenRewardMachine:playShowAct(_cb)
    self:runCsbAction("show", false, _cb, 60)
end

-- 机器摇晃
function LotteryOpenRewardMachine:playWobbleAct(_idx)
    local number = self.m_numberList[_idx]
    local databaseNumberList = {}
    if _idx < #self.m_numberList then
        local databaseIdx
        for i, _number in ipairs(self.m_whiteNumberList) do
            if _number == number then
                databaseIdx = i
                break
            end
        end
        if databaseIdx then
            table.remove(self.m_whiteNumberList, databaseIdx)
        end
        databaseNumberList = self.m_whiteNumberList
    else
        -- 红球number就是idx
        table.remove(self.m_redNumberList, number)
        databaseNumberList = self.m_redNumberList
    end

    local bRed = _idx == #self.m_numberList
    local aniName = bRed and "h" or "qiu"
    local maxCount = bRed and 9 or 30
    for i=1, #self.m_spineBallNodeList do
        local spineBall = self.m_spineBallNodeList[i]
        local bShow = i <= maxCount
        if bShow then
            local random = number
            if i  < math.min(maxCount, #self.m_spineBallNodeList) then
                local idx = util_random(1, #databaseNumberList)
                random = databaseNumberList[idx]
            end
            util_spinePlay(spineBall, aniName .. random, false)
            spineBall:setRotation(util_random(0, 360))
        end
        spineBall:setVisible(bShow)
    end

    util_spinePlay(self.m_machineSpine, "start", false)
    util_spineEndCallFunc(self.m_machineSpine, "start", function()
        if self.m_bStopWobble then
            return
        end
        
        self:playCreateBallAct(_idx)
    end)

    gLobalSoundManager:playSound("Lottery/sounds/Lottery_machine_wobble.mp3")
    gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.SHOW_FIRST_NUMBER_NPC_SAY, _idx) -- 显示摇晃出第一个号码 - npc说话

end

-- 机器吐球
function LotteryOpenRewardMachine:playCreateBallAct(_idx)
    performWithDelay(
        self,
        function()
            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.SHOW_OPEN_NUMBER_UI, _idx) -- 显示摇晃出来的号码
        end,
        0.6
    )

    self:runCsbAction("start" .. _idx, false, function()
        if self.m_bStopWobble then
            return
        end

        if _idx < #self.m_numberList then
            
            local nextIdx = _idx + 1
            if nextIdx == #self.m_numberList then
                -- 摇红球 过渡动画
                -- self:playSwitchWobbleRedAct()
                return
            end
            -- self:playWobbleAct(nextIdx)
        else
            self:playOverBallAct()
        end
    end, 60)

    self:updateBallVisible(_idx)

    gLobalSoundManager:playSound("Lottery/sounds/Lottery_machine_generate_number.mp3")
end

-- 摇红球 过渡动画
function LotteryOpenRewardMachine:playSwitchWobbleRedAct()
    self:runCsbAction("actionframe", false, function()
        self:playWobbleAct(#self.m_numberList)
    end, 60)
    gLobalSoundManager:playSound("Lottery/sounds/Lottery_machine_switch_red_ball.mp3")
end

-- 机器选号完成 完成动画
function LotteryOpenRewardMachine:playOverBallAct(_bSkip)
    if _bSkip then
        util_spinePlay(self.m_machineSpine, "idle", false)
        self.m_bStopWobble = true
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.MACHINE_OVER_FORCE_STOP_NPC_AUDIO) -- 机器摇晃玩强制结束npc说话
    end
    self:runCsbAction("over")
    self:updateBallVisible(#self.m_resultBallNodeList)
    gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.SHOW_OPEN_NUMBER_UI, #self.m_numberList) -- 显示摇晃出来的号码
    gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.MACHINE_GENERATE_NUMBER_OVER) -- 摇号机器摇号完毕
end

return LotteryOpenRewardMachine