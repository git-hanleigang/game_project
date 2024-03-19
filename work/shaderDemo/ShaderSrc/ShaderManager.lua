ShaderManager = class("ShaderManager")

local ShaderConfig = require "Shader.ShaderConfig"
package.loaded['Shader.ShaderConfig'] = nil

package.loaded['Shader.ShaderTestLayer'] = nil

local ShaderTestLayer = require "Shader.ShaderTestLayer"


function ShaderManager:showTestLayer()
    package.loaded['Shader.ShaderManager'] = nil
    require "Shader.ShaderManager"

    local layer = ShaderTestLayer:create()
    cc.Director:getInstance():getRunningScene():addChild(layer,0xffffff)
end