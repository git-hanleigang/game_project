---
--island
--2017年8月31日
--SlotsReelData.lua
--
-- 滚动期间的数据， 所有玩法方面可以对此进行干预

-- 针对于 SlotParent 父节点的order 层级关系
GD.REEL_SYMBOL_ORDER = {  -- 基本来说这四个层级就够用了
    REEL_ORDER_1 = 1000,  -- 默认都是此层级 ， 例如1~9信号
    REEL_ORDER_2 = 2000,  -- 特殊层级，wild
    REEL_ORDER_2_1 = 2200, -- 例如特殊或者比较大的 bonus 特殊关卡自行处理  等
    REEL_ORDER_2_2 = 2300, -- 例如特殊或者比较大的 scatter 特殊关卡自行处理  等
    REEL_ORDER_MASK = 2500, -- 滚动时遮罩
    REEL_ORDER_3 = 3000,  -- 尤其突出显示效果
    REEL_ORDER_4 = 4000   -- 备用 
}

local SlotsReelData = class("SlotsReelData")

SlotsReelData.m_isLastSymbol = nil  -- 是否为最终的信号
SlotsReelData.m_rowIndex = nil --  最终信号的行列 对应到 m_stcValidSymbolMatrix 中的位置
SlotsReelData.m_columnIndex = nil --    
SlotsReelData.m_ccbName = nil
SlotsReelData.m_symbolType = nil -- 

SlotsReelData.m_specShow = nil -- 是否特殊显示 , 起始位置向后干预对应行(指的是同一列中的行)
SlotsReelData.m_showOrder = nil -- 显示层级 
SlotsReelData.m_symbolTag = nil -- tag
SlotsReelData.m_bInLine = nil   -- 是否参与连线
SlotsReelData.p_layerTag = nil   -- 是否参与连线
SlotsReelData.m_reelDownAnima = nil
SlotsReelData.m_reelDownAnimaSound = nil -- 播放动画时的音效
-- 构造函数

function SlotsReelData:ctor()
    self:clear()
end

---
-- 恢复税局
function SlotsReelData:clear()
    self.m_bInLine = true
    self.m_isLastSymbol = false
    self.m_specShow = false
    self.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1  -- 初始化为特殊信号层级
    
    self.m_rowIndex = nil
    self.m_columnIndex = nil
    self.m_reelDownAnima = nil
    
    self.m_randomSymbolType = nil
    self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    self.m_symbolTag = SYMBOL_NODE_TAG  --默认tag值 用于标识特殊信号与普通信号
end

function SlotsReelData:convertNormal()
    self.m_isLastSymbol = false
    -- 留作后续扩展
end


return SlotsReelData