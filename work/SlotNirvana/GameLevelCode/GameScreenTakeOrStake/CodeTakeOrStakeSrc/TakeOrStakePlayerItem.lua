---
--xcyy
--2018年5月23日
--TakeOrStakePlayerItem.lua

local TakeOrStakePlayerItem = class("TakeOrStakePlayerItem",util_require("base.BaseView"))


function TakeOrStakePlayerItem:initUI()
    self:createCsbNode("TakeOrStake_Player.csb")

    self.m_bigwin = util_createAnimation("TakeOrStake_Player_hugewin.csb")
    self:findChild("Node_sp"):addChild(self.m_bigwin)

    self.m_frame = util_createAnimation("TakeOrStake_touxiangkuang_moren.csb")
    self:findChild("Node_touxiang"):addChild(self.m_frame)

    self:resetEventStatus()
    
    self.m_winType_pool = {}
    self.isBigWinPlaying = false
end

--[[
    重置事件状态
]]
function TakeOrStakePlayerItem:resetEventStatus()
    self.m_bigwin:setVisible(false)
end

--[[
    刷新数据
]]
function TakeOrStakePlayerItem:refreshData(data)
    self.m_playerInfo = data
end

--[[
    获取用户ID
]]
function TakeOrStakePlayerItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

--[[
    获取用户数据
]]
function TakeOrStakePlayerItem:getPlayerInfo( )
    return self.m_playerInfo
end

--[[
    刷新头像
]]
function TakeOrStakePlayerItem:refreshHead()
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())

    local head = self:findChild("sp_touxiang")
    head:removeAllChildren(true)
    
    local headSize = head:getContentSize()
    if self.m_playerInfo.frame == "" then
        self.m_frame:findChild("Player"):setVisible(isMe)
        self.m_frame:findChild("Others"):setVisible(not isMe)

        -- util_setHead(head, self.m_playerInfo.facebookId, self.m_playerInfo.head, nil, false)
    else
        self.m_frame:findChild("Player"):setVisible(false)
        self.m_frame:findChild("Others"):setVisible(false)
    end

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

-- 播放动画 进入房间 或者 切换房间
function TakeOrStakePlayerItem:playEffectByComeInOrChange( )
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())
    if isMe then
        gLobalSoundManager:playSound("TakeOrStakeSounds/sound_TakeOrStake_touxiang_effect.mp3")
        self:runCsbAction("actionframe",false)
    end
end

--[[
    显示大赢动画
]]
function TakeOrStakePlayerItem:showBigWinAni(winType)
    table.insert(self.m_winType_pool,#self.m_winType_pool + 1,winType)

    if not self.isBigWinPlaying then
        self:playNextBigWin()
    end
end

--[[
    播放大赢
]]
function TakeOrStakePlayerItem:playNextBigWin()
    local winType = self.m_winType_pool[1]
    if winType then
        table.remove(self.m_winType_pool,1,1)

        self:resetEventStatus()
        if winType == "BIG_WIN" then
            self.m_bigwin:setVisible(true)
        elseif winType == "MAGE_WIN" then
            self.m_bigwin:setVisible(true)
        elseif winType == "EPIC_WIN" then
            self.m_bigwin:setVisible(true)
        end

        self.isBigWinPlaying = true
        self.m_bigwin:runCsbAction("actionframe",false,function(  )
            self:resetEventStatus()
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
function TakeOrStakePlayerItem:checkBigEnd()
    if #self.m_winType_pool > 0 then
        return false
    end

    return true
end

--增加头像点击看个人信息
function TakeOrStakePlayerItem:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
       if not self.m_playerInfo then
          return
       end
       G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_playerInfo.udid, "","",self.m_playerInfo.head)
    end
end

return TakeOrStakePlayerItem