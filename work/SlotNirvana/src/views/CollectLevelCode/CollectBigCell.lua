
local CollectBigCell = class("CollectBigCell", BaseView)

function CollectBigCell:initUI()
    self:createCsbNode("CollectionLevel/csd/Activity_CollectionLevel_folder.csb")
    self:initView()
end

function CollectBigCell:initView()
    local pos_list = {cc.p(138,136),cc.p(138,-136),cc.p(438,136),cc.p(438,-136),cc.p(739,136),cc.p(739,-136)}
    self.m_scale = self:getUIScalePro()
    local xian = self:findChild("xian")
    self.m_xian = xian
    if self.m_scale == 1 then
        return
    end
    local sca = 1/self.m_scale
    local distance = 0
    local index = 0
    for i=1,6 do
        local node = self:findChild("node"..i)
        local x = pos_list[i].x
        local y = pos_list[i].y
        node:setPosition(x*sca+30+distance,0+y*sca)
    end
    xian:setPositionX(915*sca + 30)
end

function CollectBigCell:updataCell(_data)
    for i,v in ipairs(_data) do
         local node = util_createView("views.CollectLevelCode.CollectCell")
         node:updataCell(v)
         local parent = self:findChild("node"..i)
        parent:addChild(node)
    end
end

function CollectBigCell:updataLevelCell(_data,_idx,_type)
    if #_data > 4 then
        self.m_xian:setVisible(true)
    else
        self.m_xian:setVisible(false)
    end
    for i,v in ipairs(_data) do
        local node = util_createView("views.CollectLevelCode.CollectLevelCell")
        node:setScale((1/self.m_scale))
        node:updateInfo(v,_type)
        node:updateLevelVisible(true)
        local parent = self:findChild("node"..i)
        parent:addChild(node)
    end
end

return CollectBigCell