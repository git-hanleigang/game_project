
--paytableview 界面

local BasePayTableView = class("BasePayTableView", util_require("base.BaseView"))
BasePayTableView.m_childViews = {}
BasePayTableView.m_nCurChildViewIdx = 1
BasePayTableView.m_sViewRoot = "childRoot"

function BasePayTableView:initUI(sCsbpath)
    self:createCsbNode(sCsbpath)
    local rootNode = self:findChild("node_root")
    -- if rootNode ~= nil then
    --     local curScale = rootNode:getScale()
    --     rootNode:setScale(curScale + 0.2)
    -- end

    self:initPageView()
end

--初始化pageview
function BasePayTableView:initPageView()
    self.m_childViews = {}
    if self.m_sViewRoot ~= nil and self.m_csbOwner[self.m_sViewRoot] ~= nil then
        local children = self.m_csbOwner[self.m_sViewRoot]:getChildren()
        for k = 1, #children do
            self.m_childViews[#self.m_childViews + 1] = children[k]
            children[k]:setVisible(false)
        end
        self.m_childViews[1]:setVisible(true)
    end    

end

function BasePayTableView:clickFunc(sender)
    local sBtnName = sender:getName()
    local _btnSound = "Sounds/btn_click.mp3"
    if sBtnName == "btn_back" then        
        self:removeFromParent(true)
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
        return 
    elseif sBtnName == "btn_Left" then         
        self.m_nCurChildViewIdx = self.m_nCurChildViewIdx - 1
    elseif sBtnName == "btn_Right"  then 
        self.m_nCurChildViewIdx = self.m_nCurChildViewIdx + 1
    end
    gLobalSoundManager:playSound(_btnSound)
    self.m_nCurChildViewIdx = self.m_nCurChildViewIdx > #self.m_childViews and 1 
    or self.m_nCurChildViewIdx == 0 and #self.m_childViews 
    or self.m_nCurChildViewIdx 
    self:changeToPageByIdx(self.m_nCurChildViewIdx)
end


function BasePayTableView:changeToPageByIdx(nPageIdx)
    for k = 1, #self.m_childViews do
        self.m_childViews[k]:setVisible(nPageIdx == k)
    end
end

return BasePayTableView