--[[
    --新版每日任务pass主界面 赛季进度
    csc 2021-06-21
]]
local DailyMissionPassSeasonProgressNode = class("DailyMissionPassSeasonProgressNode", util_require("base.BaseView"))
function DailyMissionPassSeasonProgressNode:initUI()
    self:createCsbNode(self:getCsbName())

    -- 读取csb 节点
    self.m_barProgress = self:findChild("bar_progress")
    self.m_labProgress = self:findChild("lb_progress")

    self.m_nodeReward = self:findChild("node_reward")
    self.m_sprSafeBox = self:findChild("sp_safe")

    self.m_nodeEffect_1 = self:findChild("ef_lizi")
    self.m_nodeEffect_2 = self:findChild("ef_lizi2")

    -- self.m_nodeEffect_1:stopSystem()
    self.m_nodeEffect_2:stopSystem()
    -- particle:resetSystem()
    self:updateView()
end

function DailyMissionPassSeasonProgressNode:getCsbName()
    return DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_MainLeftProgress.csb"
end

--[[
    @desc: 进度条计算逻辑是用两个等级之间的差值作为 总进度（100%）
]]
function DailyMissionPassSeasonProgressNode:updateView()
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    local curLevel = actData:getLevel()
    -- 判断当前是否满级
    if curLevel >= actData:getMaxLevel() then
        -- 显示保险箱图片
        self.m_nodeReward:removeAllChildren()
        self.m_nodeReward:setVisible(false)
        self.m_sprSafeBox:setVisible(true)
        self.m_bInSafeBox = true
    else
        self.m_nodeReward:setVisible(true)
        self.m_sprSafeBox:setVisible(false)

        local pointInfo = nil
        if actData:isThreeLinePass() then
            local triplePointInfo = actData:getTriplePointsInfo()
            pointInfo = triplePointInfo[curLevel + 1]
        else
            local payPointInfo = actData:getPayPointsInfo()
            pointInfo = payPointInfo[curLevel + 1]
        end
        -- 加载道具
        if pointInfo then
            self:addRewardNode(pointInfo)
        end
    end
    local curExp, nextExp = self:getCurrData()
    local per, strPer = self:getPercent()
    self.m_barProgress:setPercent(per)
    self.m_labProgress:setString(strPer)

    self.m_lastExp = curExp
    self.m_lastLevel = curLevel
    self.m_lastNextExp = nextExp --
    self.m_currProExp = curExp
    self.m_levelStartExp = self.m_bInSafeBox and 0 or self:getCurrLevelStartExp(curLevel)
end

function DailyMissionPassSeasonProgressNode:addRewardNode(_pointInfo)
    self.m_nodeReward:removeAllChildren()
    local payRewardNode = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassRewardCell_ThreeLine, {type = "season", lock = true})
    self.m_nodeReward:addChild(payRewardNode)
    payRewardNode:updateData(_pointInfo)
end

-- 刷新经验
function DailyMissionPassSeasonProgressNode:updateExpPro(addExp)
    if addExp == 0 then
        -- 直接更新等级显示
        self:updateView()
        gLobalViewManager:removeLoadingAnima()
        return
    end

    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    local curExp, nextExp = self:getCurrData()

    self.m_nodeEffect_2:resetSystem()
    local canOpenSafeBox = false
    --是否升级
    local isUpgrade = actData:getLevel() > self.m_lastLevel and true or false
    -- 立即停止上次的逻辑， 并且设置当前最新的数据
    if self.m_progressSchedule ~= nil then
        scheduler.unscheduleGlobal(self.m_progressSchedule)
        self.m_progressSchedule = nil
    end

    local intervalTime = 0.02
    local speedTime = 3
    if self.m_bInSafeBox then
        speedTime = 1
    end
    local speedVal = curExp - self.m_lastExp -- 得到上一次记录的经验与最新的经验值的差值 ，作为距离
    if speedVal < 100 then
        speedTime = 2 -- 如果添加的经验少，加快速度
    end
    speedVal = speedVal * intervalTime / speedTime

    -- local curProExp = curExp
    local targetProExp = isUpgrade and self.m_lastNextExp or curExp
    self.m_endProExp = self.m_lastNextExp
    -- 播放进度条动画
    self.m_progressSchedule =
        scheduler.scheduleGlobal(
        function()
            local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
            if not actData then
                return
            end
            -- 做个避免卡死的处理
            if speedVal == 0 and curExp == self.m_lastExp then
                self.m_currProExp = targetProExp
            end
            -- 线上 bug报错补丁 - 需要后续查数据 2021年07月26日11:36:41
            if self.m_currProExp == nil then
                self.m_currProExp = targetProExp
            end
            -- 不停的计算当前进度距离
            -- print("----- csc self.m_currProExp = "..self.m_currProExp .. "  targetProExp =  "..targetProExp)
            if self.m_currProExp < targetProExp then
                local newCurrProExp = math.min(self.m_currProExp + speedVal, targetProExp)
                self.m_currProExp = newCurrProExp
                self:updateProgress()
            else
                if self.m_currProExp < curExp then
                    -- 直接转换为当前等级的开始经验
                    local levelExpList = actData:getLevelExpList()
                    self.m_currProExp = levelExpList[actData:getLevel()]
                    targetProExp = curExp
                    self.m_endProExp = nextExp
                    self.m_levelStartExp = self:getCurrLevelStartExp(actData:getLevel())
                    if curExp == nextExp then
                        -- print("---- csc 接下来这一次就满级了 直接设置成保险箱经验")
                        if G_GetMgr(ACTIVITY_REF.NewPass):getInSafeBoxStatus() then
                            self.m_nodeReward:removeAllChildren()
                            self.m_nodeReward:setVisible(false)
                            self.m_sprSafeBox:setVisible(true)

                            self.m_bInSafeBox = true
                            curExp, nextExp = self:getCurrData()
                            self.m_currProExp = 0
                            targetProExp = curExp
                            self.m_endProExp = nextExp
                            self.m_levelStartExp = 0

                            -- 重新计算速度
                            speedVal = curExp * intervalTime / speedTime
                        end
                    end
                else
                    if self.m_progressSchedule then
                        scheduler.unscheduleGlobal(self.m_progressSchedule)
                        self.m_progressSchedule = nil
                    end
                    self.m_nodeEffect_2:stopSystem()
                    if self.m_bInSafeBox then
                        local curExp, nextExp = self:getCurrData()
                        if curExp == nextExp and (actData:isUnlocked() or actData:getCurrIsPayHigh()) then
                            canOpenSafeBox = true
                        end
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_PROGRESS_INCEXP_OVER, {isUpgrade = isUpgrade, canOpenSafeBox = canOpenSafeBox})
                    -- 刷新一下界面确保正确
                    self:updateView()
                end
            end
        end,
        intervalTime
    )
