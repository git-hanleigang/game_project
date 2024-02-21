--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-11 16:13:57
--
local BaseReelMachine = require "Levels.BaseReel.BaseReelMachine"
local BaseMiniReelMachine = class("BaseMiniReelMachine", BaseReelMachine)

function BaseMiniReelMachine:ctor()
    BaseReelMachine.ctor(self)
end


function BaseMiniReelMachine:addObservers()
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
function BaseMiniReelMachine:initMachine()
    self.m_machineModuleName = self.m_moduleName

    self:initMachineCSB() -- 创建关卡csb信息

    self:updateBaseConfig() -- 更新关卡config.csv的配置信息
    self:updateMachineData() -- 更新滚动轮子指向、 以及更新每列的ReelColumnData
    self:initSymbolCCbNames() -- 更新最基础的信号名字
    self:initMachineData() -- 在BaseReelMachine类里面实现

    self:updateReelInfoWithMaxColumn() -- 计算最高的一列
    self:drawReelArea() -- 绘制裁剪区域

    self:initReelEffect()

    self:slotsReelRunData(
        self.m_configData.p_reelRunDatas,
        self.m_configData.p_bInclScatter,
        self.m_configData.p_bInclBonus,
        self.m_configData.p_bPlayScatterAction,
        self.m_configData.p_bPlayBonusAction
    )
end

function BaseMiniReelMachine:initMachineData()
    self:BaseMania_initCollectDataList()
    self.m_spinResultName = self.m_moduleName .. "_Datas"
    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()
end

function BaseMiniReelMachine:normalSpinBtnCall()
end
function BaseMiniReelMachine:spinResultCallFun(param)
end
function BaseMiniReelMachine:calculateLastWinCoin()
end
function BaseMiniReelMachine:setCurrSpinMode(spinMode)
    self.m_currSpinMode = spinMode
end
function BaseMiniReelMachine:getCurrSpinMode()
    return self.m_currSpinMode
end
function BaseMiniReelMachine:setGameSpinStage(spinStage)
    self.m_currSpinStage = spinStage
end
function BaseMiniReelMachine:getGameSpinStage()
    return self.m_currSpinStage
end
function BaseMiniReelMachine:setLastWinCoin(winCoin)
    self.m_lastWinCoin = winCoin
end
function BaseMiniReelMachine:getLastWinCoin()
    return self.m_lastWinCoin
end
function BaseMiniReelMachine:reelDownNotifyChangeSpinStatus()
end
function BaseMiniReelMachine:enterGamePlayMusic()
    -- do nothing
end
function BaseMiniReelMachine:changeFreeSpinModeStatus()
    -- do nothing  mini 轮子不处理 freespin 的状态
end

function BaseMiniReelMachine:checkNotifyUpdateWinCoin()
end

function BaseMiniReelMachine:playEffectNotifyNextSpinCall()
end
function BaseMiniReelMachine:checkAddQuestDoneEffectType()
end
function BaseMiniReelMachine:checkControlerReelType()
    return false
end
return BaseMiniReelMachine
