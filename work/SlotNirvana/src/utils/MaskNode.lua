--
-- 依赖于一张图片的遮罩层
-- 

local MaskNode = class("MaskNode", function() return cc.Node:create()
end)

function MaskNode:ctor()
    self:enableNodeEvents()
	self.m_MaskTex = nil
end

-- 初始化 --
-- strTex   :遮罩纹理 必须
-- pPos     :位置 如不填则居中
-- pAlpha   :半透 如不填 200
-- pSize    :遮罩大小 不填不变
function MaskNode:init( strTex , pPos, pAlpha ,pSize ,pScale )
    assert(strTex,"Slot Mask texture must't be nil")

    self.m_TextureName  = strTex
    self.m_MaskPos      = pPos or cc.p( display.cx , display.cy )
    self.m_MaskAlpha    = pAlpha or 200
    self.m_MaskSize     = pSize
    self.m_MaskScale     = pScale
    self.m_MaskColor    = cc.c4b(0, 0, 0 )
    self.m_MaskOpacity  = self.m_MaskAlpha
    if not self.m_MaskScale then
        self.m_MaskScale = 1
    end
    self:setTexture( )
    self:setSize( )
    self:genMaskborder( )
end

-- 设置遮罩纹理 --
function MaskNode:setTexture( )
    self.m_MaskTex = ccui.ImageView:create( self.m_TextureName )
    self.m_MaskTex:setScale9Enabled(false)
    self.m_MaskTex:setAnchorPoint( 0.5,0.5 )
    self.m_MaskTex:setScale( self.m_MaskScale )
    self.m_MaskTex:setOpacity( self.m_MaskAlpha )
    self.m_MaskTex:setPosition( self.m_MaskPos.x , self.m_MaskPos.y )
    self.m_MaskTex:ignoreContentAdaptWithSize(false)
    self:addChild( self.m_MaskTex )
end

-- 缩放 --
function MaskNode:setSize( )
    if self.m_MaskSize ~= nil then
        self.m_MaskTex:setContentSize( self.m_MaskSize )
    end
end

function MaskNode:onEnter(  )
    -- do something --
end

-- 生成周边遮罩 --
function MaskNode:genMaskborder(  )

    local pPos      = self.m_MaskPos
    local pSize     = self.m_MaskTex:getContentSize()
    local pScreenX  = display.width
    local pScreenY  = display.height

    -- 边框位置 --
    local pBoderT   = pPos.y + pSize.height / 2 * self.m_MaskScale
    local pBoderB   = pPos.y - pSize.height / 2 * self.m_MaskScale
    local pBoderL   = pPos.x - pSize.width  / 2 * self.m_MaskScale
    local pBoderR   = pPos.x + pSize.width  / 2 * self.m_MaskScale

    -- 创建上边框 --
    if pBoderT < pScreenY then
        local tWidth    = pScreenX
        local tHeight   = pScreenY - pBoderT
        local tboder    = ccui.Layout:create()
        tboder:setTouchEnabled(true)
        tboder:setSwallowTouches(true)
        tboder:setAnchorPoint(0, 0)
        tboder:setContentSize( cc.size( tWidth , tHeight ) )

        tboder:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
        tboder:setBackGroundColor( self.m_MaskColor );
        tboder:setBackGroundColorOpacity( self.m_MaskOpacity  )

        tboder:setPosition( 0,pBoderT )
        self:addChild( tboder )

    end

    -- 创建下边框 --
    if pBoderB > 0 then
        local tWidth    = pScreenX
        local tHeight   = pBoderB
        local tboder    = ccui.Layout:create()
        tboder:setTouchEnabled(true)
        tboder:setSwallowTouches(true)
        tboder:setAnchorPoint(0, 0)
        tboder:setContentSize( cc.size( tWidth , tHeight ) )
        tboder:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
        tboder:setBackGroundColor( self.m_MaskColor );
        tboder:setBackGroundColorOpacity( self.m_MaskOpacity  )
        tboder:setPosition( 0,0 )
        self:addChild( tboder )
    end

    -- 创建左框 --
    if pBoderL > 0  then
        local tWidth    = pBoderL
        local tHeight   = pSize.height * self.m_MaskScale
        local tboder    = ccui.Layout:create()
        tboder:setTouchEnabled(true)
        tboder:setSwallowTouches(true)
        tboder:setAnchorPoint(0, 0)
        tboder:setContentSize( cc.size( tWidth , tHeight ) )
        tboder:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
        tboder:setBackGroundColor( self.m_MaskColor );
        tboder:setBackGroundColorOpacity( self.m_MaskOpacity  )
        tboder:setPosition( 0,pBoderB )
        self:addChild( tboder )
    end


    -- 创建右框 --
    if pBoderR < pScreenX then
        local tWidth    = pScreenX - pBoderR
        local tHeight   = pSize.height * self.m_MaskScale
        local tboder    = ccui.Layout:create()
        tboder:setTouchEnabled(true)
        tboder:setSwallowTouches(true)
        tboder:setAnchorPoint(0, 0)
        tboder:setContentSize( cc.size( tWidth , tHeight ) )
        tboder:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
        tboder:setBackGroundColor( self.m_MaskColor );
        tboder:setBackGroundColorOpacity( self.m_MaskOpacity  )
        tboder:setPosition( pBoderR , pBoderB )
        self:addChild( tboder )
    end
end

return MaskNode
