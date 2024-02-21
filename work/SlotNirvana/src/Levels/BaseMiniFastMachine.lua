--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-13 18:15:48
--
local BaseFastMachine = require "Levels.BaseFastMachine" -- 先用FastMachine 以后换成金鑫最新的股弄懂
local BaseMiniFastMachine = class("BaseMiniFastMachine", BaseFastMachine)
function BaseMiniFastMachine:ctor()
    BaseFastMachine.ctor(self)
end

function BaseMiniFastMachine:addObservers()
    gLobalNoticManager:addObserver(self, self.quicklyStopReel, ViewEventType.QUICKLY_SPIN_EFFECT)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_pauseRef = self.m_pauseRef + 1
            Target:pauseMachine()
        end,
        ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_pauseRef = math.max(self.m_pauseRef - 1, 0)
            if self.m_pauseRef <= 0 then
                Target:resumeMachine()
            end
        end,
        ViewEventType.NOTIFY_RESUME_SLOTSMACHINE
    )
end

--[[
    @desc: 处理MINI轮子的初始化， 去掉了很多主轮子的内容
    time:2020-07-13 20:33:27
]]
function BaseMiniFastMachine:initMachine()
    self.m_machineModuleName = self.m_moduleName

    self:initMachineCSB() -- 创建关卡csb信息

    self:updateBaseConfig() -- 更新关卡config.csv的配置信息
    self:updateMachineData() -- 更新滚动轮子指向、 以及更新每列的ReelColumnData
    self:initSymbolCCbNames() -- 更新最基础的信号名字
    self:initMachineData() -- 在BaseSlotoManiaMachine类里面实现

    self:drawReelArea() -- 绘制裁剪区域

    self:updateReelInfoWithMaxColumn() -- 计算最高的一列

    self:initReelEffect()

    self:slotsReelRunData(
        self.m_configData.p_reelRunDatas,
        self.m_configData.p_bInclScatter,
        self.m_configData.p_bInclBonus,
        self.m_configData.p_bPlayScatterAction,
        self.m_configData.p_bPlayBonusAction
    )
end

function BaseMiniFastMachine:initMachineData()
    self:BaseMania_initCollectDataList()
    self.m_spinResultName = self.m_moduleName .. "_Datas"
    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()
    self:checkHasBigSymbol()
end

function BaseMiniFastMachine:normalSpinBtnCall()
end
function BaseMiniFastMachine:spinResultCallFun(param)
end
function BaseMiniFastMachine:calculateLastWinCoin()
end
function BaseMiniFastMachine:setCurrSpinMode(spinMode)
    self.m_currSpinMode = spinMode
end
function BaseMiniFastMachine:getCurrSpinMode()
    return self.m_currSpinMode
end
function BaseMiniFastMachine:setGameSpinStage(spinStage)
    self.m_currSpinStage = spinStage
end
function BaseMiniFastMachine:getGameSpinStage()
    return self.m_currSpinStage
end
function BaseMiniFastMachine:setLastWinCoin(winCoin)
    self.m_lastWinCoin = winCoin
end
function BaseMiniFastMachine:getLastWinCoin()
    return self.m_lastWinCoin
end
function BaseMiniFastMachine:reelDownNotifyChangeSpinStatus()
end
function BaseMiniFastMachine:enterGamePlayMusic()
    -- do nothing
end
function BaseMiniFastMachine:changeFreeSpinModeStatus()
    -- do nothing  mini 轮子不处理 freespin 的状态
end

function BaseMiniFastMachine:checkNotifyUpdateWinCoin()
end

function BaseMiniFastMachine:playEffectNotifyNextSpinCall()
end
function BaseMiniFastMachine:checkAddQuestDoneEffectType()
end

function BaseMiniFastMachine:checkControlerReelType()
    return false
end

return BaseMiniFastMachine
