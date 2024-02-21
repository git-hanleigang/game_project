--[[
    -- link卡集齐面板
]]
local BaseView = util_require("base.BaseView")
local CardLinkComplete = class("CardLinkComplete", BaseView)
function CardLinkComplete:initUI(data)
    if globalData.slotRunData.checkViewAutoClick then
        globalData.slotRunData:checkViewAutoClick(self,"Button_collect")
    end

    self.m_data = data

    local maskUI = util_newMaskLayer()
    self:addChild(maskUI,-1)
    maskUI:setOpacity(192)    

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode(string.format(CardResConfig.commonRes.linkComplete201903, "common"..CardSysRuntimeMgr:getCurAlbumID()), isAutoScale)

    self.m_numLb = self:findChild("BitmapFontLabel_1")
    self.m_numLb:setString(self.m_data)

    
    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle", true)
        self:commonShow(root)
    else
        self:runCsbAction("show", false, function()
            self:runCsbAction("idle", true)
        end)
    end

    self:addClickSound({"Button_collect"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

function CardLinkComplete:getUIScalePro()
    local x=display.width/DESIGN_SIZE.width
    local y=display.height/DESIGN_SIZE.height
    local pro=x/y
    if globalData.slotRunData.isPortrait == true then
        pro = 0.6
    end
    return pro
end

function CardLinkComplete:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_collect" then
        if self.m_clickCollect then
            return
        end
        self.m_clickCollect = true          
        CardSysManager:closeCardCollectComplete()
    end
end

function CardLinkComplete:closeUI()
    if self.isClose then
        return
    end
    self.isClose=true
    local root = self:findChild("root")
    if root then
        self:commonHide(root,function()
            self:removeFromParent()
        end)
    else
        self:runCsbAction("over",false,function ( )
            self:removeFromParent()
        end, 60)
    end
end

function CardLinkComplete:updateUI()
end

return CardLinkComplete