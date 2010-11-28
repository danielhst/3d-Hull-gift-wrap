require "iuplua"
require "iupluagl" 
require "luagl" 
require "luaglu" 
require "iupluacontrols" 
require "iuplua_pplot51" 

require "vec3"

-- APPLICATION GLOBAL TABLE
-- APPLICATION GLOBAL TABLE
-- APPLICATION GLOBAL TABLE
local app = nil
  
-- CONTROL METHODS  
-- CONTROL METHODS  
-- CONTROL METHODS  
  
local function SetupLights()
  local ambient = { .2, .2, .2, 1.} 
  local diffuse = { .8, .8, .8, 1.} 
  local specular = { 1., 1., 1., 1.} 

  gl.Light(gl.LIGHT0, gl.AMBIENT,  ambient)
  gl.Light(gl.LIGHT0, gl.DIFFUSE,  diffuse)
  gl.Light(gl.LIGHT0, gl.SPECULAR, specular)
end 

local function ActiveCamLight(op, x, y, z)
  if op then
    local pos = { x, y, z, 1.} 
    gl.PushAttrib(gl.LIGHTING_BIT, gl.ENABLE_BIT)
    gl.Enable(gl.LIGHTING)
    
    gl.Enable(gl.LIGHT0)

    gl.Light(gl.LIGHT0, gl.POSITION, pos)
  else
    gl.PopAttrib()
  end
end

local function ActiveMaterial(op)
  local ambient = { .2, .2, .2, 1.} 
  local diffuse = { .8, 0, 0, 1.} 
  local specular = { 1., 1., 1., 1.} 
  local shi = 10
  if op then
    gl.PushAttrib(gl.LIGHTING_BIT)
    gl.Material(gl.FRONT_AND_BACK, gl.AMBIENT,  ambient);
    gl.Material(gl.FRONT_AND_BACK, gl.DIFFUSE,  diffuse);
    gl.Material(gl.FRONT_AND_BACK, gl.SPECULAR, specular);
    gl.Material(gl.FRONT_AND_BACK, gl.SHININESS, shi);
  else
    gl.PopAttrib()
  end
end

local function SetupCamera()
  local x = app.cam.r*math.sin(math.rad(app.cam.beta))*math.cos(math.rad(app.cam.alpha))
  local y = app.cam.r*math.sin(math.rad(app.cam.alpha)) 
  local z = app.cam.r*math.cos(math.rad(app.cam.beta))*math.cos(math.rad(app.cam.alpha))

  local nextAlpha =  math.min(app.cam.alpha + app.cam.angInc, 360.)

  local ux = math.sin(math.rad(app.cam.beta))*math.cos(math.rad(nextAlpha)) - x
  local uy = math.sin(math.rad(nextAlpha)) - y
  local uz = math.cos(math.rad(app.cam.beta))*math.cos(math.rad(nextAlpha)) - z


  local pos = newVec3(x,y,z)
  local at = newVec3(0,0,0)
  local up = newVec3(ux,uy,uz)
  up:normalize()
  
  local dir = at - pos
  dir:normalize()
  
  local right = dir:cross(up)
  right:normalize()
  
  up = right:cross(dir)
  up:normalize()
  
  at = at + right*app.cam.center.x + up*app.cam.center.y
  pos = pos + right*app.cam.center.x + up*app.cam.center.y
  
  gl.LoadIdentity()
  glu.LookAt(pos.x, pos.y, pos.z, at.x, at.y, at.z, up.x, up.y, up.z)
  return pos.x, pos.y, pos.z, at.x, at.y, at.z, up.x, up.y, up.z
end        

local function DrawAxis()
  gl.PushAttrib(gl.LINE_BIT, gl.ENABLE_BIT)
  gl.Disable(gl.LIGHTING)
  gl.LineWidth(2)
  gl.Begin(gl.LINES)
    gl.Color(0, 0, 1); gl.Vertex(0, 0, 0); gl.Color(0, 0, 1); gl.Vertex(0, 0, 1000)
    gl.Color(0, 1, 0); gl.Vertex(0, 0, 0); gl.Color(0, 1, 0); gl.Vertex(0, 1000, 0)
    gl.Color(1, 0, 0); gl.Vertex(0, 0, 0); gl.Color(1, 0, 0); gl.Vertex(1000, 0, 0)
  gl.End()
  gl.PopAttrib()
