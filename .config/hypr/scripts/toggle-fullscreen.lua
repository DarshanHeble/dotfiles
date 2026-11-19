local win = hl.get_active_window()
if not win then
  return
end

if win.fullscreen ~= 0 then
  -- Exit fullscreen
  hl.dispatch(hl.dsp.window.fullscreen(0))
  -- If it was pinned before fullscreen, re-pin it
  if win.floating and win.tags and win.tags:find("was_pinned") then
    hl.dispatch(hl.dsp.window.pin({ window = win }))
    hl.dispatch(hl.dsp.window.tag({ window = win, tag = "-was_pinned" }))
  end
else
  -- Enter fullscreen
  if win.pinned then
    hl.dispatch(hl.dsp.window.tag({ window = win, tag = "+was_pinned" }))
    hl.dispatch(hl.dsp.window.pin({ window = win }))
  end
  hl.dispatch(hl.dsp.window.fullscreen(0))
end
