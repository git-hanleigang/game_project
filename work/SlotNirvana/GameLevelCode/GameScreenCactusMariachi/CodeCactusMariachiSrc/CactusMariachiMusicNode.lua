---
--CactusMariachiAlbumNode.lua

local CactusMariachiMusicNode = class("CactusMariachiMusicNode",util_require("base.BaseView"))

CactusMariachiMusicNode.m_curIndex = 0
CactusMariachiMusicNode.m_machine = nil
CactusMariachiMusicNode.m_shopMachine = nil
CactusMariachiMusicNode.m_curMusicLock = false

function CactusMariachiMusicNode:initUI(_machine, _shopMachine, _index)

    self:createCsbNode("CactusMariachi_shop_Music.csb")
    
    self.m_machine = _machine
    self.m_shopMachine = _shopMachine
    self.m_curIndex = _index

    self:runCsbAction("idle1")

    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.tblLockText = {}
    self.tblUnLockText = {}
    self.tblPlayText = {}

    for i=1, 5 do
        self.tblLockText[i] = self:findChild("text_lock_music_"..i)
        self.tblUnLockText[i] = self:findChild("text_unLock_music_"..i)
        self.tblPlayText[i] = self:findChild("text_play_music_"..i)
    end
end

-- 初始化界面和翻页时使用
function CactusMariachiMusicNode:refreshMusicState(_index, _isLock)
    local m_curPlayMusicIndex = self.m_shopMachine:getCurPlayMusicIndex() + 1
    self.m_curMusicLock = _isLock
    if _isLock then
        if m_curPlayMusicIndex == self.m_curIndex then
            self:runCsbAction("idle2", true)
            self:setOtherMusicTextShow()
        else
            self:runCsbAction("lanidle", true)
            self:setOtherMusicTextShow()
        end
    else
        self:runCsbAction("idle1")
        self:setOtherMusicTextShow()
    end
end

-- 切换到下一首歌
function CactusMariachiMusicNode:cutNextMusic()
    self:runCsbAction("qiehuanlv", false, function()
        self:runCsbAction("idle2", true)
        self:setOtherMusicTextShow()
    end)
    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_shopCutMusic.mp3")
    self:playEffectRandom()
end

--上一首歌变化
function CactusMariachiMusicNode:cutLastMusic()
    self:runCsbAction("qiehuanlan", false, function()
        self:runCsbAction("lanidle", true)
        self:setOtherMusicTextShow()
    end)
end

function CactusMariachiMusicNode:playMusicUnlockAni(_callFunc)
    self.m_curMusicLock = true
    self:runCsbAction("jiesuo2", false, function()
        self:runCsbAction("lanidle", true)
        self:setOtherMusicTextShow()
        if _callFunc then
            _callFunc()
        end
    end)

    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMarichi_UnLockMusic.mp3")
    self:playEffectRandom()
end

function CactusMariachiMusicNode:setOtherMusicTextShow()
    for i=1, 5 do
        self.tblLockText[i]:setVisible(false)
        self.tblUnLockText[i]:setVisible(false)
        self.tblPlayText[i]:setVisible(false)
    end
    self.tblLockText[self.m_curIndex]:setVisible(true)
    self.tblUnLockText[self.m_curIndex]:setVisible(true)
    self.tblPlayText[self.m_curIndex]:setVisible(true)
end

function CactusMariachiMusicNode:onExit()
    CactusMariachiMusicNode.super.onExit(self)
end

--默认按钮监听回调
function CactusMariachiMusicNode:clickFunc(sender)
    local name = sender:getName()

    if name == "click" and self:isCanTouch( ) then
        self.m_shopMachine:cutShopMusic(self.m_curIndex-1)
        print("当前切换第".. self.m_curIndex .. "首歌曲")
    else
        local m_curPlayMusicIndex = self.m_shopMachine:getCurPlayMusicIndex() + 1
        if m_curPlayMusicIndex ~= self.m_curIndex then
            self.m_machine:playClickEffect()
            self.m_shopMachine:showTips(self.m_curIndex-1)
        end
    end
end

function CactusMariachiMusicNode:isCanTouch()
    local m_curPlayMusicIndex = self.m_shopMachine:getCurPlayMusicIndex() + 1
    if self.m_curMusicLock and m_curPlayMusicIndex ~= self.m_curIndex then
        return true
    end
    return false
end

function CactusMariachiMusicNode:playEffectRandom()
    local randomNum = math.random(1, 10)
    if randomNum >= 1 and randomNum <= 6 then
        local randomMusic = math.random(1, 4)
        gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_shopRandomCutMusic_"..randomMusic..".mp3")
    end
end


return CactusMariachiMusicNode