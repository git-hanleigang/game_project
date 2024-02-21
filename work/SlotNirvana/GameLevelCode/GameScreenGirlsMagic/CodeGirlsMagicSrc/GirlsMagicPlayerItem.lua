---
--xcyy
--2018年5月23日
--GirlsMagicPlayerItem.lua

local GirlsMagicPlayerItem = class("GirlsMagicPlayerItem",util_require("base.BaseView"))


function GirlsMagicPlayerItem:initUI(_isUseCommonFrame)
    self:createCsbNode("GirlsMagic_Player.csb")

    self:runCsbAction("idle")

    self.multi_1 = self:findChild("multi_1")
    self.multi_2 = self:findChild("multi_2")
    self.multi_1:setVisible(false)
    self.multi_2:setVisible(false)

    --头像框
    self.head_bg_other = self:findChild("head_bg_other")
    self.head_bg_me = self:findChild("head_bg_me")

    self.m_bigwin = self:findChild("bigwin")
    self.m_megawin = self:findChild("megawin")
    self.m_epicwin = self:findChild("epicwin")
    self.m_bigwin:setVisible(false)
    self.m_megawin:setVisible(false)
    self.m_epicwin:setVisible(false)
    self.m_winType_pool = {}
    self.isBigWinPlaying = false

    self.m_isUseCommonFrame = not not _isUseCommonFrame
end


function GirlsMagicPlayerItem:onEnter()
    GirlsMagicPlayerItem.super.onEnter(self)
    --关闭个人信息界面
    gLobalNoticManager:addObserver(self,handler(self,function()
        self:refreshHead()
    end),ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER)
end

function GirlsMagicPlayerItem:resetStatus()
    self.multi_1:setVisible(false)
    self.multi_2:setVisible(false)
    self.m_bigwin:setVisible(false)
    self.m_megawin:setVisible(false)
    self.m_epicwin:setVisible(false)
end

--[[
    刷新数据
]]
function GirlsMagicPlayerItem:refreshData(data)
    self.m_playerInfo = data
end

--[[
    获取用户ID
]]
function GirlsMagicPlayerItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

--[[
    获取用户数据
]]
function GirlsMagicPlayerItem:getPlayerInfo( )
    return self.m_playerInfo
end

--[[
    刷新头像
]]
function GirlsMagicPlayerItem:refreshHead()
    if not self.m_playerInfo then
        return
    end
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())
    
    local head = self:findChild("touxiang")
    head:removeAllChildren(true)
    local headSize = head:getContentSize()
    if self.m_isUseCommonFrame then
        local frameId = isMe and globalData.userRunData.avatarFrameId or self.m_playerInfo.frame
        
        local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(self.m_playerInfo.facebookId, self.m_playerInfo.head, frameId, nil, headSize)
        head:addChild(nodeAvatar)
        nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

        if frameId == nil or frameId == "" then
            self.head_bg_other:setVisible(not isMe)
            self.head_bg_me:setVisible(isMe)
        else
            self.head_bg_other:setVisible(false)
            self.head_bg_me:setVisible(false)
        end
        if not head:getChildByName("layout_touch") then
            local layout = ccui.Layout:create()
            layout:setName("layout_touch")
            layout:setTouchEnabled(true)
            layout:setContentSize(headSize)
            self:addClick(layout)
            layout:addTo(head)
        end
        
    else
        util_setHead(head, self.m_playerInfo.facebookId, self.m_playerInfo.head, nil, false)     
        self.head_bg_other:setVisible(not isMe)
        self.head_bg_me:setVisible(isMe)
    end


    self:resetStatus()
end

--[[
    完全匹配动画
]]
function GirlsMagicPlayerItem:fullMatchAni(multiples)
    local lbl_num = self:findChild("m_lb_num_1")
    lbl_num:setString("X"..multiples)
    self.multi_1:setVisible(true)
    
    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle")
    end)
end

--[[
    乘倍显示动画
]]
function GirlsMagicPlayerItem:showMultipleAni(multiple)
    local lbl_num = self:findChild("m_lb_num_2")
    lbl_num:setString("X"..multiple)
    self.multi_2:setVisible(true)

    
    self:runCsbAction("start2",false,function(  )
        self:runCsbAction("idle2")
    end)
end

--[[
    隐藏乘倍标签动画
]]
function GirlsMagicPlayerItem:hideMutilpleAni()
    self:runCsbAction("over2")
end

--[[
    显示大赢动画
]]
function GirlsMagicPlayerItem:showBigWinAni(winType)
    table.insert(self.m_winType_pool,#self.m_winType_pool + 1,winType)

    if not self.isBigWinPlaying then
        self:playNextBigWin()
    end
end

--[[
    播放大赢
]]
function GirlsMagicPlayerItem:playNextBigWin()
    local winType = self.m_winType_pool[1]
    if winType then
        table.remove(self.m_winType_pool,1,1)

        self.m_bigwin:setVisible(false)
        self.m_megawin:setVisible(false)
        self.m_epicwin:setVisible(false)
        if winType == "BIG_WIN" then
            self.m_bigwin:setVisible(true)
        elseif winType == "MAGE_WIN" then
            self.m_megawin:setVisible(true)
        elseif winType == "EPIC_WIN" then
            self.m_epicwin:setVisible(true)
        end

        self.isBigWinPlaying = true
        self:runCsbAction("actionframe2",false,function(  )
            self.m_bigwin:setVisible(false)
            self.m_megawin:setVisible(false)
            self.m_epicwin:setVisible(false)
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
function GirlsMagicPlayerItem:checkBigEnd()
    if #self.m_winType_pool > 0 then
        return false
    end

    return true
end
--增加头像点击看个人信息
function GirlsMagicPlayerItem:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
       if not self.m_playerInfo then
          return
       end
       G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_playerInfo.udid, "","",self.m_playerInfo.head)
    end
end

return GirlsMagicPlayerItem