local WheelParamItem = class("WheelParamItem", util_require("base.BaseView"))

function WheelParamItem:initUI()
    self:createCsbNode("wheelParamTool/wheelParamNode.csb")
end

function WheelParamItem:initView(wheelData)
    self.m_wheelData = wheelData
    self:findChild("lbs_title"):setString(wheelData.key)
    for i=1,9 do
        local filed = self:findChild("TextField_"..i)
        if i == 1 then
            filed:setString(wheelData.data.m_startA)
        elseif i == 2 then
            filed:setString(wheelData.data.m_runV)
        elseif i == 3 then
            filed:setString(wheelData.data.m_runTime)
        elseif i == 4 then
            filed:setString(wheelData.data.m_slowA)
        elseif i == 5 then
            filed:setString(wheelData.data.m_slowQ)
        elseif i == 6 then
            filed:setString(wheelData.data.m_stopV)
        elseif i == 7 then
            filed:setString(wheelData.data.m_backTime)
        elseif i == 8 then
            filed:setString(wheelData.data.m_stopNum)
        elseif i == 9 then
            filed:setString(wheelData.data.m_randomDistance)
        end
    end
end

function WheelParamItem:saveParam()
    for i=1,9 do
        local filed = self:findChild("TextField_"..i)
        if i == 1 then
            self.m_wheelData.data.m_startA = tonumber(filed:getString())
        elseif i == 2 then
            self.m_wheelData.data.m_runV = tonumber(filed:getString())
        elseif i == 3 then
            self.m_wheelData.data.m_runTime = tonumber(filed:getString())
        elseif i == 4 then
            self.m_wheelData.data.m_slowA = tonumber(filed:getString())
        elseif i == 5 then
            self.m_wheelData.data.m_slowQ = tonumber(filed:getString())
        elseif i == 6 then
            self.m_wheelData.data.m_stopV = tonumber(filed:getString())
        elseif i == 7 then
            self.m_wheelData.data.m_backTime = tonumber(filed:getString())
        elseif i == 8 then
            self.m_wheelData.data.m_stopNum = tonumber(filed:getString())
        elseif i == 9 then
            self.m_wheelData.data.m_randomDistance = tonumber(filed:getString())
        end
    end
end
return WheelParamItem