--
-- 关卡bet信息数据
--
-- Date: 2019-04-10 17:52:52
--

local BetConfigData = require "data.baseDatas.BetConfigData"

local MachineBetsData = class("MachineBetsData")

MachineBetsData.p_machineName = nil -- 关卡名字
MachineBetsData.p_machineId = nil -- 关卡id
MachineBetsData.p_betList = nil -- 对应等级可以使用的bet 列表
MachineBetsData.p_freeGameBetData = nil -- 只作为免费spin次数使用
MachineBetsData.p_extraBetData = nil -- feature 触发选择的bet ， 可以为空
MachineBetsData.p_specialBets = nil -- 特殊total bet 列表
--特殊玩法触发后因系统活动bet发生修改后,玩法结束后切换bet需要特殊bet进行修改
MachineBetsData.p_specNewBet = nil
MachineBetsData.p_curBetList = nil -- 当前可以使用的bet 列表

function MachineBetsData:ctor()
    self._preMaxBetCfgData = nil -- 上次spin 最大bet data
    self._curMaxBetCfgData = nil -- 本次最新 最大bet data
end

--[[
    @desc: 更新当前使用的最终 bet 列表
    time:2019-04-11 21:00:16
    @return:
]]
function MachineBetsData:updateCurBetList()
    self.p_curBetList = {}

    for i = 1, #self.p_betList do
        local betData = self.p_betList[i]
        self.p_curBetList[#self.p_curBetList + 1] = betData
    end

    table.sort(
        self.p_curBetList,
        function(a, b)
            if a.p_totalBetValue < b.p_totalBetValue then
                return true
            end
            return false
        end
    )

    if self.p_extraBetData ~= nil then
        -- 先判断当前 p_extraBetData 是否处于新的bet列表中
        local bExist = false
        for i = 1, #self.p_curBetList do
            if self.p_curBetList[i].p_betId == self.p_extraBetData.p_betId then
                -- 上次 feature 中的total bet 在这次列表中存在,不做任何操作
                bExist = true
                break
            end
        end

        if bExist == false then
            local nCount = #self.p_curBetList
            for i = 1, nCount do
                if self.p_curBetList[i].p_totalBetValue > self.p_extraBetData.p_totalBetValue then
                    table.insert(self.p_curBetList, i, self.p_extraBetData)
                    break
                elseif nCount == i then
                    table.insert(self.p_curBetList, self.p_extraBetData)
                end
            end
        end
    end

    if self.p_freeGameBetData ~= nil then
        -- 先判断当前 p_freeGameBetData 是否处于新的bet列表中
        local bExist = false
        for i = 1, #self.p_curBetList do
            if self.p_curBetList[i].p_betId == self.p_freeGameBetData.p_betId then
                --  在这次列表中存在,不做任何操作
                bExist = true
                break
            end
        end
        if bExist == false then
            for i = 1, #self.p_curBetList do
                if self.p_curBetList[i].p_totalBetValue > self.p_freeGameBetData.p_totalBetValue then
                    table.insert(self.p_curBetList, i, self.p_freeGameBetData)
                    break
                end
            end
        end
    end

    self:upodateMaxBetIdInfo()
end

-- 更新最大spinBet信息
function MachineBetsData:upodateMaxBetIdInfo()
    if not self.p_curBetList or table.nums(self.p_curBetList) <= 0 then
        return
    end

    self._preMaxBetCfgData = self._curMaxBetCfgData
    self._curMaxBetCfgData = self.p_curBetList[#self.p_curBetList]
end
-- 检查是否触发新的 最大BetId
function MachineBetsData:checkNewMaxBetActive()
    if not self._preMaxBetCfgData or not self._curMaxBetCfgData then
        return
    end
    return self._curMaxBetCfgData.p_betId ~= self._preMaxBetCfgData.p_betId
end

-- 获取最大 bei 信息
function MachineBetsData:getMaxBetCfgData()
    return self._curMaxBetCfgData, self._preMaxBetCfgData
end

return MachineBetsData