end

function DailyMissionPassSeasonProgressNode:updateProgress()
    -- self.m_currProExp
    local overflowExp = self.m_currProExp - self.m_levelStartExp -- 溢出的经验
    local nextNeedLevelExp = self.m_endProExp - self.m_levelStartExp -- 下一级需要的经验
    local increase = overflowExp / nextNeedLevelExp -- 占比
    local per = math.floor(increase * 100)
    local strPer = math.floor(self.m_currProExp) .. " / " .. self.m_endProExp
    -- print("---- csc overflowExp = "..overflowExp .. " nextNeedLevelExp == "..nextNeedLevelExp.. " increase = "..increase)
    -- print("---- csc per = "..per.." strPer =  "..strPer)
    self.m_barProgress:setPercent(per)
    self.m_labProgress:setString(strPer)

    --计算坐标展示粒子效果
    local cont = self.m_barProgress:getContentSize()
    local posX = cont.width * increase - cont.width / 2 -- csb 制作问题
    self.m_nodeEffect_2:setPositionX(posX)
end

function DailyMissionPassSeasonProgressNode:getMedalEndPos()
    local spMedal = self:findChild("Sp_medal")
    local worldPos = spMedal:getParent():convertToWorldSpace(cc.p(spMedal:getPosition()))
    return worldPos
end

function DailyMissionPassSeasonProgressNode:getCurrData()
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    local curExp = actData:getCurExp()
    local nextExp = actData:getLevelUpExp()
    if self.m_bInSafeBox then
        -- 展示保险箱的值
        local boxData = actData:getSafeBoxConfig()
        curExp = boxData:getCurPickNum()
        nextExp = boxData:getTotalNum()
    end
    return tonumber(curExp), tonumber(nextExp)
end

function DailyMissionPassSeasonProgressNode:getPercent()
    -- 进度计算
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    local curLevel = actData:getLevel()
    local curExp, nextExp = self:getCurrData()
    local levelExpList = actData:getLevelExpList()
    local overflowExp = curExp - levelExpList[curLevel] -- 溢出的经验
    local nextNeedLevelExp = nextExp - levelExpList[curLevel] -- 下一级需要的经验
    local increase = overflowExp / nextNeedLevelExp -- 占比
    if self.m_bInSafeBox then
        increase = curExp / nextExp
    end
    local strPer = curExp .. " / " .. nextExp -- 进度文本
    return math.floor(increase * 100), strPer
end

function DailyMissionPassSeasonProgressNode:getCurrLevelStartExp(_level)
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    local levelExpList = actData:getLevelExpList()
    return levelExpList[_level]
end

-- 重置进度条给多开保险箱使用
function DailyMissionPassSeasonProgressNode:resetExpPro()
    local curExp, nextExp = self:getCurrData()
    curExp = 0
    local per, strPer = self:getPercent()
    self.m_barProgress:setPercent(per)
    self.m_labProgress:setString(strPer)

    self.m_lastExp = 0
    self.m_lastNextExp = nextExp --
    self.m_currProExp = 0

    self:updateExpPro(nextExp)
end

function DailyMissionPassSeasonProgressNode:onExit()
    if self.m_progressSchedule then
        scheduler.unscheduleGlobal(self.m_progressSchedule)
        self.m_progressSchedule = nil
    end
end

function DailyMissionPassSeasonProgressNode:clearTimer()
    if self.m_progressSchedule then
        scheduler.unscheduleGlobal(self.m_progressSchedule)
        self.m_progressSchedule = nil
    end
end

return DailyMissionPassSeasonProgressNode
