local WheelParamTool = class("WheelParamTool", util_require("base.BaseView"))

function WheelParamTool:initUI()
    self:createCsbNode("wheelParamTool/wheelParamTool.csb")
    if globalData.wheelParam and #globalData.wheelParam > 0 then
        self:initView()
    end
end

function WheelParamTool:initView()
    local posList = {
        {cc.p(685,340)},
        {cc.p(560,340),cc.p(810,340)},
        {cc.p(435,340),cc.p(685,340),cc.p(935,340)},
        {cc.p(360,340),cc.p(570,340),cc.p(780,340),cc.p(980,340)}
    }
    local tempList = posList[#globalData.wheelParam]
    local panel = self:findChild("Panel_1")
    self.m_cellList = {}
    if #globalData.wheelParam > 0 then
        for i=1,#globalData.wheelParam do
            local cell = util_createView("views.wheelParamTool.WheelParamItem")
            cell:setPosition(cc.p(tempList[i].x,tempList[i].y))
            cell:initView(globalData.wheelParam[i])
            panel:addChild(cell)
            self.m_cellList[#self.m_cellList + 1] = cell
        end

    end
end

function WheelParamTool:clickFunc(sender)

    local name = sender:getName()
    local tag = sender:getTag()
    if name=="Button_save" then
        if self.m_cellList then
            for i=1,#self.m_cellList do
                self.m_cellList[i]:saveParam()
            end
        end

    elseif name=="Button_close" then
        self:closeUI()
    end
end


function WheelParamTool:closeUI()
    self:removeFromParent()
end
return WheelParamTool