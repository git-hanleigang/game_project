local TestDataView=class("TestDataView",util_require("base.BaseView"))


TestDataView.level_cell = nil


function TestDataView:initUI()
    self:createCsbNode("TestData/TestDataView.csb")
    self.cashInfo= {}
    self.levelInfo = {}
    self:initView()
end

function TestDataView:initView(  )
    self:initCashInfo()
    self:initLevleInfo()
end

function TestDataView:initLevleInfo( )
    local levelInfo = globalTestDataManager:getLevelInfo()
    local list = self:findChild("list")
    for i,v in ipairs(levelInfo) do
        local cell = util_createView("views.TestData.TestDataItem",v)
        local layout=ccui.Layout:create()
        layout:setContentSize({width=500,height=50})
        layout:addChild(cell)
        cell:setPosition(0,25)
        list:pushBackCustomItem(layout)
        self.levelInfo[#self.levelInfo+ 1] = cell
    end
end

function TestDataView:upDateLevelInfo( )
    local levelInfo = globalTestDataManager:getLevelInfo()
    self.levelInfo[#levelInfo - 1]:initData(levelInfo[#levelInfo - 1])
    local list = self:findChild("list")
    local cell = util_createView("views.TestData.TestDataItem",levelInfo[#levelInfo])
    local layout=ccui.Layout:create()
    layout:setContentSize({width=500,height=50})
    layout:addChild(cell)
    cell:setPosition(0,25)
    list:pushBackCustomItem(layout)
    self.levelInfo[#self.levelInfo+ 1] = cell
end

function TestDataView:initCashInfo()
    local cashInfo = globalTestDataManager:getCashInfo()
    for i=1,6 do 
        local cell = self:findChild("cell_"..i)
        self:initCellInfo(cell,i,cashInfo[i])
    end
end

function TestDataView:initCellInfo(cell,index,cashInfo)
    if not cell then
        return
    end
    
    local spinTimes = cell:getChildByName("spinTimes")
    spinTimes:setString("???")
    local  time = cell:getChildByName("time")
    time:setString("???")
    local  alltime = cell:getChildByName("alltime")
    alltime:setString("???")
    if cashInfo then
        spinTimes:setString(cashInfo.spinTimes)
        time:setString(cashInfo.time)
        alltime:setString(cashInfo.allTime)
    end
    self.cashInfo[#self.cashInfo + 1] = {
        spinTimes = spinTimes,
        time = time,
        alltime = alltime
    }
end
function TestDataView:onEnter(  )
    gLobalNoticManager:addObserver(self,function(self,params)
        self:initCashInfo()
    end,"TEST_DATA_SPIN_UP")
    gLobalNoticManager:addObserver(self,function(self,params)
        self:upDateLevelInfo()
    end,"TEST_DATA_LEVEL_UP")
end

function TestDataView:onKeyBack()
end

function TestDataView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function TestDataView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "close" then
        self:setVisible(false)
    end
    
end

return TestDataView