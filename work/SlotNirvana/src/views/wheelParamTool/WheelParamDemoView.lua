local WheelParamDemoView = class("WheelParamDemoView", util_require("base.BaseView"))

function WheelParamDemoView:initUI()
    self:createCsbNode("wheelParamTool/testWheelPanel.csb")

    self.m_wheel1 = require("views.wheelParamTool.WheelParamDemoAction"):create(self:findChild("Panel_1"),16,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end,nil,"key1")
     self:addChild(self.m_wheel1)

     self.m_wheel2 = require("views.wheelParamTool.WheelParamDemoAction"):create(self:findChild("Panel_2"),16,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end,nil,"key2")
     self:addChild(self.m_wheel2)

     self.m_wheel3 = require("views.wheelParamTool.WheelParamDemoAction"):create(self:findChild("Panel_3"),16,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end,nil,"key3")
     self:addChild(self.m_wheel3)
end


function WheelParamDemoView:clickFunc(sender)

    local name = sender:getName()
    local tag = sender:getTag()
    if name=="Button_1" then
        self:beginWheelAction(1,2,3)
    elseif name=="Button_close" then
        self:closeUI()
    elseif name=="Button_show" then
        local vip = util_createView("views.wheelParamTool.WheelParamTool")
        gLobalViewManager:showUI(vip,ViewZorder.ZORDER_UI)
    end
end

function WheelParamDemoView:beginWheelAction( index,index2,index3)

    local wheelData = {}
    wheelData.m_startA = 30 --加速度
    wheelData.m_runV = 180--匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 80 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 30 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    self.m_wheel1:changeWheelRunData(wheelData)
    self.m_wheel1:recvData(index)
    self.m_wheel1:beginWheel()


    local wheelData2 = {}
    wheelData2.m_startA = 90 --加速度
    wheelData2.m_runV = 360--匀速
    wheelData2.m_runTime = 2--匀速时间
    wheelData2.m_slowA = 180 --动态减速度
    wheelData2.m_slowQ = 1 --减速圈数
    wheelData2.m_stopV = 45 --停止时速度
    wheelData2.m_backTime = 0 --回弹前停顿时间
    wheelData2.m_stopNum = 0 --停止圈数
    wheelData2.m_randomDistance = 0

    self.m_wheel2:changeWheelRunData(wheelData2)
    self.m_wheel2:recvData(index2)
    self.m_wheel2:beginWheel()

    local wheelData3 = {}
    wheelData3.m_startA = 90 --加速度
    wheelData3.m_runV = 360--匀速
    wheelData3.m_runTime = 2--匀速时间
    wheelData3.m_slowA = 180 --动态减速度
    wheelData3.m_slowQ = 1 --减速圈数
    wheelData3.m_stopV = 45 --停止时速度
    wheelData3.m_backTime = 0 --回弹前停顿时间
    wheelData3.m_stopNum = 0 --停止圈数
    wheelData3.m_randomDistance = 0

    self.m_wheel3:changeWheelRunData(wheelData3)
    self.m_wheel3:recvData(index3)
    self.m_wheel3:beginWheel()
end

function WheelParamDemoView:onExit()
    self.m_wheel1:removeBindData("key1")
    self.m_wheel2:removeBindData("key2")
    self.m_wheel3:removeBindData("key3")
end

function WheelParamDemoView:closeUI()
    self:removeFromParent()
end
return WheelParamDemoView