
local ZeusVsHadesPlayerItem = class("ZeusVsHadesPlayerItem",util_require("base.BaseView"))

function ZeusVsHadesPlayerItem:initUI(fileName)
    self:createCsbNode(fileName)
    --头像框
    self.head_bg_me = self:findChild("lvkuang")
    -- 添加大赢动画
    self.m_win = util_createAnimation("Socre_ZeusVsHAdes_touxiangwin.csb")
    self.m_win:setVisible(false)
    self:addChild(self.m_win)
    self.m_winType_pool = {}--大赢动画数组，一个一个播
    self.isBigWinPlaying = false--是否正在播放大赢
end

function ZeusVsHadesPlayerItem:onEnter()
    ZeusVsHadesPlayerItem.super.onEnter(self)
    --关闭个人信息界面
    gLobalNoticManager:addObserver(self,handler(self,function()
        self:refreshHead()
    end),ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER)
end

function ZeusVsHadesPlayerItem:resetStatus()
    self.m_win:setVisible(false)
end

--[[
    刷新数据
]]
function ZeusVsHadesPlayerItem:refreshData(data)
    self.m_playerInfo = data
end

--[[
    获取用户ID
]]
function ZeusVsHadesPlayerItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

--[[
    获取用户数据
]]
function ZeusVsHadesPlayerItem:getPlayerInfo()
    return self.m_playerInfo
end

--[[
    刷新头像
]]
function ZeusVsHadesPlayerItem:refreshHead()
    if not self.m_playerInfo then
        return
    end
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())
    local head = self:findChild("touxiang")
    head:removeAllChildren(true)

    local frameId = isMe and globalData.userRunData.avatarFrameId or self.m_playerInfo.frame
    local headSize = head:getContentSize()
    local headSizeCut = cc.size(headSize.width - 8, headSize.height - 8)
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(self.m_playerInfo.facebookId, self.m_playerInfo.head, frameId, nil, headSizeCut)
    head:addChild(nodeAvatar)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
    
    self:findChild("touxiang"):setPosition(cc.p(0, 61))

    if not self.m_headFrame then
        local headFrameNode = cc.Node:create()
        self:findChild("Node_1"):addChild(headFrameNode, 1)
        self.m_headFrame = headFrameNode
        self.m_headFrame:setPosition(head:getPosition())
    else
        self.m_headFrame:removeAllChildren(true)
    end
    util_changeNodeParent(self.m_headFrame, nodeAvatar.m_nodeFrame)

    -- self.head_bg_me:setVisible(false)

    if frameId == nil or frameId == "" then
        self.head_bg_me:setVisible(isMe)
    else
        self.head_bg_me:setVisible(false)
    end
    -- self.head_bg_me:setVisible(isMe)
    self:resetStatus()

    if not head:getChildByName("layout_touch") then
        local layout = ccui.Layout:create()
        layout:setName("layout_touch")
        layout:setTouchEnabled(true)
        layout:setContentSize(headSize)
        self:addClick(layout)
        layout:addTo(head)
    end
    
end

--[[
    显示大赢动画
]]
function ZeusVsHadesPlayerItem:showBigWinAni(winType)
    table.insert(self.m_winType_pool,#self.m_winType_pool + 1,winType)

    if not self.isBigWinPlaying then
        self:playNextBigWin()
    end
end

--[[
    播放大赢
]]
function ZeusVsHadesPlayerItem:playNextBigWin()
    local winType = self.m_winType_pool[1]
    if winType then
        table.remove(self.m_winType_pool,1,1)
        self.m_win:findChild("bigwin"):setVisible(false)
        self.m_win:findChild("megawin"):setVisible(false)
        self.m_win:findChild("epicwin"):setVisible(false)
        if winType == "BIG_WIN" then
            self.m_win:findChild("bigwin"):setVisible(true)
        elseif winType == "MAGE_WIN" then
            self.m_win:findChild("megawin"):setVisible(true)
        elseif winType == "EPIC_WIN" then
            self.m_win:findChild("epicwin"):setVisible(true)
        end
        self.m_win:setVisible(true)
        self.isBigWinPlaying = true
        self.m_win:playAction("actionframe",false,function()
            self.m_win:setVisible(false)
            if self:checkBigEnd() then
                self.isBigWinPlaying = false
            else
                self:playNextBigWin()
            end
            
        end)
    end
end

--[[
    检测大赢动画是否播放结束
]]
function ZeusVsHadesPlayerItem:checkBigEnd()
    if #self.m_winType_pool > 0 then
        return false
    end
    return true
end


--增加头像点击看个人信息
function ZeusVsHadesPlayerItem:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
       if not self.m_playerInfo then
          return
       end
       G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_playerInfo.udid, "","",self.m_playerInfo.head)
    end
end

return ZeusVsHadesPlayerItem