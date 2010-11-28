require "iuplua"
require "iupluagl" 
require "luagl" 
require "luaglu" 
require "iupluacontrols" 
require "iuplua_pplot51" 

require "vec3"
require "giftWrap"
require "visualGlCanvas"

-- AUX METHODS
-- AUX METHODS
-- AUX METHODS
function generateCubeRandomPoints(n)
  local points = {}
  for i=1, n do
    local v = newVec3(math.random()*2-1, math.random()*2-1, math.random()*2-1)
    table.insert(points, v)
  end
  return points
end

function generateParaboloidRandomPoints(n)
  local points = {}
  local a = 1
  local b = 1
  for i = 1, n do
    local x = math.random()*2-1
    local z = math.random()*2-1
    local y = (x*x)/(a*a) + (z*z)/(b*b)
    local p = newVec3(x, y, z)
    
    local v = newVec3((math.random()*2-1)/10., (math.random()*2-1)/10., (math.random()*2-1)/10.)
    
    p = p + v
    table.insert(points, p)
  end
  return points
end

function getBorderPoints(points, polys)
  local borderpoints = {}
  if points == nil or polys == nil then
    return borderpoints
  end
  
  for i = 1, #points do
    borderpoints[i] = false
  end
  
  for i, triangle in ipairs(polys) do
    for j, vertex_index in ipairs(triangle) do
      borderpoints[vertex_index] = true
    end
  end
  return borderpoints
end 


-- APPLICATION GLOBAL TABLE
-- APPLICATION GLOBAL TABLE
-- APPLICATION GLOBAL TABLE
local app = {

  cam = {
    alpha = 0,
    beta = 0,
    r = 10,
    angInc = 5,
    center = {x = 0, y = 0},
    
    near = 0.1,
    far = 10000.,
    fovy = 60.0,
  },
  
  render = {
    wireFrameEnabled = false, --W
    flatEnabled = false,     --Q
  },
  
  mouse = {
    state = 0, -- Release
    button = iup.BUTTON1, -- LEFT_BUTTON
    pos = {x = 0, y = 0}
  },
  
  options = {
    showBorderPoints = true,
    showAxis = true,
    depthTest = true,
  },
  
  genMethod = {
    {name = "Cube", func = generateCubeRandomPoints} ,
    {name = "Paraboloid", func = generateParaboloidRandomPoints} ,
  },
  
  anim = {
    enabled = true,
    pause = false, 
    step = 1,
    type = "edge",
    count = 0,
    
    transitionTime = 60,
    edgeTransitionTime = 30,
    
    Reset = function (self)
      self.step = 1
      self.type = "edge"
      self.count = 0
    end
  },
  
  width = 800,
  height = 600,
}

function app:SetWireframeEnabled()
  self.render.wireFrameEnabled = not self.render.wireFrameEnabled
  gl.PolygonMode(gl.FRONT_AND_BACK, self.render.wireFrameEnabled and gl.LINE or gl.FILL) 
end

function app:SetBorderOptionsEnabled()
  self.options.showBorderPoints = not self.options.showBorderPoints
end

function app:SetDepthEnabled()
  self.options.depthTest = not self.options.depthTest
end

function app:SetAxisEnabled()
  self.options.showAxis = not self.options.showAxis
end

function app:SetAnimEnabled()
  self.anim.enabled = not self.anim.enabled
  self.anim:Reset()
end

function app:SetAnimVelocity(value)
  local val = 1.4 - tonumber(value)
  self.anim.transitionTime = 60*val
  self.anim.edgeTransitionTime = 30*val
end

function app:SetAnimPause()
  self.anim.pause = not self.anim.pause
end

function app:SetAnimNextStep()
  if self.anim.enabled then
    self.anim.pause = true
    self.anim.step = self.anim.step + 1
    self.anim.type = "edge"
    self.anim.count = 0
  end
end

function app:SetAnimPrevStep()
  if self.anim.enabled then
    self.anim.pause = true
    self.anim.step = math.max(self.anim.step - 1, 1)
    self.anim.type = "edge"
    self.anim.count = 0
  end
end

function app:SetFlatEnabled()
  self.render.flatEnabled = not self.render.flatEnabled
  gl.ShadeModel(self.render.flatEnabled and gl.FLAT or gl.SMOOTH)
end

-- MAIN DIALOG
-- MAIN DIALOG
-- MAIN DIALOG

local ConvexHullVisual = {
  points = {},
  polys = {},
  borderpoints = {},
  numPoints = 10,
}

