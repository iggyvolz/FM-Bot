local io=require "io"
local config=require "config"
local board=config.board
board.__index=board

local function explode(div,str) -- credit: http://richard.warburton.it
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end
local function shell(script)
  return io.popen(script):read("*a"):sub(1,-2)
end
local function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end

shell("curl --silent -d \"username="..board.user.."&password="..board.pass.."&login=Login\" "..board.url.."/ucp.php?mode=login -c cookies.txt")
function board:post(subj,msg)
  local conts=shell("curl --silent \""..self.url.."/posting.php?mode=reply&f="..self.forum.."&t="..self.topic.."\" -b cookies.txt")
  shell("sleep 2;curl --silent -d \"message="..url_encode(msg).."&subject="..url_encode(subj).."&topic_cur_post_id="..explode("\"",explode("<input type=\"hidden\" name=\"topic_cur_post_id\" value=\"",conts)[2])[1].."&lastclick="..explode("\"",explode("<input type=\"hidden\" name=\"lastclick\" value=\"",conts)[2])[1].."&creation_time="..explode("\"",explode("<input type=\"hidden\" name=\"creation_time\" value=\"",conts)[2])[1].."&form_token="..explode("\"",explode("<input type=\"hidden\" name=\"form_token\" value=\"",conts)[2])[1].."&post=Submit\" \""..self.url.."/posting.php?mode=reply&f="..self.forum.."&t="..self.topic.."\" -b cookies.txt")
end
function board:read(p)
  local page=explode("</div>",explode("<div class=\"postbody\">",shell("curl --silent \""..self.url.."/viewtopic.php?f="..self.forum.."&t="..self.topic.."&start="..p.."\" -b cookies.txt"))[2])[1]
  return {["conts"]=explode("<div class=\"content\">",page)[2],["author"]=explode(">",explode("</a>",explode("<strong>",page)[2])[1])[2]}
end
local function firstpmnum()
  local self=board -- Simulate other functions for consistancy
  local page=shell("curl --silent \""..self.url.."/ucp.php?i=pm&folder=inbox\" -b cookies.txt")
  if explode("<a href=\"./ucp.php?i=pm&amp;mode=view&amp;f=0&amp;p=",page)[2]==nil then
    return nil -- No PM's
  end
  return tonumber(explode("\"",explode("<a href=\"./ucp.php?i=pm&amp;mode=view&amp;f=0&amp;p=",page)[2])[1])
end
board.firstpmnum=firstpmnum()
local function getnumofposts()
  local self=board -- Simulate other functions for consistancy
  local page=shell("curl --silent \""..self.url.."/viewtopic.php?f="..self.forum.."&t="..self.topic.."\" -b cookies.txt")
  return tonumber(explode(" posts",explode("<div class=\"pagination\">",page)[2])[1])
end
board.numposts=getnumofposts()
return board
