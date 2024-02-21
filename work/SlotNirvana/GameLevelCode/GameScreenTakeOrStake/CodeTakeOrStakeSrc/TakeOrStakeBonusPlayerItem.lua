---
--xcyy
--2018年5月23日
--TakeOrStakeBonusPlayerItem.lua

local TakeOrStakeBonusPlayerItem = class("TakeOrStakeBonusPlayerItem",util_require("base.BaseView"))

function TakeOrStakeBonusPlayerItem:initUI()
    self:createCsbNode("TakeOrStake_shejiaoplayer.csb")

end

--获取用户数据
function TakeOrStakeBonusPlayerItem:getPlayerInfo( )
    return self.m_playerInfo
end

--刷新数据
function TakeOrStakeBonusPlayerItem:refreshData(data)
    --rsItem 共用一个数据初始化时 计算得分会 x2
    self.m_playerInfo = data and clone(data) or {}
end

--[[
    获取用户ID
]]
function TakeOrStakeBonusPlayerItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

--[[
    刷新头像
]]
function TakeOrStakeBonusPlayerItem:refreshHead()
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())

    local head = self:findChild("touxiang")
    head:removeAllChildren(true)

    local headSize = head:getContentSize()
    
    self:findChild("kuang_lv"):setVisible(isMe)
    self:findChild("kuang_zi"):setVisible(not isMe)

    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(self.m_playerInfo.facebookId, self.m_playerInfo.head, self.m_playerInfo.frame, nil, headSize)
    head:addChild(nodeAvatar)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
    local layout = ccui.Layout:create()
    layout:setName("layout_touch")
    layout:setTouchEnabled(true)
    layout:setContentSize(headSize)
    self:addClick(layout)
    layout:addTo(head)
end

-- 是否显示 头像上的picker
function TakeOrStakeBonusPlayerItem:showPickerUI(isShow)
    self:findChild("zi"):setVisible(isShow)
end

--头像显示 不同的底
function TakeOrStakeBonusPlayerItem:showDiUI(showDiIndex)
    for i=1,3 do
        self:findChild("di_"..i):setVisible(false)
    end

    self:findChild("di_"..showDiIndex):setVisible(true)
end

-- 没有玩家的时候  不显示
function TakeOrStakeBonusPlayerItem:noShowUI( )
    self:findChild("touxiang"):removeAllChildren(true)
    self:findChild("kuang_lv"):setVisible(false)
    self:findChild("kuang_zi"):setVisible(false)
    self:findChild("zi"):setVisible(false)
end

--增加头像点击看个人信息
function TakeOrStakeBonusPlayerItem:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
       if not self.m_playerInfo then
          return
       end
       G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_playerInfo.udid, "","",self.m_playerInfo.head)
    end
end

return TakeOrStakeBonusPlayerItem