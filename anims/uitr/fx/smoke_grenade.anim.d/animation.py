"""
Generates an animation.xml definition with tactical anims alongside the vanilla in-world anims.
"""
import io
import math
import os
import re
import sys
import xml.etree.ElementTree as ET

DRAW_TEST_COVER_BOX = False

def addAnim(root, name, *, symbol = 'effect', frameCount = 1, frameRate = 30):
  anim = ET.SubElement(root, 'anim')
  anim.set('name', name)
  anim.set('root', symbol)
  anim.set('numframes', str(frameCount))
  anim.set('framerate', str(frameRate))
  return anim

def addFrame(anim, frameIdx0=0):
  frame = ET.SubElement(anim, 'frame')
  frame.set('idx', str(len(anim) - 1 + frameIdx0))
  frame.set('w', str(0))
  frame.set('h', str(0))
  frame.set('x', str(0))
  frame.set('y', str(0))
  return frame

def buildAnim(root, name, frameFn, *, fnKwargs=None, frameCount=1, frameIdx0=0, **kwargs):
  anim = addAnim(root, name, frameCount=frameCount, **kwargs)
  if fnKwargs is None:
    fnKwargs = {}
  for i in range(frameCount):
    frameFn(addFrame(anim, frameIdx0=frameIdx0), i, frameCount, **fnKwargs)
  return anim

def _applyTransformCoord(el, tfm, idx, coord):
  if tfm and (
      type(tfm) is dict and tfm.get(idx) or type(tfm) is list and len(tfm) > idx
      ) and tfm[idx].get(coord) is not None:
    val = tfm[idx][coord]
  elif coord == 'a' or coord == 'd': # scale factors
    val = 1
  else: # shear or translation
    val = 0
  el.set('m%d_%s' % (idx, coord), str(val))

def _applyColorCoord(el, colors, channelIn, channelOut):
  if colors and colors.get(channelIn) and colors[channelIn].get(channelOut) is not None:
    val = colors[channelIn].get(channelOut)
  elif channelIn == channelOut: # red->red, etc.
    val = 1
  else: # red->green, etc.
    val = 0
  el.set('c_%d%d' % (channelIn, channelOut), str(val))

def addElement(frame, imgName, *, imgFrame = 0, depth = 0, tfm = None, colors = None):
  el = ET.SubElement(frame, 'element')
  el.set('name', imgName)
  el.set('layername', '2571176411')
  el.set('parentname', '2571176411')
  el.set('frame', str(imgFrame))
  el.set('depth', str(depth))
  # Two sequential affine transformations.
  for idx in [1, 0]:
    for coord in ['a', 'b', 'c', 'd', 'tx', 'ty']:
      _applyTransformCoord(el, tfm, idx, coord)
  # Direct color mappings.
  for i in range(5):
    _applyColorCoord(el, colors, i, i)
  # Cross-channel color mappings.
  for i in range(5):
    for j in range(5):
      if i != j:
        _applyColorCoord(el, colors, i, j)
  return el

PARAMS = type('CoordinateParams', (object,), {
    # 0,-88 +/- 115,115/sclY = top corners of the 1x1 cover boxes.
    # y = 88 - 20 to hover slightly over them.
    # y = 0 for the ground layer.
    'x0': 0,
    'y0': 0,
    'sclD': 115,
    # Isometric projection compresses Y axis.
    'projX': 1,
    'projY': 1/1.8})

def _tfmXY(dx = 0, dy = 0, *, size = 1, projectDeltaOnly = True):
  if projectDeltaOnly:
    # Projection only affects translation coordinates.
    return {1:
        {'a': size, 'd': size,
          'tx': PARAMS.x0 + PARAMS.projX * PARAMS.sclD * dx,
          'ty': PARAMS.y0 + PARAMS.projY * PARAMS.sclD * dy}}
  else:
    # Projection also reshapes the image.
    return [
        {'a': PARAMS.projX, 'd': PARAMS.projY, 'tx': PARAMS.x0, 'ty': PARAMS.y0},
        {'a': size, 'd': size / PARAMS.projY, 'tx': PARAMS.sclD * dx, 'ty': PARAMS.sclD * dy }]

def buildTestFrame(frame, t, tMax, *, size=0.375, drawTest=DRAW_TEST_COVER_BOX):
  del t, tMax
  if drawTest:
    # Tactical cover sprite for checking scale & alignment.
    addElement(frame, 'MF_cover_1x1_tac', tfm=[{'a': 2.5, 'd': 2.5}, {'tx': 0.3, 'ty': -16.349}])

  addElement(frame, 'sphere', tfm=_tfmXY( 0,  0, size=size))
  addElement(frame, 'sphere', tfm=_tfmXY( 0,  1, size=size))
  addElement(frame, 'sphere', tfm=_tfmXY( 0, -1, size=size))
  addElement(frame, 'sphere', tfm=_tfmXY( 1,  0, size=size))
  addElement(frame, 'sphere', tfm=_tfmXY(-1,  0, size=size))

