---
--CactusMariachiAlbumNode.lua

local CactusMariachiMusicLikeNode = class("CactusMariachiMusicLikeNode",util_require("base.BaseView"))

CactusMariachiMusicLikeNode.m_curIndex = 0
CactusMariachiMusicLikeNode.m_shopMachine = nil
CactusMariachiMusicLikeNode.m_curPage = 0
CactusMariachiMusicLikeNode.m_curLikeNum = 0
CactusMariachiMusicLikeNode.m_curIndexIsLike = false

function CactusMariachiMusicLikeNode:initUI(_shopMachine, _index)

    self:createCsbNode("CactusMariachi_shop_Like.csb")
    
    self.m_shopMachine = _shopMachine
    self.m_curIndex = _index
    self.m_curPage = self.m_shopMachine.m_curPage
    
    self:runCsbAction("idle1")

    self:addClick(self:findChild("Panel_like")) -- 非按钮节点得手动绑定监听

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

-- 初始化界面和翻页时使用
function CactusMariachiMusicLikeNode:refreshMusicLikeNum(_num)
    self.m_curLikeNum = _num
    local useLikeNum = gLobalDataManager:getNumberByField("CactusMariachi_likeNumIndex_"..self.m_curIndex, "")
    if useLikeNum and useLikeNum ~= "" and useLikeNum > self.m_curLikeNum then
        self.m_curLikeNum = useLikeNum
    end
    
    self:setLikeNum()
end

function CactusMariachiMusicLikeNode:setLikeNum()
    self:findChild("m_lb_likeNum"):setString(self:getCurLikeNum())
end

function CactusMariachiMusicLikeNode:getCurLikeNum()
    local likeNum = self.m_curLikeNum
    if likeNum > 1000 then
        likeNum = math.floor(likeNum/1000)
        likeNum = likeNum .. "K+"
    end
    return likeNum
end

function CactusMariachiMusicLikeNode:onExit()
    CactusMariachiMusicLikeNode.super.onExit(self)
end

--默认按钮监听回调
function CactusMariachiMusicLikeNode:clickFunc(sender)
    local name = sender:getName()

    if name == "Panel_like" and not self.m_curIndexIsLike then
        if self:getCurMusicIsUnLock() then
            self:addLikeNum()
        else
            self.m_shopMachine:showTips(self.m_curIndex-1)
        end
    end
end

function CactusMariachiMusicLikeNode:getCurMusicIsUnLock()
    local musicStateList = self.m_shopMachine:getMusicStateList()
    local isUnlock = false
    if self.m_curIndex == 1 then
        isUnlock = true
    else
        isUnlock = musicStateList[1][self.m_curIndex]isUnlock = musicStateList[1][self.m_curIndex-1]
    end
    return isUnlock
end

function CactusMariachiMusicLikeNode:addLikeNum()
    self.m_curIndexIsLike = true
    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_shopLike.mp3")
    self:runCsbAction("fankui", false, function()
        self:runCsbAction("idle")
    end)
    performWithDelay(self.m_scWaitNode, function()
        self.m_curLikeNum = self.m_curLikeNum + 1
        gLobalDataManager:setNumberByField("CactusMariachi_likeNumIndex_"..self.m_curIndex, self.m_curLikeNum)
        self:setLikeNum()
    end, 10/60)
end

return CactusMariachiMusicLikeNode