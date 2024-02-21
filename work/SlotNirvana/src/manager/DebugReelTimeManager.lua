---
--zhpx
--2017年12月30日
--DebugReelTimeManager.lua
--
local DebugReelTimeManager = class("DebugReelTimeManager")
require("socket")

DebugReelTimeManager.m_instance = nil
DebugReelTimeManager.m_Machine = nil
-- 构造函数
function DebugReelTimeManager:ctor()
   
end

function DebugReelTimeManager:getInstance()
    if DebugReelTimeManager.m_instance == nil then
        DebugReelTimeManager.m_instance = DebugReelTimeManager.new()
    end
    return DebugReelTimeManager.m_instance
end

--设定时间
function DebugReelTimeManager:recvStartTime()
 
end

function DebugReelTimeManager:updateConfig(info)

    local reelRunDatas = {}

    local strList = util_split(info.reelRunDatas,";")
    if strList and #strList>=2 then
        local numList = {}
        local numFrist = tonumber(strList[1])
        local numSpan = tonumber(strList[2])
        if numFrist and numSpan then
            for i=1,self.m_Machine.m_iReelColumnNum do
                numList[i] = numFrist + numSpan*(i-1)
            end
            -- globalData.slotRunData.levelConfigData.p_reelRunDatas = numList
            reelRunDatas = numList
        end
    end
    --设置machine滚动参数
    self.m_Machine:slotsReelRunData(reelRunDatas,self.m_Machine.m_configData.p_bInclScatter
    ,self.m_Machine.m_configData.p_bInclBonus,self.m_Machine.m_configData.p_bPlayScatterAction
    ,self.m_Machine.m_configData.p_bPlayBonusAction)
end
return DebugReelTimeManager