end

local function DrawPoints(points, borderpoints)
  gl.PushAttrib(gl.ENABLE_BIT, gl.POINT_BIT)
  if app.options.depthTest == false then
    gl.Disable(gl.DEPTH_TEST)
  end
  gl.Disable(gl.LIGHTING)
  gl.Enable(gl.POINT_SMOOTH)
  gl.PointSize(9)
  gl.Begin(gl.POINTS)
    for i, point in ipairs(points) do
      if borderpoints[i] then
        gl.Color(0,0,1)
      else 
        gl.Color(1,0,0)
      end
      gl.Vertex(point.x, point.y, point.z)
    end
  gl.End()

  gl.PopAttrib()
end  

local function DrawHull(points, polys, x, y, z)
  ActiveMaterial(true)
  gl.Begin(gl.TRIANGLES)
  gl.Color(0,1,0)
  for i, triangle in ipairs(polys) do
    local v1 = points[triangle[2]] - points[triangle[1]]
    local v2 = points[triangle[3]] - points[triangle[1]]
    local normal = v1:cross(v2)
    normal:normalize()

    gl.Normal(normal.x, normal.y, normal.z)
    for j, vertex_index in ipairs(triangle) do
      gl.Vertex(points[vertex_index].x, points[vertex_index].y, points[vertex_index].z)
    end
  end
  gl.End()
  ActiveMaterial(false)
end

local function DrawHullAnim(points, polys, x, y, z)
  ActiveMaterial(true)
  gl.Begin(gl.TRIANGLES)
  gl.Color(0,1,0)
  for i, triangle in ipairs(polys) do
    if i >= app.anim.step then
      break
    end
    local v1 = points[triangle[2]] - points[triangle[1]]
    local v2 = points[triangle[3]] - points[triangle[1]]
    local normal = v1:cross(v2)
    normal:normalize()

    gl.Normal(normal.x, normal.y, normal.z)
    for j, vertex_index in ipairs(triangle) do
      gl.Vertex(points[vertex_index].x, points[vertex_index].y, points[vertex_index].z)
    end
  end
  gl.End()

  ActiveMaterial(false)
  
  gl.PushAttrib(gl.LINE_BIT, gl.ENABLE_BIT)
  gl.Disable(gl.LIGHTING)
  gl.LineWidth(4)
  gl.Begin(gl.LINES)
  gl.Color(0,1,0)
    for j = 1, 2 do
      gl.Vertex(points[polys[app.anim.step][j]].x, points[polys[app.anim.step][j]].y, points[polys[app.anim.step][j]].z)
    end
  gl.End()
  gl.PopAttrib()
  
  if app.anim.pause == false then
    if app.anim.count > app.anim.transitionTime then
      if app.anim.type == "edge" then
        app.anim.type = "triangle" 
      elseif app.anim.count > app.anim.transitionTime + app.anim.edgeTransitionTime then
        app.anim.step = app.anim.step + 1
        app.anim.type = "edge" 
        app.anim.count = 0
      else 
        app.anim.count = app.anim.count + 1
      end
    else
      app.anim.count = app.anim.count + 1
    end 
  end
end





local glCanvas = iup.glcanvas{buffer="DOUBLE"}

-- GLCANVAS METHODS  
-- GLCANVAS METHODS  
-- GLCANVAS METHODS  

function glCanvas:initGl()
  iup.GLMakeCurrent(self)

  gl.ClearColor(.8,.8,.8,1.0)
  
  gl.ShadeModel(app.render.flatEnabled and gl.FLAT or gl.SMOOTH)
  
  gl.PolygonMode(gl.FRONT_AND_BACK, app.render.wireFrameEnabled and gl.LINE or gl.FILL)

-- gl.CullFace(gl.BACK)
-- gl.CullFace(gl.FRONT)
-- gl.Enable(gl.CULL_FACE)

  gl.Enable(gl.DEPTH_TEST)
  -- gl.Light(gl.LIGHT0, gl.DIFFUSE, glLightDif)
  
  self:resize_cb(app.width, app.height)
  
  SetupLights()