def buildOrbitFrame(frame, t, tMax, *, drawTest=DRAW_TEST_COVER_BOX,
                    size=0.6, radius=1/math.sqrt(2), orbCount=4, period=None, fade=False):
  """Spheres orbit around a circle that fits in the tile bounds."""
  if drawTest:
    # Tactical cover sprite for checking scale & alignment.
    addElement(frame, 'MF_cover_1x1_tac', tfm=[{'a': 2.5, 'd': 2.5}, {'tx': 0.3, 'ty': -16.349}])

  if fade and t < fade:
    # Volumetric expansion up to 2x radius.
    size = size * (1 + 1 * (t/fade)**(1/3))
    alpha = 1 - (t/fade)**(2/3)
  elif fade:
      return # Past completion of the fade. Add empty frames to match in-world anim.
  else:
    alpha = 1

  tN = t / (period or tMax) # Normalized t.
  def tfmOrbit(orbIdx):
    angle = (orbIdx / orbCount + tN) * 2 * math.pi
    return {
        'tfm': _tfmXY(radius * math.cos(angle), radius * math.sin(angle), size=size),
        # Alpha decreases as it moves towards the background.
        'colors': {3: {3: alpha * (0.7 + 0.3 * math.sin(angle))}}
        }
  for i in range(orbCount):
    addElement(frame, 'sphere', **tfmOrbit(i))

def buildEdgeFrame(frame, t, tMax, *, drawTest=DRAW_TEST_COVER_BOX,
                   size=0.6 * 0.5, radius=1.5, orbCount=4, period=None, fade=False):
  """Spheres travel along the edge of the tile bounds."""
  if drawTest:
    # Tactical cover sprite for checking scale & alignment.
    addElement(frame, 'MF_cover_1x1_tac', tfm=[{'a': 2.5, 'd': 2.5}, {'tx': 0.3, 'ty': -16.349}])

  if fade and t < fade:
    # Volumetric expansion up to 3x radius.
    size = size * (1 + 2 * (t/fade)**(1/3))
    alpha = 1 - (t/fade)**(2/3)
  elif fade:
      return # Past completion of the fade. Add empty frames to match in-world anim.
  else:
    alpha = 1

  tN = t / (period or tMax) # Normalized t.
  def addEdgeOrb(orbIdx):
    # Distance within a single side.
    tSide, sideN = math.modf((tN + orbIdx / orbCount) * 4)
    sideN = sideN % 4
    # TODO: hide edges that don't touch the cloud.
    if sideN == 0:
      x, y = tSide, 1 - tSide
    elif sideN == 1:
      x, y = 1 - tSide, -tSide
    elif sideN == 2:
      x, y = -tSide, -1 + tSide
    else:
      x, y = -1 + tSide, tSide
    tfm = _tfmXY(radius * x, radius * y, size=size)
    # Alpha fades to 0 at the corners.
    colors = {3: {3: alpha * (0.5 - 0.5 * math.cos(tSide * 2 * math.pi))}}
    addElement(frame, 'sphere', tfm=tfm, colors=colors)
  for i in range(orbCount):
    addEdgeOrb(i)

def buildDocumentTree():
  root = ET.Element('Anims')

  # buildAnim(root, 'loop', frameFn=buildTestFrame, fnKwargs={'drawTest'=True})

  buildAnim(root, 'loop', symbol='tactical', frameFn=buildOrbitFrame, frameCount=100)
  # To match the vanilla in-world anim, start the pst anim at idx=100.
  # Then, pad the rest of pst's duration with empty frames, for the same reason.
  buildAnim(root, 'pst', symbol='tactical', frameFn=buildOrbitFrame,
      frameCount=100, frameIdx0=100, fnKwargs={'fade': 75, 'period': 100})

  buildAnim(root, 'loop', symbol='tactical_edge', frameFn=buildEdgeFrame, frameCount=100,
            fnKwargs={})
  buildAnim(root, 'pst', symbol='tactical_edge', frameFn=buildEdgeFrame,
                      frameCount=100, frameIdx0=100,
                      fnKwargs={'fade': 75, 'period': 100})

  return ET.ElementTree(root)

def openOutputFile():
  assert __file__[-3:] == '.py'
  outfilename = __file__[:-2] + 'xml'
  return open(outfilename, 'w', encoding='utf-8')

def openVanillaFile():
  assert __file__[-3:] == '.py'
  vanillafilename = __file__[:-2] + 'vanilla.xml'
  return open(vanillafilename, 'r', encoding='utf-8')


def main():
  tree = buildDocumentTree()

  ET.indent(tree, space='  ', level=0)
  buf = io.StringIO()
  tree.write(buf, encoding='unicode')
  buf.seek(0)

  # Insert linebreaks within attribute lists before each group of values.
  lineBreakPattern = re.compile(r' (m0_a|m1_a|c_00|c_01)=')

  with openOutputFile() as f, openVanillaFile() as vf:
    f.write('<Anims>\n')
    for line in buf:
      if line.startswith('<'): continue # Skip the outermost layer.
      formattedLine = lineBreakPattern.sub(r'\n' + 10*' ' + r'\1=', line)
      f.write(formattedLine)
    for line in vf:
      if line.startswith('<'): continue # Skip the outermost layer.
      f.write(line)
    f.write('</Anims>\n')


if __name__ == '__main__':
  main()
