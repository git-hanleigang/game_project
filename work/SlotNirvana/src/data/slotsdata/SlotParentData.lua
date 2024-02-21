

---
--island
--2017年11月15日
--SlotParentData.lua
--

local SlotParentData = class("SlotParentData")

--SlotParentData.testPro = nil  --创建属性

SlotParentData.cloumnIndex = nil -- 当前列的信息
SlotParentData.slotParent = nil -- 滚动列的父节点
SlotParentData.slotParentBig = nil --滚动列的父节点 大图标专用层
SlotParentData.rowNum = nil
SlotParentData.startX = nil --当前列的起始格子位置， 初始化时设置，以后不更改
SlotParentData.moveDistance = 0
SlotParentData.moveL = nil -- 移动距离

-- SlotParentData.gourpIndex = nil -- 滚动到了哪一组信息
-- SlotParentData.rowIndex = nil -- 滚动到了哪一行，   不会被reset
-- SlotParentData.p_maxRowIndex = nil   -- 不会被reset


SlotParentData.symbolType = -100  -- -100表明未创建  不会被reset ,只是在创建时 改变
SlotParentData.moveSpeed = nil
SlotParentData.moveDownCallFun = nil -- 滚动停止时回调函数

SlotParentData.lastReelIndex = nil -- 真数据返回后的滚动索引
SlotParentData.beginReelIndex = nil -- 假数据开始的索引
SlotParentData.reelDatas = nil -- 滚动假数据列表， 会根据轮盘处于不同状态数据不同

SlotParentData.m_isLastSymbol = nil	

SlotParentData.order = nil
SlotParentData.tag = nil
SlotParentData.reelDownAnima = nil
SlotParentData.layerTag = nil

SlotParentData.isLastNode = false -- 是否为最后节点 
SlotParentData.isReeling = false -- 是否在滚动中
SlotParentData.isDone = false --完全滚动完毕
SlotParentData.isHide = false --是否隐藏
SlotParentData.isResActionDone = false --

SlotParentData.ccbName = nil --下一个小块动画名称
SlotParentData.slotNodeH = nil --下一个小块高度
SlotParentData.fillCount = nil --大信号补块
-- 构造函数
function SlotParentData:ctor()
    printInfo("xcyy : %s","")
end

function SlotParentData:reset()


    self.moveL = 0
    self.preNode = nil
    self.isLastNode = false
    self.isReeling  = false
    self.isDone = false
    self.isResActionDone = false
    self.moveDistance = 0
    self.m_isLastSymbol = false
    self.order = 0
    self.tag = 0
    
    self.moveSpeed = nil
    self.reelDownAnima = nil
    self.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

    self.isHide = false
    self.fillCount = 0
end

function SlotParentData:clear()
    self.slotParent = nil
end



return SlotParentData
