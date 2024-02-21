--[[
    卡册展示界面
    卡册中的一个卡组 基类
]]
local BaseView = util_require("base.BaseView")
local CardAlbumCellUnitBase = class(CardAlbumCellUnitBase, BaseView)
CardAlbumCellUnitBase.m_cellData = nil -- 单个卡组的数据

-- 初始化UI --
function CardAlbumCellUnitBase:initUI()
    self:initView()
end

function CardAlbumCellUnitBase:initView()
    local res = self:getAlbumCellUnitRes()
    self:createCsbNode(res)
    self:initNode()
end

-- 子类重写
function CardAlbumCellUnitBase:getAlbumCellUnitRes()
    return ""
end

function CardAlbumCellUnitBase:initNode()
    self.m_cardIcon      = self:findChild("card_icon")
    self.m_number        = self:findChild("number")
    self.m_cardCompleted = self:findChild("card_completed")
    self.m_touch         = self:findChild("touch")

    self.m_touch:setSwallowTouches(false)
    self:addNodeClicked(self.m_touch)
end

function CardAlbumCellUnitBase:updateCell(clanIndex, cellData)
    self.m_clanIndex = clanIndex
    self.m_cellData = cellData

    -- 卡组logo
    local icon = CardResConfig.getCardClanIcon(cellData.clanId)
    util_changeTexture(self.m_cardIcon, icon)

    -- 章节卡牌收集进度，【类型展示，重复卡不计数】
    local count = CardSysRuntimeMgr:getClanCardTypeCount(cellData.cards)
    self.m_number:setString(string.format("%d/%d", count, #cellData.cards))

    -- 章节卡牌集齐标识，如果本章节的卡牌已经集齐，则需要添加集齐标识
    self.m_cardCompleted:setVisible(count >= #cellData.cards)
end

-- 点击按钮事件
function CardAlbumCellUnitBase:clickMyFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "touch" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- -- 记录当前选择的卡组编号        
        -- CardSysRuntimeMgr:setClanSelectIndex(self.m_clanIndex)
        
        -- TEST 显示卡组选择界面 --
        CardSysManager:showCardClanView(self.m_clanIndex, true)
    end
end

-- 节点选中的事件 --
function CardAlbumCellUnitBase:addNodeClicked( node )
    if not node then
        return
    end
    node:addTouchEventListener(handler(self, self.nodeClickedEvent))
end
function CardAlbumCellUnitBase:nodeClickedEvent( sender ,eventType )
    if eventType == ccui.TouchEventType.began then
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender)
        local beginPos  = sender:getTouchBeganPosition()
        local endPos    = sender:getTouchEndPosition()
        local offy      = math.abs(endPos.y-beginPos.y)
        if offy<50 then
            self:clickMyFunc(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        -- print("Touch Cancelled")
        self:clickEndFunc(sender)
    end
end

return CardAlbumCellUnitBase