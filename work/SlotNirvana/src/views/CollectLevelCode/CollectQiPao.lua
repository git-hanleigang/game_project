local CollectQiPao = class("CollectQiPao", BaseView)
local ITEM_TYPE = {
    Home_ITEM = 1,
    FOV_ITEM = 2
}
function CollectQiPao:initUI(_type)
    local path = "CollectionLevel/csd/Activity_CollectionLevel_qipao.csb"
    self._type = _type
    self:createCsbNode(path)
    self:initView()
end

function CollectQiPao:initCsbNodes()
    self.lb_return = self:findChild("lb_return")
    self.lb_favorite = self:findChild("lb_favorite")
    self.lb_lbframe = self:findChild("lb_frame")
    self.lb_lbclassic = self:findChild("lb_classic")
end

function CollectQiPao:initView()
    self.m_lbList = {self.lb_return,self.lb_favorite,self.lb_lbframe,self.lb_lbclassic}
    for i,v in ipairs(self.m_lbList) do
        if i == self._type then
            v:setVisible(true)
        else
            v:setVisible(false)
        end
    end
    self.status = true
end

function CollectQiPao:showAction()
    if self.status then
        self.status = false
        self:runCsbAction(
            "show",
            false,
            function()
                performWithDelay(
                    self,
                    function()
                        if tolua.isnull(self) then
                            return
                        end
                        self:runCsbAction("over",false,function()
                            if tolua.isnull(self) then
                               return
                            end
                            self.status = true
                            self:removeFromParent()
                        end)
                    end,
                    2
                )
            end
        )
    end 
end

function CollectQiPao:showEnd()
    self:removeFromParent()
end

function CollectQiPao:getStatus()
    return self.status
end

return CollectQiPao