function ConvexHullVisual:GeneratePoints()
  self.points = app.genMethod[tonumber(self.generationMethodsList.value)].func(self.numPoints)
  self.polys = getHullPolys(self.points)
  self.borderpoints = getBorderPoints(self.points, self.polys)
  
  local numBorder = 0
  for i, point in ipairs(self.points) do
    local pos = self.borderpoints[i] and "(B)" or "(I)"
    numBorder = self.borderpoints[i] and numBorder + 1 or numBorder
    local str = string.format("%.2f", point.x)..",  ".. string.format("%.2f", point.y)..",  ".. string.format("%.2f", point.z)
    self.pointsList[i] = pos.." "..str
  end
  self.pointsList[#self.points + 1] = nil
  self.numBorderPointsText.value = tostring(numBorder)
  app.anim:Reset()
end

function ConvexHullVisual:BuildInterface()
  self.pointsList = iup.list{expand = "VERTICAL"}
  self.numBorderPointsText = iup.text{value = 0, size = "25x"}
  
  self.generationMethodsList = iup.list{dropdown = "YES", value = 1}
  for i, method in ipairs(app.genMethod) do
    self.generationMethodsList[i] = method.name
  end
  self.generationMethodsList[#app.genMethod + 1] = nil
  
  self:GeneratePoints()

  self.numPointsText = iup.text{value = tostring(self.numPoints)}
  
  self.animPauseButton = iup.button{title = app.anim.pause and "Play" or "Pause", 
    active = app.anim.enabled and "YES" or "NO",
    action = function(lself) 
      app:SetAnimPause() 
      lself.title = app.anim.pause and "Play" or "Pause"  
      self.animPrevButton.active = app.anim.step > 1 and "YES" or "NO"  
      self.animNextButton.active = app.anim.step <= #self.polys and "YES" or "NO"  
    end
  }
  
  self.animPrevButton = iup.button{title = "Prev", 
    action = function(lself) 
      app:SetAnimPrevStep() 
      lself.active = app.anim.step > 1 and "YES" or "NO"  
      self.animPauseButton.title = app.anim.pause and "Play" or "Pause"      self.animNextButton.active = app.anim.step <= #self.polys and "YES" or "NO"  
    end
  }
  
  self.animNextButton = iup.button{title = "Next", 
    action = function(lself) 
      app:SetAnimNextStep() 
      lself.active = app.anim.step <= #self.polys and "YES" or "NO"  
      self.animPauseButton.title = app.anim.pause and "Play" or "Pause"
      self.animPrevButton.active = app.anim.step > 1 and "YES" or "NO"  
    end
  }
  
  self.animToggle = iup.toggle{title = "Animation", value = app.anim.enabled and "ON" or "OFF", 
    action = function(lself) 
      app:SetAnimEnabled()  
      self.animNextButton.active = (app.anim.enabled and app.anim.step <= #self.polys) and "YES" or "NO" 
      self.animPrevButton.active = (app.anim.enabled and app.anim.step > 1) and "YES" or "NO"  
      self.animPauseButton.active = app.anim.enabled and "YES" or "NO"  
    end
  }
  

  
  self.opsBox = iup.hbox {
    iup.fill{size = 5},
    iup.vbox{
      iup.fill{size = 5},
      -------------------------
      iup.button{title = "ResetCamera",  
        action = function(lself) app.cam.center = {x = 0, y = 0} app.cam.alpha = 0 app.cam.beta = 0    end
      },
      iup.fill{size = 5},
      
      iup.toggle{title = "WireFrame", value = app.render.wireFrameEnabled and "ON" or "OFF", 
        action = function(lself) app:SetWireframeEnabled()     end
      },
      iup.fill{size = 5},
      
      iup.toggle{title = "DepthTest", value = app.options.depthTest and "ON" or "OFF", 
        action = function(lself) app:SetDepthEnabled()     end
      },
      iup.fill{size = 5},      
            
      iup.toggle{title = "BorderPoints", value = app.options.showBorderPoints and "ON" or "OFF", 
        action = function(lself) app:SetBorderOptionsEnabled()     end
      },
      iup.fill{size = 5},      
      
      iup.toggle{title = "Axis", value = app.options.showAxis and "ON" or "OFF", 
        action = function(lself) app:SetAxisEnabled()     end
      },
      iup.fill{size = 5},    
      
      self.animToggle,
      iup.fill{size = 5},
      
      iup.label{title = "AnimationControll:"},
      iup.hbox{
        self.animPrevButton,
        self.animPauseButton,
        self.animNextButton,
      },
      
      iup.label{title = "AnimationSpeed:"},
      iup.val{"horizontal", value = .5, 
        button_release_cb = function(lself) app:SetAnimVelocity(lself.value) return iup.DEFAULT end
      },
      ------------------------
      iup.fill{size = 15},
      iup.vbox{
        iup.label{title = "Points:"},
        self.pointsList
      },
      
      iup.fill{size = 5},
      iup.hbox{
        iup.label{title = "NumBorderPoints: "},
        self.numBorderPointsText,
      },
      ------------------------
      iup.fill{size = 15},
      iup.label{title = "Generation:"},
      self.generationMethodsList,
      iup.fill{size = 5},
      iup.vbox{
        iup.label{title = "Num Points:"},
        iup.fill{size = 5},
        iup.spinbox { self.numPointsText, 
          spin_cb = function (lself, inc)
            self.numPoints = math.max(self.numPoints + tonumber(inc), 3)
            self.numPointsText.value = tostring(self.numPoints)
          end
        },
      },  
      iup.fill{size = 5},
      iup.button{title = "Generate Points", 
        action = function(lself) self:GeneratePoints() end
      },
      -------------------------
      iup.fill{size = 5},
    },
    iup.fill{size = 5}

  }
  
  self.glCanvas = CreateGlCanvas(
    app,
    function() return self.points end , 
    function() return self.polys end,
    function() return app.options.showBorderPoints == true and self.borderpoints or {} end
  )
  
  self.iupelem = iup.hbox{
    self.opsBox,
    self.glCanvas,
  }

  self.dialog = iup.dialog{self.iupelem, title = "3DConvexHull", menu = nil, rastersize = tostring(app.width).."x"..tostring(app.height)}
  return self.iupelem
end 

function ConvexHullVisual:Show()
  self.timer = iup.timer{TIME = 10, RUN = "YES"}
  function self.timer.action_cb(lself)
    self.glCanvas:display()
  end
  self.dialog:show()
  self.glCanvas:initGl()
  self.glCanvas:display()
  
  iup.MainLoop()
end 

ConvexHullVisual:BuildInterface()
ConvexHullVisual:Show()





