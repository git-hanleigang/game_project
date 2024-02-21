---
--zhpx
--2017年10月26日
--SlotsReelRunData.lua
--构造长滚信息

local SlotsReelRunData = class("SlotsReelRunData")

SlotsReelRunData.m_slotsNodeInfo = nil  --bonus Scatter位置坐标可以存放多个
SlotsReelRunData.m_reelRunLen = nil         --长滚长度
SlotsReelRunData.m_bNextReelLongRun = nil         --是否长滚
SlotsReelRunData.m_bReelLongRun = nil       --控制该列是否长滚
SlotsReelRunData.m_bInclScatter = nil     --是否计算scatter
SlotsReelRunData.m_bInclBonus = nil       --是否计算bonus
SlotsReelRunData.m_bPlayScatterAction = nil  --是否播放scatter动画
SlotsReelRunData.m_bPlayBonusAction = nil       --是否计算bonus动画
SlotsReelRunData.initInfo = nil

-- 构造函数
function SlotsReelRunData:ctor()
self.initInfo = {
    reelRunLen = -1,
    autoSpinreelRunLen = -1,--autoSpin时滚动长度
    freeSpinreelRunLen = -1,--freeSpin时滚动长度
    bReelRun = false,
    bInclScatter = true,
    bInclBonus = true,
    m_bPlayScatterAction = true,
    m_bPlayBonusAction = false
}
    self.m_slotsNodeInfo = nil  --bonus Scatter位置坐标可以存放多个
    self.m_reelRunLen = nil         --长滚长度
    self.m_bNextReelLongRun = nil         --是否长滚
    self.m_bReelLongRun = nil   
    self.m_bInclScatter = nil     --是否计算scatter
    self.m_bInclBonus = nil       --是否计算bonus
    self.m_bPlayScatterAction = nil  --是否播放scatter动画
    self.m_bPlayBonusAction = nil       --是否计算bonus动画
end

---
--创建信息之后调用 
--@param runLens int 默认长度
--@param bInclScatter bool 是否计算scatter
--@param bInclBonus bool 是否计算Bonus
--@param bPlayScatterAction bool 是否播放Bonus动画 
--@param bPlayBonusAction bool 是否播放Bonus动画
function SlotsReelRunData:initReelRunInfo(runLens, bInclScatter , bInclBonus ,bPlayScatterAction, bPlayBonusAction,autoSpinrunLens,freeSpinrunLens)
    if runLens == nil or runLens <=0 then
       assert(false,"滚动长度设置错误！")
    else 
        self.initInfo.reelRunLen = runLens
    end

    if autoSpinrunLens == nil or autoSpinrunLens <= 0 then
        self.initInfo.autoSpinreelRunLen = self.initInfo.reelRunLen
    else
        self.initInfo.autoSpinreelRunLen = autoSpinrunLens
    end
    if freeSpinrunLens == nil or freeSpinrunLens <= 0 then
        self.initInfo.freeSpinreelRunLen = self.initInfo.reelRunLen
    else
        self.initInfo.freeSpinreelRunLen = freeSpinrunLens
    end
    
    
    if bInclScatter ~= nil then
        self.initInfo.bInclScatter = bInclScatter
    end
    
    if bInclBonus ~= nil then
        self.initInfo.bInclBonus = bInclBonus
    end

    if bPlayScatterAction ~= nil then
        self.initInfo.bPlayScatterAction = bPlayScatterAction
    end
    
    if bPlayBonusAction ~= nil then
        self.initInfo.bPlayBonusAction = bPlayBonusAction
    end
   
    self:clear()
end

---初始化调用
--
function SlotsReelRunData:clear()
    self.m_slotsNodeInfo = nil 
    
    if self.initInfo.reelRunLen == -1 then
        assert(false,"new之后没有调用initReelRunInfo 初始化数据")
    end

    self.m_reelRunLen = self.initInfo.reelRunLen
    self.m_bNextReelLongRun = self.initInfo.bReelRun        
    self.m_bInclScatter = self.initInfo.bInclScatter    
    self.m_bInclBonus = self.initInfo.bInclBonus      
    self.m_bPlayScatterAction = self.initInfo.bPlayScatterAction
    self.m_bPlayBonusAction = self.initInfo.bPlayBonusAction   
    self.m_bReelLongRun = true
end
--将滚动长度设置为autospin的滚动长度
function SlotsReelRunData:setReelRunLenToAutospinReelRunLen()
    if self.initInfo.autoSpinreelRunLen then
        self.m_reelRunLen = self.initInfo.autoSpinreelRunLen
    end
end

--将滚动长度设置为freespin的滚动长度
function SlotsReelRunData:setReelRunLenToFreespinReelRunLen()
    if self.initInfo.freeSpinreelRunLen then
        self.m_reelRunLen = self.initInfo.freeSpinreelRunLen
    end
end
---
--添加坐标
--播放动画的坐标
--@param posX int 节点的x坐标
--@param posY int 节点的y坐标
--@param bPlayAnima bool 是否播放动画
--@param cSoundName string 播放音效名字 为nil 播放默认的scatter bonus音效  
function SlotsReelRunData:addPos(posX, posY, bPlayAnima, strSoundName)
    local bPlayNodeAnima = nil
    local soundName = nil
    
    if bPlayAnima == nil then
        bPlayNodeAnima = true
    else
        bPlayNodeAnima = bPlayAnima
    end
    
    if strSoundName ~= nil then
        soundName = strSoundName
    end
    
    local posInfo = {x = posX, y = posY, bIsPlay = bPlayNodeAnima, strSoundName = soundName}
    
    if self.m_slotsNodeInfo == nil  then
    	self.m_slotsNodeInfo = {}
    end
    self.m_slotsNodeInfo[#self.m_slotsNodeInfo + 1 ] = posInfo
end

---
--设置是否长滚
function SlotsReelRunData:setNextReelLongRun(bRun)
    self.m_bNextReelLongRun = bRun
end

---
--得到是否长滚
function SlotsReelRunData:getNextReelLongRun()
    return self.m_bNextReelLongRun
end

---
--设置初始长度
function SlotsReelRunData:setInitReelRunLen(len)
    self.initInfo.reelRunLen = len
end

---
--得到初始长度
function SlotsReelRunData:getInitReelRunLen()
    return self.initInfo.reelRunLen 
end



---
--设置长滚长度
function SlotsReelRunData:setReelRunLen(len)
    self.m_reelRunLen = len
end

---
--得到长滚长度
function SlotsReelRunData:getReelRunLen()
    return self.m_reelRunLen
end

---
--返回所有小块信息
function SlotsReelRunData:getSlotsNodeInfo()
    return self.m_slotsNodeInfo
end

---
--设置本列是否长滚
function SlotsReelRunData:setReelLongRun(bStatus)
    self.m_bReelLongRun = bStatus
end

---
--获取本列是否长滚
function SlotsReelRunData:getReelLongRun()
    return self.m_bReelLongRun 
end

--得到特殊图标是否参加长滚判断 是否播放动画
function SlotsReelRunData:getSpeicalSybolRunInfo(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
        
        return self.m_bInclScatter, self.m_bPlayScatterAction
        
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
    
        return self.m_bInclBonus, self.m_bPlayBonusAction
        
    end
end


-- function SlotsReelRunData:()
    
-- end

return SlotsReelRunData