local winSize = display.size

local ShaderConfig = require "Shader.ShaderConfig"
local ShaderBase = require "Shader.ShaderBase"
package.loaded['Shader.ShaderBase'] = nil
local ShaderBase = require "Shader.ShaderBase"

local SHOWTYPE = "Sprite"

local ShaderTestLayer = class("ShaderTestLayer",function()
    return cc.LayerColor:create(cc.c3b(0.2*255,0.2*255,0.2*255), winSize.width, winSize.height)
end)

function ShaderTestLayer:capitalize(str)
    return str:gsub("^%l", string.upper)
end

function ShaderTestLayer:ctor()
    self._rootNode = cc.Node:create()
    self._rootNode:setPosition(winSize.width/2 + winSize.width/6,winSize.height/2)
    self._rootNode:setScale(0.75)
    self:addChild(self._rootNode)

    self._node = cc.Node:create()
    self:addChild(self._node)

    self:initButton()
end

function ShaderTestLayer:updateTest(file)
end

function ShaderTestLayer:refreshUniform()
    if not self._curShader then
        return
    end


end

function ShaderTestLayer:createShaderNode(config)
    if not config then
        return
    end
    package.loaded['Shader.ShaderBase'] = nil
    local classname = "Shader" .. self:capitalize(config.name)
    local ShaderBase = require ("Shader.ShaderBase")
    local shader = ShaderBase:create(config,SHOWTYPE)
    self._node:addChild(shader)
    shader:setPosition(winSize.width/2 + winSize.width/6,winSize.height/2)
    self._lastCfg = config
end

function ShaderTestLayer:initButton()
    self:addBtn("精灵",2,2,function()
        SHOWTYPE = "Sprite"
        self._node:removeAllChildren()
        self:createShaderNode(self._lastCfg)
    end)

    self:addBtn("FBORender",3,2,function()
        SHOWTYPE = "FBORender"
        self._node:removeAllChildren()
        self:createShaderNode(self._lastCfg)
    end)

    self:addBtn("关闭",1,1,function()
        self:removeFromParent()
    end)

    local index = 1
    for k,v in pairs(ShaderConfig) do
        index = index + 1
        self:addBtn(v.showName,index,1,function()
            self._node:removeAllChildren()
            self:createShaderNode(v)
        end)
    end
end

function ShaderTestLayer:addBtn(name,r,c,f)
    local label = cc.Label:createWithSystemFont(name,"",24)
    local menuItem = cc.MenuItemLabel:create(label)
    menuItem:registerScriptTapHandler(function (tag, sender )
        _ = f and f()
    end)
    local menu = cc.Menu:create(menuItem)
    self:addChild(menu)

    menu:setPosition(cc.p(60 + (c - 1) * 200,winSize.height - 60 - ((r - 1) * 36)))
end


return ShaderTestLayer