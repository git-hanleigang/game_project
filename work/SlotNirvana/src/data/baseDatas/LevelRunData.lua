--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-12 14:15:29
--

local LevelRunData = class("LevelRunData")

require("socket")

LevelRunData.m_RunDataList = nil


LevelRunData.p_reelMachineConfigName = 1 --关卡配置文件名称
LevelRunData.p_reelRunDatas = 2 --假滚数量配置
LevelRunData.p_reelMoveSpeed = 3  --滚动速度配置
LevelRunData.p_reelResTime = 4 --回弹时间
LevelRunData.p_reelDownTime = 5 --过落时间
LevelRunData.p_reelResDis = 6 --回弹距离
LevelRunData.p_reelBeginJumpTime = 7 --点击spin向上跳的时间
LevelRunData.p_reelBeginJumpHigh = 8 --点击spin向上跳的高度

function LevelRunData:ctor()


    
    self.m_RunDataList = {}

    -- configData csv表里的基础数据结构
    -- configData.p_reelMachineConfigName = data[1] --关卡配置config名称
    -- configData.p_reelRunDatas = data[2] --假滚数量配置
    -- configData.p_reelMoveSpeed = data[3] --滚动速度配置
    -- configData.p_reelResTime = data[4] --回弹时间
    -- configData.p_reelDownTime = data[5] --过落时间
    -- configData.p_reelResDis = data[6] --回弹距离
    -- configData.p_reelBeginJumpTime = data[7] --点击spin向上跳的时间
    -- configData.p_reelBeginJumpHigh = data[8] --点击spin向上跳的高度

    
end

--读取关卡滚动基础配置信息
function LevelRunData:parseLevelRunConfig( levelConfigs )
    
    if self.m_RunDataList and #self.m_RunDataList > 0 then
        self.m_RunDataList = {}
    end

    for i=1,#levelConfigs do

        local data = levelConfigs[i]

    
        local configData = {}
        if data[1] then
            configData[self.p_reelMachineConfigName] = tostring(data[1]) --关卡配置config名称
        end

        if data[2] then
            configData[self.p_reelRunDatas] = tostring(data[2]) --假滚数量配置
        end

        if data[3] then
            configData[self.p_reelMoveSpeed] = tostring(data[3])  --滚动速度配置
        end

        if data[4] then
            configData[self.p_reelResTime] = tostring(data[4]) --回弹时间
        end

        if data[5] then
            configData[self.p_reelDownTime] = tostring(data[5])--过落时间
        end

        if data[6] then
            configData[self.p_reelResDis] = tostring(data[6])--回弹距离
        end

        if data[7] then
            configData[self.p_reelBeginJumpTime] = tostring(data[7])--点击spin向上跳的时间
        end

        if data[8] then
            configData[self.p_reelBeginJumpHigh] = tostring(data[8])--点击spin向上跳的高度
        end

        
        table.insert(self.m_RunDataList,configData)
        
    end
end

function LevelRunData:getReelRunCofingData( machineConfigName , dataType )
    
    if machineConfigName and dataType then
        for i=1,#self.m_RunDataList do
            local data = self.m_RunDataList[i]
            
            if data[self.p_reelMachineConfigName]  then
                local name = data[self.p_reelMachineConfigName] .. ".csv"
                if  name  == machineConfigName then
    
                    if data[dataType] and data[dataType] ~= "" then
                    
                        return data[dataType]
                    end
                    
                end
    
            end
    
        end
    end
    
end


return  LevelRunData