end

function glCanvas:action()
  self:display()
end

function glCanvas:resize_cb(width, height)
  app.width = width;
  app.height = height;
  
  gl.Viewport (0, 0, app.width, app.height);
  gl.MatrixMode (gl.PROJECTION);
  gl.LoadIdentity ();
  glu.Perspective(app.cam.fovy, app.width / app.height, app.cam.near, app.cam.far);
  gl.MatrixMode (gl.MODELVIEW);
end 

function glCanvas:keypress_cb(key, pressed)
  if pressed == 1 then 
  
    if key == 27 then --ESC
      os.exit()
      
    elseif key == 119 or key == 87 then --W
      app:SetWireframeEnabled()
      
    elseif key == 113 or key == 81 then --Q
      app:SetFlatEnabled()
 
    elseif key == 328 then --UP ARROW
      app.cam.alpha = (app.cam.alpha - app.cam.angInc)%360
    elseif key == 336 then --Down ARROW
      app.cam.alpha = (app.cam.alpha + app.cam.angInc)%360
    elseif key == 331 then --LEFT ARROW
      app.cam.beta = (app.cam.beta + app.cam.angInc)%360
    elseif key == 333 then --RIGHT ARROW
      app.cam.beta = (app.cam.beta - app.cam.angInc)%360
    elseif key == 45 then -- + 
      app.cam.r = app.cam.r + 1
    elseif key == 43 then -- -
      app.cam.r = app.cam.r - 1
  
    elseif key == 329 then --pgup 
    elseif key == 337 then --pqDown

    elseif key == 315 then --F1

    elseif key == 49 then --1
    end
  end
end

function glCanvas:button_cb(but, pressed, x, y, status)
  app.mouse.state = pressed
  app.mouse.button = but

  app.mouse.pos.x = x
  app.mouse.pos.y = y
end

function glCanvas:motion_cb(x, y, status)
  if app.mouse.button == iup.BUTTON1 and  app.mouse.state == 1 then--LEFT_BUTTON PRESSED
    local angleX = (x - app.mouse.pos.x)*.5
    local angleY = (y - app.mouse.pos.y)*.5

    app.cam.alpha = (app.cam.alpha + angleY)%360
    app.cam.beta =  (app.cam.beta - angleX)%360
    
  elseif app.mouse.button == iup.BUTTON2 and app.mouse.state == 1 then --MIDDLE_BUTTON PRESSED
    app.cam.center.x = app.cam.center.x  - (x - app.mouse.pos.x)/50.0
    app.cam.center.y = app.cam.center.y  + (y - app.mouse.pos.y)/50.0
    
  elseif app.mouse.button == iup.BUTTON3 and app.mouse.state == 1 then --RIGHT_BUTTON PRESSED
    app.cam.r = app.cam.r + (y - app.mouse.pos.y)/20.0
  end
  
  app.mouse.pos.x = x
  app.mouse.pos.y = y
end

function glCanvas:display()
  iup.GLMakeCurrent(self)
  
  gl.Clear('COLOR_BUFFER_BIT,DEPTH_BUFFER_BIT')

  local x, y, z = SetupCamera()

  if app.options.showAxis then
    DrawAxis()
  end
  
  local points = self.GetPoints_cb()
  local polys = self.GetPolys_cb()
  local borderpoints = self.GetBorderPoints_cb()
  
  ActiveCamLight(true, x, y, z)
  if app.anim.enabled and app.anim.step <= #polys then
    DrawHullAnim(points, polys)
  else     
    DrawHull(points, polys)
  end
  ActiveCamLight(false)
  
  DrawPoints(points, borderpoints)

  iup.GLSwapBuffers(self)
end


-- EXPORTED METHOD

function CreateGlCanvas(applicationTable, GetPoints_cb, GetPolys_cb, GetBorderPoints_cb)
  app = applicationTable
  glCanvas.GetPoints_cb = GetPoints_cb
  glCanvas.GetPolys_cb = GetPolys_cb
  glCanvas.GetBorderPoints_cb = GetBorderPoints_cb
  return glCanvas 
end




