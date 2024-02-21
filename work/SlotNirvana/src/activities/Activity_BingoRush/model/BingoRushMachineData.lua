-- bingo比赛任务
local MachineBetsData = require "data.baseDatas.MachineBetsData"
local BetConfigData = require "data.baseDatas.BetConfigData"
local BingoRushMachineData = class("BingoRushMachineData", require "data.baseDatas.MachineData")

BingoRushMachineData.p_winTypes = {6,16,50}

--[[
    @desc: 解析关卡bet 档位信息
    time:2019-04-11 11:42:13
    @param betsData
    @return:
]]
function BingoRushMachineData:parseMachineBetsData( data )

    local betsData = MachineBetsData:create()
    betsData.p_machineName = "BingoRush"
    betsData.p_machineId = 0
    betsData.p_extraBetData = nil
    betsData.p_freeGameBetData = nil
    betsData.p_specialBets = {}      --特殊total bet 列表

    local betDatas = {}

    --获取活动数据
    self.m_data = G_GetMgr(ACTIVITY_REF.BingoRush):getRunningData()
    local bet_Data_act = self.m_data:getCurBetData()
    local gameBets = bet_Data_act.gameBets
    for index = 1,#gameBets do
        local betData = BetConfigData:create()
        betData:parseData({betId = index,totalBet = gameBets[index]})
        betDatas[#betDatas + 1] = betData
    end
    

    betsData.p_betList = betDatas      -- 对应等级可以使用的bet 列表


    betsData:updateCurBetList( )
    self.p_betsData = betsData
end

return BingoRushMachineData
