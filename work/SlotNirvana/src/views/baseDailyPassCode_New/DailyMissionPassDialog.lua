local DailyMissionPassDialog = class("DailyMissionPassDialog", BaseLayer)

DailyMissionPassDialog.CELL_ITEM_NUM = 2 -- 每条cell 应该放 n 个道具

function DailyMissionPassDialog:ctor()
    DailyMissionPassDialog.super.ctor(self)
    self:setLandscapeCsbName(SHOP_RES_PATH.ItemBenefitBoard)
end
function DailyMissionPassDialog:initUI(_itemData,_storeType)
    DailyMissionPassDialog.super.initUI(self)
    self:paseItem(_itemData)
    self.m_listCell = {}
    self:updateView()
end

function DailyMissionPassDialog:initCsbNodes()
    self.m_listView = self:findChild("benefitsView")
end

function DailyMissionPassDialog:paseItem(_itemData)
    self.splitItemsList = {}
    for idx, itemInfo in ipairs(_itemData) do
        local newIdx = math.floor((idx-1) / self.CELL_ITEM_NUM) + 1
        if not self.splitItemsList[newIdx] then
            self.splitItemsList[newIdx] = {}
        end
        table.insert(self.splitItemsList[newIdx], itemInfo)
    end
end

function DailyMissionPassDialog:updateView()
    self.m_listView:setScrollBarEnabled(false)
    -- 加载list view
    local itemList = #self.splitItemsList

    for i = 1 ,itemList do
        local cellLayout = ccui.Layout:create()
        cellLayout:setContentSize({width = 910, height = 140})
        local cell = util_createView("views.baseDailyPassCode_New.DailyMissionPassCell")
        cell:updateView(self.splitItemsList[i])
        cellLayout:addChild(cell)
        self.m_listView:pushBackCustomItem(cellLayout)
    end

end

function DailyMissionPassDialog:clickFunc(sender)
    if self.isClose then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_close" then
        self:closeUI()
    end
end

-- 重写父类方法
function DailyMissionPassDialog:onShowedCallFunc()

end

function DailyMissionPassDialog:onEnter()
    DailyMissionPassDialog.super.onEnter(self)
end

return DailyMissionPassDialog